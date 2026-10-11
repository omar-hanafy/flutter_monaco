import 'dart:async';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

import 'monaco_observer.dart';

/// One editor, many documents - the v3 multi-document workflow.
///
/// The editor is a viewport; documents are Monaco models you open, switch,
/// and edit independently:
///
/// - [MonacoController.openDocument] opens each file once with a stable
///   `file:///` URI (language servers key diagnostics on these URIs).
/// - [MonacoController.activateDocument] switches the visible document;
///   every document keeps its own undo stack.
/// - Pinned [MonacoDocument] handles edit their model even while another
///   document is on screen (see the "log to notes" action).
/// - [MonacoController.listDocuments] enumerates everything that is open.
class MultiEditorExample extends StatefulWidget {
  const MultiEditorExample({super.key});

  @override
  State<MultiEditorExample> createState() => _MultiEditorExampleState();
}

class _DemoFile {
  const _DemoFile({
    required this.name,
    required this.language,
    required this.icon,
    required this.color,
    required this.content,
  });

  final String name;
  final MonacoLanguage language;
  final IconData icon;
  final Color color;
  final String content;

  /// Stable file-like URI: this is what language servers and
  /// [MonacoController.documentByUri] key on.
  Uri get uri => Uri.parse('file:///demo/$name');
}

class _MultiEditorExampleState extends State<MultiEditorExample> {
  static const List<_DemoFile> _files = [
    _DemoFile(
      name: 'main.dart',
      language: MonacoLanguage.dart,
      icon: Icons.flutter_dash,
      color: Colors.blue,
      content: _dartCode,
    ),
    _DemoFile(
      name: 'app.js',
      language: MonacoLanguage.javascript,
      icon: Icons.javascript,
      color: Colors.orange,
      content: _jsCode,
    ),
    _DemoFile(
      name: 'NOTES.md',
      language: MonacoLanguage.markdown,
      icon: Icons.notes,
      color: Colors.green,
      content: _markdownContent,
    ),
  ];

  MonacoController? _controller;

  /// Pinned handles from [MonacoController.openDocument], keyed by URI.
  final Map<Uri, MonacoDocument> _documents = {};

  /// Live dirty flags, driven by [MonacoController.onContentChanged].
  final Map<Uri, bool> _dirty = {};

  StreamSubscription<MonacoContentChanged>? _contentChanges;
  int _activeIndex = 0;
  String? _error;

