// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MonacoLiveStats {

/// Total number of lines in the document.
 int get lineCount;/// Total number of characters in the document.
 int get charCount;/// Number of lines covered by the primary selection (0 when empty).
 int get selectedLines;/// Number of characters in the primary selection (0 when empty).
 int get selectedCharacters;/// Number of active cursors (1 unless multi-cursor editing).
 int get caretCount;/// Primary cursor position, when known.
 Position? get cursorPosition;/// Active document language, when known.
 MonacoLanguage? get language;
/// Create a copy of MonacoLiveStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonacoLiveStatsCopyWith<MonacoLiveStats> get copyWith => _$MonacoLiveStatsCopyWithImpl<MonacoLiveStats>(this as MonacoLiveStats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonacoLiveStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonacoLiveStats&&(identical(other.lineCount, _this.lineCount) || other.lineCount == _this.lineCount)&&(identical(other.charCount, _this.charCount) || other.charCount == _this.charCount)&&(identical(other.selectedLines, _this.selectedLines) || other.selectedLines == _this.selectedLines)&&(identical(other.selectedCharacters, _this.selectedCharacters) || other.selectedCharacters == _this.selectedCharacters)&&(identical(other.caretCount, _this.caretCount) || other.caretCount == _this.caretCount)&&(identical(other.cursorPosition, _this.cursorPosition) || other.cursorPosition == _this.cursorPosition)&&(identical(other.language, _this.language) || other.language == _this.language));
}


@override
int get hashCode {
  final _this = this as MonacoLiveStats;
  return Object.hash(runtimeType,_this.lineCount,_this.charCount,_this.selectedLines,_this.selectedCharacters,_this.caretCount,_this.cursorPosition,_this.language);
}

@override
String toString() {
  final _this = this as MonacoLiveStats;
  return 'MonacoLiveStats(lineCount: ${_this.lineCount}, charCount: ${_this.charCount}, selectedLines: ${_this.selectedLines}, selectedCharacters: ${_this.selectedCharacters}, caretCount: ${_this.caretCount}, cursorPosition: ${_this.cursorPosition}, language: ${_this.language})';
}


}

/// @nodoc
abstract mixin class $MonacoLiveStatsCopyWith<$Res>  {
  factory $MonacoLiveStatsCopyWith(MonacoLiveStats value, $Res Function(MonacoLiveStats) _then) = _$MonacoLiveStatsCopyWithImpl;
@useResult
$Res call({
 int lineCount, int charCount, int selectedLines, int selectedCharacters, int caretCount, Position? cursorPosition, MonacoLanguage? language
});


$PositionCopyWith<$Res>? get cursorPosition;

}
/// @nodoc
class _$MonacoLiveStatsCopyWithImpl<$Res>
    implements $MonacoLiveStatsCopyWith<$Res> {
  _$MonacoLiveStatsCopyWithImpl(this._self, this._then);

  final MonacoLiveStats _self;
  final $Res Function(MonacoLiveStats) _then;

/// Create a copy of MonacoLiveStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lineCount = null,Object? charCount = null,Object? selectedLines = null,Object? selectedCharacters = null,Object? caretCount = null,Object? cursorPosition = freezed,Object? language = freezed,}) {
  return _then(MonacoLiveStats(
lineCount: null == lineCount ? _self.lineCount : lineCount // ignore: cast_nullable_to_non_nullable
as int,charCount: null == charCount ? _self.charCount : charCount // ignore: cast_nullable_to_non_nullable
as int,selectedLines: null == selectedLines ? _self.selectedLines : selectedLines // ignore: cast_nullable_to_non_nullable
as int,selectedCharacters: null == selectedCharacters ? _self.selectedCharacters : selectedCharacters // ignore: cast_nullable_to_non_nullable
as int,caretCount: null == caretCount ? _self.caretCount : caretCount // ignore: cast_nullable_to_non_nullable
as int,cursorPosition: freezed == cursorPosition ? _self.cursorPosition : cursorPosition // ignore: cast_nullable_to_non_nullable
as Position?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as MonacoLanguage?,
  ));
}
/// Create a copy of MonacoLiveStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PositionCopyWith<$Res>? get cursorPosition {
    if (_self.cursorPosition == null) {
    return null;
  }

  return $PositionCopyWith<$Res>(_self.cursorPosition!, (value) {
    return _then(_self.copyWith(cursorPosition: value));
  });
}
}


