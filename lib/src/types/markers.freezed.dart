// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'markers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MarkerData {

/// The range in the document where the marker should be displayed.
 Range get range;/// The message to display when hovering over the marker.
 String get message;/// The severity level of the marker.
 MarkerSeverity get severity;/// An optional error code.
 String? get code;/// The source of the marker (e.g., 'linter').
 String? get source;/// Optional tags, such as `unnecessary` or `deprecated`.
 List<String>? get tags;/// Optional related information, providing links to other locations.
 List<RelatedInformation>? get relatedInformation;
/// Create a copy of MarkerData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkerDataCopyWith<MarkerData> get copyWith => _$MarkerDataCopyWithImpl<MarkerData>(this as MarkerData, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MarkerData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkerData&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.source, _this.source) || other.source == _this.source)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&const DeepCollectionEquality().equals(other.relatedInformation, _this.relatedInformation));
}


@override
int get hashCode {
  final _this = this as MarkerData;
  return Object.hash(runtimeType,_this.range,_this.message,_this.severity,_this.code,_this.source,const DeepCollectionEquality().hash(_this.tags),const DeepCollectionEquality().hash(_this.relatedInformation));
}

@override
String toString() {
  final _this = this as MarkerData;
  return 'MarkerData(range: ${_this.range}, message: ${_this.message}, severity: ${_this.severity}, code: ${_this.code}, source: ${_this.source}, tags: ${_this.tags}, relatedInformation: ${_this.relatedInformation})';
}


}

/// @nodoc
abstract mixin class $MarkerDataCopyWith<$Res>  {
  factory $MarkerDataCopyWith(MarkerData value, $Res Function(MarkerData) _then) = _$MarkerDataCopyWithImpl;
@useResult
$Res call({
 Range range, String message, MarkerSeverity severity, String? code, String? source, List<String>? tags, List<RelatedInformation>? relatedInformation
});


$RangeCopyWith<$Res> get range;

}
/// @nodoc
class _$MarkerDataCopyWithImpl<$Res>
    implements $MarkerDataCopyWith<$Res> {
  _$MarkerDataCopyWithImpl(this._self, this._then);

  final MarkerData _self;
  final $Res Function(MarkerData) _then;

/// Create a copy of MarkerData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? message = null,Object? severity = null,Object? code = freezed,Object? source = freezed,Object? tags = freezed,Object? relatedInformation = freezed,}) {
  return _then(MarkerData(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as MarkerSeverity,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,relatedInformation: freezed == relatedInformation ? _self.relatedInformation : relatedInformation // ignore: cast_nullable_to_non_nullable
as List<RelatedInformation>?,
  ));
}
/// Create a copy of MarkerData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get range {
  
  return $RangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [MarkerData].
extension MarkerDataPatterns on MarkerData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarkerData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarkerData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarkerData value)  $default,){
final _that = this;
switch (_that) {
case _MarkerData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarkerData value)?  $default,){
final _that = this;
switch (_that) {
case _MarkerData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Range range,  String message,  MarkerSeverity severity,  String? code,  String? source,  List<String>? tags,  List<RelatedInformation>? relatedInformation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarkerData() when $default != null:
return $default(_that.range,_that.message,_that.severity,_that.code,_that.source,_that.tags,_that.relatedInformation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Range range,  String message,  MarkerSeverity severity,  String? code,  String? source,  List<String>? tags,  List<RelatedInformation>? relatedInformation)  $default,) {final _that = this;
switch (_that) {
case _MarkerData():
return $default(_that.range,_that.message,_that.severity,_that.code,_that.source,_that.tags,_that.relatedInformation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Range range,  String message,  MarkerSeverity severity,  String? code,  String? source,  List<String>? tags,  List<RelatedInformation>? relatedInformation)?  $default,) {final _that = this;
switch (_that) {
case _MarkerData() when $default != null:
return $default(_that.range,_that.message,_that.severity,_that.code,_that.source,_that.tags,_that.relatedInformation);case _:
  return null;

}
}

}

/// @nodoc


class _MarkerData extends MarkerData {
  const _MarkerData({required this.range, required this.message, this.severity = MarkerSeverity.info, this.code, this.source,  List<String>? tags,  List<RelatedInformation>? relatedInformation}): _tags = tags,_relatedInformation = relatedInformation,super._();
  

/// The range in the document where the marker should be displayed.
@override final  Range range;
/// The message to display when hovering over the marker.
@override final  String message;
/// The severity level of the marker.
@override@JsonKey() final  MarkerSeverity severity;
/// An optional error code.
@override final  String? code;
/// The source of the marker (e.g., 'linter').
@override final  String? source;
/// Optional tags, such as `unnecessary` or `deprecated`.
 final  List<String>? _tags;
/// Optional tags, such as `unnecessary` or `deprecated`.
@override List<String>? get tags {
  final value = _tags;
  if (value == null) return null;
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Optional related information, providing links to other locations.
 final  List<RelatedInformation>? _relatedInformation;
/// Optional related information, providing links to other locations.
@override List<RelatedInformation>? get relatedInformation {
  final value = _relatedInformation;
  if (value == null) return null;
  if (_relatedInformation is EqualUnmodifiableListView) return _relatedInformation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of MarkerData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarkerDataCopyWith<_MarkerData> get copyWith => __$MarkerDataCopyWithImpl<_MarkerData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarkerData&&(identical(other.range, range) || other.range == range)&&(identical(other.message, message) || other.message == message)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.code, code) || other.code == code)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.tags, _tags)&&const DeepCollectionEquality().equals(other.relatedInformation, _relatedInformation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,range,message,severity,code,source,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_relatedInformation));
}

