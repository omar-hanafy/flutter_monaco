// MonacoDiffEditor demo (Phase 11): original vs modified with a language
// picker and a side-by-side / inline toggle.
//
// Run with: flutter run -d macos -t lib/diff_example.dart

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

const _originalDart = '''
class Greeter {
  Greeter(this.name);

  final String name;

  void greet() {
    print('Hello, \$name!');
  }
}

void main() {
  Greeter('world').greet();
}
''';

const _modifiedDart = '''
class Greeter {
  Greeter(this.name, {this.excited = false});

  final String name;
  final bool excited;

  void greet() {
    final punctuation = excited ? '!!!' : '.';
    print('Hello, \$name\$punctuation');
  }
}

void main() {
  Greeter('world', excited: true).greet();
}
''';

const _originalJson = '''
{
  "name": "flutter_monaco",
  "version": "2.3.0",
  "features": ["editor", "lsp"]
}
''';

const _modifiedJson = '''
{
  "name": "flutter_monaco",
  "version": "3.0.0",
  "features": ["editor", "lsp", "diff", "custom-actions"],
  "protocol": 3
}
''';

void main() {
  runApp(const DiffExampleApp());
}

/// Standalone entrypoint for the diff editor demo.
class DiffExampleApp extends StatelessWidget {
  /// Creates the demo app.
  const DiffExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monaco Diff Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const DiffExamplePage(),
    );
  }
}

/// The demo page: diff editor plus language and layout controls.
class DiffExamplePage extends StatefulWidget {
  /// Creates the demo page.
  const DiffExamplePage({super.key});

  @override
  State<DiffExamplePage> createState() => _DiffExamplePageState();
}

class _DiffExamplePageState extends State<DiffExamplePage> {
  MonacoDiffController? _controller;
  MonacoLanguage _language = MonacoLanguage.dart;
  bool _sideBySide = true;

  (String, String) get _texts => _language == MonacoLanguage.dart
      ? (_originalDart, _modifiedDart)
      : (_originalJson, _modifiedJson);

  @override
  Widget build(BuildContext context) {
    final (original, modified) = _texts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monaco Diff Editor'),
        actions: [
          DropdownButton<MonacoLanguage>(
            value: _language,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: MonacoLanguage.dart, child: Text('Dart')),
              DropdownMenuItem(value: MonacoLanguage.json, child: Text('JSON')),
            ],
            onChanged: (language) {
              if (language != null) setState(() => _language = language);
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(_sideBySide ? Icons.view_column : Icons.view_agenda),
            tooltip: _sideBySide
                ? 'Switch to inline'
                : 'Switch to side by side',
            onPressed: () => setState(() => _sideBySide = !_sideBySide),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: 'Previous change',
            onPressed: () => _controller?.revealPreviousChange(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Next change',
            onPressed: () => _controller?.revealNextChange(),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Print modified text',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final text = await _controller?.getModifiedText();
              final changes = await _controller?.getLineChangeCount();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Modified: ${text?.length ?? 0} chars, '
                    '$changes changed block(s)',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: MonacoDiffEditor(
          original: original,
          modified: modified,
          language: _language,
          diffOptions: MonacoDiffOptions(renderSideBySide: _sideBySide),
          onReady: (controller) => _controller = controller,
        ),
      ),
    );
  }
}
