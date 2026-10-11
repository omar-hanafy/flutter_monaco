import 'package:flutter_monaco/src/types/geometry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'completion.freezed.dart';

/// Represents a suggestion item for code completion.
@Freezed(fromJson: false, toJson: false)
sealed class CompletionItem with _$CompletionItem {
  /// Creates a completion item.
  const factory CompletionItem({
    /// The label of this completion item.
    required String label,

    /// The text to be inserted into the document. If `null`, [label] is used.
    String? insertText,

    /// The kind of this completion item (e.g., method, function).
    CompletionItemKind? kind,

    /// A human-readable string with additional information about this item.
    String? detail,

    /// A human-readable string that represents a doc-comment.
    String? documentation,

    /// A string that should be used when comparing this item with other items.
    String? sortText,

    /// A string that should be used when filtering a set of completion items.
    String? filterText,

    /// The range of text to be replaced by this completion item.
    Range? range,

    /// Characters that trigger the commit of this completion.
    List<String>? commitCharacters,

    /// Rules that control how the [insertText] is formatted.
    Set<InsertTextRule>? insertTextRules,
  }) = _CompletionItem;

  const CompletionItem._();

  /// Creates a [CompletionItem] from a JSON map.
  ///
  /// `label` is required; every other key is optional and `null` when
  /// absent. Throws a [FormatException] if `label` is missing or any present
  /// key has the wrong type.
  factory CompletionItem.fromJson(Map<String, dynamic> json) => CompletionItem(
    label: _requireString(json, 'CompletionItem', 'label'),
    insertText: _optionalString(json, 'CompletionItem', 'insertText'),
    kind: CompletionItemKind.maybeFromJsonValue(
      _optionalString(json, 'CompletionItem', 'kind'),
    ),
    detail: _optionalString(json, 'CompletionItem', 'detail'),
    documentation: _optionalString(json, 'CompletionItem', 'documentation'),
    sortText: _optionalString(json, 'CompletionItem', 'sortText'),
    filterText: _optionalString(json, 'CompletionItem', 'filterText'),
    range: switch (_optionalMap(json, 'CompletionItem', 'range')) {
      null => null,
      final rangeJson => Range.fromJson(rangeJson),
    },
    commitCharacters: _optionalStringList(
      json,
      'CompletionItem',
      'commitCharacters',
    ),
    insertTextRules: _optionalStringList(
      json,
      'CompletionItem',
      'insertTextRules',
    )?.map(InsertTextRule.fromJsonValue).toSet(),
  );

  /// Converts the completion item to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'label': label,
    if (insertText != null) 'insertText': insertText,
    if (kind != null) 'kind': kind!.jsonValue,
    if (detail != null) 'detail': detail,
    if (documentation != null) 'documentation': documentation,
    if (sortText != null) 'sortText': sortText,
    if (filterText != null) 'filterText': filterText,
    if (range != null) 'range': range!.toJson(),
    if (commitCharacters != null) 'commitCharacters': commitCharacters,
    if (insertTextRules != null && insertTextRules!.isNotEmpty)
      'insertTextRules': insertTextRules!
          .map((rule) => rule.jsonValue)
          .toList(),
  };
}

/// A list of completion items to be returned to the editor.
@Freezed(fromJson: false, toJson: false)
sealed class CompletionList with _$CompletionList {
  /// Creates a completion list.
  const factory CompletionList({
    /// The list of completion suggestions.
    required List<CompletionItem> suggestions,

    /// If `true`, indicates that this is not the full list of suggestions.
    @Default(false) bool isIncomplete,
  }) = _CompletionList;

  const CompletionList._();

  /// Creates a [CompletionList] from a JSON map.
  ///
  /// `suggestions` is required and must be a list of maps; `isIncomplete`
  /// defaults to `false` when absent. Throws a [FormatException] if
  /// `suggestions` is missing or any present key has the wrong type.
  factory CompletionList.fromJson(Map<String, dynamic> json) => CompletionList(
    suggestions: _requireMapList(
      json,
      'CompletionList',
      'suggestions',
    ).map(CompletionItem.fromJson).toList(),
    isIncomplete:
        _optionalBool(json, 'CompletionList', 'isIncomplete') ?? false,
  );

  /// Converts the completion list to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'suggestions': suggestions.map((item) => item.toJson()).toList(),
    'isIncomplete': isIncomplete,
  };
}

/// Represents a request for completion items from the editor.
@Freezed(fromJson: false, toJson: false)
sealed class CompletionRequest with _$CompletionRequest {
  /// Creates a completion request.
  const factory CompletionRequest({
    /// The unique ID of the completion provider that was invoked.
    required String providerId,

    /// A unique ID for this specific request.
    required String requestId,

    /// The language ID of the document.
    required String language,

    /// The URI of the document.
    Uri? uri,

    /// The position in the document where the request was triggered.
    required Position position,

    /// The default range to be replaced by a completion item.
    required Range defaultRange,

    /// The text of the line where the request was triggered.
    String? lineText,

    /// The kind of trigger that initiated the completion request.
    int? triggerKind,

    /// The character that triggered the completion request.
    String? triggerCharacter,
  }) = _CompletionRequest;

  const CompletionRequest._();

