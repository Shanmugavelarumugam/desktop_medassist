import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/invoice.dart';
import '../../domain/repository/billing_repository.dart';
import '../datasource/billing_remote_datasource.dart';

class BillingRepositoryImpl implements BillingRepository {
  final BillingRemoteDataSource _remoteDataSource;

  BillingRepositoryImpl(this._remoteDataSource);

  @override
  Future<Invoice> createInvoice({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double gst,
    required double total,
    required String paymentMethod,
    required String notes,
  }) {
    return _remoteDataSource.createInvoice(
      items: items,
      subtotal: subtotal,
      discount: discount,
      gst: gst,
      total: total,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }

  @override
  Future<List<Invoice>> getInvoices() {
    return _remoteDataSource.getInvoices();
  }

  @override
  Future<List<MedicineBatch>> getBatches(String medicineId) {
    return _remoteDataSource.getBatches(medicineId);
  }

  @override
  Future<Invoice> cancelInvoice({required String id, required String reason}) {
    return _remoteDataSource.cancelInvoice(id: id, reason: reason);
  }

  @override
  Future<Map<String, dynamic>> getDailySummary() {
    return _remoteDataSource.getDailySummary();
  }

  @override
  Future<Map<String, dynamic>> getPaymentBreakdown() {
    return _remoteDataSource.getPaymentBreakdown();
  }
}

// Global Injectable BillingRepository Provider
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final remoteDataSource = ref.watch(billingRemoteDataSourceProvider);
  return BillingRepositoryImpl(remoteDataSource);
});
