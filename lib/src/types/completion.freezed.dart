// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'completion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompletionItem {

/// The label of this completion item.
 String get label;/// The text to be inserted into the document. If `null`, [label] is used.
 String? get insertText;/// The kind of this completion item (e.g., method, function).
 CompletionItemKind? get kind;/// A human-readable string with additional information about this item.
 String? get detail;/// A human-readable string that represents a doc-comment.
 String? get documentation;/// A string that should be used when comparing this item with other items.
 String? get sortText;/// A string that should be used when filtering a set of completion items.
 String? get filterText;/// The range of text to be replaced by this completion item.
 Range? get range;/// Characters that trigger the commit of this completion.
 List<String>? get commitCharacters;/// Rules that control how the [insertText] is formatted.
 Set<InsertTextRule>? get insertTextRules;
/// Create a copy of CompletionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletionItemCopyWith<CompletionItem> get copyWith => _$CompletionItemCopyWithImpl<CompletionItem>(this as CompletionItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CompletionItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletionItem&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.insertText, _this.insertText) || other.insertText == _this.insertText)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.documentation, _this.documentation) || other.documentation == _this.documentation)&&(identical(other.sortText, _this.sortText) || other.sortText == _this.sortText)&&(identical(other.filterText, _this.filterText) || other.filterText == _this.filterText)&&(identical(other.range, _this.range) || other.range == _this.range)&&const DeepCollectionEquality().equals(other.commitCharacters, _this.commitCharacters)&&const DeepCollectionEquality().equals(other.insertTextRules, _this.insertTextRules));
}


@override
int get hashCode {
  final _this = this as CompletionItem;
  return Object.hash(runtimeType,_this.label,_this.insertText,_this.kind,_this.detail,_this.documentation,_this.sortText,_this.filterText,_this.range,const DeepCollectionEquality().hash(_this.commitCharacters),const DeepCollectionEquality().hash(_this.insertTextRules));
}

@override
String toString() {
  final _this = this as CompletionItem;
  return 'CompletionItem(label: ${_this.label}, insertText: ${_this.insertText}, kind: ${_this.kind}, detail: ${_this.detail}, documentation: ${_this.documentation}, sortText: ${_this.sortText}, filterText: ${_this.filterText}, range: ${_this.range}, commitCharacters: ${_this.commitCharacters}, insertTextRules: ${_this.insertTextRules})';
}


}

