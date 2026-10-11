/// @docImport 'package:flutter_monaco/src/editor/controller.dart';
library;

import 'package:flutter_monaco/src/options/option_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'json_diagnostics.freezed.dart';

/// Configures Monaco's JSON language diagnostics and schema validation.
///
/// Pass an instance to [MonacoController.setJsonDiagnostics] to enable
/// inline errors and warnings for JSON content. All fields are optional;
/// `null` fields are omitted from the payload so Monaco keeps its own
/// defaults for those settings.
///
/// ### Usage
/// ```dart
/// controller.setJsonDiagnostics(JsonDiagnosticsOptions(
///   validate: true,
///   allowComments: true,
///   trailingCommas: DiagnosticsSeverity.warning,
///   schemas: [JsonDiagnosticsSchema(...)],
/// ));
/// ```
@freezed
sealed class JsonDiagnosticsOptions with _$JsonDiagnosticsOptions {
  const factory JsonDiagnosticsOptions({
    /// Whether to tolerate comments inside JSON.
    ///
    /// When `true`, comments are allowed without emitting syntax errors.
    /// When `false`, Monaco treats comments as syntax errors. When `null`,
    /// this field is omitted and Monaco keeps its bundled default (`true`).
    /// See also [comments], which controls the diagnostic severity when
    /// Monaco reports comments.
    bool? allowComments,

    /// Whether Monaco should fetch remote schemas on demand using `fetch`.
    ///
    /// Requires the schema host to be allowed by the Content Security Policy.
    /// The default CSP uses `connect-src 'self' blob:`, which blocks external
    /// hosts. Remote schema fetches that fail are reported at the severity
    /// configured by [schemaRequest].
    bool? enableSchemaRequest,

    /// Whether Monaco should validate JSON content against the provided
    /// [schemas].
    ///
    /// Set to `true` to enable schema validation. When `null`, Monaco uses
    /// its own default (enabled).
    bool? validate,

    /// Severity for schema-fetch failures (e.g. network errors or 404s).
    ///
    /// Only relevant when [enableSchemaRequest] is `true`. Monaco defaults
    /// to [DiagnosticsSeverity.warning] when `null`.
    DiagnosticsSeverity? schemaRequest,

    /// Severity for schema validation errors. Set to
    /// [DiagnosticsSeverity.ignore] to suppress schema validation entirely.
    ///
    /// Monaco defaults to [DiagnosticsSeverity.warning] when `null`.
    DiagnosticsSeverity? schemaValidation,

    /// Severity for trailing commas in JSON.
    ///
    /// Monaco defaults to [DiagnosticsSeverity.error] when `null`.
    DiagnosticsSeverity? trailingCommas,

    /// Severity for comments in JSON. Takes precedence over [allowComments]:
    /// setting this to [DiagnosticsSeverity.ignore] suppresses comment
    /// diagnostics regardless of the [allowComments] value.
    ///
    /// Monaco defaults to [DiagnosticsSeverity.error] when `null`.
    DiagnosticsSeverity? comments,

    /// Schema definitions and their file-match associations.
    ///
    /// Each [JsonDiagnosticsSchema] maps a JSON Schema to a set of model-URI
    /// patterns. See [JsonDiagnosticsSchema.fileMatch] for matching details.
    List<JsonDiagnosticsSchema>? schemas,
  }) = _JsonDiagnosticsOptions;

  const JsonDiagnosticsOptions._();

  /// Deserializes [JsonDiagnosticsOptions] from a JSON map.
  ///
  /// Severity strings are resolved via [DiagnosticsSeverity.fromId], which
  /// falls back to [DiagnosticsSeverity.warning] for unrecognized values.
  /// Missing keys produce `null` fields; any present key with the wrong
  /// type throws a [FormatException].
  factory JsonDiagnosticsOptions.fromJson(Map<String, dynamic> json) {
    return JsonDiagnosticsOptions(
      allowComments: _optionalBool(
        json,
        'JsonDiagnosticsOptions',
        'allowComments',
      ),
      validate: _optionalBool(json, 'JsonDiagnosticsOptions', 'validate'),
      enableSchemaRequest: _optionalBool(
        json,
        'JsonDiagnosticsOptions',
        'enableSchemaRequest',
      ),
      schemaRequest: _optionalSeverity(
        json,
        'JsonDiagnosticsOptions',
        'schemaRequest',
      ),
      comments: _optionalSeverity(json, 'JsonDiagnosticsOptions', 'comments'),
      schemaValidation: _optionalSeverity(
        json,
        'JsonDiagnosticsOptions',
        'schemaValidation',
      ),
      trailingCommas: _optionalSeverity(
        json,
        'JsonDiagnosticsOptions',
        'trailingCommas',
      ),
      schemas: _optionalMapList(
        json,
        'JsonDiagnosticsOptions',
        'schemas',
      )?.map(JsonDiagnosticsSchema.fromJson).toList(),
    );
  }

