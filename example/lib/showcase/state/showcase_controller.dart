import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

import '../data/demo_snippets.dart';
import '../data/samples.dart';
import '../data/showcase_metadata.dart';

/// The editor theme choices exposed in the playground theme picker: the four
/// built-in Monaco themes plus one custom theme registered at runtime.
enum PlaygroundTheme {
  dark,
  light,
  hcDark,
  hcLight,
  midnight;

  String get label => switch (this) {
    PlaygroundTheme.dark => 'Dark',
    PlaygroundTheme.light => 'Light',
    PlaygroundTheme.hcDark => 'High Contrast Dark',
    PlaygroundTheme.hcLight => 'High Contrast Light',
    PlaygroundTheme.midnight => 'Midnight (custom)',
  };

  /// The Monaco theme to apply via [MonacoController.setTheme].
  MonacoTheme get monacoTheme => switch (this) {
    PlaygroundTheme.dark => MonacoTheme.vsDark,
    PlaygroundTheme.light => MonacoTheme.vs,
    PlaygroundTheme.hcDark => MonacoTheme.hcBlack,
    PlaygroundTheme.hcLight => MonacoTheme.hcLight,
    PlaygroundTheme.midnight => const MonacoTheme(kMidnightThemeId),
  };

  bool get isDark =>
      this == PlaygroundTheme.dark ||
      this == PlaygroundTheme.hcDark ||
      this == PlaygroundTheme.midnight;
}

/// One open document in the playground's tab strip. The primary tab (index 0)
/// is the document the editor booted with; demo tabs are opened at runtime
/// via [MonacoController.openDocument].
class ShowcaseDocTab {
  ShowcaseDocTab({
    required this.label,
    required this.language,
    required this.doc,
  });

  String label;
  MonacoLanguage language;
  final MonacoDocument doc;

  Uri? get uri => doc.uri;
}

/// One rendered line in the live event feed: the sealed-union case name plus
/// a short human summary of its payload.
class ShowcaseEventEntry {
  const ShowcaseEventEntry({
    required this.type,
    required this.detail,
    required this.seq,
  });

  final String type;
  final String detail;
  final int seq;
}

/// Holds all page + playground state and brokers every live change to the
/// single shared [MonacoController].
///
/// The owning [MonacoEditor] is created once with [initialEditorOptions] and
/// is never rebuilt with new options/content; instead every change is applied
/// imperatively here, which keeps the editor instance stable.
class ShowcaseController extends ChangeNotifier {
  ShowcaseController({ShowcaseMetadataLoader? metadataLoader})
    : _metadataLoader = metadataLoader ?? ShowcaseMetadataLoader();

  final ShowcaseMetadataLoader _metadataLoader;

  // --- Page state ---
  Brightness _brightness = Brightness.dark;
  Brightness get brightness => _brightness;

  ShowcaseMetadata _metadata = ShowcaseMetadata.fallback;
  ShowcaseMetadata get metadata => _metadata;

  bool _metadataLoading = false;
  bool get metadataLoading => _metadataLoading;

  /// Set by the app so feature cards can scroll the page to the playground.
  VoidCallback? onRequestScrollToPlayground;

  /// Set by the app so feature cards can scroll the page to the live diff.
  VoidCallback? onRequestScrollToDiff;

  // --- Editor state mirrors ---
  PlaygroundTheme _playgroundTheme = PlaygroundTheme.dark;
  PlaygroundTheme get playgroundTheme => _playgroundTheme;

  MonacoLanguage _language = MonacoLanguage.dart;
  MonacoLanguage get language => _language;

  bool _minimap = false;
  bool get minimap => _minimap;

  bool _wordWrap = true;
  bool get wordWrap => _wordWrap;

  bool _lineNumbers = true;
  bool get lineNumbers => _lineNumbers;

  bool _readOnly = false;
  bool get readOnly => _readOnly;

  double _fontSize = 14;
  double get fontSize => _fontSize;

  String? _hint;
  String? get hint => _hint;

  MonacoController? _editor;
  bool get isEditorReady => _editor != null;

  /// The live protocol handshake (Monaco version, protocol version, lsp/diff
  /// capability flags), populated once the editor is ready.
  MonacoCapabilities? _capabilities;
  MonacoCapabilities? get capabilities => _capabilities;

  // --- Multi-document tabs ---
  final List<ShowcaseDocTab> _tabs = [];
  List<ShowcaseDocTab> get tabs => List.unmodifiable(_tabs);

  int _activeTab = 0;
  int get activeTab => _activeTab;

