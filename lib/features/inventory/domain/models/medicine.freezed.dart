// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medicine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MedicineCategory {

 String get id; String get tenantId; String get name; String? get description; String? get parentId; String get createdAt; String get updatedAt;
/// Create a copy of MedicineCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicineCategoryCopyWith<MedicineCategory> get copyWith => _$MedicineCategoryCopyWithImpl<MedicineCategory>(this as MedicineCategory, _$identity);

  /// Serializes this MedicineCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicineCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,name,description,parentId,createdAt,updatedAt);

@override
String toString() {
  return 'MedicineCategory(id: $id, tenantId: $tenantId, name: $name, description: $description, parentId: $parentId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MedicineCategoryCopyWith<$Res>  {
  factory $MedicineCategoryCopyWith(MedicineCategory value, $Res Function(MedicineCategory) _then) = _$MedicineCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String name, String? description, String? parentId, String createdAt, String updatedAt
});




}
/// @nodoc
class _$MedicineCategoryCopyWithImpl<$Res>
    implements $MedicineCategoryCopyWith<$Res> {
  _$MedicineCategoryCopyWithImpl(this._self, this._then);

  final MedicineCategory _self;
  final $Res Function(MedicineCategory) _then;

/// Create a copy of MedicineCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? name = null,Object? description = freezed,Object? parentId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicineCategory].
extension MedicineCategoryPatterns on MedicineCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicineCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicineCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicineCategory value)  $default,){
final _that = this;
switch (_that) {
case _MedicineCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicineCategory value)?  $default,){
final _that = this;
switch (_that) {
case _MedicineCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String name,  String? description,  String? parentId,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicineCategory() when $default != null:
return $default(_that.id,_that.tenantId,_that.name,_that.description,_that.parentId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String name,  String? description,  String? parentId,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MedicineCategory():
return $default(_that.id,_that.tenantId,_that.name,_that.description,_that.parentId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String name,  String? description,  String? parentId,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MedicineCategory() when $default != null:
return $default(_that.id,_that.tenantId,_that.name,_that.description,_that.parentId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MedicineCategory implements MedicineCategory {
  const _MedicineCategory({required this.id, required this.tenantId, required this.name, this.description, this.parentId, required this.createdAt, required this.updatedAt});
  factory _MedicineCategory.fromJson(Map<String, dynamic> json) => _$MedicineCategoryFromJson(json);

@override final  String id;
@override final  String tenantId;
@override final  String name;
@override final  String? description;
@override final  String? parentId;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of MedicineCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicineCategoryCopyWith<_MedicineCategory> get copyWith => __$MedicineCategoryCopyWithImpl<_MedicineCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedicineCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicineCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,name,description,parentId,createdAt,updatedAt);

@override
String toString() {
  return 'MedicineCategory(id: $id, tenantId: $tenantId, name: $name, description: $description, parentId: $parentId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MedicineCategoryCopyWith<$Res> implements $MedicineCategoryCopyWith<$Res> {
  factory _$MedicineCategoryCopyWith(_MedicineCategory value, $Res Function(_MedicineCategory) _then) = __$MedicineCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String name, String? description, String? parentId, String createdAt, String updatedAt
});




}
/// @nodoc
class __$MedicineCategoryCopyWithImpl<$Res>
    implements _$MedicineCategoryCopyWith<$Res> {
  __$MedicineCategoryCopyWithImpl(this._self, this._then);

  final _MedicineCategory _self;
  final $Res Function(_MedicineCategory) _then;

/// Create a copy of MedicineCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? name = null,Object? description = freezed,Object? parentId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MedicineCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Manufacturer {

 String get id; String get tenantId; String get name; String? get contactEmail; String? get phone; String? get address; String? get licenseNumber; String? get gstNumber; String get createdAt; String get updatedAt;
/// Create a copy of Manufacturer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManufacturerCopyWith<Manufacturer> get copyWith => _$ManufacturerCopyWithImpl<Manufacturer>(this as Manufacturer, _$identity);

  /// Serializes this Manufacturer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Manufacturer&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.licenseNumber, licenseNumber) || other.licenseNumber == licenseNumber)&&(identical(other.gstNumber, gstNumber) || other.gstNumber == gstNumber)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,name,contactEmail,phone,address,licenseNumber,gstNumber,createdAt,updatedAt);

@override
String toString() {
  return 'Manufacturer(id: $id, tenantId: $tenantId, name: $name, contactEmail: $contactEmail, phone: $phone, address: $address, licenseNumber: $licenseNumber, gstNumber: $gstNumber, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ManufacturerCopyWith<$Res>  {
  factory $ManufacturerCopyWith(Manufacturer value, $Res Function(Manufacturer) _then) = _$ManufacturerCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String name, String? contactEmail, String? phone, String? address, String? licenseNumber, String? gstNumber, String createdAt, String updatedAt
});




}
/// @nodoc
class _$ManufacturerCopyWithImpl<$Res>
    implements $ManufacturerCopyWith<$Res> {
  _$ManufacturerCopyWithImpl(this._self, this._then);

  final Manufacturer _self;
  final $Res Function(Manufacturer) _then;

/// Create a copy of Manufacturer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? name = null,Object? contactEmail = freezed,Object? phone = freezed,Object? address = freezed,Object? licenseNumber = freezed,Object? gstNumber = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,licenseNumber: freezed == licenseNumber ? _self.licenseNumber : licenseNumber // ignore: cast_nullable_to_non_nullable
as String?,gstNumber: freezed == gstNumber ? _self.gstNumber : gstNumber // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Manufacturer].
extension ManufacturerPatterns on Manufacturer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Manufacturer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Manufacturer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Manufacturer value)  $default,){
final _that = this;
switch (_that) {
case _Manufacturer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Manufacturer value)?  $default,){
final _that = this;
switch (_that) {
case _Manufacturer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String name,  String? contactEmail,  String? phone,  String? address,  String? licenseNumber,  String? gstNumber,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Manufacturer() when $default != null:
return $default(_that.id,_that.tenantId,_that.name,_that.contactEmail,_that.phone,_that.address,_that.licenseNumber,_that.gstNumber,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String name,  String? contactEmail,  String? phone,  String? address,  String? licenseNumber,  String? gstNumber,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Manufacturer():
return $default(_that.id,_that.tenantId,_that.name,_that.contactEmail,_that.phone,_that.address,_that.licenseNumber,_that.gstNumber,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String name,  String? contactEmail,  String? phone,  String? address,  String? licenseNumber,  String? gstNumber,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Manufacturer() when $default != null:
return $default(_that.id,_that.tenantId,_that.name,_that.contactEmail,_that.phone,_that.address,_that.licenseNumber,_that.gstNumber,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Manufacturer implements Manufacturer {
  const _Manufacturer({required this.id, required this.tenantId, required this.name, this.contactEmail, this.phone, this.address, this.licenseNumber, this.gstNumber, required this.createdAt, required this.updatedAt});
  factory _Manufacturer.fromJson(Map<String, dynamic> json) => _$ManufacturerFromJson(json);

@override final  String id;
@override final  String tenantId;
@override final  String name;
@override final  String? contactEmail;
@override final  String? phone;
@override final  String? address;
@override final  String? licenseNumber;
@override final  String? gstNumber;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of Manufacturer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManufacturerCopyWith<_Manufacturer> get copyWith => __$ManufacturerCopyWithImpl<_Manufacturer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ManufacturerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Manufacturer&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.licenseNumber, licenseNumber) || other.licenseNumber == licenseNumber)&&(identical(other.gstNumber, gstNumber) || other.gstNumber == gstNumber)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,name,contactEmail,phone,address,licenseNumber,gstNumber,createdAt,updatedAt);

@override
String toString() {
  return 'Manufacturer(id: $id, tenantId: $tenantId, name: $name, contactEmail: $contactEmail, phone: $phone, address: $address, licenseNumber: $licenseNumber, gstNumber: $gstNumber, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ManufacturerCopyWith<$Res> implements $ManufacturerCopyWith<$Res> {
  factory _$ManufacturerCopyWith(_Manufacturer value, $Res Function(_Manufacturer) _then) = __$ManufacturerCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String name, String? contactEmail, String? phone, String? address, String? licenseNumber, String? gstNumber, String createdAt, String updatedAt
});




}
/// @nodoc
class __$ManufacturerCopyWithImpl<$Res>
    implements _$ManufacturerCopyWith<$Res> {
  __$ManufacturerCopyWithImpl(this._self, this._then);

  final _Manufacturer _self;
  final $Res Function(_Manufacturer) _then;

/// Create a copy of Manufacturer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? name = null,Object? contactEmail = freezed,Object? phone = freezed,Object? address = freezed,Object? licenseNumber = freezed,Object? gstNumber = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Manufacturer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,licenseNumber: freezed == licenseNumber ? _self.licenseNumber : licenseNumber // ignore: cast_nullable_to_non_nullable
as String?,gstNumber: freezed == gstNumber ? _self.gstNumber : gstNumber // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Medicine {

 String get id; String get tenantId; String get name; String? get genericName; String? get categoryId; String? get manufacturerId; num? get gstPercentage; int? get reorderLevel; bool? get prescriptionRequired; bool? get isActive; String get createdAt; String get updatedAt; String get status; MedicineCategory? get category; Manufacturer? get manufacturer; int get stock; int get availableStock; int get reservedStock; String? get batchId; String? get batchNumber; String? get expiryDate; double get mrp; double get purchasePrice; String? get hsnCode; String? get barcode; String? get supplier; String? get notes; List<MedicineBatch>? get inventoryBatches;
/// Create a copy of Medicine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicineCopyWith<Medicine> get copyWith => _$MedicineCopyWithImpl<Medicine>(this as Medicine, _$identity);

  /// Serializes this Medicine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Medicine&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.genericName, genericName) || other.genericName == genericName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.manufacturerId, manufacturerId) || other.manufacturerId == manufacturerId)&&(identical(other.gstPercentage, gstPercentage) || other.gstPercentage == gstPercentage)&&(identical(other.reorderLevel, reorderLevel) || other.reorderLevel == reorderLevel)&&(identical(other.prescriptionRequired, prescriptionRequired) || other.prescriptionRequired == prescriptionRequired)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.category, category) || other.category == category)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.availableStock, availableStock) || other.availableStock == availableStock)&&(identical(other.reservedStock, reservedStock) || other.reservedStock == reservedStock)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.hsnCode, hsnCode) || other.hsnCode == hsnCode)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.inventoryBatches, inventoryBatches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tenantId,name,genericName,categoryId,manufacturerId,gstPercentage,reorderLevel,prescriptionRequired,isActive,createdAt,updatedAt,status,category,manufacturer,stock,availableStock,reservedStock,batchId,batchNumber,expiryDate,mrp,purchasePrice,hsnCode,barcode,supplier,notes,const DeepCollectionEquality().hash(inventoryBatches)]);

@override
String toString() {
  return 'Medicine(id: $id, tenantId: $tenantId, name: $name, genericName: $genericName, categoryId: $categoryId, manufacturerId: $manufacturerId, gstPercentage: $gstPercentage, reorderLevel: $reorderLevel, prescriptionRequired: $prescriptionRequired, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, category: $category, manufacturer: $manufacturer, stock: $stock, availableStock: $availableStock, reservedStock: $reservedStock, batchId: $batchId, batchNumber: $batchNumber, expiryDate: $expiryDate, mrp: $mrp, purchasePrice: $purchasePrice, hsnCode: $hsnCode, barcode: $barcode, supplier: $supplier, notes: $notes, inventoryBatches: $inventoryBatches)';
}


}

/// @nodoc
abstract mixin class $MedicineCopyWith<$Res>  {
  factory $MedicineCopyWith(Medicine value, $Res Function(Medicine) _then) = _$MedicineCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String name, String? genericName, String? categoryId, String? manufacturerId, num? gstPercentage, int? reorderLevel, bool? prescriptionRequired, bool? isActive, String createdAt, String updatedAt, String status, MedicineCategory? category, Manufacturer? manufacturer, int stock, int availableStock, int reservedStock, String? batchId, String? batchNumber, String? expiryDate, double mrp, double purchasePrice, String? hsnCode, String? barcode, String? supplier, String? notes, List<MedicineBatch>? inventoryBatches
});


$MedicineCategoryCopyWith<$Res>? get category;$ManufacturerCopyWith<$Res>? get manufacturer;

}
/// @nodoc
class _$MedicineCopyWithImpl<$Res>
    implements $MedicineCopyWith<$Res> {
  _$MedicineCopyWithImpl(this._self, this._then);

  final Medicine _self;
  final $Res Function(Medicine) _then;

/// Create a copy of Medicine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? name = null,Object? genericName = freezed,Object? categoryId = freezed,Object? manufacturerId = freezed,Object? gstPercentage = freezed,Object? reorderLevel = freezed,Object? prescriptionRequired = freezed,Object? isActive = freezed,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? category = freezed,Object? manufacturer = freezed,Object? stock = null,Object? availableStock = null,Object? reservedStock = null,Object? batchId = freezed,Object? batchNumber = freezed,Object? expiryDate = freezed,Object? mrp = null,Object? purchasePrice = null,Object? hsnCode = freezed,Object? barcode = freezed,Object? supplier = freezed,Object? notes = freezed,Object? inventoryBatches = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,genericName: freezed == genericName ? _self.genericName : genericName // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,manufacturerId: freezed == manufacturerId ? _self.manufacturerId : manufacturerId // ignore: cast_nullable_to_non_nullable
as String?,gstPercentage: freezed == gstPercentage ? _self.gstPercentage : gstPercentage // ignore: cast_nullable_to_non_nullable
as num?,reorderLevel: freezed == reorderLevel ? _self.reorderLevel : reorderLevel // ignore: cast_nullable_to_non_nullable
as int?,prescriptionRequired: freezed == prescriptionRequired ? _self.prescriptionRequired : prescriptionRequired // ignore: cast_nullable_to_non_nullable
as bool?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MedicineCategory?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as Manufacturer?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,availableStock: null == availableStock ? _self.availableStock : availableStock // ignore: cast_nullable_to_non_nullable
as int,reservedStock: null == reservedStock ? _self.reservedStock : reservedStock // ignore: cast_nullable_to_non_nullable
as int,batchId: freezed == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String?,batchNumber: freezed == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as double,purchasePrice: null == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double,hsnCode: freezed == hsnCode ? _self.hsnCode : hsnCode // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,inventoryBatches: freezed == inventoryBatches ? _self.inventoryBatches : inventoryBatches // ignore: cast_nullable_to_non_nullable
as List<MedicineBatch>?,
  ));
}
/// Create a copy of Medicine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicineCategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $MedicineCategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of Medicine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ManufacturerCopyWith<$Res>? get manufacturer {
    if (_self.manufacturer == null) {
    return null;
  }

  return $ManufacturerCopyWith<$Res>(_self.manufacturer!, (value) {
    return _then(_self.copyWith(manufacturer: value));
  });
}
}


