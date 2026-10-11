import 'package:flutter_monaco/src/options/language.dart';
import 'package:flutter_monaco/src/options/theme.dart';
import 'package:flutter_monaco/src/types/geometry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats.freezed.dart';

/// Real-time editor statistics, updated on every content or cursor change
/// via the `stats` protocol event.
@freezed
sealed class MonacoLiveStats with _$MonacoLiveStats {
  /// Creates a statistics snapshot.
  const factory MonacoLiveStats({
    /// Total number of lines in the document.
    @Default(0) int lineCount,

    /// Total number of characters in the document.
    @Default(0) int charCount,

    /// Number of lines covered by the primary selection (0 when empty).
    @Default(0) int selectedLines,

    /// Number of characters in the primary selection (0 when empty).
    @Default(0) int selectedCharacters,

    /// Number of active cursors (1 unless multi-cursor editing).
    @Default(1) int caretCount,

    /// Primary cursor position, when known.
    Position? cursorPosition,

    /// Active document language, when known.
    MonacoLanguage? language,
  }) = _MonacoLiveStats;

  const MonacoLiveStats._();

  /// Parses the `stats` event payload.
  ///
  /// Wire keys: `lineCount`, `charCount`, `selLines`, `selChars`,
  /// `caretCount`, `language`, `cursorLine`, `cursorColumn`. Missing
  /// fields default; wrongly-typed fields throw [FormatException].
  factory MonacoLiveStats.fromJson(Map<String, dynamic> json) {
    final cursorLine = _optInt(json, 'cursorLine');
    final cursorColumn = _optInt(json, 'cursorColumn');
    final language = json['language'];
    if (language != null && language is! String) {
      throw FormatException(
        'MonacoLiveStats.fromJson: "language" must be a string, got $language',
      );
    }
    return MonacoLiveStats(
      lineCount: _optInt(json, 'lineCount') ?? 0,
      charCount: _optInt(json, 'charCount') ?? 0,
      selectedLines: _optInt(json, 'selLines') ?? 0,
      selectedCharacters: _optInt(json, 'selChars') ?? 0,
      caretCount: _optInt(json, 'caretCount') ?? 1,
      cursorPosition: (cursorLine != null && cursorColumn != null)
          ? Position(line: cursorLine, column: cursorColumn)
          : null,
      language: language is String ? MonacoLanguage(language) : null,
    );
  }

  /// Whether the primary selection is non-empty.
  bool get hasSelection => selectedCharacters > 0;

  /// Whether more than one cursor is active.
  bool get hasMultipleCursors => caretCount > 1;
}

/// A full snapshot of the editor, produced by
/// `MonacoController.getEditorState` in a single bridge round trip.
@freezed
sealed class EditorState with _$EditorState {
  /// Creates an editor state snapshot.
  const factory EditorState({
    /// Full document text.
    required String content,

    /// Primary selection, when one exists.
    Range? selection,

    /// Primary cursor position, when known.
    Position? cursorPosition,

    /// Total number of lines.
    @Default(0) int lineCount,

    /// Whether the document changed since the last `markSaved`.
    @Default(false) bool isDirty,

    /// Active document language, when known.
    MonacoLanguage? language,

    /// Active theme, when known.
    MonacoTheme? theme,

    /// Live statistics at snapshot time.
    @Default(MonacoLiveStats()) MonacoLiveStats stats,
  }) = _EditorState;

  const EditorState._();

  /// Parses the `editor.getState` response payload.
  ///
  /// Throws [FormatException] on a missing/invalid `content` or
  /// wrongly-typed optional fields.
  factory EditorState.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    if (content is! String) {
      throw FormatException(
        'EditorState.fromJson: "content" must be a string, got '
        '${content.runtimeType}',
      );
    }
    final selection = json['selection'];
    if (selection != null && selection is! Map) {
      throw const FormatException(
        'EditorState.fromJson: "selection" must be a map',
      );
    }
    final cursorPosition = json['cursorPosition'];
    if (cursorPosition != null && cursorPosition is! Map) {
      throw const FormatException(
        'EditorState.fromJson: "cursorPosition" must be a map',
      );
    }
    final language = json['language'];
    if (language != null && language is! String) {
      throw const FormatException(
        'EditorState.fromJson: "language" must be a string',
      );
    }
    final theme = json['theme'];
    if (theme != null && theme is! String) {
      throw const FormatException(
        'EditorState.fromJson: "theme" must be a string',
      );
    }
    final isDirty = json['isDirty'];
    if (isDirty != null && isDirty is! bool) {
      throw const FormatException(
        'EditorState.fromJson: "isDirty" must be a bool',
      );
    }
    final stats = json['stats'];
    if (stats != null && stats is! Map) {
      throw const FormatException(
        'EditorState.fromJson: "stats" must be a map',
      );
    }

    return EditorState(
      content: content,
      selection: selection is Map
          ? Range.fromJson(Map<String, dynamic>.from(selection))
          : null,
      cursorPosition: cursorPosition is Map
          ? Position.fromJson(Map<String, dynamic>.from(cursorPosition))
          : null,
      lineCount: _optInt(json, 'lineCount') ?? 0,
      isDirty: isDirty is bool && isDirty,
      language: language is String ? MonacoLanguage(language) : null,
      theme: theme is String ? MonacoTheme(theme) : null,
      stats: stats is Map
          ? MonacoLiveStats.fromJson(Map<String, dynamic>.from(stats))
          : const MonacoLiveStats(),
    );
  }
}

int? _optInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  // Web numbers are doubles: `2.0 is int` and `double.infinity is int` hold.
  if (value is int && value.isFinite) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  throw FormatException('stats: "$key" must be an integer, got $value');
}
