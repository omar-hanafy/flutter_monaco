// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'json_diagnostics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JsonDiagnosticsOptions {

/// Whether to tolerate comments inside JSON.
///
/// When `true`, comments are allowed without emitting syntax errors.
/// When `false`, Monaco treats comments as syntax errors. When `null`,
/// this field is omitted and Monaco keeps its bundled default (`true`).
/// See also [comments], which controls the diagnostic severity when
/// Monaco reports comments.
 bool? get allowComments;/// Whether Monaco should fetch remote schemas on demand using `fetch`.
///
/// Requires the schema host to be allowed by the Content Security Policy.
/// The default CSP uses `connect-src 'self' blob:`, which blocks external
/// hosts. Remote schema fetches that fail are reported at the severity
/// configured by [schemaRequest].
 bool? get enableSchemaRequest;/// Whether Monaco should validate JSON content against the provided
/// [schemas].
///
/// Set to `true` to enable schema validation. When `null`, Monaco uses
/// its own default (enabled).
 bool? get validate;/// Severity for schema-fetch failures (e.g. network errors or 404s).
///
/// Only relevant when [enableSchemaRequest] is `true`. Monaco defaults
/// to [DiagnosticsSeverity.warning] when `null`.
 DiagnosticsSeverity? get schemaRequest;/// Severity for schema validation errors. Set to
/// [DiagnosticsSeverity.ignore] to suppress schema validation entirely.
///
/// Monaco defaults to [DiagnosticsSeverity.warning] when `null`.
 DiagnosticsSeverity? get schemaValidation;/// Severity for trailing commas in JSON.
///
/// Monaco defaults to [DiagnosticsSeverity.error] when `null`.
 DiagnosticsSeverity? get trailingCommas;/// Severity for comments in JSON. Takes precedence over [allowComments]:
/// setting this to [DiagnosticsSeverity.ignore] suppresses comment
/// diagnostics regardless of the [allowComments] value.
///
/// Monaco defaults to [DiagnosticsSeverity.error] when `null`.
 DiagnosticsSeverity? get comments;/// Schema definitions and their file-match associations.
///
/// Each [JsonDiagnosticsSchema] maps a JSON Schema to a set of model-URI
/// patterns. See [JsonDiagnosticsSchema.fileMatch] for matching details.
 List<JsonDiagnosticsSchema>? get schemas;
/// Create a copy of JsonDiagnosticsOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonDiagnosticsOptionsCopyWith<JsonDiagnosticsOptions> get copyWith => _$JsonDiagnosticsOptionsCopyWithImpl<JsonDiagnosticsOptions>(this as JsonDiagnosticsOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JsonDiagnosticsOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonDiagnosticsOptions&&(identical(other.allowComments, _this.allowComments) || other.allowComments == _this.allowComments)&&(identical(other.enableSchemaRequest, _this.enableSchemaRequest) || other.enableSchemaRequest == _this.enableSchemaRequest)&&(identical(other.validate, _this.validate) || other.validate == _this.validate)&&(identical(other.schemaRequest, _this.schemaRequest) || other.schemaRequest == _this.schemaRequest)&&(identical(other.schemaValidation, _this.schemaValidation) || other.schemaValidation == _this.schemaValidation)&&(identical(other.trailingCommas, _this.trailingCommas) || other.trailingCommas == _this.trailingCommas)&&(identical(other.comments, _this.comments) || other.comments == _this.comments)&&const DeepCollectionEquality().equals(other.schemas, _this.schemas));
}


@override
int get hashCode {
  final _this = this as JsonDiagnosticsOptions;
  return Object.hash(runtimeType,_this.allowComments,_this.enableSchemaRequest,_this.validate,_this.schemaRequest,_this.schemaValidation,_this.trailingCommas,_this.comments,const DeepCollectionEquality().hash(_this.schemas));
}

@override
String toString() {
  final _this = this as JsonDiagnosticsOptions;
  return 'JsonDiagnosticsOptions(allowComments: ${_this.allowComments}, enableSchemaRequest: ${_this.enableSchemaRequest}, validate: ${_this.validate}, schemaRequest: ${_this.schemaRequest}, schemaValidation: ${_this.schemaValidation}, trailingCommas: ${_this.trailingCommas}, comments: ${_this.comments}, schemas: ${_this.schemas})';
}


}