  /// Uri strings of documents with unsaved edits, for the tab dirty dots.
  /// A separate listenable so per-keystroke updates don't rebuild the page.
  final ValueNotifier<Set<String>> dirtyDocs = ValueNotifier(const {});

  // --- Live event feed ---
  /// Newest-first ring buffer of decoded [MonacoEvent]s (capped at
  /// [_eventLogCap]). A separate listenable for the same reason as
  /// [dirtyDocs].
  final ValueNotifier<List<ShowcaseEventEntry>> eventLog = ValueNotifier(
    const [],
  );
  static const int _eventLogCap = 6;
  int _eventSeq = 0;

  bool _eventFeedOpen = false;
  bool get eventFeedOpen => _eventFeedOpen;

  StreamSubscription<MonacoEvent>? _eventSub;

  // --- Custom action demo ---
  int _saveCount = 0;
  int get saveCount => _saveCount;

  /// Owner key for the markers demo's diagnostics.
  static const String _demoMarkerOwner = 'showcase-demo';

  /// Decoration set backing the decorations demo; created lazily so demos
  /// can highlight lines without clobbering other decorations.
  MonacoDecorationSet? _demoDecorations;

  /// The underlying Monaco controller, available after [attachEditor].
  /// Used by [MonacoFocusGuard] for web overlay handling.
  MonacoController? get monaco => _editor;

  /// Live editor stats (cursor, line/char counts). Null until the editor is
  /// attached.
  ValueListenable<MonacoLiveStats>? get liveStats => _editor?.stats;

  /// Stable options used to create the editor widget. Computed once.
  late final EditorOptions initialEditorOptions = _buildOptions();

  /// Initial document for the editor widget.
  String get initialValue =>
      sampleFor(MonacoLanguage.dart, metadata: _metadata);

  EditorOptions _buildOptions() => EditorOptions(
    language: _language,
    theme: _playgroundTheme.isDark ? MonacoTheme.vsDark : MonacoTheme.vs,
    fontSize: _fontSize,
    wordWrap: _wordWrap ? MonacoWordWrap.on : MonacoWordWrap.off,
    minimap: MonacoMinimapOptions(enabled: _minimap),
    lineNumbers: _lineNumbers ? MonacoLineNumbers.on : MonacoLineNumbers.off,
    readOnly: _readOnly,
    scrollBeyondLastLine: false,
    padding: const MonacoPadding(top: 16, bottom: 16),
  );

