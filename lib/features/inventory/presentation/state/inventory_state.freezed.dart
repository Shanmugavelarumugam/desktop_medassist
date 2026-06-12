// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InventoryState {

 List<Medicine> get medicines; List<MedicineCategory> get categories; List<Manufacturer> get manufacturers; bool get isLoading; String? get errorMessage; String get search; String get selectedCategory; String get selectedStatus; InventorySummary get summary;
/// Create a copy of InventoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryStateCopyWith<InventoryState> get copyWith => _$InventoryStateCopyWithImpl<InventoryState>(this as InventoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryState&&const DeepCollectionEquality().equals(other.medicines, medicines)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.manufacturers, manufacturers)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.search, search) || other.search == search)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.selectedStatus, selectedStatus) || other.selectedStatus == selectedStatus)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(medicines),const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(manufacturers),isLoading,errorMessage,search,selectedCategory,selectedStatus,summary);

@override
String toString() {
  return 'InventoryState(medicines: $medicines, categories: $categories, manufacturers: $manufacturers, isLoading: $isLoading, errorMessage: $errorMessage, search: $search, selectedCategory: $selectedCategory, selectedStatus: $selectedStatus, summary: $summary)';
}


}

/// @nodoc
abstract mixin class $InventoryStateCopyWith<$Res>  {
  factory $InventoryStateCopyWith(InventoryState value, $Res Function(InventoryState) _then) = _$InventoryStateCopyWithImpl;
@useResult
$Res call({
 List<Medicine> medicines, List<MedicineCategory> categories, List<Manufacturer> manufacturers, bool isLoading, String? errorMessage, String search, String selectedCategory, String selectedStatus, InventorySummary summary
});




}
/// @nodoc
class _$InventoryStateCopyWithImpl<$Res>
    implements $InventoryStateCopyWith<$Res> {
  _$InventoryStateCopyWithImpl(this._self, this._then);

  final InventoryState _self;
  final $Res Function(InventoryState) _then;

/// Create a copy of InventoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? medicines = null,Object? categories = null,Object? manufacturers = null,Object? isLoading = null,Object? errorMessage = freezed,Object? search = null,Object? selectedCategory = null,Object? selectedStatus = null,Object? summary = null,}) {
  return _then(_self.copyWith(
medicines: null == medicines ? _self.medicines : medicines // ignore: cast_nullable_to_non_nullable
as List<Medicine>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<MedicineCategory>,manufacturers: null == manufacturers ? _self.manufacturers : manufacturers // ignore: cast_nullable_to_non_nullable
as List<Manufacturer>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,selectedCategory: null == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as String,selectedStatus: null == selectedStatus ? _self.selectedStatus : selectedStatus // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as InventorySummary,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryState].
extension InventoryStatePatterns on InventoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryState value)  $default,){
final _that = this;
switch (_that) {
case _InventoryState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryState value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Medicine> medicines,  List<MedicineCategory> categories,  List<Manufacturer> manufacturers,  bool isLoading,  String? errorMessage,  String search,  String selectedCategory,  String selectedStatus,  InventorySummary summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryState() when $default != null:
return $default(_that.medicines,_that.categories,_that.manufacturers,_that.isLoading,_that.errorMessage,_that.search,_that.selectedCategory,_that.selectedStatus,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Medicine> medicines,  List<MedicineCategory> categories,  List<Manufacturer> manufacturers,  bool isLoading,  String? errorMessage,  String search,  String selectedCategory,  String selectedStatus,  InventorySummary summary)  $default,) {final _that = this;
switch (_that) {
case _InventoryState():
return $default(_that.medicines,_that.categories,_that.manufacturers,_that.isLoading,_that.errorMessage,_that.search,_that.selectedCategory,_that.selectedStatus,_that.summary);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Medicine> medicines,  List<MedicineCategory> categories,  List<Manufacturer> manufacturers,  bool isLoading,  String? errorMessage,  String search,  String selectedCategory,  String selectedStatus,  InventorySummary summary)?  $default,) {final _that = this;
switch (_that) {
case _InventoryState() when $default != null:
return $default(_that.medicines,_that.categories,_that.manufacturers,_that.isLoading,_that.errorMessage,_that.search,_that.selectedCategory,_that.selectedStatus,_that.summary);case _:
  return null;

}
}

}

/// @nodoc


class _InventoryState implements InventoryState {
  const _InventoryState({final  List<Medicine> medicines = const [], final  List<MedicineCategory> categories = const [], final  List<Manufacturer> manufacturers = const [], this.isLoading = false, this.errorMessage, this.search = '', this.selectedCategory = 'All Categories', this.selectedStatus = 'All Status', this.summary = const InventorySummary()}): _medicines = medicines,_categories = categories,_manufacturers = manufacturers;
  

 final  List<Medicine> _medicines;
@override@JsonKey() List<Medicine> get medicines {
  if (_medicines is EqualUnmodifiableListView) return _medicines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_medicines);
}

 final  List<MedicineCategory> _categories;
@override@JsonKey() List<MedicineCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<Manufacturer> _manufacturers;
@override@JsonKey() List<Manufacturer> get manufacturers {
  if (_manufacturers is EqualUnmodifiableListView) return _manufacturers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_manufacturers);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
@override@JsonKey() final  String search;
@override@JsonKey() final  String selectedCategory;
@override@JsonKey() final  String selectedStatus;
@override@JsonKey() final  InventorySummary summary;

/// Create a copy of InventoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryStateCopyWith<_InventoryState> get copyWith => __$InventoryStateCopyWithImpl<_InventoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryState&&const DeepCollectionEquality().equals(other._medicines, _medicines)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._manufacturers, _manufacturers)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.search, search) || other.search == search)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.selectedStatus, selectedStatus) || other.selectedStatus == selectedStatus)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_medicines),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_manufacturers),isLoading,errorMessage,search,selectedCategory,selectedStatus,summary);

@override
String toString() {
  return 'InventoryState(medicines: $medicines, categories: $categories, manufacturers: $manufacturers, isLoading: $isLoading, errorMessage: $errorMessage, search: $search, selectedCategory: $selectedCategory, selectedStatus: $selectedStatus, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$InventoryStateCopyWith<$Res> implements $InventoryStateCopyWith<$Res> {
  factory _$InventoryStateCopyWith(_InventoryState value, $Res Function(_InventoryState) _then) = __$InventoryStateCopyWithImpl;
@override @useResult
$Res call({
 List<Medicine> medicines, List<MedicineCategory> categories, List<Manufacturer> manufacturers, bool isLoading, String? errorMessage, String search, String selectedCategory, String selectedStatus, InventorySummary summary
});




}
/// @nodoc
class __$InventoryStateCopyWithImpl<$Res>
    implements _$InventoryStateCopyWith<$Res> {
  __$InventoryStateCopyWithImpl(this._self, this._then);

  final _InventoryState _self;
  final $Res Function(_InventoryState) _then;

/// Create a copy of InventoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? medicines = null,Object? categories = null,Object? manufacturers = null,Object? isLoading = null,Object? errorMessage = freezed,Object? search = null,Object? selectedCategory = null,Object? selectedStatus = null,Object? summary = null,}) {
  return _then(_InventoryState(
medicines: null == medicines ? _self._medicines : medicines // ignore: cast_nullable_to_non_nullable
as List<Medicine>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<MedicineCategory>,manufacturers: null == manufacturers ? _self._manufacturers : manufacturers // ignore: cast_nullable_to_non_nullable
as List<Manufacturer>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,selectedCategory: null == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as String,selectedStatus: null == selectedStatus ? _self.selectedStatus : selectedStatus // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as InventorySummary,
  ));
}


}

// dart format on
