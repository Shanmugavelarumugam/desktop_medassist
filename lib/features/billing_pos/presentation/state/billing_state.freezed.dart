// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CartItem {

 Medicine get medicine; String get batchId; String get batchNumber; double get mrp; int get quantity; int get availableStock; String get expiryDate;
/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartItemCopyWith<CartItem> get copyWith => _$CartItemCopyWithImpl<CartItem>(this as CartItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartItem&&(identical(other.medicine, medicine) || other.medicine == medicine)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.availableStock, availableStock) || other.availableStock == availableStock)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate));
}


@override
int get hashCode => Object.hash(runtimeType,medicine,batchId,batchNumber,mrp,quantity,availableStock,expiryDate);

@override
String toString() {
  return 'CartItem(medicine: $medicine, batchId: $batchId, batchNumber: $batchNumber, mrp: $mrp, quantity: $quantity, availableStock: $availableStock, expiryDate: $expiryDate)';
}


}

/// @nodoc
abstract mixin class $CartItemCopyWith<$Res>  {
  factory $CartItemCopyWith(CartItem value, $Res Function(CartItem) _then) = _$CartItemCopyWithImpl;
@useResult
$Res call({
 Medicine medicine, String batchId, String batchNumber, double mrp, int quantity, int availableStock, String expiryDate
});


$MedicineCopyWith<$Res> get medicine;

}
/// @nodoc
class _$CartItemCopyWithImpl<$Res>
    implements $CartItemCopyWith<$Res> {
  _$CartItemCopyWithImpl(this._self, this._then);

  final CartItem _self;
  final $Res Function(CartItem) _then;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? medicine = null,Object? batchId = null,Object? batchNumber = null,Object? mrp = null,Object? quantity = null,Object? availableStock = null,Object? expiryDate = null,}) {
  return _then(_self.copyWith(
medicine: null == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as Medicine,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,batchNumber: null == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,availableStock: null == availableStock ? _self.availableStock : availableStock // ignore: cast_nullable_to_non_nullable
as int,expiryDate: null == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicineCopyWith<$Res> get medicine {
  
  return $MedicineCopyWith<$Res>(_self.medicine, (value) {
    return _then(_self.copyWith(medicine: value));
  });
}
}


/// Adds pattern-matching-related methods to [CartItem].
extension CartItemPatterns on CartItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartItem value)  $default,){
final _that = this;
switch (_that) {
case _CartItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartItem value)?  $default,){
final _that = this;
switch (_that) {
case _CartItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Medicine medicine,  String batchId,  String batchNumber,  double mrp,  int quantity,  int availableStock,  String expiryDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartItem() when $default != null:
return $default(_that.medicine,_that.batchId,_that.batchNumber,_that.mrp,_that.quantity,_that.availableStock,_that.expiryDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Medicine medicine,  String batchId,  String batchNumber,  double mrp,  int quantity,  int availableStock,  String expiryDate)  $default,) {final _that = this;
switch (_that) {
case _CartItem():
return $default(_that.medicine,_that.batchId,_that.batchNumber,_that.mrp,_that.quantity,_that.availableStock,_that.expiryDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Medicine medicine,  String batchId,  String batchNumber,  double mrp,  int quantity,  int availableStock,  String expiryDate)?  $default,) {final _that = this;
switch (_that) {
case _CartItem() when $default != null:
return $default(_that.medicine,_that.batchId,_that.batchNumber,_that.mrp,_that.quantity,_that.availableStock,_that.expiryDate);case _:
  return null;

}
}

}

/// @nodoc


class _CartItem implements CartItem {
  const _CartItem({required this.medicine, required this.batchId, required this.batchNumber, required this.mrp, required this.quantity, required this.availableStock, required this.expiryDate});
  

@override final  Medicine medicine;
@override final  String batchId;
@override final  String batchNumber;
@override final  double mrp;
@override final  int quantity;
@override final  int availableStock;
@override final  String expiryDate;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartItemCopyWith<_CartItem> get copyWith => __$CartItemCopyWithImpl<_CartItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartItem&&(identical(other.medicine, medicine) || other.medicine == medicine)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.batchNumber, batchNumber) || other.batchNumber == batchNumber)&&(identical(other.mrp, mrp) || other.mrp == mrp)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.availableStock, availableStock) || other.availableStock == availableStock)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate));
}


@override
int get hashCode => Object.hash(runtimeType,medicine,batchId,batchNumber,mrp,quantity,availableStock,expiryDate);