/// @nodoc
abstract mixin class $JsonDiagnosticsOptionsCopyWith<$Res>  {
  factory $JsonDiagnosticsOptionsCopyWith(JsonDiagnosticsOptions value, $Res Function(JsonDiagnosticsOptions) _then) = _$JsonDiagnosticsOptionsCopyWithImpl;
@useResult
$Res call({
 bool? allowComments, bool? enableSchemaRequest, bool? validate, DiagnosticsSeverity? schemaRequest, DiagnosticsSeverity? schemaValidation, DiagnosticsSeverity? trailingCommas, DiagnosticsSeverity? comments, List<JsonDiagnosticsSchema>? schemas
});




}
/// @nodoc
class _$JsonDiagnosticsOptionsCopyWithImpl<$Res>
    implements $JsonDiagnosticsOptionsCopyWith<$Res> {
  _$JsonDiagnosticsOptionsCopyWithImpl(this._self, this._then);

  final JsonDiagnosticsOptions _self;
  final $Res Function(JsonDiagnosticsOptions) _then;

/// Create a copy of JsonDiagnosticsOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allowComments = freezed,Object? enableSchemaRequest = freezed,Object? validate = freezed,Object? schemaRequest = freezed,Object? schemaValidation = freezed,Object? trailingCommas = freezed,Object? comments = freezed,Object? schemas = freezed,}) {
  return _then(JsonDiagnosticsOptions(
allowComments: freezed == allowComments ? _self.allowComments : allowComments // ignore: cast_nullable_to_non_nullable
as bool?,enableSchemaRequest: freezed == enableSchemaRequest ? _self.enableSchemaRequest : enableSchemaRequest // ignore: cast_nullable_to_non_nullable
as bool?,validate: freezed == validate ? _self.validate : validate // ignore: cast_nullable_to_non_nullable
as bool?,schemaRequest: freezed == schemaRequest ? _self.schemaRequest : schemaRequest // ignore: cast_nullable_to_non_nullable
as DiagnosticsSeverity?,schemaValidation: freezed == schemaValidation ? _self.schemaValidation : schemaValidation // ignore: cast_nullable_to_non_nullable
as DiagnosticsSeverity?,trailingCommas: freezed == trailingCommas ? _self.trailingCommas : trailingCommas // ignore: cast_nullable_to_non_nullable
as DiagnosticsSeverity?,comments: freezed == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as DiagnosticsSeverity?,schemas: freezed == schemas ? _self.schemas : schemas // ignore: cast_nullable_to_non_nullable
as List<JsonDiagnosticsSchema>?,
  ));
}

}


/// Adds pattern-matching-related methods to [JsonDiagnosticsOptions].
extension JsonDiagnosticsOptionsPatterns on JsonDiagnosticsOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JsonDiagnosticsOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JsonDiagnosticsOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JsonDiagnosticsOptions value)  $default,){
final _that = this;
switch (_that) {
case _JsonDiagnosticsOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JsonDiagnosticsOptions value)?  $default,){
final _that = this;
switch (_that) {
case _JsonDiagnosticsOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? allowComments,  bool? enableSchemaRequest,  bool? validate,  DiagnosticsSeverity? schemaRequest,  DiagnosticsSeverity? schemaValidation,  DiagnosticsSeverity? trailingCommas,  DiagnosticsSeverity? comments,  List<JsonDiagnosticsSchema>? schemas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JsonDiagnosticsOptions() when $default != null:
return $default(_that.allowComments,_that.enableSchemaRequest,_that.validate,_that.schemaRequest,_that.schemaValidation,_that.trailingCommas,_that.comments,_that.schemas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? allowComments,  bool? enableSchemaRequest,  bool? validate,  DiagnosticsSeverity? schemaRequest,  DiagnosticsSeverity? schemaValidation,  DiagnosticsSeverity? trailingCommas,  DiagnosticsSeverity? comments,  List<JsonDiagnosticsSchema>? schemas)  $default,) {final _that = this;
switch (_that) {
case _JsonDiagnosticsOptions():
return $default(_that.allowComments,_that.enableSchemaRequest,_that.validate,_that.schemaRequest,_that.schemaValidation,_that.trailingCommas,_that.comments,_that.schemas);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? allowComments,  bool? enableSchemaRequest,  bool? validate,  DiagnosticsSeverity? schemaRequest,  DiagnosticsSeverity? schemaValidation,  DiagnosticsSeverity? trailingCommas,  DiagnosticsSeverity? comments,  List<JsonDiagnosticsSchema>? schemas)?  $default,) {final _that = this;
switch (_that) {
case _JsonDiagnosticsOptions() when $default != null:
return $default(_that.allowComments,_that.enableSchemaRequest,_that.validate,_that.schemaRequest,_that.schemaValidation,_that.trailingCommas,_that.comments,_that.schemas);case _:
  return null;

}
}

}