/// @nodoc
abstract mixin class $CompletionItemCopyWith<$Res>  {
  factory $CompletionItemCopyWith(CompletionItem value, $Res Function(CompletionItem) _then) = _$CompletionItemCopyWithImpl;
@useResult
$Res call({
 String label, String? insertText, CompletionItemKind? kind, String? detail, String? documentation, String? sortText, String? filterText, Range? range, List<String>? commitCharacters, Set<InsertTextRule>? insertTextRules
});


$RangeCopyWith<$Res>? get range;

}
/// @nodoc
class _$CompletionItemCopyWithImpl<$Res>
    implements $CompletionItemCopyWith<$Res> {
  _$CompletionItemCopyWithImpl(this._self, this._then);

  final CompletionItem _self;
  final $Res Function(CompletionItem) _then;

/// Create a copy of CompletionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? insertText = freezed,Object? kind = freezed,Object? detail = freezed,Object? documentation = freezed,Object? sortText = freezed,Object? filterText = freezed,Object? range = freezed,Object? commitCharacters = freezed,Object? insertTextRules = freezed,}) {
  return _then(CompletionItem(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,insertText: freezed == insertText ? _self.insertText : insertText // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CompletionItemKind?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,documentation: freezed == documentation ? _self.documentation : documentation // ignore: cast_nullable_to_non_nullable
as String?,sortText: freezed == sortText ? _self.sortText : sortText // ignore: cast_nullable_to_non_nullable
as String?,filterText: freezed == filterText ? _self.filterText : filterText // ignore: cast_nullable_to_non_nullable
as String?,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range?,commitCharacters: freezed == commitCharacters ? _self.commitCharacters : commitCharacters // ignore: cast_nullable_to_non_nullable
as List<String>?,insertTextRules: freezed == insertTextRules ? _self.insertTextRules : insertTextRules // ignore: cast_nullable_to_non_nullable
as Set<InsertTextRule>?,
  ));
}
/// Create a copy of CompletionItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $RangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [CompletionItem].
extension CompletionItemPatterns on CompletionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompletionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompletionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompletionItem value)  $default,){
final _that = this;
switch (_that) {
case _CompletionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompletionItem value)?  $default,){
final _that = this;
switch (_that) {
case _CompletionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String? insertText,  CompletionItemKind? kind,  String? detail,  String? documentation,  String? sortText,  String? filterText,  Range? range,  List<String>? commitCharacters,  Set<InsertTextRule>? insertTextRules)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompletionItem() when $default != null:
return $default(_that.label,_that.insertText,_that.kind,_that.detail,_that.documentation,_that.sortText,_that.filterText,_that.range,_that.commitCharacters,_that.insertTextRules);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String? insertText,  CompletionItemKind? kind,  String? detail,  String? documentation,  String? sortText,  String? filterText,  Range? range,  List<String>? commitCharacters,  Set<InsertTextRule>? insertTextRules)  $default,) {final _that = this;
switch (_that) {
case _CompletionItem():
return $default(_that.label,_that.insertText,_that.kind,_that.detail,_that.documentation,_that.sortText,_that.filterText,_that.range,_that.commitCharacters,_that.insertTextRules);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String? insertText,  CompletionItemKind? kind,  String? detail,  String? documentation,  String? sortText,  String? filterText,  Range? range,  List<String>? commitCharacters,  Set<InsertTextRule>? insertTextRules)?  $default,) {final _that = this;
switch (_that) {
case _CompletionItem() when $default != null:
return $default(_that.label,_that.insertText,_that.kind,_that.detail,_that.documentation,_that.sortText,_that.filterText,_that.range,_that.commitCharacters,_that.insertTextRules);case _:
  return null;

}
}

}

/// @nodoc


class _CompletionItem extends CompletionItem {
  const _CompletionItem({required this.label, this.insertText, this.kind, this.detail, this.documentation, this.sortText, this.filterText, this.range,  List<String>? commitCharacters,  Set<InsertTextRule>? insertTextRules}): _commitCharacters = commitCharacters,_insertTextRules = insertTextRules,super._();
  

/// The label of this completion item.
@override final  String label;
/// The text to be inserted into the document. If `null`, [label] is used.
@override final  String? insertText;
/// The kind of this completion item (e.g., method, function).
@override final  CompletionItemKind? kind;
/// A human-readable string with additional information about this item.
@override final  String? detail;
/// A human-readable string that represents a doc-comment.
@override final  String? documentation;
/// A string that should be used when comparing this item with other items.
@override final  String? sortText;
/// A string that should be used when filtering a set of completion items.
@override final  String? filterText;
/// The range of text to be replaced by this completion item.
@override final  Range? range;
/// Characters that trigger the commit of this completion.
 final  List<String>? _commitCharacters;
/// Characters that trigger the commit of this completion.
@override List<String>? get commitCharacters {
  final value = _commitCharacters;
  if (value == null) return null;
  if (_commitCharacters is EqualUnmodifiableListView) return _commitCharacters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Rules that control how the [insertText] is formatted.
 final  Set<InsertTextRule>? _insertTextRules;
/// Rules that control how the [insertText] is formatted.
@override Set<InsertTextRule>? get insertTextRules {
  final value = _insertTextRules;
  if (value == null) return null;
  if (_insertTextRules is EqualUnmodifiableSetView) return _insertTextRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(value);
}


/// Create a copy of CompletionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletionItemCopyWith<_CompletionItem> get copyWith => __$CompletionItemCopyWithImpl<_CompletionItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletionItem&&(identical(other.label, label) || other.label == label)&&(identical(other.insertText, insertText) || other.insertText == insertText)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.documentation, documentation) || other.documentation == documentation)&&(identical(other.sortText, sortText) || other.sortText == sortText)&&(identical(other.filterText, filterText) || other.filterText == filterText)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other.commitCharacters, _commitCharacters)&&const DeepCollectionEquality().equals(other.insertTextRules, _insertTextRules));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,insertText,kind,detail,documentation,sortText,filterText,range,const DeepCollectionEquality().hash(_commitCharacters),const DeepCollectionEquality().hash(_insertTextRules));
}

@override
String toString() {
    return 'CompletionItem(label: $label, insertText: $insertText, kind: $kind, detail: $detail, documentation: $documentation, sortText: $sortText, filterText: $filterText, range: $range, commitCharacters: $commitCharacters, insertTextRules: $insertTextRules)';
}


}

