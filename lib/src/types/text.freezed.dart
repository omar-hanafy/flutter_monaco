// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditOperation {

/// The range of text to be replaced.
 Range get range;/// The new text to insert. An empty string results in a deletion.
 String get text;/// If `true`, forces markers to move with the text.
 bool? get forceMoveMarkers;
/// Create a copy of EditOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditOperationCopyWith<EditOperation> get copyWith => _$EditOperationCopyWithImpl<EditOperation>(this as EditOperation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditOperation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditOperation&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.forceMoveMarkers, _this.forceMoveMarkers) || other.forceMoveMarkers == _this.forceMoveMarkers));
}


@override
int get hashCode {
  final _this = this as EditOperation;
  return Object.hash(runtimeType,_this.range,_this.text,_this.forceMoveMarkers);
}

@override
String toString() {
  final _this = this as EditOperation;
  return 'EditOperation(range: ${_this.range}, text: ${_this.text}, forceMoveMarkers: ${_this.forceMoveMarkers})';
}


}

/// @nodoc
abstract mixin class $EditOperationCopyWith<$Res>  {
  factory $EditOperationCopyWith(EditOperation value, $Res Function(EditOperation) _then) = _$EditOperationCopyWithImpl;
@useResult
$Res call({
 Range range, String text, bool? forceMoveMarkers
});


$RangeCopyWith<$Res> get range;

}
/// @nodoc
class _$EditOperationCopyWithImpl<$Res>
    implements $EditOperationCopyWith<$Res> {
  _$EditOperationCopyWithImpl(this._self, this._then);

  final EditOperation _self;
  final $Res Function(EditOperation) _then;

/// Create a copy of EditOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? text = null,Object? forceMoveMarkers = freezed,}) {
  return _then(EditOperation(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,forceMoveMarkers: freezed == forceMoveMarkers ? _self.forceMoveMarkers : forceMoveMarkers // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of EditOperation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get range {
  
  return $RangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditOperation].
extension EditOperationPatterns on EditOperation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditOperation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditOperation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditOperation value)  $default,){
final _that = this;
switch (_that) {
case _EditOperation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditOperation value)?  $default,){
final _that = this;
switch (_that) {
case _EditOperation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Range range,  String text,  bool? forceMoveMarkers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditOperation() when $default != null:
return $default(_that.range,_that.text,_that.forceMoveMarkers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Range range,  String text,  bool? forceMoveMarkers)  $default,) {final _that = this;
switch (_that) {
case _EditOperation():
return $default(_that.range,_that.text,_that.forceMoveMarkers);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Range range,  String text,  bool? forceMoveMarkers)?  $default,) {final _that = this;
switch (_that) {
case _EditOperation() when $default != null:
return $default(_that.range,_that.text,_that.forceMoveMarkers);case _:
  return null;

}
}

}

/// @nodoc


class _EditOperation extends EditOperation {
  const _EditOperation({required this.range, required this.text, this.forceMoveMarkers}): super._();
  

/// The range of text to be replaced.
@override final  Range range;
/// The new text to insert. An empty string results in a deletion.
@override final  String text;
/// If `true`, forces markers to move with the text.
@override final  bool? forceMoveMarkers;

/// Create a copy of EditOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditOperationCopyWith<_EditOperation> get copyWith => __$EditOperationCopyWithImpl<_EditOperation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditOperation&&(identical(other.range, range) || other.range == range)&&(identical(other.text, text) || other.text == text)&&(identical(other.forceMoveMarkers, forceMoveMarkers) || other.forceMoveMarkers == forceMoveMarkers));
}


@override
int get hashCode {
    return Object.hash(runtimeType,range,text,forceMoveMarkers);
}

@override
String toString() {
    return 'EditOperation(range: $range, text: $text, forceMoveMarkers: $forceMoveMarkers)';
}


}

