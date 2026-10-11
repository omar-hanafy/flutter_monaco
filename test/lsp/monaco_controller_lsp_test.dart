import 'dart:async';
import 'dart:convert';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

/// Drives the Dart side of the LSP bridge protocol against the fake WebView.
///
/// Every `lsp.*` command now rides the protocol v3 dispatch envelope: calls
/// are recorded in [FakePlatformWebViewController.dispatched] and resolve
/// from `response` envelopes posted through the `flutterChannel`. By default
/// the fake auto-answers every dispatch with success, so simple flows just
/// await the controller call. Tests that need precise response sequencing
/// (reconnect choreography, hung handshakes) set `webView.autoRespond =
/// false` and answer through this harness instead.
class LspBridgeHarness {
  LspBridgeHarness(this.webView);

  final FakePlatformWebViewController webView;
  final Set<String> _consumedDispatchIds = {};

  /// Returns the oldest not-yet-consumed dispatch of [method], waiting for
  /// it to be issued if necessary.
  Future<({String requestId, Map<String, Object?> params})> waitForDispatch(
    String method, {
    int maxTurns = 200,
  }) async {
    for (var i = 0; i < maxTurns; i++) {
      for (final call in webView.dispatched) {
        if (call['method'] != method) continue;
        final requestId = call['id']! as String;
        if (_consumedDispatchIds.contains(requestId)) continue;
        _consumedDispatchIds.add(requestId);
        return (
          requestId: requestId,
          params: (call['params']! as Map).cast<String, Object?>(),
        );
      }
      await Future<void>.delayed(Duration.zero);
    }
    fail(
      'No "$method" dispatch was issued. Dispatched calls:\n'
      '${webView.dispatched.join('\n')}',
    );
  }

  void respondOk(String requestId, {Object? value = true}) {
    _emit({
      'v': 3,
      'kind': 'response',
      'id': requestId,
      'ok': true,
      'undefined': false,
      'value': value,
    });
  }

  void respondError(String requestId, String message) {
    _emit({
      'v': 3,
      'kind': 'response',
      'id': requestId,
      'ok': false,
      'error': {'name': 'Error', 'message': message},
    });
  }

  void emitStatus(String connectionId, String status, {String? errorMessage}) {
    webView.emitEvent('lspStatus', {
      'connectionId': connectionId,
      'status': status,
      'error': errorMessage == null
          ? null
          : {'name': 'Error', 'message': errorMessage},
    });
  }

  void emitLspMessage(String connectionId, Map<String, Object?> message) {
    webView.emitEvent('lspMessage', {
      'connectionId': connectionId,
      'message': message,
    });
  }

  /// Waits for the next dispatch of [method] and acknowledges it with a
  /// success response. Used when manually driving fire-and-forget
  /// disconnects.
  Future<void> acknowledge(String method) async {
    final dispatch = await waitForDispatch(method);
    respondOk(dispatch.requestId);
  }

  void _emit(Map<String, Object?> payload) {
    webView.emitToChannel('flutterChannel', jsonEncode(payload));
  }
}

