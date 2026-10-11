import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/src/common/exceptions.dart';
import 'package:flutter_monaco/src/lsp/lsp_transport.dart';
import 'package:flutter_monaco/src/lsp/lsp_types.dart';
import 'package:flutter_monaco/src/protocol/envelope.dart';
import 'package:flutter_monaco/src/protocol/protocol.dart';

/// A live connection between the Monaco editor and one language server.
///
/// Obtained from `MonacoController.connectLanguageServer`. While the
/// connection is [LspConnectionStatus.open], Monaco's built-in LSP client
/// drives every language feature the server advertises - completions, hover,
/// go-to-definition, rename, formatting, code actions, semantic tokens, and
/// diagnostics - directly inside the editor. There is nothing to wire up in
/// Dart; this handle only exposes lifecycle control and observability.
///
/// ### Lifecycle
///
/// ```
/// connecting ──► open ──► closed
///      │           │
///      ▼           ▼ (unexpected drop + reconnect policy)
///   (throws)   connecting ──► open / failed
/// ```
///
/// - The initial `connectLanguageServer` call resolves only after the LSP
///   `initialize` handshake completes; on failure it throws and no handle is
///   returned.
/// - [stateChanges] broadcasts every transition; [whenClosed] completes once
///   the connection permanently ends.
/// - [disconnect] tears down the in-page client (unregistering all language
///   feature providers) and, for bridged transports, invokes the transport's
///   `onClose` callback.
///
/// Diagnostics published by the server appear as Monaco markers under the
/// owner `'lsp'`.
class LanguageServerConnection {
  LanguageServerConnection._({
    required this.id,
    required this.transport,
    required this.reconnectPolicy,
    required this._initializationTimeout,
    required this._manager,
  });

  /// The unique identifier passed to `connectLanguageServer`.
  final String id;

  /// The transport description this connection was created with.
  final LspTransport transport;

  /// The reconnect policy applied to unexpected transport drops.
  final LspReconnectPolicy reconnectPolicy;

  final Duration _initializationTimeout;
  final MonacoLspManager _manager;

  LspConnectionState _state = const LspConnectionState(
    status: LspConnectionStatus.connecting,
  );
  final StreamController<LspConnectionState> _stateController =
      StreamController<LspConnectionState>.broadcast();
  final Completer<void> _closedCompleter = Completer<void>();

  StreamSubscription<Map<String, Object?>>? _pumpSubscription;
  Future<void> _deliverChain = Future<void>.value();
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _userDisconnected = false;
  bool _finalized = false;

  /// The bridged transport's onClose future, started by finalization; an
  /// explicit [disconnect] awaits it so "disconnected" includes the local
  /// process/socket shutdown. Null for non-bridged transports.
  Future<void>? _transportShutdown;

  /// The most recent connection state.
  LspConnectionState get state => _state;

  /// Broadcast stream of state transitions.
  ///
  /// The stream closes after the final `closed`/`failed` state is emitted.
  Stream<LspConnectionState> get stateChanges => _stateController.stream;

  /// Completes when the connection has permanently ended (explicit
  /// [disconnect], controller disposal, transport death without reconnect,
  /// or exhausted reconnect attempts). Never completes with an error.
  Future<void> get whenClosed => _closedCompleter.future;

  /// Whether the connection currently serves language features.
  bool get isOpen => _state.isOpen;

  /// Disconnects the language server and unregisters every provider the
  /// in-page LSP client installed.
  ///
  /// Non-destructive to editor content and models. Safe to call multiple
  /// times. For bridged transports the returned future completes only after
  /// the transport's `onClose` callback finished (e.g. the local server
  /// process exited), so awaiting it means the local side is down too.
  Future<void> disconnect() => _manager._disconnect(this);

