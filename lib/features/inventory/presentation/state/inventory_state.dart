import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/medicine.dart';
import '../../domain/models/inventory_summary.dart';

part 'inventory_state.freezed.dart';

@freezed
abstract class InventoryState with _$InventoryState {
  const factory InventoryState({
    @Default([]) List<Medicine> medicines,
    @Default([]) List<MedicineCategory> categories,
    @Default([]) List<Manufacturer> manufacturers,
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default('') String search,
    @Default('All Categories') String selectedCategory,
    @Default('All Status') String selectedStatus,
    @Default(InventorySummary()) InventorySummary summary,
  }) = _InventoryState;
}
