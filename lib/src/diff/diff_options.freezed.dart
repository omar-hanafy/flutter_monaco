// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diff_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MonacoDiffOptions {

/// `true` renders original and modified side by side; `false` renders
/// an inline (unified) diff.
 bool? get renderSideBySide;/// Whether the modified editor is read-only.
 bool? get readOnly;/// Whether the original (left) editor accepts edits.
 bool? get originalEditable;/// Whether leading/trailing whitespace differences are ignored.
 bool? get ignoreTrimWhitespace;/// Whether the revert arrows are shown in the glyph margin.
 bool? get renderMarginRevertIcon;/// Raw Monaco diff options merged last (they win over typed fields).
 Map<String, Object?>? get extra;
/// Create a copy of MonacoDiffOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoDiffOptionsCopyWith<MonacoDiffOptions> get copyWith => _$MonacoDiffOptionsCopyWithImpl<MonacoDiffOptions>(this as MonacoDiffOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoDiffOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoDiffOptions&&(identical(other.renderSideBySide, _this.renderSideBySide) || other.renderSideBySide == _this.renderSideBySide)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly)&&(identical(other.originalEditable, _this.originalEditable) || other.originalEditable == _this.originalEditable)&&(identical(other.ignoreTrimWhitespace, _this.ignoreTrimWhitespace) || other.ignoreTrimWhitespace == _this.ignoreTrimWhitespace)&&(identical(other.renderMarginRevertIcon, _this.renderMarginRevertIcon) || other.renderMarginRevertIcon == _this.renderMarginRevertIcon)&&const DeepCollectionEquality().equals(other.extra, _this.extra));
}


@override
int get hashCode {
  final _this = this as MonacoDiffOptions;
  return Object.hash(runtimeType,_this.renderSideBySide,_this.readOnly,_this.originalEditable,_this.ignoreTrimWhitespace,_this.renderMarginRevertIcon,const DeepCollectionEquality().hash(_this.extra));
}

@override
String toString() {
  final _this = this as MonacoDiffOptions;
  return 'MonacoDiffOptions(renderSideBySide: ${_this.renderSideBySide}, readOnly: ${_this.readOnly}, originalEditable: ${_this.originalEditable}, ignoreTrimWhitespace: ${_this.ignoreTrimWhitespace}, renderMarginRevertIcon: ${_this.renderMarginRevertIcon}, extra: ${_this.extra})';
}


}