  /// **Experimental.** Sends a raw JSON-RPC request through the open
  /// connection and returns the server's result.
  ///
  /// Intended for non-standard server extensions (e.g.
  /// `pyright/createConfigFile` or `rust-analyzer/expandMacro`). Standard
  /// LSP traffic is fully handled by Monaco - do not replicate it here.
  ///
  /// This escape hatch relies on Monaco-internal plumbing (verified against
  /// Monaco 0.55.1) and may throw a descriptive [MonacoJavaScriptError]
  /// on future Monaco upgrades. Throws [StateError] when the connection is
  /// not open.
  Future<Object?> sendRequest(
    String method, [
    Object? params,
    Duration timeout = const Duration(seconds: 30),
  ]) {
    return _manager._sendRequest(this, method, params, timeout);
  }

  /// **Experimental.** Sends a raw JSON-RPC notification through the open
  /// connection. Same caveats as [sendRequest].
  Future<void> sendNotification(String method, [Object? params]) {
    return _manager._sendNotification(this, method, params);
  }

  void _setState(LspConnectionState next) {
    if (_state == next) return;
    _state = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  @override
  String toString() =>
      'LanguageServerConnection($id, ${_state.status.name}, $transport)';
}

/// Internal coordinator for all language server connections of one
/// `MonacoController`.
///
/// Owns the Dart side of the LSP bridge protocol on top of `MonacoProtocol`:
///
/// - `lsp.*` command dispatch (request correlation lives in the protocol
///   layer, which generalized the mechanism this manager pioneered).
/// - `lspStatus` events (open/closed transitions from the page).
/// - `lspMessage` events (client-to-server messages of bridged transports).
///
/// Not exported from the package; use `MonacoController.connectLanguageServer`.
class MonacoLspManager {
  /// Creates a manager wired to [protocol] events.
  MonacoLspManager({required this._protocol}) {
    _eventsSubscription = _protocol.events.listen(_onProtocolEvent);
  }

  static const Duration _disconnectTimeout = Duration(seconds: 5);

  final MonacoProtocol _protocol;
  StreamSubscription<ProtocolEvent>? _eventsSubscription;

  final Map<String, LanguageServerConnection> _connections = {};
  bool _disposed = false;

  /// Connections that have not permanently closed yet.
  List<LanguageServerConnection> get connections =>
      List.unmodifiable(_connections.values);

  /// The connection registered under [id], or `null`.
  LanguageServerConnection? connection(String id) => _connections[id];

  /// Opens a new language server connection. See
  /// `MonacoController.connectLanguageServer` for the public contract.
  Future<LanguageServerConnection> connect({
    required String id,
    required LspTransport transport,
    LspReconnectPolicy reconnectPolicy = const LspReconnectPolicy.none(),
    Duration initializationTimeout = const Duration(seconds: 30),
  }) async {
    if (_disposed) {
      throw StateError('MonacoController has been disposed.');
    }
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'id must be a non-empty string');
    }
    if (_connections.containsKey(id)) {
      throw StateError(
        'A language server connection with id "$id" already exists. '
        'Disconnect it first or use a different id.',
      );
    }
    if (transport is LspBridgedTransport && reconnectPolicy.enabled) {
      throw ArgumentError(
        'Reconnect policies are not supported for LspBridgedTransport: its '
        'message stream is single-use. Respawn the server and call '
        'connectLanguageServer again from app code instead.',
      );
    }

    final connection = LanguageServerConnection._(
      id: id,
      transport: transport,
      reconnectPolicy: reconnectPolicy,
      initializationTimeout: initializationTimeout,
      manager: this,
    );
    _connections[id] = connection;

