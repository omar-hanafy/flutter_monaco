// Language Server Protocol demo.
//
// Demonstrates both LSP transports on a live editor:
//
// 1. WebSocket (all platforms) - point the editor at any WebSocket-fronted
//    language server. For a quick local server, front a stdio server with a
//    proxy, e.g.:
//
//      npx jsonrpc-ws-proxy --port 3000 \
//        --languageServers '{"python": ["pyright-langserver", "--stdio"]}'
//
//    The endpoint's origin must be allow-listed via `allowedConnectSources`
//    when the editor is created, so changing the endpoint recreates the
//    editor.
//
// 2. Local stdio process (desktop) - spawn a language server binary from
//    Dart (e.g. `pyright-langserver --stdio`) and relay JSON-RPC through the
//    Flutter bridge. No port, no proxy, no CSP changes.
//
// Run with: flutter run -t lib/lsp_example.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const LspExampleApp());
}

const String _samplePython = '''
from dataclasses import dataclass


@dataclass
class Point:
    x: float
    y: float

    def scaled(self, factor: float) -> "Point":
        return Point(self.x * factor, self.y * factor)


def total_distance(points: list[Point]) -> float:
    distance = 0.0
    for first, second in zip(points, points[1:]):
        dx = second.x - first.x
        dy = second.y - first.y
        distance += (dx**2 + dy**2) ** 0.5
    return distance


print(total_distance([Point(0, 0), Point(3, 4), Point(6, 8)]))
''';

class LspExampleApp extends StatelessWidget {
  const LspExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monaco LSP Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LspDemoPage(),
    );
  }
}

class LspDemoPage extends StatefulWidget {
  const LspDemoPage({super.key});

  @override
  State<LspDemoPage> createState() => _LspDemoPageState();
}

class _LspDemoPageState extends State<LspDemoPage> {
  final TextEditingController _wsUrlController = TextEditingController(
    text: 'ws://127.0.0.1:3000/python',
  );
  final TextEditingController _commandController = TextEditingController(
    text: 'pyright-langserver --stdio',
  );

  /// The origin currently allow-listed in the editor's CSP. Changing the
  /// WebSocket endpoint to a different origin recreates the editor.
  String _allowedOrigin = 'ws://127.0.0.1:3000';

  /// Forces a fresh editor (and WebView) when the CSP allow-list changes.
  int _editorGeneration = 0;

  MonacoController? _controller;
  LanguageServerConnection? _connection;
  StreamSubscription<LspConnectionState>? _stateSubscription;
  LspConnectionState? _connectionState;
  final List<String> _log = [];
  bool _busy = false;