/// @nodoc


class _JsonDiagnosticsOptions extends JsonDiagnosticsOptions {
  const _JsonDiagnosticsOptions({this.allowComments, this.enableSchemaRequest, this.validate, this.schemaRequest, this.schemaValidation, this.trailingCommas, this.comments,  List<JsonDiagnosticsSchema>? schemas}): _schemas = schemas,super._();
  

/// Whether to tolerate comments inside JSON.
///
/// When `true`, comments are allowed without emitting syntax errors.
/// When `false`, Monaco treats comments as syntax errors. When `null`,
/// this field is omitted and Monaco keeps its bundled default (`true`).
/// See also [comments], which controls the diagnostic severity when
/// Monaco reports comments.
@override final  bool? allowComments;
/// Whether Monaco should fetch remote schemas on demand using `fetch`.
///
/// Requires the schema host to be allowed by the Content Security Policy.
/// The default CSP uses `connect-src 'self' blob:`, which blocks external
/// hosts. Remote schema fetches that fail are reported at the severity
/// configured by [schemaRequest].
@override final  bool? enableSchemaRequest;
/// Whether Monaco should validate JSON content against the provided
/// [schemas].
///
/// Set to `true` to enable schema validation. When `null`, Monaco uses
/// its own default (enabled).
@override final  bool? validate;
/// Severity for schema-fetch failures (e.g. network errors or 404s).
///
/// Only relevant when [enableSchemaRequest] is `true`. Monaco defaults
/// to [DiagnosticsSeverity.warning] when `null`.
@override final  DiagnosticsSeverity? schemaRequest;
/// Severity for schema validation errors. Set to
/// [DiagnosticsSeverity.ignore] to suppress schema validation entirely.
///
/// Monaco defaults to [DiagnosticsSeverity.warning] when `null`.
@override final  DiagnosticsSeverity? schemaValidation;
/// Severity for trailing commas in JSON.
///
/// Monaco defaults to [DiagnosticsSeverity.error] when `null`.
@override final  DiagnosticsSeverity? trailingCommas;
/// Severity for comments in JSON. Takes precedence over [allowComments]:
/// setting this to [DiagnosticsSeverity.ignore] suppresses comment
/// diagnostics regardless of the [allowComments] value.
///
/// Monaco defaults to [DiagnosticsSeverity.error] when `null`.
@override final  DiagnosticsSeverity? comments;
/// Schema definitions and their file-match associations.
///
/// Each [JsonDiagnosticsSchema] maps a JSON Schema to a set of model-URI
/// patterns. See [JsonDiagnosticsSchema.fileMatch] for matching details.
 final  List<JsonDiagnosticsSchema>? _schemas;
/// Schema definitions and their file-match associations.
///
/// Each [JsonDiagnosticsSchema] maps a JSON Schema to a set of model-URI
/// patterns. See [JsonDiagnosticsSchema.fileMatch] for matching details.
@override List<JsonDiagnosticsSchema>? get schemas {
  final value = _schemas;
  if (value == null) return null;
  if (_schemas is EqualUnmodifiableListView) return _schemas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of JsonDiagnosticsOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JsonDiagnosticsOptionsCopyWith<_JsonDiagnosticsOptions> get copyWith => __$JsonDiagnosticsOptionsCopyWithImpl<_JsonDiagnosticsOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JsonDiagnosticsOptions&&(identical(other.allowComments, allowComments) || other.allowComments == allowComments)&&(identical(other.enableSchemaRequest, enableSchemaRequest) || other.enableSchemaRequest == enableSchemaRequest)&&(identical(other.validate, validate) || other.validate == validate)&&(identical(other.schemaRequest, schemaRequest) || other.schemaRequest == schemaRequest)&&(identical(other.schemaValidation, schemaValidation) || other.schemaValidation == schemaValidation)&&(identical(other.trailingCommas, trailingCommas) || other.trailingCommas == trailingCommas)&&(identical(other.comments, comments) || other.comments == comments)&&const DeepCollectionEquality().equals(other.schemas, _schemas));
}