/// @nodoc
abstract mixin class _$CompletionItemCopyWith<$Res> implements $CompletionItemCopyWith<$Res> {
  factory _$CompletionItemCopyWith(_CompletionItem value, $Res Function(_CompletionItem) _then) = __$CompletionItemCopyWithImpl;
@override @useResult
$Res call({
 String label, String? insertText, CompletionItemKind? kind, String? detail, String? documentation, String? sortText, String? filterText, Range? range, List<String>? commitCharacters, Set<InsertTextRule>? insertTextRules
});


@override $RangeCopyWith<$Res>? get range;

}
/// @nodoc
class __$CompletionItemCopyWithImpl<$Res>
    implements _$CompletionItemCopyWith<$Res> {
  __$CompletionItemCopyWithImpl(this._self, this._then);

  final _CompletionItem _self;
  final $Res Function(_CompletionItem) _then;

/// Create a copy of CompletionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? insertText = freezed,Object? kind = freezed,Object? detail = freezed,Object? documentation = freezed,Object? sortText = freezed,Object? filterText = freezed,Object? range = freezed,Object? commitCharacters = freezed,Object? insertTextRules = freezed,}) {
  return _then(_CompletionItem(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,insertText: freezed == insertText ? _self.insertText : insertText // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CompletionItemKind?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,documentation: freezed == documentation ? _self.documentation : documentation // ignore: cast_nullable_to_non_nullable
as String?,sortText: freezed == sortText ? _self.sortText : sortText // ignore: cast_nullable_to_non_nullable
as String?,filterText: freezed == filterText ? _self.filterText : filterText // ignore: cast_nullable_to_non_nullable
as String?,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as Range?,commitCharacters: freezed == commitCharacters ? _self._commitCharacters : commitCharacters // ignore: cast_nullable_to_non_nullable
as List<String>?,insertTextRules: freezed == insertTextRules ? _self._insertTextRules : insertTextRules // ignore: cast_nullable_to_non_nullable
as Set<InsertTextRule>?,
  ));
}

/// Create a copy of CompletionItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $RangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

/// @nodoc
mixin _$CompletionList {

/// The list of completion suggestions.
 List<CompletionItem> get suggestions;/// If `true`, indicates that this is not the full list of suggestions.
 bool get isIncomplete;
/// Create a copy of CompletionList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletionListCopyWith<CompletionList> get copyWith => _$CompletionListCopyWithImpl<CompletionList>(this as CompletionList, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CompletionList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletionList&&const DeepCollectionEquality().equals(other.suggestions, _this.suggestions)&&(identical(other.isIncomplete, _this.isIncomplete) || other.isIncomplete == _this.isIncomplete));
}


@override
int get hashCode {
  final _this = this as CompletionList;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.suggestions),_this.isIncomplete);
}

@override
String toString() {
  final _this = this as CompletionList;
  return 'CompletionList(suggestions: ${_this.suggestions}, isIncomplete: ${_this.isIncomplete})';
}


}