/// Adds pattern-matching-related methods to [Medicine].
extension MedicinePatterns on Medicine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Medicine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Medicine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Medicine value)  $default,){
final _that = this;
switch (_that) {
case _Medicine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Medicine value)?  $default,){
final _that = this;
switch (_that) {
case _Medicine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String name,  String? genericName,  String? categoryId,  String? manufacturerId,  num? gstPercentage,  int? reorderLevel,  bool? prescriptionRequired,  bool? isActive,  String createdAt,  String updatedAt,  String status,  MedicineCategory? category,  Manufacturer? manufacturer,  int stock,  int availableStock,  int reservedStock,  String? batchId,  String? batchNumber,  String? expiryDate,  double mrp,  double purchasePrice,  String? hsnCode,  String? barcode,  String? supplier,  String? notes,  List<MedicineBatch>? inventoryBatches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Medicine() when $default != null:
return $default(_that.id,_that.tenantId,_that.name,_that.genericName,_that.categoryId,_that.manufacturerId,_that.gstPercentage,_that.reorderLevel,_that.prescriptionRequired,_that.isActive,_that.createdAt,_that.updatedAt,_that.status,_that.category,_that.manufacturer,_that.stock,_that.availableStock,_that.reservedStock,_that.batchId,_that.batchNumber,_that.expiryDate,_that.mrp,_that.purchasePrice,_that.hsnCode,_that.barcode,_that.supplier,_that.notes,_that.inventoryBatches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String name,  String? genericName,  String? categoryId,  String? manufacturerId,  num? gstPercentage,  int? reorderLevel,  bool? prescriptionRequired,  bool? isActive,  String createdAt,  String updatedAt,  String status,  MedicineCategory? category,  Manufacturer? manufacturer,  int stock,  int availableStock,  int reservedStock,  String? batchId,  String? batchNumber,  String? expiryDate,  double mrp,  double purchasePrice,  String? hsnCode,  String? barcode,  String? supplier,  String? notes,  List<MedicineBatch>? inventoryBatches)  $default,) {final _that = this;
switch (_that) {
case _Medicine():
return $default(_that.id,_that.tenantId,_that.name,_that.genericName,_that.categoryId,_that.manufacturerId,_that.gstPercentage,_that.reorderLevel,_that.prescriptionRequired,_that.isActive,_that.createdAt,_that.updatedAt,_that.status,_that.category,_that.manufacturer,_that.stock,_that.availableStock,_that.reservedStock,_that.batchId,_that.batchNumber,_that.expiryDate,_that.mrp,_that.purchasePrice,_that.hsnCode,_that.barcode,_that.supplier,_that.notes,_that.inventoryBatches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String name,  String? genericName,  String? categoryId,  String? manufacturerId,  num? gstPercentage,  int? reorderLevel,  bool? prescriptionRequired,  bool? isActive,  String createdAt,  String updatedAt,  String status,  MedicineCategory? category,  Manufacturer? manufacturer,  int stock,  int availableStock,  int reservedStock,  String? batchId,  String? batchNumber,  String? expiryDate,  double mrp,  double purchasePrice,  String? hsnCode,  String? barcode,  String? supplier,  String? notes,  List<MedicineBatch>? inventoryBatches)?  $default,) {final _that = this;
switch (_that) {
case _Medicine() when $default != null:
return $default(_that.id,_that.tenantId,_that.name,_that.genericName,_that.categoryId,_that.manufacturerId,_that.gstPercentage,_that.reorderLevel,_that.prescriptionRequired,_that.isActive,_that.createdAt,_that.updatedAt,_that.status,_that.category,_that.manufacturer,_that.stock,_that.availableStock,_that.reservedStock,_that.batchId,_that.batchNumber,_that.expiryDate,_that.mrp,_that.purchasePrice,_that.hsnCode,_that.barcode,_that.supplier,_that.notes,_that.inventoryBatches);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Medicine implements Medicine {
  const _Medicine({required this.id, required this.tenantId, required this.name, this.genericName, this.categoryId, this.manufacturerId, this.gstPercentage, this.reorderLevel, this.prescriptionRequired, this.isActive, required this.createdAt, required this.updatedAt, required this.status, this.category, this.manufacturer, this.stock = 0, this.availableStock = 0, this.reservedStock = 0, this.batchId, this.batchNumber, this.expiryDate, this.mrp = 0.0, this.purchasePrice = 0.0, this.hsnCode, this.barcode, this.supplier, this.notes, final  List<MedicineBatch>? inventoryBatches}): _inventoryBatches = inventoryBatches;
  factory _Medicine.fromJson(Map<String, dynamic> json) => _$MedicineFromJson(json);

@override final  String id;
@override final  String tenantId;
@override final  String name;
@override final  String? genericName;
@override final  String? categoryId;
@override final  String? manufacturerId;
@override final  num? gstPercentage;
@override final  int? reorderLevel;
@override final  bool? prescriptionRequired;
@override final  bool? isActive;
@override final  String createdAt;
@override final  String updatedAt;
@override final  String status;
@override final  MedicineCategory? category;
@override final  Manufacturer? manufacturer;
@override@JsonKey() final  int stock;
@override@JsonKey() final  int availableStock;
@override@JsonKey() final  int reservedStock;
@override final  String? batchId;
@override final  String? batchNumber;
@override final  String? expiryDate;
@override@JsonKey() final  double mrp;
@override@JsonKey() final  double purchasePrice;
@override final  String? hsnCode;
@override final  String? barcode;
@override final  String? supplier;
@override final  String? notes;
 final  List<MedicineBatch>? _inventoryBatches;
@override List<MedicineBatch>? get inventoryBatches {
  final value = _inventoryBatches;
  if (value == null) return null;
  if (_inventoryBatches is EqualUnmodifiableListView) return _inventoryBatches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Medicine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicineCopyWith<_Medicine> get copyWith => __$MedicineCopyWithImpl<_Medicine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedicineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Medicine&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.genericName, genericName) || other.genericName == genericName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.manufacturerId, manufacturerId) || other.manufacturerId == manufacturerId)&&(identical(other.gstPercentage, gstPercentage) || other.gstPercentage == gstPercentage)&&(identical(other.reorderLevel, reorderLevel) || other.reorderLevel == reorderLevel)&&(identical(other.prescriptionRequired, prescriptionRequired) || other.prescriptionRequired == prescriptionRequired)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.category, category) || other.category == category)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.availableStock, availableStock) || other.availableStock == availableStock)&&(identical(other.reservedStock, reservedStock) || other.reservedStock == reservedStock)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.hsnCode, hsnCode) || other.hsnCode == hsnCode)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._inventoryBatches, _inventoryBatches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tenantId,name,genericName,categoryId,manufacturerId,gstPercentage,reorderLevel,prescriptionRequired,isActive,createdAt,updatedAt,status,category,manufacturer,stock,availableStock,reservedStock,batchId,batchNumber,expiryDate,mrp,purchasePrice,hsnCode,barcode,supplier,notes,const DeepCollectionEquality().hash(_inventoryBatches)]);