@override
int get hashCode {
    return Object.hash(runtimeType,allowComments,enableSchemaRequest,validate,schemaRequest,schemaValidation,trailingCommas,comments,const DeepCollectionEquality().hash(_schemas));
}

@override
String toString() {
    return 'JsonDiagnosticsOptions(allowComments: $allowComments, enableSchemaRequest: $enableSchemaRequest, validate: $validate, schemaRequest: $schemaRequest, schemaValidation: $schemaValidation, trailingCommas: $trailingCommas, comments: $comments, schemas: $schemas)';
}


}

/// @nodoc
abstract mixin class _$JsonDiagnosticsOptionsCopyWith<$Res> implements $JsonDiagnosticsOptionsCopyWith<$Res> {
  factory _$JsonDiagnosticsOptionsCopyWith(_JsonDiagnosticsOptions value, $Res Function(_JsonDiagnosticsOptions) _then) = __$JsonDiagnosticsOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool? allowComments, bool? enableSchemaRequest, bool? validate, DiagnosticsSeverity? schemaRequest, DiagnosticsSeverity? schemaValidation, DiagnosticsSeverity? trailingCommas, DiagnosticsSeverity? comments, List<JsonDiagnosticsSchema>? schemas
});




}
/// @nodoc
class __$JsonDiagnosticsOptionsCopyWithImpl<$Res>
    implements _$JsonDiagnosticsOptionsCopyWith<$Res> {
  __$JsonDiagnosticsOptionsCopyWithImpl(this._self, this._then);

  final _JsonDiagnosticsOptions _self;
  final $Res Function(_JsonDiagnosticsOptions) _then;

/// Create a copy of JsonDiagnosticsOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allowComments = freezed,Object? enableSchemaRequest = freezed,Object? validate = freezed,Object? schemaRequest = freezed,Object? schemaValidation = freezed,Object? trailingCommas = freezed,Object? comments = freezed,Object? schemas = freezed,}) {
  return _then(_JsonDiagnosticsOptions(
allowComments: freezed == allowComments ? _self.allowComments : allowComments // ignore: cast_nullable_to_non_nullable
as bool?,enableSchemaRequest: freezed == enableSchemaRequest ? _self.enableSchemaRequest : enableSchemaRequest // ignore: cast_nullable_to_non_nullable
as bool?,validate: freezed == validate ? _self.validate : validate // ignore: cast_nullable_to_non_nullable
as bool?,schemaRequest: freezed == schemaRequest ? _self.schemaRequest : schemaRequest // ignore: cast_nullable_to_non_nullable
as DiagnosticsSeverity?,schemaValidation: freezed == schemaValidation ? _self.schemaValidation : schemaValidation // ignore: cast_nullable_to_non_nullable
as DiagnosticsSeverity?,trailingCommas: freezed == trailingCommas ? _self.trailingCommas : trailingCommas // ignore: cast_nullable_to_non_nullable
as DiagnosticsSeverity?,comments: freezed == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as DiagnosticsSeverity?,schemas: freezed == schemas ? _self._schemas : schemas // ignore: cast_nullable_to_non_nullable
as List<JsonDiagnosticsSchema>?,
  ));
}


}

