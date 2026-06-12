import '../../domain/models/purchase.dart';

abstract class PurchaseRepository {
  Future<List<PurchaseOrder>> getPurchaseOrders();
  Future<PurchaseOrder> createPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double gstAmount,
    required double totalAmount,
    String? notes,
  });
  Future<PurchaseOrder> updatePurchaseOrderStatus({
    required String id,
    required String status,
  });
  Future<PurchaseOrder> approvePurchaseOrder({required String id});
  Future<void> receivePurchaseOrder({
    required String id,
    required List<Map<String, dynamic>> receivedItems,
    String? notes,
  });
  Future<List<Supplier>> getSuppliers();
  Future<Supplier> createSupplier({
    required String name,
    required String phone,
    required String email,
    required String gstNumber,
    required String address,
    String? supplierType,
    String? contactPerson,
    String? drugLicenseNumber,
    String? licenseExpiry,
    String? status,
    bool? isPreferred,
    double? rating,
    int? leadTimeDays,
    int? paymentTermsDays,
    double? creditLimit,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
  });
}