  bool get _canSpawnProcess => !kIsWeb;

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _wsUrlController.dispose();
    _commandController.dispose();
    // Disposing the controller closes LSP connections, which stops the
    // spawned server process through the transport's onClose hook.
    super.dispose();
  }

  void _appendLog(String message) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, '${TimeOfDay.now().format(context)}  $message');
      if (_log.length > 60) _log.removeLast();
    });
  }

  Future<void> _onEditorReady(MonacoController controller) async {
    _controller = controller;
    // Language servers key their state on document URIs; give the demo
    // buffer a stable file-like URI instead of Monaco's default inmemory://.
    final document = await controller.openDocument(
      text: _samplePython,
      language: MonacoLanguage.python,
      uri: Uri.parse('file:///demo/main.py'),
    );
    await controller.activateDocument(document);
    _appendLog('Editor ready (document ${document.uri})');
  }

  void _watchConnection(LanguageServerConnection connection) {
    _connection = connection;
    _connectionState = connection.state;
    _stateSubscription?.cancel();
    _stateSubscription = connection.stateChanges.listen((state) {
      _appendLog('Connection: $state');
      if (mounted) setState(() => _connectionState = state);
    });
    unawaited(
      connection.whenClosed.then((_) {
        if (!mounted) return;
        setState(() {
          if (identical(_connection, connection)) {
            _connection = null;
          }
        });
      }),
    );
    setState(() {});
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _appendLog('ERROR: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connectWebSocket() => _runGuarded(() async {
    final controller = _controller;
    if (controller == null) return;
    final url = Uri.parse(_wsUrlController.text.trim());
    final origin = '${url.scheme}://${url.authority}';
    if (origin != _allowedOrigin) {
      _appendLog(
        'Endpoint origin changed to $origin - recreating the editor so the '
        'Content-Security-Policy allows it. Connect again once ready.',
      );
      setState(() {
        _allowedOrigin = origin;
        _editorGeneration++;
        _controller = null;
      });
      return;
    }

    _appendLog('Connecting to $url ...');
    final connection = await controller.connectLanguageServer(
      id: 'ws-server',
      transport: LspWebSocketTransport(url: url),
      reconnectPolicy: const LspReconnectPolicy.exponentialBackoff(
        maxAttempts: 3,
      ),
    );
    _watchConnection(connection);
    _appendLog(
      'Language server connected - try hovering, Ctrl+Space, F2, '
      'or introducing a type error.',
    );
  });

  Future<void> _spawnLocalServer() => _runGuarded(() async {
    final controller = _controller;
    if (controller == null) return;
    final parts = _commandController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;

    _appendLog('Spawning ${parts.join(' ')} ...');
    final process = await LspServerProcess.start(
      parts.first,
      parts.skip(1).toList(),
      onStderr: (line) => _appendLog('[server] $line'),
    );
    unawaited(
      process.exitCode.then(
        (code) => _appendLog('Server process exited with code $code'),
      ),
    );

    try {
      final connection = await controller.connectLanguageServer(
        id: 'stdio-server',
        transport: process.transport,
      );
      _watchConnection(connection);
      _appendLog('Local language server connected.');
    } catch (error) {
      // The transport was never adopted by a connection; stop the orphaned
      // process ourselves.
      await process.stop();
      rethrow;
    }
  });

  Future<void> _disconnect() => _runGuarded(() async {
    final connection = _connection;
    if (connection == null) return;
    await connection.disconnect();
    _appendLog('Disconnected.');
  });

  @override
  Widget build(BuildContext context) {
    final state = _connectionState;
    final connected = _connection != null && (state?.isOpen ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monaco LSP Demo'),
        actions: [
          if (_connection != null)
            IconButton(
              tooltip: 'Disconnect',
              onPressed: _busy ? null : _disconnect,
              icon: const Icon(Icons.link_off),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _wsUrlController,
                          enabled: !_busy && _connection == null,
                          decoration: const InputDecoration(
                            labelText: 'WebSocket language server URL',
                            helperText:
                                'e.g. npx jsonrpc-ws-proxy --port 3000 '
                                '--languageServers \'{"python": '
                                '["pyright-langserver", "--stdio"]}\'',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _busy || connected || _controller == null
                            ? null
                            : _connectWebSocket,
                        icon: const Icon(Icons.link),
                        label: const Text('Connect'),
                      ),
                    ],
                  ),
                  if (_canSpawnProcess) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commandController,
                            enabled: !_busy && _connection == null,
                            decoration: const InputDecoration(
                              labelText: 'Local stdio server command (desktop)',
                              helperText:
                                  'e.g. pyright-langserver --stdio, '
                                  'typescript-language-server --stdio',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: _busy || connected || _controller == null
                              ? null
                              : _spawnLocalServer,
                          icon: const Icon(Icons.terminal),
                          label: const Text('Spawn'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ConnectionBadge(state: state),
                      const SizedBox(width: 12),
                      Text(
                        'CSP connect-src allows: $_allowedOrigin',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: MonacoEditor(
                key: ValueKey('lsp-editor-$_editorGeneration'),
                page: MonacoPageConfig(allowedConnectSources: [_allowedOrigin]),
                options: const EditorOptions(
                  language: MonacoLanguage.python,
                  fontSize: 13,
                ),
                showStatusBar: true,
                onReady: (controller) => unawaited(_onEditorReady(controller)),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                itemCount: _log.length,
                itemBuilder: (context, index) => Text(
                  _log[_log.length - 1 - index],
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.state});

  final LspConnectionState? state;

  @override
  Widget build(BuildContext context) {
    final status = state?.status;
    final (color, label) = switch (status) {
      null => (Colors.grey, 'no connection'),
      LspConnectionStatus.connecting => (
        Colors.amber,
        state!.reconnectAttempt > 0
            ? 'reconnecting (#${state!.reconnectAttempt})'
            : 'connecting',
      ),
      LspConnectionStatus.open => (Colors.green, 'open'),
      LspConnectionStatus.closed => (Colors.grey, 'closed'),
      LspConnectionStatus.failed => (Colors.red, 'failed'),
    };

    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text('LSP: $label'),
      visualDensity: VisualDensity.compact,
    );
  }
}
