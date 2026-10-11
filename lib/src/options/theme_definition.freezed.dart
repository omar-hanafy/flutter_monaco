// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MonacoThemeDefinition {

/// Custom theme identifier passed to `monaco.editor.setTheme`.
 String get id;/// Built-in Monaco base theme used as the starting point.
 MonacoBaseTheme get base;/// Whether Monaco should inherit unspecified rules from [base].
 bool get inherit;/// Token color rules layered on top of [base].
 List<MonacoThemeRule> get rules;/// Monaco color-token map (e.g. `{'editor.background': '#1E1E1E'}`).
 Map<String, String> get colors;/// Optional encoded token colors accepted by Monaco.
 List<String>? get encodedTokensColors;
/// Create a copy of MonacoThemeDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoThemeDefinitionCopyWith<MonacoThemeDefinition> get copyWith => _$MonacoThemeDefinitionCopyWithImpl<MonacoThemeDefinition>(this as MonacoThemeDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoThemeDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoThemeDefinition&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.base, _this.base) || other.base == _this.base)&&(identical(other.inherit, _this.inherit) || other.inherit == _this.inherit)&&const DeepCollectionEquality().equals(other.rules, _this.rules)&&const DeepCollectionEquality().equals(other.colors, _this.colors)&&const DeepCollectionEquality().equals(other.encodedTokensColors, _this.encodedTokensColors));
}


@override
int get hashCode {
  final _this = this as MonacoThemeDefinition;
  return Object.hash(runtimeType,_this.id,_this.base,_this.inherit,const DeepCollectionEquality().hash(_this.rules),const DeepCollectionEquality().hash(_this.colors),const DeepCollectionEquality().hash(_this.encodedTokensColors));
}

@override
String toString() {
  final _this = this as MonacoThemeDefinition;
  return 'MonacoThemeDefinition(id: ${_this.id}, base: ${_this.base}, inherit: ${_this.inherit}, rules: ${_this.rules}, colors: ${_this.colors}, encodedTokensColors: ${_this.encodedTokensColors})';
}


}

/// @nodoc
abstract mixin class $MonacoThemeDefinitionCopyWith<$Res>  {
  factory $MonacoThemeDefinitionCopyWith(MonacoThemeDefinition value, $Res Function(MonacoThemeDefinition) _then) = _$MonacoThemeDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, MonacoBaseTheme base, bool inherit, List<MonacoThemeRule> rules, Map<String, String> colors, List<String>? encodedTokensColors
});




}
/// @nodoc
class _$MonacoThemeDefinitionCopyWithImpl<$Res>
    implements $MonacoThemeDefinitionCopyWith<$Res> {
  _$MonacoThemeDefinitionCopyWithImpl(this._self, this._then);

  final MonacoThemeDefinition _self;
  final $Res Function(MonacoThemeDefinition) _then;

/// Create a copy of MonacoThemeDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? base = null,Object? inherit = null,Object? rules = null,Object? colors = null,Object? encodedTokensColors = freezed,}) {
  return _then(MonacoThemeDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as MonacoBaseTheme,inherit: null == inherit ? _self.inherit : inherit // ignore: cast_nullable_to_non_nullable
as bool,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<MonacoThemeRule>,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as Map<String, String>,encodedTokensColors: freezed == encodedTokensColors ? _self.encodedTokensColors : encodedTokensColors // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonacoThemeDefinition].
extension MonacoThemeDefinitionPatterns on MonacoThemeDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoThemeDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoThemeDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoThemeDefinition value)  $default,){
final _that = this;
switch (_that) {
case _MonacoThemeDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoThemeDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoThemeDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MonacoBaseTheme base,  bool inherit,  List<MonacoThemeRule> rules,  Map<String, String> colors,  List<String>? encodedTokensColors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoThemeDefinition() when $default != null:
return $default(_that.id,_that.base,_that.inherit,_that.rules,_that.colors,_that.encodedTokensColors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MonacoBaseTheme base,  bool inherit,  List<MonacoThemeRule> rules,  Map<String, String> colors,  List<String>? encodedTokensColors)  $default,) {final _that = this;
switch (_that) {
case _MonacoThemeDefinition():
return $default(_that.id,_that.base,_that.inherit,_that.rules,_that.colors,_that.encodedTokensColors);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MonacoBaseTheme base,  bool inherit,  List<MonacoThemeRule> rules,  Map<String, String> colors,  List<String>? encodedTokensColors)?  $default,) {final _that = this;
switch (_that) {
case _MonacoThemeDefinition() when $default != null:
return $default(_that.id,_that.base,_that.inherit,_that.rules,_that.colors,_that.encodedTokensColors);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoThemeDefinition extends MonacoThemeDefinition {
  const _MonacoThemeDefinition({required this.id, required this.base, this.inherit = true,  List<MonacoThemeRule> rules = const <MonacoThemeRule>[],  Map<String, String> colors = const <String, String>{},  List<String>? encodedTokensColors}): _rules = rules,_colors = colors,_encodedTokensColors = encodedTokensColors,super._();
  

/// Custom theme identifier passed to `monaco.editor.setTheme`.
@override final  String id;
/// Built-in Monaco base theme used as the starting point.
@override final  MonacoBaseTheme base;
/// Whether Monaco should inherit unspecified rules from [base].
@override@JsonKey() final  bool inherit;
/// Token color rules layered on top of [base].
 final  List<MonacoThemeRule> _rules;
/// Token color rules layered on top of [base].
@override@JsonKey() List<MonacoThemeRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}

/// Monaco color-token map (e.g. `{'editor.background': '#1E1E1E'}`).
 final  Map<String, String> _colors;
/// Monaco color-token map (e.g. `{'editor.background': '#1E1E1E'}`).
@override@JsonKey() Map<String, String> get colors {
  if (_colors is EqualUnmodifiableMapView) return _colors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_colors);
}

/// Optional encoded token colors accepted by Monaco.
 final  List<String>? _encodedTokensColors;
/// Optional encoded token colors accepted by Monaco.
@override List<String>? get encodedTokensColors {
  final value = _encodedTokensColors;
  if (value == null) return null;
  if (_encodedTokensColors is EqualUnmodifiableListView) return _encodedTokensColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of MonacoThemeDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoThemeDefinitionCopyWith<_MonacoThemeDefinition> get copyWith => __$MonacoThemeDefinitionCopyWithImpl<_MonacoThemeDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoThemeDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.base, base) || other.base == base)&&(identical(other.inherit, inherit) || other.inherit == inherit)&&const DeepCollectionEquality().equals(other.rules, _rules)&&const DeepCollectionEquality().equals(other.colors, _colors)&&const DeepCollectionEquality().equals(other.encodedTokensColors, _encodedTokensColors));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,base,inherit,const DeepCollectionEquality().hash(_rules),const DeepCollectionEquality().hash(_colors),const DeepCollectionEquality().hash(_encodedTokensColors));
}