/// @nodoc
abstract mixin class _$EditOperationCopyWith<$Res> implements $EditOperationCopyWith<$Res> {
  factory _$EditOperationCopyWith(_EditOperation value, $Res Function(_EditOperation) _then) = __$EditOperationCopyWithImpl;
@override @useResult
$Res call({
 Range range, String text, bool? forceMoveMarkers
});


@override $RangeCopyWith<$Res> get range;

}
/// @nodoc
class __$EditOperationCopyWithImpl<$Res>
    implements _$EditOperationCopyWith<$Res> {
  __$EditOperationCopyWithImpl(this._self, this._then);

  final _EditOperation _self;
  final $Res Function(_EditOperation) _then;

/// Create a copy of EditOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? text = null,Object? forceMoveMarkers = freezed,}) {
  return _then(_EditOperation(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,forceMoveMarkers: freezed == forceMoveMarkers ? _self.forceMoveMarkers : forceMoveMarkers // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of EditOperation
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
mixin _$MonacoTextChange {

/// The range of text that was replaced.
 Range get range;/// The new text that was inserted. An empty string means a deletion.
 String get text;
/// Create a copy of MonacoTextChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoTextChangeCopyWith<MonacoTextChange> get copyWith => _$MonacoTextChangeCopyWithImpl<MonacoTextChange>(this as MonacoTextChange, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoTextChange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoTextChange&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.text, _this.text) || other.text == _this.text));
}


@override
int get hashCode {
  final _this = this as MonacoTextChange;
  return Object.hash(runtimeType,_this.range,_this.text);
}

@override
String toString() {
  final _this = this as MonacoTextChange;
  return 'MonacoTextChange(range: ${_this.range}, text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $MonacoTextChangeCopyWith<$Res>  {
  factory $MonacoTextChangeCopyWith(MonacoTextChange value, $Res Function(MonacoTextChange) _then) = _$MonacoTextChangeCopyWithImpl;
@useResult
$Res call({
 Range range, String text
});


$RangeCopyWith<$Res> get range;

}
/// @nodoc
class _$MonacoTextChangeCopyWithImpl<$Res>
    implements $MonacoTextChangeCopyWith<$Res> {
  _$MonacoTextChangeCopyWithImpl(this._self, this._then);

  final MonacoTextChange _self;
  final $Res Function(MonacoTextChange) _then;

/// Create a copy of MonacoTextChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? text = null,}) {
  return _then(MonacoTextChange(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of MonacoTextChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get range {
  
  return $RangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [MonacoTextChange].
extension MonacoTextChangePatterns on MonacoTextChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoTextChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoTextChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoTextChange value)  $default,){
final _that = this;
switch (_that) {
case _MonacoTextChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoTextChange value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoTextChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Range range,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoTextChange() when $default != null:
return $default(_that.range,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Range range,  String text)  $default,) {final _that = this;
switch (_that) {
case _MonacoTextChange():
return $default(_that.range,_that.text);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Range range,  String text)?  $default,) {final _that = this;
switch (_that) {
case _MonacoTextChange() when $default != null:
return $default(_that.range,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoTextChange extends MonacoTextChange {
  const _MonacoTextChange({required this.range, required this.text}): super._();
  

/// The range of text that was replaced.
@override final  Range range;
/// The new text that was inserted. An empty string means a deletion.
@override final  String text;

/// Create a copy of MonacoTextChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoTextChangeCopyWith<_MonacoTextChange> get copyWith => __$MonacoTextChangeCopyWithImpl<_MonacoTextChange>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoTextChange&&(identical(other.range, range) || other.range == range)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,range,text);
}

@override
String toString() {
    return 'MonacoTextChange(range: $range, text: $text)';
}


}

/// @nodoc
abstract mixin class _$MonacoTextChangeCopyWith<$Res> implements $MonacoTextChangeCopyWith<$Res> {
  factory _$MonacoTextChangeCopyWith(_MonacoTextChange value, $Res Function(_MonacoTextChange) _then) = __$MonacoTextChangeCopyWithImpl;
@override @useResult
$Res call({
 Range range, String text
});


@override $RangeCopyWith<$Res> get range;

}
/// @nodoc
class __$MonacoTextChangeCopyWithImpl<$Res>
    implements _$MonacoTextChangeCopyWith<$Res> {
  __$MonacoTextChangeCopyWithImpl(this._self, this._then);

  final _MonacoTextChange _self;
  final $Res Function(_MonacoTextChange) _then;

/// Create a copy of MonacoTextChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? text = null,}) {
  return _then(_MonacoTextChange(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of MonacoTextChange
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
mixin _$FindMatch {

/// The range of the matched text.
 Range get range;/// The text that was matched.
 String? get match;
/// Create a copy of FindMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FindMatchCopyWith<FindMatch> get copyWith => _$FindMatchCopyWithImpl<FindMatch>(this as FindMatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FindMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FindMatch&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.match, _this.match) || other.match == _this.match));
}


@override
int get hashCode {
  final _this = this as FindMatch;
  return Object.hash(runtimeType,_this.range,_this.match);
}

@override
String toString() {
  final _this = this as FindMatch;
  return 'FindMatch(range: ${_this.range}, match: ${_this.match})';
}


}

/// @nodoc
abstract mixin class $FindMatchCopyWith<$Res>  {
  factory $FindMatchCopyWith(FindMatch value, $Res Function(FindMatch) _then) = _$FindMatchCopyWithImpl;
@useResult
$Res call({
 Range range, String? match
});


$RangeCopyWith<$Res> get range;

}
/// @nodoc
class _$FindMatchCopyWithImpl<$Res>
    implements $FindMatchCopyWith<$Res> {
  _$FindMatchCopyWithImpl(this._self, this._then);

  final FindMatch _self;
  final $Res Function(FindMatch) _then;

/// Create a copy of FindMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? match = freezed,}) {
  return _then(FindMatch(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,match: freezed == match ? _self.match : match // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of FindMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get range {
  
  return $RangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [FindMatch].
extension FindMatchPatterns on FindMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FindMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FindMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FindMatch value)  $default,){
final _that = this;
switch (_that) {
case _FindMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FindMatch value)?  $default,){
final _that = this;
switch (_that) {
case _FindMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Range range,  String? match)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FindMatch() when $default != null:
return $default(_that.range,_that.match);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Range range,  String? match)  $default,) {final _that = this;
switch (_that) {
case _FindMatch():
return $default(_that.range,_that.match);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Range range,  String? match)?  $default,) {final _that = this;
switch (_that) {
case _FindMatch() when $default != null:
return $default(_that.range,_that.match);case _:
  return null;

}
}

}

/// @nodoc


class _FindMatch extends FindMatch {
  const _FindMatch({required this.range, this.match}): super._();
  

/// The range of the matched text.
@override final  Range range;
/// The text that was matched.
@override final  String? match;

/// Create a copy of FindMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FindMatchCopyWith<_FindMatch> get copyWith => __$FindMatchCopyWithImpl<_FindMatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FindMatch&&(identical(other.range, range) || other.range == range)&&(identical(other.match, match) || other.match == match));
}


@override
int get hashCode {
    return Object.hash(runtimeType,range,match);
}

@override
String toString() {
    return 'FindMatch(range: $range, match: $match)';
}


}

/// @nodoc
abstract mixin class _$FindMatchCopyWith<$Res> implements $FindMatchCopyWith<$Res> {
  factory _$FindMatchCopyWith(_FindMatch value, $Res Function(_FindMatch) _then) = __$FindMatchCopyWithImpl;
@override @useResult
$Res call({
 Range range, String? match
});


@override $RangeCopyWith<$Res> get range;

}
/// @nodoc
class __$FindMatchCopyWithImpl<$Res>
    implements _$FindMatchCopyWith<$Res> {
  __$FindMatchCopyWithImpl(this._self, this._then);

  final _FindMatch _self;
  final $Res Function(_FindMatch) _then;

/// Create a copy of FindMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? match = freezed,}) {
  return _then(_FindMatch(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range,match: freezed == match ? _self.match : match // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FindMatch
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
mixin _$FindOptions {

/// If `true`, treats the search query as a regular expression.
 bool get isRegex;/// If `true`, performs a case-sensitive search.
 bool get matchCase;/// If `true`, only matches whole words.
 bool get wholeWord;/// If `true`, searches only within the editable range of the document.
 bool? get searchOnlyEditableRange;/// The maximum number of matches to find.
 int? get limitResultCount;
/// Create a copy of FindOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FindOptionsCopyWith<FindOptions> get copyWith => _$FindOptionsCopyWithImpl<FindOptions>(this as FindOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FindOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FindOptions&&(identical(other.isRegex, _this.isRegex) || other.isRegex == _this.isRegex)&&(identical(other.matchCase, _this.matchCase) || other.matchCase == _this.matchCase)&&(identical(other.wholeWord, _this.wholeWord) || other.wholeWord == _this.wholeWord)&&(identical(other.searchOnlyEditableRange, _this.searchOnlyEditableRange) || other.searchOnlyEditableRange == _this.searchOnlyEditableRange)&&(identical(other.limitResultCount, _this.limitResultCount) || other.limitResultCount == _this.limitResultCount));
}


@override
int get hashCode {
  final _this = this as FindOptions;
  return Object.hash(runtimeType,_this.isRegex,_this.matchCase,_this.wholeWord,_this.searchOnlyEditableRange,_this.limitResultCount);
}

@override
String toString() {
  final _this = this as FindOptions;
  return 'FindOptions(isRegex: ${_this.isRegex}, matchCase: ${_this.matchCase}, wholeWord: ${_this.wholeWord}, searchOnlyEditableRange: ${_this.searchOnlyEditableRange}, limitResultCount: ${_this.limitResultCount})';
}


}

/// @nodoc
abstract mixin class $FindOptionsCopyWith<$Res>  {
  factory $FindOptionsCopyWith(FindOptions value, $Res Function(FindOptions) _then) = _$FindOptionsCopyWithImpl;
@useResult
$Res call({
 bool isRegex, bool matchCase, bool wholeWord, bool? searchOnlyEditableRange, int? limitResultCount
});




}
/// @nodoc
class _$FindOptionsCopyWithImpl<$Res>
    implements $FindOptionsCopyWith<$Res> {
  _$FindOptionsCopyWithImpl(this._self, this._then);

  final FindOptions _self;
  final $Res Function(FindOptions) _then;

/// Create a copy of FindOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isRegex = null,Object? matchCase = null,Object? wholeWord = null,Object? searchOnlyEditableRange = freezed,Object? limitResultCount = freezed,}) {
  return _then(FindOptions(
isRegex: null == isRegex ? _self.isRegex : isRegex // ignore: cast_nullable_to_non_nullable
as bool,matchCase: null == matchCase ? _self.matchCase : matchCase // ignore: cast_nullable_to_non_nullable
as bool,wholeWord: null == wholeWord ? _self.wholeWord : wholeWord // ignore: cast_nullable_to_non_nullable
as bool,searchOnlyEditableRange: freezed == searchOnlyEditableRange ? _self.searchOnlyEditableRange : searchOnlyEditableRange // ignore: cast_nullable_to_non_nullable
as bool?,limitResultCount: freezed == limitResultCount ? _self.limitResultCount : limitResultCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FindOptions].
extension FindOptionsPatterns on FindOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FindOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FindOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FindOptions value)  $default,){
final _that = this;
switch (_that) {
case _FindOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FindOptions value)?  $default,){
final _that = this;
switch (_that) {
case _FindOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isRegex,  bool matchCase,  bool wholeWord,  bool? searchOnlyEditableRange,  int? limitResultCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FindOptions() when $default != null:
return $default(_that.isRegex,_that.matchCase,_that.wholeWord,_that.searchOnlyEditableRange,_that.limitResultCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isRegex,  bool matchCase,  bool wholeWord,  bool? searchOnlyEditableRange,  int? limitResultCount)  $default,) {final _that = this;
switch (_that) {
case _FindOptions():
return $default(_that.isRegex,_that.matchCase,_that.wholeWord,_that.searchOnlyEditableRange,_that.limitResultCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isRegex,  bool matchCase,  bool wholeWord,  bool? searchOnlyEditableRange,  int? limitResultCount)?  $default,) {final _that = this;
switch (_that) {
case _FindOptions() when $default != null:
return $default(_that.isRegex,_that.matchCase,_that.wholeWord,_that.searchOnlyEditableRange,_that.limitResultCount);case _:
  return null;

}
}

}

/// @nodoc


class _FindOptions extends FindOptions {
  const _FindOptions({this.isRegex = false, this.matchCase = false, this.wholeWord = false, this.searchOnlyEditableRange, this.limitResultCount}): super._();
  

/// If `true`, treats the search query as a regular expression.
@override@JsonKey() final  bool isRegex;
/// If `true`, performs a case-sensitive search.
@override@JsonKey() final  bool matchCase;
/// If `true`, only matches whole words.
@override@JsonKey() final  bool wholeWord;
/// If `true`, searches only within the editable range of the document.
@override final  bool? searchOnlyEditableRange;
/// The maximum number of matches to find.
@override final  int? limitResultCount;

/// Create a copy of FindOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FindOptionsCopyWith<_FindOptions> get copyWith => __$FindOptionsCopyWithImpl<_FindOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FindOptions&&(identical(other.isRegex, isRegex) || other.isRegex == isRegex)&&(identical(other.matchCase, matchCase) || other.matchCase == matchCase)&&(identical(other.wholeWord, wholeWord) || other.wholeWord == wholeWord)&&(identical(other.searchOnlyEditableRange, searchOnlyEditableRange) || other.searchOnlyEditableRange == searchOnlyEditableRange)&&(identical(other.limitResultCount, limitResultCount) || other.limitResultCount == limitResultCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isRegex,matchCase,wholeWord,searchOnlyEditableRange,limitResultCount);
}

@override
String toString() {
    return 'FindOptions(isRegex: $isRegex, matchCase: $matchCase, wholeWord: $wholeWord, searchOnlyEditableRange: $searchOnlyEditableRange, limitResultCount: $limitResultCount)';
}


}

/// @nodoc
abstract mixin class _$FindOptionsCopyWith<$Res> implements $FindOptionsCopyWith<$Res> {
  factory _$FindOptionsCopyWith(_FindOptions value, $Res Function(_FindOptions) _then) = __$FindOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool isRegex, bool matchCase, bool wholeWord, bool? searchOnlyEditableRange, int? limitResultCount
});




}
/// @nodoc
class __$FindOptionsCopyWithImpl<$Res>
    implements _$FindOptionsCopyWith<$Res> {
  __$FindOptionsCopyWithImpl(this._self, this._then);

  final _FindOptions _self;
  final $Res Function(_FindOptions) _then;

/// Create a copy of FindOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isRegex = null,Object? matchCase = null,Object? wholeWord = null,Object? searchOnlyEditableRange = freezed,Object? limitResultCount = freezed,}) {
  return _then(_FindOptions(
isRegex: null == isRegex ? _self.isRegex : isRegex // ignore: cast_nullable_to_non_nullable
as bool,matchCase: null == matchCase ? _self.matchCase : matchCase // ignore: cast_nullable_to_non_nullable
as bool,wholeWord: null == wholeWord ? _self.wholeWord : wholeWord // ignore: cast_nullable_to_non_nullable
as bool,searchOnlyEditableRange: freezed == searchOnlyEditableRange ? _self.searchOnlyEditableRange : searchOnlyEditableRange // ignore: cast_nullable_to_non_nullable
as bool?,limitResultCount: freezed == limitResultCount ? _self.limitResultCount : limitResultCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
