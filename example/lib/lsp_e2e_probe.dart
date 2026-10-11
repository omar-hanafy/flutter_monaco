// End-to-end LSP verification probe. NOT a demo - run by maintainers to
// prove the full loop against a real language server:
//
//   real WebView -> Monaco 0.55 -> flutterMonaco.lsp bridge -> bridged
//   transport -> LspServerProcess (pyright) -> publishDiagnostics -> markers
//
// Usage:
//   flutter run -d macos -t lib/lsp_e2e_probe.dart \
//     --dart-define=PYRIGHT_BIN=/path/to/pyright-langserver
//
// Prints PROBE_RESULT: PASS/FAIL and exits.

import 'dart:async';
import 'dart:io';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

const String _pyrightBin = String.fromEnvironment(
  'PYRIGHT_BIN',
  defaultValue: 'pyright-langserver',
);

const String _brokenPython = '''
def add(a: int, b: int) -> int:
    return a + b


result = add("not-an-int", 2)
undefined_name
''';

void main() {
  runApp(const ProbeApp());
}

class ProbeApp extends StatefulWidget {
  const ProbeApp({super.key});

  @override
  State<ProbeApp> createState() => _ProbeAppState();
}

class _ProbeAppState extends State<ProbeApp> {
  MonacoController? _controller;
  String _status = 'starting';

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  void _log(String message) {
    // ignore: avoid_print
    print('PROBE: $message');
    if (mounted) setState(() => _status = message);
  }

  Future<void> _run() async {
    try {
      _log('creating editor...');
      final controller = await MonacoController.create(
        options: const EditorOptions(language: MonacoLanguage.python),
      );
      setState(() => _controller = controller);
      _log('editor ready (Monaco ${MonacoAssets.monacoVersion})');

      final lspAvailable = await controller.evaluateJavaScript<bool>(
        '!!(window.monaco && monaco.lsp && monaco.lsp.MonacoLspClient '
        '&& window.flutterMonaco.lsp)',
      );
      _log('monaco.lsp + bridge available = $lspAvailable');
      if (lspAvailable != true) {
        return _finish(false, 'monaco.lsp namespace missing');
      }

      final document = await controller.openDocument(
        text: _brokenPython,
        language: MonacoLanguage.python,
        uri: Uri.parse('file:///probe/main.py'),
      );
      await controller.activateDocument(document);
      _log('document opened: ${document.uri}');

      _log('spawning pyright at $_pyrightBin ...');
      final server = await LspServerProcess.start(_pyrightBin, ['--stdio']);
      unawaited(
        server.exitCode.then((code) => _log('pyright exited with $code')),
      );

      final connection = await controller.connectLanguageServer(
        id: 'pyright',
        transport: server.transport,
      );
      _log('connection state = ${connection.state.status}');
      if (!connection.isOpen) {
        return _finish(false, 'connection did not open');
      }

      // Wait for pyright's publishDiagnostics to land as 'lsp' markers.
      for (var i = 0; i < 90; i++) {
        final count = await controller.evaluateJavaScript<int>(
          "monaco.editor.getModelMarkers({ owner: 'lsp' }).length",
        );
        if ((count ?? 0) > 0) {
          final messages = await controller.evaluateJavaScript<String>(
            "JSON.stringify(monaco.editor.getModelMarkers({ owner: 'lsp' })"
            '.map(m => m.message))',
          );
          _log('diagnostics arrived: $count marker(s): $messages');

          // Also prove the experimental generic notification path works.
          await connection.sendNotification(r'$/cancelRequest', {'id': 99999});
          _log('sendNotification accepted');

          _log('disconnecting...');
          await connection.disconnect();
          _log('post-disconnect state = ${connection.state.status}');
          final cleared = await controller.evaluateJavaScript<int>(
            "monaco.editor.getModelMarkers({ owner: 'lsp' }).length",
          );
          _log('markers after disconnect = $cleared');
          return _finish(
            connection.state.status == LspConnectionStatus.closed &&
                cleared == 0,
            'full LSP loop verified',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      return _finish(false, 'no LSP diagnostics within 45s');
    } catch (error, stackTrace) {
      _log('exception: $error\n$stackTrace');
      return _finish(false, '$error');
    }
  }

  void _finish(bool pass, String detail) {
    // ignore: avoid_print
    print('PROBE_RESULT: ${pass ? 'PASS' : 'FAIL'} - $detail');
    exit(pass ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('LSP E2E Probe: $_status')),
        body: _controller == null
            ? const Center(child: CircularProgressIndicator())
            : _controller!.webViewWidget,
      ),
    );
  }
}
