import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/purchase.dart';
import '../../domain/repository/purchase_repository.dart';
import '../datasource/purchase_remote_datasource.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource _remoteDataSource;

  PurchaseRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders() {
    return _remoteDataSource.getPurchaseOrders();
  }

  @override
  Future<PurchaseOrder> createPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double gstAmount,
    required double totalAmount,
    String? notes,
  }) {
    return _remoteDataSource.createPurchaseOrder(
      supplierId: supplierId,
      items: items,
      subtotal: subtotal,
      gstAmount: gstAmount,
      totalAmount: totalAmount,
      notes: notes,
    );
  }

  @override
  Future<PurchaseOrder> updatePurchaseOrderStatus({
    required String id,
    required String status,
  }) {
    return _remoteDataSource.updatePurchaseOrderStatus(id: id, status: status);
  }

  @override
  Future<PurchaseOrder> approvePurchaseOrder({required String id}) {
    return _remoteDataSource.approvePurchaseOrder(id: id);
  }

  @override
  Future<void> receivePurchaseOrder({
    required String id,
    required List<Map<String, dynamic>> receivedItems,
    String? notes,
  }) {
    return _remoteDataSource.receivePurchaseOrder(
      id: id,
      receivedItems: receivedItems,
      notes: notes,
    );
  }

  @override
  Future<List<Supplier>> getSuppliers() {
    return _remoteDataSource.getSuppliers();
  }

  @override
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
  }) {
    return _remoteDataSource.createSupplier(
      name: name,
      phone: phone,
      email: email,
      gstNumber: gstNumber,
      address: address,
      supplierType: supplierType,
      contactPerson: contactPerson,
      drugLicenseNumber: drugLicenseNumber,
      licenseExpiry: licenseExpiry,
      status: status,
      isPreferred: isPreferred,
      rating: rating,
      leadTimeDays: leadTimeDays,
      paymentTermsDays: paymentTermsDays,
      creditLimit: creditLimit,
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
    );
  }
}

// Global Injectable PurchaseRepository Provider
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final remoteDataSource = ref.watch(purchaseRemoteDataSourceProvider);
  return PurchaseRepositoryImpl(remoteDataSource);
});
