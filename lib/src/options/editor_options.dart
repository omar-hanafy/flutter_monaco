/// @docImport 'package:flutter_monaco/src/editor/controller.dart';
library;

import 'package:flutter_monaco/src/options/language.dart';
import 'package:flutter_monaco/src/options/option_enums.dart';
import 'package:flutter_monaco/src/options/sub_options.dart';
import 'package:flutter_monaco/src/options/theme.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_options.freezed.dart';

/// Configuration for the Monaco editor.
///
/// Every field is nullable and `null` means "unset": the field is omitted
/// from the payload sent to Monaco, so Monaco's own default (or the value a
/// previous [MonacoController.updateOptions] call applied) stays in effect.
/// This makes updates sparse: `updateOptions(EditorOptions(fontSize: 16))`
/// changes only the font size.
///
/// At boot, the `MonacoEditor` widget and `MonacoController.create` merge
/// the curated `MonacoDefaults.editorOptions` under the caller's options,
/// so an empty `EditorOptions()` still produces a fully configured editor.
@freezed
sealed class EditorOptions with _$EditorOptions {
  /// Creates a sparse editor configuration; `null` fields are unset.
  const factory EditorOptions({
    /// Initial document language. Only consumed at boot (the `page.boot`
    /// command); use `controller.document.setLanguage` on a live editor.
    MonacoLanguage? language,

    /// Editor theme. When `null`, the `MonacoEditor` widget resolves a
    /// theme from `Theme.of(context).brightness`; a headless
    /// `MonacoController.create` falls back to `MonacoDefaults.darkTheme`.
    /// Custom themes registered with `defineTheme` are selected by their
    /// id: `MonacoTheme('app-dark')`.
    MonacoTheme? theme,

    /// Font size in pixels.
    double? fontSize,

    /// CSS `font-family` string (e.g. `'Fira Code, monospace'`).
    String? fontFamily,

    /// Whether font ligatures render (requires a compatible font).
    bool? fontLigatures,

    /// Line height. `0` lets Monaco compute from [fontSize]; values below
    /// `8` are multipliers of the font size; `8` and above are absolute
    /// pixels (Monaco's own semantics - the value is passed through).
    double? lineHeight,

    /// Letter spacing in pixels.
    double? letterSpacing,

    /// Width used to render full-width (e.g. CJK) characters. Monaco
    /// defaults to [MonacoFullwidthCharacterWidth.font];
    /// [MonacoFullwidthCharacterWidth.twoCells] keeps columns aligned in
    /// monospace fonts. Added in Monaco 0.57.
    MonacoFullwidthCharacterWidth? fullwidthCharacterWidth,

    /// Word wrapping behavior.
    MonacoWordWrap? wordWrap,

    /// Wrap column used by [MonacoWordWrap.wordWrapColumn] and
    /// [MonacoWordWrap.bounded].
    int? wordWrapColumn,

    /// Whether an indicator is rendered at the wrapping column of
    /// soft-wrapped lines. Only has an effect while [wordWrap] wraps lines.
    /// With viewport wrapping ([MonacoWordWrap.on] and
    /// [MonacoWordWrap.bounded]) Monaco reserves the rightmost column for
    /// the indicator, so lines wrap one column earlier. Monaco defaults to
    /// `false`. Added in Monaco 0.57.
    bool? wordWrapIndicator,

    /// Minimap (code overview strip) configuration.
    MonacoMinimapOptions? minimap,

    /// Line number rendering in the gutter.
    MonacoLineNumbers? lineNumbers,

    /// Column positions of vertical rulers (e.g. `[80, 120]`).
    List<int>? rulers,

    /// Number of spaces a tab is equal to.
    int? tabSize,

    /// Whether `Tab` inserts spaces instead of a tab character.
    bool? insertSpaces,

    /// Whether Monaco detects indentation from file contents.
    bool? detectIndentation,

    /// Whether the document is read-only.
    bool? readOnly,

    /// Message shown when the user tries to edit a read-only document.
    String? readOnlyMessage,

    /// Whether the editor resizes itself with its container.
    bool? automaticLayout,

    /// Content padding.
    MonacoPadding? padding,

    /// Scrollbar configuration.
    MonacoScrollbarOptions? scrollbar,

    /// Whether scrolling can go beyond the last line.
    bool? scrollBeyondLastLine,

    /// Whether scrolling animates.
    bool? smoothScrolling,

    /// Whether Ctrl/Cmd + mouse wheel zooms the font.
    bool? mouseWheelZoom,

    /// Cursor blinking animation.
    CursorBlinking? cursorBlinking,

    /// Cursor shape.
    CursorStyle? cursorStyle,

    /// Cursor width in pixels (for [CursorStyle.line]).
    int? cursorWidth,

    /// Whitespace character rendering.
    RenderWhitespace? renderWhitespace,

    /// Whether control characters render.
    bool? renderControlCharacters,

    /// Current-line highlight rendering.
    MonacoLineHighlight? renderLineHighlight,

    /// Whether matching brackets get per-pair colors.
    bool? bracketPairColorization,

    /// Bracket-pair and indentation guide rendering.
    MonacoGuidesOptions? guides,

    /// Automatic closing of brackets.
    AutoClosingBehavior? autoClosingBrackets,

    /// Automatic closing of quotes.
    AutoClosingBehavior? autoClosingQuotes,

    /// Whether pasted text is formatted.
    bool? formatOnPaste,

    /// Whether text formats as you type.
    bool? formatOnType,

    /// Whether the suggestion widget appears while typing.
    bool? quickSuggestions,

    /// Whether suggestions appear on trigger characters (e.g. `.`).
    bool? suggestOnTriggerCharacters,

    /// Whether parameter hints appear in call sites.
    bool? parameterHints,

    /// Whether hover tooltips appear. Sent as Monaco's `hover.enabled`
    /// `'on'`/`'off'`; for `'onKeyboardModifier'` or other hover settings
    /// use [extra] (e.g. `{'hover': {'enabled': 'onKeyboardModifier'}}`).
    bool? hover,

    /// Whether the right-click context menu is enabled.
    bool? contextMenu,

    /// Whether other occurrences of the selection are highlighted.
    bool? selectionHighlight,

    /// Whether symbol occurrences are highlighted semantically.
    bool? occurrencesHighlight,

    /// Whether selections render with rounded corners.
    bool? roundedSelection,

    /// Whether double-clicking just inside a bracket or quote selects the
    /// enclosed content instead of the word under the pointer. On by
    /// default since Monaco 0.56; set `false` to keep plain word selection.
    bool? doubleClickSelectsBlock,

    /// Whether code folding is enabled.
    bool? folding,

    /// When the folding controls in the gutter are visible.
    MonacoFoldingControls? showFoldingControls,

    /// Whether links in the document are clickable.
    bool? links,

    /// Find widget behavior.
    MonacoFindOptions? find,

    /// Sticky scroll (pinned enclosing scopes) configuration.
    MonacoStickyScroll? stickyScroll,

    /// Whether the overview ruler draws a border.
    bool? overviewRulerBorder,

    /// Disables the layer-hinting render optimization (try `true` if you
    /// see rendering artifacts on some platforms).
    bool? disableLayerHinting,

    /// Disables monospace font optimizations.
    bool? disableMonospaceOptimizations,

    /// Raw Monaco options merged LAST into the payload; keys here win over
    /// every modeled field. The permanent escape hatch for anything not
    /// modeled above.
    Map<String, Object?>? extra,
  }) = _EditorOptions;

