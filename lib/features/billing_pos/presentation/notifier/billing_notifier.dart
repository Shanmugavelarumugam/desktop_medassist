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
  final Map<String, List<MedicineBatch>> _batchesCache = {};
  late BillingRepository _repository;

  @override
  BillingState build() {
    _repository = ref.watch(billingRepositoryProvider);
    Future.microtask(() {
      Future.wait([loadInvoices(), loadAnalytics()]);
    });
    return const BillingState();
  }

  Future<void> loadInvoices({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (!forceRefresh && state.invoices.isNotEmpty) {
      return;
    }
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
    print('ADDING TO CART');
    // ignore: avoid_print
    print('Medicine: ${medicine.name}');
    // ignore: avoid_print
    print('Medicine MRP: ${medicine.mrp}');
    // ignore: avoid_print
    print('Incoming MRP Parameter: $mrp');

    debugPrint('${medicine.name} | Qty=$quantity | Price=$mrp');
    final existingIndex = state.cartItems.indexWhere(
      (item) => item.batchId == batchId,
    );

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
      cartItems: state.cartItems
          .where((item) => item.batchId != batchId)
          .toList(),
    );
  }

  void updateQuantity(String batchId, int quantity) {
    state = state.copyWith(
      cartItems: state.cartItems.map((item) {
        if (item.batchId == batchId) {
          final finalQty = quantity > item.availableStock
              ? item.availableStock
              : (quantity < 1 ? 1 : quantity);
          return item.copyWith(quantity: finalQty);
        }
        return item;
      }).toList(),
    );
  }

  Future<void> updateMedicineTotalQuantity(
    String medicineId,
    int desiredTotalQty,
  ) async {
    final cartItemIndex = state.cartItems.indexWhere(
      (x) => x.medicine.id == medicineId,
    );
    if (cartItemIndex < 0) return;

    final targetItem = state.cartItems[cartItemIndex];
    final medicine = targetItem.medicine;

    if (desiredTotalQty <= 0) {
      final otherMedicinesItems = state.cartItems
          .where((x) => x.medicine.id != medicineId)
          .toList();
      state = state.copyWith(cartItems: otherMedicinesItems);
      return;
    }

    // Fetch and sort active batches
    final batches = await fetchBatches(medicineId);
    var validBatches = batches
        .where((b) => b.medicineId == medicineId && b.availableQuantity > 0)
        .toList();

    validBatches.sort((a, b) {
      final aExp = DateTime.tryParse(a.expiryDate) ?? DateTime(9999);
      final bExp = DateTime.tryParse(b.expiryDate) ?? DateTime(9999);
      return aExp.compareTo(bExp);
    });

    final totalStock = validBatches.fold(
      0,
      (sum, b) => sum + b.availableQuantity,
    );
    final finalTotalQty = desiredTotalQty > totalStock
        ? totalStock
        : desiredTotalQty;

    // Allocate finalTotalQty
    int remaining = finalTotalQty;
    final Map<String, int> allocations = {};
    for (final batch in validBatches) {
      if (remaining <= 0) break;
      final alloc = remaining > batch.availableQuantity
          ? batch.availableQuantity
          : remaining;
      allocations[batch.id] = alloc;
      remaining -= alloc;
    }

    // Rebuild cart items
    final otherMedicinesItems = state.cartItems
        .where((x) => x.medicine.id != medicineId)
        .toList();
    final List<CartItem> newCartItems = [...otherMedicinesItems];

    for (final entry in allocations.entries) {
      final batchId = entry.key;
      final qty = entry.value;
      final batch = validBatches.firstWhere((b) => b.id == batchId);

      newCartItems.add(
        CartItem(
          medicine: medicine,
          batchId: batch.id,
          batchNumber: batch.batchNumber,
          mrp: double.tryParse(batch.mrp.toString()) ?? medicine.mrp,
          quantity: qty,
          availableStock: batch.availableQuantity,
          expiryDate: batch.expiryDate,
        ),
      );
    }

    state = state.copyWith(cartItems: newCartItems);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount < 0 ? 0 : discount);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearCart() {
    _batchesCache.clear();
    state = state.copyWith(
      cartItems: [],
      discount: 0.0,
      paymentMethod: 'CASH',
      lastCreatedInvoice: null,
      errorMessage: null,
    );
  }

  Future<Invoice?> checkoutCart({
    required String patientName,
    required String patientPhone,
    String notes = '',
  }) async {
    if (state.cartItems.isEmpty) {
      state = state.copyWith(errorMessage: 'Cart is empty');
      return null;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      lastCreatedInvoice: null,
    );
    try {
      final itemsPayload = state.cartItems.map((item) {
        return {
          'medicineId': item.medicine.id,
          'batchId': item.batchId,
          'quantity': item.quantity,
          'unitPrice': item.mrp,
          'gstPercentage': item.medicine.gstPercentage ?? 12,
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
          'TOTAL=$itemTotal',
        );
      }

      final paymentsPayload = [
        {'paymentMode': state.paymentMethod, 'amount': state.cartTotal},
      ];

      final payload = {
        'patientName': patientName.trim().isEmpty
            ? 'Walk-in Customer'
            : patientName.trim(),
        'patientPhone': patientPhone.trim().isEmpty
            ? '9876543210'
            : patientPhone.trim(),
        'discountAmount': state.discount,
        'discountPercentage': 0,
        'paymentMode': state.paymentMethod,
        'items': itemsPayload,
        'payments': paymentsPayload,
        'notes': notes.trim(),
      };

      debugPrint('===== INVOICE PAYLOAD =====');
      debugPrint(jsonEncode(payload));

      final invoice = await _repository.createInvoice(
        items: itemsPayload,
        patientName: payload['patientName'] as String,
        patientPhone: payload['patientPhone'] as String,
        discountAmount: payload['discountAmount'] as double,
        paymentMode: payload['paymentMode'] as String,
        payments: paymentsPayload,
        notes: notes.trim(),
      );

      debugPrint('===== API SUCCESS RESPONSE =====');
      debugPrint('Invoice ID: ${invoice.id}');
      debugPrint('Invoice Number: ${invoice.invoiceNumber}');
      debugPrint('Response Subtotal: ${invoice.subtotal}');
      debugPrint('Response GST: ${invoice.gst}');
      debugPrint('Response Total: ${invoice.total}');

      // ── Cache Invalidation ──────────────────────────────────────────────────
      // Stock was just deducted in the backend.
      // 1. Clear the local batch cache.
      _batchesCache.clear();
      debugPrint('===== BATCH CACHE CLEARED (post-checkout) =====');

      // 2. Invalidate the Riverpod inventory provider so keepAlive screens
      //    are forced to rebuild with fresh state, not stale cached medicines.
      ref.invalidate(inventoryNotifierProvider);
      debugPrint('===== INVENTORY PROVIDER INVALIDATED (post-checkout) =====');

      // Wait one frame/tick for the invalidation/disposal to process
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Await a fresh inventory load so medicines are ready before the
      //    billing screen repaints.
      await ref
          .read(inventoryNotifierProvider.notifier)
          .loadInventory(forceRefresh: true);
      debugPrint('===== INVENTORY RELOADED (post-checkout) =====');

      // 4. Reload billing invoices and analytics.
      await loadInvoices(forceRefresh: true);
      await loadAnalytics(forceRefresh: true);

      state = state.copyWith(
        cartItems: [], // clear cart upon success
        discount: 0.0,
        lastCreatedInvoice: invoice,
        isLoading: false,
      );

      return invoice;
    } catch (e) {
      debugPrint('===== API ERROR =====');
      debugPrint(e.toString());
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<List<MedicineBatch>> fetchBatches(
    String medicineId, {
    bool forceRefresh = false,
  }) async {
    // Serve from local cache unless a force-refresh is requested.
    if (!forceRefresh && _batchesCache.containsKey(medicineId)) {
      debugPrint('===== BATCHES CACHE HIT (medId: $medicineId) =====');
      return _batchesCache[medicineId]!;
    }

    // Remove any stale entry so we don't accidentally serve it below.
    _batchesCache.remove(medicineId);

    // Only fall back to the inventory model cache when NOT force-refreshing.
    // After an invoice the inventory state has been invalidated and reloaded,
    // so this path would serve the freshly loaded batches correctly.
    if (!forceRefresh) {
      final inventoryState = ref.read(inventoryNotifierProvider);
      final medIndex = inventoryState.medicines.indexWhere(
        (m) => m.id == medicineId,
      );
      if (medIndex >= 0) {
        final med = inventoryState.medicines[medIndex];
        if (med.inventoryBatches != null && med.inventoryBatches!.isNotEmpty) {
          debugPrint(
            '===== BATCHES FROM INVENTORY MODEL (medId: $medicineId) =====',
          );
          _batchesCache[medicineId] = med.inventoryBatches!;
          return med.inventoryBatches!;
        }
      }
    }

    try {
      debugPrint('===== API CALL: GET BATCHES (medId: $medicineId) =====');
      final batches = await _repository.getBatches(medicineId);
      debugPrint('===== API SUCCESS: GET BATCHES =====');
      debugPrint('Loaded ${batches.length} batches');
      _batchesCache[medicineId] = batches;
      return batches;
    } catch (e) {
      debugPrint('===== API ERROR: GET BATCHES =====');
      debugPrint(e.toString());
      return [];
    }
  }

  Future<void> loadAnalytics({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        state.dailySummary.isNotEmpty &&
        state.paymentBreakdown.isNotEmpty) {
      return;
    }
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
      debugPrint(
        '===== API CALL: CANCEL INVOICE (id: $id, reason: $reason) =====',
      );
      await _repository.cancelInvoice(id: id, reason: reason);
      debugPrint('===== API SUCCESS: CANCEL INVOICE =====');

      // ── Cache Invalidation ──────────────────────────────────────────────────
      // Stock was restored to the backend on cancellation.
      // 1. Clear the local batch cache.
      _batchesCache.clear();
      debugPrint('===== BATCH CACHE CLEARED (post-cancel) =====');

      // 2. Invalidate the Riverpod inventory provider so keepAlive screens
      //    rebuild with restored stock quantities.
      ref.invalidate(inventoryNotifierProvider);
      debugPrint('===== INVENTORY PROVIDER INVALIDATED (post-cancel) =====');

      // 3. Await a fresh inventory load.
      await ref
          .read(inventoryNotifierProvider.notifier)
          .loadInventory(forceRefresh: true);
      debugPrint('===== INVENTORY RELOADED (post-cancel) =====');

      // 4. Reload invoices and analytics.
      await loadInvoices(forceRefresh: true);
      await loadAnalytics(forceRefresh: true);

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
final billingNotifierProvider = NotifierProvider<BillingNotifier, BillingState>(
  BillingNotifier.new,
);

class ActiveTemplateNotifier extends Notifier<String> {
  @override
  String build() => 'classic';

  void setTemplate(String templateId) {
    state = templateId;
  }
}

final activeTemplateProvider = NotifierProvider<ActiveTemplateNotifier, String>(
  ActiveTemplateNotifier.new,
);

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
