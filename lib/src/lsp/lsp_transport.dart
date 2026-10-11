import 'dart:async';

/// Identifies an [LspTransport] variant without exposing implementation
/// details.
enum LspTransportKind {
  /// The editor's WebView opens a WebSocket directly to the server.
  webSocket,

  /// JSON-RPC messages are relayed through the Flutter/JavaScript bridge.
  bridged,

  /// A user-registered JavaScript factory builds the transport in-page.
  custom,
}

/// Describes how the LSP client inside the editor WebView reaches a language
/// server.
///
/// Transports are descriptions, not live connections: the JavaScript bridge
/// turns them into a Monaco `IMessageTransport` when
/// `MonacoController.connectLanguageServer` runs. Pick the variant that
/// matches where your server lives:
///
/// - [LspWebSocketTransport] - the server (or a proxy in front of it) speaks
///   WebSocket. Works on every supported platform, but requires the target
///   origin to be allow-listed via `allowedConnectSources` when creating the
///   editor.
/// - [LspBridgedTransport] - Dart owns the wire. JSON-RPC messages are
///   relayed through the Flutter bridge, which lets desktop apps talk to a
///   local stdio server process (see `LspServerProcess`) without opening any
///   network port or relaxing the Content-Security-Policy.
/// - [LspCustomTransport] - an escape hatch for advanced setups (web workers,
///   iframes, custom protocols). You register a factory on
///   `window.flutterMonacoLspTransports` and own the `IMessageTransport`
///   implementation.
sealed class LspTransport {
  const LspTransport();

  /// The transport variant.
  LspTransportKind get kind;

  /// Serializes this transport into the payload consumed by the JavaScript
  /// bridge's `flutterMonaco.lsp.connect`.
  Map<String, Object?> toBridgePayload();
}

/// Connects the in-page LSP client to a WebSocket-fronted language server.
///
/// Most stdio language servers (pyright, typescript-language-server,
/// rust-analyzer, gopls, ...) do not speak WebSocket natively. Front them
/// with a thin proxy - for example:
///
/// ```sh
/// npx jsonrpc-ws-proxy --port 3000 \
///   --languageServers '{"python": ["pyright-langserver", "--stdio"]}'
/// ```
///
/// ## Content-Security-Policy
///
/// The editor page ships with `connect-src 'self' blob:`, which blocks every
/// `ws://`/`wss://` handshake. Allow the server's origin explicitly when
/// creating the editor:
///
/// ```dart
/// final controller = await MonacoController.create(
///   page: const MonacoPageConfig(
///     allowedConnectSources: ['ws://127.0.0.1:3000'],
///   ),
/// );
/// ```
///
/// Without the opt-in the browser refuses the connection and
/// `connectLanguageServer` fails.
///
/// ## Authentication
///
/// Browser WebSockets cannot carry custom HTTP headers. If the server needs
/// a token, pass it in the URL query string (`wss://host/lsp?token=...`) or
/// use an [LspCustomTransport] that builds an authenticated socket itself.
final class LspWebSocketTransport extends LspTransport {
  /// Creates a WebSocket transport for [url].
  ///
  /// [url] must use the `ws` or `wss` scheme.
  LspWebSocketTransport({required this.url}) {
    if (url.scheme != 'ws' && url.scheme != 'wss') {
      throw ArgumentError.value(
        url,
        'url',
        'LSP WebSocket transport requires a ws:// or wss:// URL',
      );
    }
  }

  /// The WebSocket endpoint, e.g. `ws://127.0.0.1:3000` or
  /// `wss://lsp.example.com/python`.
  final Uri url;

  @override
  LspTransportKind get kind => LspTransportKind.webSocket;

  @override
  Map<String, Object?> toBridgePayload() => {
    'kind': 'webSocket',
    'url': url.toString(),
  };

  @override
  String toString() => 'LspWebSocketTransport($url)';
}