@override
String toString() {
  return 'Medicine(id: $id, tenantId: $tenantId, name: $name, genericName: $genericName, categoryId: $categoryId, manufacturerId: $manufacturerId, gstPercentage: $gstPercentage, reorderLevel: $reorderLevel, prescriptionRequired: $prescriptionRequired, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, category: $category, manufacturer: $manufacturer, stock: $stock, availableStock: $availableStock, reservedStock: $reservedStock, batchId: $batchId, batchNumber: $batchNumber, expiryDate: $expiryDate, mrp: $mrp, purchasePrice: $purchasePrice, hsnCode: $hsnCode, barcode: $barcode, supplier: $supplier, notes: $notes, inventoryBatches: $inventoryBatches)';
}


}

/// @nodoc
abstract mixin class _$MedicineCopyWith<$Res> implements $MedicineCopyWith<$Res> {
  factory _$MedicineCopyWith(_Medicine value, $Res Function(_Medicine) _then) = __$MedicineCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String name, String? genericName, String? categoryId, String? manufacturerId, num? gstPercentage, int? reorderLevel, bool? prescriptionRequired, bool? isActive, String createdAt, String updatedAt, String status, MedicineCategory? category, Manufacturer? manufacturer, int stock, int availableStock, int reservedStock, String? batchId, String? batchNumber, String? expiryDate, double mrp, double purchasePrice, String? hsnCode, String? barcode, String? supplier, String? notes, List<MedicineBatch>? inventoryBatches
});


