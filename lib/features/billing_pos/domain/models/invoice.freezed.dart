// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvoiceItem {

 String get id; String get medicineId; String get name; int get qty; num get price; num get mrp; num get gst; num get gstAmount; num get total; String get batchId; String get batchNumber;
/// Create a copy of InvoiceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceItemCopyWith<InvoiceItem> get copyWith => _$InvoiceItemCopyWithImpl<InvoiceItem>(this as InvoiceItem, _$identity);

  /// Serializes this InvoiceItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceItem&&(identical(other.id, id) || other.id == id)&&(identical(other.medicineId, medicineId) || other.medicineId == medicineId)&&(identical(other.name, name) || other.name == name)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.gst, gst) || other.gst == gst)&&(identical(other.gstAmount, gstAmount) || other.gstAmount == gstAmount)&&(identical(other.total, total) || other.total == total)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,medicineId,name,qty,price,mrp,gst,gstAmount,total,batchId,batchNumber);

@override
String toString() {
  return 'InvoiceItem(id: $id, medicineId: $medicineId, name: $name, qty: $qty, price: $price, mrp: $mrp, gst: $gst, gstAmount: $gstAmount, total: $total, batchId: $batchId, batchNumber: $batchNumber)';
}


}

/// @nodoc
abstract mixin class $InvoiceItemCopyWith<$Res>  {
  factory $InvoiceItemCopyWith(InvoiceItem value, $Res Function(InvoiceItem) _then) = _$InvoiceItemCopyWithImpl;
@useResult
$Res call({
 String id, String medicineId, String name, int qty, num price, num mrp, num gst, num gstAmount, num total, String batchId, String batchNumber
});




}
/// @nodoc
class _$InvoiceItemCopyWithImpl<$Res>
    implements $InvoiceItemCopyWith<$Res> {
  _$InvoiceItemCopyWithImpl(this._self, this._then);

  final InvoiceItem _self;
  final $Res Function(InvoiceItem) _then;

/// Create a copy of InvoiceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? medicineId = null,Object? name = null,Object? qty = null,Object? price = null,Object? mrp = null,Object? gst = null,Object? gstAmount = null,Object? total = null,Object? batchId = null,Object? batchNumber = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medicineId: null == medicineId ? _self.medicineId : medicineId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as num,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as num,gst: null == gst ? _self.gst : gst // ignore: cast_nullable_to_non_nullable
as num,gstAmount: null == gstAmount ? _self.gstAmount : gstAmount // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,batchNumber: null == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceItem].
extension InvoiceItemPatterns on InvoiceItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceItem value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceItem value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String medicineId,  String name,  int qty,  num price,  num mrp,  num gst,  num gstAmount,  num total,  String batchId,  String batchNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceItem() when $default != null:
return $default(_that.id,_that.medicineId,_that.name,_that.qty,_that.price,_that.mrp,_that.gst,_that.gstAmount,_that.total,_that.batchId,_that.batchNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String medicineId,  String name,  int qty,  num price,  num mrp,  num gst,  num gstAmount,  num total,  String batchId,  String batchNumber)  $default,) {final _that = this;
switch (_that) {
case _InvoiceItem():
return $default(_that.id,_that.medicineId,_that.name,_that.qty,_that.price,_that.mrp,_that.gst,_that.gstAmount,_that.total,_that.batchId,_that.batchNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String medicineId,  String name,  int qty,  num price,  num mrp,  num gst,  num gstAmount,  num total,  String batchId,  String batchNumber)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceItem() when $default != null:
return $default(_that.id,_that.medicineId,_that.name,_that.qty,_that.price,_that.mrp,_that.gst,_that.gstAmount,_that.total,_that.batchId,_that.batchNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceItem implements InvoiceItem {
  const _InvoiceItem({required this.id, required this.medicineId, required this.name, required this.qty, required this.price, required this.mrp, required this.gst, required this.gstAmount, required this.total, required this.batchId, required this.batchNumber});
  factory _InvoiceItem.fromJson(Map<String, dynamic> json) => _$InvoiceItemFromJson(json);

@override final  String id;
@override final  String medicineId;
@override final  String name;
@override final  int qty;
@override final  num price;
@override final  num mrp;
@override final  num gst;
@override final  num gstAmount;
@override final  num total;
@override final  String batchId;
@override final  String batchNumber;

/// Create a copy of InvoiceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceItemCopyWith<_InvoiceItem> get copyWith => __$InvoiceItemCopyWithImpl<_InvoiceItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceItem&&(identical(other.id, id) || other.id == id)&&(identical(other.medicineId, medicineId) || other.medicineId == medicineId)&&(identical(other.name, name) || other.name == name)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.gst, gst) || other.gst == gst)&&(identical(other.gstAmount, gstAmount) || other.gstAmount == gstAmount)&&(identical(other.total, total) || other.total == total)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,medicineId,name,qty,price,mrp,gst,gstAmount,total,batchId,batchNumber);

@override
String toString() {
  return 'InvoiceItem(id: $id, medicineId: $medicineId, name: $name, qty: $qty, price: $price, mrp: $mrp, gst: $gst, gstAmount: $gstAmount, total: $total, batchId: $batchId, batchNumber: $batchNumber)';
}


}

/// @nodoc
abstract mixin class _$InvoiceItemCopyWith<$Res> implements $InvoiceItemCopyWith<$Res> {
  factory _$InvoiceItemCopyWith(_InvoiceItem value, $Res Function(_InvoiceItem) _then) = __$InvoiceItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String medicineId, String name, int qty, num price, num mrp, num gst, num gstAmount, num total, String batchId, String batchNumber
});




}
/// @nodoc
class __$InvoiceItemCopyWithImpl<$Res>
    implements _$InvoiceItemCopyWith<$Res> {
  __$InvoiceItemCopyWithImpl(this._self, this._then);

  final _InvoiceItem _self;
  final $Res Function(_InvoiceItem) _then;

/// Create a copy of InvoiceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? medicineId = null,Object? name = null,Object? qty = null,Object? price = null,Object? mrp = null,Object? gst = null,Object? gstAmount = null,Object? total = null,Object? batchId = null,Object? batchNumber = null,}) {
  return _then(_InvoiceItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medicineId: null == medicineId ? _self.medicineId : medicineId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as num,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as num,gst: null == gst ? _self.gst : gst // ignore: cast_nullable_to_non_nullable
as num,gstAmount: null == gstAmount ? _self.gstAmount : gstAmount // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,batchNumber: null == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Invoice {

 String get id; String get invoiceNumber; String get date; String get status; String get paymentStatus; String get paymentMethod; String get patientName; String get patientPhone; List<InvoiceItem> get items; num get subtotal; num get discount; num get gst; num get total; num get paidAmount; num get balanceAmount; String? get notes; String? get pdfUrl;
/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceCopyWith<Invoice> get copyWith => _$InvoiceCopyWithImpl<Invoice>(this as Invoice, _$identity);

  /// Serializes this Invoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.patientPhone, patientPhone) || other.patientPhone == patientPhone)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.gst, gst) || other.gst == gst)&&(identical(other.total, total) || other.total == total)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.balanceAmount, balanceAmount) || other.balanceAmount == balanceAmount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,invoiceNumber,date,status,paymentStatus,paymentMethod,patientName,patientPhone,const DeepCollectionEquality().hash(items),subtotal,discount,gst,total,paidAmount,balanceAmount,notes,pdfUrl);

@override
String toString() {
  return 'Invoice(id: $id, invoiceNumber: $invoiceNumber, date: $date, status: $status, paymentStatus: $paymentStatus, paymentMethod: $paymentMethod, patientName: $patientName, patientPhone: $patientPhone, items: $items, subtotal: $subtotal, discount: $discount, gst: $gst, total: $total, paidAmount: $paidAmount, balanceAmount: $balanceAmount, notes: $notes, pdfUrl: $pdfUrl)';
}


}

/// @nodoc
abstract mixin class $InvoiceCopyWith<$Res>  {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) _then) = _$InvoiceCopyWithImpl;
@useResult
$Res call({
 String id, String invoiceNumber, String date, String status, String paymentStatus, String paymentMethod, String patientName, String patientPhone, List<InvoiceItem> items, num subtotal, num discount, num gst, num total, num paidAmount, num balanceAmount, String? notes, String? pdfUrl
});




}
/// @nodoc
class _$InvoiceCopyWithImpl<$Res>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._self, this._then);

  final Invoice _self;
  final $Res Function(Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? invoiceNumber = null,Object? date = null,Object? status = null,Object? paymentStatus = null,Object? paymentMethod = null,Object? patientName = null,Object? patientPhone = null,Object? items = null,Object? subtotal = null,Object? discount = null,Object? gst = null,Object? total = null,Object? paidAmount = null,Object? balanceAmount = null,Object? notes = freezed,Object? pdfUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,patientPhone: null == patientPhone ? _self.patientPhone : patientPhone // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<InvoiceItem>,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as num,gst: null == gst ? _self.gst : gst // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as num,balanceAmount: null == balanceAmount ? _self.balanceAmount : balanceAmount // ignore: cast_nullable_to_non_nullable
as num,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,pdfUrl: freezed == pdfUrl ? _self.pdfUrl : pdfUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Invoice].
extension InvoicePatterns on Invoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invoice value)  $default,){
final _that = this;
switch (_that) {
case _Invoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invoice value)?  $default,){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String invoiceNumber,  String date,  String status,  String paymentStatus,  String paymentMethod,  String patientName,  String patientPhone,  List<InvoiceItem> items,  num subtotal,  num discount,  num gst,  num total,  num paidAmount,  num balanceAmount,  String? notes,  String? pdfUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.invoiceNumber,_that.date,_that.status,_that.paymentStatus,_that.paymentMethod,_that.patientName,_that.patientPhone,_that.items,_that.subtotal,_that.discount,_that.gst,_that.total,_that.paidAmount,_that.balanceAmount,_that.notes,_that.pdfUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String invoiceNumber,  String date,  String status,  String paymentStatus,  String paymentMethod,  String patientName,  String patientPhone,  List<InvoiceItem> items,  num subtotal,  num discount,  num gst,  num total,  num paidAmount,  num balanceAmount,  String? notes,  String? pdfUrl)  $default,) {final _that = this;
switch (_that) {
case _Invoice():
return $default(_that.id,_that.invoiceNumber,_that.date,_that.status,_that.paymentStatus,_that.paymentMethod,_that.patientName,_that.patientPhone,_that.items,_that.subtotal,_that.discount,_that.gst,_that.total,_that.paidAmount,_that.balanceAmount,_that.notes,_that.pdfUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String invoiceNumber,  String date,  String status,  String paymentStatus,  String paymentMethod,  String patientName,  String patientPhone,  List<InvoiceItem> items,  num subtotal,  num discount,  num gst,  num total,  num paidAmount,  num balanceAmount,  String? notes,  String? pdfUrl)?  $default,) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.invoiceNumber,_that.date,_that.status,_that.paymentStatus,_that.paymentMethod,_that.patientName,_that.patientPhone,_that.items,_that.subtotal,_that.discount,_that.gst,_that.total,_that.paidAmount,_that.balanceAmount,_that.notes,_that.pdfUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Invoice implements Invoice {
  const _Invoice({required this.id, required this.invoiceNumber, required this.date, required this.status, required this.paymentStatus, required this.paymentMethod, required this.patientName, required this.patientPhone, required final  List<InvoiceItem> items, required this.subtotal, required this.discount, required this.gst, required this.total, required this.paidAmount, required this.balanceAmount, this.notes, this.pdfUrl}): _items = items;
  factory _Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);

@override final  String id;
@override final  String invoiceNumber;
@override final  String date;
@override final  String status;
@override final  String paymentStatus;
@override final  String paymentMethod;
@override final  String patientName;
@override final  String patientPhone;
 final  List<InvoiceItem> _items;
@override List<InvoiceItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  num subtotal;
@override final  num discount;
@override final  num gst;
@override final  num total;
@override final  num paidAmount;
@override final  num balanceAmount;
@override final  String? notes;
@override final  String? pdfUrl;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceCopyWith<_Invoice> get copyWith => __$InvoiceCopyWithImpl<_Invoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.patientPhone, patientPhone) || other.patientPhone == patientPhone)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.gst, gst) || other.gst == gst)&&(identical(other.total, total) || other.total == total)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.balanceAmount, balanceAmount) || other.balanceAmount == balanceAmount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,invoiceNumber,date,status,paymentStatus,paymentMethod,patientName,patientPhone,const DeepCollectionEquality().hash(_items),subtotal,discount,gst,total,paidAmount,balanceAmount,notes,pdfUrl);

