import 'package:flutter_monaco/src/types/geometry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'markers.freezed.dart';

/// Defines the severity levels for markers (diagnostics) in the editor.
enum MarkerSeverity {
  /// A hint, typically rendered with a subtle indicator.
  hint(1),

  /// An informational message.
  info(2),

  /// A warning, typically rendered with a yellow underline.
  warning(4),

  /// An error, typically rendered with a red underline.
  error(8);

  const MarkerSeverity(this.value);

  /// The integer value used by the Monaco Editor.
  final int value;

  /// Creates a [MarkerSeverity] from its integer [value].
  static MarkerSeverity fromValue(int value) {
    return MarkerSeverity.values.firstWhere(
      (s) => s.value == value,
      orElse: () => MarkerSeverity.info,
    );
  }
}

/// Represents a marker, such as a warning or error, displayed in the editor.
@freezed
sealed class MarkerData with _$MarkerData {
  /// Creates a marker with the specified properties.
  const factory MarkerData({
    /// The range in the document where the marker should be displayed.
    required Range range,

    /// The message to display when hovering over the marker.
    required String message,

    /// The severity level of the marker.
    @Default(MarkerSeverity.info) MarkerSeverity severity,

    /// An optional error code.
    String? code,

    /// The source of the marker (e.g., 'linter').
    String? source,

    /// Optional tags, such as `unnecessary` or `deprecated`.
    List<String>? tags,

    /// Optional related information, providing links to other locations.
    List<RelatedInformation>? relatedInformation,
  }) = _MarkerData;

  /// A convenience factory for creating an error marker.
  factory MarkerData.error({
    required Range range,
    required String message,
    String? code,
    String? source,
  }) {
    return MarkerData(
      range: range,
      message: message,
      severity: MarkerSeverity.error,
      code: code,
      source: source,
    );
  }

  /// A convenience factory for creating a warning marker.
  factory MarkerData.warning({
    required Range range,
    required String message,
    String? code,
    String? source,
  }) {
    return MarkerData(
      range: range,
      message: message,
      severity: MarkerSeverity.warning,
      code: code,
      source: source,
    );
  }

  const MarkerData._();

  /// Creates a [MarkerData] object from a JSON map.
  ///
  /// The range keys (`startLineNumber`, `startColumn`, `endLineNumber`,
  /// `endColumn`) are read from the top-level map, matching the flattened
  /// shape produced by [toJson]. `message` is required; `severity` defaults
  /// to [MarkerSeverity.info] when absent. Throws a [FormatException] if a
  /// required key is missing or any present key has the wrong type.
  factory MarkerData.fromJson(Map<String, dynamic> json) {
    final severity = _optionalInt(json, 'MarkerData', 'severity');
    return MarkerData(
      range: Range.fromJson(json),
      message: _requireString(json, 'MarkerData', 'message'),
      severity: severity == null
          ? MarkerSeverity.info
          : MarkerSeverity.fromValue(severity),
      code: _optionalString(json, 'MarkerData', 'code'),
      source: _optionalString(json, 'MarkerData', 'source'),
      tags: _optionalStringList(json, 'MarkerData', 'tags'),
      relatedInformation: _optionalMapList(
        json,
        'MarkerData',
        'relatedInformation',
      )?.map(RelatedInformation.fromJson).toList(),
    );
  }

  /// Converts the marker data to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      ...range.toJson(),
      'message': message,
      'severity': severity.value,
    };

    if (code != null) json['code'] = code;
    if (source != null) json['source'] = source;
    if (tags != null && tags!.isNotEmpty) json['tags'] = tags;
    if (relatedInformation != null && relatedInformation!.isNotEmpty) {
      json['relatedInformation'] = relatedInformation!
          .map((info) => info.toJson())
          .toList();
    }

    return json;
  }
}

/// Represents related information for a [MarkerData], allowing navigation to
/// other parts of the code.
@freezed
sealed class RelatedInformation with _$RelatedInformation {
  /// Creates a related information object.
  const factory RelatedInformation({
    /// The URI of the resource to link to.
    required Uri resource,

    /// The range within the resource to highlight.
    required Range range,

    /// The message to display for this piece of information.
    required String message,
  }) = _RelatedInformation;

  const RelatedInformation._();

  /// Creates a [RelatedInformation] object from a JSON map.
  ///
  /// `resource` and `message` are required; the range keys are read from the
  /// top-level map, matching the flattened shape produced by [toJson].
  /// Throws a [FormatException] if a required key is missing or invalid.
  factory RelatedInformation.fromJson(Map<String, dynamic> json) {
    return RelatedInformation(
      resource: _requireUri(json, 'RelatedInformation', 'resource'),
      range: Range.fromJson(json),
      message: _requireString(json, 'RelatedInformation', 'message'),
    );
  }

  /// Converts the related information to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'resource': resource.toString(),
    ...range.toJson(),
    'message': message,
  };
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

/// Reads a required URI string at [key].
Uri _requireUri(Map<String, dynamic> json, String type, String key) {
  final raw = _requireString(json, type, key);
  final uri = Uri.tryParse(raw);
  if (uri == null) _fail(type, key, 'URI string', raw);
  return uri;
}

/// Reads an optional string at [key]; `null` when absent.
String? _optionalString(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  _fail(type, key, 'String', value);
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

/// Reads an optional list of strings at [key]; `null` when absent.
List<String>? _optionalStringList(
  Map<String, dynamic> json,
  String type,
  String key,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is List && value.every((element) => element is String)) {
    return List<String>.from(value);
  }
  _fail(type, key, 'List<String>', value);
}

/// Reads an optional list of JSON objects at [key]; `null` when absent.
List<Map<String, dynamic>>? _optionalMapList(
  Map<String, dynamic> json,
  String type,
  String key,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is List && value.every((element) => element is Map)) {
    return [
      for (final element in value) Map<String, dynamic>.from(element as Map),
    ];
  }
  _fail(type, key, 'List<Map>', value);
}