  const EditorOptions._();

  /// Parses options produced by [toJson].
  ///
  /// Strict: unknown keys and wrongly-typed values throw a
  /// [FormatException]. `language`/`theme` accept any string (open typed
  /// ids); enum fields require exact Monaco id strings.
  factory EditorOptions.fromJson(Map<String, dynamic> json) {
    const knownKeys = {
      'language',
      'theme',
      'fontSize',
      'fontFamily',
      'fontLigatures',
      'lineHeight',
      'letterSpacing',
      'fullwidthCharacterWidth',
      'wordWrap',
      'wordWrapColumn',
      'wordWrapIndicator',
      'minimap',
      'lineNumbers',
      'rulers',
      'tabSize',
      'insertSpaces',
      'detectIndentation',
      'readOnly',
      'readOnlyMessage',
      'automaticLayout',
      'padding',
      'scrollbar',
      'scrollBeyondLastLine',
      'smoothScrolling',
      'mouseWheelZoom',
      'cursorBlinking',
      'cursorStyle',
      'cursorWidth',
      'renderWhitespace',
      'renderControlCharacters',
      'renderLineHighlight',
      'bracketPairColorization',
      'guides',
      'autoClosingBrackets',
      'autoClosingQuotes',
      'formatOnPaste',
      'formatOnType',
      'quickSuggestions',
      'suggestOnTriggerCharacters',
      'parameterHints',
      'hover',
      'contextMenu',
      'selectionHighlight',
      'occurrencesHighlight',
      'roundedSelection',
      'doubleClickSelectsBlock',
      'folding',
      'showFoldingControls',
      'links',
      'find',
      'stickyScroll',
      'overviewRulerBorder',
      'disableLayerHinting',
      'disableMonospaceOptimizations',
      'extra',
    };
    for (final key in json.keys) {
      if (!knownKeys.contains(key)) {
        throw FormatException('EditorOptions.fromJson: unknown key "$key"');
      }
    }

    final rawLanguage = _optString(json, 'language');
    final rawTheme = _optString(json, 'theme');
    return EditorOptions(
      language: rawLanguage == null ? null : MonacoLanguage(rawLanguage),
      theme: rawTheme == null ? null : MonacoTheme(rawTheme),
      fontSize: _optDouble(json, 'fontSize'),
      fontFamily: _optString(json, 'fontFamily'),
      fontLigatures: _optBool(json, 'fontLigatures'),
      lineHeight: _optDouble(json, 'lineHeight'),
      letterSpacing: _optDouble(json, 'letterSpacing'),
      fullwidthCharacterWidth: _optEnum(
        json,
        'fullwidthCharacterWidth',
        MonacoFullwidthCharacterWidth.values,
        (e) => e.id,
      ),
      wordWrap: _optEnum(json, 'wordWrap', MonacoWordWrap.values, (e) => e.id),
      wordWrapColumn: _optInt(json, 'wordWrapColumn'),
      wordWrapIndicator: _optBool(json, 'wordWrapIndicator'),
      minimap: _optSub(json, 'minimap', MonacoMinimapOptions.fromJson),
      lineNumbers: _optEnum(
        json,
        'lineNumbers',
        MonacoLineNumbers.values,
        (e) => e.id,
      ),
      rulers: _optIntList(json, 'rulers'),
      tabSize: _optInt(json, 'tabSize'),
      insertSpaces: _optBool(json, 'insertSpaces'),
      detectIndentation: _optBool(json, 'detectIndentation'),
      readOnly: _optBool(json, 'readOnly'),
      readOnlyMessage: _optString(json, 'readOnlyMessage'),
      automaticLayout: _optBool(json, 'automaticLayout'),
      padding: _optSub(json, 'padding', MonacoPadding.fromJson),
      scrollbar: _optSub(json, 'scrollbar', MonacoScrollbarOptions.fromJson),
      scrollBeyondLastLine: _optBool(json, 'scrollBeyondLastLine'),
      smoothScrolling: _optBool(json, 'smoothScrolling'),
      mouseWheelZoom: _optBool(json, 'mouseWheelZoom'),
      cursorBlinking: _optEnum(
        json,
        'cursorBlinking',
        CursorBlinking.values,
        (e) => e.id,
      ),
      cursorStyle: _optEnum(
        json,
        'cursorStyle',
        CursorStyle.values,
        (e) => e.id,
      ),
      cursorWidth: _optInt(json, 'cursorWidth'),
      renderWhitespace: _optEnum(
        json,
        'renderWhitespace',
        RenderWhitespace.values,
        (e) => e.id,
      ),
      renderControlCharacters: _optBool(json, 'renderControlCharacters'),
      renderLineHighlight: _optEnum(
        json,
        'renderLineHighlight',
        MonacoLineHighlight.values,
        (e) => e.id,
      ),
      bracketPairColorization: _optBool(json, 'bracketPairColorization'),
      guides: _optSub(json, 'guides', MonacoGuidesOptions.fromJson),
      autoClosingBrackets: _optEnum(
        json,
        'autoClosingBrackets',
        AutoClosingBehavior.values,
        (e) => e.id,
      ),
      autoClosingQuotes: _optEnum(
        json,
        'autoClosingQuotes',
        AutoClosingBehavior.values,
        (e) => e.id,
      ),
      formatOnPaste: _optBool(json, 'formatOnPaste'),
      formatOnType: _optBool(json, 'formatOnType'),
      quickSuggestions: _optBool(json, 'quickSuggestions'),
      suggestOnTriggerCharacters: _optBool(json, 'suggestOnTriggerCharacters'),
      parameterHints: _optBool(json, 'parameterHints'),
      hover: _optBool(json, 'hover'),
      contextMenu: _optBool(json, 'contextMenu'),
      selectionHighlight: _optBool(json, 'selectionHighlight'),
      occurrencesHighlight: _optBool(json, 'occurrencesHighlight'),
      roundedSelection: _optBool(json, 'roundedSelection'),
      doubleClickSelectsBlock: _optBool(json, 'doubleClickSelectsBlock'),
      folding: _optBool(json, 'folding'),
      showFoldingControls: _optEnum(
        json,
        'showFoldingControls',
        MonacoFoldingControls.values,
        (e) => e.id,
      ),
      links: _optBool(json, 'links'),
      find: _optSub(json, 'find', MonacoFindOptions.fromJson),
      stickyScroll: _optSub(json, 'stickyScroll', MonacoStickyScroll.fromJson),
      overviewRulerBorder: _optBool(json, 'overviewRulerBorder'),
      disableLayerHinting: _optBool(json, 'disableLayerHinting'),
      disableMonospaceOptimizations: _optBool(
        json,
        'disableMonospaceOptimizations',
      ),
      extra: _optExtra(json, 'extra'),
    );
  }

