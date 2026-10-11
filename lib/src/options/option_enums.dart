// Option enums for the Monaco editor configuration surface.
//
// Each enum value exposes an `id` that is the exact wire string the Monaco
// editor expects for the corresponding option.

/// Controls how lines are wrapped in the editor.
enum MonacoWordWrap {
  /// Lines never wrap.
  off('off'),

  /// Lines wrap at the viewport width.
  on('on'),

  /// Lines wrap at the configured word wrap column.
  wordWrapColumn('wordWrapColumn'),

  /// Lines wrap at the minimum of the viewport width and the configured
  /// word wrap column.
  bounded('bounded');

  const MonacoWordWrap(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;
}

/// Controls how line numbers are rendered in the editor gutter.
enum MonacoLineNumbers {
  /// Line numbers are not rendered.
  off('off'),

  /// Absolute line numbers are rendered.
  on('on'),

  /// Line numbers are rendered relative to the cursor position.
  relative('relative'),

  /// Line numbers are rendered every 10 lines.
  interval('interval');

  const MonacoLineNumbers(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;
}

/// Controls how the current line is highlighted.
enum MonacoLineHighlight {
  /// The current line is not highlighted.
  none('none'),

  /// Only the gutter of the current line is highlighted.
  gutter('gutter'),

  /// Only the content of the current line is highlighted.
  line('line'),

  /// Both the gutter and the content of the current line are highlighted.
  all('all');

  const MonacoLineHighlight(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;
}

/// Controls when the folding controls in the gutter are shown.
enum MonacoFoldingControls {
  /// Folding controls are always visible.
  always('always'),

  /// Folding controls are shown only when hovering over the gutter.
  mouseover('mouseover'),

  /// Folding controls are never shown.
  never('never');

  const MonacoFoldingControls(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;
}

/// Controls the visibility of an editor scrollbar.
enum MonacoScrollbarVisibility {
  /// The scrollbar is shown automatically based on the content size.
  auto('auto'),

  /// The scrollbar is always visible.
  visible('visible'),

  /// The scrollbar is never visible.
  hidden('hidden');

  const MonacoScrollbarVisibility(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;
}

/// Controls on which side of the editor the minimap is rendered.
enum MonacoMinimapSide {
  /// The minimap is rendered on the left side of the editor.
  left('left'),

  /// The minimap is rendered on the right side of the editor.
  right('right');

  const MonacoMinimapSide(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;
}

/// The base themes bundled with the Monaco editor.
enum MonacoBaseTheme {
  /// The standard light theme.
  vs('vs'),

  /// The standard dark theme.
  vsDark('vs-dark'),

  /// A high-contrast dark theme for accessibility.
  hcBlack('hc-black'),

  /// A high-contrast light theme for accessibility.
  hcLight('hc-light');

  const MonacoBaseTheme(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;
}

/// Defines the animation style of the editor's cursor.
enum CursorBlinking {
  /// The cursor blinks smoothly.
  blink('blink', 'Blink'),

  /// The cursor fades in and out.
  smooth('smooth', 'Smooth'),

  /// The cursor changes its opacity.
  phase('phase', 'Phase'),

  /// The cursor expands and contracts.
  expand('expand', 'Expand'),

  /// The cursor is a solid, non-blinking block.
  solid('solid', 'Solid');

  const CursorBlinking(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the cursor style.
  final String label;

  /// Creates a [CursorBlinking] style from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static CursorBlinking fromId(
    String? id, {
    CursorBlinking orElse = CursorBlinking.blink,
  }) {
    if (id == null) return orElse;
    return CursorBlinking.values.firstWhere(
      (c) => c.id == id,
      orElse: () => orElse,
    );
  }
}

/// Defines the visual style of the editor's cursor.
enum CursorStyle {
  /// A vertical line.
  line('line', 'Line'),

  /// A solid block.
  block('block', 'Block'),

  /// A horizontal line below the character.
  underline('underline', 'Underline'),

  /// A thin vertical line.
  lineThin('line-thin', 'Line Thin'),

  /// An outlined block.
  blockOutline('block-outline', 'Block Outline'),

  /// A thin horizontal line below the character.
  underlineThin('underline-thin', 'Underline Thin');

  const CursorStyle(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the cursor style.
  final String label;

  /// Creates a [CursorStyle] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static CursorStyle fromId(
    String? id, {
    CursorStyle orElse = CursorStyle.line,
  }) {
    if (id == null) return orElse;
    return CursorStyle.values.firstWhere(
      (c) => c.id == id,
      orElse: () => orElse,
    );
  }
}

/// Defines how whitespace characters are rendered in the editor.
enum RenderWhitespace {
  /// No whitespace is rendered.
  none('none', 'None'),

  /// Whitespace is rendered at the boundary of words.
  boundary('boundary', 'Boundary'),

  /// Whitespace is rendered only in selected text.
  selection('selection', 'Selection'),

  /// Only trailing whitespace is rendered.
  trailing('trailing', 'Trailing'),

  /// All whitespace is rendered.
  all('all', 'All');

  const RenderWhitespace(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the whitespace rendering option.
  final String label;

  /// Creates a [RenderWhitespace] option from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static RenderWhitespace fromId(
    String? id, {
    RenderWhitespace orElse = RenderWhitespace.selection,
  }) {
    if (id == null) return orElse;
    return RenderWhitespace.values.firstWhere(
      (r) => r.id == id,
      orElse: () => orElse,
    );
  }
}

/// Defines the automatic closing behavior for brackets and quotes.
enum AutoClosingBehavior {
  /// Brackets and quotes are always automatically closed.
  always('always', 'Always'),

