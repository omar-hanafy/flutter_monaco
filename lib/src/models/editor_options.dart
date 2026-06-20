import 'package:convert_object/convert_object.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_options.freezed.dart';

/// Options for configuring the Monaco Editor behavior and appearance.
@freezed
sealed class EditorOptions with _$EditorOptions {
  const factory EditorOptions({
    /// The initial syntax highlighting language.
    ///
    /// Defaults to [MonacoLanguage.dart].
    /// Changing this value on an active editor triggers a re-tokenization.
    @Default(MonacoLanguage.dart) MonacoLanguage language,

    /// The built-in Monaco color theme of the editor.
    ///
    /// Use this for Monaco's bundled themes. For custom themes registered
    /// with `MonacoController.defineTheme`, set [themeId] to the custom
    /// theme's id instead (it overrides this field when non-null).
    ///
    /// Defaults to [MonacoTheme.vsDark].
    @Default(MonacoTheme.vsDark) MonacoTheme theme,

    /// Raw Monaco theme identifier to apply.
    ///
    /// When non-null, this is used by `MonacoController.setThemeById`
    /// instead of [theme]. Intended for:
    /// - Custom themes registered with `MonacoController.defineTheme`.
    /// - Apps persisting theme selections as strings.
    ///
    /// `null` (the default) falls back to [theme].
    String? themeId,

    /// The font size in pixels.
    @Default(14) double fontSize,

    /// The font family to use.
    ///
    /// Accepts a CSS `font-family` string (e.g. "Fira Code, monospace").
    @Default('Consolas, "Courier New", monospace') String fontFamily,

    /// The line height for editor lines.
    ///
    /// - Use `0` to let Monaco compute a value from [fontSize].
    /// - Values between `0` and `8` are treated as multipliers of [fontSize]
    ///   (for example, `1.4` means 140 percent of [fontSize]).
    /// - Values `8` or greater are treated as absolute pixel values.
    @Default(1.4) double lineHeight,

    /// Controls whether long lines should wrap to the next line.
    ///
    /// If `true`, lines will wrap at the viewport width.
    @Default(true) bool wordWrap,

    /// Controls whether the minimap (code overview) is shown.
    @Default(false) bool minimap,

    /// Controls whether line numbers are displayed in the gutter.
    @Default(true) bool lineNumbers,

    /// A list of column numbers where vertical rulers should be rendered.
    ///
    /// Useful for enforcing line length limits (e.g. `[80, 120]`).
    @Default([]) List<int> rulers,

    /// The number of spaces a tab character is equal to.
    ///
    /// Also controls indentation size if [insertSpaces] is true.
    @Default(4) int tabSize,

    /// If `true`, pressing `Tab` inserts spaces instead of a tab character.
    @Default(true) bool insertSpaces,

    /// If `true`, prevents the user from editing the content.
    @Default(false) bool readOnly,

    /// If `true`, the editor will automatically resize to fit its container.
    @Default(true) bool automaticLayout,

    /// Optional padding for the editor content (top, bottom).
    Map<String, int>? padding,

    /// If `true`, allows scrolling beyond the last line of the file.
    @Default(true) bool scrollBeyondLastLine,

    /// If `true`, enables smooth scrolling animation.
    @Default(false) bool smoothScrolling,

    /// Controls the cursor blinking animation style.
    @Default(CursorBlinking.blink) CursorBlinking cursorBlinking,

    /// Controls the visual style of the cursor (line, block, etc.).
    @Default(CursorStyle.line) CursorStyle cursorStyle,

    /// Controls how whitespace characters are rendered.
    @Default(RenderWhitespace.selection) RenderWhitespace renderWhitespace,

    /// If `true`, enables colorization of matching brackets.
    @Default(true) bool bracketPairColorization,

    /// Controls automatic closing of brackets (e.g. `{` -> `{}`).
    @Default(AutoClosingBehavior.languageDefined)
    AutoClosingBehavior autoClosingBrackets,

    /// Controls automatic closing of quotes (e.g. `"` -> `""`).
    @Default(AutoClosingBehavior.languageDefined)
    AutoClosingBehavior autoClosingQuotes,

    /// If `true`, automatically formats text when pasted.
    @Default(false) bool formatOnPaste,

    /// If `true`, automatically formats text as you type.
    @Default(false) bool formatOnType,

    /// If `true`, shows the suggestion widget while typing.
    @Default(true) bool quickSuggestions,

    /// If `true`, enables font ligatures (requires a compatible font like Fira Code).
    @Default(false) bool fontLigatures,

    /// If `true`, shows parameter hints when typing function calls.
    @Default(true) bool parameterHints,

    /// If `true`, shows hover details when the mouse is over a symbol.
    @Default(true) bool hover,

    /// If `true`, enables the default context menu (right-click).
    @Default(true) bool contextMenu,

    /// If `true`, allows zooming the font size with Ctrl + Mouse Wheel.
    @Default(false) bool mouseWheelZoom,

    /// If `true`, renders selections with rounded corners.
    @Default(true) bool roundedSelection,

    /// If `true`, highlights other occurrences of the selected text.
    @Default(true) bool selectionHighlight,

    /// If `true`, draws a border around the overview ruler.
    @Default(true) bool overviewRulerBorder,

    /// If `true`, renders control characters.
    @Default(false) bool renderControlCharacters,

    /// If `true`, disables the "layer hinting" optimization.
    ///
    /// Try setting this to `true` if you see rendering artifacts on some platforms.
    @Default(false) bool disableLayerHinting,

    /// If `true`, disables monospace font optimizations.
    @Default(false) bool disableMonospaceOptimizations,
  }) = _EditorOptions;

