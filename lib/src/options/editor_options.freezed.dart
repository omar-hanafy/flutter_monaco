// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorOptions {

/// Initial document language. Only consumed at boot (the `page.boot`
/// command); use `controller.document.setLanguage` on a live editor.
 MonacoLanguage? get language;/// Editor theme. When `null`, the `MonacoEditor` widget resolves a
/// theme from `Theme.of(context).brightness`; a headless
/// `MonacoController.create` falls back to `MonacoDefaults.darkTheme`.
/// Custom themes registered with `defineTheme` are selected by their
/// id: `MonacoTheme('app-dark')`.
 MonacoTheme? get theme;/// Font size in pixels.
 double? get fontSize;/// CSS `font-family` string (e.g. `'Fira Code, monospace'`).
 String? get fontFamily;/// Whether font ligatures render (requires a compatible font).
 bool? get fontLigatures;/// Line height. `0` lets Monaco compute from [fontSize]; values below
/// `8` are multipliers of the font size; `8` and above are absolute
/// pixels (Monaco's own semantics - the value is passed through).
 double? get lineHeight;/// Letter spacing in pixels.
 double? get letterSpacing;/// Word wrapping behavior.
 MonacoWordWrap? get wordWrap;/// Wrap column used by [MonacoWordWrap.wordWrapColumn] and
/// [MonacoWordWrap.bounded].
 int? get wordWrapColumn;/// Minimap (code overview strip) configuration.
 MonacoMinimapOptions? get minimap;/// Line number rendering in the gutter.
 MonacoLineNumbers? get lineNumbers;/// Column positions of vertical rulers (e.g. `[80, 120]`).
 List<int>? get rulers;/// Number of spaces a tab is equal to.
 int? get tabSize;/// Whether `Tab` inserts spaces instead of a tab character.
 bool? get insertSpaces;/// Whether Monaco detects indentation from file contents.
 bool? get detectIndentation;/// Whether the document is read-only.
 bool? get readOnly;/// Message shown when the user tries to edit a read-only document.
 String? get readOnlyMessage;/// Whether the editor resizes itself with its container.
 bool? get automaticLayout;/// Content padding.
 MonacoPadding? get padding;/// Scrollbar configuration.
 MonacoScrollbarOptions? get scrollbar;/// Whether scrolling can go beyond the last line.
 bool? get scrollBeyondLastLine;/// Whether scrolling animates.
 bool? get smoothScrolling;/// Whether Ctrl/Cmd + mouse wheel zooms the font.
 bool? get mouseWheelZoom;/// Cursor blinking animation.
 CursorBlinking? get cursorBlinking;/// Cursor shape.
 CursorStyle? get cursorStyle;/// Cursor width in pixels (for [CursorStyle.line]).
 int? get cursorWidth;/// Whitespace character rendering.
 RenderWhitespace? get renderWhitespace;/// Whether control characters render.
 bool? get renderControlCharacters;/// Current-line highlight rendering.
 MonacoLineHighlight? get renderLineHighlight;/// Whether matching brackets get per-pair colors.
 bool? get bracketPairColorization;/// Bracket-pair and indentation guide rendering.
 MonacoGuidesOptions? get guides;/// Automatic closing of brackets.
 AutoClosingBehavior? get autoClosingBrackets;/// Automatic closing of quotes.
 AutoClosingBehavior? get autoClosingQuotes;/// Whether pasted text is formatted.
 bool? get formatOnPaste;/// Whether text formats as you type.
 bool? get formatOnType;/// Whether the suggestion widget appears while typing.
 bool? get quickSuggestions;/// Whether suggestions appear on trigger characters (e.g. `.`).
 bool? get suggestOnTriggerCharacters;/// Whether parameter hints appear in call sites.
 bool? get parameterHints;/// Whether hover tooltips appear.
 bool? get hover;/// Whether the right-click context menu is enabled.
 bool? get contextMenu;/// Whether other occurrences of the selection are highlighted.
 bool? get selectionHighlight;/// Whether symbol occurrences are highlighted semantically.
 bool? get occurrencesHighlight;/// Whether selections render with rounded corners.
 bool? get roundedSelection;/// Whether code folding is enabled.
 bool? get folding;/// When the folding controls in the gutter are visible.
 MonacoFoldingControls? get showFoldingControls;/// Whether links in the document are clickable.
 bool? get links;/// Sticky scroll (pinned enclosing scopes) configuration.
 MonacoStickyScroll? get stickyScroll;/// Whether the overview ruler draws a border.
 bool? get overviewRulerBorder;/// Disables the layer-hinting render optimization (try `true` if you
/// see rendering artifacts on some platforms).
 bool? get disableLayerHinting;/// Disables monospace font optimizations.
 bool? get disableMonospaceOptimizations;/// Raw Monaco options merged LAST into the payload; keys here win over
/// every modeled field. The permanent escape hatch for anything not
/// modeled above.
 Map<String, Object?>? get extra;
/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorOptionsCopyWith<EditorOptions> get copyWith => _$EditorOptionsCopyWithImpl<EditorOptions>(this as EditorOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorOptions&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.fontSize, _this.fontSize) || other.fontSize == _this.fontSize)&&(identical(other.fontFamily, _this.fontFamily) || other.fontFamily == _this.fontFamily)&&(identical(other.fontLigatures, _this.fontLigatures) || other.fontLigatures == _this.fontLigatures)&&(identical(other.lineHeight, _this.lineHeight) || other.lineHeight == _this.lineHeight)&&(identical(other.letterSpacing, _this.letterSpacing) || other.letterSpacing == _this.letterSpacing)&&(identical(other.wordWrap, _this.wordWrap) || other.wordWrap == _this.wordWrap)&&(identical(other.wordWrapColumn, _this.wordWrapColumn) || other.wordWrapColumn == _this.wordWrapColumn)&&(identical(other.minimap, _this.minimap) || other.minimap == _this.minimap)&&(identical(other.lineNumbers, _this.lineNumbers) || other.lineNumbers == _this.lineNumbers)&&const DeepCollectionEquality().equals(other.rulers, _this.rulers)&&(identical(other.tabSize, _this.tabSize) || other.tabSize == _this.tabSize)&&(identical(other.insertSpaces, _this.insertSpaces) || other.insertSpaces == _this.insertSpaces)&&(identical(other.detectIndentation, _this.detectIndentation) || other.detectIndentation == _this.detectIndentation)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly)&&(identical(other.readOnlyMessage, _this.readOnlyMessage) || other.readOnlyMessage == _this.readOnlyMessage)&&(identical(other.automaticLayout, _this.automaticLayout) || other.automaticLayout == _this.automaticLayout)&&(identical(other.padding, _this.padding) || other.padding == _this.padding)&&(identical(other.scrollbar, _this.scrollbar) || other.scrollbar == _this.scrollbar)&&(identical(other.scrollBeyondLastLine, _this.scrollBeyondLastLine) || other.scrollBeyondLastLine == _this.scrollBeyondLastLine)&&(identical(other.smoothScrolling, _this.smoothScrolling) || other.smoothScrolling == _this.smoothScrolling)&&(identical(other.mouseWheelZoom, _this.mouseWheelZoom) || other.mouseWheelZoom == _this.mouseWheelZoom)&&(identical(other.cursorBlinking, _this.cursorBlinking) || other.cursorBlinking == _this.cursorBlinking)&&(identical(other.cursorStyle, _this.cursorStyle) || other.cursorStyle == _this.cursorStyle)&&(identical(other.cursorWidth, _this.cursorWidth) || other.cursorWidth == _this.cursorWidth)&&(identical(other.renderWhitespace, _this.renderWhitespace) || other.renderWhitespace == _this.renderWhitespace)&&(identical(other.renderControlCharacters, _this.renderControlCharacters) || other.renderControlCharacters == _this.renderControlCharacters)&&(identical(other.renderLineHighlight, _this.renderLineHighlight) || other.renderLineHighlight == _this.renderLineHighlight)&&(identical(other.bracketPairColorization, _this.bracketPairColorization) || other.bracketPairColorization == _this.bracketPairColorization)&&(identical(other.guides, _this.guides) || other.guides == _this.guides)&&(identical(other.autoClosingBrackets, _this.autoClosingBrackets) || other.autoClosingBrackets == _this.autoClosingBrackets)&&(identical(other.autoClosingQuotes, _this.autoClosingQuotes) || other.autoClosingQuotes == _this.autoClosingQuotes)&&(identical(other.formatOnPaste, _this.formatOnPaste) || other.formatOnPaste == _this.formatOnPaste)&&(identical(other.formatOnType, _this.formatOnType) || other.formatOnType == _this.formatOnType)&&(identical(other.quickSuggestions, _this.quickSuggestions) || other.quickSuggestions == _this.quickSuggestions)&&(identical(other.suggestOnTriggerCharacters, _this.suggestOnTriggerCharacters) || other.suggestOnTriggerCharacters == _this.suggestOnTriggerCharacters)&&(identical(other.parameterHints, _this.parameterHints) || other.parameterHints == _this.parameterHints)&&(identical(other.hover, _this.hover) || other.hover == _this.hover)&&(identical(other.contextMenu, _this.contextMenu) || other.contextMenu == _this.contextMenu)&&(identical(other.selectionHighlight, _this.selectionHighlight) || other.selectionHighlight == _this.selectionHighlight)&&(identical(other.occurrencesHighlight, _this.occurrencesHighlight) || other.occurrencesHighlight == _this.occurrencesHighlight)&&(identical(other.roundedSelection, _this.roundedSelection) || other.roundedSelection == _this.roundedSelection)&&(identical(other.folding, _this.folding) || other.folding == _this.folding)&&(identical(other.showFoldingControls, _this.showFoldingControls) || other.showFoldingControls == _this.showFoldingControls)&&(identical(other.links, _this.links) || other.links == _this.links)&&(identical(other.stickyScroll, _this.stickyScroll) || other.stickyScroll == _this.stickyScroll)&&(identical(other.overviewRulerBorder, _this.overviewRulerBorder) || other.overviewRulerBorder == _this.overviewRulerBorder)&&(identical(other.disableLayerHinting, _this.disableLayerHinting) || other.disableLayerHinting == _this.disableLayerHinting)&&(identical(other.disableMonospaceOptimizations, _this.disableMonospaceOptimizations) || other.disableMonospaceOptimizations == _this.disableMonospaceOptimizations)&&const DeepCollectionEquality().equals(other.extra, _this.extra));
}