  /// Serializes to a JSON map suitable for the Monaco JS bridge.
  ///
  /// `null` fields are omitted so Monaco keeps its own defaults for those
  /// settings. Severity values are serialized as their string [DiagnosticsSeverity.id].
  Map<String, dynamic> toJson() => {
    if (validate != null) 'validate': validate,
    if (allowComments != null) 'allowComments': allowComments,
    if (enableSchemaRequest != null) 'enableSchemaRequest': enableSchemaRequest,
    if (schemas != null && schemas!.isNotEmpty)
      'schemas': schemas!.map((schema) => schema.toJson()).toList(),
    if (schemaRequest != null) 'schemaRequest': schemaRequest!.id,
    if (schemaValidation != null) 'schemaValidation': schemaValidation!.id,
    if (comments != null) 'comments': comments!.id,
    if (trailingCommas != null) 'trailingCommas': trailingCommas!.id,
  };
}

/// Associates a JSON Schema with a set of Monaco model-URI patterns.
///
/// Used inside [JsonDiagnosticsOptions.schemas] to tell Monaco which schema
/// applies to which JSON models. You can either inline the schema via
/// [schema] or point to a remote schema via [uri] when
/// [JsonDiagnosticsOptions.enableSchemaRequest] is `true`.
@freezed
sealed class JsonDiagnosticsSchema with _$JsonDiagnosticsSchema {
  const factory JsonDiagnosticsSchema({
    /// Identifier for this schema. When [schema] is `null` and
    /// [JsonDiagnosticsOptions.enableSchemaRequest] is `true`, Monaco fetches
    /// the schema definition from this URI.
    required Uri uri,

    /// Glob patterns matched against the Monaco model URI (not file paths).
    ///
    /// Use `['*']` to apply this schema to every JSON model. For targeted
    /// matching, set a meaningful URI when calling
    /// `MonacoController.openDocument` and use a pattern that matches it.
    /// When `null`, the schema is registered but not automatically applied.
    List<String>? fileMatch,

    /// The JSON Schema definition as a Dart map.
    ///
    /// When provided, Monaco uses this directly instead of fetching from [uri].
    /// The map should follow the JSON Schema specification (e.g. draft-07).
    Map<String, dynamic>? schema,
  }) = _JsonDiagnosticsSchema;

  const JsonDiagnosticsSchema._();

  /// Deserializes a [JsonDiagnosticsSchema] from a JSON map.
  ///
  /// Requires the exact `'uri'` key. Throws a [FormatException] if `'uri'`
  /// is missing or invalid, or if any present optional key has the wrong
  /// type.
  factory JsonDiagnosticsSchema.fromJson(Map<String, dynamic> json) {
    return JsonDiagnosticsSchema(
      uri: _requireUri(json, 'JsonDiagnosticsSchema', 'uri'),
      fileMatch: _optionalStringList(
        json,
        'JsonDiagnosticsSchema',
        'fileMatch',
      ),
      schema: _optionalMap(json, 'JsonDiagnosticsSchema', 'schema'),
    );
  }

  /// Serializes to a JSON map. `null` optional fields are omitted.
  Map<String, dynamic> toJson() => {
    'uri': uri.toString(),
    if (fileMatch != null) 'fileMatch': fileMatch,
    if (schema != null) 'schema': schema,
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

/// Reads an optional bool at [key]; `null` when absent.
bool? _optionalBool(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  _fail(type, key, 'bool', value);
}

/// Reads an optional string at [key]; `null` when absent.
String? _optionalString(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  _fail(type, key, 'String', value);
}

/// Reads an optional severity string at [key] and resolves it via
/// [DiagnosticsSeverity.fromId]; `null` when absent.
DiagnosticsSeverity? _optionalSeverity(
  Map<String, dynamic> json,
  String type,
  String key,
) {
  final raw = _optionalString(json, type, key);
  if (raw == null) return null;
  return DiagnosticsSeverity.fromId(raw);
}

/// Reads an optional nested JSON object at [key]; `null` when absent.
Map<String, dynamic>? _optionalMap(
  Map<String, dynamic> json,
  String type,
  String key,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is Map) return Map<String, dynamic>.from(value);
  _fail(type, key, 'Map', value);
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
