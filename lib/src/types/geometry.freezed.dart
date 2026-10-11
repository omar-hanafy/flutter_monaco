// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geometry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Position {

/// The 1-based line number.
 int get line;/// The 1-based column number.
 int get column;
/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionCopyWith<Position> get copyWith => _$PositionCopyWithImpl<Position>(this as Position, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Position;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Position&&(identical(other.line, _this.line) || other.line == _this.line)&&(identical(other.column, _this.column) || other.column == _this.column));
}


@override
int get hashCode {
  final _this = this as Position;
  return Object.hash(runtimeType,_this.line,_this.column);
}

@override
String toString() {
  final _this = this as Position;
  return 'Position(line: ${_this.line}, column: ${_this.column})';
}


}

/// @nodoc
abstract mixin class $PositionCopyWith<$Res>  {
  factory $PositionCopyWith(Position value, $Res Function(Position) _then) = _$PositionCopyWithImpl;
@useResult
$Res call({
 int line, int column
});




}
/// @nodoc
class _$PositionCopyWithImpl<$Res>
    implements $PositionCopyWith<$Res> {
  _$PositionCopyWithImpl(this._self, this._then);

  final Position _self;
  final $Res Function(Position) _then;

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? line = null,Object? column = null,}) {
  return _then(Position(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Position].
extension PositionPatterns on Position {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Position value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Position() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Position value)  $default,){
final _that = this;
switch (_that) {
case _Position():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Position value)?  $default,){
final _that = this;
switch (_that) {
case _Position() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int line,  int column)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Position() when $default != null:
return $default(_that.line,_that.column);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int line,  int column)  $default,) {final _that = this;
switch (_that) {
case _Position():
return $default(_that.line,_that.column);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int line,  int column)?  $default,) {final _that = this;
switch (_that) {
case _Position() when $default != null:
return $default(_that.line,_that.column);case _:
  return null;

}
}

}

/// @nodoc


class _Position extends Position {
  const _Position({required this.line, required this.column}): super._();
  

/// The 1-based line number.
@override final  int line;
/// The 1-based column number.
@override final  int column;

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionCopyWith<_Position> get copyWith => __$PositionCopyWithImpl<_Position>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Position&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column));
}


@override
int get hashCode {
    return Object.hash(runtimeType,line,column);
}

@override
String toString() {
    return 'Position(line: $line, column: $column)';
}


}

