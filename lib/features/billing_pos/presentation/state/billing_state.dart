import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../../domain/models/invoice.dart';

part 'billing_state.freezed.dart';

@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required Medicine medicine,
    required String batchId,
    required String batchNumber,
    required double mrp,
    required int quantity,
    required int availableStock,
    required String expiryDate,
  }) = _CartItem;
}

@freezed
abstract class BillingState with _$BillingState {
  const factory BillingState({
    @Default([]) List<CartItem> cartItems,
    @Default(0.0) double discount,
    @Default('CASH') String paymentMethod,
    @Default('Walk-in Customer') String patientName,
    @Default('N/A') String patientPhone,
    @Default([]) List<Invoice> invoices,
    @Default(false) bool isLoading,
    String? errorMessage,
    Invoice? lastCreatedInvoice,
    @Default({}) Map<String, dynamic> dailySummary,
    @Default({}) Map<String, dynamic> paymentBreakdown,
  }) = _BillingState;
}