@override
String toString() {
  return 'CartItem(medicine: $medicine, batchId: $batchId, batchNumber: $batchNumber, mrp: $mrp, quantity: $quantity, availableStock: $availableStock, expiryDate: $expiryDate)';
}


}

/// @nodoc
abstract mixin class _$CartItemCopyWith<$Res> implements $CartItemCopyWith<$Res> {
  factory _$CartItemCopyWith(_CartItem value, $Res Function(_CartItem) _then) = __$CartItemCopyWithImpl;
@override @useResult
$Res call({
 Medicine medicine, String batchId, String batchNumber, double mrp, int quantity, int availableStock, String expiryDate
});


@override $MedicineCopyWith<$Res> get medicine;

}
/// @nodoc
class __$CartItemCopyWithImpl<$Res>
    implements _$CartItemCopyWith<$Res> {
  __$CartItemCopyWithImpl(this._self, this._then);

  final _CartItem _self;
  final $Res Function(_CartItem) _then;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? medicine = null,Object? batchId = null,Object? batchNumber = null,Object? mrp = null,Object? quantity = null,Object? availableStock = null,Object? expiryDate = null,}) {
  return _then(_CartItem(
medicine: null == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as Medicine,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,batchNumber: null == batchNumber ? _self.batchNumber : batchNumber // ignore: cast_nullable_to_non_nullable
as String,mrp: null == mrp ? _self.mrp : mrp // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,availableStock: null == availableStock ? _self.availableStock : availableStock // ignore: cast_nullable_to_non_nullable
as int,expiryDate: null == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedicineCopyWith<$Res> get medicine {
  
  return $MedicineCopyWith<$Res>(_self.medicine, (value) {
    return _then(_self.copyWith(medicine: value));
  });
}
}

/// @nodoc
mixin _$BillingState {

 List<CartItem> get cartItems; double get discount; String get paymentMethod; String get patientName; String get patientPhone; List<Invoice> get invoices; bool get isLoading; String? get errorMessage; Invoice? get lastCreatedInvoice; Map<String, dynamic> get dailySummary; Map<String, dynamic> get paymentBreakdown;
/// Create a copy of BillingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillingStateCopyWith<BillingState> get copyWith => _$BillingStateCopyWithImpl<BillingState>(this as BillingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillingState&&const DeepCollectionEquality().equals(other.cartItems, cartItems)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.patientPhone, patientPhone) || other.patientPhone == patientPhone)&&const DeepCollectionEquality().equals(other.invoices, invoices)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.lastCreatedInvoice, lastCreatedInvoice) || other.lastCreatedInvoice == lastCreatedInvoice)&&const DeepCollectionEquality().equals(other.dailySummary, dailySummary)&&const DeepCollectionEquality().equals(other.paymentBreakdown, paymentBreakdown));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(cartItems),discount,paymentMethod,patientName,patientPhone,const DeepCollectionEquality().hash(invoices),isLoading,errorMessage,lastCreatedInvoice,const DeepCollectionEquality().hash(dailySummary),const DeepCollectionEquality().hash(paymentBreakdown));

@override
String toString() {
  return 'BillingState(cartItems: $cartItems, discount: $discount, paymentMethod: $paymentMethod, patientName: $patientName, patientPhone: $patientPhone, invoices: $invoices, isLoading: $isLoading, errorMessage: $errorMessage, lastCreatedInvoice: $lastCreatedInvoice, dailySummary: $dailySummary, paymentBreakdown: $paymentBreakdown)';
}


}

/// @nodoc
abstract mixin class $BillingStateCopyWith<$Res>  {
  factory $BillingStateCopyWith(BillingState value, $Res Function(BillingState) _then) = _$BillingStateCopyWithImpl;
@useResult
$Res call({
 List<CartItem> cartItems, double discount, String paymentMethod, String patientName, String patientPhone, List<Invoice> invoices, bool isLoading, String? errorMessage, Invoice? lastCreatedInvoice, Map<String, dynamic> dailySummary, Map<String, dynamic> paymentBreakdown
});


$InvoiceCopyWith<$Res>? get lastCreatedInvoice;

}
/// @nodoc
class _$BillingStateCopyWithImpl<$Res>
    implements $BillingStateCopyWith<$Res> {
  _$BillingStateCopyWithImpl(this._self, this._then);

  final BillingState _self;
  final $Res Function(BillingState) _then;

/// Create a copy of BillingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cartItems = null,Object? discount = null,Object? paymentMethod = null,Object? patientName = null,Object? patientPhone = null,Object? invoices = null,Object? isLoading = null,Object? errorMessage = freezed,Object? lastCreatedInvoice = freezed,Object? dailySummary = null,Object? paymentBreakdown = null,}) {
  return _then(_self.copyWith(
cartItems: null == cartItems ? _self.cartItems : cartItems // ignore: cast_nullable_to_non_nullable
as List<CartItem>,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,patientPhone: null == patientPhone ? _self.patientPhone : patientPhone // ignore: cast_nullable_to_non_nullable
as String,invoices: null == invoices ? _self.invoices : invoices // ignore: cast_nullable_to_non_nullable
as List<Invoice>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,lastCreatedInvoice: freezed == lastCreatedInvoice ? _self.lastCreatedInvoice : lastCreatedInvoice // ignore: cast_nullable_to_non_nullable
as Invoice?,dailySummary: null == dailySummary ? _self.dailySummary : dailySummary // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,paymentBreakdown: null == paymentBreakdown ? _self.paymentBreakdown : paymentBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of BillingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceCopyWith<$Res>? get lastCreatedInvoice {
    if (_self.lastCreatedInvoice == null) {
    return null;
  }

  return $InvoiceCopyWith<$Res>(_self.lastCreatedInvoice!, (value) {
    return _then(_self.copyWith(lastCreatedInvoice: value));
  });
}
}


/// Adds pattern-matching-related methods to [BillingState].
extension BillingStatePatterns on BillingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillingState value)  $default,){
final _that = this;
switch (_that) {
case _BillingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillingState value)?  $default,){
final _that = this;
switch (_that) {
case _BillingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CartItem> cartItems,  double discount,  String paymentMethod,  String patientName,  String patientPhone,  List<Invoice> invoices,  bool isLoading,  String? errorMessage,  Invoice? lastCreatedInvoice,  Map<String, dynamic> dailySummary,  Map<String, dynamic> paymentBreakdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillingState() when $default != null:
return $default(_that.cartItems,_that.discount,_that.paymentMethod,_that.patientName,_that.patientPhone,_that.invoices,_that.isLoading,_that.errorMessage,_that.lastCreatedInvoice,_that.dailySummary,_that.paymentBreakdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CartItem> cartItems,  double discount,  String paymentMethod,  String patientName,  String patientPhone,  List<Invoice> invoices,  bool isLoading,  String? errorMessage,  Invoice? lastCreatedInvoice,  Map<String, dynamic> dailySummary,  Map<String, dynamic> paymentBreakdown)  $default,) {final _that = this;
switch (_that) {
case _BillingState():
return $default(_that.cartItems,_that.discount,_that.paymentMethod,_that.patientName,_that.patientPhone,_that.invoices,_that.isLoading,_that.errorMessage,_that.lastCreatedInvoice,_that.dailySummary,_that.paymentBreakdown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CartItem> cartItems,  double discount,  String paymentMethod,  String patientName,  String patientPhone,  List<Invoice> invoices,  bool isLoading,  String? errorMessage,  Invoice? lastCreatedInvoice,  Map<String, dynamic> dailySummary,  Map<String, dynamic> paymentBreakdown)?  $default,) {final _that = this;
switch (_that) {
case _BillingState() when $default != null:
return $default(_that.cartItems,_that.discount,_that.paymentMethod,_that.patientName,_that.patientPhone,_that.invoices,_that.isLoading,_that.errorMessage,_that.lastCreatedInvoice,_that.dailySummary,_that.paymentBreakdown);case _:
  return null;

}
}

}

/// @nodoc


class _BillingState implements BillingState {
  const _BillingState({final  List<CartItem> cartItems = const [], this.discount = 0.0, this.paymentMethod = 'CASH', this.patientName = 'Walk-in Customer', this.patientPhone = 'N/A', final  List<Invoice> invoices = const [], this.isLoading = false, this.errorMessage, this.lastCreatedInvoice, final  Map<String, dynamic> dailySummary = const {}, final  Map<String, dynamic> paymentBreakdown = const {}}): _cartItems = cartItems,_invoices = invoices,_dailySummary = dailySummary,_paymentBreakdown = paymentBreakdown;
  

 final  List<CartItem> _cartItems;
@override@JsonKey() List<CartItem> get cartItems {
  if (_cartItems is EqualUnmodifiableListView) return _cartItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cartItems);
}

@override@JsonKey() final  double discount;
@override@JsonKey() final  String paymentMethod;
@override@JsonKey() final  String patientName;
@override@JsonKey() final  String patientPhone;
 final  List<Invoice> _invoices;
@override@JsonKey() List<Invoice> get invoices {
  if (_invoices is EqualUnmodifiableListView) return _invoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invoices);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
@override final  Invoice? lastCreatedInvoice;
 final  Map<String, dynamic> _dailySummary;
@override@JsonKey() Map<String, dynamic> get dailySummary {
  if (_dailySummary is EqualUnmodifiableMapView) return _dailySummary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dailySummary);
}

 final  Map<String, dynamic> _paymentBreakdown;
@override@JsonKey() Map<String, dynamic> get paymentBreakdown {
  if (_paymentBreakdown is EqualUnmodifiableMapView) return _paymentBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_paymentBreakdown);
}


