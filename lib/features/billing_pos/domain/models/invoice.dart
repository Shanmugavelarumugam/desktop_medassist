import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

@freezed
abstract class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String medicineId,
    required String name,
    required int qty,
    required num price,
    required num mrp,
    required num gst,
    required num gstAmount,
    required num total,
    required String batchId,
    required String batchNumber,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);
}

@freezed
abstract class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String invoiceNumber,
    required String date,
    required String status,
    required String paymentStatus,
    required String paymentMethod,
    required String patientName,
    required String patientPhone,
    required List<InvoiceItem> items,
    required num subtotal,
    required num discount,
    required num gst,
    required num total,
    required num paidAmount,
    required num balanceAmount,
    String? notes,
    String? pdfUrl,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}

@freezed
abstract class MedicineBatch with _$MedicineBatch {
  const factory MedicineBatch({
    required String id,
    required String medicineId,
    required String batchNumber,
    required int quantity,
    required int availableQuantity,
    required String expiryDate,
    required dynamic
    mrp, // mrp and purchasePrice come back as strings or nums from backend
    dynamic purchasePrice,
    String? status,
    String? medicineName,
    Map<String, dynamic>? medicine,
  }) = _MedicineBatch;

  factory MedicineBatch.fromJson(Map<String, dynamic> json) =>
      _$MedicineBatchFromJson(json);
}
