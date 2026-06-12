import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase.freezed.dart';
part 'purchase.g.dart';

@freezed
abstract class Supplier with _$Supplier {
  const factory Supplier({
    @Default('') String id,
    @Default('') String tenantId,
    required String name,
    @Default('') String phone,
    @Default('') String email,
    @Default('') String gstNumber,
    @Default('') String address,
    @Default('') String createdAt,
    @Default('') String updatedAt,
    String? supplierCode,
    String? supplierType,
    String? contactPerson,
    String? drugLicenseNumber,
    String? licenseExpiry,
    @Default('ACTIVE') String status,
    @Default(false) bool isPreferred,
    @JsonKey(fromJson: _parseDouble) double? rating,
    @JsonKey(fromJson: _parseIntWithDefault7) @Default(7) int leadTimeDays,
    @JsonKey(fromJson: _parseIntWithDefault30) @Default(30) int paymentTermsDays,
    @JsonKey(fromJson: _parseDouble) double? creditLimit,
    @JsonKey(fromJson: _parseDouble) double? outstandingBalance,
    @JsonKey(fromJson: _parseDouble) double? totalPurchases,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
  }) = _Supplier;

  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _parseIntWithDefault7(dynamic value) {
  if (value == null) return 7;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 7;
}

int _parseIntWithDefault30(dynamic value) {
  if (value == null) return 30;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 30;
}

@freezed
abstract class PurchaseOrderItem with _$PurchaseOrderItem {
  const PurchaseOrderItem._();

  const factory PurchaseOrderItem({
    required String id,
    required String purchaseOrderId,
    required String medicineId,
    required String medicineName,
    required int currentStock,
    required int reorderQty,
    required int quantity,
    required int receivedQuantity,
    required String unitPrice, // Backend Decimal returned as String
    required double gstPercentage,
    required String totalAmount, // Backend Decimal returned as String
  }) = _PurchaseOrderItem;

  double get unitPriceDouble => double.tryParse(unitPrice) ?? 0.0;
  double get totalAmountDouble => double.tryParse(totalAmount) ?? 0.0;

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) => _$PurchaseOrderItemFromJson(json);
}

@freezed
abstract class PurchaseOrder with _$PurchaseOrder {
  const PurchaseOrder._();

  const factory PurchaseOrder({
    required String id,
    required String tenantId,
    String? branchId,
    required String userId,
    required String supplierId,
    required String orderNumber,
    required String status, // DRAFT, PENDING_APPROVAL, APPROVED, RECEIVED, CANCELLED
    required String subtotal, // Backend Decimal returned as String
    required String gstAmount, // Backend Decimal returned as String
    required String totalAmount, // Backend Decimal returned as String
    String? notes,
    String? expectedDeliveryDate,
    required String createdAt,
    required String updatedAt,
    String? approvedAt,
    String? approvedBy,
    String? cancelledAt,
    Supplier? supplier,
    @Default([]) List<PurchaseOrderItem> items,
  }) = _PurchaseOrder;

  double get subtotalDouble => double.tryParse(subtotal) ?? 0.0;
  double get gstAmountDouble => double.tryParse(gstAmount) ?? 0.0;
  double get totalAmountDouble => double.tryParse(totalAmount) ?? 0.0;

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => _$PurchaseOrderFromJson(json);
}