/// A Dart-owned transport that relays JSON-RPC messages through the Flutter
/// bridge.
///
/// Use this when the language server is reachable from Dart but not from the
/// WebView - most importantly a local stdio server process on desktop. The
/// `LspServerProcess` helper spawns such a process and hands you a fully
/// wired [LspBridgedTransport]:
///
/// ```dart
/// final server = await LspServerProcess.start(
///   'pyright-langserver', ['--stdio'],
/// );
/// final connection = await controller.connectLanguageServer(
///   id: 'pyright',
///   transport: server.transport,
/// );
/// ```
///
/// Both directions carry parsed JSON-RPC messages (maps), never raw bytes:
///
/// - [fromServer] streams messages produced by the server; the connection
///   forwards each one into the in-page LSP client. When this stream closes
///   the connection treats the server as gone and transitions to `closed`;
///   when it emits an error the connection transitions to `failed` with that
///   error. Either one during the LSP `initialize` handshake makes
///   `connectLanguageServer` throw right away (the error, or a [StateError]
///   for a plain close).
/// - [toServer] receives every message the in-page client sends; write it to
///   the server (the `LspServerProcess` helper frames it onto stdin). If it
///   throws, the connection treats the server as gone.
/// - [onClose] runs once when the connection ends for good - terminate the
///   server process here. See [onClose] for exactly when it runs.
///
/// Message ordering is preserved in both directions.
///
/// A bridged transport is single-use: [fromServer] is consumed by exactly one
/// connection, so reconnecting requires constructing a new transport (and
/// usually a new server process). For that reason automatic reconnect
/// policies are not supported with bridged transports.
final class LspBridgedTransport extends LspTransport {
  /// Creates a bridged transport from a server-message stream and a
  /// client-message callback.
  LspBridgedTransport({
    required this.fromServer,
    required this.toServer,
    this.onClose,
  });

  /// Messages from the language server, to be delivered to the in-page
  /// client.
  final Stream<Map<String, Object?>> fromServer;

  /// Called for every message the in-page client sends to the server.
  final void Function(Map<String, Object?> message) toServer;

  /// Releases the server; invoked at most once.
  ///
  /// The connection owns the transport once `connectLanguageServer` has
  /// started connecting it, and runs this callback when the connection ends
  /// for good: explicit disconnect, controller disposal, server death, or a
  /// page reload. If `connectLanguageServer` throws, this callback has
  /// already completed by the time the error reaches the caller, whatever
  /// the cause (invalid or duplicate id, an unsupported reconnect policy,
  /// a failed or timed-out handshake, disposal or a page reload during
  /// connect). The only exception is a call that fails while waiting for
  /// the editor to become ready (the controller was disposed or the editor
  /// failed to boot): the transport was never used, this callback does not
  /// run, and the caller still owns the server. `LspServerProcess.stop` is
  /// idempotent, so calling it after any failed connect is always safe.
  final Future<void> Function()? onClose;

  @override
  LspTransportKind get kind => LspTransportKind.bridged;

  @override
  Map<String, Object?> toBridgePayload() => {'kind': 'bridged'};

  @override
  String toString() => 'LspBridgedTransport()';
}

/// A transport built by a user-registered JavaScript factory.
///
/// Register the factory on `window.flutterMonacoLspTransports` (for example
/// via `MonacoController.runJavaScript`) before connecting:
///
/// ```js
/// window.flutterMonacoLspTransports = {
///   myWorker: (config) => monaco.lsp.createTransportToWorker(
///     new Worker(config.workerUrl)),
/// };
/// ```
///
/// The factory receives [config] and must return (or resolve to) an object
/// implementing Monaco's `IMessageTransport` interface (`state`, `send`,
/// `setListener`, `toString`). Monaco's own helpers
/// (`monaco.lsp.WebSocketTransport.fromWebSocket`,
/// `monaco.lsp.createTransportToWorker`,
/// `monaco.lsp.createTransportToIFrame`) all qualify.
///
/// The name lookup is a deliberate trust boundary: transports can only be
/// created from factories the app registered explicitly, never from
/// arbitrary strings.
final class LspCustomTransport extends LspTransport {
  /// Creates a custom transport referencing the factory registered under
  /// [factoryName].
  LspCustomTransport({required this.factoryName, this.config = const {}}) {
    if (factoryName.trim().isEmpty) {
      throw ArgumentError.value(
        factoryName,
        'factoryName',
        'factoryName must be a non-empty string',
      );
    }
  }

  /// Key of the factory on `window.flutterMonacoLspTransports`.
  final String factoryName;

  /// JSON-serializable configuration passed to the factory.
  final Map<String, Object?> config;

  @override
  LspTransportKind get kind => LspTransportKind.custom;

  @override
  Map<String, Object?> toBridgePayload() => {
    'kind': 'custom',
    'factoryName': factoryName,
    'config': config,
  };

  @override
  String toString() => 'LspCustomTransport($factoryName)';
}