  /// Behavior is determined by the language's configuration.
  languageDefined('languageDefined', 'Language Defined'),

  /// Brackets and quotes are closed only when the cursor is before whitespace.
  beforeWhitespace('beforeWhitespace', 'Before Whitespace'),

  /// Brackets and quotes are never automatically closed.
  never('never', 'Never');

  const AutoClosingBehavior(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the behavior.
  final String label;

  /// Creates an [AutoClosingBehavior] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static AutoClosingBehavior fromId(
    String? id, {
    AutoClosingBehavior orElse = AutoClosingBehavior.languageDefined,
  }) {
    if (id == null) return orElse;
    return AutoClosingBehavior.values.firstWhere(
      (a) => a.id == id,
      orElse: () => orElse,
    );
  }
}

/// Severity levels for Monaco's JSON language diagnostics.
///
/// Used by [JsonDiagnosticsOptions] fields such as
/// [JsonDiagnosticsOptions.schemaValidation] and
/// [JsonDiagnosticsOptions.trailingCommas] to control how specific issues
/// are surfaced in the editor.
///
/// This is separate from [MarkerSeverity], which controls inline markers
/// set programmatically via `MonacoDocument.setMarkers`.
enum DiagnosticsSeverity {
  /// Shown as a red squiggly underline. Blocks "no errors" status.
  error('error'),

  /// Shown as a yellow squiggly underline. Does not block "no errors" status.
  warning('warning'),

  /// Suppresses the diagnostic entirely - no underline, no Problems entry.
  ignore('ignore');

  /// The string value passed to Monaco's JavaScript API.
  final String id;

  const DiagnosticsSeverity(this.id);

  /// Resolves a Monaco severity string to a [DiagnosticsSeverity] value.
  ///
  /// Returns [orElse] (defaults to [warning]) when [id] is `null` or does
  /// not match any known value. This makes it safe for parsing external or
  /// user-provided configuration without throwing.
  static DiagnosticsSeverity fromId(
    String? id, {
    DiagnosticsSeverity orElse = DiagnosticsSeverity.warning,
  }) {
    if (id == null) return orElse;
    return DiagnosticsSeverity.values.firstWhere(
      (s) => s.id == id,
      orElse: () => orElse,
    );
  }
}

/// Controls the width used to render full-width characters (Monaco
/// `fullwidthCharacterWidth`, added in Monaco 0.57).
enum MonacoFullwidthCharacterWidth {
  /// Full-width characters use the width defined by the font (Monaco's
  /// default).
  font('font'),

  /// Full-width characters render centered in exactly two character cells,
  /// keeping columns aligned.
  ///
  /// Only applies to monospace fonts (Monaco behaves as [font] otherwise),
  /// does not apply to multi-code-point full-width characters or to GPU
  /// rendering, and costs some line-rendering performance.
  twoCells('twoCells');

  const MonacoFullwidthCharacterWidth(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;

  /// Creates a [MonacoFullwidthCharacterWidth] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static MonacoFullwidthCharacterWidth fromId(
    String? id, {
    MonacoFullwidthCharacterWidth orElse = MonacoFullwidthCharacterWidth.font,
  }) {
    if (id == null) return orElse;
    return MonacoFullwidthCharacterWidth.values.firstWhere(
      (w) => w.id == id,
      orElse: () => orElse,
    );
  }
}

/// Controls whether the find widget's search string is seeded from the
/// editor selection (Monaco `find.seedSearchStringFromSelection`).
enum MonacoFindSeedSearchString {
  /// Never seed the search string from the editor selection.
  never('never'),

  /// Always seed the search string from the editor selection, including
  /// the word at the cursor when nothing is selected (Monaco's default).
  always('always'),

  /// Seed the search string only from a non-empty editor selection.
  selection('selection');

  const MonacoFindSeedSearchString(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;

  /// Creates a [MonacoFindSeedSearchString] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static MonacoFindSeedSearchString fromId(
    String? id, {
    MonacoFindSeedSearchString orElse = MonacoFindSeedSearchString.always,
  }) {
    if (id == null) return orElse;
    return MonacoFindSeedSearchString.values.firstWhere(
      (s) => s.id == id,
      orElse: () => orElse,
    );
  }
}

/// Controls when the find widget turns on "Find in Selection"
/// automatically (Monaco `find.autoFindInSelection`).
enum MonacoAutoFindInSelection {
  /// Never turn on Find in Selection automatically (Monaco's default).
  never('never'),

  /// Always turn on Find in Selection automatically.
  always('always'),

  /// Turn on Find in Selection automatically when multiple lines of
  /// content are selected.
  multiline('multiline');

  const MonacoAutoFindInSelection(this.id);

  /// The wire string sent to the Monaco editor.
  final String id;

  /// Creates a [MonacoAutoFindInSelection] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static MonacoAutoFindInSelection fromId(
    String? id, {
    MonacoAutoFindInSelection orElse = MonacoAutoFindInSelection.never,
  }) {
    if (id == null) return orElse;
    return MonacoAutoFindInSelection.values.firstWhere(
      (a) => a.id == id,
      orElse: () => orElse,
    );
  }
}