/// @nodoc
mixin _$JsonDiagnosticsSchema {

/// Identifier for this schema. When [schema] is `null` and
/// [JsonDiagnosticsOptions.enableSchemaRequest] is `true`, Monaco fetches
/// the schema definition from this URI.
 Uri get uri;/// Glob patterns matched against the Monaco model URI (not file paths).
///
/// Use `['*']` to apply this schema to every JSON model. For targeted
/// matching, set a meaningful URI when calling
/// `MonacoController.openDocument` and use a pattern that matches it.
/// When `null`, the schema is registered but not automatically applied.
 List<String>? get fileMatch;/// The JSON Schema definition as a Dart map.
///
/// When provided, Monaco uses this directly instead of fetching from [uri].
/// The map should follow the JSON Schema specification (e.g. draft-07).
 Map<String, dynamic>? get schema;
/// Create a copy of JsonDiagnosticsSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonDiagnosticsSchemaCopyWith<JsonDiagnosticsSchema> get copyWith => _$JsonDiagnosticsSchemaCopyWithImpl<JsonDiagnosticsSchema>(this as JsonDiagnosticsSchema, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JsonDiagnosticsSchema;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonDiagnosticsSchema&&(identical(other.uri, _this.uri) || other.uri == _this.uri)&&const DeepCollectionEquality().equals(other.fileMatch, _this.fileMatch)&&const DeepCollectionEquality().equals(other.schema, _this.schema));
}


@override
int get hashCode {
  final _this = this as JsonDiagnosticsSchema;
  return Object.hash(runtimeType,_this.uri,const DeepCollectionEquality().hash(_this.fileMatch),const DeepCollectionEquality().hash(_this.schema));
}

@override
String toString() {
  final _this = this as JsonDiagnosticsSchema;
  return 'JsonDiagnosticsSchema(uri: ${_this.uri}, fileMatch: ${_this.fileMatch}, schema: ${_this.schema})';
}


}

/// @nodoc
abstract mixin class $JsonDiagnosticsSchemaCopyWith<$Res>  {
  factory $JsonDiagnosticsSchemaCopyWith(JsonDiagnosticsSchema value, $Res Function(JsonDiagnosticsSchema) _then) = _$JsonDiagnosticsSchemaCopyWithImpl;
@useResult
$Res call({
 Uri uri, List<String>? fileMatch, Map<String, dynamic>? schema
});




}
/// @nodoc
class _$JsonDiagnosticsSchemaCopyWithImpl<$Res>
    implements $JsonDiagnosticsSchemaCopyWith<$Res> {
  _$JsonDiagnosticsSchemaCopyWithImpl(this._self, this._then);

  final JsonDiagnosticsSchema _self;
  final $Res Function(JsonDiagnosticsSchema) _then;

/// Create a copy of JsonDiagnosticsSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uri = null,Object? fileMatch = freezed,Object? schema = freezed,}) {
  return _then(JsonDiagnosticsSchema(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as Uri,fileMatch: freezed == fileMatch ? _self.fileMatch : fileMatch // ignore: cast_nullable_to_non_nullable
as List<String>?,schema: freezed == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [JsonDiagnosticsSchema].
extension JsonDiagnosticsSchemaPatterns on JsonDiagnosticsSchema {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JsonDiagnosticsSchema value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JsonDiagnosticsSchema() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JsonDiagnosticsSchema value)  $default,){
final _that = this;
switch (_that) {
case _JsonDiagnosticsSchema():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JsonDiagnosticsSchema value)?  $default,){
final _that = this;
switch (_that) {
case _JsonDiagnosticsSchema() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uri uri,  List<String>? fileMatch,  Map<String, dynamic>? schema)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JsonDiagnosticsSchema() when $default != null:
return $default(_that.uri,_that.fileMatch,_that.schema);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uri uri,  List<String>? fileMatch,  Map<String, dynamic>? schema)  $default,) {final _that = this;
switch (_that) {
case _JsonDiagnosticsSchema():
return $default(_that.uri,_that.fileMatch,_that.schema);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uri uri,  List<String>? fileMatch,  Map<String, dynamic>? schema)?  $default,) {final _that = this;
switch (_that) {
case _JsonDiagnosticsSchema() when $default != null:
return $default(_that.uri,_that.fileMatch,_that.schema);case _:
  return null;

}
}

}