/// @nodoc
abstract mixin class $CompletionListCopyWith<$Res>  {
  factory $CompletionListCopyWith(CompletionList value, $Res Function(CompletionList) _then) = _$CompletionListCopyWithImpl;
@useResult
$Res call({
 List<CompletionItem> suggestions, bool isIncomplete
});




}
/// @nodoc
class _$CompletionListCopyWithImpl<$Res>
    implements $CompletionListCopyWith<$Res> {
  _$CompletionListCopyWithImpl(this._self, this._then);

  final CompletionList _self;
  final $Res Function(CompletionList) _then;

/// Create a copy of CompletionList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? suggestions = null,Object? isIncomplete = null,}) {
  return _then(CompletionList(
suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<CompletionItem>,isIncomplete: null == isIncomplete ? _self.isIncomplete : isIncomplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CompletionList].
extension CompletionListPatterns on CompletionList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompletionList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompletionList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompletionList value)  $default,){
final _that = this;
switch (_that) {
case _CompletionList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompletionList value)?  $default,){
final _that = this;
switch (_that) {
case _CompletionList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CompletionItem> suggestions,  bool isIncomplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompletionList() when $default != null:
return $default(_that.suggestions,_that.isIncomplete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CompletionItem> suggestions,  bool isIncomplete)  $default,) {final _that = this;
switch (_that) {
case _CompletionList():
return $default(_that.suggestions,_that.isIncomplete);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CompletionItem> suggestions,  bool isIncomplete)?  $default,) {final _that = this;
switch (_that) {
case _CompletionList() when $default != null:
return $default(_that.suggestions,_that.isIncomplete);case _:
  return null;

}
}

}

/// @nodoc


class _CompletionList extends CompletionList {
  const _CompletionList({required  List<CompletionItem> suggestions, this.isIncomplete = false}): _suggestions = suggestions,super._();
  

/// The list of completion suggestions.
 final  List<CompletionItem> _suggestions;
/// The list of completion suggestions.
@override List<CompletionItem> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}

/// If `true`, indicates that this is not the full list of suggestions.
@override@JsonKey() final  bool isIncomplete;

/// Create a copy of CompletionList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletionListCopyWith<_CompletionList> get copyWith => __$CompletionListCopyWithImpl<_CompletionList>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletionList&&const DeepCollectionEquality().equals(other.suggestions, _suggestions)&&(identical(other.isIncomplete, isIncomplete) || other.isIncomplete == isIncomplete));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_suggestions),isIncomplete);
}

@override
String toString() {
    return 'CompletionList(suggestions: $suggestions, isIncomplete: $isIncomplete)';
}


}

