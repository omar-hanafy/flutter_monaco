import 'package:freezed_annotation/freezed_annotation.dart';

part 'geometry.freezed.dart';

/// Represents a position in the editor, using 1-based indexing for lines and
/// columns.
@freezed
sealed class Position with _$Position {
  /// Creates a position with the given 1-based [line] and [column].
  const factory Position({
    /// The 1-based line number.
    required int line,

    /// The 1-based column number.
    required int column,
  }) = _Position;

  const Position._();

  /// Creates a [Position] from a JSON map.
  ///
  /// Expects the exact wire keys `lineNumber` and `column`, both numbers.
  /// Throws a [FormatException] if either key is missing or not a number.
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      line: _requireInt(json, 'Position', 'lineNumber'),
      column: _requireInt(json, 'Position', 'column'),
    );
  }

  /// Creates a [Position] from 0-based [line] and [column] indices.
  factory Position.fromZeroBased(int line, int column) {
    return Position(line: line + 1, column: column + 1);
  }

  /// The 0-based line number.
  int get lineZeroBased => line - 1;

  /// The 0-based column number.
  int get columnZeroBased => column - 1;

  /// Converts the position to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'lineNumber': line, 'column': column};
}

/// Represents a range in the editor, defined by a start and end [Position].
///
/// The range is inclusive of the start and end positions.
@freezed
sealed class Range with _$Range {
  /// Creates a range with the given 1-based start and end coordinates.
  const factory Range({
    /// The 1-based line number where the range starts.
    required int startLine,

    /// The 1-based column number where the range starts.
    required int startColumn,

    /// The 1-based line number where the range ends.
    required int endLine,

    /// The 1-based column number where the range ends.
    required int endColumn,
  }) = _Range;

  const Range._();

  /// Creates a [Range] from a start and end [Position].
  factory Range.fromPositions(Position start, Position end) {
    return Range(
      startLine: start.line,
      startColumn: start.column,
      endLine: end.line,
      endColumn: end.column,
    );
  }

  /// Creates a [Range] that covers a single line.
  ///
  /// If [endColumn] is not provided, it defaults to [startColumn], creating a
  /// collapsed range at that position.
  factory Range.singleLine(int line, {int startColumn = 1, int? endColumn}) {
    return Range(
      startLine: line,
      startColumn: startColumn,
      endLine: line,
      endColumn: endColumn ?? startColumn,
    );
  }

  /// Creates a [Range] that covers one or more entire lines, from the beginning
  /// of the [startLine] to the end of the [endLine].
  factory Range.lines(int startLine, int endLine) {
    return Range(
      startLine: startLine,
      startColumn: 1,
      endLine: endLine,
      endColumn: 2147483647, // Max int32, effectively end of line
    );
  }

  /// Creates a [Range] from a JSON map.
  ///
  /// Expects the exact wire keys `startLineNumber`, `startColumn`,
  /// `endLineNumber`, and `endColumn`, all numbers. Throws a
  /// [FormatException] if any key is missing or not a number.
  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      startLine: _requireInt(json, 'Range', 'startLineNumber'),
      startColumn: _requireInt(json, 'Range', 'startColumn'),
      endLine: _requireInt(json, 'Range', 'endLineNumber'),
      endColumn: _requireInt(json, 'Range', 'endColumn'),
    );
  }

  /// Converts the range to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'startLineNumber': startLine,
    'startColumn': startColumn,
    'endLineNumber': endLine,
    'endColumn': endColumn,
  };

  /// The starting position of the range.
  Position get startPosition => Position(line: startLine, column: startColumn);

  /// The ending position of the range.
  Position get endPosition => Position(line: endLine, column: endColumn);

  /// Returns `true` if the range is collapsed (i.e., has zero length).
  bool get isCollapsed => startLine == endLine && startColumn == endColumn;

  /// Checks if the given [position] is inside this range.
  bool containsPosition(Position position) {
    if (position.line < startLine || position.line > endLine) {
      return false;
    }
    if (position.line == startLine && position.column < startColumn) {
      return false;
    }
    if (position.line == endLine && position.column > endColumn) {
      return false;
    }
    return true;
  }

  /// Checks if this range intersects with [other].
  bool intersects(Range other) {
    return !(endLine < other.startLine ||
        other.endLine < startLine ||
        (endLine == other.startLine && endColumn < other.startColumn) ||
        (other.endLine == startLine && other.endColumn < startColumn));
  }
}

/// Throws a [FormatException] describing a missing or invalid wire value.
Never _fail(String type, String key, String expected, Object? value) {
  final actual = value == null ? 'missing or null' : '${value.runtimeType}';
  throw FormatException(
    '$type.fromJson: missing/invalid "$key" (expected $expected, was $actual)',
  );
}

/// Reads a required integer at [key], accepting integral [num] wire values.
int _requireInt(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  // Web numbers are doubles: `2.0 is int` and `double.infinity is int` hold.
  if (value is int && value.isFinite) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  _fail(type, key, 'int', value);
}