/// Adds pattern-matching-related methods to [MonacoLiveStats].
extension MonacoLiveStatsPatterns on MonacoLiveStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonacoLiveStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonacoLiveStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonacoLiveStats value)  $default,){
final _that = this;
switch (_that) {
case _MonacoLiveStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonacoLiveStats value)?  $default,){
final _that = this;
switch (_that) {
case _MonacoLiveStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int lineCount,  int charCount,  int selectedLines,  int selectedCharacters,  int caretCount,  Position? cursorPosition,  MonacoLanguage? language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonacoLiveStats() when $default != null:
return $default(_that.lineCount,_that.charCount,_that.selectedLines,_that.selectedCharacters,_that.caretCount,_that.cursorPosition,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int lineCount,  int charCount,  int selectedLines,  int selectedCharacters,  int caretCount,  Position? cursorPosition,  MonacoLanguage? language)  $default,) {final _that = this;
switch (_that) {
case _MonacoLiveStats():
return $default(_that.lineCount,_that.charCount,_that.selectedLines,_that.selectedCharacters,_that.caretCount,_that.cursorPosition,_that.language);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int lineCount,  int charCount,  int selectedLines,  int selectedCharacters,  int caretCount,  Position? cursorPosition,  MonacoLanguage? language)?  $default,) {final _that = this;
switch (_that) {
case _MonacoLiveStats() when $default != null:
return $default(_that.lineCount,_that.charCount,_that.selectedLines,_that.selectedCharacters,_that.caretCount,_that.cursorPosition,_that.language);case _:
  return null;

}
}

}

/// @nodoc


class _MonacoLiveStats extends MonacoLiveStats {
  const _MonacoLiveStats({this.lineCount = 0, this.charCount = 0, this.selectedLines = 0, this.selectedCharacters = 0, this.caretCount = 1, this.cursorPosition, this.language}): super._();
  

/// Total number of lines in the document.
@override@JsonKey() final  int lineCount;
/// Total number of characters in the document.
@override@JsonKey() final  int charCount;
/// Number of lines covered by the primary selection (0 when empty).
@override@JsonKey() final  int selectedLines;
/// Number of characters in the primary selection (0 when empty).
@override@JsonKey() final  int selectedCharacters;
/// Number of active cursors (1 unless multi-cursor editing).
@override@JsonKey() final  int caretCount;
/// Primary cursor position, when known.
@override final  Position? cursorPosition;
/// Active document language, when known.
@override final  MonacoLanguage? language;

/// Create a copy of MonacoLiveStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonacoLiveStatsCopyWith<_MonacoLiveStats> get copyWith => __$MonacoLiveStatsCopyWithImpl<_MonacoLiveStats>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonacoLiveStats&&(identical(other.lineCount, lineCount) || other.lineCount == lineCount)&&(identical(other.charCount, charCount) || other.charCount == charCount)&&(identical(other.selectedLines, selectedLines) || other.selectedLines == selectedLines)&&(identical(other.selectedCharacters, selectedCharacters) || other.selectedCharacters == selectedCharacters)&&(identical(other.caretCount, caretCount) || other.caretCount == caretCount)&&(identical(other.cursorPosition, cursorPosition) || other.cursorPosition == cursorPosition)&&(identical(other.language, language) || other.language == language));
}


@override
int get hashCode {
    return Object.hash(runtimeType,lineCount,charCount,selectedLines,selectedCharacters,caretCount,cursorPosition,language);
}

