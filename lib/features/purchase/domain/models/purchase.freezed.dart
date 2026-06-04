// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Supplier {

 String get id; String get tenantId; String get name; String get phone; String get email; String get gstNumber; String get address; String get createdAt; String get updatedAt;
/// Create a copy of Supplier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupplierCopyWith<Supplier> get copyWith => _$SupplierCopyWithImpl<Supplier>(this as Supplier, _$identity);

  /// Serializes this Supplier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Supplier&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.gstNumber, gstNumber) || other.gstNumber == gstNumber)&&(identical(other.address, address) || other.address == address)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,name,phone,email,gstNumber,address,createdAt,updatedAt);

@override
String toString() {
  return 'Supplier(id: $id, tenantId: $tenantId, name: $name, phone: $phone, email: $email, gstNumber: $gstNumber, address: $address, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SupplierCopyWith<$Res>  {
  factory $SupplierCopyWith(Supplier value, $Res Function(Supplier) _then) = _$SupplierCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String name, String phone, String email, String gstNumber, String address, String createdAt, String updatedAt
});




}
/// @nodoc
class _$SupplierCopyWithImpl<$Res>
    implements $SupplierCopyWith<$Res> {
  _$SupplierCopyWithImpl(this._self, this._then);

  final Supplier _self;
  final $Res Function(Supplier) _then;

/// Create a copy of Supplier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? name = null,Object? phone = null,Object? email = null,Object? gstNumber = null,Object? address = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,gstNumber: null == gstNumber ? _self.gstNumber : gstNumber // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Supplier].
extension SupplierPatterns on Supplier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Supplier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Supplier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Supplier value)  $default,){
final _that = this;
switch (_that) {
case _Supplier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Supplier value)?  $default,){
final _that = this;
switch (_that) {
case _Supplier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String name,  String phone,  String email,  String gstNumber,  String address,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Supplier() when $default != null:
return $default(_that.id,_that.tenantId,_that.name,_that.phone,_that.email,_that.gstNumber,_that.address,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String name,  String phone,  String email,  String gstNumber,  String address,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Supplier():
return $default(_that.id,_that.tenantId,_that.name,_that.phone,_that.email,_that.gstNumber,_that.address,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String name,  String phone,  String email,  String gstNumber,  String address,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Supplier() when $default != null:
return $default(_that.id,_that.tenantId,_that.name,_that.phone,_that.email,_that.gstNumber,_that.address,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Supplier implements Supplier {
  const _Supplier({this.id = '', this.tenantId = '', required this.name, this.phone = '', this.email = '', this.gstNumber = '', this.address = '', this.createdAt = '', this.updatedAt = ''});
  factory _Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String tenantId;
@override final  String name;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String email;
@override@JsonKey() final  String gstNumber;
@override@JsonKey() final  String address;
@override@JsonKey() final  String createdAt;
@override@JsonKey() final  String updatedAt;

/// Create a copy of Supplier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupplierCopyWith<_Supplier> get copyWith => __$SupplierCopyWithImpl<_Supplier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupplierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Supplier&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.gstNumber, gstNumber) || other.gstNumber == gstNumber)&&(identical(other.address, address) || other.address == address)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,name,phone,email,gstNumber,address,createdAt,updatedAt);

@override
String toString() {
  return 'Supplier(id: $id, tenantId: $tenantId, name: $name, phone: $phone, email: $email, gstNumber: $gstNumber, address: $address, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SupplierCopyWith<$Res> implements $SupplierCopyWith<$Res> {
  factory _$SupplierCopyWith(_Supplier value, $Res Function(_Supplier) _then) = __$SupplierCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String name, String phone, String email, String gstNumber, String address, String createdAt, String updatedAt
});




}
/// @nodoc
class __$SupplierCopyWithImpl<$Res>
    implements _$SupplierCopyWith<$Res> {
  __$SupplierCopyWithImpl(this._self, this._then);

  final _Supplier _self;
  final $Res Function(_Supplier) _then;

/// Create a copy of Supplier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? name = null,Object? phone = null,Object? email = null,Object? gstNumber = null,Object? address = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Supplier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,gstNumber: null == gstNumber ? _self.gstNumber : gstNumber // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PurchaseOrderItem {

 String get id; String get purchaseOrderId; String get medicineId; String get medicineName; int get currentStock; int get reorderQty; int get quantity; int get receivedQuantity; String get unitPrice;// Backend Decimal returned as String
 double get gstPercentage; String get totalAmount;
/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderItemCopyWith<PurchaseOrderItem> get copyWith => _$PurchaseOrderItemCopyWithImpl<PurchaseOrderItem>(this as PurchaseOrderItem, _$identity);

  /// Serializes this PurchaseOrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.medicineId, medicineId) || other.medicineId == medicineId)&&(identical(other.medicineName, medicineName) || other.medicineName == medicineName)&&(identical(other.currentStock, currentStock) || other.currentStock == currentStock)&&(identical(other.reorderQty, reorderQty) || other.reorderQty == reorderQty)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.receivedQuantity, receivedQuantity) || other.receivedQuantity == receivedQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.gstPercentage, gstPercentage) || other.gstPercentage == gstPercentage)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,purchaseOrderId,medicineId,medicineName,currentStock,reorderQty,quantity,receivedQuantity,unitPrice,gstPercentage,totalAmount);

@override
String toString() {
  return 'PurchaseOrderItem(id: $id, purchaseOrderId: $purchaseOrderId, medicineId: $medicineId, medicineName: $medicineName, currentStock: $currentStock, reorderQty: $reorderQty, quantity: $quantity, receivedQuantity: $receivedQuantity, unitPrice: $unitPrice, gstPercentage: $gstPercentage, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderItemCopyWith<$Res>  {
  factory $PurchaseOrderItemCopyWith(PurchaseOrderItem value, $Res Function(PurchaseOrderItem) _then) = _$PurchaseOrderItemCopyWithImpl;
@useResult
$Res call({
 String id, String purchaseOrderId, String medicineId, String medicineName, int currentStock, int reorderQty, int quantity, int receivedQuantity, String unitPrice, double gstPercentage, String totalAmount
});




}
/// @nodoc
class _$PurchaseOrderItemCopyWithImpl<$Res>
    implements $PurchaseOrderItemCopyWith<$Res> {
  _$PurchaseOrderItemCopyWithImpl(this._self, this._then);

  final PurchaseOrderItem _self;
  final $Res Function(PurchaseOrderItem) _then;

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? purchaseOrderId = null,Object? medicineId = null,Object? medicineName = null,Object? currentStock = null,Object? reorderQty = null,Object? quantity = null,Object? receivedQuantity = null,Object? unitPrice = null,Object? gstPercentage = null,Object? totalAmount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,purchaseOrderId: null == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as String,medicineId: null == medicineId ? _self.medicineId : medicineId // ignore: cast_nullable_to_non_nullable
as String,medicineName: null == medicineName ? _self.medicineName : medicineName // ignore: cast_nullable_to_non_nullable
as String,currentStock: null == currentStock ? _self.currentStock : currentStock // ignore: cast_nullable_to_non_nullable
as int,reorderQty: null == reorderQty ? _self.reorderQty : reorderQty // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,receivedQuantity: null == receivedQuantity ? _self.receivedQuantity : receivedQuantity // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,gstPercentage: null == gstPercentage ? _self.gstPercentage : gstPercentage // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchaseOrderItem].
extension PurchaseOrderItemPatterns on PurchaseOrderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseOrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseOrderItem value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrderItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseOrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String purchaseOrderId,  String medicineId,  String medicineName,  int currentStock,  int reorderQty,  int quantity,  int receivedQuantity,  String unitPrice,  double gstPercentage,  String totalAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
return $default(_that.id,_that.purchaseOrderId,_that.medicineId,_that.medicineName,_that.currentStock,_that.reorderQty,_that.quantity,_that.receivedQuantity,_that.unitPrice,_that.gstPercentage,_that.totalAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String purchaseOrderId,  String medicineId,  String medicineName,  int currentStock,  int reorderQty,  int quantity,  int receivedQuantity,  String unitPrice,  double gstPercentage,  String totalAmount)  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrderItem():
return $default(_that.id,_that.purchaseOrderId,_that.medicineId,_that.medicineName,_that.currentStock,_that.reorderQty,_that.quantity,_that.receivedQuantity,_that.unitPrice,_that.gstPercentage,_that.totalAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String purchaseOrderId,  String medicineId,  String medicineName,  int currentStock,  int reorderQty,  int quantity,  int receivedQuantity,  String unitPrice,  double gstPercentage,  String totalAmount)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrderItem() when $default != null:
return $default(_that.id,_that.purchaseOrderId,_that.medicineId,_that.medicineName,_that.currentStock,_that.reorderQty,_that.quantity,_that.receivedQuantity,_that.unitPrice,_that.gstPercentage,_that.totalAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseOrderItem extends PurchaseOrderItem {
  const _PurchaseOrderItem({required this.id, required this.purchaseOrderId, required this.medicineId, required this.medicineName, required this.currentStock, required this.reorderQty, required this.quantity, required this.receivedQuantity, required this.unitPrice, required this.gstPercentage, required this.totalAmount}): super._();
  factory _PurchaseOrderItem.fromJson(Map<String, dynamic> json) => _$PurchaseOrderItemFromJson(json);

@override final  String id;
@override final  String purchaseOrderId;
@override final  String medicineId;
@override final  String medicineName;
@override final  int currentStock;
@override final  int reorderQty;
@override final  int quantity;
@override final  int receivedQuantity;
@override final  String unitPrice;
// Backend Decimal returned as String
@override final  double gstPercentage;
@override final  String totalAmount;

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseOrderItemCopyWith<_PurchaseOrderItem> get copyWith => __$PurchaseOrderItemCopyWithImpl<_PurchaseOrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseOrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseOrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.medicineId, medicineId) || other.medicineId == medicineId)&&(identical(other.medicineName, medicineName) || other.medicineName == medicineName)&&(identical(other.currentStock, currentStock) || other.currentStock == currentStock)&&(identical(other.reorderQty, reorderQty) || other.reorderQty == reorderQty)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.receivedQuantity, receivedQuantity) || other.receivedQuantity == receivedQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.gstPercentage, gstPercentage) || other.gstPercentage == gstPercentage)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,purchaseOrderId,medicineId,medicineName,currentStock,reorderQty,quantity,receivedQuantity,unitPrice,gstPercentage,totalAmount);

@override
String toString() {
  return 'PurchaseOrderItem(id: $id, purchaseOrderId: $purchaseOrderId, medicineId: $medicineId, medicineName: $medicineName, currentStock: $currentStock, reorderQty: $reorderQty, quantity: $quantity, receivedQuantity: $receivedQuantity, unitPrice: $unitPrice, gstPercentage: $gstPercentage, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class _$PurchaseOrderItemCopyWith<$Res> implements $PurchaseOrderItemCopyWith<$Res> {
  factory _$PurchaseOrderItemCopyWith(_PurchaseOrderItem value, $Res Function(_PurchaseOrderItem) _then) = __$PurchaseOrderItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String purchaseOrderId, String medicineId, String medicineName, int currentStock, int reorderQty, int quantity, int receivedQuantity, String unitPrice, double gstPercentage, String totalAmount
});




}
/// @nodoc
class __$PurchaseOrderItemCopyWithImpl<$Res>
    implements _$PurchaseOrderItemCopyWith<$Res> {
  __$PurchaseOrderItemCopyWithImpl(this._self, this._then);

  final _PurchaseOrderItem _self;
  final $Res Function(_PurchaseOrderItem) _then;

/// Create a copy of PurchaseOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? purchaseOrderId = null,Object? medicineId = null,Object? medicineName = null,Object? currentStock = null,Object? reorderQty = null,Object? quantity = null,Object? receivedQuantity = null,Object? unitPrice = null,Object? gstPercentage = null,Object? totalAmount = null,}) {
  return _then(_PurchaseOrderItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,purchaseOrderId: null == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as String,medicineId: null == medicineId ? _self.medicineId : medicineId // ignore: cast_nullable_to_non_nullable
as String,medicineName: null == medicineName ? _self.medicineName : medicineName // ignore: cast_nullable_to_non_nullable
as String,currentStock: null == currentStock ? _self.currentStock : currentStock // ignore: cast_nullable_to_non_nullable
as int,reorderQty: null == reorderQty ? _self.reorderQty : reorderQty // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,receivedQuantity: null == receivedQuantity ? _self.receivedQuantity : receivedQuantity // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,gstPercentage: null == gstPercentage ? _self.gstPercentage : gstPercentage // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PurchaseOrder {

 String get id; String get tenantId; String? get branchId; String get userId; String get supplierId; String get orderNumber; String get status;// DRAFT, PENDING_APPROVAL, APPROVED, RECEIVED, CANCELLED
 String get subtotal;// Backend Decimal returned as String
 String get gstAmount;// Backend Decimal returned as String
 String get totalAmount;// Backend Decimal returned as String
 String? get notes; String? get expectedDeliveryDate; String get createdAt; String get updatedAt; String? get approvedAt; String? get approvedBy; String? get cancelledAt; Supplier? get supplier; List<PurchaseOrderItem> get items;
/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderCopyWith<PurchaseOrder> get copyWith => _$PurchaseOrderCopyWithImpl<PurchaseOrder>(this as PurchaseOrder, _$identity);

  /// Serializes this PurchaseOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.gstAmount, gstAmount) || other.gstAmount == gstAmount)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.expectedDeliveryDate, expectedDeliveryDate) || other.expectedDeliveryDate == expectedDeliveryDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tenantId,branchId,userId,supplierId,orderNumber,status,subtotal,gstAmount,totalAmount,notes,expectedDeliveryDate,createdAt,updatedAt,approvedAt,approvedBy,cancelledAt,supplier,const DeepCollectionEquality().hash(items)]);

@override
String toString() {
  return 'PurchaseOrder(id: $id, tenantId: $tenantId, branchId: $branchId, userId: $userId, supplierId: $supplierId, orderNumber: $orderNumber, status: $status, subtotal: $subtotal, gstAmount: $gstAmount, totalAmount: $totalAmount, notes: $notes, expectedDeliveryDate: $expectedDeliveryDate, createdAt: $createdAt, updatedAt: $updatedAt, approvedAt: $approvedAt, approvedBy: $approvedBy, cancelledAt: $cancelledAt, supplier: $supplier, items: $items)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderCopyWith<$Res>  {
  factory $PurchaseOrderCopyWith(PurchaseOrder value, $Res Function(PurchaseOrder) _then) = _$PurchaseOrderCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String? branchId, String userId, String supplierId, String orderNumber, String status, String subtotal, String gstAmount, String totalAmount, String? notes, String? expectedDeliveryDate, String createdAt, String updatedAt, String? approvedAt, String? approvedBy, String? cancelledAt, Supplier? supplier, List<PurchaseOrderItem> items
});


$SupplierCopyWith<$Res>? get supplier;

}
/// @nodoc
class _$PurchaseOrderCopyWithImpl<$Res>
    implements $PurchaseOrderCopyWith<$Res> {
  _$PurchaseOrderCopyWithImpl(this._self, this._then);

  final PurchaseOrder _self;
  final $Res Function(PurchaseOrder) _then;

/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? branchId = freezed,Object? userId = null,Object? supplierId = null,Object? orderNumber = null,Object? status = null,Object? subtotal = null,Object? gstAmount = null,Object? totalAmount = null,Object? notes = freezed,Object? expectedDeliveryDate = freezed,Object? createdAt = null,Object? updatedAt = null,Object? approvedAt = freezed,Object? approvedBy = freezed,Object? cancelledAt = freezed,Object? supplier = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,supplierId: null == supplierId ? _self.supplierId : supplierId // ignore: cast_nullable_to_non_nullable
as String,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,gstAmount: null == gstAmount ? _self.gstAmount : gstAmount // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,expectedDeliveryDate: freezed == expectedDeliveryDate ? _self.expectedDeliveryDate : expectedDeliveryDate // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as String?,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as Supplier?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PurchaseOrderItem>,
  ));
}
/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}
}