@override
int get hashCode {
  final _this = this as EditorOptions;
  return Object.hashAll([runtimeType,_this.language,_this.theme,_this.fontSize,_this.fontFamily,_this.fontLigatures,_this.lineHeight,_this.letterSpacing,_this.wordWrap,_this.wordWrapColumn,_this.minimap,_this.lineNumbers,const DeepCollectionEquality().hash(_this.rulers),_this.tabSize,_this.insertSpaces,_this.detectIndentation,_this.readOnly,_this.readOnlyMessage,_this.automaticLayout,_this.padding,_this.scrollbar,_this.scrollBeyondLastLine,_this.smoothScrolling,_this.mouseWheelZoom,_this.cursorBlinking,_this.cursorStyle,_this.cursorWidth,_this.renderWhitespace,_this.renderControlCharacters,_this.renderLineHighlight,_this.bracketPairColorization,_this.guides,_this.autoClosingBrackets,_this.autoClosingQuotes,_this.formatOnPaste,_this.formatOnType,_this.quickSuggestions,_this.suggestOnTriggerCharacters,_this.parameterHints,_this.hover,_this.contextMenu,_this.selectionHighlight,_this.occurrencesHighlight,_this.roundedSelection,_this.folding,_this.showFoldingControls,_this.links,_this.stickyScroll,_this.overviewRulerBorder,_this.disableLayerHinting,_this.disableMonospaceOptimizations,const DeepCollectionEquality().hash(_this.extra)]);
}

@override
String toString() {
  final _this = this as EditorOptions;
  return 'EditorOptions(language: ${_this.language}, theme: ${_this.theme}, fontSize: ${_this.fontSize}, fontFamily: ${_this.fontFamily}, fontLigatures: ${_this.fontLigatures}, lineHeight: ${_this.lineHeight}, letterSpacing: ${_this.letterSpacing}, wordWrap: ${_this.wordWrap}, wordWrapColumn: ${_this.wordWrapColumn}, minimap: ${_this.minimap}, lineNumbers: ${_this.lineNumbers}, rulers: ${_this.rulers}, tabSize: ${_this.tabSize}, insertSpaces: ${_this.insertSpaces}, detectIndentation: ${_this.detectIndentation}, readOnly: ${_this.readOnly}, readOnlyMessage: ${_this.readOnlyMessage}, automaticLayout: ${_this.automaticLayout}, padding: ${_this.padding}, scrollbar: ${_this.scrollbar}, scrollBeyondLastLine: ${_this.scrollBeyondLastLine}, smoothScrolling: ${_this.smoothScrolling}, mouseWheelZoom: ${_this.mouseWheelZoom}, cursorBlinking: ${_this.cursorBlinking}, cursorStyle: ${_this.cursorStyle}, cursorWidth: ${_this.cursorWidth}, renderWhitespace: ${_this.renderWhitespace}, renderControlCharacters: ${_this.renderControlCharacters}, renderLineHighlight: ${_this.renderLineHighlight}, bracketPairColorization: ${_this.bracketPairColorization}, guides: ${_this.guides}, autoClosingBrackets: ${_this.autoClosingBrackets}, autoClosingQuotes: ${_this.autoClosingQuotes}, formatOnPaste: ${_this.formatOnPaste}, formatOnType: ${_this.formatOnType}, quickSuggestions: ${_this.quickSuggestions}, suggestOnTriggerCharacters: ${_this.suggestOnTriggerCharacters}, parameterHints: ${_this.parameterHints}, hover: ${_this.hover}, contextMenu: ${_this.contextMenu}, selectionHighlight: ${_this.selectionHighlight}, occurrencesHighlight: ${_this.occurrencesHighlight}, roundedSelection: ${_this.roundedSelection}, folding: ${_this.folding}, showFoldingControls: ${_this.showFoldingControls}, links: ${_this.links}, stickyScroll: ${_this.stickyScroll}, overviewRulerBorder: ${_this.overviewRulerBorder}, disableLayerHinting: ${_this.disableLayerHinting}, disableMonospaceOptimizations: ${_this.disableMonospaceOptimizations}, extra: ${_this.extra})';
}


}