    try {
      await _open(connection, attempt: 0);
      return connection;
    } catch (error) {
      _finalize(connection, LspConnectionStatus.failed, error: error);
      rethrow;
    }
  }

  /// Disconnects the connection registered under [id]; no-op when unknown.
  Future<void> disconnect(String id) async {
    final connection = _connections[id];
    if (connection == null) return;
    await _disconnect(connection);
  }

  /// Establishes (or re-establishes) the in-page client for [connection].
  Future<void> _open(
    LanguageServerConnection connection, {
    required int attempt,
  }) async {
    connection._setState(
      LspConnectionState(
        status: LspConnectionStatus.connecting,
        reconnectAttempt: attempt,
      ),
    );

    _throwIfGone(connection);

    // Issue the connect call first: the JS side registers the connection
    // synchronously in its prologue, so every deliverServerMessage issued
    // afterwards (the pump below) finds a live transport - including the
    // server's response to the `initialize` request that the handshake
    // itself depends on.
    final resultFuture = await _protocol.invokeIssued('lsp.connect', {
      'id': connection.id,
      'transport': connection.transport.toBridgePayload(),
    }, timeout: null);
    resultFuture.ignore();

    final transport = connection.transport;
    if (transport is LspBridgedTransport &&
        connection._pumpSubscription == null) {
      _startBridgedPump(connection, transport);
    }

    try {
      await resultFuture.timeout(connection._initializationTimeout);
    } on TimeoutException {
      // Best-effort teardown of whatever the page managed to build.
      unawaited(_invokeSafely('lsp.disconnect', {'id': connection.id}));
      throw TimeoutException(
        'Language server "${connection.id}" did not complete the LSP '
        'initialize handshake within '
        '${connection._initializationTimeout.inSeconds}s. Check that the '
        'server is reachable (for WebSocket transports also check the '
        'allowedConnectSources CSP opt-in).',
        connection._initializationTimeout,
      );
    }

    _throwIfGone(connection);
    connection._reconnectAttempt = 0;
    connection._setState(
      const LspConnectionState(status: LspConnectionStatus.open),
    );
  }

  void _throwIfGone(LanguageServerConnection connection) {
    if (_disposed) {
      throw StateError('MonacoController was disposed during LSP connect.');
    }
    if (connection._finalized || connection._userDisconnected) {
      throw StateError(
        'LSP connection "${connection.id}" was disconnected during connect.',
      );
    }
  }

  // ─── Bridged transport pump (Dart -> JS direction) ───────────────────────

  void _startBridgedPump(
    LanguageServerConnection connection,
    LspBridgedTransport transport,
  ) {
    connection._pumpSubscription = transport.fromServer.listen(
      (message) => _deliverToPage(connection, message),
      onError: (Object error, StackTrace stackTrace) {
        _handleServerGone(connection, error);
      },
      onDone: () => _handleServerGone(connection, null),
    );
  }

  void _deliverToPage(
    LanguageServerConnection connection,
    Map<String, Object?> message,
  ) {
    // Chain deliveries so message order is preserved even though each
    // runJavaScript call is asynchronous.
    connection._deliverChain = connection._deliverChain.then((_) async {
      if (_disposed || connection._finalized) return;
      try {
        // Await issuance only (the outer future): message order on the page
        // is script-issue order, and delivery does not need the response.
        final delivered = await _protocol.invokeIssued(
          'lsp.deliverServerMessage',
          {'id': connection.id, 'message': message},
          timeout: null,
        );
        delivered.ignore();
      } catch (error) {
        debugPrint(
          '[MonacoLsp] Failed to deliver server message for '
          '"${connection.id}": $error',
        );
      }
    });
  }

  /// The bridged server stream ended or errored: the server is gone.
  void _handleServerGone(LanguageServerConnection connection, Object? error) {
    if (_disposed || connection._finalized || connection._userDisconnected) {
      return;
    }
    unawaited(() async {
      await _invokeSafely('lsp.disconnect', {'id': connection.id});
      if (connection._finalized) return;
      _finalize(
        connection,
        error == null ? LspConnectionStatus.closed : LspConnectionStatus.failed,
        error: error,
      );
    }());
  }

  // ─── Protocol events (JS -> Dart) ─────────────────────────────────────────

  void _onProtocolEvent(ProtocolEvent event) {
    if (_disposed) return;
    switch (event.name) {
      case 'lspStatus':
        _handleLspStatus(Map<String, dynamic>.from(event.data));
      case 'lspMessage':
        _handleLspMessage(Map<String, dynamic>.from(event.data));
    }
  }

  void _handleLspStatus(Map<String, dynamic> json) {
    final connection = _connections[json['connectionId']?.toString()];
    if (connection == null || connection._finalized) return;

    final status = json['status']?.toString();
    switch (status) {
      case 'open':
        // The connect flow drives the open transition itself (after the
        // invoke result); this event is informational.
        break;
      case 'closed':
      case 'failed':
        final rawError = json['error'];
        final errorInfo = rawError is Map
            ? Map<String, dynamic>.from(rawError)
            : null;
        final error = errorInfo == null
            ? null
            : MonacoJavaScriptError.fromJson(
                errorInfo,
                operation: 'lsp:${connection.id}',
              );
        _handleRemoteClosed(connection, error);
    }
  }

  void _handleLspMessage(Map<String, dynamic> json) {
    final connection = _connections[json['connectionId']?.toString()];
    if (connection == null || connection._finalized) return;
    final transport = connection.transport;
    if (transport is! LspBridgedTransport) return;
    final rawMessage = json['message'];
    final message = rawMessage is Map
        ? Map<String, Object?>.from(rawMessage)
        : null;
    if (message == null) return;
    try {
      transport.toServer(message);
    } catch (error) {
      debugPrint(
        '[MonacoLsp] toServer callback for "${connection.id}" threw: $error',
      );
      // A throwing send means the local process/socket plumbing is gone;
      // the connection cannot be trusted to stay "open". Route it through
      // the same path as a transport-reported close (which also honors the
      // reconnect policy).
      _handleRemoteClosed(connection, error);
    }
  }

  /// The page reported the transport closed without an explicit disconnect.
  void _handleRemoteClosed(LanguageServerConnection connection, Object? error) {
    if (_disposed || connection._finalized || connection._userDisconnected) {
      return;
    }
    // While connecting/reconnecting the connect flow owns error handling;
    // transient close events during the handshake are surfaced there.
    if (connection._state.status == LspConnectionStatus.connecting) return;

    if (connection.reconnectPolicy.enabled) {
      _scheduleReconnect(connection, error);
    } else {
      unawaited(() async {
        // Dispose the in-page client so its providers unregister; the
        // transport is already dead.
        await _invokeSafely('lsp.disconnect', {'id': connection.id});
        if (connection._finalized) return;
        _finalize(connection, LspConnectionStatus.closed, error: error);
      }());
    }
  }

  // ─── Reconnect ────────────────────────────────────────────────────────────

  void _scheduleReconnect(LanguageServerConnection connection, Object? error) {
    final attempt = connection._reconnectAttempt + 1;
    if (attempt > connection.reconnectPolicy.maxAttempts) {
      unawaited(() async {
        await _invokeSafely('lsp.disconnect', {'id': connection.id});
        if (connection._finalized) return;
        _finalize(connection, LspConnectionStatus.failed, error: error);
      }());
      return;
    }

    connection._reconnectAttempt = attempt;
    connection._setState(
      LspConnectionState(
        status: LspConnectionStatus.connecting,
        error: error,
        reconnectAttempt: attempt,
      ),
    );

    unawaited(() async {
      // Tear down the dead in-page client first; reconnect reuses the id.
      await _invokeSafely('lsp.disconnect', {'id': connection.id});
      if (_disposed || connection._finalized || connection._userDisconnected) {
        return;
      }
      final delay = connection.reconnectPolicy.delayFor(attempt);
      connection._reconnectTimer = Timer(delay, () {
        unawaited(_attemptReconnect(connection));
      });
    }());
  }

  Future<void> _attemptReconnect(LanguageServerConnection connection) async {
    if (_disposed || connection._finalized || connection._userDisconnected) {
      return;
    }
    try {
      await _open(connection, attempt: connection._reconnectAttempt);
    } catch (error) {
      if (_disposed || connection._finalized || connection._userDisconnected) {
        return;
      }
      _scheduleReconnect(connection, error);
    }
  }

  // ─── Disconnect / disposal ────────────────────────────────────────────────

  Future<void> _disconnect(LanguageServerConnection connection) async {
    if (connection._finalized) {
      // Already finalized elsewhere; still let an explicit disconnect wait
      // out an in-flight transport shutdown.
      await connection._transportShutdown;
      return;
    }
    connection._userDisconnected = true;
    connection._reconnectTimer?.cancel();
    await _invokeSafely('lsp.disconnect', {'id': connection.id});
    if (!connection._finalized) {
      _finalize(connection, LspConnectionStatus.closed);
    }
    // An awaited disconnect means the LOCAL side is down too: for bridged
    // transports (LspServerProcess and friends) that is the onClose
    // process/socket shutdown, which _finalize starts without awaiting.
    await connection._transportShutdown;
  }

  void _finalize(
    LanguageServerConnection connection,
    LspConnectionStatus status, {
    Object? error,
  }) {
    if (connection._finalized) return;
    connection._finalized = true;
    connection._reconnectTimer?.cancel();
    connection._pumpSubscription?.cancel();
    if (identical(_connections[connection.id], connection)) {
      _connections.remove(connection.id);
    }
    connection._setState(
      LspConnectionState(
        status: status,
        error: error,
        reconnectAttempt: connection._reconnectAttempt,
      ),
    );
    connection._stateController.close();
    if (!connection._closedCompleter.isCompleted) {
      connection._closedCompleter.complete();
    }

    final transport = connection.transport;
    if (transport is LspBridgedTransport && transport.onClose != null) {
      // Started here without awaiting (this runs from synchronous dispose
      // paths); stored on the connection so an explicit disconnect() can
      // await the local shutdown.
      final shutdown = Future<void>.sync(() => transport.onClose!())
          .catchError((Object closeError) {
            debugPrint(
              '[MonacoLsp] onClose for "${connection.id}" threw: $closeError',
            );
          });
      connection._transportShutdown = shutdown;
      unawaited(shutdown);
    }
  }

  /// Synchronously tears down all connections. Called from
  /// `MonacoController.dispose()` before the WebView is destroyed.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // Best-effort in-page cleanup while the WebView might still be alive;
    // the JS context (and any open sockets) dies with the WebView anyway.
    try {
      unawaited(
        Future<Object?>.sync(
          () => _protocol.invoke(
            'lsp.disconnectAll',
            {},
            timeout: _disconnectTimeout,
          ),
        ).then((_) {}, onError: (_) {}),
      );
    } catch (_) {}

    for (final connection in List.of(_connections.values)) {
      _finalize(connection, LspConnectionStatus.closed);
    }
    _connections.clear();
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
  }

  // ─── Power-user escape hatches ────────────────────────────────────────────

  Future<Object?> _sendRequest(
    LanguageServerConnection connection,
    String method,
    Object? params,
    Duration timeout,
  ) async {
    _requireOpen(connection, 'sendRequest');
    return _invokeAsync('lsp.sendRequest', {
      'id': connection.id,
      'method': method,
      'params': params,
    }, timeout: timeout);
  }

  Future<void> _sendNotification(
    LanguageServerConnection connection,
    String method,
    Object? params,
  ) async {
    _requireOpen(connection, 'sendNotification');
    await _invokeAsync('lsp.sendNotification', {
      'id': connection.id,
      'method': method,
      'params': params,
    }, timeout: const Duration(seconds: 10));
  }

  void _requireOpen(LanguageServerConnection connection, String operation) {
    if (!connection.isOpen) {
      throw StateError(
        'Cannot $operation on LSP connection "${connection.id}": connection '
        'is ${connection.state.status.name}.',
      );
    }
  }

  // ─── Async invoke plumbing ────────────────────────────────────────────────

  /// Dispatches an `lsp.*` command with the manager's timeout wording and
  /// undefined-to-null mapping.
  Future<Object?> _invokeAsync(
    String method,
    Map<String, Object?> params, {
    required Duration timeout,
  }) async {
    final future = await _protocol.invokeIssued(method, params, timeout: null);
    try {
      final result = await future.timeout(timeout);
      return identical(result, monacoJsUndefined) ? null : result;
    } on TimeoutException {
      throw TimeoutException(
        'Monaco bridge call "$method" timed out after '
        '${timeout.inSeconds}s.',
        timeout,
      );
    }
  }

  Future<void> _invokeSafely(String method, Map<String, Object?> params) async {
    try {
      await _invokeAsync(method, params, timeout: _disconnectTimeout);
    } catch (error) {
      // Best-effort: the WebView may already be gone or the page may not
      // know the connection anymore.
      debugPrint('[MonacoLsp] $method(${params['id']}) failed: $error');
    }
  }
}