/// Adds pattern-matching-related methods to [PurchaseOrder].
extension PurchaseOrderPatterns on PurchaseOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseOrder value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseOrder value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String? branchId,  String userId,  String supplierId,  String orderNumber,  String status,  String subtotal,  String gstAmount,  String totalAmount,  String? notes,  String? expectedDeliveryDate,  String createdAt,  String updatedAt,  String? approvedAt,  String? approvedBy,  String? cancelledAt,  Supplier? supplier,  List<PurchaseOrderItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
return $default(_that.id,_that.tenantId,_that.branchId,_that.userId,_that.supplierId,_that.orderNumber,_that.status,_that.subtotal,_that.gstAmount,_that.totalAmount,_that.notes,_that.expectedDeliveryDate,_that.createdAt,_that.updatedAt,_that.approvedAt,_that.approvedBy,_that.cancelledAt,_that.supplier,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String? branchId,  String userId,  String supplierId,  String orderNumber,  String status,  String subtotal,  String gstAmount,  String totalAmount,  String? notes,  String? expectedDeliveryDate,  String createdAt,  String updatedAt,  String? approvedAt,  String? approvedBy,  String? cancelledAt,  Supplier? supplier,  List<PurchaseOrderItem> items)  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrder():
return $default(_that.id,_that.tenantId,_that.branchId,_that.userId,_that.supplierId,_that.orderNumber,_that.status,_that.subtotal,_that.gstAmount,_that.totalAmount,_that.notes,_that.expectedDeliveryDate,_that.createdAt,_that.updatedAt,_that.approvedAt,_that.approvedBy,_that.cancelledAt,_that.supplier,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String? branchId,  String userId,  String supplierId,  String orderNumber,  String status,  String subtotal,  String gstAmount,  String totalAmount,  String? notes,  String? expectedDeliveryDate,  String createdAt,  String updatedAt,  String? approvedAt,  String? approvedBy,  String? cancelledAt,  Supplier? supplier,  List<PurchaseOrderItem> items)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseOrder() when $default != null:
return $default(_that.id,_that.tenantId,_that.branchId,_that.userId,_that.supplierId,_that.orderNumber,_that.status,_that.subtotal,_that.gstAmount,_that.totalAmount,_that.notes,_that.expectedDeliveryDate,_that.createdAt,_that.updatedAt,_that.approvedAt,_that.approvedBy,_that.cancelledAt,_that.supplier,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseOrder extends PurchaseOrder {
  const _PurchaseOrder({required this.id, required this.tenantId, this.branchId, required this.userId, required this.supplierId, required this.orderNumber, required this.status, required this.subtotal, required this.gstAmount, required this.totalAmount, this.notes, this.expectedDeliveryDate, required this.createdAt, required this.updatedAt, this.approvedAt, this.approvedBy, this.cancelledAt, this.supplier, final  List<PurchaseOrderItem> items = const []}): _items = items,super._();
  factory _PurchaseOrder.fromJson(Map<String, dynamic> json) => _$PurchaseOrderFromJson(json);

@override final  String id;
@override final  String tenantId;
@override final  String? branchId;
@override final  String userId;
@override final  String supplierId;
@override final  String orderNumber;
@override final  String status;
// DRAFT, PENDING_APPROVAL, APPROVED, RECEIVED, CANCELLED
@override final  String subtotal;
// Backend Decimal returned as String
@override final  String gstAmount;
// Backend Decimal returned as String
@override final  String totalAmount;
// Backend Decimal returned as String
@override final  String? notes;
@override final  String? expectedDeliveryDate;
@override final  String createdAt;
@override final  String updatedAt;
@override final  String? approvedAt;
@override final  String? approvedBy;
@override final  String? cancelledAt;
@override final  Supplier? supplier;
 final  List<PurchaseOrderItem> _items;
@override@JsonKey() List<PurchaseOrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseOrderCopyWith<_PurchaseOrder> get copyWith => __$PurchaseOrderCopyWithImpl<_PurchaseOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.gstAmount, gstAmount) || other.gstAmount == gstAmount)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.expectedDeliveryDate, expectedDeliveryDate) || other.expectedDeliveryDate == expectedDeliveryDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tenantId,branchId,userId,supplierId,orderNumber,status,subtotal,gstAmount,totalAmount,notes,expectedDeliveryDate,createdAt,updatedAt,approvedAt,approvedBy,cancelledAt,supplier,const DeepCollectionEquality().hash(_items)]);

