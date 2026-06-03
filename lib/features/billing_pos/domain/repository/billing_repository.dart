import '../../domain/models/invoice.dart';

abstract class BillingRepository {
  Future<Invoice> createInvoice({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double gst,
    required double total,
    required String paymentMethod,
    required String notes,
  });

  Future<List<Invoice>> getInvoices();
  Future<List<MedicineBatch>> getBatches(String medicineId);
  Future<Invoice> cancelInvoice({required String id, required String reason});
  Future<Map<String, dynamic>> getDailySummary();
  Future<Map<String, dynamic>> getPaymentBreakdown();
}