@override
String toString() {
    return 'MonacoLiveStats(lineCount: $lineCount, charCount: $charCount, selectedLines: $selectedLines, selectedCharacters: $selectedCharacters, caretCount: $caretCount, cursorPosition: $cursorPosition, language: $language)';
}


}

/// @nodoc
abstract mixin class _$MonacoLiveStatsCopyWith<$Res> implements $MonacoLiveStatsCopyWith<$Res> {
  factory _$MonacoLiveStatsCopyWith(_MonacoLiveStats value, $Res Function(_MonacoLiveStats) _then) = __$MonacoLiveStatsCopyWithImpl;
@override @useResult
$Res call({
 int lineCount, int charCount, int selectedLines, int selectedCharacters, int caretCount, Position? cursorPosition, MonacoLanguage? language
});


@override $PositionCopyWith<$Res>? get cursorPosition;

}
/// @nodoc
class __$MonacoLiveStatsCopyWithImpl<$Res>
    implements _$MonacoLiveStatsCopyWith<$Res> {
  __$MonacoLiveStatsCopyWithImpl(this._self, this._then);

  final _MonacoLiveStats _self;
  final $Res Function(_MonacoLiveStats) _then;

/// Create a copy of MonacoLiveStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lineCount = null,Object? charCount = null,Object? selectedLines = null,Object? selectedCharacters = null,Object? caretCount = null,Object? cursorPosition = freezed,Object? language = freezed,}) {
  return _then(_MonacoLiveStats(
lineCount: null == lineCount ? _self.lineCount : lineCount // ignore: cast_nullable_to_non_nullable
as int,charCount: null == charCount ? _self.charCount : charCount // ignore: cast_nullable_to_non_nullable
as int,selectedLines: null == selectedLines ? _self.selectedLines : selectedLines // ignore: cast_nullable_to_non_nullable
as int,selectedCharacters: null == selectedCharacters ? _self.selectedCharacters : selectedCharacters // ignore: cast_nullable_to_non_nullable
as int,caretCount: null == caretCount ? _self.caretCount : caretCount // ignore: cast_nullable_to_non_nullable
as int,cursorPosition: freezed == cursorPosition ? _self.cursorPosition : cursorPosition // ignore: cast_nullable_to_non_nullable
as Position?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as MonacoLanguage?,
  ));
}

/// Create a copy of MonacoLiveStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PositionCopyWith<$Res>? get cursorPosition {
    if (_self.cursorPosition == null) {
    return null;
  }

  return $PositionCopyWith<$Res>(_self.cursorPosition!, (value) {
    return _then(_self.copyWith(cursorPosition: value));
  });
}
}

/// @nodoc
mixin _$EditorState {

/// Full document text.
 String get content;/// Primary selection, when one exists.
 Range? get selection;/// Primary cursor position, when known.
 Position? get cursorPosition;/// Total number of lines.
 int get lineCount;/// Whether the document changed since the last `markSaved`.
 bool get isDirty;/// Active document language, when known.
 MonacoLanguage? get language;/// Active theme, when known.
 MonacoTheme? get theme;/// Live statistics at snapshot time.
 MonacoLiveStats get stats;
/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorStateCopyWith<EditorState> get copyWith => _$EditorStateCopyWithImpl<EditorState>(this as EditorState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorState&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.selection, _this.selection) || other.selection == _this.selection)&&(identical(other.cursorPosition, _this.cursorPosition) || other.cursorPosition == _this.cursorPosition)&&(identical(other.lineCount, _this.lineCount) || other.lineCount == _this.lineCount)&&(identical(other.isDirty, _this.isDirty) || other.isDirty == _this.isDirty)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.stats, _this.stats) || other.stats == _this.stats));
}


@override
int get hashCode {
  final _this = this as EditorState;
  return Object.hash(runtimeType,_this.content,_this.selection,_this.cursorPosition,_this.lineCount,_this.isDirty,_this.language,_this.theme,_this.stats);
}

