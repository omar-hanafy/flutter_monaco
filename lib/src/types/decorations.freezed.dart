// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'decorations.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DecorationOptions {

/// The range to which the decoration should be applied.
 Range get range;/// A map of Monaco-specific decoration options.
 Map<String, dynamic> get options;
/// Create a copy of DecorationOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecorationOptionsCopyWith<DecorationOptions> get copyWith => _$DecorationOptionsCopyWithImpl<DecorationOptions>(this as DecorationOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DecorationOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DecorationOptions&&(identical(other.range, _this.range) || other.range == _this.range)&&const DeepCollectionEquality().equals(other.options, _this.options));
}


@override
int get hashCode {
  final _this = this as DecorationOptions;
  return Object.hash(runtimeType,_this.range,const DeepCollectionEquality().hash(_this.options));
}

@override
String toString() {
  final _this = this as DecorationOptions;
  return 'DecorationOptions(range: ${_this.range}, options: ${_this.options})';
}


}

/// @nodoc
abstract mixin class $DecorationOptionsCopyWith<$Res>  {
  factory $DecorationOptionsCopyWith(DecorationOptions value, $Res Function(DecorationOptions) _then) = _$DecorationOptionsCopyWithImpl;
@useResult
$Res call({
 Range range, Map<String, dynamic> options
});


$RangeCopyWith<$Res> get range;

}
/// @nodoc
class _$DecorationOptionsCopyWithImpl<$Res>
    implements $DecorationOptionsCopyWith<$Res> {
  _$DecorationOptionsCopyWithImpl(this._self, this._then);

  final DecorationOptions _self;
  final $Res Function(DecorationOptions) _then;

/// Create a copy of DecorationOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? options = null,}) {
  return _then(DecorationOptions(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of DecorationOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get range {
  
  return $RangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [DecorationOptions].
extension DecorationOptionsPatterns on DecorationOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DecorationOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DecorationOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DecorationOptions value)  $default,){
final _that = this;
switch (_that) {
case _DecorationOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DecorationOptions value)?  $default,){
final _that = this;
switch (_that) {
case _DecorationOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Range range,  Map<String, dynamic> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DecorationOptions() when $default != null:
return $default(_that.range,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Range range,  Map<String, dynamic> options)  $default,) {final _that = this;
switch (_that) {
case _DecorationOptions():
return $default(_that.range,_that.options);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Range range,  Map<String, dynamic> options)?  $default,) {final _that = this;
switch (_that) {
case _DecorationOptions() when $default != null:
return $default(_that.range,_that.options);case _:
  return null;

}
}

}

/// @nodoc


class _DecorationOptions extends DecorationOptions {
  const _DecorationOptions({required this.range,  Map<String, dynamic> options = const {}}): _options = options,super._();
  

/// The range to which the decoration should be applied.
@override final  Range range;
/// A map of Monaco-specific decoration options.
 final  Map<String, dynamic> _options;
/// A map of Monaco-specific decoration options.
@override@JsonKey() Map<String, dynamic> get options {
  if (_options is EqualUnmodifiableMapView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_options);
}


/// Create a copy of DecorationOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DecorationOptionsCopyWith<_DecorationOptions> get copyWith => __$DecorationOptionsCopyWithImpl<_DecorationOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DecorationOptions&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other.options, _options));
}


@override
int get hashCode {
    return Object.hash(runtimeType,range,const DeepCollectionEquality().hash(_options));
}

@override
String toString() {
    return 'DecorationOptions(range: $range, options: $options)';
}


}

/// @nodoc
abstract mixin class _$DecorationOptionsCopyWith<$Res> implements $DecorationOptionsCopyWith<$Res> {
  factory _$DecorationOptionsCopyWith(_DecorationOptions value, $Res Function(_DecorationOptions) _then) = __$DecorationOptionsCopyWithImpl;
@override @useResult
$Res call({
 Range range, Map<String, dynamic> options
});


@override $RangeCopyWith<$Res> get range;

}
/// @nodoc
class __$DecorationOptionsCopyWithImpl<$Res>
    implements _$DecorationOptionsCopyWith<$Res> {
  __$DecorationOptionsCopyWithImpl(this._self, this._then);

  final _DecorationOptions _self;
  final $Res Function(_DecorationOptions) _then;

/// Create a copy of DecorationOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? options = null,}) {
  return _then(_DecorationOptions(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of DecorationOptions
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