  const EditorOptions._();

  /// Returns the Monaco theme id to apply.
  ///
  /// Returns [themeId] if non-null (custom or persisted themes), otherwise
  /// falls back to the built-in [theme]'s id.
  String get effectiveThemeId => themeId ?? theme.id;

  factory EditorOptions.fromJson(Map<String, dynamic> json) {
    // Accept legacy single-field `theme` values (id strings) by detecting
    // built-in ids vs custom ids. Built-in ids round-trip via [theme];
    // unrecognized ids load into [themeId] so custom themes survive
    // persistence. When both fields are present, keep `theme` as the built-in
    // fallback and use `themeId` as the raw override.
    final builtInIds = MonacoTheme.values.map((value) => value.id).toSet();
    final rawBuiltInTheme = json.tryGetString('theme');
    final rawThemeId = json.tryGetString('themeId');
    final legacyCustomThemeId =
        rawThemeId == null && !builtInIds.contains(rawBuiltInTheme)
        ? rawBuiltInTheme
        : null;

    return EditorOptions(
      language: MonacoLanguage.fromId(
        json.getString('language', defaultValue: 'markdown'),
      ),
      theme: MonacoTheme.fromId(rawBuiltInTheme, orElse: MonacoTheme.vsDark),
      themeId: rawThemeId ?? legacyCustomThemeId,
      fontSize: json.getDouble('fontSize', defaultValue: 14),
      fontFamily: json.getString(
        'fontFamily',
        defaultValue: 'Consolas, "Courier New", monospace',
      ),
      lineHeight: json.getDouble('lineHeight', defaultValue: 1.4),
      wordWrap: json.getBool('wordWrap', defaultValue: true),
      minimap: json.getBool('minimap', defaultValue: false),
      lineNumbers: json.getBool('lineNumbers', defaultValue: true),
      rulers: json.getList<int>('rulers', defaultValue: []),
      tabSize: json.getInt('tabSize', defaultValue: 4),
      insertSpaces: json.getBool('insertSpaces', defaultValue: true),
      readOnly: json.getBool('readOnly', defaultValue: false),
      automaticLayout: json.getBool('automaticLayout', defaultValue: true),
      padding: json.tryGetMap<String, int>('padding'),
      scrollBeyondLastLine: json.getBool(
        'scrollBeyondLastLine',
        defaultValue: true,
      ),
      smoothScrolling: json.getBool('smoothScrolling', defaultValue: false),
      cursorBlinking: CursorBlinking.fromId(
        json.getString('cursorBlinking', defaultValue: 'blink'),
      ),
      cursorStyle: CursorStyle.fromId(
        json.getString('cursorStyle', defaultValue: 'line'),
      ),
      renderWhitespace: RenderWhitespace.fromId(
        json.getString('renderWhitespace', defaultValue: 'selection'),
      ),
      bracketPairColorization: json.getBool(
        'bracketPairColorization',
        defaultValue: true,
      ),
      autoClosingBrackets: AutoClosingBehavior.fromId(
        json.getString('autoClosingBrackets', defaultValue: 'languageDefined'),
      ),
      autoClosingQuotes: AutoClosingBehavior.fromId(
        json.getString('autoClosingQuotes', defaultValue: 'languageDefined'),
      ),
      formatOnPaste: json.getBool('formatOnPaste', defaultValue: false),
      formatOnType: json.getBool('formatOnType', defaultValue: false),
      quickSuggestions: json.getBool('quickSuggestions', defaultValue: true),
      fontLigatures: json.getBool('fontLigatures', defaultValue: false),
      parameterHints: json.getBool('parameterHints', defaultValue: true),
      hover: json.getBool('hover', defaultValue: true),
      contextMenu: json.getBool('contextMenu', defaultValue: true),
      mouseWheelZoom: json.getBool('mouseWheelZoom', defaultValue: false),
      roundedSelection: json.getBool('roundedSelection', defaultValue: true),
      selectionHighlight: json.getBool(
        'selectionHighlight',
        defaultValue: true,
      ),
      overviewRulerBorder: json.getBool(
        'overviewRulerBorder',
        defaultValue: true,
      ),
      renderControlCharacters: json.getBool(
        'renderControlCharacters',
        defaultValue: false,
      ),
      disableLayerHinting: json.getBool(
        'disableLayerHinting',
        defaultValue: false,
      ),
      disableMonospaceOptimizations: json.getBool(
        'disableMonospaceOptimizations',
        defaultValue: false,
      ),
    );
  }