@override
String toString() {
  return 'Invoice(id: $id, invoiceNumber: $invoiceNumber, date: $date, status: $status, paymentStatus: $paymentStatus, paymentMethod: $paymentMethod, patientName: $patientName, patientPhone: $patientPhone, items: $items, subtotal: $subtotal, discount: $discount, gst: $gst, total: $total, paidAmount: $paidAmount, balanceAmount: $balanceAmount, notes: $notes, pdfUrl: $pdfUrl)';
}


}

/// @nodoc
abstract mixin class _$InvoiceCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$InvoiceCopyWith(_Invoice value, $Res Function(_Invoice) _then) = __$InvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String invoiceNumber, String date, String status, String paymentStatus, String paymentMethod, String patientName, String patientPhone, List<InvoiceItem> items, num subtotal, num discount, num gst, num total, num paidAmount, num balanceAmount, String? notes, String? pdfUrl
});




}
/// @nodoc
class __$InvoiceCopyWithImpl<$Res>
    implements _$InvoiceCopyWith<$Res> {
  __$InvoiceCopyWithImpl(this._self, this._then);

  final _Invoice _self;
  final $Res Function(_Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? invoiceNumber = null,Object? date = null,Object? status = null,Object? paymentStatus = null,Object? paymentMethod = null,Object? patientName = null,Object? patientPhone = null,Object? items = null,Object? subtotal = null,Object? discount = null,Object? gst = null,Object? total = null,Object? paidAmount = null,Object? balanceAmount = null,Object? notes = freezed,Object? pdfUrl = freezed,}) {
  return _then(_Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,patientPhone: null == patientPhone ? _self.patientPhone : patientPhone // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<InvoiceItem>,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as num,gst: null == gst ? _self.gst : gst // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as num,balanceAmount: null == balanceAmount ? _self.balanceAmount : balanceAmount // ignore: cast_nullable_to_non_nullable
as num,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,pdfUrl: freezed == pdfUrl ? _self.pdfUrl : pdfUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MedicineBatch {

 String get id; String get medicineId; String get batchNumber; int get quantity; int get availableQuantity; String get expiryDate; String get mrp;// mrp and purchasePrice come back as strings or nums from backend
 String? get purchasePrice; String? get status;
/// Create a copy of MedicineBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicineBatchCopyWith<MedicineBatch> get copyWith => _$MedicineBatchCopyWithImpl<MedicineBatch>(this as MedicineBatch, _$identity);

  /// Serializes this MedicineBatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicineBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.medicineId, medicineId) || other.medicineId == medicineId)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.availableQuantity, availableQuantity) || other.availableQuantity == availableQuantity)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,medicineId,batchNumber,quantity,availableQuantity,expiryDate,mrp,purchasePrice,status);

@override
String toString() {
  return 'MedicineBatch(id: $id, medicineId: $medicineId, batchNumber: $batchNumber, quantity: $quantity, availableQuantity: $availableQuantity, expiryDate: $expiryDate, mrp: $mrp, purchasePrice: $purchasePrice, status: $status)';
}


}

/// @nodoc
abstract mixin class $MedicineBatchCopyWith<$Res>  {
  factory $MedicineBatchCopyWith(MedicineBatch value, $Res Function(MedicineBatch) _then) = _$MedicineBatchCopyWithImpl;
@useResult
$Res call({
 String id, String medicineId, String batchNumber, int quantity, int availableQuantity, String expiryDate, String mrp, String? purchasePrice, String? status
});




}
/// @nodoc
class _$MedicineBatchCopyWithImpl<$Res>
    implements $MedicineBatchCopyWith<$Res> {
  _$MedicineBatchCopyWithImpl(this._self, this._then);

  final MedicineBatch _self;
  final $Res Function(MedicineBatch) _then;

/// Create a copy of MedicineBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? medicineId = null,Object? batchNumber = null,Object? quantity = null,Object? availableQuantity = null,Object? expiryDate = null,Object? mrp = null,Object? purchasePrice = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medicineId: null == medicineId ? _self.medicineId : medicineId // ignore: cast_nullable_to_non_nullable
as String,batchNumber: null == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,availableQuantity: null == availableQuantity ? _self.availableQuantity : availableQuantity // ignore: cast_nullable_to_non_nullable
as int,expiryDate: null == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as String,purchasePrice: freezed == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicineBatch].
extension MedicineBatchPatterns on MedicineBatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicineBatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicineBatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicineBatch value)  $default,){
final _that = this;
switch (_that) {
case _MedicineBatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicineBatch value)?  $default,){
final _that = this;
switch (_that) {
case _MedicineBatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String medicineId,  String batchNumber,  int quantity,  int availableQuantity,  String expiryDate,  String mrp,  String? purchasePrice,  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicineBatch() when $default != null:
return $default(_that.id,_that.medicineId,_that.batchNumber,_that.quantity,_that.availableQuantity,_that.expiryDate,_that.mrp,_that.purchasePrice,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String medicineId,  String batchNumber,  int quantity,  int availableQuantity,  String expiryDate,  String mrp,  String? purchasePrice,  String? status)  $default,) {final _that = this;
switch (_that) {
case _MedicineBatch():
return $default(_that.id,_that.medicineId,_that.batchNumber,_that.quantity,_that.availableQuantity,_that.expiryDate,_that.mrp,_that.purchasePrice,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String medicineId,  String batchNumber,  int quantity,  int availableQuantity,  String expiryDate,  String mrp,  String? purchasePrice,  String? status)?  $default,) {final _that = this;
switch (_that) {
case _MedicineBatch() when $default != null:
return $default(_that.id,_that.medicineId,_that.batchNumber,_that.quantity,_that.availableQuantity,_that.expiryDate,_that.mrp,_that.purchasePrice,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MedicineBatch implements MedicineBatch {
  const _MedicineBatch({required this.id, required this.medicineId, required this.batchNumber, required this.quantity, required this.availableQuantity, required this.expiryDate, required this.mrp, this.purchasePrice, this.status});
  factory _MedicineBatch.fromJson(Map<String, dynamic> json) => _$MedicineBatchFromJson(json);

@override final  String id;
@override final  String medicineId;
@override final  String batchNumber;
@override final  int quantity;
@override final  int availableQuantity;
@override final  String expiryDate;
@override final  String mrp;
// mrp and purchasePrice come back as strings or nums from backend
@override final  String? purchasePrice;
@override final  String? status;

/// Create a copy of MedicineBatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicineBatchCopyWith<_MedicineBatch> get copyWith => __$MedicineBatchCopyWithImpl<_MedicineBatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedicineBatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicineBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.medicineId, medicineId) || other.medicineId == medicineId)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.availableQuantity, availableQuantity) || other.availableQuantity == availableQuantity)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,medicineId,batchNumber,quantity,availableQuantity,expiryDate,mrp,purchasePrice,status);

@override
String toString() {
  return 'MedicineBatch(id: $id, medicineId: $medicineId, batchNumber: $batchNumber, quantity: $quantity, availableQuantity: $availableQuantity, expiryDate: $expiryDate, mrp: $mrp, purchasePrice: $purchasePrice, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MedicineBatchCopyWith<$Res> implements $MedicineBatchCopyWith<$Res> {
  factory _$MedicineBatchCopyWith(_MedicineBatch value, $Res Function(_MedicineBatch) _then) = __$MedicineBatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String medicineId, String batchNumber, int quantity, int availableQuantity, String expiryDate, String mrp, String? purchasePrice, String? status
});




}
/// @nodoc
class __$MedicineBatchCopyWithImpl<$Res>
    implements _$MedicineBatchCopyWith<$Res> {
  __$MedicineBatchCopyWithImpl(this._self, this._then);

  final _MedicineBatch _self;
  final $Res Function(_MedicineBatch) _then;

/// Create a copy of MedicineBatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? medicineId = null,Object? batchNumber = null,Object? quantity = null,Object? availableQuantity = null,Object? expiryDate = null,Object? mrp = null,Object? purchasePrice = freezed,Object? status = freezed,}) {
  return _then(_MedicineBatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,medicineId: null == medicineId ? _self.medicineId : medicineId // ignore: cast_nullable_to_non_nullable
as String,batchNumber: null == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,availableQuantity: null == availableQuantity ? _self.availableQuantity : availableQuantity // ignore: cast_nullable_to_non_nullable
as int,expiryDate: null == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as String,purchasePrice: freezed == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
