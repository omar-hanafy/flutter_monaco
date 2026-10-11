// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sub_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MonacoPadding {

/// Space above the first line, in pixels.
 int? get top;/// Space below the last line, in pixels.
 int? get bottom;
/// Create a copy of MonacoPadding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoPaddingCopyWith<MonacoPadding> get copyWith => _$MonacoPaddingCopyWithImpl<MonacoPadding>(this as MonacoPadding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoPadding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoPadding&&(identical(other.top, _this.top) || other.top == _this.top)&&(identical(other.bottom, _this.bottom) || other.bottom == _this.bottom));
}


@override
int get hashCode {
  final _this = this as MonacoPadding;
  return Object.hash(runtimeType,_this.top,_this.bottom);
}

@override
String toString() {
  final _this = this as MonacoPadding;
  return 'MonacoPadding(top: ${_this.top}, bottom: ${_this.bottom})';
}


}

/// @nodoc
abstract mixin class $MonacoPaddingCopyWith<$Res>  {
  factory $MonacoPaddingCopyWith(MonacoPadding value, $Res Function(MonacoPadding) _then) = _$MonacoPaddingCopyWithImpl;
@useResult
$Res call({
 int? top, int? bottom
});




}
/// @nodoc
class _$MonacoPaddingCopyWithImpl<$Res>
    implements $MonacoPaddingCopyWith<$Res> {
  _$MonacoPaddingCopyWithImpl(this._self, this._then);

  final MonacoPadding _self;
  final $Res Function(MonacoPadding) _then;

/// Create a copy of MonacoPadding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? top = freezed,Object? bottom = freezed,}) {
  return _then(MonacoPadding(
top: freezed == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as int?,bottom: freezed == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonacoPadding].
extension MonacoPaddingPatterns on MonacoPadding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoPadding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoPadding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoPadding value)  $default,){
final _that = this;
switch (_that) {
case _MonacoPadding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoPadding value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoPadding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? top,  int? bottom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoPadding() when $default != null:
return $default(_that.top,_that.bottom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? top,  int? bottom)  $default,) {final _that = this;
switch (_that) {
case _MonacoPadding():
return $default(_that.top,_that.bottom);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? top,  int? bottom)?  $default,) {final _that = this;
switch (_that) {
case _MonacoPadding() when $default != null:
return $default(_that.top,_that.bottom);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoPadding extends MonacoPadding {
  const _MonacoPadding({this.top, this.bottom}): super._();
  

/// Space above the first line, in pixels.
@override final  int? top;
/// Space below the last line, in pixels.
@override final  int? bottom;

/// Create a copy of MonacoPadding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoPaddingCopyWith<_MonacoPadding> get copyWith => __$MonacoPaddingCopyWithImpl<_MonacoPadding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoPadding&&(identical(other.top, top) || other.top == top)&&(identical(other.bottom, bottom) || other.bottom == bottom));
}


@override
int get hashCode {
    return Object.hash(runtimeType,top,bottom);
}

@override
String toString() {
    return 'MonacoPadding(top: $top, bottom: $bottom)';
}


}

/// @nodoc
abstract mixin class _$MonacoPaddingCopyWith<$Res> implements $MonacoPaddingCopyWith<$Res> {
  factory _$MonacoPaddingCopyWith(_MonacoPadding value, $Res Function(_MonacoPadding) _then) = __$MonacoPaddingCopyWithImpl;
@override @useResult
$Res call({
 int? top, int? bottom
});




}
/// @nodoc
class __$MonacoPaddingCopyWithImpl<$Res>
    implements _$MonacoPaddingCopyWith<$Res> {
  __$MonacoPaddingCopyWithImpl(this._self, this._then);

  final _MonacoPadding _self;
  final $Res Function(_MonacoPadding) _then;

/// Create a copy of MonacoPadding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? top = freezed,Object? bottom = freezed,}) {
  return _then(_MonacoPadding(
top: freezed == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as int?,bottom: freezed == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$MonacoMinimapOptions {

/// Whether the minimap is shown.
 bool? get enabled;/// Which side of the editor hosts the minimap.
 MonacoMinimapSide? get side;/// Whether real characters (instead of color blocks) are rendered.
 bool? get renderCharacters;/// Maximum number of columns the minimap renders.
 int? get maxColumn;/// Minimap scale factor (1, 2, or 3).
 int? get scale;
/// Create a copy of MonacoMinimapOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoMinimapOptionsCopyWith<MonacoMinimapOptions> get copyWith => _$MonacoMinimapOptionsCopyWithImpl<MonacoMinimapOptions>(this as MonacoMinimapOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoMinimapOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoMinimapOptions&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.side, _this.side) || other.side == _this.side)&&(identical(other.renderCharacters, _this.renderCharacters) || other.renderCharacters == _this.renderCharacters)&&(identical(other.maxColumn, _this.maxColumn) || other.maxColumn == _this.maxColumn)&&(identical(other.scale, _this.scale) || other.scale == _this.scale));
}


@override
int get hashCode {
  final _this = this as MonacoMinimapOptions;
  return Object.hash(runtimeType,_this.enabled,_this.side,_this.renderCharacters,_this.maxColumn,_this.scale);
}

@override
String toString() {
  final _this = this as MonacoMinimapOptions;
  return 'MonacoMinimapOptions(enabled: ${_this.enabled}, side: ${_this.side}, renderCharacters: ${_this.renderCharacters}, maxColumn: ${_this.maxColumn}, scale: ${_this.scale})';
}


}

/// @nodoc
abstract mixin class $MonacoMinimapOptionsCopyWith<$Res>  {
  factory $MonacoMinimapOptionsCopyWith(MonacoMinimapOptions value, $Res Function(MonacoMinimapOptions) _then) = _$MonacoMinimapOptionsCopyWithImpl;
@useResult
$Res call({
 bool? enabled, MonacoMinimapSide? side, bool? renderCharacters, int? maxColumn, int? scale
});




}
/// @nodoc
class _$MonacoMinimapOptionsCopyWithImpl<$Res>
    implements $MonacoMinimapOptionsCopyWith<$Res> {
  _$MonacoMinimapOptionsCopyWithImpl(this._self, this._then);

  final MonacoMinimapOptions _self;
  final $Res Function(MonacoMinimapOptions) _then;

/// Create a copy of MonacoMinimapOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = freezed,Object? side = freezed,Object? renderCharacters = freezed,Object? maxColumn = freezed,Object? scale = freezed,}) {
  return _then(MonacoMinimapOptions(
enabled: freezed == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool?,side: freezed == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as MonacoMinimapSide?,renderCharacters: freezed == renderCharacters ? _self.renderCharacters : renderCharacters // ignore: cast_nullable_to_non_nullable
as bool?,maxColumn: freezed == maxColumn ? _self.maxColumn : maxColumn // ignore: cast_nullable_to_non_nullable
as int?,scale: freezed == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonacoMinimapOptions].
extension MonacoMinimapOptionsPatterns on MonacoMinimapOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoMinimapOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoMinimapOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoMinimapOptions value)  $default,){
final _that = this;
switch (_that) {
case _MonacoMinimapOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoMinimapOptions value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoMinimapOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? enabled,  MonacoMinimapSide? side,  bool? renderCharacters,  int? maxColumn,  int? scale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoMinimapOptions() when $default != null:
return $default(_that.enabled,_that.side,_that.renderCharacters,_that.maxColumn,_that.scale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? enabled,  MonacoMinimapSide? side,  bool? renderCharacters,  int? maxColumn,  int? scale)  $default,) {final _that = this;
switch (_that) {
case _MonacoMinimapOptions():
return $default(_that.enabled,_that.side,_that.renderCharacters,_that.maxColumn,_that.scale);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? enabled,  MonacoMinimapSide? side,  bool? renderCharacters,  int? maxColumn,  int? scale)?  $default,) {final _that = this;
switch (_that) {
case _MonacoMinimapOptions() when $default != null:
return $default(_that.enabled,_that.side,_that.renderCharacters,_that.maxColumn,_that.scale);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoMinimapOptions extends MonacoMinimapOptions {
  const _MonacoMinimapOptions({this.enabled, this.side, this.renderCharacters, this.maxColumn, this.scale}): super._();
  

/// Whether the minimap is shown.
@override final  bool? enabled;
/// Which side of the editor hosts the minimap.
@override final  MonacoMinimapSide? side;
/// Whether real characters (instead of color blocks) are rendered.
@override final  bool? renderCharacters;
/// Maximum number of columns the minimap renders.
@override final  int? maxColumn;
/// Minimap scale factor (1, 2, or 3).
@override final  int? scale;

/// Create a copy of MonacoMinimapOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoMinimapOptionsCopyWith<_MonacoMinimapOptions> get copyWith => __$MonacoMinimapOptionsCopyWithImpl<_MonacoMinimapOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoMinimapOptions&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.side, side) || other.side == side)&&(identical(other.renderCharacters, renderCharacters) || other.renderCharacters == renderCharacters)&&(identical(other.maxColumn, maxColumn) || other.maxColumn == maxColumn)&&(identical(other.scale, scale) || other.scale == scale));
}


@override
int get hashCode {
    return Object.hash(runtimeType,enabled,side,renderCharacters,maxColumn,scale);
}

@override
String toString() {
    return 'MonacoMinimapOptions(enabled: $enabled, side: $side, renderCharacters: $renderCharacters, maxColumn: $maxColumn, scale: $scale)';
}


}

/// @nodoc
abstract mixin class _$MonacoMinimapOptionsCopyWith<$Res> implements $MonacoMinimapOptionsCopyWith<$Res> {
  factory _$MonacoMinimapOptionsCopyWith(_MonacoMinimapOptions value, $Res Function(_MonacoMinimapOptions) _then) = __$MonacoMinimapOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool? enabled, MonacoMinimapSide? side, bool? renderCharacters, int? maxColumn, int? scale
});




}
/// @nodoc
class __$MonacoMinimapOptionsCopyWithImpl<$Res>
    implements _$MonacoMinimapOptionsCopyWith<$Res> {
  __$MonacoMinimapOptionsCopyWithImpl(this._self, this._then);

  final _MonacoMinimapOptions _self;
  final $Res Function(_MonacoMinimapOptions) _then;

/// Create a copy of MonacoMinimapOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = freezed,Object? side = freezed,Object? renderCharacters = freezed,Object? maxColumn = freezed,Object? scale = freezed,}) {
  return _then(_MonacoMinimapOptions(
enabled: freezed == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool?,side: freezed == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as MonacoMinimapSide?,renderCharacters: freezed == renderCharacters ? _self.renderCharacters : renderCharacters // ignore: cast_nullable_to_non_nullable
as bool?,maxColumn: freezed == maxColumn ? _self.maxColumn : maxColumn // ignore: cast_nullable_to_non_nullable
as int?,scale: freezed == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$MonacoScrollbarOptions {

/// Vertical scrollbar visibility.
 MonacoScrollbarVisibility? get vertical;/// Horizontal scrollbar visibility.
 MonacoScrollbarVisibility? get horizontal;/// Vertical scrollbar width, in pixels.
 int? get verticalScrollbarSize;/// Horizontal scrollbar height, in pixels.
 int? get horizontalScrollbarSize;/// Whether the editor consumes mouse wheel events.
 bool? get handleMouseWheel;/// Whether scrollbars cast shadows on the content.
 bool? get useShadows;
/// Create a copy of MonacoScrollbarOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoScrollbarOptionsCopyWith<MonacoScrollbarOptions> get copyWith => _$MonacoScrollbarOptionsCopyWithImpl<MonacoScrollbarOptions>(this as MonacoScrollbarOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoScrollbarOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoScrollbarOptions&&(identical(other.vertical, _this.vertical) || other.vertical == _this.vertical)&&(identical(other.horizontal, _this.horizontal) || other.horizontal == _this.horizontal)&&(identical(other.verticalScrollbarSize, _this.verticalScrollbarSize) || other.verticalScrollbarSize == _this.verticalScrollbarSize)&&(identical(other.horizontalScrollbarSize, _this.horizontalScrollbarSize) || other.horizontalScrollbarSize == _this.horizontalScrollbarSize)&&(identical(other.handleMouseWheel, _this.handleMouseWheel) || other.handleMouseWheel == _this.handleMouseWheel)&&(identical(other.useShadows, _this.useShadows) || other.useShadows == _this.useShadows));
}


@override
int get hashCode {
  final _this = this as MonacoScrollbarOptions;
  return Object.hash(runtimeType,_this.vertical,_this.horizontal,_this.verticalScrollbarSize,_this.horizontalScrollbarSize,_this.handleMouseWheel,_this.useShadows);
}

@override
String toString() {
  final _this = this as MonacoScrollbarOptions;
  return 'MonacoScrollbarOptions(vertical: ${_this.vertical}, horizontal: ${_this.horizontal}, verticalScrollbarSize: ${_this.verticalScrollbarSize}, horizontalScrollbarSize: ${_this.horizontalScrollbarSize}, handleMouseWheel: ${_this.handleMouseWheel}, useShadows: ${_this.useShadows})';
}


}

/// @nodoc
abstract mixin class $MonacoScrollbarOptionsCopyWith<$Res>  {
  factory $MonacoScrollbarOptionsCopyWith(MonacoScrollbarOptions value, $Res Function(MonacoScrollbarOptions) _then) = _$MonacoScrollbarOptionsCopyWithImpl;
@useResult
$Res call({
 MonacoScrollbarVisibility? vertical, MonacoScrollbarVisibility? horizontal, int? verticalScrollbarSize, int? horizontalScrollbarSize, bool? handleMouseWheel, bool? useShadows
});




}
/// @nodoc
class _$MonacoScrollbarOptionsCopyWithImpl<$Res>
    implements $MonacoScrollbarOptionsCopyWith<$Res> {
  _$MonacoScrollbarOptionsCopyWithImpl(this._self, this._then);

  final MonacoScrollbarOptions _self;
  final $Res Function(MonacoScrollbarOptions) _then;

/// Create a copy of MonacoScrollbarOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vertical = freezed,Object? horizontal = freezed,Object? verticalScrollbarSize = freezed,Object? horizontalScrollbarSize = freezed,Object? handleMouseWheel = freezed,Object? useShadows = freezed,}) {
  return _then(MonacoScrollbarOptions(
vertical: freezed == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as MonacoScrollbarVisibility?,horizontal: freezed == horizontal ? _self.horizontal : horizontal // ignore: cast_nullable_to_non_nullable
as MonacoScrollbarVisibility?,verticalScrollbarSize: freezed == verticalScrollbarSize ? _self.verticalScrollbarSize : verticalScrollbarSize // ignore: cast_nullable_to_non_nullable
as int?,horizontalScrollbarSize: freezed == horizontalScrollbarSize ? _self.horizontalScrollbarSize : horizontalScrollbarSize // ignore: cast_nullable_to_non_nullable
as int?,handleMouseWheel: freezed == handleMouseWheel ? _self.handleMouseWheel : handleMouseWheel // ignore: cast_nullable_to_non_nullable
as bool?,useShadows: freezed == useShadows ? _self.useShadows : useShadows // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonacoScrollbarOptions].
extension MonacoScrollbarOptionsPatterns on MonacoScrollbarOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoScrollbarOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoScrollbarOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoScrollbarOptions value)  $default,){
final _that = this;
switch (_that) {
case _MonacoScrollbarOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoScrollbarOptions value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoScrollbarOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MonacoScrollbarVisibility? vertical,  MonacoScrollbarVisibility? horizontal,  int? verticalScrollbarSize,  int? horizontalScrollbarSize,  bool? handleMouseWheel,  bool? useShadows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoScrollbarOptions() when $default != null:
return $default(_that.vertical,_that.horizontal,_that.verticalScrollbarSize,_that.horizontalScrollbarSize,_that.handleMouseWheel,_that.useShadows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MonacoScrollbarVisibility? vertical,  MonacoScrollbarVisibility? horizontal,  int? verticalScrollbarSize,  int? horizontalScrollbarSize,  bool? handleMouseWheel,  bool? useShadows)  $default,) {final _that = this;
switch (_that) {
case _MonacoScrollbarOptions():
return $default(_that.vertical,_that.horizontal,_that.verticalScrollbarSize,_that.horizontalScrollbarSize,_that.handleMouseWheel,_that.useShadows);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MonacoScrollbarVisibility? vertical,  MonacoScrollbarVisibility? horizontal,  int? verticalScrollbarSize,  int? horizontalScrollbarSize,  bool? handleMouseWheel,  bool? useShadows)?  $default,) {final _that = this;
switch (_that) {
case _MonacoScrollbarOptions() when $default != null:
return $default(_that.vertical,_that.horizontal,_that.verticalScrollbarSize,_that.horizontalScrollbarSize,_that.handleMouseWheel,_that.useShadows);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoScrollbarOptions extends MonacoScrollbarOptions {
  const _MonacoScrollbarOptions({this.vertical, this.horizontal, this.verticalScrollbarSize, this.horizontalScrollbarSize, this.handleMouseWheel, this.useShadows}): super._();
  

/// Vertical scrollbar visibility.
@override final  MonacoScrollbarVisibility? vertical;
/// Horizontal scrollbar visibility.
@override final  MonacoScrollbarVisibility? horizontal;
/// Vertical scrollbar width, in pixels.
@override final  int? verticalScrollbarSize;
/// Horizontal scrollbar height, in pixels.
@override final  int? horizontalScrollbarSize;
/// Whether the editor consumes mouse wheel events.
@override final  bool? handleMouseWheel;
/// Whether scrollbars cast shadows on the content.
@override final  bool? useShadows;

/// Create a copy of MonacoScrollbarOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoScrollbarOptionsCopyWith<_MonacoScrollbarOptions> get copyWith => __$MonacoScrollbarOptionsCopyWithImpl<_MonacoScrollbarOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoScrollbarOptions&&(identical(other.vertical, vertical) || other.vertical == vertical)&&(identical(other.horizontal, horizontal) || other.horizontal == horizontal)&&(identical(other.verticalScrollbarSize, verticalScrollbarSize) || other.verticalScrollbarSize == verticalScrollbarSize)&&(identical(other.horizontalScrollbarSize, horizontalScrollbarSize) || other.horizontalScrollbarSize == horizontalScrollbarSize)&&(identical(other.handleMouseWheel, handleMouseWheel) || other.handleMouseWheel == handleMouseWheel)&&(identical(other.useShadows, useShadows) || other.useShadows == useShadows));
}


@override
int get hashCode {
    return Object.hash(runtimeType,vertical,horizontal,verticalScrollbarSize,horizontalScrollbarSize,handleMouseWheel,useShadows);
}

@override
String toString() {
    return 'MonacoScrollbarOptions(vertical: $vertical, horizontal: $horizontal, verticalScrollbarSize: $verticalScrollbarSize, horizontalScrollbarSize: $horizontalScrollbarSize, handleMouseWheel: $handleMouseWheel, useShadows: $useShadows)';
}


}

/// @nodoc
abstract mixin class _$MonacoScrollbarOptionsCopyWith<$Res> implements $MonacoScrollbarOptionsCopyWith<$Res> {
  factory _$MonacoScrollbarOptionsCopyWith(_MonacoScrollbarOptions value, $Res Function(_MonacoScrollbarOptions) _then) = __$MonacoScrollbarOptionsCopyWithImpl;
@override @useResult
$Res call({
 MonacoScrollbarVisibility? vertical, MonacoScrollbarVisibility? horizontal, int? verticalScrollbarSize, int? horizontalScrollbarSize, bool? handleMouseWheel, bool? useShadows
});




}
/// @nodoc
class __$MonacoScrollbarOptionsCopyWithImpl<$Res>
    implements _$MonacoScrollbarOptionsCopyWith<$Res> {
  __$MonacoScrollbarOptionsCopyWithImpl(this._self, this._then);

  final _MonacoScrollbarOptions _self;
  final $Res Function(_MonacoScrollbarOptions) _then;

/// Create a copy of MonacoScrollbarOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vertical = freezed,Object? horizontal = freezed,Object? verticalScrollbarSize = freezed,Object? horizontalScrollbarSize = freezed,Object? handleMouseWheel = freezed,Object? useShadows = freezed,}) {
  return _then(_MonacoScrollbarOptions(
vertical: freezed == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as MonacoScrollbarVisibility?,horizontal: freezed == horizontal ? _self.horizontal : horizontal // ignore: cast_nullable_to_non_nullable
as MonacoScrollbarVisibility?,verticalScrollbarSize: freezed == verticalScrollbarSize ? _self.verticalScrollbarSize : verticalScrollbarSize // ignore: cast_nullable_to_non_nullable
as int?,horizontalScrollbarSize: freezed == horizontalScrollbarSize ? _self.horizontalScrollbarSize : horizontalScrollbarSize // ignore: cast_nullable_to_non_nullable
as int?,handleMouseWheel: freezed == handleMouseWheel ? _self.handleMouseWheel : handleMouseWheel // ignore: cast_nullable_to_non_nullable
as bool?,useShadows: freezed == useShadows ? _self.useShadows : useShadows // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$MonacoGuidesOptions {

/// Whether bracket-pair guides are rendered.
 bool? get bracketPairs;/// Whether indentation guides are rendered.
 bool? get indentation;
/// Create a copy of MonacoGuidesOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoGuidesOptionsCopyWith<MonacoGuidesOptions> get copyWith => _$MonacoGuidesOptionsCopyWithImpl<MonacoGuidesOptions>(this as MonacoGuidesOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoGuidesOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoGuidesOptions&&(identical(other.bracketPairs, _this.bracketPairs) || other.bracketPairs == _this.bracketPairs)&&(identical(other.indentation, _this.indentation) || other.indentation == _this.indentation));
}


@override
int get hashCode {
  final _this = this as MonacoGuidesOptions;
  return Object.hash(runtimeType,_this.bracketPairs,_this.indentation);
}

@override
String toString() {
  final _this = this as MonacoGuidesOptions;
  return 'MonacoGuidesOptions(bracketPairs: ${_this.bracketPairs}, indentation: ${_this.indentation})';
}


}

/// @nodoc
abstract mixin class $MonacoGuidesOptionsCopyWith<$Res>  {
  factory $MonacoGuidesOptionsCopyWith(MonacoGuidesOptions value, $Res Function(MonacoGuidesOptions) _then) = _$MonacoGuidesOptionsCopyWithImpl;
@useResult
$Res call({
 bool? bracketPairs, bool? indentation
});




}
/// @nodoc
class _$MonacoGuidesOptionsCopyWithImpl<$Res>
    implements $MonacoGuidesOptionsCopyWith<$Res> {
  _$MonacoGuidesOptionsCopyWithImpl(this._self, this._then);

  final MonacoGuidesOptions _self;
  final $Res Function(MonacoGuidesOptions) _then;

/// Create a copy of MonacoGuidesOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bracketPairs = freezed,Object? indentation = freezed,}) {
  return _then(MonacoGuidesOptions(
bracketPairs: freezed == bracketPairs ? _self.bracketPairs : bracketPairs // ignore: cast_nullable_to_non_nullable
as bool?,indentation: freezed == indentation ? _self.indentation : indentation // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonacoGuidesOptions].
extension MonacoGuidesOptionsPatterns on MonacoGuidesOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoGuidesOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoGuidesOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoGuidesOptions value)  $default,){
final _that = this;
switch (_that) {
case _MonacoGuidesOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoGuidesOptions value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoGuidesOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? bracketPairs,  bool? indentation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoGuidesOptions() when $default != null:
return $default(_that.bracketPairs,_that.indentation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? bracketPairs,  bool? indentation)  $default,) {final _that = this;
switch (_that) {
case _MonacoGuidesOptions():
return $default(_that.bracketPairs,_that.indentation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? bracketPairs,  bool? indentation)?  $default,) {final _that = this;
switch (_that) {
case _MonacoGuidesOptions() when $default != null:
return $default(_that.bracketPairs,_that.indentation);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoGuidesOptions extends MonacoGuidesOptions {
  const _MonacoGuidesOptions({this.bracketPairs, this.indentation}): super._();
  

/// Whether bracket-pair guides are rendered.
@override final  bool? bracketPairs;
/// Whether indentation guides are rendered.
@override final  bool? indentation;

/// Create a copy of MonacoGuidesOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoGuidesOptionsCopyWith<_MonacoGuidesOptions> get copyWith => __$MonacoGuidesOptionsCopyWithImpl<_MonacoGuidesOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoGuidesOptions&&(identical(other.bracketPairs, bracketPairs) || other.bracketPairs == bracketPairs)&&(identical(other.indentation, indentation) || other.indentation == indentation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bracketPairs,indentation);
}

@override
String toString() {
    return 'MonacoGuidesOptions(bracketPairs: $bracketPairs, indentation: $indentation)';
}


}

/// @nodoc
abstract mixin class _$MonacoGuidesOptionsCopyWith<$Res> implements $MonacoGuidesOptionsCopyWith<$Res> {
  factory _$MonacoGuidesOptionsCopyWith(_MonacoGuidesOptions value, $Res Function(_MonacoGuidesOptions) _then) = __$MonacoGuidesOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool? bracketPairs, bool? indentation
});




}
/// @nodoc
class __$MonacoGuidesOptionsCopyWithImpl<$Res>
    implements _$MonacoGuidesOptionsCopyWith<$Res> {
  __$MonacoGuidesOptionsCopyWithImpl(this._self, this._then);

  final _MonacoGuidesOptions _self;
  final $Res Function(_MonacoGuidesOptions) _then;

/// Create a copy of MonacoGuidesOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bracketPairs = freezed,Object? indentation = freezed,}) {
  return _then(_MonacoGuidesOptions(
bracketPairs: freezed == bracketPairs ? _self.bracketPairs : bracketPairs // ignore: cast_nullable_to_non_nullable
as bool?,indentation: freezed == indentation ? _self.indentation : indentation // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$MonacoStickyScroll {

/// Whether sticky scroll is enabled.
 bool? get enabled;/// Maximum number of sticky lines shown.
 int? get maxLineCount;
/// Create a copy of MonacoStickyScroll
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoStickyScrollCopyWith<MonacoStickyScroll> get copyWith => _$MonacoStickyScrollCopyWithImpl<MonacoStickyScroll>(this as MonacoStickyScroll, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoStickyScroll;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoStickyScroll&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.maxLineCount, _this.maxLineCount) || other.maxLineCount == _this.maxLineCount));
}


@override
int get hashCode {
  final _this = this as MonacoStickyScroll;
  return Object.hash(runtimeType,_this.enabled,_this.maxLineCount);
}

@override
String toString() {
  final _this = this as MonacoStickyScroll;
  return 'MonacoStickyScroll(enabled: ${_this.enabled}, maxLineCount: ${_this.maxLineCount})';
}


}

/// @nodoc
abstract mixin class $MonacoStickyScrollCopyWith<$Res>  {
  factory $MonacoStickyScrollCopyWith(MonacoStickyScroll value, $Res Function(MonacoStickyScroll) _then) = _$MonacoStickyScrollCopyWithImpl;
@useResult
$Res call({
 bool? enabled, int? maxLineCount
});




}
/// @nodoc
class _$MonacoStickyScrollCopyWithImpl<$Res>
    implements $MonacoStickyScrollCopyWith<$Res> {
  _$MonacoStickyScrollCopyWithImpl(this._self, this._then);

  final MonacoStickyScroll _self;
  final $Res Function(MonacoStickyScroll) _then;

/// Create a copy of MonacoStickyScroll
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = freezed,Object? maxLineCount = freezed,}) {
  return _then(MonacoStickyScroll(
enabled: freezed == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool?,maxLineCount: freezed == maxLineCount ? _self.maxLineCount : maxLineCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonacoStickyScroll].
extension MonacoStickyScrollPatterns on MonacoStickyScroll {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoStickyScroll value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoStickyScroll() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoStickyScroll value)  $default,){
final _that = this;
switch (_that) {
case _MonacoStickyScroll():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoStickyScroll value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoStickyScroll() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? enabled,  int? maxLineCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoStickyScroll() when $default != null:
return $default(_that.enabled,_that.maxLineCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? enabled,  int? maxLineCount)  $default,) {final _that = this;
switch (_that) {
case _MonacoStickyScroll():
return $default(_that.enabled,_that.maxLineCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? enabled,  int? maxLineCount)?  $default,) {final _that = this;
switch (_that) {
case _MonacoStickyScroll() when $default != null:
return $default(_that.enabled,_that.maxLineCount);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoStickyScroll extends MonacoStickyScroll {
  const _MonacoStickyScroll({this.enabled, this.maxLineCount}): super._();
  

/// Whether sticky scroll is enabled.
@override final  bool? enabled;
/// Maximum number of sticky lines shown.
@override final  int? maxLineCount;

/// Create a copy of MonacoStickyScroll
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoStickyScrollCopyWith<_MonacoStickyScroll> get copyWith => __$MonacoStickyScrollCopyWithImpl<_MonacoStickyScroll>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoStickyScroll&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.maxLineCount, maxLineCount) || other.maxLineCount == maxLineCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,enabled,maxLineCount);
}

@override
String toString() {
    return 'MonacoStickyScroll(enabled: $enabled, maxLineCount: $maxLineCount)';
}


}

/// @nodoc
abstract mixin class _$MonacoStickyScrollCopyWith<$Res> implements $MonacoStickyScrollCopyWith<$Res> {
  factory _$MonacoStickyScrollCopyWith(_MonacoStickyScroll value, $Res Function(_MonacoStickyScroll) _then) = __$MonacoStickyScrollCopyWithImpl;
@override @useResult
$Res call({
 bool? enabled, int? maxLineCount
});




}
/// @nodoc
class __$MonacoStickyScrollCopyWithImpl<$Res>
    implements _$MonacoStickyScrollCopyWith<$Res> {
  __$MonacoStickyScrollCopyWithImpl(this._self, this._then);

  final _MonacoStickyScroll _self;
  final $Res Function(_MonacoStickyScroll) _then;

/// Create a copy of MonacoStickyScroll
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = freezed,Object? maxLineCount = freezed,}) {
  return _then(_MonacoStickyScroll(
enabled: freezed == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool?,maxLineCount: freezed == maxLineCount ? _self.maxLineCount : maxLineCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
