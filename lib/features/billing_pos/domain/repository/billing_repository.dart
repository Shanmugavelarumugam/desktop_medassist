import '../../domain/models/invoice.dart';

abstract class BillingRepository {
  Future<Invoice> createInvoice({
    required List<Map<String, dynamic>> items,
    required String patientName,
    required String patientPhone,
    required double discountAmount,
    required String paymentMode,
    required List<Map<String, dynamic>> payments,
    required String notes,
  });

  Future<List<Invoice>> getInvoices();
  Future<List<MedicineBatch>> getBatches(String medicineId);
  Future<Invoice> cancelInvoice({required String id, required String reason});
  Future<Map<String, dynamic>> getDailySummary();
  Future<Map<String, dynamic>> getPaymentBreakdown();
}