Future<void> pumpMicrotasks([int turns = 20]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakePlatformWebViewController webView;
  late MonacoController controller;
  late LspBridgeHarness harness;

  setUp(() async {
    webView = FakePlatformWebViewController();
    controller = await MonacoController.createForTesting(
      webViewController: webView,
    );
    harness = LspBridgeHarness(webView);
  });

  tearDown(() {
    controller.dispose();
  });

  group('connectLanguageServer', () {
    test(
      'resolves after the JS handshake and registers the connection',
      () async {
        final connection = await controller.connectLanguageServer(
          id: 'py',
          transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        );

        final connect = await harness.waitForDispatch('lsp.connect');
        expect(connect.params, {
          'id': 'py',
          'transport': {'kind': 'webSocket', 'url': 'ws://localhost:1'},
        });

        expect(connection.id, 'py');
        expect(connection.isOpen, isTrue);
        expect(connection.state.status, LspConnectionStatus.open);
        expect(controller.languageServerConnections, [connection]);
        expect(controller.languageServerConnection('py'), same(connection));
      },
    );

    test('emits connecting then open on stateChanges', () async {
      final connection = await controller.connectLanguageServer(
        id: 'py',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );

      // The open state is already current; further transitions stream.
      expect(connection.state.status, LspConnectionStatus.open);
      expect(connection.state.reconnectAttempt, 0);
    });

    test('throws on duplicate ids while connected', () async {
      await controller.connectLanguageServer(
        id: 'dup',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );

      expect(
        () => controller.connectLanguageServer(
          id: 'dup',
          transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:2')),
        ),
        throwsStateError,
      );
    });

    test('throws on empty id', () async {
      expect(
        () => controller.connectLanguageServer(
          id: '  ',
          transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        ),
        throwsArgumentError,
      );
    });

    test('rejects reconnect policies for bridged transports', () async {
      expect(
        () => controller.connectLanguageServer(
          id: 'bridged',
          transport: LspBridgedTransport(
            fromServer: const Stream.empty(),
            toServer: (_) {},
          ),
          reconnectPolicy: const LspReconnectPolicy.exponentialBackoff(),
        ),
        throwsArgumentError,
      );
    });

    test('propagates JS connect failures and registers nothing', () async {
      webView.injectCommandFailure(
        'lsp.connect',
        message: 'WebSocket handshake refused',
      );

      final connectFuture = controller.connectLanguageServer(
        id: 'broken',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );

      await expectLater(
        connectFuture,
        throwsA(
          isA<MonacoJavaScriptError>().having(
            (e) => e.message,
            'message',
            contains('handshake refused'),
          ),
        ),
      );
      expect(controller.languageServerConnections, isEmpty);
      // The id is reusable after a failed connect.
      expect(controller.languageServerConnection('broken'), isNull);
    });

    test('times out when the handshake never completes', () async {
      webView.autoRespond = false;

      final connectFuture = controller.connectLanguageServer(
        id: 'slow',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        initializationTimeout: const Duration(milliseconds: 50),
      );

      await harness.waitForDispatch('lsp.connect');

      await expectLater(connectFuture, throwsA(isA<TimeoutException>()));
      expect(controller.languageServerConnections, isEmpty);
      // Best-effort teardown was attempted.
      await harness.waitForDispatch('lsp.disconnect');
    });
  });

  group('disconnect', () {
    test('closes the connection and completes whenClosed', () async {
      final connection = await controller.connectLanguageServer(
        id: 'py',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );

      final states = <LspConnectionState>[];
      connection.stateChanges.listen(states.add);

      await connection.disconnect();
      await connection.whenClosed;

      final disconnect = await harness.waitForDispatch('lsp.disconnect');
      expect(disconnect.params, {'id': 'py'});
      expect(connection.state.status, LspConnectionStatus.closed);
      expect(states.last.status, LspConnectionStatus.closed);
      expect(controller.languageServerConnections, isEmpty);
    });

    test('disconnectLanguageServer is a no-op for unknown ids', () async {
      await controller.disconnectLanguageServer('nope');
    });

    test('completes even when the JS side fails', () async {
      final connection = await controller.connectLanguageServer(
        id: 'py',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );

      webView.injectCommandFailure('lsp.disconnect', message: 'page went away');

      await controller.disconnectLanguageServer('py');
      expect(connection.state.status, LspConnectionStatus.closed);
    });
  });

  group('bridged transports', () {
    test('relays server messages to the page in order', () async {
      final fromServer = StreamController<Map<String, Object?>>();

      final connectFuture = controller.connectLanguageServer(
        id: 'bridged',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
        ),
      );

      fromServer
        ..add({'jsonrpc': '2.0', 'id': 1, 'result': {}})
        ..add({'jsonrpc': '2.0', 'method': 'window/logMessage'});
      await connectFuture;
      await pumpMicrotasks();

      final connect = await harness.waitForDispatch('lsp.connect');
      expect(connect.params['transport'], {'kind': 'bridged'});

      final deliveries = webView.dispatched
          .where((d) => d['method'] == 'lsp.deliverServerMessage')
          .toList();
      expect(deliveries, hasLength(2));
      expect(deliveries[0]['params'], {
        'id': 'bridged',
        'message': {'jsonrpc': '2.0', 'id': 1, 'result': <String, Object?>{}},
      });
      expect(deliveries[1]['params'], {
        'id': 'bridged',
        'message': {'jsonrpc': '2.0', 'method': 'window/logMessage'},
      });
      // Ordering: the connect dispatch must have been issued before the
      // first delivery so the JS side has registered the transport.
      final connectIndex = webView.dispatched.indexWhere(
        (d) => d['method'] == 'lsp.connect',
      );
      final deliverIndex = webView.dispatched.indexWhere(
        (d) => d['method'] == 'lsp.deliverServerMessage',
      );
      expect(connectIndex, lessThan(deliverIndex));

      await fromServer.close();
    });

    test('routes client messages from the page to toServer', () async {
      final received = <Map<String, Object?>>[];
      final fromServer = StreamController<Map<String, Object?>>();

      await controller.connectLanguageServer(
        id: 'bridged',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: received.add,
        ),
      );

      harness.emitLspMessage('bridged', {
        'jsonrpc': '2.0',
        'method': 'initialize',
        'id': 0,
      });
      harness.emitLspMessage('bridged', {
        'jsonrpc': '2.0',
        'method': 'textDocument/didOpen',
      });
      await pumpMicrotasks();

      expect(received, hasLength(2));
      expect(received[0]['method'], 'initialize');
      expect(received[1]['method'], 'textDocument/didOpen');

      await fromServer.close();
      await pumpMicrotasks();
    });

    test('closes the connection when the server stream ends', () async {
      var onCloseCalls = 0;
      final fromServer = StreamController<Map<String, Object?>>();

      final connection = await controller.connectLanguageServer(
        id: 'bridged',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
          onClose: () async => onCloseCalls++,
        ),
      );

      await fromServer.close();
      await connection.whenClosed;

      expect(connection.state.status, LspConnectionStatus.closed);
      expect(onCloseCalls, 1);
      expect(controller.languageServerConnections, isEmpty);
    });

    test('fails the connection when the server stream errors', () async {
      final fromServer = StreamController<Map<String, Object?>>();

      final connection = await controller.connectLanguageServer(
        id: 'bridged',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
        ),
      );

      fromServer.addError(StateError('server crashed'));
      await connection.whenClosed;

      expect(connection.state.status, LspConnectionStatus.failed);
      expect(connection.state.error, isA<StateError>());

      await fromServer.close();
    });

    test('invokes onClose exactly once on explicit disconnect', () async {
      var onCloseCalls = 0;
      final fromServer = StreamController<Map<String, Object?>>();

      final connection = await controller.connectLanguageServer(
        id: 'bridged',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
          onClose: () async => onCloseCalls++,
        ),
      );

      await connection.disconnect();
      await pumpMicrotasks();

      expect(onCloseCalls, 1);
      await fromServer.close();
    });
  });

  group('unexpected transport drops', () {
    test('without a reconnect policy the connection closes', () async {
      final connection = await controller.connectLanguageServer(
        id: 'ws',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );

      harness.emitStatus('ws', 'closed', errorMessage: 'socket dropped');
      await connection.whenClosed;

      expect(connection.state.status, LspConnectionStatus.closed);
      expect(
        (connection.state.error as MonacoJavaScriptError?)?.message,
        contains('socket dropped'),
      );
    });

    test('with a reconnect policy the connection reopens', () async {
      // Drive responses manually: the test must observe the intermediate
      // connecting state before the second connect resolves.
      webView.autoRespond = false;

      final connectFuture = controller.connectLanguageServer(
        id: 'ws',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        reconnectPolicy: const LspReconnectPolicy.exponentialBackoff(
          initialDelay: Duration(milliseconds: 1),
          maxAttempts: 3,
        ),
      );
      final first = await harness.waitForDispatch('lsp.connect');
      harness.respondOk(first.requestId);
      final connection = await connectFuture;

      final states = <LspConnectionState>[];
      connection.stateChanges.listen(states.add);

      // Drop the transport: expect JS cleanup, then a fresh connect.
      harness.emitStatus('ws', 'closed', errorMessage: 'network blip');
      await harness.acknowledge('lsp.disconnect');
      final second = await harness.waitForDispatch('lsp.connect');
      expect(connection.state.status, LspConnectionStatus.connecting);
      expect(connection.state.reconnectAttempt, 1);

      harness.respondOk(second.requestId);
      await pumpMicrotasks();

      expect(connection.state.status, LspConnectionStatus.open);
      expect(connection.state.reconnectAttempt, 0);
      expect(
        states.map((s) => s.status),
        containsAllInOrder([
          LspConnectionStatus.connecting,
          LspConnectionStatus.open,
        ]),
      );
      expect(controller.languageServerConnections, [connection]);
    });

    test('exhausted reconnect attempts fail the connection', () async {
      webView.autoRespond = false;

      final connectFuture = controller.connectLanguageServer(
        id: 'ws',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        reconnectPolicy: const LspReconnectPolicy.exponentialBackoff(
          initialDelay: Duration(milliseconds: 1),
          maxAttempts: 1,
        ),
      );
      final first = await harness.waitForDispatch('lsp.connect');
      harness.respondOk(first.requestId);
      final connection = await connectFuture;

      harness.emitStatus('ws', 'closed', errorMessage: 'gone');
      await harness.acknowledge('lsp.disconnect');
      final retry = await harness.waitForDispatch('lsp.connect');
      harness.respondError(retry.requestId, 'still down');
      await harness.acknowledge('lsp.disconnect');
      await connection.whenClosed;

      expect(connection.state.status, LspConnectionStatus.failed);
      expect(controller.languageServerConnections, isEmpty);
    });
  });

  group('experimental request escape hatches', () {
    test('sendRequest forwards to the page and returns the result', () async {
      final connection = await controller.connectLanguageServer(
        id: 'py',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );

      webView.injectCommandSuccess('lsp.sendRequest', value: {'pong': true});
      final result = await connection.sendRequest('pyright/ping', {'x': 1});

      final request = await harness.waitForDispatch('lsp.sendRequest');
      expect(request.params, {
        'id': 'py',
        'method': 'pyright/ping',
        'params': {'x': 1},
      });
      expect(result, {'pong': true});
    });

    test('sendRequest throws when the connection is not open', () async {
      final connection = await controller.connectLanguageServer(
        id: 'py',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );

      await connection.disconnect();

      expect(() => connection.sendRequest('x'), throwsStateError);
      expect(() => connection.sendNotification('x'), throwsStateError);
    });
  });

  group('controller disposal', () {
    test('closes connections and stops the server process hook', () async {
      var onCloseCalls = 0;
      final fromServer = StreamController<Map<String, Object?>>();

      final connection = await controller.connectLanguageServer(
        id: 'bridged',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
          onClose: () async => onCloseCalls++,
        ),
      );

      controller.dispose();
      await connection.whenClosed;
      await pumpMicrotasks();

      expect(connection.state.status, LspConnectionStatus.closed);
      expect(onCloseCalls, 1);
      expect(controller.languageServerConnections, isEmpty);

      await fromServer.close();
    });

    test('connect after dispose throws MonacoDisposedError', () async {
      controller.dispose();
      expect(
        () => controller.connectLanguageServer(
          id: 'late',
          transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        ),
        throwsA(isA<MonacoDisposedError>()),
      );
    });
  });

  group('bridged transport hardening', () {
    test('a throwing toServer fails the connection', () async {
      final fromServer = StreamController<Map<String, Object?>>();
      addTearDown(fromServer.close);
      final connection = await controller.connectLanguageServer(
        id: 'crashy',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) => throw StateError('stdin is gone'),
        ),
      );
      await pumpMicrotasks();
      expect(connection.state.status, LspConnectionStatus.open);

      harness.emitLspMessage('crashy', {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'workspace/configuration',
      });
      await pumpMicrotasks();

      // A send that throws means the local plumbing is gone; the connection
      // must stop claiming to be open.
      expect(connection.state.status, LspConnectionStatus.closed);
      expect(connection.state.error, isNotNull);
      expect(controller.languageServerConnections, isEmpty);
    });

    test('disconnect() awaits the bridged transport onClose', () async {
      final fromServer = StreamController<Map<String, Object?>>();
      addTearDown(fromServer.close);
      final closeGate = Completer<void>();
      var closeStarted = false;
      final connection = await controller.connectLanguageServer(
        id: 'proc',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
          onClose: () {
            closeStarted = true;
            return closeGate.future;
          },
        ),
      );
      await pumpMicrotasks();

      var disconnected = false;
      final done = connection.disconnect().then((_) => disconnected = true);
      await pumpMicrotasks();
      expect(closeStarted, isTrue);
      expect(
        disconnected,
        isFalse,
        reason:
            'an awaited disconnect must mean the local process/socket '
            'shutdown completed',
      );

      closeGate.complete();
      await done;
      expect(disconnected, isTrue);
    });
  });

  group('handshake failures fail fast', () {
    // Each case uses a long initialization timeout and asserts the connect
    // settles well inside it: waiting the timeout out is the defect.
    const longTimeout = Duration(seconds: 30);
    const fastEnough = Duration(seconds: 2);

    Future<Object?> connectError(Future<LanguageServerConnection> future) {
      return future
          .then<Object?>(
            (_) => fail('connect unexpectedly succeeded'),
            onError: (Object error) => error,
          )
          .timeout(
            fastEnough,
            onTimeout: () => fail(
              'connect waited for the initialization timeout instead of '
              'failing fast',
            ),
          );
    }

    test('a server stream error fails connect with that error', () async {
      webView.autoRespond = false;
      final fromServer = StreamController<Map<String, Object?>>();
      addTearDown(fromServer.close);
      var onCloseCalls = 0;
      final states = <LspConnectionStatus>[];

      final future = controller.connectLanguageServer(
        id: 'srv',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
          onClose: () async => onCloseCalls++,
        ),
        initializationTimeout: longTimeout,
      );
      await harness.waitForDispatch('lsp.connect');
      final connection = controller.languageServerConnection('srv')!;
      connection.stateChanges.listen((s) => states.add(s.status));

      final cause = StateError('server exited with code 2');
      fromServer.addError(cause);

      expect(await connectError(future), same(cause));
      expect(connection.state.status, LspConnectionStatus.failed);
      expect(connection.state.error, same(cause));
      expect(states, [LspConnectionStatus.failed]);
      expect(onCloseCalls, 1);
      expect(controller.languageServerConnections, isEmpty);
      // The half-built page client is torn down.
      await harness.waitForDispatch('lsp.disconnect');
    });

    test('a server stream that ends fails connect as failed', () async {
      webView.autoRespond = false;
      final fromServer = StreamController<Map<String, Object?>>();

      final future = controller.connectLanguageServer(
        id: 'srv',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
        ),
        initializationTimeout: longTimeout,
      );
      await harness.waitForDispatch('lsp.connect');
      final connection = controller.languageServerConnection('srv')!;

      await fromServer.close();

      final error = await connectError(future);
      expect(
        error,
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('before completing the LSP initialize handshake'),
        ),
      );
      expect(connection.state.status, LspConnectionStatus.failed);
      expect(connection.state.error, same(error));
    });

    test('a throwing toServer fails connect with that error', () async {
      webView.autoRespond = false;
      final fromServer = StreamController<Map<String, Object?>>();
      addTearDown(fromServer.close);
      final cause = StateError('stdin pipe broken');

      final future = controller.connectLanguageServer(
        id: 'srv',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) => throw cause,
        ),
        initializationTimeout: longTimeout,
      );
      await harness.waitForDispatch('lsp.connect');
      harness.emitLspMessage('srv', {
        'jsonrpc': '2.0',
        'id': 0,
        'method': 'initialize',
      });

      expect(await connectError(future), same(cause));
      expect(
        controller.languageServerConnection('srv'),
        isNull,
        reason: 'the failed connection is unregistered',
      );
    });

    test('a transport closed by the page fails connect', () async {
      webView.autoRespond = false;

      final future = controller.connectLanguageServer(
        id: 'ws',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        initializationTimeout: longTimeout,
      );
      await harness.waitForDispatch('lsp.connect');
      harness.emitStatus('ws', 'closed', errorMessage: 'socket dropped');

      expect(
        await connectError(future),
        isA<MonacoJavaScriptError>().having(
          (e) => e.message,
          'message',
          contains('socket dropped'),
        ),
      );
      expect(controller.languageServerConnections, isEmpty);
    });

    test('disconnect during the handshake settles connect at once', () async {
      webView.autoRespond = false;
      final future = controller.connectLanguageServer(
        id: 'ws',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        initializationTimeout: longTimeout,
      );
      await harness.waitForDispatch('lsp.connect');
      final connection = controller.languageServerConnection('ws')!;

      final disconnected = connection.disconnect();
      await harness.acknowledge('lsp.disconnect');
      await disconnected;

      expect(await connectError(future), isA<StateError>());
      expect(connection.state.status, LspConnectionStatus.closed);
    });
  });

  group('bridged transport ownership', () {
    // Once handed to connectLanguageServer, a bridged transport belongs to
    // the connection: when the call throws, onClose has already completed.
    Future<void> expectClosedBeforeThrow(
      Future<LanguageServerConnection> Function(LspBridgedTransport) connect,
      Matcher throwsMatcher,
    ) async {
      final closeGate = Completer<void>();
      var onCloseCalls = 0;
      final transport = LspBridgedTransport(
        fromServer: const Stream.empty(),
        toServer: (_) {},
        onClose: () {
          onCloseCalls++;
          return closeGate.future;
        },
      );
      var settled = false;
      final future = connect(transport)
        ..then((_) {}, onError: (_) {}).whenComplete(() => settled = true);
      await pumpMicrotasks();
      expect(onCloseCalls, 1);
      expect(settled, isFalse, reason: 'connect waits for onClose');
      closeGate.complete();
      await expectLater(future, throwsMatcher);
      expect(onCloseCalls, 1);
    }

    test('an invalid id still runs onClose', () {
      return expectClosedBeforeThrow(
        (transport) =>
            controller.connectLanguageServer(id: ' ', transport: transport),
        throwsArgumentError,
      );
    });

    test('a duplicate id still runs onClose', () async {
      await controller.connectLanguageServer(
        id: 'dup',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );
      return expectClosedBeforeThrow(
        (transport) =>
            controller.connectLanguageServer(id: 'dup', transport: transport),
        throwsStateError,
      );
    });

    test('an unsupported reconnect policy still runs onClose', () {
      return expectClosedBeforeThrow(
        (transport) => controller.connectLanguageServer(
          id: 'p',
          transport: transport,
          reconnectPolicy: const LspReconnectPolicy.exponentialBackoff(),
        ),
        throwsArgumentError,
      );
    });

    test('a failed handshake runs onClose before throwing', () {
      webView.injectCommandFailure('lsp.connect', message: 'boom');
      return expectClosedBeforeThrow(
        (transport) =>
            controller.connectLanguageServer(id: 'p', transport: transport),
        throwsA(isA<MonacoJavaScriptError>()),
      );
    });
  });

  group('controller disposal during connect', () {
    test('does not subscribe to the server stream of a connection disposed '
        'while lsp.connect was being issued', () async {
      webView.autoRespond = false;
      var listened = false;
      final source = StreamController<Map<String, Object?>>(
        onListen: () => listened = true,
      );
      // close() only completes once a listener saw the done event, and the
      // fixed code never listens.
      addTearDown(() => unawaited(source.close()));

      final future = controller.connectLanguageServer(
        id: 'p',
        transport: LspBridgedTransport(
          fromServer: source.stream,
          toServer: (_) {},
        ),
      );
      final error = future.then<Object?>((_) => null, onError: (Object e) => e);
      // Dispose after the connect script was handed to the WebView but
      // before the manager resumed from issuing it.
      for (var i = 0; i < 10 && webView.dispatched.isEmpty; i++) {
        await Future<void>.microtask(() {});
      }
      expect(webView.dispatched.map((c) => c['method']), ['lsp.connect']);
      controller.dispose();
      await pumpMicrotasks();

      expect(await error, isA<MonacoDisposedError>());
      expect(
        source.hasListener,
        isFalse,
        reason:
            'a disposed connection must not keep a pump subscription '
            '(listened: $listened)',
      );
    });
  });

  group('page reload', () {
    // A reload discards the page-side LSP client and any page-owned socket,
    // so every connection must end as failed with MonacoPageReloadedError.
    late FakePlatformWebViewController reloadWebView;
    late MonacoController booted;
    late LspBridgeHarness reloadHarness;

    setUp(() async {
      reloadWebView = FakePlatformWebViewController();
      booted = await MonacoController.createForTesting(
        webViewController: reloadWebView,
        markReady: false,
        runBoot: true,
      );
      await booted.whenReady;
      reloadHarness = LspBridgeHarness(reloadWebView);
    });

    tearDown(() => booted.dispose());

    int connectCount() => reloadWebView.dispatched
        .where((c) => c['method'] == 'lsp.connect')
        .length;

    test('fails every open connection with MonacoPageReloadedError', () async {
      final ws = await booted.connectLanguageServer(
        id: 'ws',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
        reconnectPolicy: const LspReconnectPolicy.exponentialBackoff(
          initialDelay: Duration(milliseconds: 1),
        ),
      );
      final fromServer = StreamController<Map<String, Object?>>();
      addTearDown(fromServer.close);
      var onCloseCalls = 0;
      final bridged = await booted.connectLanguageServer(
        id: 'proc',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
          onClose: () async => onCloseCalls++,
        ),
      );
      expect(fromServer.hasListener, isTrue);
      final connectsBefore = connectCount();
      final reloaded = booted.onPageReloaded.first;

      reloadWebView.emitReadyLifecycle();
      await reloaded;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await pumpMicrotasks();

      for (final connection in [ws, bridged]) {
        expect(connection.isOpen, isFalse);
        expect(connection.state.status, LspConnectionStatus.failed);
        expect(connection.state.error, isA<MonacoPageReloadedError>());
        await connection.whenClosed.timeout(const Duration(seconds: 1));
        expect(() => connection.sendRequest('x'), throwsStateError);
      }
      expect(booted.languageServerConnections, isEmpty);
      // No automatic reconnect onto the bare page: the app reconnects after
      // restoring its documents.
      expect(connectCount(), connectsBefore);
      // The bridged server is released to its owner and the pump stops.
      expect(onCloseCalls, 1);
      expect(fromServer.hasListener, isFalse);
      // Disconnecting the stale handle is still safe.
      await ws.disconnect();
    });

    test('the same id reconnects from onPageReloaded', () async {
      await booted.connectLanguageServer(
        id: 'ws',
        transport: LspWebSocketTransport(url: Uri.parse('ws://localhost:1')),
      );
      final reconnected = Completer<LanguageServerConnection>();
      booted.onPageReloaded.listen((_) {
        reconnected.complete(
          booted.connectLanguageServer(
            id: 'ws',
            transport: LspWebSocketTransport(
              url: Uri.parse('ws://localhost:1'),
            ),
          ),
        );
      });

      reloadWebView.emitReadyLifecycle();
      final connection = await reconnected.future.timeout(
        const Duration(seconds: 1),
      );
      expect(connection.isOpen, isTrue);
      expect(booted.languageServerConnection('ws'), same(connection));
    });

    test('a connect in flight fails with MonacoPageReloadedError', () async {
      reloadWebView.autoRespond = false;
      var onCloseCalls = 0;
      final fromServer = StreamController<Map<String, Object?>>();
      addTearDown(fromServer.close);
      final future = booted.connectLanguageServer(
        id: 'proc',
        transport: LspBridgedTransport(
          fromServer: fromServer.stream,
          toServer: (_) {},
          onClose: () async => onCloseCalls++,
        ),
      );
      await reloadHarness.waitForDispatch('lsp.connect');

      reloadWebView.emitReadyLifecycle();

      await expectLater(future, throwsA(isA<MonacoPageReloadedError>()));
      expect(onCloseCalls, 1);
      expect(booted.languageServerConnections, isEmpty);
    });
  });
}