@override $MedicineCategoryCopyWith<$Res>? get category;@override $ManufacturerCopyWith<$Res>? get manufacturer;

}
/// @nodoc
class __$MedicineCopyWithImpl<$Res>
    implements _$MedicineCopyWith<$Res> {
  __$MedicineCopyWithImpl(this._self, this._then);

  final _Medicine _self;
  final $Res Function(_Medicine) _then;

/// Create a copy of Medicine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? name = null,Object? genericName = freezed,Object? categoryId = freezed,Object? manufacturerId = freezed,Object? gstPercentage = freezed,Object? reorderLevel = freezed,Object? prescriptionRequired = freezed,Object? isActive = freezed,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? category = freezed,Object? manufacturer = freezed,Object? stock = null,Object? availableStock = null,Object? reservedStock = null,Object? batchId = freezed,Object? batchNumber = freezed,Object? expiryDate = freezed,Object? mrp = null,Object? purchasePrice = null,Object? hsnCode = freezed,Object? barcode = freezed,Object? supplier = freezed,Object? notes = freezed,Object? inventoryBatches = freezed,}) {
  return _then(_Medicine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,genericName: freezed == genericName ? _self.genericName : genericName // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,manufacturerId: freezed == manufacturerId ? _self.manufacturerId : manufacturerId // ignore: cast_nullable_to_non_nullable
as String?,gstPercentage: freezed == gstPercentage ? _self.gstPercentage : gstPercentage // ignore: cast_nullable_to_non_nullable
as num?,reorderLevel: freezed == reorderLevel ? _self.reorderLevel : reorderLevel // ignore: cast_nullable_to_non_nullable
as int?,prescriptionRequired: freezed == prescriptionRequired ? _self.prescriptionRequired : prescriptionRequired // ignore: cast_nullable_to_non_nullable
as bool?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MedicineCategory?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as Manufacturer?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,availableStock: null == availableStock ? _self.availableStock : availableStock // ignore: cast_nullable_to_non_nullable
as int,reservedStock: null == reservedStock ? _self.reservedStock : reservedStock // ignore: cast_nullable_to_non_nullable
as int,batchId: freezed == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String?,batchNumber: freezed == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String?,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as double,purchasePrice: null == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double,hsnCode: freezed == hsnCode ? _self.hsnCode : hsnCode // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,inventoryBatches: freezed == inventoryBatches ? _self._inventoryBatches : inventoryBatches // ignore: cast_nullable_to_non_nullable
as List<MedicineBatch>?,
  ));
}

/// Create a copy of Medicine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicineCategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $MedicineCategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of Medicine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ManufacturerCopyWith<$Res>? get manufacturer {
    if (_self.manufacturer == null) {
    return null;
  }

  return $ManufacturerCopyWith<$Res>(_self.manufacturer!, (value) {
    return _then(_self.copyWith(manufacturer: value));
  });
}
}

// dart format on
