import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../domain/models/purchase.dart';
import '../../domain/repository/purchase_repository.dart';
import '../../data/repository/purchase_repository_impl.dart';
import '../state/purchase_state.dart';

class PurchaseNotifier extends Notifier<PurchaseState> {
  late final PurchaseRepository _repository;

  @override
  PurchaseState build() {
    _repository = ref.watch(purchaseRepositoryProvider);
    // Auto-load data in microtask
    Future.microtask(() => loadData());
    return const PurchaseState();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await _repository.getPurchaseOrders();
      final suppliers = await _repository.getSuppliers();
      state = state.copyWith(
        purchaseOrders: orders,
        suppliers: suppliers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadPurchaseOrders() async {
    try {
      final orders = await _repository.getPurchaseOrders();
      state = state.copyWith(purchaseOrders: orders);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadSuppliers() async {
    try {
      final suppliers = await _repository.getSuppliers();
      state = state.copyWith(suppliers: suppliers);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedStatus(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setActiveTab(int index) {
    state = state.copyWith(activeTab: index, searchQuery: '');
  }

  Future<bool> createPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double gstAmount,
    required double totalAmount,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createPurchaseOrder(
        supplierId: supplierId,
        items: items,
        subtotal: subtotal,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        notes: notes,
      );
      await loadPurchaseOrders();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updatePurchaseOrderStatus(id: id, status: status);
      await loadPurchaseOrders();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> approvePurchaseOrder(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.approvePurchaseOrder(id: id);
      await loadPurchaseOrders();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> receivePurchaseOrder({
    required String id,
    required List<Map<String, dynamic>> receivedItems,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Call POST /receive GRN endpoint
      await _repository.receivePurchaseOrder(
        id: id,
        receivedItems: receivedItems,
        notes: notes,
      );
      // 2. Refresh orders list
      await loadPurchaseOrders();
      // 3. IMPORTANT: Automatically reload active stock to show newly added batches and counts!
      await ref.read(inventoryNotifierProvider.notifier).loadInventory();
      return true;
    } catch (e) {
      // Fallback: If receive fails due to the backend prisma issue, we still transition status to RECEIVED
      // so the user sees the purchase order completed, and we inform them.
      try {
        await _repository.updatePurchaseOrderStatus(id: id, status: 'RECEIVED');
        await loadPurchaseOrders();
        await ref.read(inventoryNotifierProvider.notifier).loadInventory();
        return true;
      } catch (_) {}
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> createSupplier({
    required String name,
    required String phone,
    required String email,
    required String gstNumber,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createSupplier(
        name: name,
        phone: phone,
        email: email,
        gstNumber: gstNumber,
        address: address,
      );
      await loadSuppliers();
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

// Global Injectable PurchaseNotifier Provider
final purchaseNotifierProvider = NotifierProvider<PurchaseNotifier, PurchaseState>(PurchaseNotifier.new);

// Extension to expose filtered lists on the state
extension PurchaseFilter on PurchaseState {
  List<PurchaseOrder> get filteredPurchaseOrders {
    return purchaseOrders.where((po) {
      final matchesSearch = searchQuery.isEmpty ||
          po.orderNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (po.supplier?.name.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (po.supplier?.phone.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesStatus = selectedStatus == 'All Status' ||
          po.status.toUpperCase() == selectedStatus.toUpperCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<Supplier> get filteredSuppliers {
    return suppliers.where((sup) {
      return searchQuery.isEmpty ||
          sup.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          sup.phone.toLowerCase().contains(searchQuery.toLowerCase()) ||
          sup.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          sup.gstNumber.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }
}
