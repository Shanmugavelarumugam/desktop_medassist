// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PurchaseState {

 bool get isLoading; String? get errorMessage; List<PurchaseOrder> get purchaseOrders; List<Supplier> get suppliers; String get selectedStatus; String get searchQuery; int get activeTab;
/// Create a copy of PurchaseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseStateCopyWith<PurchaseState> get copyWith => _$PurchaseStateCopyWithImpl<PurchaseState>(this as PurchaseState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other.purchaseOrders, purchaseOrders)&&const DeepCollectionEquality().equals(other.suppliers, suppliers)&&(identical(other.selectedStatus, selectedStatus) || other.selectedStatus == selectedStatus)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.activeTab, activeTab) || other.activeTab == activeTab));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,errorMessage,const DeepCollectionEquality().hash(purchaseOrders),const DeepCollectionEquality().hash(suppliers),selectedStatus,searchQuery,activeTab);

@override
String toString() {
  return 'PurchaseState(isLoading: $isLoading, errorMessage: $errorMessage, purchaseOrders: $purchaseOrders, suppliers: $suppliers, selectedStatus: $selectedStatus, searchQuery: $searchQuery, activeTab: $activeTab)';
}


}

/// @nodoc
abstract mixin class $PurchaseStateCopyWith<$Res>  {
  factory $PurchaseStateCopyWith(PurchaseState value, $Res Function(PurchaseState) _then) = _$PurchaseStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String? errorMessage, List<PurchaseOrder> purchaseOrders, List<Supplier> suppliers, String selectedStatus, String searchQuery, int activeTab
});




}
/// @nodoc
class _$PurchaseStateCopyWithImpl<$Res>
    implements $PurchaseStateCopyWith<$Res> {
  _$PurchaseStateCopyWithImpl(this._self, this._then);

  final PurchaseState _self;
  final $Res Function(PurchaseState) _then;

/// Create a copy of PurchaseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? errorMessage = freezed,Object? purchaseOrders = null,Object? suppliers = null,Object? selectedStatus = null,Object? searchQuery = null,Object? activeTab = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,purchaseOrders: null == purchaseOrders ? _self.purchaseOrders : purchaseOrders // ignore: cast_nullable_to_non_nullable
as List<PurchaseOrder>,suppliers: null == suppliers ? _self.suppliers : suppliers // ignore: cast_nullable_to_non_nullable
as List<Supplier>,selectedStatus: null == selectedStatus ? _self.selectedStatus : selectedStatus // ignore: cast_nullable_to_non_nullable
as String,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,activeTab: null == activeTab ? _self.activeTab : activeTab // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchaseState].
extension PurchaseStatePatterns on PurchaseState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseState value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseState value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String? errorMessage,  List<PurchaseOrder> purchaseOrders,  List<Supplier> suppliers,  String selectedStatus,  String searchQuery,  int activeTab)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.purchaseOrders,_that.suppliers,_that.selectedStatus,_that.searchQuery,_that.activeTab);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String? errorMessage,  List<PurchaseOrder> purchaseOrders,  List<Supplier> suppliers,  String selectedStatus,  String searchQuery,  int activeTab)  $default,) {final _that = this;
switch (_that) {
case _PurchaseState():
return $default(_that.isLoading,_that.errorMessage,_that.purchaseOrders,_that.suppliers,_that.selectedStatus,_that.searchQuery,_that.activeTab);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String? errorMessage,  List<PurchaseOrder> purchaseOrders,  List<Supplier> suppliers,  String selectedStatus,  String searchQuery,  int activeTab)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.purchaseOrders,_that.suppliers,_that.selectedStatus,_that.searchQuery,_that.activeTab);case _:
  return null;

}
}

}

/// @nodoc


class _PurchaseState implements PurchaseState {
  const _PurchaseState({this.isLoading = false, this.errorMessage, final  List<PurchaseOrder> purchaseOrders = const [], final  List<Supplier> suppliers = const [], this.selectedStatus = 'All Status', this.searchQuery = '', this.activeTab = 0}): _purchaseOrders = purchaseOrders,_suppliers = suppliers;
  

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
 final  List<PurchaseOrder> _purchaseOrders;
@override@JsonKey() List<PurchaseOrder> get purchaseOrders {
  if (_purchaseOrders is EqualUnmodifiableListView) return _purchaseOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_purchaseOrders);
}

 final  List<Supplier> _suppliers;
@override@JsonKey() List<Supplier> get suppliers {
  if (_suppliers is EqualUnmodifiableListView) return _suppliers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suppliers);
}

@override@JsonKey() final  String selectedStatus;
@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  int activeTab;

/// Create a copy of PurchaseState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseStateCopyWith<_PurchaseState> get copyWith => __$PurchaseStateCopyWithImpl<_PurchaseState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other._purchaseOrders, _purchaseOrders)&&const DeepCollectionEquality().equals(other._suppliers, _suppliers)&&(identical(other.selectedStatus, selectedStatus) || other.selectedStatus == selectedStatus)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.activeTab, activeTab) || other.activeTab == activeTab));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,errorMessage,const DeepCollectionEquality().hash(_purchaseOrders),const DeepCollectionEquality().hash(_suppliers),selectedStatus,searchQuery,activeTab);

@override
String toString() {
  return 'PurchaseState(isLoading: $isLoading, errorMessage: $errorMessage, purchaseOrders: $purchaseOrders, suppliers: $suppliers, selectedStatus: $selectedStatus, searchQuery: $searchQuery, activeTab: $activeTab)';
}


}

/// @nodoc
abstract mixin class _$PurchaseStateCopyWith<$Res> implements $PurchaseStateCopyWith<$Res> {
  factory _$PurchaseStateCopyWith(_PurchaseState value, $Res Function(_PurchaseState) _then) = __$PurchaseStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String? errorMessage, List<PurchaseOrder> purchaseOrders, List<Supplier> suppliers, String selectedStatus, String searchQuery, int activeTab
});




}
/// @nodoc
class __$PurchaseStateCopyWithImpl<$Res>
    implements _$PurchaseStateCopyWith<$Res> {
  __$PurchaseStateCopyWithImpl(this._self, this._then);

  final _PurchaseState _self;
  final $Res Function(_PurchaseState) _then;

/// Create a copy of PurchaseState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? errorMessage = freezed,Object? purchaseOrders = null,Object? suppliers = null,Object? selectedStatus = null,Object? searchQuery = null,Object? activeTab = null,}) {
  return _then(_PurchaseState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,purchaseOrders: null == purchaseOrders ? _self._purchaseOrders : purchaseOrders // ignore: cast_nullable_to_non_nullable
as List<PurchaseOrder>,suppliers: null == suppliers ? _self._suppliers : suppliers // ignore: cast_nullable_to_non_nullable
as List<Supplier>,selectedStatus: null == selectedStatus ? _self.selectedStatus : selectedStatus // ignore: cast_nullable_to_non_nullable
as String,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,activeTab: null == activeTab ? _self.activeTab : activeTab // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
