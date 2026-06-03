import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/purchase.dart';

part 'purchase_state.freezed.dart';

@freezed
abstract class PurchaseState with _$PurchaseState {
  const factory PurchaseState({
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default([]) List<PurchaseOrder> purchaseOrders,
    @Default([]) List<Supplier> suppliers,
    @Default('All Status') String selectedStatus,
    @Default('') String searchQuery,
    @Default(0) int activeTab, // 0 for Purchase Orders, 1 for Suppliers
  }) = _PurchaseState;
}
