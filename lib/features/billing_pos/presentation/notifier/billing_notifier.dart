import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repository/billing_repository.dart';
import '../../data/repository/billing_repository_impl.dart';
import '../state/billing_state.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../domain/models/invoice.dart';

class BillingNotifier extends Notifier<BillingState> {
  late final BillingRepository _repository;

  @override
  BillingState build() {
    _repository = ref.watch(billingRepositoryProvider);
    Future.microtask(() {
      loadInvoices();
      loadAnalytics();
    });
    return const BillingState();
  }

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final invoices = await _repository.getInvoices();
      state = state.copyWith(invoices: invoices, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void addToCart({
    required Medicine medicine,
    required String batchId,
    required String batchNumber,
    required double mrp,
    required int quantity,
    required int availableStock,
    required String expiryDate,
  }) {
    final existingIndex = state.cartItems.indexWhere((item) => item.batchId == batchId);
    
    if (existingIndex >= 0) {
      // Item already in cart, increment quantity
      final existing = state.cartItems[existingIndex];
      final newQty = existing.quantity + quantity;
      
      // Limit to available stock
      final finalQty = newQty > availableStock ? availableStock : newQty;
      
      final updatedList = List<CartItem>.from(state.cartItems);
      updatedList[existingIndex] = existing.copyWith(quantity: finalQty);
      state = state.copyWith(cartItems: updatedList);
    } else {
      // Add new item
      final finalQty = quantity > availableStock ? availableStock : quantity;
      final newItem = CartItem(
        medicine: medicine,
        batchId: batchId,
        batchNumber: batchNumber,
        mrp: mrp,
        quantity: finalQty,
        availableStock: availableStock,
        expiryDate: expiryDate,
      );
      state = state.copyWith(cartItems: [...state.cartItems, newItem]);
    }
  }

  void removeFromCart(String batchId) {
    state = state.copyWith(
      cartItems: state.cartItems.where((item) => item.batchId != batchId).toList(),
    );
  }

  void updateQuantity(String batchId, int quantity) {
    state = state.copyWith(
      cartItems: state.cartItems.map((item) {
        if (item.batchId == batchId) {
          final finalQty = quantity > item.availableStock ? item.availableStock : (quantity < 1 ? 1 : quantity);
          return item.copyWith(quantity: finalQty);
        }
        return item;
      }).toList(),
    );
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount < 0 ? 0 : discount);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearCart() {
    state = state.copyWith(
      cartItems: [],
      discount: 0.0,
      paymentMethod: 'CASH',
      lastCreatedInvoice: null,
      errorMessage: null,
    );
  }

  Future<bool> checkoutCart({String notes = ''}) async {
    if (state.cartItems.isEmpty) {
      state = state.copyWith(errorMessage: 'Cart is empty');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, lastCreatedInvoice: null);
    try {
      final itemsPayload = state.cartItems.map((item) {
        final itemTotal = item.mrp * item.quantity;
        final gstRate = (item.medicine.gstPercentage ?? 12.0) / 100.0;
        final itemSubtotal = itemTotal / (1.0 + gstRate);
        final itemGst = itemTotal - itemSubtotal;
        
        return {
          'medicineId': item.medicine.id,
          'batchId': item.batchId,
          'quantity': item.quantity,
          'price': itemSubtotal,
          'mrp': item.mrp,
          'gst': itemGst,
          'total': itemTotal,
        };
      }).toList();

      final invoice = await _repository.createInvoice(
        items: itemsPayload,
        subtotal: state.cartSubtotal,
        discount: state.discount,
        gst: state.cartGst,
        total: state.cartTotal,
        paymentMethod: state.paymentMethod,
        notes: notes.trim(),
      );

      // Refresh inventory stock amounts so the main screen updates instantly!
      ref.read(inventoryNotifierProvider.notifier).loadInventory();
      
      // Reload billing list and analytics
      await loadInvoices();
      await loadAnalytics();

      state = state.copyWith(
        cartItems: [], // clear cart upon success
        discount: 0.0,
        lastCreatedInvoice: invoice,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<List<MedicineBatch>> fetchBatches(String medicineId) async {
    try {
      return await _repository.getBatches(medicineId);
    } catch (e) {
      debugPrint("Error fetching batches in BillingNotifier: $e");
      return [];
    }
  }

  Future<void> loadAnalytics() async {
    try {
      final summary = await _repository.getDailySummary();
      final breakdown = await _repository.getPaymentBreakdown();
      state = state.copyWith(
        dailySummary: summary,
        paymentBreakdown: breakdown,
      );
    } catch (e) {
      debugPrint("Error loading analytics: $e");
    }
  }

  Future<bool> cancelInvoice(String id, String reason) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.cancelInvoice(id: id, reason: reason);
      
      // Refresh inventory stock amounts so the main screen updates instantly!
      ref.read(inventoryNotifierProvider.notifier).loadInventory();
      
      // Reload invoices and analytics
      await loadInvoices();
      await loadAnalytics();
      
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

// Global Injectable BillingNotifier Provider
final billingNotifierProvider = NotifierProvider<BillingNotifier, BillingState>(BillingNotifier.new);

// Extension to expose local cart calculations
extension CartCalculations on BillingState {
  double get cartSubtotal {
    return cartItems.fold(0.0, (sum, item) => sum + (item.mrp * item.quantity));
  }

  double get cartGst {
    // Standard back-calculated GST (inclusive in MRP) or flat 12% estimation
    // Since MRP in Indian pharmacy is inclusive of all taxes, we back-calculate GST:
    // GST = Total - (Total / (1 + GST_Rate))
    return cartItems.fold(0.0, (sum, item) {
      final itemTotal = item.mrp * item.quantity;
      final gstRate = (item.medicine.gstPercentage ?? 12.0) / 100.0;
      final itemSubtotal = itemTotal / (1.0 + gstRate);
      return sum + (itemTotal - itemSubtotal);
    });
  }

  double get cartTotal {
    final sub = cartSubtotal;
    final tot = sub - discount;
    return tot < 0 ? 0.0 : tot;
  }
}