/// Create a copy of BillingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillingStateCopyWith<_BillingState> get copyWith => __$BillingStateCopyWithImpl<_BillingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillingState&&const DeepCollectionEquality().equals(other._cartItems, _cartItems)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.patientPhone, patientPhone) || other.patientPhone == patientPhone)&&const DeepCollectionEquality().equals(other._invoices, _invoices)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.lastCreatedInvoice, lastCreatedInvoice) || other.lastCreatedInvoice == lastCreatedInvoice)&&const DeepCollectionEquality().equals(other._dailySummary, _dailySummary)&&const DeepCollectionEquality().equals(other._paymentBreakdown, _paymentBreakdown));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cartItems),discount,paymentMethod,patientName,patientPhone,const DeepCollectionEquality().hash(_invoices),isLoading,errorMessage,lastCreatedInvoice,const DeepCollectionEquality().hash(_dailySummary),const DeepCollectionEquality().hash(_paymentBreakdown));

@override
String toString() {
  return 'BillingState(cartItems: $cartItems, discount: $discount, paymentMethod: $paymentMethod, patientName: $patientName, patientPhone: $patientPhone, invoices: $invoices, isLoading: $isLoading, errorMessage: $errorMessage, lastCreatedInvoice: $lastCreatedInvoice, dailySummary: $dailySummary, paymentBreakdown: $paymentBreakdown)';
}


}