@override
String toString() {
    return 'MarkerData(range: $range, message: $message, severity: $severity, code: $code, source: $source, tags: $tags, relatedInformation: $relatedInformation)';
}


}

/// @nodoc
abstract mixin class _$MarkerDataCopyWith<$Res> implements $MarkerDataCopyWith<$Res> {
  factory _$MarkerDataCopyWith(_MarkerData value, $Res Function(_MarkerData) _then) = __$MarkerDataCopyWithImpl;
@override @useResult
$Res call({
 Range range, String message, MarkerSeverity severity, String? code, String? source, List<String>? tags, List<RelatedInformation>? relatedInformation
});


@override $RangeCopyWith<$Res> get range;

}
/// @nodoc
class __$MarkerDataCopyWithImpl<$Res>
    implements _$MarkerDataCopyWith<$Res> {
  __$MarkerDataCopyWithImpl(this._self, this._then);

  final _MarkerData _self;
  final $Res Function(_MarkerData) _then;

/// Create a copy of MarkerData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? message = null,Object? severity = null,Object? code = freezed,Object? source = freezed,Object? tags = freezed,Object? relatedInformation = freezed,}) {
  return _then(_MarkerData(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as MarkerSeverity,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,relatedInformation: freezed == relatedInformation ? _self._relatedInformation : relatedInformation // ignore: cast_nullable_to_non_nullable
as List<RelatedInformation>?,
  ));
}

/// Create a copy of MarkerData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get range {
  
  return $RangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

/// @nodoc
mixin _$RelatedInformation {

/// The URI of the resource to link to.
 Uri get resource;/// The range within the resource to highlight.
 Range get range;/// The message to display for this piece of information.
 String get message;
/// Create a copy of RelatedInformation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelatedInformationCopyWith<RelatedInformation> get copyWith => _$RelatedInformationCopyWithImpl<RelatedInformation>(this as RelatedInformation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RelatedInformation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelatedInformation&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.message, _this.message) || other.message == _this.message));
}


@override
int get hashCode {
  final _this = this as RelatedInformation;
  return Object.hash(runtimeType,_this.resource,_this.range,_this.message);
}

@override
String toString() {
  final _this = this as RelatedInformation;
  return 'RelatedInformation(resource: ${_this.resource}, range: ${_this.range}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $RelatedInformationCopyWith<$Res>  {
  factory $RelatedInformationCopyWith(RelatedInformation value, $Res Function(RelatedInformation) _then) = _$RelatedInformationCopyWithImpl;
@useResult
$Res call({
 Uri resource, Range range, String message
});


$RangeCopyWith<$Res> get range;

}
/// @nodoc
class _$RelatedInformationCopyWithImpl<$Res>
    implements $RelatedInformationCopyWith<$Res> {
  _$RelatedInformationCopyWithImpl(this._self, this._then);

  final RelatedInformation _self;
  final $Res Function(RelatedInformation) _then;

/// Create a copy of RelatedInformation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? range = null,Object? message = null,}) {
  return _then(RelatedInformation(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as Uri,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of RelatedInformation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get range {
  
  return $RangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [RelatedInformation].
extension RelatedInformationPatterns on RelatedInformation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelatedInformation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelatedInformation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelatedInformation value)  $default,){
final _that = this;
switch (_that) {
case _RelatedInformation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelatedInformation value)?  $default,){
final _that = this;
switch (_that) {
case _RelatedInformation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uri resource,  Range range,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelatedInformation() when $default != null:
return $default(_that.resource,_that.range,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uri resource,  Range range,  String message)  $default,) {final _that = this;
switch (_that) {
case _RelatedInformation():
return $default(_that.resource,_that.range,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uri resource,  Range range,  String message)?  $default,) {final _that = this;
switch (_that) {
case _RelatedInformation() when $default != null:
return $default(_that.resource,_that.range,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _RelatedInformation extends RelatedInformation {
  const _RelatedInformation({required this.resource, required this.range, required this.message}): super._();
  

/// The URI of the resource to link to.
@override final  Uri resource;
/// The range within the resource to highlight.
@override final  Range range;
/// The message to display for this piece of information.
@override final  String message;

/// Create a copy of RelatedInformation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelatedInformationCopyWith<_RelatedInformation> get copyWith => __$RelatedInformationCopyWithImpl<_RelatedInformation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelatedInformation&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.range, range) || other.range == range)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,range,message);
}

@override
String toString() {
    return 'RelatedInformation(resource: $resource, range: $range, message: $message)';
}


}

/// @nodoc
abstract mixin class _$RelatedInformationCopyWith<$Res> implements $RelatedInformationCopyWith<$Res> {
  factory _$RelatedInformationCopyWith(_RelatedInformation value, $Res Function(_RelatedInformation) _then) = __$RelatedInformationCopyWithImpl;
@override @useResult
$Res call({
 Uri resource, Range range, String message
});


@override $RangeCopyWith<$Res> get range;

}
/// @nodoc
class __$RelatedInformationCopyWithImpl<$Res>
    implements _$RelatedInformationCopyWith<$Res> {
  __$RelatedInformationCopyWithImpl(this._self, this._then);

  final _RelatedInformation _self;
  final $Res Function(_RelatedInformation) _then;

/// Create a copy of RelatedInformation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? range = null,Object? message = null,}) {
  return _then(_RelatedInformation(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as Uri,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of RelatedInformation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get range {
  
  return $RangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

// dart format on