/// @nodoc
abstract mixin class _$PositionCopyWith<$Res> implements $PositionCopyWith<$Res> {
  factory _$PositionCopyWith(_Position value, $Res Function(_Position) _then) = __$PositionCopyWithImpl;
@override @useResult
$Res call({
 int line, int column
});




}
/// @nodoc
class __$PositionCopyWithImpl<$Res>
    implements _$PositionCopyWith<$Res> {
  __$PositionCopyWithImpl(this._self, this._then);

  final _Position _self;
  final $Res Function(_Position) _then;

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? line = null,Object? column = null,}) {
  return _then(_Position(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Range {

/// The 1-based line number where the range starts.
 int get startLine;/// The 1-based column number where the range starts.
 int get startColumn;/// The 1-based line number where the range ends.
 int get endLine;/// The 1-based column number where the range ends.
 int get endColumn;
/// Create a copy of Range
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RangeCopyWith<Range> get copyWith => _$RangeCopyWithImpl<Range>(this as Range, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Range;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Range&&(identical(other.startLine, _this.startLine) || other.startLine == _this.startLine)&&(identical(other.startColumn, _this.startColumn) || other.startColumn == _this.startColumn)&&(identical(other.endLine, _this.endLine) || other.endLine == _this.endLine)&&(identical(other.endColumn, _this.endColumn) || other.endColumn == _this.endColumn));
}


@override
int get hashCode {
  final _this = this as Range;
  return Object.hash(runtimeType,_this.startLine,_this.startColumn,_this.endLine,_this.endColumn);
}

@override
String toString() {
  final _this = this as Range;
  return 'Range(startLine: ${_this.startLine}, startColumn: ${_this.startColumn}, endLine: ${_this.endLine}, endColumn: ${_this.endColumn})';
}


}

/// @nodoc
abstract mixin class $RangeCopyWith<$Res>  {
  factory $RangeCopyWith(Range value, $Res Function(Range) _then) = _$RangeCopyWithImpl;
@useResult
$Res call({
 int startLine, int startColumn, int endLine, int endColumn
});




}
/// @nodoc
class _$RangeCopyWithImpl<$Res>
    implements $RangeCopyWith<$Res> {
  _$RangeCopyWithImpl(this._self, this._then);

  final Range _self;
  final $Res Function(Range) _then;

/// Create a copy of Range
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startLine = null,Object? startColumn = null,Object? endLine = null,Object? endColumn = null,}) {
  return _then(Range(
startLine: null == startLine ? _self.startLine : startLine // ignore: cast_nullable_to_non_nullable
as int,startColumn: null == startColumn ? _self.startColumn : startColumn // ignore: cast_nullable_to_non_nullable
as int,endLine: null == endLine ? _self.endLine : endLine // ignore: cast_nullable_to_non_nullable
as int,endColumn: null == endColumn ? _self.endColumn : endColumn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Range].
extension RangePatterns on Range {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Range value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Range() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Range value)  $default,){
final _that = this;
switch (_that) {
case _Range():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Range value)?  $default,){
final _that = this;
switch (_that) {
case _Range() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int startLine,  int startColumn,  int endLine,  int endColumn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Range() when $default != null:
return $default(_that.startLine,_that.startColumn,_that.endLine,_that.endColumn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int startLine,  int startColumn,  int endLine,  int endColumn)  $default,) {final _that = this;
switch (_that) {
case _Range():
return $default(_that.startLine,_that.startColumn,_that.endLine,_that.endColumn);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int startLine,  int startColumn,  int endLine,  int endColumn)?  $default,) {final _that = this;
switch (_that) {
case _Range() when $default != null:
return $default(_that.startLine,_that.startColumn,_that.endLine,_that.endColumn);case _:
  return null;

}
}

}

/// @nodoc


class _Range extends Range {
  const _Range({required this.startLine, required this.startColumn, required this.endLine, required this.endColumn}): super._();
  

/// The 1-based line number where the range starts.
@override final  int startLine;
/// The 1-based column number where the range starts.
@override final  int startColumn;
/// The 1-based line number where the range ends.
@override final  int endLine;
/// The 1-based column number where the range ends.
@override final  int endColumn;

/// Create a copy of Range
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RangeCopyWith<_Range> get copyWith => __$RangeCopyWithImpl<_Range>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Range&&(identical(other.startLine, startLine) || other.startLine == startLine)&&(identical(other.startColumn, startColumn) || other.startColumn == startColumn)&&(identical(other.endLine, endLine) || other.endLine == endLine)&&(identical(other.endColumn, endColumn) || other.endColumn == endColumn));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startLine,startColumn,endLine,endColumn);
}

@override
String toString() {
    return 'Range(startLine: $startLine, startColumn: $startColumn, endLine: $endLine, endColumn: $endColumn)';
}


}

/// @nodoc
abstract mixin class _$RangeCopyWith<$Res> implements $RangeCopyWith<$Res> {
  factory _$RangeCopyWith(_Range value, $Res Function(_Range) _then) = __$RangeCopyWithImpl;
@override @useResult
$Res call({
 int startLine, int startColumn, int endLine, int endColumn
});




}
/// @nodoc
class __$RangeCopyWithImpl<$Res>
    implements _$RangeCopyWith<$Res> {
  __$RangeCopyWithImpl(this._self, this._then);

  final _Range _self;
  final $Res Function(_Range) _then;

/// Create a copy of Range
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startLine = null,Object? startColumn = null,Object? endLine = null,Object? endColumn = null,}) {
  return _then(_Range(
startLine: null == startLine ? _self.startLine : startLine // ignore: cast_nullable_to_non_nullable
as int,startColumn: null == startColumn ? _self.startColumn : startColumn // ignore: cast_nullable_to_non_nullable
as int,endLine: null == endLine ? _self.endLine : endLine // ignore: cast_nullable_to_non_nullable
as int,endColumn: null == endColumn ? _self.endColumn : endColumn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