  /// Called from [MonacoEditor.onReady]: registers the custom theme, the
  /// completion snippets, and the Cmd/Ctrl+S save action, wires the event
  /// feed, captures the handshake, then syncs the current theme.
  Future<void> attachEditor(MonacoController controller) async {
    _editor = controller;
    _demoDecorations = null; // Any previous set died with its controller.
    _capabilities = controller.capabilities;
    _tabs.clear();
    _activeTab = 0;
    dirtyDocs.value = const {};

    // Every decoded event is one case of the sealed MonacoEvent union; the
    // feed panel renders them as they arrive.
    unawaited(_eventSub?.cancel());
    _eventSub = controller.events.listen(_logEvent);

    try {
      await controller.defineTheme(kMidnightTheme);
      await controller.registerStaticCompletions(
        id: 'showcase-snippets',
        languages: const [
          MonacoLanguage.dart,
          MonacoLanguage.typescript,
          MonacoLanguage.javascript,
          MonacoLanguage.python,
        ],
        triggerCharacters: const ['.'],
        items: kDemoCompletions,
      );
      // Dart-defined editor action with a real keybinding (new in 3.0). It
      // also shows up in the editor's context menu and command palette.
      await controller.addAction(
        const MonacoActionDescriptor(
          id: MonacoAction('showcase.save'),
          label: 'Save (showcase demo)',
          keybindings: [MonacoKeybinding(key: MonacoKey.keyS, ctrlCmd: true)],
          contextMenuGroupId: 'navigation',
          contextMenuOrder: 1,
        ),
        _onSaveAction,
      );
      await controller.setTheme(_playgroundTheme.monacoTheme);
      // The document the editor booted with becomes the primary tab.
      final docs = await controller.listDocuments();
      if (docs.isNotEmpty) {
        _tabs.add(
          ShowcaseDocTab(
            label: _labelFor(_language),
            language: _language,
            doc: docs.first,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ShowcaseController] attachEditor failed: $e');
    }
    notifyListeners();
  }

  Future<void> loadMetadata() async {
    if (_metadataLoading) return;
    _metadataLoading = true;
    notifyListeners();
    try {
      _metadata = await _metadataLoader.load();
      final editor = _editor;
      if (editor != null && _language == MonacoLanguage.json) {
        await editor.document.setText(
          sampleFor(_language, metadata: _metadata),
        );
      }
    } catch (e) {
      debugPrint('[ShowcaseController] metadata load failed: $e');
    } finally {
      _metadataLoading = false;
      notifyListeners();
    }
  }

  // --- Page theme ---

  /// Flips the page brightness and keeps the editor theme in sync (the nav
  /// toggle controls both, per the design).
  void toggleBrightness() {
    _brightness = _brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    _playgroundTheme = _brightness == Brightness.dark
        ? PlaygroundTheme.dark
        : PlaygroundTheme.light;
    _applyTheme();
    notifyListeners();
  }

  // --- Editor theme (playground picker can override the page) ---

  void setPlaygroundTheme(PlaygroundTheme theme) {
    if (theme == _playgroundTheme) return;
    _playgroundTheme = theme;
    _applyTheme();
    notifyListeners();
  }

  void _applyTheme() {
    _editor?.setTheme(_playgroundTheme.monacoTheme);
  }

  // --- Language ---

  Future<void> setLanguage(MonacoLanguage language) async {
    if (language == _language) return;
    _language = language;
    _hint = null;
    if (_tabs.isNotEmpty) {
      final tab = _tabs[_activeTab];
      tab.language = language;
      tab.label = _labelFor(language, stem: tab.label.split('.').first);
    }
    notifyListeners();
    final editor = _editor;
    if (editor == null) return;
    await _clearDemoArtifacts(editor);
    await editor.document.setLanguage(language);
    await editor.document.setText(sampleFor(language, metadata: _metadata));
  }

  /// Removes the markers and decorations left behind by the feature demos.
  Future<void> _clearDemoArtifacts(MonacoController editor) async {
    await editor.document.clearMarkers(owner: _demoMarkerOwner);
    await _demoDecorations?.clear();
  }

  // --- Options ---

  void setMinimap(bool value) {
    _minimap = value;
    _applyOptions();
    notifyListeners();
  }

  void setWordWrap(bool value) {
    _wordWrap = value;
    _applyOptions();
    notifyListeners();
  }

  void setLineNumbers(bool value) {
    _lineNumbers = value;
    _applyOptions();
    notifyListeners();
  }

  void setReadOnly(bool value) {
    _readOnly = value;
    _applyOptions();
    notifyListeners();
  }

  void changeFontSize(double delta) {
    final next = (_fontSize + delta).clamp(10.0, 28.0);
    if (next == _fontSize) return;
    _fontSize = next;
    _applyOptions();
    notifyListeners();
  }

  void _applyOptions() {
    _editor?.updateOptions(_buildOptions());
  }

  // --- Quick actions ---

  void format() => _editor?.executeAction(MonacoAction.formatDocument);
  void find() => _editor?.executeAction(MonacoAction.find);
  void foldAll() => _editor?.executeAction(MonacoAction.foldAll);

  Future<String> currentValue() async =>
      await _editor?.document.getText() ?? '';

  Future<void> reset() async {
    final editor = _editor;
    _hint = null;
    _eventFeedOpen = false;
    notifyListeners();
    if (editor == null) return;
    await _clearDemoArtifacts(editor);
    // Close the demo tabs and return to the primary document.
    if (_tabs.length > 1) {
      final primary = _tabs.first;
      final extras = _tabs.sublist(1);
      _tabs.removeRange(1, _tabs.length);
      _activeTab = 0;
      _language = primary.language;
      notifyListeners();
      await editor.activateDocument(primary.doc);
      for (final tab in extras) {
        try {
          await tab.doc.close();
        } catch (e) {
          debugPrint('[ShowcaseController] closing ${tab.label} failed: $e');
        }
      }
    }
    dirtyDocs.value = const {};
    await editor.document.setLanguage(_language);
    await editor.document.setText(sampleFor(_language, metadata: _metadata));
  }

  /// Scrolls the page to the playground (used by feature-card "Try it" links).
  void scrollToPlayground() => onRequestScrollToPlayground?.call();

  /// Scrolls the page to the live migration diff.
  void scrollToDiff() => onRequestScrollToDiff?.call();

  // --- Multi-document tabs ---

  Future<void> activateTab(int index) async {
    final editor = _editor;
    if (editor == null || index < 0 || index >= _tabs.length) return;
    if (index == _activeTab) return;
    _activeTab = index;
    final tab = _tabs[index];
    _language = tab.language;
    notifyListeners();
    await editor.activateDocument(tab.doc);
  }

  /// Closes a demo tab (the primary tab at index 0 cannot be closed).
  Future<void> closeTab(int index) async {
    final editor = _editor;
    if (editor == null || index <= 0 || index >= _tabs.length) return;
    final tab = _tabs.removeAt(index);
    if (_activeTab == index) {
      _activeTab = 0;
      _language = _tabs.first.language;
      await editor.activateDocument(_tabs.first.doc);
    } else if (_activeTab > index) {
      _activeTab--;
    }
    final uri = tab.uri?.toString();
    if (uri != null) {
      dirtyDocs.value = {...dirtyDocs.value}..remove(uri);
    }
    notifyListeners();
    try {
      await tab.doc.close();
    } catch (e) {
      debugPrint('[ShowcaseController] closing ${tab.label} failed: $e');
    }
  }

  // --- Advanced feature demos (all drive the one editor) ---

  Future<void> runIntelliSenseDemo() async {
    await setLanguage(MonacoLanguage.dart);
    _setHint(
      'Type "pr" then press Ctrl/Cmd + Space to see custom completions.',
    );
  }

  Future<void> runJsonValidationDemo() async {
    final editor = _editor;
    _language = MonacoLanguage.json;
    notifyListeners();
    if (editor == null) return;
    await _demoDecorations?.clear();
    await editor.document.setLanguage(MonacoLanguage.json);
    await editor.document.setText(kInvalidJsonSample);
    await editor.setJsonDiagnostics(kJsonDiagnostics);
    _setHint(
      'Invalid fields are underlined - hover a squiggle for the schema '
      'error.',
    );
  }

  Future<void> runMarkersDemo() async {
    final editor = _editor;
    _language = MonacoLanguage.javascript;
    notifyListeners();
    if (editor == null) return;
    await _demoDecorations?.clear();
    await editor.document.setLanguage(MonacoLanguage.javascript);
    await editor.document.setText(kMarkersDemoCode);
    await editor.document.setMarkers([
      ...kDemoErrorMarkers,
      ...kDemoWarningMarkers,
    ], owner: _demoMarkerOwner);
    _setHint(
      'Error + warning squiggles with overview-ruler ticks - hover to '
      'read each message.',
    );
  }

  Future<void> runDecorationsDemo() async {
    final editor = _editor;
    if (editor == null) return;
    final lineCount = editor.stats.value.lineCount;
    if (lineCount <= 0) return;
    final targets = <int>[
      1,
      if (lineCount >= 3) 3,
      if (lineCount >= 5) 5,
    ].where((line) => line <= lineCount).toList();
    final decorations = _demoDecorations ??= await editor.createDecorationSet();
    await decorations.set([
      for (final line in targets)
        DecorationOptions.line(
          range: Range.lines(line, line),
          className: 'demo-line-highlight',
        ),
    ]);
    _setHint('Lines highlighted with a MonacoDecorationSet + injected CSS.');
  }

  /// Custom-action demo: focuses the editor and invites the keypress; the
  /// registered Dart callback does the rest.
  Future<void> runCustomActionDemo() async {
    final editor = _editor;
    if (editor == null) return;
    _setHint(
      'Press Cmd/Ctrl+S inside the editor - the keybinding runs a Dart '
      'callback registered with controller.addAction (also in the '
      'right-click menu as "Save (showcase demo)").',
    );
    await editor.requestFocus();
  }

  /// Multi-document demo: opens two more documents and switches to one, so
  /// the tab strip shows independent MonacoDocument handles.
  Future<void> runMultiDocumentDemo() async {
    final editor = _editor;
    if (editor == null || _tabs.isEmpty) return;
    if (_tabs.length == 1) {
      final python = await editor.openDocument(
        text: sampleFor(MonacoLanguage.python, metadata: _metadata),
        language: MonacoLanguage.python,
        uri: Uri.parse('inmemory://showcase/server.py'),
      );
      final markdown = await editor.openDocument(
        text: sampleFor(MonacoLanguage.markdown, metadata: _metadata),
        language: MonacoLanguage.markdown,
        uri: Uri.parse('inmemory://showcase/notes.md'),
      );
      _tabs.addAll([
        ShowcaseDocTab(
          label: 'server.py',
          language: MonacoLanguage.python,
          doc: python,
        ),
        ShowcaseDocTab(
          label: 'notes.md',
          language: MonacoLanguage.markdown,
          doc: markdown,
        ),
      ]);
      notifyListeners();
    }
    await activateTab(1);
    _setHint(
      'Each tab is a MonacoDocument opened with controller.openDocument - '
      'own undo stack, own language, own dirty state. Edit one and watch '
      'its tab dot.',
    );
  }

  /// Event-feed demo: opens the live feed under the editor.
  Future<void> runEventsDemo() async {
    _eventFeedOpen = true;
    _setHint(
      'Type, select, and click around - every line below is one case of '
      'the sealed MonacoEvent union from controller.events.',
    );
  }

  void closeEventFeed() {
    _eventFeedOpen = false;
    notifyListeners();
  }

  Future<void> _onSaveAction() async {
    final editor = _editor;
    if (editor == null) return;
    _saveCount++;
    final text = await editor.document.getText();
    await editor.document.markSaved();
    if (_tabs.isNotEmpty) {
      final uri = _tabs[_activeTab].uri?.toString();
      if (uri != null) {
        dirtyDocs.value = {...dirtyDocs.value}..remove(uri);
      }
    }
    _setHint(
      'Saved ${text.length} characters (save #$_saveCount). Cmd/Ctrl+S ran '
      'Dart code via controller.addAction - no JavaScript involved.',
    );
  }

  void _logEvent(MonacoEvent event) {
    final (type, detail) = switch (event) {
      MonacoContentChanged(
        :final isFlush,
        :final changes,
        :final truncated,
        :final documentUri,
      ) =>
        (
          'MonacoContentChanged',
          isFlush
              ? 'flush - whole document replaced'
              : truncated
              ? 'changes truncated (>64 KB)'
              : '${changes?.length ?? 0} change range(s)'
                    '${documentUri != null ? ' in ${_docLabel(documentUri)}' : ''}',
        ),
      MonacoSelectionChanged(:final selection) => (
        'MonacoSelectionChanged',
        switch (selection) {
          null => 'selection cleared',
          Range(:final startLine, :final startColumn)
              when selection.isCollapsed =>
            'caret at $startLine:$startColumn',
          final range =>
            '${range.startLine}:${range.startColumn} -> '
                '${range.endLine}:${range.endColumn}',
        },
      ),
      MonacoFocusChanged(:final focused) => (
        'MonacoFocusChanged',
        focused ? 'editor focused' : 'editor blurred',
      ),
      MonacoScrollHandoffEvent() => (
        'MonacoScrollHandoffEvent',
        'edge reached - scroll hands off to the page',
      ),
      MonacoUnknownEvent(:final name) => ('MonacoUnknownEvent', name),
    };

    // Tab dirty dots ride the same stream: real user edits are non-flush.
    if (event case MonacoContentChanged(
      isFlush: false,
      documentUri: final Uri uri,
    )) {
      final key = uri.toString();
      if (!dirtyDocs.value.contains(key)) {
        dirtyDocs.value = {...dirtyDocs.value, key};
      }
    }

    final next = [
      ShowcaseEventEntry(type: type, detail: detail, seq: _eventSeq++),
      ...eventLog.value,
    ];
    if (next.length > _eventLogCap) {
      next.removeRange(_eventLogCap, next.length);
    }
    eventLog.value = next;
  }

  /// Human label for a document uri: the tab label when the document is
  /// open in the tab strip (the boot model's anonymous `inmemory://model/1`
  /// would otherwise render as "1"), else the uri basename.
  String _docLabel(Uri uri) {
    for (final tab in _tabs) {
      if (tab.uri == uri) return tab.label;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? uri.toString() : segments.last;
  }

  static String _labelFor(MonacoLanguage language, {String? stem}) {
    final base = stem ?? 'main';
    final extension = switch (language) {
      MonacoLanguage.dart => 'dart',
      MonacoLanguage.typescript => 'ts',
      MonacoLanguage.javascript => 'js',
      MonacoLanguage.python => 'py',
      MonacoLanguage.json => 'json',
      MonacoLanguage.rust => 'rs',
      MonacoLanguage.go => 'go',
      MonacoLanguage.sql => 'sql',
      MonacoLanguage.yaml => 'yaml',
      MonacoLanguage.html => 'html',
      MonacoLanguage.css => 'css',
      MonacoLanguage.markdown => 'md',
      MonacoLanguage.java => 'java',
      MonacoLanguage.kotlin => 'kt',
      MonacoLanguage.swift => 'swift',
      _ => 'txt',
    };
    return '$base.$extension';
  }

  void _setHint(String message) {
    _hint = message;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_eventSub?.cancel());
    eventLog.dispose();
    dirtyDocs.dispose();
    _metadataLoader.dispose();
    super.dispose();
  }
}