/// @nodoc
abstract mixin class $MonacoDiffOptionsCopyWith<$Res>  {
  factory $MonacoDiffOptionsCopyWith(MonacoDiffOptions value, $Res Function(MonacoDiffOptions) _then) = _$MonacoDiffOptionsCopyWithImpl;
@useResult
$Res call({
 bool? renderSideBySide, bool? readOnly, bool? originalEditable, bool? ignoreTrimWhitespace, bool? renderMarginRevertIcon, Map<String, Object?>? extra
});




}
/// @nodoc
class _$MonacoDiffOptionsCopyWithImpl<$Res>
    implements $MonacoDiffOptionsCopyWith<$Res> {
  _$MonacoDiffOptionsCopyWithImpl(this._self, this._then);

  final MonacoDiffOptions _self;
  final $Res Function(MonacoDiffOptions) _then;

/// Create a copy of MonacoDiffOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? renderSideBySide = freezed,Object? readOnly = freezed,Object? originalEditable = freezed,Object? ignoreTrimWhitespace = freezed,Object? renderMarginRevertIcon = freezed,Object? extra = freezed,}) {
  return _then(MonacoDiffOptions(
renderSideBySide: freezed == renderSideBySide ? _self.renderSideBySide : renderSideBySide // ignore: cast_nullable_to_non_nullable
as bool?,readOnly: freezed == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool?,originalEditable: freezed == originalEditable ? _self.originalEditable : originalEditable // ignore: cast_nullable_to_non_nullable
as bool?,ignoreTrimWhitespace: freezed == ignoreTrimWhitespace ? _self.ignoreTrimWhitespace : ignoreTrimWhitespace // ignore: cast_nullable_to_non_nullable
as bool?,renderMarginRevertIcon: freezed == renderMarginRevertIcon ? _self.renderMarginRevertIcon : renderMarginRevertIcon // ignore: cast_nullable_to_non_nullable
as bool?,extra: freezed == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonacoDiffOptions].
extension MonacoDiffOptionsPatterns on MonacoDiffOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoDiffOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoDiffOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoDiffOptions value)  $default,){
final _that = this;
switch (_that) {
case _MonacoDiffOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoDiffOptions value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoDiffOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? renderSideBySide,  bool? readOnly,  bool? originalEditable,  bool? ignoreTrimWhitespace,  bool? renderMarginRevertIcon,  Map<String, Object?>? extra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoDiffOptions() when $default != null:
return $default(_that.renderSideBySide,_that.readOnly,_that.originalEditable,_that.ignoreTrimWhitespace,_that.renderMarginRevertIcon,_that.extra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? renderSideBySide,  bool? readOnly,  bool? originalEditable,  bool? ignoreTrimWhitespace,  bool? renderMarginRevertIcon,  Map<String, Object?>? extra)  $default,) {final _that = this;
switch (_that) {
case _MonacoDiffOptions():
return $default(_that.renderSideBySide,_that.readOnly,_that.originalEditable,_that.ignoreTrimWhitespace,_that.renderMarginRevertIcon,_that.extra);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? renderSideBySide,  bool? readOnly,  bool? originalEditable,  bool? ignoreTrimWhitespace,  bool? renderMarginRevertIcon,  Map<String, Object?>? extra)?  $default,) {final _that = this;
switch (_that) {
case _MonacoDiffOptions() when $default != null:
return $default(_that.renderSideBySide,_that.readOnly,_that.originalEditable,_that.ignoreTrimWhitespace,_that.renderMarginRevertIcon,_that.extra);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoDiffOptions extends MonacoDiffOptions {
  const _MonacoDiffOptions({this.renderSideBySide, this.readOnly, this.originalEditable, this.ignoreTrimWhitespace, this.renderMarginRevertIcon,  Map<String, Object?>? extra}): _extra = extra,super._();
  

/// `true` renders original and modified side by side; `false` renders
/// an inline (unified) diff.
@override final  bool? renderSideBySide;
/// Whether the modified editor is read-only.
@override final  bool? readOnly;
/// Whether the original (left) editor accepts edits.
@override final  bool? originalEditable;
/// Whether leading/trailing whitespace differences are ignored.
@override final  bool? ignoreTrimWhitespace;
/// Whether the revert arrows are shown in the glyph margin.
@override final  bool? renderMarginRevertIcon;
/// Raw Monaco diff options merged last (they win over typed fields).
 final  Map<String, Object?>? _extra;
/// Raw Monaco diff options merged last (they win over typed fields).
@override Map<String, Object?>? get extra {
  final value = _extra;
  if (value == null) return null;
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of MonacoDiffOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoDiffOptionsCopyWith<_MonacoDiffOptions> get copyWith => __$MonacoDiffOptionsCopyWithImpl<_MonacoDiffOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoDiffOptions&&(identical(other.renderSideBySide, renderSideBySide) || other.renderSideBySide == renderSideBySide)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.originalEditable, originalEditable) || other.originalEditable == originalEditable)&&(identical(other.ignoreTrimWhitespace, ignoreTrimWhitespace) || other.ignoreTrimWhitespace == ignoreTrimWhitespace)&&(identical(other.renderMarginRevertIcon, renderMarginRevertIcon) || other.renderMarginRevertIcon == renderMarginRevertIcon)&&const DeepCollectionEquality().equals(other.extra, _extra));
}


@override
int get hashCode {
    return Object.hash(runtimeType,renderSideBySide,readOnly,originalEditable,ignoreTrimWhitespace,renderMarginRevertIcon,const DeepCollectionEquality().hash(_extra));
}

@override
String toString() {
    return 'MonacoDiffOptions(renderSideBySide: $renderSideBySide, readOnly: $readOnly, originalEditable: $originalEditable, ignoreTrimWhitespace: $ignoreTrimWhitespace, renderMarginRevertIcon: $renderMarginRevertIcon, extra: $extra)';
}


}

/// @nodoc
abstract mixin class _$MonacoDiffOptionsCopyWith<$Res> implements $MonacoDiffOptionsCopyWith<$Res> {
  factory _$MonacoDiffOptionsCopyWith(_MonacoDiffOptions value, $Res Function(_MonacoDiffOptions) _then) = __$MonacoDiffOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool? renderSideBySide, bool? readOnly, bool? originalEditable, bool? ignoreTrimWhitespace, bool? renderMarginRevertIcon, Map<String, Object?>? extra
});




}
/// @nodoc
class __$MonacoDiffOptionsCopyWithImpl<$Res>
    implements _$MonacoDiffOptionsCopyWith<$Res> {
  __$MonacoDiffOptionsCopyWithImpl(this._self, this._then);

  final _MonacoDiffOptions _self;
  final $Res Function(_MonacoDiffOptions) _then;

/// Create a copy of MonacoDiffOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? renderSideBySide = freezed,Object? readOnly = freezed,Object? originalEditable = freezed,Object? ignoreTrimWhitespace = freezed,Object? renderMarginRevertIcon = freezed,Object? extra = freezed,}) {
  return _then(_MonacoDiffOptions(
renderSideBySide: freezed == renderSideBySide ? _self.renderSideBySide : renderSideBySide // ignore: cast_nullable_to_non_nullable
as bool?,readOnly: freezed == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool?,originalEditable: freezed == originalEditable ? _self.originalEditable : originalEditable // ignore: cast_nullable_to_non_nullable
as bool?,ignoreTrimWhitespace: freezed == ignoreTrimWhitespace ? _self.ignoreTrimWhitespace : ignoreTrimWhitespace // ignore: cast_nullable_to_non_nullable
as bool?,renderMarginRevertIcon: freezed == renderMarginRevertIcon ? _self.renderMarginRevertIcon : renderMarginRevertIcon // ignore: cast_nullable_to_non_nullable
as bool?,extra: freezed == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

// dart format on