/// @nodoc
abstract mixin class _$BillingStateCopyWith<$Res> implements $BillingStateCopyWith<$Res> {
  factory _$BillingStateCopyWith(_BillingState value, $Res Function(_BillingState) _then) = __$BillingStateCopyWithImpl;
@override @useResult
$Res call({
 List<CartItem> cartItems, double discount, String paymentMethod, String patientName, String patientPhone, List<Invoice> invoices, bool isLoading, String? errorMessage, Invoice? lastCreatedInvoice, Map<String, dynamic> dailySummary, Map<String, dynamic> paymentBreakdown
});


@override $InvoiceCopyWith<$Res>? get lastCreatedInvoice;

}
/// @nodoc
class __$BillingStateCopyWithImpl<$Res>
    implements _$BillingStateCopyWith<$Res> {
  __$BillingStateCopyWithImpl(this._self, this._then);

  final _BillingState _self;
  final $Res Function(_BillingState) _then;

/// Create a copy of BillingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cartItems = null,Object? discount = null,Object? paymentMethod = null,Object? patientName = null,Object? patientPhone = null,Object? invoices = null,Object? isLoading = null,Object? errorMessage = freezed,Object? lastCreatedInvoice = freezed,Object? dailySummary = null,Object? paymentBreakdown = null,}) {
  return _then(_BillingState(
cartItems: null == cartItems ? _self._cartItems : cartItems // ignore: cast_nullable_to_non_nullable
as List<CartItem>,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,patientPhone: null == patientPhone ? _self.patientPhone : patientPhone // ignore: cast_nullable_to_non_nullable
as String,invoices: null == invoices ? _self._invoices : invoices // ignore: cast_nullable_to_non_nullable
as List<Invoice>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,lastCreatedInvoice: freezed == lastCreatedInvoice ? _self.lastCreatedInvoice : lastCreatedInvoice // ignore: cast_nullable_to_non_nullable
as Invoice?,dailySummary: null == dailySummary ? _self._dailySummary : dailySummary // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,paymentBreakdown: null == paymentBreakdown ? _self._paymentBreakdown : paymentBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of BillingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceCopyWith<$Res>? get lastCreatedInvoice {
    if (_self.lastCreatedInvoice == null) {
    return null;
  }

  return $InvoiceCopyWith<$Res>(_self.lastCreatedInvoice!, (value) {
    return _then(_self.copyWith(lastCreatedInvoice: value));
  });
}
}

// dart format on
