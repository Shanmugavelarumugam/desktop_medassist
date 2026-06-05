import 'dart:convert';
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
      debugPrint('===== API CALL: GET INVOICES =====');
      final invoices = await _repository.getInvoices();
      debugPrint('===== API SUCCESS: GET INVOICES =====');
      debugPrint('Loaded ${invoices.length} invoices');
      state = state.copyWith(invoices: invoices, isLoading: false);
    } catch (e) {
      debugPrint('===== API ERROR: GET INVOICES =====');
      debugPrint(e.toString());
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
    // ignore: avoid_print
    print('========================');
    // ignore: avoid_print
    print('ADDING TO CART');
    // ignore: avoid_print
    print('Medicine: ${medicine.name}');
    // ignore: avoid_print
    print('Medicine MRP: ${medicine.mrp}');
    // ignore: avoid_print
    print('Incoming MRP Parameter: $mrp');
    // ignore: avoid_print
    print('========================');

    debugPrint('${medicine.name} | Qty=$quantity | Price=$mrp');
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

      // ignore: avoid_print
      print('CART ITEM CREATED');
      // ignore: avoid_print
      print('MRP: ${newItem.mrp}');
      // ignore: avoid_print
      print('Qty: ${newItem.quantity}');

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
        final unitTotal = item.mrp;
        final gstRate = (item.medicine.gstPercentage ?? 12.0) / 100.0;
        final unitSubtotal = unitTotal / (1.0 + gstRate);
        final unitGst = unitTotal - unitSubtotal;
        
        return {
          'medicineId': item.medicine.id,
          'batchId': item.batchId,
          'quantity': item.quantity,
          'qty': item.quantity,
          'price': unitSubtotal,
          'unitPrice': unitSubtotal,
          'mrp': item.mrp,
          'gst': unitGst,
          'gstAmount': unitGst,
          'total': unitTotal,
          'totalPrice': unitTotal,
        };
      }).toList();

      for (final item in state.cartItems) {
        final itemTotal = item.mrp * item.quantity;
        final gstRate = (item.medicine.gstPercentage ?? 12.0) / 100.0;
        final itemSubtotal = itemTotal / (1.0 + gstRate);
        debugPrint(
          'MED=${item.medicine.name} '
          'QTY=${item.quantity} '
          'PRICE=$itemSubtotal '
          'MRP=${item.mrp} '
          'TOTAL=$itemTotal'
        );
      }

      final payload = {
        'subtotal': state.cartSubtotal,
        'discount': state.discount,
        'gst': state.cartGst,
        'total': state.cartTotal,
        'items': itemsPayload,
      };

      debugPrint('===== INVOICE PAYLOAD =====');
      debugPrint(jsonEncode(payload));

      final invoice = await _repository.createInvoice(
        items: itemsPayload,
        subtotal: state.cartSubtotal,
        discount: state.discount,
        gst: state.cartGst,
        total: state.cartTotal,
        paymentMethod: state.paymentMethod,
        notes: notes.trim(),
      );

      debugPrint('===== API SUCCESS RESPONSE =====');
      debugPrint('Invoice ID: ${invoice.id}');
      debugPrint('Invoice Number: ${invoice.invoiceNumber}');
      debugPrint('Response Subtotal: ${invoice.subtotal}');
      debugPrint('Response GST: ${invoice.gst}');
      debugPrint('Response Total: ${invoice.total}');

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
      debugPrint('===== API ERROR =====');
      debugPrint(e.toString());
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<List<MedicineBatch>> fetchBatches(String medicineId) async {
    try {
      debugPrint('===== API CALL: GET BATCHES (medId: $medicineId) =====');
      final batches = await _repository.getBatches(medicineId);
      debugPrint('===== API SUCCESS: GET BATCHES =====');
      debugPrint('Loaded ${batches.length} batches');
      return batches;
    } catch (e) {
      debugPrint('===== API ERROR: GET BATCHES =====');
      debugPrint(e.toString());
      return [];
    }
  }

  Future<void> loadAnalytics() async {
    try {
      debugPrint('===== API CALL: GET ANALYTICS =====');
      final summary = await _repository.getDailySummary();
      final breakdown = await _repository.getPaymentBreakdown();
      debugPrint('===== API SUCCESS: GET ANALYTICS =====');
      debugPrint('Daily Summary: $summary');
      debugPrint('Payment Breakdown: $breakdown');
      state = state.copyWith(
        dailySummary: summary,
        paymentBreakdown: breakdown,
      );
    } catch (e) {
      debugPrint('===== API ERROR: GET ANALYTICS =====');
      debugPrint(e.toString());
    }
  }

  Future<bool> cancelInvoice(String id, String reason) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      debugPrint('===== API CALL: CANCEL INVOICE (id: $id, reason: $reason) =====');
      await _repository.cancelInvoice(id: id, reason: reason);
      debugPrint('===== API SUCCESS: CANCEL INVOICE =====');
      
      // Refresh inventory stock amounts so the main screen updates instantly!
      ref.read(inventoryNotifierProvider.notifier).loadInventory();
      
      // Reload invoices and analytics
      await loadInvoices();
      await loadAnalytics();
      
      return true;
    } catch (e) {
      debugPrint('===== API ERROR: CANCEL INVOICE =====');
      debugPrint(e.toString());
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
    // Calculate true pre-tax subtotal (sum of item base prices)
    return cartItems.fold(0.0, (sum, item) {
      final itemTotal = item.mrp * item.quantity;
      final gstRate = (item.medicine.gstPercentage ?? 12.0) / 100.0;
      final itemSubtotal = itemTotal / (1.0 + gstRate);
      return sum + itemSubtotal;
    });
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
    // Grand total = base subtotal + gst - discount
    final sub = cartSubtotal;
    final gst = cartGst;
    final tot = sub + gst - discount;
    return tot < 0 ? 0.0 : tot;
  }
}