@override
String toString() {
  return 'PurchaseOrder(id: $id, tenantId: $tenantId, branchId: $branchId, userId: $userId, supplierId: $supplierId, orderNumber: $orderNumber, status: $status, subtotal: $subtotal, gstAmount: $gstAmount, totalAmount: $totalAmount, notes: $notes, expectedDeliveryDate: $expectedDeliveryDate, createdAt: $createdAt, updatedAt: $updatedAt, approvedAt: $approvedAt, approvedBy: $approvedBy, cancelledAt: $cancelledAt, supplier: $supplier, items: $items)';
}


}

/// @nodoc
abstract mixin class _$PurchaseOrderCopyWith<$Res> implements $PurchaseOrderCopyWith<$Res> {
  factory _$PurchaseOrderCopyWith(_PurchaseOrder value, $Res Function(_PurchaseOrder) _then) = __$PurchaseOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String? branchId, String userId, String supplierId, String orderNumber, String status, String subtotal, String gstAmount, String totalAmount, String? notes, String? expectedDeliveryDate, String createdAt, String updatedAt, String? approvedAt, String? approvedBy, String? cancelledAt, Supplier? supplier, List<PurchaseOrderItem> items
});


@override $SupplierCopyWith<$Res>? get supplier;

}
/// @nodoc
class __$PurchaseOrderCopyWithImpl<$Res>
    implements _$PurchaseOrderCopyWith<$Res> {
  __$PurchaseOrderCopyWithImpl(this._self, this._then);

  final _PurchaseOrder _self;
  final $Res Function(_PurchaseOrder) _then;

/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? branchId = freezed,Object? userId = null,Object? supplierId = null,Object? orderNumber = null,Object? status = null,Object? subtotal = null,Object? gstAmount = null,Object? totalAmount = null,Object? notes = freezed,Object? expectedDeliveryDate = freezed,Object? createdAt = null,Object? updatedAt = null,Object? approvedAt = freezed,Object? approvedBy = freezed,Object? cancelledAt = freezed,Object? supplier = freezed,Object? items = null,}) {
  return _then(_PurchaseOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,supplierId: null == supplierId ? _self.supplierId : supplierId // ignore: cast_nullable_to_non_nullable
as String,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,gstAmount: null == gstAmount ? _self.gstAmount : gstAmount // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,expectedDeliveryDate: freezed == expectedDeliveryDate ? _self.expectedDeliveryDate : expectedDeliveryDate // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as String?,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as Supplier?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PurchaseOrderItem>,
  ));
}

/// Create a copy of PurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}
}

// dart format on