/// @nodoc
abstract mixin class _$CompletionListCopyWith<$Res> implements $CompletionListCopyWith<$Res> {
  factory _$CompletionListCopyWith(_CompletionList value, $Res Function(_CompletionList) _then) = __$CompletionListCopyWithImpl;
@override @useResult
$Res call({
 List<CompletionItem> suggestions, bool isIncomplete
});




}
/// @nodoc
class __$CompletionListCopyWithImpl<$Res>
    implements _$CompletionListCopyWith<$Res> {
  __$CompletionListCopyWithImpl(this._self, this._then);

  final _CompletionList _self;
  final $Res Function(_CompletionList) _then;

/// Create a copy of CompletionList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? suggestions = null,Object? isIncomplete = null,}) {
  return _then(_CompletionList(
suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<CompletionItem>,isIncomplete: null == isIncomplete ? _self.isIncomplete : isIncomplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CompletionRequest {

/// The unique ID of the completion provider that was invoked.
 String get providerId;/// A unique ID for this specific request.
 String get requestId;/// The language ID of the document.
 String get language;/// The URI of the document.
 Uri? get uri;/// The position in the document where the request was triggered.
 Position get position;/// The default range to be replaced by a completion item.
 Range get defaultRange;/// The text of the line where the request was triggered.
 String? get lineText;/// The kind of trigger that initiated the completion request.
 int? get triggerKind;/// The character that triggered the completion request.
 String? get triggerCharacter;
/// Create a copy of CompletionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletionRequestCopyWith<CompletionRequest> get copyWith => _$CompletionRequestCopyWithImpl<CompletionRequest>(this as CompletionRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CompletionRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletionRequest&&(identical(other.providerId, _this.providerId) || other.providerId == _this.providerId)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.uri, _this.uri) || other.uri == _this.uri)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.defaultRange, _this.defaultRange) || other.defaultRange == _this.defaultRange)&&(identical(other.lineText, _this.lineText) || other.lineText == _this.lineText)&&(identical(other.triggerKind, _this.triggerKind) || other.triggerKind == _this.triggerKind)&&(identical(other.triggerCharacter, _this.triggerCharacter) || other.triggerCharacter == _this.triggerCharacter));
}


@override
int get hashCode {
  final _this = this as CompletionRequest;
  return Object.hash(runtimeType,_this.providerId,_this.requestId,_this.language,_this.uri,_this.position,_this.defaultRange,_this.lineText,_this.triggerKind,_this.triggerCharacter);
}

@override
String toString() {
  final _this = this as CompletionRequest;
  return 'CompletionRequest(providerId: ${_this.providerId}, requestId: ${_this.requestId}, language: ${_this.language}, uri: ${_this.uri}, position: ${_this.position}, defaultRange: ${_this.defaultRange}, lineText: ${_this.lineText}, triggerKind: ${_this.triggerKind}, triggerCharacter: ${_this.triggerCharacter})';
}


}

/// @nodoc
abstract mixin class $CompletionRequestCopyWith<$Res>  {
  factory $CompletionRequestCopyWith(CompletionRequest value, $Res Function(CompletionRequest) _then) = _$CompletionRequestCopyWithImpl;
@useResult
$Res call({
 String providerId, String requestId, String language, Uri? uri, Position position, Range defaultRange, String? lineText, int? triggerKind, String? triggerCharacter
});


$PositionCopyWith<$Res> get position;$RangeCopyWith<$Res> get defaultRange;

}
/// @nodoc
class _$CompletionRequestCopyWithImpl<$Res>
    implements $CompletionRequestCopyWith<$Res> {
  _$CompletionRequestCopyWithImpl(this._self, this._then);

  final CompletionRequest _self;
  final $Res Function(CompletionRequest) _then;

/// Create a copy of CompletionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = null,Object? requestId = null,Object? language = null,Object? uri = freezed,Object? position = null,Object? defaultRange = null,Object? lineText = freezed,Object? triggerKind = freezed,Object? triggerCharacter = freezed,}) {
  return _then(CompletionRequest(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,uri: freezed == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as Uri?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,defaultRange: null == defaultRange ? _self.defaultRange : defaultRange // ignore: cast_nullable_to_non_nullable
as Range,lineText: freezed == lineText ? _self.lineText : lineText // ignore: cast_nullable_to_non_nullable
as String?,triggerKind: freezed == triggerKind ? _self.triggerKind : triggerKind // ignore: cast_nullable_to_non_nullable
as int?,triggerCharacter: freezed == triggerCharacter ? _self.triggerCharacter : triggerCharacter // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CompletionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PositionCopyWith<$Res> get position {
  
  return $PositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}/// Create a copy of CompletionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get defaultRange {
  
  return $RangeCopyWith<$Res>(_self.defaultRange, (value) {
    return _then(_self.copyWith(defaultRange: value));
  });
}
}


/// Adds pattern-matching-related methods to [CompletionRequest].
extension CompletionRequestPatterns on CompletionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompletionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompletionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompletionRequest value)  $default,){
final _that = this;
switch (_that) {
case _CompletionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompletionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CompletionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String providerId,  String requestId,  String language,  Uri? uri,  Position position,  Range defaultRange,  String? lineText,  int? triggerKind,  String? triggerCharacter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompletionRequest() when $default != null:
return $default(_that.providerId,_that.requestId,_that.language,_that.uri,_that.position,_that.defaultRange,_that.lineText,_that.triggerKind,_that.triggerCharacter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String providerId,  String requestId,  String language,  Uri? uri,  Position position,  Range defaultRange,  String? lineText,  int? triggerKind,  String? triggerCharacter)  $default,) {final _that = this;
switch (_that) {
case _CompletionRequest():
return $default(_that.providerId,_that.requestId,_that.language,_that.uri,_that.position,_that.defaultRange,_that.lineText,_that.triggerKind,_that.triggerCharacter);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String providerId,  String requestId,  String language,  Uri? uri,  Position position,  Range defaultRange,  String? lineText,  int? triggerKind,  String? triggerCharacter)?  $default,) {final _that = this;
switch (_that) {
case _CompletionRequest() when $default != null:
return $default(_that.providerId,_that.requestId,_that.language,_that.uri,_that.position,_that.defaultRange,_that.lineText,_that.triggerKind,_that.triggerCharacter);case _:
  return null;

}
}

}