  /// Convert to Monaco editor options format
  Map<String, dynamic> toMonacoOptions() {
    final int? lineHeightPx = lineHeight <= 0
        ? null
        : (lineHeight < 8
              ? (fontSize * lineHeight).round()
              : lineHeight.round());

    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': ?lineHeightPx,
      'wordWrap': wordWrap ? 'on' : 'off',
      'minimap': {'enabled': minimap},
      'lineNumbers': lineNumbers ? 'on' : 'off',
      'rulers': rulers,
      'tabSize': tabSize,
      'insertSpaces': insertSpaces,
      'readOnly': readOnly,
      'automaticLayout': automaticLayout,
      if (padding != null) 'padding': padding,
      'scrollBeyondLastLine': scrollBeyondLastLine,
      'smoothScrolling': smoothScrolling,
      'cursorBlinking': cursorBlinking.id,
      'cursorStyle': cursorStyle.id,
      'renderWhitespace': renderWhitespace.id,
      'bracketPairColorization': {'enabled': bracketPairColorization},
      'autoClosingBrackets': autoClosingBrackets.id,
      'autoClosingQuotes': autoClosingQuotes.id,
      'formatOnPaste': formatOnPaste,
      'formatOnType': formatOnType,
      'quickSuggestions': quickSuggestions,
      'fontLigatures': fontLigatures,
      'parameterHints': {'enabled': parameterHints},
      'hover': {'enabled': hover},
      'contextmenu': contextMenu,
      'mouseWheelZoom': mouseWheelZoom,
      'roundedSelection': roundedSelection,
      'selectionHighlight': selectionHighlight,
      'overviewRulerBorder': overviewRulerBorder,
      'renderControlCharacters': renderControlCharacters,
      'disableLayerHinting': disableLayerHinting,
      'disableMonospaceOptimizations': disableMonospaceOptimizations,
    };
  }
}