/// @nodoc
abstract mixin class $EditorOptionsCopyWith<$Res>  {
  factory $EditorOptionsCopyWith(EditorOptions value, $Res Function(EditorOptions) _then) = _$EditorOptionsCopyWithImpl;
@useResult
$Res call({
 MonacoLanguage? language, MonacoTheme? theme, double? fontSize, String? fontFamily, bool? fontLigatures, double? lineHeight, double? letterSpacing, MonacoWordWrap? wordWrap, int? wordWrapColumn, MonacoMinimapOptions? minimap, MonacoLineNumbers? lineNumbers, List<int>? rulers, int? tabSize, bool? insertSpaces, bool? detectIndentation, bool? readOnly, String? readOnlyMessage, bool? automaticLayout, MonacoPadding? padding, MonacoScrollbarOptions? scrollbar, bool? scrollBeyondLastLine, bool? smoothScrolling, bool? mouseWheelZoom, CursorBlinking? cursorBlinking, CursorStyle? cursorStyle, int? cursorWidth, RenderWhitespace? renderWhitespace, bool? renderControlCharacters, MonacoLineHighlight? renderLineHighlight, bool? bracketPairColorization, MonacoGuidesOptions? guides, AutoClosingBehavior? autoClosingBrackets, AutoClosingBehavior? autoClosingQuotes, bool? formatOnPaste, bool? formatOnType, bool? quickSuggestions, bool? suggestOnTriggerCharacters, bool? parameterHints, bool? hover, bool? contextMenu, bool? selectionHighlight, bool? occurrencesHighlight, bool? roundedSelection, bool? folding, MonacoFoldingControls? showFoldingControls, bool? links, MonacoStickyScroll? stickyScroll, bool? overviewRulerBorder, bool? disableLayerHinting, bool? disableMonospaceOptimizations, Map<String, Object?>? extra
});


$MonacoMinimapOptionsCopyWith<$Res>? get minimap;$MonacoPaddingCopyWith<$Res>? get padding;$MonacoScrollbarOptionsCopyWith<$Res>? get scrollbar;$MonacoGuidesOptionsCopyWith<$Res>? get guides;$MonacoStickyScrollCopyWith<$Res>? get stickyScroll;

}
/// @nodoc
class _$EditorOptionsCopyWithImpl<$Res>
    implements $EditorOptionsCopyWith<$Res> {
  _$EditorOptionsCopyWithImpl(this._self, this._then);

  final EditorOptions _self;
  final $Res Function(EditorOptions) _then;

/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = freezed,Object? theme = freezed,Object? fontSize = freezed,Object? fontFamily = freezed,Object? fontLigatures = freezed,Object? lineHeight = freezed,Object? letterSpacing = freezed,Object? wordWrap = freezed,Object? wordWrapColumn = freezed,Object? minimap = freezed,Object? lineNumbers = freezed,Object? rulers = freezed,Object? tabSize = freezed,Object? insertSpaces = freezed,Object? detectIndentation = freezed,Object? readOnly = freezed,Object? readOnlyMessage = freezed,Object? automaticLayout = freezed,Object? padding = freezed,Object? scrollbar = freezed,Object? scrollBeyondLastLine = freezed,Object? smoothScrolling = freezed,Object? mouseWheelZoom = freezed,Object? cursorBlinking = freezed,Object? cursorStyle = freezed,Object? cursorWidth = freezed,Object? renderWhitespace = freezed,Object? renderControlCharacters = freezed,Object? renderLineHighlight = freezed,Object? bracketPairColorization = freezed,Object? guides = freezed,Object? autoClosingBrackets = freezed,Object? autoClosingQuotes = freezed,Object? formatOnPaste = freezed,Object? formatOnType = freezed,Object? quickSuggestions = freezed,Object? suggestOnTriggerCharacters = freezed,Object? parameterHints = freezed,Object? hover = freezed,Object? contextMenu = freezed,Object? selectionHighlight = freezed,Object? occurrencesHighlight = freezed,Object? roundedSelection = freezed,Object? folding = freezed,Object? showFoldingControls = freezed,Object? links = freezed,Object? stickyScroll = freezed,Object? overviewRulerBorder = freezed,Object? disableLayerHinting = freezed,Object? disableMonospaceOptimizations = freezed,Object? extra = freezed,}) {
  return _then(EditorOptions(
language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as MonacoLanguage?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as MonacoTheme?,fontSize: freezed == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double?,fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,fontLigatures: freezed == fontLigatures ? _self.fontLigatures : fontLigatures // ignore: cast_nullable_to_non_nullable
as bool?,lineHeight: freezed == lineHeight ? _self.lineHeight : lineHeight // ignore: cast_nullable_to_non_nullable
as double?,letterSpacing: freezed == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double?,wordWrap: freezed == wordWrap ? _self.wordWrap : wordWrap // ignore: cast_nullable_to_non_nullable
as MonacoWordWrap?,wordWrapColumn: freezed == wordWrapColumn ? _self.wordWrapColumn : wordWrapColumn // ignore: cast_nullable_to_non_nullable
as int?,minimap: freezed == minimap ? _self.minimap : minimap // ignore: cast_nullable_to_non_nullable
as MonacoMinimapOptions?,lineNumbers: freezed == lineNumbers ? _self.lineNumbers : lineNumbers // ignore: cast_nullable_to_non_nullable
as MonacoLineNumbers?,rulers: freezed == rulers ? _self.rulers : rulers // ignore: cast_nullable_to_non_nullable
as List<int>?,tabSize: freezed == tabSize ? _self.tabSize : tabSize // ignore: cast_nullable_to_non_nullable
as int?,insertSpaces: freezed == insertSpaces ? _self.insertSpaces : insertSpaces // ignore: cast_nullable_to_non_nullable
as bool?,detectIndentation: freezed == detectIndentation ? _self.detectIndentation : detectIndentation // ignore: cast_nullable_to_non_nullable
as bool?,readOnly: freezed == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool?,readOnlyMessage: freezed == readOnlyMessage ? _self.readOnlyMessage : readOnlyMessage // ignore: cast_nullable_to_non_nullable
as String?,automaticLayout: freezed == automaticLayout ? _self.automaticLayout : automaticLayout // ignore: cast_nullable_to_non_nullable
as bool?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as MonacoPadding?,scrollbar: freezed == scrollbar ? _self.scrollbar : scrollbar // ignore: cast_nullable_to_non_nullable
as MonacoScrollbarOptions?,scrollBeyondLastLine: freezed == scrollBeyondLastLine ? _self.scrollBeyondLastLine : scrollBeyondLastLine // ignore: cast_nullable_to_non_nullable
as bool?,smoothScrolling: freezed == smoothScrolling ? _self.smoothScrolling : smoothScrolling // ignore: cast_nullable_to_non_nullable
as bool?,mouseWheelZoom: freezed == mouseWheelZoom ? _self.mouseWheelZoom : mouseWheelZoom // ignore: cast_nullable_to_non_nullable
as bool?,cursorBlinking: freezed == cursorBlinking ? _self.cursorBlinking : cursorBlinking // ignore: cast_nullable_to_non_nullable
as CursorBlinking?,cursorStyle: freezed == cursorStyle ? _self.cursorStyle : cursorStyle // ignore: cast_nullable_to_non_nullable
as CursorStyle?,cursorWidth: freezed == cursorWidth ? _self.cursorWidth : cursorWidth // ignore: cast_nullable_to_non_nullable
as int?,renderWhitespace: freezed == renderWhitespace ? _self.renderWhitespace : renderWhitespace // ignore: cast_nullable_to_non_nullable
as RenderWhitespace?,renderControlCharacters: freezed == renderControlCharacters ? _self.renderControlCharacters : renderControlCharacters // ignore: cast_nullable_to_non_nullable
as bool?,renderLineHighlight: freezed == renderLineHighlight ? _self.renderLineHighlight : renderLineHighlight // ignore: cast_nullable_to_non_nullable
as MonacoLineHighlight?,bracketPairColorization: freezed == bracketPairColorization ? _self.bracketPairColorization : bracketPairColorization // ignore: cast_nullable_to_non_nullable
as bool?,guides: freezed == guides ? _self.guides : guides // ignore: cast_nullable_to_non_nullable
as MonacoGuidesOptions?,autoClosingBrackets: freezed == autoClosingBrackets ? _self.autoClosingBrackets : autoClosingBrackets // ignore: cast_nullable_to_non_nullable
as AutoClosingBehavior?,autoClosingQuotes: freezed == autoClosingQuotes ? _self.autoClosingQuotes : autoClosingQuotes // ignore: cast_nullable_to_non_nullable
as AutoClosingBehavior?,formatOnPaste: freezed == formatOnPaste ? _self.formatOnPaste : formatOnPaste // ignore: cast_nullable_to_non_nullable
as bool?,formatOnType: freezed == formatOnType ? _self.formatOnType : formatOnType // ignore: cast_nullable_to_non_nullable
as bool?,quickSuggestions: freezed == quickSuggestions ? _self.quickSuggestions : quickSuggestions // ignore: cast_nullable_to_non_nullable
as bool?,suggestOnTriggerCharacters: freezed == suggestOnTriggerCharacters ? _self.suggestOnTriggerCharacters : suggestOnTriggerCharacters // ignore: cast_nullable_to_non_nullable
as bool?,parameterHints: freezed == parameterHints ? _self.parameterHints : parameterHints // ignore: cast_nullable_to_non_nullable
as bool?,hover: freezed == hover ? _self.hover : hover // ignore: cast_nullable_to_non_nullable
as bool?,contextMenu: freezed == contextMenu ? _self.contextMenu : contextMenu // ignore: cast_nullable_to_non_nullable
as bool?,selectionHighlight: freezed == selectionHighlight ? _self.selectionHighlight : selectionHighlight // ignore: cast_nullable_to_non_nullable
as bool?,occurrencesHighlight: freezed == occurrencesHighlight ? _self.occurrencesHighlight : occurrencesHighlight // ignore: cast_nullable_to_non_nullable
as bool?,roundedSelection: freezed == roundedSelection ? _self.roundedSelection : roundedSelection // ignore: cast_nullable_to_non_nullable
as bool?,folding: freezed == folding ? _self.folding : folding // ignore: cast_nullable_to_non_nullable
as bool?,showFoldingControls: freezed == showFoldingControls ? _self.showFoldingControls : showFoldingControls // ignore: cast_nullable_to_non_nullable
as MonacoFoldingControls?,links: freezed == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as bool?,stickyScroll: freezed == stickyScroll ? _self.stickyScroll : stickyScroll // ignore: cast_nullable_to_non_nullable
as MonacoStickyScroll?,overviewRulerBorder: freezed == overviewRulerBorder ? _self.overviewRulerBorder : overviewRulerBorder // ignore: cast_nullable_to_non_nullable
as bool?,disableLayerHinting: freezed == disableLayerHinting ? _self.disableLayerHinting : disableLayerHinting // ignore: cast_nullable_to_non_nullable
as bool?,disableMonospaceOptimizations: freezed == disableMonospaceOptimizations ? _self.disableMonospaceOptimizations : disableMonospaceOptimizations // ignore: cast_nullable_to_non_nullable
as bool?,extra: freezed == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}
/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoMinimapOptionsCopyWith<$Res>? get minimap {
    if (_self.minimap == null) {
    return null;
  }

  return $MonacoMinimapOptionsCopyWith<$Res>(_self.minimap!, (value) {
    return _then(_self.copyWith(minimap: value));
  });
}/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoPaddingCopyWith<$Res>? get padding {
    if (_self.padding == null) {
    return null;
  }

  return $MonacoPaddingCopyWith<$Res>(_self.padding!, (value) {
    return _then(_self.copyWith(padding: value));
  });
}/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoScrollbarOptionsCopyWith<$Res>? get scrollbar {
    if (_self.scrollbar == null) {
    return null;
  }

  return $MonacoScrollbarOptionsCopyWith<$Res>(_self.scrollbar!, (value) {
    return _then(_self.copyWith(scrollbar: value));
  });
}/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoGuidesOptionsCopyWith<$Res>? get guides {
    if (_self.guides == null) {
    return null;
  }

  return $MonacoGuidesOptionsCopyWith<$Res>(_self.guides!, (value) {
    return _then(_self.copyWith(guides: value));
  });
}/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoStickyScrollCopyWith<$Res>? get stickyScroll {
    if (_self.stickyScroll == null) {
    return null;
  }

  return $MonacoStickyScrollCopyWith<$Res>(_self.stickyScroll!, (value) {
    return _then(_self.copyWith(stickyScroll: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorOptions].
extension EditorOptionsPatterns on EditorOptions {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorOptions() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorOptions value)  $default,){
final _that = this;
switch (_that) {
case _EditorOptions():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorOptions value)?  $default,){
final _that = this;
switch (_that) {
case _EditorOptions() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MonacoLanguage? language,  MonacoTheme? theme,  double? fontSize,  String? fontFamily,  bool? fontLigatures,  double? lineHeight,  double? letterSpacing,  MonacoWordWrap? wordWrap,  int? wordWrapColumn,  MonacoMinimapOptions? minimap,  MonacoLineNumbers? lineNumbers,  List<int>? rulers,  int? tabSize,  bool? insertSpaces,  bool? detectIndentation,  bool? readOnly,  String? readOnlyMessage,  bool? automaticLayout,  MonacoPadding? padding,  MonacoScrollbarOptions? scrollbar,  bool? scrollBeyondLastLine,  bool? smoothScrolling,  bool? mouseWheelZoom,  CursorBlinking? cursorBlinking,  CursorStyle? cursorStyle,  int? cursorWidth,  RenderWhitespace? renderWhitespace,  bool? renderControlCharacters,  MonacoLineHighlight? renderLineHighlight,  bool? bracketPairColorization,  MonacoGuidesOptions? guides,  AutoClosingBehavior? autoClosingBrackets,  AutoClosingBehavior? autoClosingQuotes,  bool? formatOnPaste,  bool? formatOnType,  bool? quickSuggestions,  bool? suggestOnTriggerCharacters,  bool? parameterHints,  bool? hover,  bool? contextMenu,  bool? selectionHighlight,  bool? occurrencesHighlight,  bool? roundedSelection,  bool? folding,  MonacoFoldingControls? showFoldingControls,  bool? links,  MonacoStickyScroll? stickyScroll,  bool? overviewRulerBorder,  bool? disableLayerHinting,  bool? disableMonospaceOptimizations,  Map<String, Object?>? extra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorOptions() when $default != null:
return $default(_that.language,_that.theme,_that.fontSize,_that.fontFamily,_that.fontLigatures,_that.lineHeight,_that.letterSpacing,_that.wordWrap,_that.wordWrapColumn,_that.minimap,_that.lineNumbers,_that.rulers,_that.tabSize,_that.insertSpaces,_that.detectIndentation,_that.readOnly,_that.readOnlyMessage,_that.automaticLayout,_that.padding,_that.scrollbar,_that.scrollBeyondLastLine,_that.smoothScrolling,_that.mouseWheelZoom,_that.cursorBlinking,_that.cursorStyle,_that.cursorWidth,_that.renderWhitespace,_that.renderControlCharacters,_that.renderLineHighlight,_that.bracketPairColorization,_that.guides,_that.autoClosingBrackets,_that.autoClosingQuotes,_that.formatOnPaste,_that.formatOnType,_that.quickSuggestions,_that.suggestOnTriggerCharacters,_that.parameterHints,_that.hover,_that.contextMenu,_that.selectionHighlight,_that.occurrencesHighlight,_that.roundedSelection,_that.folding,_that.showFoldingControls,_that.links,_that.stickyScroll,_that.overviewRulerBorder,_that.disableLayerHinting,_that.disableMonospaceOptimizations,_that.extra);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MonacoLanguage? language,  MonacoTheme? theme,  double? fontSize,  String? fontFamily,  bool? fontLigatures,  double? lineHeight,  double? letterSpacing,  MonacoWordWrap? wordWrap,  int? wordWrapColumn,  MonacoMinimapOptions? minimap,  MonacoLineNumbers? lineNumbers,  List<int>? rulers,  int? tabSize,  bool? insertSpaces,  bool? detectIndentation,  bool? readOnly,  String? readOnlyMessage,  bool? automaticLayout,  MonacoPadding? padding,  MonacoScrollbarOptions? scrollbar,  bool? scrollBeyondLastLine,  bool? smoothScrolling,  bool? mouseWheelZoom,  CursorBlinking? cursorBlinking,  CursorStyle? cursorStyle,  int? cursorWidth,  RenderWhitespace? renderWhitespace,  bool? renderControlCharacters,  MonacoLineHighlight? renderLineHighlight,  bool? bracketPairColorization,  MonacoGuidesOptions? guides,  AutoClosingBehavior? autoClosingBrackets,  AutoClosingBehavior? autoClosingQuotes,  bool? formatOnPaste,  bool? formatOnType,  bool? quickSuggestions,  bool? suggestOnTriggerCharacters,  bool? parameterHints,  bool? hover,  bool? contextMenu,  bool? selectionHighlight,  bool? occurrencesHighlight,  bool? roundedSelection,  bool? folding,  MonacoFoldingControls? showFoldingControls,  bool? links,  MonacoStickyScroll? stickyScroll,  bool? overviewRulerBorder,  bool? disableLayerHinting,  bool? disableMonospaceOptimizations,  Map<String, Object?>? extra)  $default,) {final _that = this;
switch (_that) {
case _EditorOptions():
return $default(_that.language,_that.theme,_that.fontSize,_that.fontFamily,_that.fontLigatures,_that.lineHeight,_that.letterSpacing,_that.wordWrap,_that.wordWrapColumn,_that.minimap,_that.lineNumbers,_that.rulers,_that.tabSize,_that.insertSpaces,_that.detectIndentation,_that.readOnly,_that.readOnlyMessage,_that.automaticLayout,_that.padding,_that.scrollbar,_that.scrollBeyondLastLine,_that.smoothScrolling,_that.mouseWheelZoom,_that.cursorBlinking,_that.cursorStyle,_that.cursorWidth,_that.renderWhitespace,_that.renderControlCharacters,_that.renderLineHighlight,_that.bracketPairColorization,_that.guides,_that.autoClosingBrackets,_that.autoClosingQuotes,_that.formatOnPaste,_that.formatOnType,_that.quickSuggestions,_that.suggestOnTriggerCharacters,_that.parameterHints,_that.hover,_that.contextMenu,_that.selectionHighlight,_that.occurrencesHighlight,_that.roundedSelection,_that.folding,_that.showFoldingControls,_that.links,_that.stickyScroll,_that.overviewRulerBorder,_that.disableLayerHinting,_that.disableMonospaceOptimizations,_that.extra);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MonacoLanguage? language,  MonacoTheme? theme,  double? fontSize,  String? fontFamily,  bool? fontLigatures,  double? lineHeight,  double? letterSpacing,  MonacoWordWrap? wordWrap,  int? wordWrapColumn,  MonacoMinimapOptions? minimap,  MonacoLineNumbers? lineNumbers,  List<int>? rulers,  int? tabSize,  bool? insertSpaces,  bool? detectIndentation,  bool? readOnly,  String? readOnlyMessage,  bool? automaticLayout,  MonacoPadding? padding,  MonacoScrollbarOptions? scrollbar,  bool? scrollBeyondLastLine,  bool? smoothScrolling,  bool? mouseWheelZoom,  CursorBlinking? cursorBlinking,  CursorStyle? cursorStyle,  int? cursorWidth,  RenderWhitespace? renderWhitespace,  bool? renderControlCharacters,  MonacoLineHighlight? renderLineHighlight,  bool? bracketPairColorization,  MonacoGuidesOptions? guides,  AutoClosingBehavior? autoClosingBrackets,  AutoClosingBehavior? autoClosingQuotes,  bool? formatOnPaste,  bool? formatOnType,  bool? quickSuggestions,  bool? suggestOnTriggerCharacters,  bool? parameterHints,  bool? hover,  bool? contextMenu,  bool? selectionHighlight,  bool? occurrencesHighlight,  bool? roundedSelection,  bool? folding,  MonacoFoldingControls? showFoldingControls,  bool? links,  MonacoStickyScroll? stickyScroll,  bool? overviewRulerBorder,  bool? disableLayerHinting,  bool? disableMonospaceOptimizations,  Map<String, Object?>? extra)?  $default,) {final _that = this;
switch (_that) {
case _EditorOptions() when $default != null:
return $default(_that.language,_that.theme,_that.fontSize,_that.fontFamily,_that.fontLigatures,_that.lineHeight,_that.letterSpacing,_that.wordWrap,_that.wordWrapColumn,_that.minimap,_that.lineNumbers,_that.rulers,_that.tabSize,_that.insertSpaces,_that.detectIndentation,_that.readOnly,_that.readOnlyMessage,_that.automaticLayout,_that.padding,_that.scrollbar,_that.scrollBeyondLastLine,_that.smoothScrolling,_that.mouseWheelZoom,_that.cursorBlinking,_that.cursorStyle,_that.cursorWidth,_that.renderWhitespace,_that.renderControlCharacters,_that.renderLineHighlight,_that.bracketPairColorization,_that.guides,_that.autoClosingBrackets,_that.autoClosingQuotes,_that.formatOnPaste,_that.formatOnType,_that.quickSuggestions,_that.suggestOnTriggerCharacters,_that.parameterHints,_that.hover,_that.contextMenu,_that.selectionHighlight,_that.occurrencesHighlight,_that.roundedSelection,_that.folding,_that.showFoldingControls,_that.links,_that.stickyScroll,_that.overviewRulerBorder,_that.disableLayerHinting,_that.disableMonospaceOptimizations,_that.extra);case _:
  return null;

}
}

}

/// @nodoc


class _EditorOptions extends EditorOptions {
  const _EditorOptions({this.language, this.theme, this.fontSize, this.fontFamily, this.fontLigatures, this.lineHeight, this.letterSpacing, this.wordWrap, this.wordWrapColumn, this.minimap, this.lineNumbers,  List<int>? rulers, this.tabSize, this.insertSpaces, this.detectIndentation, this.readOnly, this.readOnlyMessage, this.automaticLayout, this.padding, this.scrollbar, this.scrollBeyondLastLine, this.smoothScrolling, this.mouseWheelZoom, this.cursorBlinking, this.cursorStyle, this.cursorWidth, this.renderWhitespace, this.renderControlCharacters, this.renderLineHighlight, this.bracketPairColorization, this.guides, this.autoClosingBrackets, this.autoClosingQuotes, this.formatOnPaste, this.formatOnType, this.quickSuggestions, this.suggestOnTriggerCharacters, this.parameterHints, this.hover, this.contextMenu, this.selectionHighlight, this.occurrencesHighlight, this.roundedSelection, this.folding, this.showFoldingControls, this.links, this.stickyScroll, this.overviewRulerBorder, this.disableLayerHinting, this.disableMonospaceOptimizations,  Map<String, Object?>? extra}): _rulers = rulers,_extra = extra,super._();
  

/// Initial document language. Only consumed at boot (the `page.boot`
/// command); use `controller.document.setLanguage` on a live editor.
@override final  MonacoLanguage? language;
/// Editor theme. When `null`, the `MonacoEditor` widget resolves a
/// theme from `Theme.of(context).brightness`; a headless
/// `MonacoController.create` falls back to `MonacoDefaults.darkTheme`.
/// Custom themes registered with `defineTheme` are selected by their
/// id: `MonacoTheme('app-dark')`.
@override final  MonacoTheme? theme;
/// Font size in pixels.
@override final  double? fontSize;
/// CSS `font-family` string (e.g. `'Fira Code, monospace'`).
@override final  String? fontFamily;
/// Whether font ligatures render (requires a compatible font).
@override final  bool? fontLigatures;
/// Line height. `0` lets Monaco compute from [fontSize]; values below
/// `8` are multipliers of the font size; `8` and above are absolute
/// pixels (Monaco's own semantics - the value is passed through).
@override final  double? lineHeight;
/// Letter spacing in pixels.
@override final  double? letterSpacing;
/// Word wrapping behavior.
@override final  MonacoWordWrap? wordWrap;
/// Wrap column used by [MonacoWordWrap.wordWrapColumn] and
/// [MonacoWordWrap.bounded].
@override final  int? wordWrapColumn;
/// Minimap (code overview strip) configuration.
@override final  MonacoMinimapOptions? minimap;
/// Line number rendering in the gutter.
@override final  MonacoLineNumbers? lineNumbers;
/// Column positions of vertical rulers (e.g. `[80, 120]`).
 final  List<int>? _rulers;
/// Column positions of vertical rulers (e.g. `[80, 120]`).
@override List<int>? get rulers {
  final value = _rulers;
  if (value == null) return null;
  if (_rulers is EqualUnmodifiableListView) return _rulers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Number of spaces a tab is equal to.
@override final  int? tabSize;
/// Whether `Tab` inserts spaces instead of a tab character.
@override final  bool? insertSpaces;
/// Whether Monaco detects indentation from file contents.
@override final  bool? detectIndentation;
/// Whether the document is read-only.
@override final  bool? readOnly;
/// Message shown when the user tries to edit a read-only document.
@override final  String? readOnlyMessage;
/// Whether the editor resizes itself with its container.
@override final  bool? automaticLayout;
/// Content padding.
@override final  MonacoPadding? padding;
/// Scrollbar configuration.
@override final  MonacoScrollbarOptions? scrollbar;
/// Whether scrolling can go beyond the last line.
@override final  bool? scrollBeyondLastLine;
/// Whether scrolling animates.
@override final  bool? smoothScrolling;
/// Whether Ctrl/Cmd + mouse wheel zooms the font.
@override final  bool? mouseWheelZoom;
/// Cursor blinking animation.
@override final  CursorBlinking? cursorBlinking;
/// Cursor shape.
@override final  CursorStyle? cursorStyle;
/// Cursor width in pixels (for [CursorStyle.line]).
@override final  int? cursorWidth;
/// Whitespace character rendering.
@override final  RenderWhitespace? renderWhitespace;
/// Whether control characters render.
@override final  bool? renderControlCharacters;
/// Current-line highlight rendering.
@override final  MonacoLineHighlight? renderLineHighlight;
/// Whether matching brackets get per-pair colors.
@override final  bool? bracketPairColorization;
/// Bracket-pair and indentation guide rendering.
@override final  MonacoGuidesOptions? guides;
/// Automatic closing of brackets.
@override final  AutoClosingBehavior? autoClosingBrackets;
/// Automatic closing of quotes.
@override final  AutoClosingBehavior? autoClosingQuotes;
/// Whether pasted text is formatted.
@override final  bool? formatOnPaste;
/// Whether text formats as you type.
@override final  bool? formatOnType;
/// Whether the suggestion widget appears while typing.
@override final  bool? quickSuggestions;
/// Whether suggestions appear on trigger characters (e.g. `.`).
@override final  bool? suggestOnTriggerCharacters;
/// Whether parameter hints appear in call sites.
@override final  bool? parameterHints;
/// Whether hover tooltips appear.
@override final  bool? hover;
/// Whether the right-click context menu is enabled.
@override final  bool? contextMenu;
/// Whether other occurrences of the selection are highlighted.
@override final  bool? selectionHighlight;
/// Whether symbol occurrences are highlighted semantically.
@override final  bool? occurrencesHighlight;
/// Whether selections render with rounded corners.
@override final  bool? roundedSelection;
/// Whether code folding is enabled.
@override final  bool? folding;
/// When the folding controls in the gutter are visible.
@override final  MonacoFoldingControls? showFoldingControls;
/// Whether links in the document are clickable.
@override final  bool? links;
/// Sticky scroll (pinned enclosing scopes) configuration.
@override final  MonacoStickyScroll? stickyScroll;
/// Whether the overview ruler draws a border.
@override final  bool? overviewRulerBorder;
/// Disables the layer-hinting render optimization (try `true` if you
/// see rendering artifacts on some platforms).
@override final  bool? disableLayerHinting;
/// Disables monospace font optimizations.
@override final  bool? disableMonospaceOptimizations;
/// Raw Monaco options merged LAST into the payload; keys here win over
/// every modeled field. The permanent escape hatch for anything not
/// modeled above.
 final  Map<String, Object?>? _extra;
/// Raw Monaco options merged LAST into the payload; keys here win over
/// every modeled field. The permanent escape hatch for anything not
/// modeled above.
@override Map<String, Object?>? get extra {
  final value = _extra;
  if (value == null) return null;
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorOptionsCopyWith<_EditorOptions> get copyWith => __$EditorOptionsCopyWithImpl<_EditorOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorOptions&&(identical(other.language, language) || other.language == language)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontLigatures, fontLigatures) || other.fontLigatures == fontLigatures)&&(identical(other.lineHeight, lineHeight) || other.lineHeight == lineHeight)&&(identical(other.letterSpacing, letterSpacing) || other.letterSpacing == letterSpacing)&&(identical(other.wordWrap, wordWrap) || other.wordWrap == wordWrap)&&(identical(other.wordWrapColumn, wordWrapColumn) || other.wordWrapColumn == wordWrapColumn)&&(identical(other.minimap, minimap) || other.minimap == minimap)&&(identical(other.lineNumbers, lineNumbers) || other.lineNumbers == lineNumbers)&&const DeepCollectionEquality().equals(other.rulers, _rulers)&&(identical(other.tabSize, tabSize) || other.tabSize == tabSize)&&(identical(other.insertSpaces, insertSpaces) || other.insertSpaces == insertSpaces)&&(identical(other.detectIndentation, detectIndentation) || other.detectIndentation == detectIndentation)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.readOnlyMessage, readOnlyMessage) || other.readOnlyMessage == readOnlyMessage)&&(identical(other.automaticLayout, automaticLayout) || other.automaticLayout == automaticLayout)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.scrollbar, scrollbar) || other.scrollbar == scrollbar)&&(identical(other.scrollBeyondLastLine, scrollBeyondLastLine) || other.scrollBeyondLastLine == scrollBeyondLastLine)&&(identical(other.smoothScrolling, smoothScrolling) || other.smoothScrolling == smoothScrolling)&&(identical(other.mouseWheelZoom, mouseWheelZoom) || other.mouseWheelZoom == mouseWheelZoom)&&(identical(other.cursorBlinking, cursorBlinking) || other.cursorBlinking == cursorBlinking)&&(identical(other.cursorStyle, cursorStyle) || other.cursorStyle == cursorStyle)&&(identical(other.cursorWidth, cursorWidth) || other.cursorWidth == cursorWidth)&&(identical(other.renderWhitespace, renderWhitespace) || other.renderWhitespace == renderWhitespace)&&(identical(other.renderControlCharacters, renderControlCharacters) || other.renderControlCharacters == renderControlCharacters)&&(identical(other.renderLineHighlight, renderLineHighlight) || other.renderLineHighlight == renderLineHighlight)&&(identical(other.bracketPairColorization, bracketPairColorization) || other.bracketPairColorization == bracketPairColorization)&&(identical(other.guides, guides) || other.guides == guides)&&(identical(other.autoClosingBrackets, autoClosingBrackets) || other.autoClosingBrackets == autoClosingBrackets)&&(identical(other.autoClosingQuotes, autoClosingQuotes) || other.autoClosingQuotes == autoClosingQuotes)&&(identical(other.formatOnPaste, formatOnPaste) || other.formatOnPaste == formatOnPaste)&&(identical(other.formatOnType, formatOnType) || other.formatOnType == formatOnType)&&(identical(other.quickSuggestions, quickSuggestions) || other.quickSuggestions == quickSuggestions)&&(identical(other.suggestOnTriggerCharacters, suggestOnTriggerCharacters) || other.suggestOnTriggerCharacters == suggestOnTriggerCharacters)&&(identical(other.parameterHints, parameterHints) || other.parameterHints == parameterHints)&&(identical(other.hover, hover) || other.hover == hover)&&(identical(other.contextMenu, contextMenu) || other.contextMenu == contextMenu)&&(identical(other.selectionHighlight, selectionHighlight) || other.selectionHighlight == selectionHighlight)&&(identical(other.occurrencesHighlight, occurrencesHighlight) || other.occurrencesHighlight == occurrencesHighlight)&&(identical(other.roundedSelection, roundedSelection) || other.roundedSelection == roundedSelection)&&(identical(other.folding, folding) || other.folding == folding)&&(identical(other.showFoldingControls, showFoldingControls) || other.showFoldingControls == showFoldingControls)&&(identical(other.links, links) || other.links == links)&&(identical(other.stickyScroll, stickyScroll) || other.stickyScroll == stickyScroll)&&(identical(other.overviewRulerBorder, overviewRulerBorder) || other.overviewRulerBorder == overviewRulerBorder)&&(identical(other.disableLayerHinting, disableLayerHinting) || other.disableLayerHinting == disableLayerHinting)&&(identical(other.disableMonospaceOptimizations, disableMonospaceOptimizations) || other.disableMonospaceOptimizations == disableMonospaceOptimizations)&&const DeepCollectionEquality().equals(other.extra, _extra));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,language,theme,fontSize,fontFamily,fontLigatures,lineHeight,letterSpacing,wordWrap,wordWrapColumn,minimap,lineNumbers,const DeepCollectionEquality().hash(_rulers),tabSize,insertSpaces,detectIndentation,readOnly,readOnlyMessage,automaticLayout,padding,scrollbar,scrollBeyondLastLine,smoothScrolling,mouseWheelZoom,cursorBlinking,cursorStyle,cursorWidth,renderWhitespace,renderControlCharacters,renderLineHighlight,bracketPairColorization,guides,autoClosingBrackets,autoClosingQuotes,formatOnPaste,formatOnType,quickSuggestions,suggestOnTriggerCharacters,parameterHints,hover,contextMenu,selectionHighlight,occurrencesHighlight,roundedSelection,folding,showFoldingControls,links,stickyScroll,overviewRulerBorder,disableLayerHinting,disableMonospaceOptimizations,const DeepCollectionEquality().hash(_extra)]);
}