  /// Serializes for persistence; omits null fields. Round-trips through
  /// [EditorOptions.fromJson].
  Map<String, dynamic> toJson() {
    return {
      if (language != null) 'language': language!.id,
      if (theme != null) 'theme': theme!.id,
      if (fontSize != null) 'fontSize': fontSize,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontLigatures != null) 'fontLigatures': fontLigatures,
      if (lineHeight != null) 'lineHeight': lineHeight,
      if (letterSpacing != null) 'letterSpacing': letterSpacing,
      if (fullwidthCharacterWidth != null)
        'fullwidthCharacterWidth': fullwidthCharacterWidth!.id,
      if (wordWrap != null) 'wordWrap': wordWrap!.id,
      if (wordWrapColumn != null) 'wordWrapColumn': wordWrapColumn,
      if (wordWrapIndicator != null) 'wordWrapIndicator': wordWrapIndicator,
      if (minimap != null) 'minimap': minimap!.toJson(),
      if (lineNumbers != null) 'lineNumbers': lineNumbers!.id,
      if (rulers != null) 'rulers': rulers,
      if (tabSize != null) 'tabSize': tabSize,
      if (insertSpaces != null) 'insertSpaces': insertSpaces,
      if (detectIndentation != null) 'detectIndentation': detectIndentation,
      if (readOnly != null) 'readOnly': readOnly,
      if (readOnlyMessage != null) 'readOnlyMessage': readOnlyMessage,
      if (automaticLayout != null) 'automaticLayout': automaticLayout,
      if (padding != null) 'padding': padding!.toJson(),
      if (scrollbar != null) 'scrollbar': scrollbar!.toJson(),
      if (scrollBeyondLastLine != null)
        'scrollBeyondLastLine': scrollBeyondLastLine,
      if (smoothScrolling != null) 'smoothScrolling': smoothScrolling,
      if (mouseWheelZoom != null) 'mouseWheelZoom': mouseWheelZoom,
      if (cursorBlinking != null) 'cursorBlinking': cursorBlinking!.id,
      if (cursorStyle != null) 'cursorStyle': cursorStyle!.id,
      if (cursorWidth != null) 'cursorWidth': cursorWidth,
      if (renderWhitespace != null) 'renderWhitespace': renderWhitespace!.id,
      if (renderControlCharacters != null)
        'renderControlCharacters': renderControlCharacters,
      if (renderLineHighlight != null)
        'renderLineHighlight': renderLineHighlight!.id,
      if (bracketPairColorization != null)
        'bracketPairColorization': bracketPairColorization,
      if (guides != null) 'guides': guides!.toJson(),
      if (autoClosingBrackets != null)
        'autoClosingBrackets': autoClosingBrackets!.id,
      if (autoClosingQuotes != null) 'autoClosingQuotes': autoClosingQuotes!.id,
      if (formatOnPaste != null) 'formatOnPaste': formatOnPaste,
      if (formatOnType != null) 'formatOnType': formatOnType,
      if (quickSuggestions != null) 'quickSuggestions': quickSuggestions,
      if (suggestOnTriggerCharacters != null)
        'suggestOnTriggerCharacters': suggestOnTriggerCharacters,
      if (parameterHints != null) 'parameterHints': parameterHints,
      if (hover != null) 'hover': hover,
      if (contextMenu != null) 'contextMenu': contextMenu,
      if (selectionHighlight != null) 'selectionHighlight': selectionHighlight,
      if (occurrencesHighlight != null)
        'occurrencesHighlight': occurrencesHighlight,
      if (roundedSelection != null) 'roundedSelection': roundedSelection,
      if (doubleClickSelectsBlock != null)
        'doubleClickSelectsBlock': doubleClickSelectsBlock,
      if (folding != null) 'folding': folding,
      if (showFoldingControls != null)
        'showFoldingControls': showFoldingControls!.id,
      if (links != null) 'links': links,
      if (find != null) 'find': find!.toJson(),
      if (stickyScroll != null) 'stickyScroll': stickyScroll!.toJson(),
      if (overviewRulerBorder != null)
        'overviewRulerBorder': overviewRulerBorder,
      if (disableLayerHinting != null)
        'disableLayerHinting': disableLayerHinting,
      if (disableMonospaceOptimizations != null)
        'disableMonospaceOptimizations': disableMonospaceOptimizations,
      if (extra != null) 'extra': extra,
    };
  }

  /// Returns a copy where non-null fields of [other] override this
  /// instance's fields. Structured options ([minimap], [padding],
  /// [scrollbar], [guides], [find], [stickyScroll]) merge field-wise, so a partial
  /// override (e.g. only `minimap.side`) keeps this instance's other nested
  /// values instead of resetting them to Monaco's defaults. [extra] maps are
  /// merged key-wise, [other]'s keys winning. Returns `this` when [other]
  /// is null.
  EditorOptions merge(EditorOptions? other) {
    if (other == null) return this;
    return EditorOptions(
      language: other.language ?? language,
      theme: other.theme ?? theme,
      fontSize: other.fontSize ?? fontSize,
      fontFamily: other.fontFamily ?? fontFamily,
      fontLigatures: other.fontLigatures ?? fontLigatures,
      lineHeight: other.lineHeight ?? lineHeight,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      fullwidthCharacterWidth:
          other.fullwidthCharacterWidth ?? fullwidthCharacterWidth,
      wordWrap: other.wordWrap ?? wordWrap,
      wordWrapColumn: other.wordWrapColumn ?? wordWrapColumn,
      wordWrapIndicator: other.wordWrapIndicator ?? wordWrapIndicator,
      minimap: minimap?.merge(other.minimap) ?? other.minimap,
      lineNumbers: other.lineNumbers ?? lineNumbers,
      rulers: other.rulers ?? rulers,
      tabSize: other.tabSize ?? tabSize,
      insertSpaces: other.insertSpaces ?? insertSpaces,
      detectIndentation: other.detectIndentation ?? detectIndentation,
      readOnly: other.readOnly ?? readOnly,
      readOnlyMessage: other.readOnlyMessage ?? readOnlyMessage,
      automaticLayout: other.automaticLayout ?? automaticLayout,
      padding: padding?.merge(other.padding) ?? other.padding,
      scrollbar: scrollbar?.merge(other.scrollbar) ?? other.scrollbar,
      scrollBeyondLastLine: other.scrollBeyondLastLine ?? scrollBeyondLastLine,
      smoothScrolling: other.smoothScrolling ?? smoothScrolling,
      mouseWheelZoom: other.mouseWheelZoom ?? mouseWheelZoom,
      cursorBlinking: other.cursorBlinking ?? cursorBlinking,
      cursorStyle: other.cursorStyle ?? cursorStyle,
      cursorWidth: other.cursorWidth ?? cursorWidth,
      renderWhitespace: other.renderWhitespace ?? renderWhitespace,
      renderControlCharacters:
          other.renderControlCharacters ?? renderControlCharacters,
      renderLineHighlight: other.renderLineHighlight ?? renderLineHighlight,
      bracketPairColorization:
          other.bracketPairColorization ?? bracketPairColorization,
      guides: guides?.merge(other.guides) ?? other.guides,
      autoClosingBrackets: other.autoClosingBrackets ?? autoClosingBrackets,
      autoClosingQuotes: other.autoClosingQuotes ?? autoClosingQuotes,
      formatOnPaste: other.formatOnPaste ?? formatOnPaste,
      formatOnType: other.formatOnType ?? formatOnType,
      quickSuggestions: other.quickSuggestions ?? quickSuggestions,
      suggestOnTriggerCharacters:
          other.suggestOnTriggerCharacters ?? suggestOnTriggerCharacters,
      parameterHints: other.parameterHints ?? parameterHints,
      hover: other.hover ?? hover,
      contextMenu: other.contextMenu ?? contextMenu,
      selectionHighlight: other.selectionHighlight ?? selectionHighlight,
      occurrencesHighlight: other.occurrencesHighlight ?? occurrencesHighlight,
      roundedSelection: other.roundedSelection ?? roundedSelection,
      doubleClickSelectsBlock:
          other.doubleClickSelectsBlock ?? doubleClickSelectsBlock,
      folding: other.folding ?? folding,
      showFoldingControls: other.showFoldingControls ?? showFoldingControls,
      links: other.links ?? links,
      find: find?.merge(other.find) ?? other.find,
      stickyScroll:
          stickyScroll?.merge(other.stickyScroll) ?? other.stickyScroll,
      overviewRulerBorder: other.overviewRulerBorder ?? overviewRulerBorder,
      disableLayerHinting: other.disableLayerHinting ?? disableLayerHinting,
      disableMonospaceOptimizations:
          other.disableMonospaceOptimizations ?? disableMonospaceOptimizations,
      extra: (extra == null && other.extra == null)
          ? null
          : {...?extra, ...?other.extra},
    );
  }

  /// Sparse Monaco options payload; null fields are omitted.
  ///
  /// [language] and [theme] are NOT included - they travel via the boot
  /// command, `setLanguage`, and `setTheme`. [extra] merges last, so its
  /// keys win over every modeled field.
  Map<String, dynamic> toMonacoOptions() {
    return {
      if (fontSize != null) 'fontSize': fontSize,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontLigatures != null) 'fontLigatures': fontLigatures,
      if (lineHeight != null) 'lineHeight': lineHeight,
      if (letterSpacing != null) 'letterSpacing': letterSpacing,
      if (fullwidthCharacterWidth != null)
        'fullwidthCharacterWidth': fullwidthCharacterWidth!.id,
      if (wordWrap != null) 'wordWrap': wordWrap!.id,
      if (wordWrapColumn != null) 'wordWrapColumn': wordWrapColumn,
      if (wordWrapIndicator != null) 'wordWrapIndicator': wordWrapIndicator,
      if (minimap != null) 'minimap': minimap!.toMonacoJson(),
      if (lineNumbers != null) 'lineNumbers': lineNumbers!.id,
      if (rulers != null) 'rulers': rulers,
      if (tabSize != null) 'tabSize': tabSize,
      if (insertSpaces != null) 'insertSpaces': insertSpaces,
      if (detectIndentation != null) 'detectIndentation': detectIndentation,
      if (readOnly != null) 'readOnly': readOnly,
      if (readOnlyMessage != null)
        'readOnlyMessage': {'value': readOnlyMessage},
      if (automaticLayout != null) 'automaticLayout': automaticLayout,
      if (padding != null) 'padding': padding!.toMonacoJson(),
      if (scrollbar != null) 'scrollbar': scrollbar!.toMonacoJson(),
      if (scrollBeyondLastLine != null)
        'scrollBeyondLastLine': scrollBeyondLastLine,
      if (smoothScrolling != null) 'smoothScrolling': smoothScrolling,
      if (mouseWheelZoom != null) 'mouseWheelZoom': mouseWheelZoom,
      if (cursorBlinking != null) 'cursorBlinking': cursorBlinking!.id,
      if (cursorStyle != null) 'cursorStyle': cursorStyle!.id,
      if (cursorWidth != null) 'cursorWidth': cursorWidth,
      if (renderWhitespace != null) 'renderWhitespace': renderWhitespace!.id,
      if (renderControlCharacters != null)
        'renderControlCharacters': renderControlCharacters,
      if (renderLineHighlight != null)
        'renderLineHighlight': renderLineHighlight!.id,
      if (bracketPairColorization != null)
        'bracketPairColorization': {'enabled': bracketPairColorization},
      if (guides != null) 'guides': guides!.toMonacoJson(),
      if (autoClosingBrackets != null)
        'autoClosingBrackets': autoClosingBrackets!.id,
      if (autoClosingQuotes != null) 'autoClosingQuotes': autoClosingQuotes!.id,
      if (formatOnPaste != null) 'formatOnPaste': formatOnPaste,
      if (formatOnType != null) 'formatOnType': formatOnType,
      if (quickSuggestions != null) 'quickSuggestions': quickSuggestions,
      if (suggestOnTriggerCharacters != null)
        'suggestOnTriggerCharacters': suggestOnTriggerCharacters,
      if (parameterHints != null) 'parameterHints': {'enabled': parameterHints},
      if (hover != null)
        // Monaco expects 'on' | 'off' | 'onKeyboardModifier' and ignores
        // a boolean.
        'hover': {'enabled': hover! ? 'on' : 'off'},
      if (contextMenu != null) 'contextmenu': contextMenu,
      if (selectionHighlight != null) 'selectionHighlight': selectionHighlight,
      if (occurrencesHighlight != null)
        // Monaco expects 'off' | 'singleFile' | 'multiFile'.
        'occurrencesHighlight': occurrencesHighlight! ? 'singleFile' : 'off',
      if (roundedSelection != null) 'roundedSelection': roundedSelection,
      if (doubleClickSelectsBlock != null)
        'doubleClickSelectsBlock': doubleClickSelectsBlock,
      if (folding != null) 'folding': folding,
      if (showFoldingControls != null)
        'showFoldingControls': showFoldingControls!.id,
      if (links != null) 'links': links,
      if (find != null) 'find': find!.toMonacoJson(),
      if (stickyScroll != null) 'stickyScroll': stickyScroll!.toMonacoJson(),
      if (overviewRulerBorder != null)
        'overviewRulerBorder': overviewRulerBorder,
      if (disableLayerHinting != null)
        'disableLayerHinting': disableLayerHinting,
      if (disableMonospaceOptimizations != null)
        'disableMonospaceOptimizations': disableMonospaceOptimizations,
      ...?extra,
    };
  }
}