@override
String toString() {
    return 'MonacoThemeDefinition(id: $id, base: $base, inherit: $inherit, rules: $rules, colors: $colors, encodedTokensColors: $encodedTokensColors)';
}


}

/// @nodoc
abstract mixin class _$MonacoThemeDefinitionCopyWith<$Res> implements $MonacoThemeDefinitionCopyWith<$Res> {
  factory _$MonacoThemeDefinitionCopyWith(_MonacoThemeDefinition value, $Res Function(_MonacoThemeDefinition) _then) = __$MonacoThemeDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, MonacoBaseTheme base, bool inherit, List<MonacoThemeRule> rules, Map<String, String> colors, List<String>? encodedTokensColors
});




}
/// @nodoc
class __$MonacoThemeDefinitionCopyWithImpl<$Res>
    implements _$MonacoThemeDefinitionCopyWith<$Res> {
  __$MonacoThemeDefinitionCopyWithImpl(this._self, this._then);

  final _MonacoThemeDefinition _self;
  final $Res Function(_MonacoThemeDefinition) _then;

/// Create a copy of MonacoThemeDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? base = null,Object? inherit = null,Object? rules = null,Object? colors = null,Object? encodedTokensColors = freezed,}) {
  return _then(_MonacoThemeDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as MonacoBaseTheme,inherit: null == inherit ? _self.inherit : inherit // ignore: cast_nullable_to_non_nullable
as bool,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<MonacoThemeRule>,colors: null == colors ? _self._colors : colors // ignore: cast_nullable_to_non_nullable
as Map<String, String>,encodedTokensColors: freezed == encodedTokensColors ? _self._encodedTokensColors : encodedTokensColors // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

/// @nodoc
mixin _$MonacoThemeRule {

/// Token selector, for example `comment`, `keyword`, or `string`.
 String get token;/// Foreground color without the `#` prefix.
 String? get foreground;/// Background color without the `#` prefix.
 String? get background;/// Monaco font style string (e.g. `italic`, `bold`, `italic underline`).
 String? get fontStyle;
/// Create a copy of MonacoThemeRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoThemeRuleCopyWith<MonacoThemeRule> get copyWith => _$MonacoThemeRuleCopyWithImpl<MonacoThemeRule>(this as MonacoThemeRule, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoThemeRule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoThemeRule&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.foreground, _this.foreground) || other.foreground == _this.foreground)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.fontStyle, _this.fontStyle) || other.fontStyle == _this.fontStyle));
}


@override
int get hashCode {
  final _this = this as MonacoThemeRule;
  return Object.hash(runtimeType,_this.token,_this.foreground,_this.background,_this.fontStyle);
}

@override
String toString() {
  final _this = this as MonacoThemeRule;
  return 'MonacoThemeRule(token: ${_this.token}, foreground: ${_this.foreground}, background: ${_this.background}, fontStyle: ${_this.fontStyle})';
}


}

/// @nodoc
abstract mixin class $MonacoThemeRuleCopyWith<$Res>  {
  factory $MonacoThemeRuleCopyWith(MonacoThemeRule value, $Res Function(MonacoThemeRule) _then) = _$MonacoThemeRuleCopyWithImpl;
@useResult
$Res call({
 String token, String? foreground, String? background, String? fontStyle
});




}
/// @nodoc
class _$MonacoThemeRuleCopyWithImpl<$Res>
    implements $MonacoThemeRuleCopyWith<$Res> {
  _$MonacoThemeRuleCopyWithImpl(this._self, this._then);

  final MonacoThemeRule _self;
  final $Res Function(MonacoThemeRule) _then;

/// Create a copy of MonacoThemeRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? foreground = freezed,Object? background = freezed,Object? fontStyle = freezed,}) {
  return _then(MonacoThemeRule(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,foreground: freezed == foreground ? _self.foreground : foreground // ignore: cast_nullable_to_non_nullable
as String?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,fontStyle: freezed == fontStyle ? _self.fontStyle : fontStyle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonacoThemeRule].
extension MonacoThemeRulePatterns on MonacoThemeRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoThemeRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoThemeRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoThemeRule value)  $default,){
final _that = this;
switch (_that) {
case _MonacoThemeRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoThemeRule value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoThemeRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String? foreground,  String? background,  String? fontStyle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoThemeRule() when $default != null:
return $default(_that.token,_that.foreground,_that.background,_that.fontStyle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String? foreground,  String? background,  String? fontStyle)  $default,) {final _that = this;
switch (_that) {
case _MonacoThemeRule():
return $default(_that.token,_that.foreground,_that.background,_that.fontStyle);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String? foreground,  String? background,  String? fontStyle)?  $default,) {final _that = this;
switch (_that) {
case _MonacoThemeRule() when $default != null:
return $default(_that.token,_that.foreground,_that.background,_that.fontStyle);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoThemeRule extends MonacoThemeRule {
  const _MonacoThemeRule({required this.token, this.foreground, this.background, this.fontStyle}): super._();
  

/// Token selector, for example `comment`, `keyword`, or `string`.
@override final  String token;
/// Foreground color without the `#` prefix.
@override final  String? foreground;
/// Background color without the `#` prefix.
@override final  String? background;
/// Monaco font style string (e.g. `italic`, `bold`, `italic underline`).
@override final  String? fontStyle;

/// Create a copy of MonacoThemeRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoThemeRuleCopyWith<_MonacoThemeRule> get copyWith => __$MonacoThemeRuleCopyWithImpl<_MonacoThemeRule>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoThemeRule&&(identical(other.token, token) || other.token == token)&&(identical(other.foreground, foreground) || other.foreground == foreground)&&(identical(other.background, background) || other.background == background)&&(identical(other.fontStyle, fontStyle) || other.fontStyle == fontStyle));
}


@override
int get hashCode {
    return Object.hash(runtimeType,token,foreground,background,fontStyle);
}

@override
String toString() {
    return 'MonacoThemeRule(token: $token, foreground: $foreground, background: $background, fontStyle: $fontStyle)';
}


}

/// @nodoc
abstract mixin class _$MonacoThemeRuleCopyWith<$Res> implements $MonacoThemeRuleCopyWith<$Res> {
  factory _$MonacoThemeRuleCopyWith(_MonacoThemeRule value, $Res Function(_MonacoThemeRule) _then) = __$MonacoThemeRuleCopyWithImpl;
@override @useResult
$Res call({
 String token, String? foreground, String? background, String? fontStyle
});




}
/// @nodoc
class __$MonacoThemeRuleCopyWithImpl<$Res>
    implements _$MonacoThemeRuleCopyWith<$Res> {
  __$MonacoThemeRuleCopyWithImpl(this._self, this._then);

  final _MonacoThemeRule _self;
  final $Res Function(_MonacoThemeRule) _then;

/// Create a copy of MonacoThemeRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? foreground = freezed,Object? background = freezed,Object? fontStyle = freezed,}) {
  return _then(_MonacoThemeRule(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,foreground: freezed == foreground ? _self.foreground : foreground // ignore: cast_nullable_to_non_nullable
as String?,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,fontStyle: freezed == fontStyle ? _self.fontStyle : fontStyle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
