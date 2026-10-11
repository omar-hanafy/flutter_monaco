import 'package:flutter_monaco/src/types/geometry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text.freezed.dart';

/// Represents a single text edit operation to be applied to the editor.
@freezed
sealed class EditOperation with _$EditOperation {
  /// Creates an edit operation.
  const factory EditOperation({
    /// The range of text to be replaced.
    required Range range,

    /// The new text to insert. An empty string results in a deletion.
    required String text,

    /// If `true`, forces markers to move with the text.
    bool? forceMoveMarkers,
  }) = _EditOperation;

  const EditOperation._();

  /// A convenience factory for creating an insertion operation at a [position].
  factory EditOperation.insert({
    required Position position,
    required String text,
    bool? forceMoveMarkers,
  }) {
    return EditOperation(
      range: Range.fromPositions(position, position),
      text: text,
      forceMoveMarkers: forceMoveMarkers,
    );
  }

  /// A convenience factory for creating a deletion operation over a [range].
  factory EditOperation.delete({required Range range, bool? forceMoveMarkers}) {
    return EditOperation(
      range: range,
      text: '',
      forceMoveMarkers: forceMoveMarkers,
    );
  }

  /// Creates an [EditOperation] from a JSON map.
  ///
  /// Expects a required `range` map and a required `text` string, plus an
  /// optional `forceMoveMarkers` bool. Throws a [FormatException] if a
  /// required key is missing or any present key has the wrong type.
  factory EditOperation.fromJson(Map<String, dynamic> json) {
    return EditOperation(
      range: Range.fromJson(_requireMap(json, 'EditOperation', 'range')),
      text: _requireString(json, 'EditOperation', 'text'),
      forceMoveMarkers: _optionalBool(
        json,
        'EditOperation',
        'forceMoveMarkers',
      ),
    );
  }

  /// Converts the edit operation to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'range': range.toJson(), 'text': text};
    if (forceMoveMarkers != null) {
      json['forceMoveMarkers'] = forceMoveMarkers;
    }
    return json;
  }
}

/// Represents a single content change reported by the editor over the wire.
///
/// Mirrors Monaco's model content change events: [range] is the replaced
/// range in the pre-change document and [text] is the inserted text (empty
/// for a pure deletion).
@freezed
sealed class MonacoTextChange with _$MonacoTextChange {
  /// Creates a text change.
  const factory MonacoTextChange({
    /// The range of text that was replaced.
    required Range range,

    /// The new text that was inserted. An empty string means a deletion.
    required String text,
  }) = _MonacoTextChange;

  const MonacoTextChange._();

  /// Creates a [MonacoTextChange] from a JSON map.
  ///
  /// Expects a required `range` map and a required `text` string. Throws a
  /// [FormatException] if either key is missing or has the wrong type.
  factory MonacoTextChange.fromJson(Map<String, dynamic> json) {
    return MonacoTextChange(
      range: Range.fromJson(_requireMap(json, 'MonacoTextChange', 'range')),
      text: _requireString(json, 'MonacoTextChange', 'text'),
    );
  }

  /// Converts the text change to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'range': range.toJson(), 'text': text};
}

/// Represents a single match found during a find operation.
@freezed
sealed class FindMatch with _$FindMatch {
  /// Creates a find match result.
  const factory FindMatch({
    /// The range of the matched text.
    required Range range,

    /// The text that was matched.
    String? match,
  }) = _FindMatch;

  const FindMatch._();

  /// Creates a [FindMatch] from a JSON map.
  ///
  /// Expects a required `range` map and an optional `match` string. Throws a
  /// [FormatException] if `range` is missing or any present key has the
  /// wrong type.
  factory FindMatch.fromJson(Map<String, dynamic> json) {
    return FindMatch(
      range: Range.fromJson(_requireMap(json, 'FindMatch', 'range')),
      match: _optionalString(json, 'FindMatch', 'match'),
    );
  }

  /// Converts the find match to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'range': range.toJson(),
    if (match != null) 'match': match,
  };
}

/// Defines options for programmatic find operations.
@freezed
sealed class FindOptions with _$FindOptions {
  /// Creates find options.
  const factory FindOptions({
    /// If `true`, treats the search query as a regular expression.
    @Default(false) bool isRegex,

    /// If `true`, performs a case-sensitive search.
    @Default(false) bool matchCase,

    /// If `true`, only matches whole words.
    @Default(false) bool wholeWord,

    /// If `true`, searches only within the editable range of the document.
    bool? searchOnlyEditableRange,

    /// The maximum number of matches to find.
    int? limitResultCount,
  }) = _FindOptions;

  /// A convenience factory for creating case-sensitive find options.
  factory FindOptions.caseSensitive({
    bool isRegex = false,
    bool wholeWord = false,
  }) {
    return FindOptions(isRegex: isRegex, matchCase: true, wholeWord: wholeWord);
  }

  /// A convenience factory for creating regular expression find options.
  factory FindOptions.regex({bool matchCase = false}) {
    return FindOptions(isRegex: true, matchCase: matchCase, wholeWord: false);
  }

  const FindOptions._();

  /// Creates [FindOptions] from a JSON map.
  ///
  /// `isRegex`, `matchCase`, and `wholeWord` default to `false` when absent;
  /// `searchOnlyEditableRange` and `limitResultCount` are `null` when absent.
  /// Throws a [FormatException] if any present key has the wrong type.
  factory FindOptions.fromJson(Map<String, dynamic> json) {
    return FindOptions(
      isRegex: _optionalBool(json, 'FindOptions', 'isRegex') ?? false,
      matchCase: _optionalBool(json, 'FindOptions', 'matchCase') ?? false,
      wholeWord: _optionalBool(json, 'FindOptions', 'wholeWord') ?? false,
      searchOnlyEditableRange: _optionalBool(
        json,
        'FindOptions',
        'searchOnlyEditableRange',
      ),
      limitResultCount: _optionalInt(json, 'FindOptions', 'limitResultCount'),
    );
  }

  /// Converts the find options to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'isRegex': isRegex,
      'matchCase': matchCase,
      'wholeWord': wholeWord,
    };
    if (searchOnlyEditableRange != null) {
      json['searchOnlyEditableRange'] = searchOnlyEditableRange;
    }
    if (limitResultCount != null) {
      json['limitResultCount'] = limitResultCount;
    }
    return json;
  }
}

/// Throws a [FormatException] describing a missing or invalid wire value.
Never _fail(String type, String key, String expected, Object? value) {
  final actual = value == null ? 'missing or null' : '${value.runtimeType}';
  throw FormatException(
    '$type.fromJson: missing/invalid "$key" (expected $expected, was $actual)',
  );
}

/// Reads a required string at [key].
String _requireString(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  if (value is String) return value;
  _fail(type, key, 'String', value);
}

/// Reads an optional string at [key]; `null` when absent.
String? _optionalString(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  _fail(type, key, 'String', value);
}

/// Reads a required nested JSON object at [key].
Map<String, dynamic> _requireMap(
  Map<String, dynamic> json,
  String type,
  String key,
) {
  final value = json[key];
  if (value is Map) return Map<String, dynamic>.from(value);
  _fail(type, key, 'Map', value);
}

/// Reads an optional bool at [key]; `null` when absent.
bool? _optionalBool(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  _fail(type, key, 'bool', value);
}

/// Reads an optional integer at [key], accepting integral [num] wire values.
int? _optionalInt(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  if (value == null) return null;
  // Web numbers are doubles: `2.0 is int` and `double.infinity is int` hold.
  if (value is int && value.isFinite) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  _fail(type, key, 'int', value);
}
