import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repository/inventory_repository.dart';
import '../../data/repository/inventory_repository_impl.dart';
import '../state/inventory_state.dart';
import '../../domain/models/medicine.dart';

class InventoryNotifier extends Notifier<InventoryState> {
  late final InventoryRepository _repository;

  @override
  InventoryState build() {
    _repository = ref.watch(inventoryRepositoryProvider);
    // Load inventory immediately in microtask
    Future.microtask(() => loadInventory());
    return const InventoryState();
  }

  Future<void> loadInventory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final medicines = await _repository.getMedicines();
      final categories = await _repository.getCategories();
      final manufacturers = await _repository.getManufacturers();
      state = state.copyWith(
        medicines: medicines,
        categories: categories,
        manufacturers: manufacturers,
        isLoading: false,
      );
    } catch (e) {
      debugPrint("NOTIFIER LOAD INVENTORY ERROR: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setStatus(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  Future<bool> createMedicine({
    required String name,
    required String genericName,
    required double mrp,
    required double purchasePrice,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required String categoryId,
    String? manufacturerId,
    double? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    String? hsnCode,
    String? barcode,
    String? supplier,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createMedicine(
        name: name,
        genericName: genericName,
        mrp: mrp,
        purchasePrice: purchasePrice,
        batchNumber: batchNumber,
        quantity: quantity,
        expiryDate: expiryDate,
        categoryId: categoryId,
        manufacturerId: manufacturerId,
        gstPercentage: gstPercentage,
        reorderLevel: reorderLevel,
        prescriptionRequired: prescriptionRequired,
        hsnCode: hsnCode,
        barcode: barcode,
        supplier: supplier,
        notes: notes,
      );
      await loadInventory();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateMedicine({
    required String id,
    required String name,
    String? genericName,
    String? categoryId,
    String? manufacturerId,
    double? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    String? hsnCode,
    String? barcode,
    String? supplier,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateMedicine(
        id: id,
        name: name,
        genericName: genericName,
        categoryId: categoryId,
        manufacturerId: manufacturerId,
        gstPercentage: gstPercentage,
        reorderLevel: reorderLevel,
        prescriptionRequired: prescriptionRequired,
        hsnCode: hsnCode,
        barcode: barcode,
        supplier: supplier,
        notes: notes,
      );
      await loadInventory();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteMedicine({required String id}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteMedicine(id: id);
      await loadInventory();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> addBatch({
    required String medicineId,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required double purchasePrice,
    required double mrp,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.addBatch(
        medicineId: medicineId,
        batchNumber: batchNumber,
        quantity: quantity,
        expiryDate: expiryDate,
        purchasePrice: purchasePrice,
        mrp: mrp,
      );
      await loadInventory();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

// Global Injectable InventoryNotifier Provider
final inventoryNotifierProvider = NotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);

// Extension to expose filtered list and computed dashboard statistics on the state
extension InventoryStats on InventoryState {
  List<Medicine> get filteredMedicines {
    return medicines.where((med) {
      // 1. Search Filter (by name, generic, or batch)
      final matchesSearch = search.isEmpty ||
          med.name.toLowerCase().contains(search.toLowerCase()) ||
          (med.genericName != null && med.genericName!.toLowerCase().contains(search.toLowerCase())) ||
          (med.batchNumber != null && med.batchNumber!.toLowerCase().contains(search.toLowerCase()));

      // 2. Category Filter
      final matchesCategory = selectedCategory == 'All Categories' ||
          (med.category != null && med.category!.name == selectedCategory);

      // 3. Status Filter
      final matchesStatus = selectedStatus == 'All Status' || _checkStatusMatches(med, selectedStatus);

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  bool _checkStatusMatches(Medicine med, String statusFilter) {
    final now = DateTime.now();
    final bool isExpired = med.expiryDate != null && DateTime.parse(med.expiryDate!).isBefore(now);
    final int reorderLevel = med.reorderLevel ?? 10;
    
    switch (statusFilter) {
      case 'Expired':
        return isExpired;
      case 'Out of Stock':
        return med.stock == 0;
      case 'Low Stock':
        return med.stock > 0 && med.stock <= reorderLevel && !isExpired;
      case 'In Stock':
        return med.stock > reorderLevel && !isExpired;
      default:
        return true;
    }
  }

  // Calculated Stats
  int get totalSKU => medicines.length;

  int get outOfStockCount => medicines.where((m) => m.stock == 0).length;

  int get lowStockCount {
    final now = DateTime.now();
    return medicines.where((m) {
      final isExpired = m.expiryDate != null && m.expiryDate!.isNotEmpty && DateTime.parse(m.expiryDate!).isBefore(now);
      return m.stock > 0 && m.stock <= (m.reorderLevel ?? 10) && !isExpired;
    }).length;
  }

  int get inStockCount {
    final now = DateTime.now();
    return medicines.where((m) {
      final isExpired = m.expiryDate != null && m.expiryDate!.isNotEmpty && DateTime.parse(m.expiryDate!).isBefore(now);
      return m.stock > (m.reorderLevel ?? 10) && !isExpired;
    }).length;
  }

  int get expiredCount {
    final now = DateTime.now();
    return medicines.where((m) => m.expiryDate != null && m.expiryDate!.isNotEmpty && DateTime.parse(m.expiryDate!).isBefore(now)).length;
  }

  double get inventoryValue {
    return medicines.fold(0.0, (sum, m) => sum + (m.stock * m.mrp));
  }
}