@override
String toString() {
    return 'EditorOptions(language: $language, theme: $theme, fontSize: $fontSize, fontFamily: $fontFamily, fontLigatures: $fontLigatures, lineHeight: $lineHeight, letterSpacing: $letterSpacing, wordWrap: $wordWrap, wordWrapColumn: $wordWrapColumn, minimap: $minimap, lineNumbers: $lineNumbers, rulers: $rulers, tabSize: $tabSize, insertSpaces: $insertSpaces, detectIndentation: $detectIndentation, readOnly: $readOnly, readOnlyMessage: $readOnlyMessage, automaticLayout: $automaticLayout, padding: $padding, scrollbar: $scrollbar, scrollBeyondLastLine: $scrollBeyondLastLine, smoothScrolling: $smoothScrolling, mouseWheelZoom: $mouseWheelZoom, cursorBlinking: $cursorBlinking, cursorStyle: $cursorStyle, cursorWidth: $cursorWidth, renderWhitespace: $renderWhitespace, renderControlCharacters: $renderControlCharacters, renderLineHighlight: $renderLineHighlight, bracketPairColorization: $bracketPairColorization, guides: $guides, autoClosingBrackets: $autoClosingBrackets, autoClosingQuotes: $autoClosingQuotes, formatOnPaste: $formatOnPaste, formatOnType: $formatOnType, quickSuggestions: $quickSuggestions, suggestOnTriggerCharacters: $suggestOnTriggerCharacters, parameterHints: $parameterHints, hover: $hover, contextMenu: $contextMenu, selectionHighlight: $selectionHighlight, occurrencesHighlight: $occurrencesHighlight, roundedSelection: $roundedSelection, folding: $folding, showFoldingControls: $showFoldingControls, links: $links, stickyScroll: $stickyScroll, overviewRulerBorder: $overviewRulerBorder, disableLayerHinting: $disableLayerHinting, disableMonospaceOptimizations: $disableMonospaceOptimizations, extra: $extra)';
}


}