  Future<void> _onReady(MonacoController controller) async {
    try {
      // Open every file as its own document. Opening does not activate.
      for (final file in _files) {
        _documents[file.uri] = await controller.openDocument(
          text: file.content,
          language: file.language,
          uri: file.uri,
        );
      }
      await controller.activateDocument(_documents[_files.first.uri]!);

      // Drop the editor's initial scratch model so listDocuments shows
      // exactly our three files.
      for (final doc in await controller.listDocuments()) {
        if (!_documents.containsKey(doc.uri)) {
          await doc.close();
        }
      }

      // Content changes carry the document URI, so one stream can keep
      // per-tab dirty markers accurate.
      _contentChanges = controller.onContentChanged.listen((event) async {
        final uri = event.documentUri;
        final document = _documents[uri];
        if (document == null) return;
        final dirty = await document.isDirty();
        if (mounted) setState(() => _dirty[uri!] = dirty);
      });

      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _contentChanges?.cancel();
    // The MonacoEditor widget owns and disposes the controller it created.
    super.dispose();
  }

  Future<void> _activate(int index) async {
    final controller = _controller;
    if (controller == null || index == _activeIndex) return;
    await controller.activateDocument(_documents[_files[index].uri]!);
    if (mounted) setState(() => _activeIndex = index);
  }

  /// Appends a line to NOTES.md through its pinned handle - no activation
  /// needed; the edit lands even while another document is visible.
  Future<void> _logToNotes() async {
    final notes = _documents[_files.last.uri];
    if (notes == null || !mounted) return;
    final activeName = _files[_activeIndex].name;
    final time = TimeOfDay.now().format(context);
    final lastLine = await notes.lineCount();
    final lastLineText = await notes.lineAt(lastLine);
    await notes.insert(
      Position(line: lastLine, column: lastLineText.length + 1),
      '\n- [$time] logged from $activeName',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appended to NOTES.md (switch tabs to see it)'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          width: 340,
        ),
      );
    }
  }

  Future<void> _markActiveSaved() async {
    final file = _files[_activeIndex];
    final document = _documents[file.uri];
    if (document == null) return;
    await document.markSaved();
    if (mounted) setState(() => _dirty[file.uri] = false);
  }

  /// Shows everything the controller has open, straight from
  /// [MonacoController.listDocuments].
  Future<void> _showOpenDocuments() async {
    final controller = _controller;
    if (controller == null) return;
    final documents = await controller.listDocuments();
    final rows = <({String uri, String detail, bool dirty})>[];
    for (final doc in documents) {
      final language = await doc.getLanguage();
      final lines = await doc.lineCount();
      final dirty = await doc.isDirty();
      rows.add((
        uri: '${doc.uri}',
        detail: '${language.id} - $lines lines',
        dirty: dirty,
      ));
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open documents (${rows.length})'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final row in rows)
                ListTile(
                  dense: true,
                  leading: Icon(
                    row.dirty ? Icons.circle : Icons.description_outlined,
                    size: row.dirty ? 12 : 20,
                    color: row.dirty ? Colors.amber : null,
                  ),
                  title: Text(row.uri),
                  subtitle: Text(
                    row.dirty ? '${row.detail} - unsaved' : row.detail,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return MonacoScaffold(
      appBar: AppBar(
        title: const Text('Multi-Document Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Append a line to NOTES.md in the background',
            onPressed: controller == null ? null : _logToNotes,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Mark active document saved',
            onPressed: controller == null ? null : _markActiveSaved,
          ),
        ],
      ),
      body: Column(
        children: [
          // Keep Flutter dialogs/menus clickable over the editor on Web.
          if (controller != null)
            MonacoFocusGuard(
              controller: controller,
              modalRouteObserver: monacoRouteObserver,
            ),
          _buildTabBar(),
          if (_error != null)
            MaterialBanner(
              content: Text('Failed to open documents: $_error'),
              backgroundColor: Colors.red.shade100,
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            child: MonacoEditor(
              options: const EditorOptions(
                theme: MonacoTheme.vsDark,
                minimap: MonacoMinimapOptions(enabled: true),
              ),
              showStatusBar: true,
              onReady: (c) => unawaited(_onReady(c)),
            ),
          ),
        ],
      ),
      // MonacoScaffold wraps this in a MonacoOverlayBoundary on Web so the
      // underlying Monaco iframe does not swallow the click.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller == null ? null : _showOpenDocuments,
        label: const Text('Open Documents'),
        icon: const Icon(Icons.folder_open),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      color: const Color(0xFF252526),
      child: Row(
        children: [
          for (var i = 0; i < _files.length; i++)
            _buildTab(_files[i], index: i, active: i == _activeIndex),
          const Spacer(),
          if (_controller == null)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(_DemoFile file, {required int index, required bool active}) {
    final dirty = _dirty[file.uri] ?? false;
    return InkWell(
      onTap: _controller == null ? null : () => unawaited(_activate(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E1E1E) : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: active ? file.color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(file.icon, size: 16, color: file.color),
            const SizedBox(width: 8),
            Text(
              file.name,
              style: TextStyle(
                color: active ? Colors.white : Colors.white60,
                fontSize: 13,
              ),
            ),
            if (dirty) ...[
              const SizedBox(width: 6),
              const Icon(Icons.circle, size: 8, color: Colors.amber),
            ],
          ],
        ),
      ),
    );
  }

  static const String _dartCode = '''
// main.dart - opened as file:///demo/main.dart
import 'package:material_ui/material_ui.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('One editor, many documents')),
      ),
    );
  }
}
''';

  static const String _jsCode = '''
// app.js - opened as file:///demo/app.js
export function counter(start = 0) {
  let count = start;
  return {
    increment: () => ++count,
    decrement: () => Math.max(0, --count),
    get value() { return count; },
  };
}

const demo = counter();
demo.increment();
console.log(`count is now \${demo.value}`);
''';

  static const String _markdownContent = '''
# Multi-Document Notes

All three tabs share **one** Monaco editor. Each tab is a document opened
with `controller.openDocument(text: ..., language: ..., uri: ...)`.

Try it:

- Edit a file, switch tabs, switch back: undo history survives.
- Watch the amber dot appear on edited tabs (`onContentChanged` +
  `document.isDirty()`).
- Press the note icon in the app bar while another tab is active: the
  pinned `MonacoDocument` handle writes here in the background.
- Press "Open Documents" to see `listDocuments()`.

## Log
''';
}