/// @nodoc


class _CompletionRequest extends CompletionRequest {
  const _CompletionRequest({required this.providerId, required this.requestId, required this.language, this.uri, required this.position, required this.defaultRange, this.lineText, this.triggerKind, this.triggerCharacter}): super._();
  

/// The unique ID of the completion provider that was invoked.
@override final  String providerId;
/// A unique ID for this specific request.
@override final  String requestId;
/// The language ID of the document.
@override final  String language;
/// The URI of the document.
@override final  Uri? uri;
/// The position in the document where the request was triggered.
@override final  Position position;
/// The default range to be replaced by a completion item.
@override final  Range defaultRange;
/// The text of the line where the request was triggered.
@override final  String? lineText;
/// The kind of trigger that initiated the completion request.
@override final  int? triggerKind;
/// The character that triggered the completion request.
@override final  String? triggerCharacter;

/// Create a copy of CompletionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletionRequestCopyWith<_CompletionRequest> get copyWith => __$CompletionRequestCopyWithImpl<_CompletionRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletionRequest&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.language, language) || other.language == language)&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.position, position) || other.position == position)&&(identical(other.defaultRange, defaultRange) || other.defaultRange == defaultRange)&&(identical(other.lineText, lineText) || other.lineText == lineText)&&(identical(other.triggerKind, triggerKind) || other.triggerKind == triggerKind)&&(identical(other.triggerCharacter, triggerCharacter) || other.triggerCharacter == triggerCharacter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,providerId,requestId,language,uri,position,defaultRange,lineText,triggerKind,triggerCharacter);
}

@override
String toString() {
    return 'CompletionRequest(providerId: $providerId, requestId: $requestId, language: $language, uri: $uri, position: $position, defaultRange: $defaultRange, lineText: $lineText, triggerKind: $triggerKind, triggerCharacter: $triggerCharacter)';
}


}

/// @nodoc
abstract mixin class _$CompletionRequestCopyWith<$Res> implements $CompletionRequestCopyWith<$Res> {
  factory _$CompletionRequestCopyWith(_CompletionRequest value, $Res Function(_CompletionRequest) _then) = __$CompletionRequestCopyWithImpl;
@override @useResult
$Res call({
 String providerId, String requestId, String language, Uri? uri, Position position, Range defaultRange, String? lineText, int? triggerKind, String? triggerCharacter
});


@override $PositionCopyWith<$Res> get position;@override $RangeCopyWith<$Res> get defaultRange;

}
/// @nodoc
class __$CompletionRequestCopyWithImpl<$Res>
    implements _$CompletionRequestCopyWith<$Res> {
  __$CompletionRequestCopyWithImpl(this._self, this._then);

  final _CompletionRequest _self;
  final $Res Function(_CompletionRequest) _then;

/// Create a copy of CompletionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = null,Object? requestId = null,Object? language = null,Object? uri = freezed,Object? position = null,Object? defaultRange = null,Object? lineText = freezed,Object? triggerKind = freezed,Object? triggerCharacter = freezed,}) {
  return _then(_CompletionRequest(
providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,uri: freezed == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as Uri?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,defaultRange: null == defaultRange ? _self.defaultRange : defaultRange // ignore: cast_nullable_to_non_nullable
as Range,lineText: freezed == lineText ? _self.lineText : lineText // ignore: cast_nullable_to_non_nullable
as String?,triggerKind: freezed == triggerKind ? _self.triggerKind : triggerKind // ignore: cast_nullable_to_non_nullable
as int?,triggerCharacter: freezed == triggerCharacter ? _self.triggerCharacter : triggerCharacter // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CompletionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PositionCopyWith<$Res> get position {
  
  return $PositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}/// Create a copy of CompletionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeCopyWith<$Res> get defaultRange {
  
  return $RangeCopyWith<$Res>(_self.defaultRange, (value) {
    return _then(_self.copyWith(defaultRange: value));
  });
}
}

// dart format on