/// @nodoc
abstract mixin class _$EditorOptionsCopyWith<$Res> implements $EditorOptionsCopyWith<$Res> {
  factory _$EditorOptionsCopyWith(_EditorOptions value, $Res Function(_EditorOptions) _then) = __$EditorOptionsCopyWithImpl;
@override @useResult
$Res call({
 MonacoLanguage? language, MonacoTheme? theme, double? fontSize, String? fontFamily, bool? fontLigatures, double? lineHeight, double? letterSpacing, MonacoWordWrap? wordWrap, int? wordWrapColumn, MonacoMinimapOptions? minimap, MonacoLineNumbers? lineNumbers, List<int>? rulers, int? tabSize, bool? insertSpaces, bool? detectIndentation, bool? readOnly, String? readOnlyMessage, bool? automaticLayout, MonacoPadding? padding, MonacoScrollbarOptions? scrollbar, bool? scrollBeyondLastLine, bool? smoothScrolling, bool? mouseWheelZoom, CursorBlinking? cursorBlinking, CursorStyle? cursorStyle, int? cursorWidth, RenderWhitespace? renderWhitespace, bool? renderControlCharacters, MonacoLineHighlight? renderLineHighlight, bool? bracketPairColorization, MonacoGuidesOptions? guides, AutoClosingBehavior? autoClosingBrackets, AutoClosingBehavior? autoClosingQuotes, bool? formatOnPaste, bool? formatOnType, bool? quickSuggestions, bool? suggestOnTriggerCharacters, bool? parameterHints, bool? hover, bool? contextMenu, bool? selectionHighlight, bool? occurrencesHighlight, bool? roundedSelection, bool? folding, MonacoFoldingControls? showFoldingControls, bool? links, MonacoStickyScroll? stickyScroll, bool? overviewRulerBorder, bool? disableLayerHinting, bool? disableMonospaceOptimizations, Map<String, Object?>? extra
});


@override $MonacoMinimapOptionsCopyWith<$Res>? get minimap;@override $MonacoPaddingCopyWith<$Res>? get padding;@override $MonacoScrollbarOptionsCopyWith<$Res>? get scrollbar;@override $MonacoGuidesOptionsCopyWith<$Res>? get guides;@override $MonacoStickyScrollCopyWith<$Res>? get stickyScroll;

}
/// @nodoc
class __$EditorOptionsCopyWithImpl<$Res>
    implements _$EditorOptionsCopyWith<$Res> {
  __$EditorOptionsCopyWithImpl(this._self, this._then);

  final _EditorOptions _self;
  final $Res Function(_EditorOptions) _then;

/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = freezed,Object? theme = freezed,Object? fontSize = freezed,Object? fontFamily = freezed,Object? fontLigatures = freezed,Object? lineHeight = freezed,Object? letterSpacing = freezed,Object? wordWrap = freezed,Object? wordWrapColumn = freezed,Object? minimap = freezed,Object? lineNumbers = freezed,Object? rulers = freezed,Object? tabSize = freezed,Object? insertSpaces = freezed,Object? detectIndentation = freezed,Object? readOnly = freezed,Object? readOnlyMessage = freezed,Object? automaticLayout = freezed,Object? padding = freezed,Object? scrollbar = freezed,Object? scrollBeyondLastLine = freezed,Object? smoothScrolling = freezed,Object? mouseWheelZoom = freezed,Object? cursorBlinking = freezed,Object? cursorStyle = freezed,Object? cursorWidth = freezed,Object? renderWhitespace = freezed,Object? renderControlCharacters = freezed,Object? renderLineHighlight = freezed,Object? bracketPairColorization = freezed,Object? guides = freezed,Object? autoClosingBrackets = freezed,Object? autoClosingQuotes = freezed,Object? formatOnPaste = freezed,Object? formatOnType = freezed,Object? quickSuggestions = freezed,Object? suggestOnTriggerCharacters = freezed,Object? parameterHints = freezed,Object? hover = freezed,Object? contextMenu = freezed,Object? selectionHighlight = freezed,Object? occurrencesHighlight = freezed,Object? roundedSelection = freezed,Object? folding = freezed,Object? showFoldingControls = freezed,Object? links = freezed,Object? stickyScroll = freezed,Object? overviewRulerBorder = freezed,Object? disableLayerHinting = freezed,Object? disableMonospaceOptimizations = freezed,Object? extra = freezed,}) {
  return _then(_EditorOptions(
language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as MonacoLanguage?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as MonacoTheme?,fontSize: freezed == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double?,fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,fontLigatures: freezed == fontLigatures ? _self.fontLigatures : fontLigatures // ignore: cast_nullable_to_non_nullable
as bool?,lineHeight: freezed == lineHeight ? _self.lineHeight : lineHeight // ignore: cast_nullable_to_non_nullable
as double?,letterSpacing: freezed == letterSpacing ? _self.letterSpacing : letterSpacing // ignore: cast_nullable_to_non_nullable
as double?,wordWrap: freezed == wordWrap ? _self.wordWrap : wordWrap // ignore: cast_nullable_to_non_nullable
as MonacoWordWrap?,wordWrapColumn: freezed == wordWrapColumn ? _self.wordWrapColumn : wordWrapColumn // ignore: cast_nullable_to_non_nullable
as int?,minimap: freezed == minimap ? _self.minimap : minimap // ignore: cast_nullable_to_non_nullable
as MonacoMinimapOptions?,lineNumbers: freezed == lineNumbers ? _self.lineNumbers : lineNumbers // ignore: cast_nullable_to_non_nullable
as MonacoLineNumbers?,rulers: freezed == rulers ? _self._rulers : rulers // ignore: cast_nullable_to_non_nullable
as List<int>?,tabSize: freezed == tabSize ? _self.tabSize : tabSize // ignore: cast_nullable_to_non_nullable
as int?,insertSpaces: freezed == insertSpaces ? _self.insertSpaces : insertSpaces // ignore: cast_nullable_to_non_nullable
as bool?,detectIndentation: freezed == detectIndentation ? _self.detectIndentation : detectIndentation // ignore: cast_nullable_to_non_nullable
as bool?,readOnly: freezed == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool?,readOnlyMessage: freezed == readOnlyMessage ? _self.readOnlyMessage : readOnlyMessage // ignore: cast_nullable_to_non_nullable
as String?,automaticLayout: freezed == automaticLayout ? _self.automaticLayout : automaticLayout // ignore: cast_nullable_to_non_nullable
as bool?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as MonacoPadding?,scrollbar: freezed == scrollbar ? _self.scrollbar : scrollbar // ignore: cast_nullable_to_non_nullable
as MonacoScrollbarOptions?,scrollBeyondLastLine: freezed == scrollBeyondLastLine ? _self.scrollBeyondLastLine : scrollBeyondLastLine // ignore: cast_nullable_to_non_nullable
as bool?,smoothScrolling: freezed == smoothScrolling ? _self.smoothScrolling : smoothScrolling // ignore: cast_nullable_to_non_nullable
as bool?,mouseWheelZoom: freezed == mouseWheelZoom ? _self.mouseWheelZoom : mouseWheelZoom // ignore: cast_nullable_to_non_nullable
as bool?,cursorBlinking: freezed == cursorBlinking ? _self.cursorBlinking : cursorBlinking // ignore: cast_nullable_to_non_nullable
as CursorBlinking?,cursorStyle: freezed == cursorStyle ? _self.cursorStyle : cursorStyle // ignore: cast_nullable_to_non_nullable
as CursorStyle?,cursorWidth: freezed == cursorWidth ? _self.cursorWidth : cursorWidth // ignore: cast_nullable_to_non_nullable
as int?,renderWhitespace: freezed == renderWhitespace ? _self.renderWhitespace : renderWhitespace // ignore: cast_nullable_to_non_nullable
as RenderWhitespace?,renderControlCharacters: freezed == renderControlCharacters ? _self.renderControlCharacters : renderControlCharacters // ignore: cast_nullable_to_non_nullable
as bool?,renderLineHighlight: freezed == renderLineHighlight ? _self.renderLineHighlight : renderLineHighlight // ignore: cast_nullable_to_non_nullable
as MonacoLineHighlight?,bracketPairColorization: freezed == bracketPairColorization ? _self.bracketPairColorization : bracketPairColorization // ignore: cast_nullable_to_non_nullable
as bool?,guides: freezed == guides ? _self.guides : guides // ignore: cast_nullable_to_non_nullable
as MonacoGuidesOptions?,autoClosingBrackets: freezed == autoClosingBrackets ? _self.autoClosingBrackets : autoClosingBrackets // ignore: cast_nullable_to_non_nullable
as AutoClosingBehavior?,autoClosingQuotes: freezed == autoClosingQuotes ? _self.autoClosingQuotes : autoClosingQuotes // ignore: cast_nullable_to_non_nullable
as AutoClosingBehavior?,formatOnPaste: freezed == formatOnPaste ? _self.formatOnPaste : formatOnPaste // ignore: cast_nullable_to_non_nullable
as bool?,formatOnType: freezed == formatOnType ? _self.formatOnType : formatOnType // ignore: cast_nullable_to_non_nullable
as bool?,quickSuggestions: freezed == quickSuggestions ? _self.quickSuggestions : quickSuggestions // ignore: cast_nullable_to_non_nullable
as bool?,suggestOnTriggerCharacters: freezed == suggestOnTriggerCharacters ? _self.suggestOnTriggerCharacters : suggestOnTriggerCharacters // ignore: cast_nullable_to_non_nullable
as bool?,parameterHints: freezed == parameterHints ? _self.parameterHints : parameterHints // ignore: cast_nullable_to_non_nullable
as bool?,hover: freezed == hover ? _self.hover : hover // ignore: cast_nullable_to_non_nullable
as bool?,contextMenu: freezed == contextMenu ? _self.contextMenu : contextMenu // ignore: cast_nullable_to_non_nullable
as bool?,selectionHighlight: freezed == selectionHighlight ? _self.selectionHighlight : selectionHighlight // ignore: cast_nullable_to_non_nullable
as bool?,occurrencesHighlight: freezed == occurrencesHighlight ? _self.occurrencesHighlight : occurrencesHighlight // ignore: cast_nullable_to_non_nullable
as bool?,roundedSelection: freezed == roundedSelection ? _self.roundedSelection : roundedSelection // ignore: cast_nullable_to_non_nullable
as bool?,folding: freezed == folding ? _self.folding : folding // ignore: cast_nullable_to_non_nullable
as bool?,showFoldingControls: freezed == showFoldingControls ? _self.showFoldingControls : showFoldingControls // ignore: cast_nullable_to_non_nullable
as MonacoFoldingControls?,links: freezed == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as bool?,stickyScroll: freezed == stickyScroll ? _self.stickyScroll : stickyScroll // ignore: cast_nullable_to_non_nullable
as MonacoStickyScroll?,overviewRulerBorder: freezed == overviewRulerBorder ? _self.overviewRulerBorder : overviewRulerBorder // ignore: cast_nullable_to_non_nullable
as bool?,disableLayerHinting: freezed == disableLayerHinting ? _self.disableLayerHinting : disableLayerHinting // ignore: cast_nullable_to_non_nullable
as bool?,disableMonospaceOptimizations: freezed == disableMonospaceOptimizations ? _self.disableMonospaceOptimizations : disableMonospaceOptimizations // ignore: cast_nullable_to_non_nullable
as bool?,extra: freezed == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}

/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoMinimapOptionsCopyWith<$Res>? get minimap {
    if (_self.minimap == null) {
    return null;
  }

  return $MonacoMinimapOptionsCopyWith<$Res>(_self.minimap!, (value) {
    return _then(_self.copyWith(minimap: value));
  });
}/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoPaddingCopyWith<$Res>? get padding {
    if (_self.padding == null) {
    return null;
  }

  return $MonacoPaddingCopyWith<$Res>(_self.padding!, (value) {
    return _then(_self.copyWith(padding: value));
  });
}/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoScrollbarOptionsCopyWith<$Res>? get scrollbar {
    if (_self.scrollbar == null) {
    return null;
  }

  return $MonacoScrollbarOptionsCopyWith<$Res>(_self.scrollbar!, (value) {
    return _then(_self.copyWith(scrollbar: value));
  });
}/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoGuidesOptionsCopyWith<$Res>? get guides {
    if (_self.guides == null) {
    return null;
  }

  return $MonacoGuidesOptionsCopyWith<$Res>(_self.guides!, (value) {
    return _then(_self.copyWith(guides: value));
  });
}/// Create a copy of EditorOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoStickyScrollCopyWith<$Res>? get stickyScroll {
    if (_self.stickyScroll == null) {
    return null;
  }

  return $MonacoStickyScrollCopyWith<$Res>(_self.stickyScroll!, (value) {
    return _then(_self.copyWith(stickyScroll: value));
  });
}
}

// dart format on