/// @nodoc


class _JsonDiagnosticsSchema extends JsonDiagnosticsSchema {
  const _JsonDiagnosticsSchema({required this.uri,  List<String>? fileMatch,  Map<String, dynamic>? schema}): _fileMatch = fileMatch,_schema = schema,super._();
  

/// Identifier for this schema. When [schema] is `null` and
/// [JsonDiagnosticsOptions.enableSchemaRequest] is `true`, Monaco fetches
/// the schema definition from this URI.
@override final  Uri uri;
/// Glob patterns matched against the Monaco model URI (not file paths).
///
/// Use `['*']` to apply this schema to every JSON model. For targeted
/// matching, set a meaningful URI when calling
/// `MonacoController.openDocument` and use a pattern that matches it.
/// When `null`, the schema is registered but not automatically applied.
 final  List<String>? _fileMatch;
/// Glob patterns matched against the Monaco model URI (not file paths).
///
/// Use `['*']` to apply this schema to every JSON model. For targeted
/// matching, set a meaningful URI when calling
/// `MonacoController.openDocument` and use a pattern that matches it.
/// When `null`, the schema is registered but not automatically applied.
@override List<String>? get fileMatch {
  final value = _fileMatch;
  if (value == null) return null;
  if (_fileMatch is EqualUnmodifiableListView) return _fileMatch;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// The JSON Schema definition as a Dart map.
///
/// When provided, Monaco uses this directly instead of fetching from [uri].
/// The map should follow the JSON Schema specification (e.g. draft-07).
 final  Map<String, dynamic>? _schema;
/// The JSON Schema definition as a Dart map.
///
/// When provided, Monaco uses this directly instead of fetching from [uri].
/// The map should follow the JSON Schema specification (e.g. draft-07).
@override Map<String, dynamic>? get schema {
  final value = _schema;
  if (value == null) return null;
  if (_schema is EqualUnmodifiableMapView) return _schema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of JsonDiagnosticsSchema
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JsonDiagnosticsSchemaCopyWith<_JsonDiagnosticsSchema> get copyWith => __$JsonDiagnosticsSchemaCopyWithImpl<_JsonDiagnosticsSchema>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JsonDiagnosticsSchema&&(identical(other.uri, uri) || other.uri == uri)&&const DeepCollectionEquality().equals(other.fileMatch, _fileMatch)&&const DeepCollectionEquality().equals(other.schema, _schema));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uri,const DeepCollectionEquality().hash(_fileMatch),const DeepCollectionEquality().hash(_schema));
}

@override
String toString() {
    return 'JsonDiagnosticsSchema(uri: $uri, fileMatch: $fileMatch, schema: $schema)';
}


}

/// @nodoc
abstract mixin class _$JsonDiagnosticsSchemaCopyWith<$Res> implements $JsonDiagnosticsSchemaCopyWith<$Res> {
  factory _$JsonDiagnosticsSchemaCopyWith(_JsonDiagnosticsSchema value, $Res Function(_JsonDiagnosticsSchema) _then) = __$JsonDiagnosticsSchemaCopyWithImpl;
@override @useResult
$Res call({
 Uri uri, List<String>? fileMatch, Map<String, dynamic>? schema
});




}
/// @nodoc
class __$JsonDiagnosticsSchemaCopyWithImpl<$Res>
    implements _$JsonDiagnosticsSchemaCopyWith<$Res> {
  __$JsonDiagnosticsSchemaCopyWithImpl(this._self, this._then);

  final _JsonDiagnosticsSchema _self;
  final $Res Function(_JsonDiagnosticsSchema) _then;

/// Create a copy of JsonDiagnosticsSchema
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? fileMatch = freezed,Object? schema = freezed,}) {
  return _then(_JsonDiagnosticsSchema(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as Uri,fileMatch: freezed == fileMatch ? _self._fileMatch : fileMatch // ignore: cast_nullable_to_non_nullable
as List<String>?,schema: freezed == schema ? _self._schema : schema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
