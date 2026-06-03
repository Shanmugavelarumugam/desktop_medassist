import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase.freezed.dart';
part 'purchase.g.dart';

@freezed
abstract class Supplier with _$Supplier {
  const factory Supplier({
    required String id,
    required String tenantId,
    required String name,
    required String phone,
    required String email,
    required String gstNumber,
    required String address,
    required String createdAt,
    required String updatedAt,
  }) = _Supplier;

  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
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