@override
String toString() {
  final _this = this as EditorState;
  return 'EditorState(content: ${_this.content}, selection: ${_this.selection}, cursorPosition: ${_this.cursorPosition}, lineCount: ${_this.lineCount}, isDirty: ${_this.isDirty}, language: ${_this.language}, theme: ${_this.theme}, stats: ${_this.stats})';
}


}

/// @nodoc
abstract mixin class $EditorStateCopyWith<$Res>  {
  factory $EditorStateCopyWith(EditorState value, $Res Function(EditorState) _then) = _$EditorStateCopyWithImpl;
@useResult
$Res call({
 String content, Range? selection, Position? cursorPosition, int lineCount, bool isDirty, MonacoLanguage? language, MonacoTheme? theme, MonacoLiveStats stats
});


$RangeCopyWith<$Res>? get selection;$PositionCopyWith<$Res>? get cursorPosition;$MonacoLiveStatsCopyWith<$Res> get stats;

}
/// @nodoc
class _$EditorStateCopyWithImpl<$Res>
    implements $EditorStateCopyWith<$Res> {
  _$EditorStateCopyWithImpl(this._self, this._then);

  final EditorState _self;
  final $Res Function(EditorState) _then;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? selection = freezed,Object? cursorPosition = freezed,Object? lineCount = null,Object? isDirty = null,Object? language = freezed,Object? theme = freezed,Object? stats = null,}) {
  return _then(EditorState(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,selection: freezed == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as Range?,cursorPosition: freezed == cursorPosition ? _self.cursorPosition : cursorPosition // ignore: cast_nullable_to_non_nullable
as Position?,lineCount: null == lineCount ? _self.lineCount : lineCount // ignore: cast_nullable_to_non_nullable
as int,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as MonacoLanguage?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as MonacoTheme?,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as MonacoLiveStats,
  ));
}
/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res>? get selection {
    if (_self.selection == null) {
    return null;
  }

  return $RangeCopyWith<$Res>(_self.selection!, (value) {
    return _then(_self.copyWith(selection: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PositionCopyWith<$Res>? get cursorPosition {
    if (_self.cursorPosition == null) {
    return null;
  }

  return $PositionCopyWith<$Res>(_self.cursorPosition!, (value) {
    return _then(_self.copyWith(cursorPosition: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoLiveStatsCopyWith<$Res> get stats {
  
  return $MonacoLiveStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorState].
extension EditorStatePatterns on EditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorState value)  $default,){
final _that = this;
switch (_that) {
case _EditorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorState value)?  $default,){
final _that = this;
switch (_that) {
case _EditorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  Range? selection,  Position? cursorPosition,  int lineCount,  bool isDirty,  MonacoLanguage? language,  MonacoTheme? theme,  MonacoLiveStats stats)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorState() when $default != null:
return $default(_that.content,_that.selection,_that.cursorPosition,_that.lineCount,_that.isDirty,_that.language,_that.theme,_that.stats);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  Range? selection,  Position? cursorPosition,  int lineCount,  bool isDirty,  MonacoLanguage? language,  MonacoTheme? theme,  MonacoLiveStats stats)  $default,) {final _that = this;
switch (_that) {
case _EditorState():
return $default(_that.content,_that.selection,_that.cursorPosition,_that.lineCount,_that.isDirty,_that.language,_that.theme,_that.stats);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  Range? selection,  Position? cursorPosition,  int lineCount,  bool isDirty,  MonacoLanguage? language,  MonacoTheme? theme,  MonacoLiveStats stats)?  $default,) {final _that = this;
switch (_that) {
case _EditorState() when $default != null:
return $default(_that.content,_that.selection,_that.cursorPosition,_that.lineCount,_that.isDirty,_that.language,_that.theme,_that.stats);case _:
  return null;

}
}

}

/// @nodoc


class _EditorState extends EditorState {
  const _EditorState({required this.content, this.selection, this.cursorPosition, this.lineCount = 0, this.isDirty = false, this.language, this.theme, this.stats = const MonacoLiveStats()}): super._();
  

/// Full document text.
@override final  String content;
/// Primary selection, when one exists.
@override final  Range? selection;
/// Primary cursor position, when known.
@override final  Position? cursorPosition;
/// Total number of lines.
@override@JsonKey() final  int lineCount;
/// Whether the document changed since the last `markSaved`.
@override@JsonKey() final  bool isDirty;
/// Active document language, when known.
@override final  MonacoLanguage? language;
/// Active theme, when known.
@override final  MonacoTheme? theme;
/// Live statistics at snapshot time.
@override@JsonKey() final  MonacoLiveStats stats;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorStateCopyWith<_EditorState> get copyWith => __$EditorStateCopyWithImpl<_EditorState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorState&&(identical(other.content, content) || other.content == content)&&(identical(other.selection, selection) || other.selection == selection)&&(identical(other.cursorPosition, cursorPosition) || other.cursorPosition == cursorPosition)&&(identical(other.lineCount, lineCount) || other.lineCount == lineCount)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty)&&(identical(other.language, language) || other.language == language)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.stats, stats) || other.stats == stats));
}


@override
int get hashCode {
    return Object.hash(runtimeType,content,selection,cursorPosition,lineCount,isDirty,language,theme,stats);
}

@override
String toString() {
    return 'EditorState(content: $content, selection: $selection, cursorPosition: $cursorPosition, lineCount: $lineCount, isDirty: $isDirty, language: $language, theme: $theme, stats: $stats)';
}


}

/// @nodoc
abstract mixin class _$EditorStateCopyWith<$Res> implements $EditorStateCopyWith<$Res> {
  factory _$EditorStateCopyWith(_EditorState value, $Res Function(_EditorState) _then) = __$EditorStateCopyWithImpl;
@override @useResult
$Res call({
 String content, Range? selection, Position? cursorPosition, int lineCount, bool isDirty, MonacoLanguage? language, MonacoTheme? theme, MonacoLiveStats stats
});


@override $RangeCopyWith<$Res>? get selection;@override $PositionCopyWith<$Res>? get cursorPosition;@override $MonacoLiveStatsCopyWith<$Res> get stats;

}
/// @nodoc
class __$EditorStateCopyWithImpl<$Res>
    implements _$EditorStateCopyWith<$Res> {
  __$EditorStateCopyWithImpl(this._self, this._then);

  final _EditorState _self;
  final $Res Function(_EditorState) _then;

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? selection = freezed,Object? cursorPosition = freezed,Object? lineCount = null,Object? isDirty = null,Object? language = freezed,Object? theme = freezed,Object? stats = null,}) {
  return _then(_EditorState(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,selection: freezed == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as Range?,cursorPosition: freezed == cursorPosition ? _self.cursorPosition : cursorPosition // ignore: cast_nullable_to_non_nullable
as Position?,lineCount: null == lineCount ? _self.lineCount : lineCount // ignore: cast_nullable_to_non_nullable
as int,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as MonacoLanguage?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as MonacoTheme?,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as MonacoLiveStats,
  ));
}

/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res>? get selection {
    if (_self.selection == null) {
    return null;
  }

  return $RangeCopyWith<$Res>(_self.selection!, (value) {
    return _then(_self.copyWith(selection: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PositionCopyWith<$Res>? get cursorPosition {
    if (_self.cursorPosition == null) {
    return null;
  }

  return $PositionCopyWith<$Res>(_self.cursorPosition!, (value) {
    return _then(_self.copyWith(cursorPosition: value));
  });
}/// Create a copy of EditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonacoLiveStatsCopyWith<$Res> get stats {
  
  return $MonacoLiveStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}

// dart format on