String? _optString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException(
    'EditorOptions.fromJson: "$key" must be a string, got $value',
  );
}

double? _optDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw FormatException(
    'EditorOptions.fromJson: "$key" must be a number, got $value',
  );
}

int? _optInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  // Web numbers are doubles: `2.0 is int` and `double.infinity is int` hold.
  if (value is int && value.isFinite) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  throw FormatException(
    'EditorOptions.fromJson: "$key" must be an integer, got $value',
  );
}

bool? _optBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException(
    'EditorOptions.fromJson: "$key" must be a bool, got $value',
  );
}

List<int>? _optIntList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is List) {
    return value.map((e) {
      if (e is int && e.isFinite) return e;
      if (e is double && e.isFinite && e == e.truncateToDouble()) {
        return e.toInt();
      }
      throw FormatException(
        'EditorOptions.fromJson: "$key" entries must be integers, got $e',
      );
    }).toList();
  }
  throw FormatException(
    'EditorOptions.fromJson: "$key" must be a list, got $value',
  );
}

T? _optEnum<T>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
  String Function(T) idOf,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) {
    for (final candidate in values) {
      if (idOf(candidate) == value) return candidate;
    }
  }
  throw FormatException('EditorOptions.fromJson: unknown "$key" value $value');
}

T? _optSub<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) parse,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is Map) return parse(Map<String, dynamic>.from(value));
  throw FormatException(
    'EditorOptions.fromJson: "$key" must be a map, got $value',
  );
}

Map<String, Object?>? _optExtra(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException(
    'EditorOptions.fromJson: "$key" must be a map, got $value',
  );
}
