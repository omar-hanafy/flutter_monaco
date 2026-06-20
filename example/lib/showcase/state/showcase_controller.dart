import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

import '../data/demo_snippets.dart';
import '../data/samples.dart';

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

  /// The Monaco theme id to apply via [MonacoController.setThemeById].
  String get monacoId => switch (this) {
        PlaygroundTheme.dark => MonacoTheme.vsDark.id,
        PlaygroundTheme.light => MonacoTheme.vs.id,
        PlaygroundTheme.hcDark => MonacoTheme.hcBlack.id,
        PlaygroundTheme.hcLight => MonacoTheme.hcLight.id,
        PlaygroundTheme.midnight => kMidnightThemeId,
      };

  bool get isDark =>
      this == PlaygroundTheme.dark ||
      this == PlaygroundTheme.hcDark ||
      this == PlaygroundTheme.midnight;
}

/// Holds all page + playground state and brokers every live change to the
/// single shared [MonacoController].
///
/// The owning [MonacoEditor] is created once with [initialEditorOptions] and
/// is never rebuilt with new options/content; instead every change is applied
/// imperatively here, which keeps the editor instance stable.
class ShowcaseController extends ChangeNotifier {
  // --- Page state ---
  Brightness _brightness = Brightness.dark;
  Brightness get brightness => _brightness;

  /// Set by the app so feature cards can scroll the page to the playground.
  VoidCallback? onRequestScrollToPlayground;

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

  /// The underlying Monaco controller, available after [attachEditor].
  /// Used by [MonacoFocusGuard] for web overlay handling.
  MonacoController? get monaco => _editor;

  /// Live editor stats (cursor, line/char counts). Null until the editor is
  /// attached.
  ValueListenable<LiveStats>? get liveStats => _editor?.liveStats;

  /// Stable options used to create the editor widget. Computed once.
  late final EditorOptions initialEditorOptions = _buildOptions();

  /// Initial document for the editor widget.
  String get initialValue => sampleFor(MonacoLanguage.dart);

  EditorOptions _buildOptions() => EditorOptions(
        language: _language,
        theme: _playgroundTheme.isDark ? MonacoTheme.vsDark : MonacoTheme.vs,
        fontSize: _fontSize,
        wordWrap: _wordWrap,
        minimap: _minimap,
        lineNumbers: _lineNumbers,
        readOnly: _readOnly,
        automaticLayout: true,
        scrollBeyondLastLine: false,
        padding: const {'top': 16, 'bottom': 16},
      );

  /// Called from [MonacoEditor.onReady]: registers the custom theme and
  /// completion snippets, then syncs the current theme.
  Future<void> attachEditor(MonacoController controller) async {
    _editor = controller;
    try {
      await controller.defineTheme(kMidnightTheme);
      await controller.registerStaticCompletions(
        id: 'showcase-snippets',
        languages: const ['dart', 'typescript', 'javascript', 'python'],
        triggerCharacters: const ['.'],
        items: kDemoCompletions,
      );
      await controller.setThemeById(_playgroundTheme.monacoId);
    } catch (e) {
      debugPrint('[ShowcaseController] attachEditor failed: $e');
    }
    notifyListeners();
  }

  // --- Page theme ---

  /// Flips the page brightness and keeps the editor theme in sync (the nav
  /// toggle controls both, per the design).
  void toggleBrightness() {
    _brightness =
        _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
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
    _editor?.setThemeById(_playgroundTheme.monacoId);
  }

  // --- Language ---

  Future<void> setLanguage(MonacoLanguage language) async {
    if (language == _language) return;
    _language = language;
    _hint = null;
    notifyListeners();
    final editor = _editor;
    if (editor == null) return;
    await editor.clearAllMarkers();
    await editor.clearDecorations();
    await editor.setLanguage(language);
    await editor.setValue(sampleFor(language));
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

  void format() => _editor?.format();
  void find() => _editor?.find();
  void foldAll() => _editor?.foldAll();

  Future<String> currentValue() async => await _editor?.getValue() ?? '';

  Future<void> reset() async {
    final editor = _editor;
    _hint = null;
    notifyListeners();
    if (editor == null) return;
    await editor.clearAllMarkers();
    await editor.clearDecorations();
    await editor.setLanguage(_language);
    await editor.setValue(sampleFor(_language));
  }

  /// Scrolls the page to the playground (used by feature-card "Try it" links).
  void scrollToPlayground() => onRequestScrollToPlayground?.call();

  // --- Advanced feature demos (all drive the one editor) ---

  Future<void> runIntelliSenseDemo() async {
    await setLanguage(MonacoLanguage.dart);
    _setHint(
        'Type "pr" then press Ctrl/Cmd + Space to see custom completions.');
  }

  Future<void> runJsonValidationDemo() async {
    final editor = _editor;
    _language = MonacoLanguage.json;
    notifyListeners();
    if (editor == null) return;
    await editor.clearDecorations();
    await editor.setLanguage(MonacoLanguage.json);
    await editor.setValue(kInvalidJsonSample);
    await editor.setJsonDiagnostics(kJsonDiagnostics);
    _setHint('Invalid fields are underlined - hover a squiggle for the schema '
        'error.');
  }

  Future<void> runMarkersDemo() async {
    final editor = _editor;
    _language = MonacoLanguage.javascript;
    notifyListeners();
    if (editor == null) return;
    await editor.clearDecorations();
    await editor.setLanguage(MonacoLanguage.javascript);
    await editor.setValue(kMarkersDemoCode);
    await editor.setErrorMarkers(kDemoErrorMarkers);
    await editor.setWarningMarkers(kDemoWarningMarkers);
    _setHint('Error + warning squiggles with overview-ruler ticks - hover to '
        'read each message.');
  }

  Future<void> runDecorationsDemo() async {
    final editor = _editor;
    if (editor == null) return;
    final lineCount = editor.liveStats.value.lineCount.value;
    if (lineCount <= 0) return;
    final targets = <int>[
      1,
      if (lineCount >= 3) 3,
      if (lineCount >= 5) 5,
    ].where((line) => line <= lineCount).toList();
    await editor.clearDecorations();
    await editor.addLineDecorations(targets, 'demo-line-highlight');
    _setHint('Lines highlighted with setDecorations + injected CSS.');
  }

  void _setHint(String message) {
    _hint = message;
    notifyListeners();
  }
}