  /// Creates a [CompletionRequest] from a JSON map.
  ///
  /// `providerId`, `requestId`, `language`, `position`, and `defaultRange`
  /// are required; the remaining keys are optional and `null` when absent.
  /// Throws a [FormatException] if a required key is missing or any present
  /// key has the wrong type.
  factory CompletionRequest.fromJson(Map<String, dynamic> json) =>
      CompletionRequest(
        providerId: _requireString(json, 'CompletionRequest', 'providerId'),
        requestId: _requireString(json, 'CompletionRequest', 'requestId'),
        language: _requireString(json, 'CompletionRequest', 'language'),
        uri: _optionalUri(json, 'CompletionRequest', 'uri'),
        position: Position.fromJson(
          _requireMap(json, 'CompletionRequest', 'position'),
        ),
        defaultRange: Range.fromJson(
          _requireMap(json, 'CompletionRequest', 'defaultRange'),
        ),
        lineText: _optionalString(json, 'CompletionRequest', 'lineText'),
        triggerKind: _optionalInt(json, 'CompletionRequest', 'triggerKind'),
        triggerCharacter: _optionalString(
          json,
          'CompletionRequest',
          'triggerCharacter',
        ),
      );

  /// Converts the completion request to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'requestId': requestId,
    'language': language,
    if (uri != null) 'uri': uri.toString(),
    'position': position.toJson(),
    'defaultRange': defaultRange.toJson(),
    if (lineText != null) 'lineText': lineText,
    if (triggerKind != null) 'triggerKind': triggerKind,
    if (triggerCharacter != null) 'triggerCharacter': triggerCharacter,
  };
}

/// Defines the kind of a [CompletionItem] for icon and sorting purposes.
enum CompletionItemKind {
  /// A text completion.
  text('Text'),

  /// A method completion.
  method('Method'),

  /// A function completion.
  functionType('Function'),

  /// A constructor completion.
  constructor('Constructor'),

  /// A field completion.
  field('Field'),

  /// A variable completion.
  variable('Variable'),

  /// A class completion.
  classType('Class'),

  /// An interface completion.
  interfaceType('Interface'),

  /// A module completion.
  module('Module'),

  /// A property completion.
  property('Property'),

  /// A unit completion.
  unit('Unit'),

  /// A value completion.
  value('Value'),

  /// An enum completion.
  enumType('Enum'),

  /// A keyword completion.
  keyword('Keyword'),

  /// A snippet completion.
  snippet('Snippet'),

  /// A color completion.
  color('Color'),

  /// A file completion.
  file('File'),

  /// A reference completion.
  reference('Reference'),

  /// A folder completion.
  folder('Folder'),

  /// An enum member completion.
  enumMember('EnumMember'),

  /// A constant completion.
  constant('Constant'),

  /// A struct completion.
  struct('Struct'),

  /// An event completion.
  event('Event'),

  /// An operator completion.
  operatorType('Operator'),

  /// A type parameter completion.
  typeParameter('TypeParameter');

  const CompletionItemKind(this.jsonValue);

  /// The string value used in JSON serialization.
  final String jsonValue;

  /// Creates a [CompletionItemKind] from its JSON string value.
  static CompletionItemKind fromJsonValue(String value) {
    return maybeFromJsonValue(value) ?? CompletionItemKind.text;
  }

  /// Tries to create a [CompletionItemKind] from its JSON string value.
  ///
  /// Returns `null` if the value is not recognized.
  static CompletionItemKind? maybeFromJsonValue(String? value) {
    if (value == null) return null;
    for (final kind in CompletionItemKind.values) {
      if (kind.jsonValue == value) return kind;
    }
    return null;
  }
}

/// Defines rules for how the `insertText` of a [CompletionItem] is handled.
enum InsertTextRule {
  /// The editor should keep the whitespace of the replaced range.
  keepWhitespace('KeepWhitespace'),

  /// The `insertText` is a snippet and should be parsed accordingly.
  insertAsSnippet('InsertAsSnippet');

  const InsertTextRule(this.jsonValue);

  /// The string value used in JSON serialization.
  final String jsonValue;

  /// Creates an [InsertTextRule] from its JSON string value.
  static InsertTextRule fromJsonValue(String value) {
    return InsertTextRule.values.firstWhere(
      (rule) => rule.jsonValue == value,
      orElse: () => InsertTextRule.insertAsSnippet,
    );
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

/// Reads a required list of JSON objects at [key].
List<Map<String, dynamic>> _requireMapList(
  Map<String, dynamic> json,
  String type,
  String key,
) {
  final value = json[key];
  if (value is List && value.every((element) => element is Map)) {
    return [
      for (final element in value) Map<String, dynamic>.from(element as Map),
    ];
  }
  _fail(type, key, 'List<Map>', value);
}

/// Reads an optional string at [key]; `null` when absent.
String? _optionalString(Map<String, dynamic> json, String type, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  _fail(type, key, 'String', value);
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

/// Reads an optional URI string at [key]; `null` when absent.
Uri? _optionalUri(Map<String, dynamic> json, String type, String key) {
  final raw = _optionalString(json, type, key);
  if (raw == null) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null) _fail(type, key, 'URI string', raw);
  return uri;
}
