import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../notifier/billing_notifier.dart';
import '../state/billing_state.dart';
import '../../domain/models/invoice.dart';
import '../../utils/invoice_printer.dart';

// ─── Intents ──────────────────────────────────────────────────────────────────
class SearchIntent extends Intent {
  const SearchIntent();
}

class PaymentIntent extends Intent {
  const PaymentIntent();
}

class CheckoutIntent extends Intent {
  const CheckoutIntent();
}

class DiscountIntent extends Intent {
  const DiscountIntent();
}

class CashIntent extends Intent {
  const CashIntent();
}

class UpiIntent extends Intent {
  const UpiIntent();
}

class CardIntent extends Intent {
  const CardIntent();
}

class NewBillIntent extends Intent {
  const NewBillIntent();
}

class HoldBillIntent extends Intent {
  const HoldBillIntent();
}

class ReturnBillIntent extends Intent {
  const ReturnBillIntent();
}

class DeleteItemIntent extends Intent {
  const DeleteItemIntent();
}

class QuantityEditIntent extends Intent {
  const QuantityEditIntent();
}

class ToggleHudIntent extends Intent {
  const ToggleHudIntent();
}

class ChangeBatchIntent extends Intent {
  const ChangeBatchIntent();
}

class BillingPosScreen extends ConsumerStatefulWidget {
  const BillingPosScreen({super.key});

  @override
  ConsumerState<BillingPosScreen> createState() => _BillingPosScreenState();
}

class _BillingPosScreenState extends ConsumerState<BillingPosScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _receivedAmountController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _receivedFocusNode = FocusNode();
  final FocusNode _discountFocusNode = FocusNode();
  final FocusNode _rootFocusNode = FocusNode();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _discountType = '₹ Flat';
  double _receivedAmount = 0.0;
  int _selectedProductIndex = 0;
  int _selectedCartIndex = -1; // -1 = nothing selected
  bool _showHud = false;
  bool _stockWarningShown = false;
  bool _isUpdatingQty = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final currentMedicines = ref.read(inventoryNotifierProvider).medicines;
      if (currentMedicines.isEmpty) {
        ref.read(inventoryNotifierProvider.notifier).loadInventory(limit: 1000);
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _selectedProductIndex = 0;
      });
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref
              .read(inventoryNotifierProvider.notifier)
              .loadInventory(search: _searchController.text, limit: 1000);
        }
      });
    });

    _discountController.addListener(_updateDiscount);
    _receivedAmountController.addListener(() {
      setState(() {
        _receivedAmount =
            double.tryParse(_receivedAmountController.text) ?? 0.0;
      });
    });

    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        final state = ref.read(inventoryNotifierProvider);
        var filteredMeds = state.medicines.where((m) {
          final matchesSearch =
              m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (m.genericName != null &&
                  m.genericName!.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  )) ||
              (m.barcode != null && m.barcode == _searchQuery);
          final matchesCategory =
              _selectedCategory == 'All' || m.categoryId == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _searchController.clear();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            if (_selectedProductIndex + 2 < filteredMeds.length) {
              _selectedProductIndex += 2;
            } else {
              _selectedProductIndex = filteredMeds.length - 1;
            }
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            if (_selectedProductIndex - 2 >= 0) {
              _selectedProductIndex -= 2;
            } else {
              _selectedProductIndex = 0;
            }
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          setState(() {
            if (_selectedProductIndex < filteredMeds.length - 1) {
              _selectedProductIndex++;
            }
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          setState(() {
            if (_selectedProductIndex > 0) {
              _selectedProductIndex--;
            }
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (filteredMeds.isNotEmpty &&
              _selectedProductIndex >= 0 &&
              _selectedProductIndex < filteredMeds.length) {
            final med = filteredMeds[_selectedProductIndex];
            if (med.stock > 0) {
              _handleProductAdd(med);
            }
          }
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _updateDiscount() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _discountController.dispose();
    _notesController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _doctorNameController.dispose();
    _receivedAmountController.dispose();
    _searchFocusNode.dispose();
    _receivedFocusNode.dispose();
    _discountFocusNode.dispose();
    _rootFocusNode.dispose();
    super.dispose();
  }

  void _applyCalculatedDiscount() {
    final rawVal = double.tryParse(_discountController.text) ?? 0.0;
    final state = ref.read(billingNotifierProvider);
    double effectiveDiscount = 0.0;
    if (_discountType == '% Percent') {
      final sub = state.cartSubtotal + state.cartGst;
      effectiveDiscount = sub * (rawVal / 100.0);
    } else {
      effectiveDiscount = rawVal;
    }

    Future.microtask(() {
      ref.read(billingNotifierProvider.notifier).setDiscount(effectiveDiscount);
    });
  }

  // ─── Add medicine to cart — always FEFO auto-pick, never shows popup ─────────
  void _handleProductAdd(Medicine medicine) async {
    final batches = await ref
        .read(billingNotifierProvider.notifier)
        .fetchBatches(medicine.id);
    if (!mounted) return;

    var validBatches = batches
        .where((b) => b.medicineId == medicine.id && b.availableQuantity > 0)
        .toList();

    // Remove expired batches
    validBatches = validBatches.where((b) {
      final expiry = DateTime.tryParse(b.expiryDate);
      if (expiry == null) return false;
      return !expiry.isBefore(DateTime.now());
    }).toList();

    if (validBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active stock batches found for this medicine.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Always auto-pick FEFO (First Expiry First Out) — no popup ever
    validBatches.sort((a, b) {
      final aExp = DateTime.tryParse(a.expiryDate) ?? DateTime(9999);
      final bExp = DateTime.tryParse(b.expiryDate) ?? DateTime(9999);
      return aExp.compareTo(bExp);
    });

    // Find the first active batch that still has unallocated stock in the cart
    final state = ref.read(billingNotifierProvider);
    MedicineBatch? targetBatch;

    for (final batch in validBatches) {
      final existingIndex = state.cartItems.indexWhere(
        (item) => item.batchId == batch.id,
      );
      final existingQty = existingIndex >= 0
          ? state.cartItems[existingIndex].quantity
          : 0;
      if (existingQty < batch.availableQuantity) {
        targetBatch = batch;
        break;
      }
    }

    if (targetBatch == null) {
      final totalActiveStock = validBatches.fold(
        0,
        (sum, b) => sum + b.availableQuantity,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot add more quantity. All active stock ($totalActiveStock) is already in the cart.',
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ref
        .read(billingNotifierProvider.notifier)
        .addToCart(
          medicine: medicine,
          batchId: targetBatch.id,
          batchNumber: targetBatch.batchNumber,
          mrp: double.tryParse(targetBatch.mrp.toString()) ?? 0.0,
          quantity: 1,
          availableStock: targetBatch.availableQuantity,
          expiryDate: targetBatch.expiryDate,
        );
    _searchController.clear();

    // Select the newly added or updated item row in the cart
    final updatedCart = ref.read(billingNotifierProvider).cartItems;
    final targetIndex = updatedCart.indexWhere(
      (item) => item.batchId == targetBatch!.id,
    );
    if (targetIndex >= 0) {
      setState(() => _selectedCartIndex = targetIndex);
    }
    _searchFocusNode.requestFocus();
  }

  void _showStockLimitSnackbar() {
    if (_stockWarningShown || !mounted) return;

    _stockWarningShown = true;

    final messenger = ScaffoldMessenger.of(context);

    // remove queued snackbars
    messenger.clearSnackBars();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Maximum available stock already added'),
        backgroundColor: Color(0xFFEF4444),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _stockWarningShown = false;
      }
    });
  }

  void _updateCartItemQuantity(CartItem item, int newQty) async {
    if (_isUpdatingQty) return;
    _isUpdatingQty = true;

    try {
      final totalAvailableStock = _getTotalActiveStock(item.medicine);
      if (newQty > totalAvailableStock) {
        _showStockLimitSnackbar();
        return;
      }

      if (newQty < 1) {
        ref.read(billingNotifierProvider.notifier).removeFromCart(item.batchId);
      } else {
        await ref
            .read(billingNotifierProvider.notifier)
            .updateMedicineTotalQuantity(item.medicine.id, newQty);
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _isUpdatingQty = false;
        }
      });
    }
  }

  MedicineBatch? _getRecommendedBatch(Medicine med) {
    if (med.inventoryBatches == null || med.inventoryBatches!.isEmpty) {
      return null;
    }
    var validBatches = med.inventoryBatches!
        .where((b) => b.availableQuantity > 0)
        .toList();

    // Remove expired batches
    validBatches = validBatches.where((b) {
      final expiry = DateTime.tryParse(b.expiryDate);
      if (expiry == null) return false;
      return !expiry.isBefore(DateTime.now());
    }).toList();

    if (validBatches.isEmpty) {
      return null;
    }

    // Sort by FEFO
    validBatches.sort((a, b) {
      final aExp = DateTime.tryParse(a.expiryDate) ?? DateTime(9999);
      final bExp = DateTime.tryParse(b.expiryDate) ?? DateTime(9999);
      return aExp.compareTo(bExp);
    });
    return validBatches.first;
  }

  int _getTotalActiveStock(Medicine med) {
    if (med.inventoryBatches == null || med.inventoryBatches!.isEmpty) {
      return 0;
    }
    var validBatches = med.inventoryBatches!
        .where((b) => b.availableQuantity > 0)
        .toList();

    // Remove expired batches
    validBatches = validBatches.where((b) {
      final expiry = DateTime.tryParse(b.expiryDate);
      if (expiry == null) return false;
      return !expiry.isBefore(DateTime.now());
    }).toList();

    return validBatches.fold(0, (sum, b) => sum + b.availableQuantity);
  }

  // ─── Quick Quantity Edit Dialog ──────────────────────────────────────────────
  void _showQuantityEditDialog() {
    final state = ref.read(billingNotifierProvider);
    if (state.cartItems.isEmpty) return;

    final idx =
        (_selectedCartIndex >= 0 && _selectedCartIndex < state.cartItems.length)
        ? _selectedCartIndex
        : state.cartItems.length - 1;

    final item = state.cartItems[idx];
    final qtyController = TextEditingController(text: '${item.quantity}');
    final focusNode = FocusNode();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF0D9488),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Edit Quantity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.medicine.name,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        content: Focus(
          focusNode: focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(ctx).pop();
                _searchFocusNode.requestFocus();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Enter quantity',
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFF94A3B8),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF0D9488),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF0D9488),
                  width: 2.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              helperText: 'Press Enter to confirm • Esc to cancel',
              helperStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
            onSubmitted: (val) {
              final newQty = int.tryParse(val) ?? item.quantity;
              final totalAvailableStock = _getTotalActiveStock(item.medicine);
              if (newQty > totalAvailableStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Maximum available stock is $totalAvailableStock',
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    duration: const Duration(seconds: 2),
                  ),
                );
                _updateCartItemQuantity(item, totalAvailableStock);
              } else if (newQty > 0) {
                _updateCartItemQuantity(item, newQty);
              }
              Navigator.of(ctx).pop();
              _searchFocusNode.requestFocus();
            },
          ),
        ),
      ),
    ).then((_) {
      qtyController.dispose();
      _searchFocusNode.requestFocus();
    });
  }

  // ─── New Bill ────────────────────────────────────────────────────────────────
  void _startNewBill() {
    ref.read(billingNotifierProvider.notifier).clearCart();
    _discountController.text = '0';
    _notesController.clear();
    _customerNameController.clear();
    _customerPhoneController.clear();
    _doctorNameController.clear();
    _receivedAmountController.clear();
    _searchController.clear();
    setState(() => _selectedCartIndex = -1);
    _searchFocusNode.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New bill started'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  // ─── Delete selected cart item ───────────────────────────────────────────────
  void _deleteSelectedCartItem() {
    final state = ref.read(billingNotifierProvider);
    if (state.cartItems.isEmpty) return;

    final idx =
        (_selectedCartIndex >= 0 && _selectedCartIndex < state.cartItems.length)
        ? _selectedCartIndex
        : state.cartItems.length - 1;

    final item = state.cartItems[idx];
    ref.read(billingNotifierProvider.notifier).removeFromCart(item.batchId);
    setState(() {
      final newLen = state.cartItems.length - 1;
      _selectedCartIndex = newLen > 0 ? (idx < newLen ? idx : newLen - 1) : -1;
    });
    _searchFocusNode.requestFocus();
  }

  // ─── Change Batch Dialog (from cart item) ────────────────────────────────────
  // Called when staff taps the batch badge in cart or presses B.
  // Fetches all valid batches for that cart item's medicine and lets staff
  // switch to a different one. FEFO batch is pre-highlighted.
  void _showBatchChangerDialog(CartItem cartItem) async {
    final batches = await ref
        .read(billingNotifierProvider.notifier)
        .fetchBatches(cartItem.medicine.id);
    if (!mounted) return;

    var validBatches = batches
        .where(
          (b) =>
              b.medicineId == cartItem.medicine.id && b.availableQuantity > 0,
        )
        .toList();

    validBatches = validBatches.where((b) {
      final expiry = DateTime.tryParse(b.expiryDate);
      if (expiry == null) return false;
      return !expiry.isBefore(DateTime.now());
    }).toList();

    if (validBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other batches available.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Sort FEFO
    validBatches.sort((a, b) {
      final aExp = DateTime.tryParse(a.expiryDate) ?? DateTime(9999);
      final bExp = DateTime.tryParse(b.expiryDate) ?? DateTime(9999);
      return aExp.compareTo(bExp);
    });

    // Pre-select currently active batch
    int selectedBatchIndex = validBatches.indexWhere(
      (b) => b.id == cartItem.batchId,
    );
    if (selectedBatchIndex < 0) selectedBatchIndex = 0;

    final focusNode = FocusNode();

    void confirmBatch(BuildContext ctx, MedicineBatch batch) {
      Navigator.of(ctx).pop();
      // Remove old batch entry and re-add with new batch, preserving quantity
      ref
          .read(billingNotifierProvider.notifier)
          .removeFromCart(cartItem.batchId);
      ref
          .read(billingNotifierProvider.notifier)
          .addToCart(
            medicine: cartItem.medicine,
            batchId: batch.id,
            batchNumber: batch.batchNumber,
            mrp: double.tryParse(batch.mrp.toString()) ?? 0.0,
            quantity: cartItem.quantity,
            availableStock: batch.availableQuantity,
            expiryDate: batch.expiryDate,
          );
      _searchFocusNode.requestFocus();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF0D9488),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Batch',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            cartItem.medicine.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Keyboard hint bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _hudKey('↑↓', 'Navigate'),
                      _hudKey('1–${validBatches.length}', 'Quick pick'),
                      _hudKey('↵', 'Select'),
                      _hudKey('Esc', 'Cancel'),
                    ],
                  ),
                ),
              ],
            ),
            content: Focus(
              focusNode: focusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent || event is KeyRepeatEvent) {
                  // ↑↓ navigate
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (selectedBatchIndex < validBatches.length - 1) {
                      setDialogState(() => selectedBatchIndex++);
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (selectedBatchIndex > 0) {
                      setDialogState(() => selectedBatchIndex--);
                    }
                    return KeyEventResult.handled;
                  }
                  // Enter confirms
                  else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    confirmBatch(ctx, validBatches[selectedBatchIndex]);
                    return KeyEventResult.handled;
                  }
                  // Esc cancels
                  else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(ctx).pop();
                    _searchFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  // Number keys 1–9 for quick pick
                  else if (event.character != null) {
                    final num = int.tryParse(event.character!);
                    if (num != null && num >= 1 && num <= validBatches.length) {
                      confirmBatch(ctx, validBatches[num - 1]);
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: SizedBox(
                width: 420,
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: validBatches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final batch = validBatches[index];
                    final expiryDate = DateTime.parse(batch.expiryDate);
                    final now = DateTime.now();
                    final daysToExpiry = expiryDate.difference(now).inDays;
                    final nearExpiry = daysToExpiry <= 30;
                    final formattedExpiry = DateFormat(
                      'MMM yyyy',
                    ).format(expiryDate);
                    final batchMrp =
                        double.tryParse(batch.mrp.toString()) ?? 0.0;
                    final isSelected = index == selectedBatchIndex;
                    final isCurrent = batch.id == cartItem.batchId;

                    return InkWell(
                      onTap: () => confirmBatch(ctx, batch),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0D9488)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Number key badge
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        batch.batchNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isSelected
                                              ? const Color(0xFF0D9488)
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF64748B,
                                            ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          child: const Text(
                                            'CURRENT',
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (!isCurrent && index == 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D9488),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          child: const Text(
                                            'FEFO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        'Exp: $formattedExpiry',
                                        style: TextStyle(
                                          color: nearExpiry
                                              ? Colors.orange
                                              : const Color(0xFF64748B),
                                          fontSize: 11,
                                          fontWeight: nearExpiry
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      const Text(
                                        ' · ',
                                        style: TextStyle(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      Text(
                                        'Stock: ${batch.availableQuantity}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${batchMrp.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isSelected
                                      ? '↵ Select'
                                      : 'Tap / ${index + 1}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _searchFocusNode.requestFocus();
                },
                child: const Text(
                  'Cancel (Esc)',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) => _searchFocusNode.requestFocus());
  }

  // Small key+label widget used in dialog hint bar
  Widget _hudKey(String key, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // ─── Checkout Success Dialog ─────────────────────────────────────────────────
  void _showCheckoutSuccessDialog(Invoice invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        const primaryTeal = Color(0xFF0F766E);
        const textDark = Color(0xFF0F172A);

        final cgst = invoice.gst / 2;
        final sgst = invoice.gst / 2;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'VIYAN MEDASSIST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '123, Healthcare Street, Medical Hub, Bangalore',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'GSTIN: 29ABCDE1234F1Z1 | Ph: +91 98765 43210',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text: 'INVOICE # ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: invoice.invoiceNumber),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text: 'DATE: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: () {
                                try {
                                  return DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(
                                    DateTime.parse(invoice.date).toLocal(),
                                  );
                                } catch (_) {
                                  return invoice.date;
                                }
                              }(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(
                          text: 'PATIENT: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: invoice.patientName.isNotEmpty
                              ? invoice.patientName
                              : 'Walk-in Customer',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(
                          text: 'PHONE: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: invoice.patientPhone.isNotEmpty
                              ? invoice.patientPhone
                              : '',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.black, thickness: 1.5),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Medicine',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Qty',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'MRP',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Total',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.black, thickness: 1.5),

                  // Group items by medicine name for clean consolidated receipt view (hides raw split batches)
                  ...() {
                    final seen = <String>{};
                    final groups = <String, List<dynamic>>{};
                    for (final item in invoice.items) {
                      if (!seen.contains(item.name)) {
                        seen.add(item.name);
                        groups[item.name] = [];
                      }
                      groups[item.name]!.add(item);
                    }

                    final widgets = <Widget>[];
                    for (final name in seen) {
                      final groupItems = groups[name]!;

                      final int totalQty = groupItems.fold(
                        0,
                        (sum, x) => sum + (x.qty as int),
                      );
                      final double totalVal = groupItems.fold(
                        0.0,
                        (sum, x) =>
                            sum + (double.tryParse(x.total.toString()) ?? 0.0),
                      );
                      final double effectiveMrp = totalQty > 0
                          ? (totalVal / totalQty)
                          : 0.0;

                      widgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  totalQty.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₹${effectiveMrp.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₹${totalVal.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      widgets.add(
                        const Divider(color: Color(0xFFF1F5F9), height: 8),
                      );
                    }
                    return widgets;
                  }(),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 250,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '₹${invoice.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'CGST',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '₹${cgst.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SGST',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '₹${sgst.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            if (invoice.discount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Discount',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    '-₹${invoice.discount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Divider(color: Colors.black, thickness: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '₹${invoice.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.black, thickness: 1),
                  const SizedBox(height: 24),
                  const Text(
                    'Thank you for visiting! Get well soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 48),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => InvoicePrinter.printInvoice(invoice),
                          icon: const Icon(Icons.print_outlined, size: 20),
                          label: const Text(
                            'Print Receipt',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textDark,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _startNewBill();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'New Sale (Ctrl+N)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _triggerCheckout() async {
    final notifier = ref.read(billingNotifierProvider.notifier);
    final state = ref.read(billingNotifierProvider);

    if (state.cartItems.isEmpty || state.isLoading) return;

    List<String> combinedNotes = [];
    if (_doctorNameController.text.trim().isNotEmpty) {
      combinedNotes.add('Doctor: ${_doctorNameController.text.trim()}');
    }
    if (_notesController.text.trim().isNotEmpty) {
      combinedNotes.add('Notes: ${_notesController.text.trim()}');
    }

    final finalNotes = combinedNotes.join(' | ');
    _applyCalculatedDiscount();

    final invoice = await notifier.checkoutCart(
      patientName: _customerNameController.text.trim(),
      patientPhone: _customerPhoneController.text.trim(),
      notes: finalNotes,
    );

    if (mounted) {
      if (invoice != null) {
        _showCheckoutSuccessDialog(invoice);
      } else {
        final error =
            ref.read(billingNotifierProvider).errorMessage ?? 'Checkout failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF8FAFC);

    final inventoryState = ref.watch(inventoryNotifierProvider);
    final allMedicines = inventoryState.medicines;
    final allCategories = inventoryState.categories;
    final isInventoryLoading = inventoryState.isLoading;
    final state = ref.watch(billingNotifierProvider);

    _applyCalculatedDiscount();

    final filteredMeds = allMedicines.where((med) {
      if (_selectedCategory != 'All' && med.categoryId != _selectedCategory)
        return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return med.name.toLowerCase().contains(q) ||
          (med.genericName != null &&
              med.genericName!.toLowerCase().contains(q)) ||
          (med.batchNumber != null &&
              med.batchNumber!.toLowerCase().contains(q));
    }).toList();

    // Clamp selected cart index
    if (state.cartItems.isNotEmpty &&
        _selectedCartIndex >= state.cartItems.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedCartIndex = state.cartItems.length - 1);
      });
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.f2): const SearchIntent(),
        const SingleActivator(LogicalKeyboardKey.f4): const PaymentIntent(),
        const SingleActivator(LogicalKeyboardKey.f5): const CashIntent(),
        const SingleActivator(LogicalKeyboardKey.f6): const UpiIntent(),
        const SingleActivator(LogicalKeyboardKey.f7): const CardIntent(),
        const SingleActivator(LogicalKeyboardKey.f8): const CheckoutIntent(),
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            const DiscountIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const NewBillIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            const HoldBillIntent(),
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            const ReturnBillIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const DeleteItemIntent(),
        const SingleActivator(LogicalKeyboardKey.keyQ):
            const QuantityEditIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB):
            const ChangeBatchIntent(),
        const SingleActivator(LogicalKeyboardKey.slash, shift: true):
            const ToggleHudIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (_) {
              _searchFocusNode.requestFocus();
              return null;
            },
          ),
          PaymentIntent: CallbackAction<PaymentIntent>(
            onInvoke: (_) {
              _receivedFocusNode.requestFocus();
              return null;
            },
          ),
          CashIntent: CallbackAction<CashIntent>(
            onInvoke: (_) {
              ref
                  .read(billingNotifierProvider.notifier)
                  .setPaymentMethod('CASH');
              Future.delayed(
                const Duration(milliseconds: 100),
                () => _receivedFocusNode.requestFocus(),
              );
              return null;
            },
          ),
          UpiIntent: CallbackAction<UpiIntent>(
            onInvoke: (_) {
              ref
                  .read(billingNotifierProvider.notifier)
                  .setPaymentMethod('UPI');
              return null;
            },
          ),
          CardIntent: CallbackAction<CardIntent>(
            onInvoke: (_) {
              ref
                  .read(billingNotifierProvider.notifier)
                  .setPaymentMethod('CARD');
              return null;
            },
          ),
          CheckoutIntent: CallbackAction<CheckoutIntent>(
            onInvoke: (_) {
              _triggerCheckout();
              return null;
            },
          ),
          DiscountIntent: CallbackAction<DiscountIntent>(
            onInvoke: (_) {
              _discountFocusNode.requestFocus();
              return null;
            },
          ),
          NewBillIntent: CallbackAction<NewBillIntent>(
            onInvoke: (_) {
              _startNewBill();
              return null;
            },
          ),
          HoldBillIntent: CallbackAction<HoldBillIntent>(
            onInvoke: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hold Bill — coming soon'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF475569),
                ),
              );
              return null;
            },
          ),
          ReturnBillIntent: CallbackAction<ReturnBillIntent>(
            onInvoke: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Return Bill — coming soon'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF475569),
                ),
              );
              return null;
            },
          ),
          DeleteItemIntent: CallbackAction<DeleteItemIntent>(
            onInvoke: (_) {
              _deleteSelectedCartItem();
              return null;
            },
          ),
          QuantityEditIntent: CallbackAction<QuantityEditIntent>(
            onInvoke: (_) {
              if (!_searchFocusNode.hasFocus) {
                _showQuantityEditDialog();
              }
              return null;
            },
          ),
          ChangeBatchIntent: CallbackAction<ChangeBatchIntent>(
            onInvoke: (_) {
              final cartState = ref.read(billingNotifierProvider);
              if (cartState.cartItems.isEmpty) return null;
              final idx =
                  (_selectedCartIndex >= 0 &&
                      _selectedCartIndex < cartState.cartItems.length)
                  ? _selectedCartIndex
                  : cartState.cartItems.length - 1;
              _showBatchChangerDialog(cartState.cartItems[idx]);
              return null;
            },
          ),
          ToggleHudIntent: CallbackAction<ToggleHudIntent>(
            onInvoke: (_) {
              setState(() => _showHud = !_showHud);
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: FocusScope(
            autofocus: true,
            child: Stack(
              children: [
                // ─── Main UI ────────────────────────────────────────────────
                Container(
                  color: bgGrey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ════ LEFT PANEL ════════════════════════════════════════
                      Expanded(
                        flex: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              right: BorderSide(color: borderGrey, width: 1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer Details
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PRESCRIPTION / CUSTOMER DETAILS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: softGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FocusTraversalOrder(
                                            order: const NumericFocusOrder(1),
                                            child: TextFormField(
                                              controller:
                                                  _customerNameController,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Customer Name (Walk-in)',
                                                hintStyle: const TextStyle(
                                                  fontSize: 13,
                                                  color: softGrey,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FocusTraversalOrder(
                                            order: const NumericFocusOrder(2),
                                            child: TextFormField(
                                              controller:
                                                  _customerPhoneController,
                                              keyboardType: TextInputType.phone,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Mobile No.',
                                                hintStyle: const TextStyle(
                                                  fontSize: 13,
                                                  color: softGrey,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    FocusTraversalOrder(
                                      order: const NumericFocusOrder(3),
                                      child: TextFormField(
                                        controller: _doctorNameController,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Doctor Name (Optional)',
                                          hintStyle: const TextStyle(
                                            fontSize: 13,
                                            color: softGrey,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: borderGrey),

                              // Cart Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                color: bgGrey,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Checkout Cart',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                    if (state.cartItems.isNotEmpty)
                                      InkWell(
                                        onTap: () {
                                          ref
                                              .read(
                                                billingNotifierProvider
                                                    .notifier,
                                              )
                                              .clearCart();
                                          _discountController.text = '0';
                                          setState(
                                            () => _selectedCartIndex = -1,
                                          );
                                        },
                                        child: const Text(
                                          'Clear All',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: borderGrey),

                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: Colors.white,
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Medicine',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: softGrey,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: softGrey,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Total',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: softGrey,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 24),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: borderGrey),

                              // Cart Items
                              Expanded(
                                child: state.cartItems.isEmpty
                                    ? Center(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.add_shopping_cart_rounded,
                                                size: 56,
                                                color: Color(0xFFE2E8F0),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                '🛒 Cart is Empty',
                                                style: TextStyle(
                                                  color: textDark,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Start typing medicine name (F2)',
                                                style: TextStyle(
                                                  color: softGrey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'or Scan barcode to add item',
                                                style: TextStyle(
                                                  color: softGrey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: state.cartItems.length,
                                        separatorBuilder: (_, _) =>
                                            const Divider(
                                              height: 1,
                                              color: borderGrey,
                                            ),
                                        itemBuilder: (context, index) {
                                          final item = state.cartItems[index];
                                          final totalItemPrice =
                                              item.mrp * item.quantity;
                                          final isCartSelected =
                                              index == _selectedCartIndex;
                                          final firstIndex = state.cartItems
                                              .indexWhere(
                                                (x) =>
                                                    x.medicine.id ==
                                                    item.medicine.id,
                                              );
                                          final isDuplicateBatch =
                                              firstIndex >= 0 &&
                                              firstIndex != index;
                                          final totalAvailableStock =
                                              _getTotalActiveStock(
                                                item.medicine,
                                              );
                                          final currentTotal = state.cartItems
                                              .where(
                                                (x) =>
                                                    x.medicine.id ==
                                                    item.medicine.id,
                                              )
                                              .fold(
                                                0,
                                                (sum, x) => sum + x.quantity,
                                              );
                                          final canIncrease =
                                              currentTotal <
                                              totalAvailableStock;

                                          return GestureDetector(
                                            onTap: () => setState(
                                              () => _selectedCartIndex = index,
                                            ),
                                            child: Focus(
                                              onKeyEvent: (node, event) {
                                                if (event is KeyDownEvent) {
                                                  if (event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .numpadAdd ||
                                                      event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .equal ||
                                                      event.character == '+') {
                                                    if (canIncrease) {
                                                      _updateCartItemQuantity(
                                                        item,
                                                        currentTotal + 1,
                                                      );
                                                    }
                                                    return KeyEventResult
                                                        .handled;
                                                  } else if (event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .numpadSubtract ||
                                                      event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .minus ||
                                                      event.character == '-') {
                                                    _updateCartItemQuantity(
                                                      item,
                                                      currentTotal - 1,
                                                    );
                                                    return KeyEventResult
                                                        .handled;
                                                  } else if (event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .delete ||
                                                      event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .backspace) {
                                                    ref
                                                        .read(
                                                          billingNotifierProvider
                                                              .notifier,
                                                        )
                                                        .removeFromCart(
                                                          item.batchId,
                                                        );
                                                    return KeyEventResult
                                                        .handled;
                                                  }
                                                }
                                                return KeyEventResult.ignored;
                                              },
                                              child: Builder(
                                                builder: (context) {
                                                  final isFocused = Focus.of(
                                                    context,
                                                  ).hasFocus;
                                                  return Container(
                                                    // Denser row padding
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 7,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isCartSelected
                                                          ? primaryTeal
                                                                .withValues(
                                                                  alpha: 0.07,
                                                                )
                                                          : isFocused
                                                          ? primaryTeal
                                                                .withValues(
                                                                  alpha: 0.04,
                                                                )
                                                          : Colors.transparent,
                                                      border: Border(
                                                        left: BorderSide(
                                                          color: isCartSelected
                                                              ? primaryTeal
                                                              : Colors
                                                                    .transparent,
                                                          width: 3,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        // ── Medicine name + batch badge ──────────────────
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              // Row 1: selection dot + name
                                                              Row(
                                                                children: [
                                                                  if (isCartSelected)
                                                                    Container(
                                                                      margin: const EdgeInsets.only(
                                                                        right:
                                                                            5,
                                                                      ),
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            3,
                                                                        vertical:
                                                                            1,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            primaryTeal,
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              3,
                                                                            ),
                                                                      ),
                                                                      child: const Text(
                                                                        '●',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              7,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  Expanded(
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Flexible(
                                                                          child: Text(
                                                                            item.medicine.name,
                                                                            style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 12,
                                                                              color: isCartSelected
                                                                                  ? primaryTeal
                                                                                  : textDark,
                                                                            ),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        if (isDuplicateBatch) ...[
                                                                          const SizedBox(
                                                                            width:
                                                                                6,
                                                                          ),
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: 5,
                                                                              vertical: 1.5,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: const Color(
                                                                                0xFFFEF3C7,
                                                                              ), // soft amber
                                                                              borderRadius: BorderRadius.circular(
                                                                                4,
                                                                              ),
                                                                              border: Border.all(
                                                                                color: const Color(
                                                                                  0xFFFDE68A,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            child: const Text(
                                                                              'Different Batch',
                                                                              style: TextStyle(
                                                                                color: Color(
                                                                                  0xFFD97706,
                                                                                ),
                                                                                fontSize: 8,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                              // Row 2: batch badge + unit price
                                                              Row(
                                                                children: [
                                                                  GestureDetector(
                                                                    onTap: () =>
                                                                        _showBatchChangerDialog(
                                                                          item,
                                                                        ),
                                                                    child: Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            5,
                                                                        vertical:
                                                                            1,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            isCartSelected
                                                                            ? primaryTeal.withValues(
                                                                                alpha: 0.08,
                                                                              )
                                                                            : const Color(
                                                                                0xFFF1F5F9,
                                                                              ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              3,
                                                                            ),
                                                                        border: Border.all(
                                                                          color:
                                                                              isCartSelected
                                                                              ? primaryTeal.withValues(
                                                                                  alpha: 0.3,
                                                                                )
                                                                              : const Color(
                                                                                  0xFFE2E8F0,
                                                                                ),
                                                                        ),
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Text(
                                                                            'B: ${item.batchNumber}',
                                                                            style: TextStyle(
                                                                              fontSize: 9,
                                                                              color: isCartSelected
                                                                                  ? primaryTeal
                                                                                  : softGrey,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                2,
                                                                          ),
                                                                          Icon(
                                                                            Icons.unfold_more,
                                                                            size:
                                                                                9,
                                                                            color:
                                                                                isCartSelected
                                                                                ? primaryTeal
                                                                                : softGrey,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 5,
                                                                  ),
                                                                  Text(
                                                                    '₹${item.mrp.toStringAsFixed(2)}/ea',
                                                                    style: const TextStyle(
                                                                      color:
                                                                          softGrey,
                                                                      fontSize:
                                                                          9,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                          width: 8,
                                                        ),

                                                        // ── Quantity stepper (bigger hit targets) ────────
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            border: Border.all(
                                                              color:
                                                                  isCartSelected
                                                                  ? primaryTeal
                                                                        .withValues(
                                                                          alpha:
                                                                              0.5,
                                                                        )
                                                                  : borderGrey,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            color: Colors.white,
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              InkWell(
                                                                onTap: () {
                                                                  _updateCartItemQuantity(
                                                                    item,
                                                                    currentTotal -
                                                                        1,
                                                                  );
                                                                },
                                                                borderRadius:
                                                                    const BorderRadius.horizontal(
                                                                      left:
                                                                          Radius.circular(
                                                                            5,
                                                                          ),
                                                                    ),
                                                                child: Container(
                                                                  width: 30,
                                                                  height: 30,
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  decoration: const BoxDecoration(
                                                                    border: Border(
                                                                      right: BorderSide(
                                                                        color:
                                                                            borderGrey,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons
                                                                        .remove,
                                                                    size: 15,
                                                                    color:
                                                                        softGrey,
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 34,
                                                                height: 30,
                                                                child: Center(
                                                                  child: Text(
                                                                    '${item.quantity}',
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14,
                                                                      color:
                                                                          textDark,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              InkWell(
                                                                onTap:
                                                                    canIncrease
                                                                    ? () {
                                                                        _updateCartItemQuantity(
                                                                          item,
                                                                          currentTotal +
                                                                              1,
                                                                        );
                                                                      }
                                                                    : null,
                                                                borderRadius:
                                                                    const BorderRadius.horizontal(
                                                                      right:
                                                                          Radius.circular(
                                                                            5,
                                                                          ),
                                                                    ),
                                                                child: Opacity(
                                                                  opacity:
                                                                      canIncrease
                                                                      ? 1.0
                                                                      : 0.4,
                                                                  child: Container(
                                                                    width: 30,
                                                                    height: 30,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    decoration: const BoxDecoration(
                                                                      border: Border(
                                                                        left: BorderSide(
                                                                          color:
                                                                              borderGrey,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: const Icon(
                                                                      Icons.add,
                                                                      size: 15,
                                                                      color:
                                                                          primaryTeal,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        // ── Line total — always right-aligned ────────────
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        SizedBox(
                                                          width: 78,
                                                          child: Text(
                                                            '₹${NumberFormat('#,##,##0.00').format(totalItemPrice)}',
                                                            textAlign:
                                                                TextAlign.right,
                                                            maxLines: 1,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 13,
                                                                  color:
                                                                      textDark,
                                                                ),
                                                          ),
                                                        ),

                                                        // ── Remove button ─────────────────────────────────
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        InkWell(
                                                          onTap: () {
                                                            ref
                                                                .read(
                                                                  billingNotifierProvider
                                                                      .notifier,
                                                                )
                                                                .removeFromCart(
                                                                  item.batchId,
                                                                );
                                                            setState(() {
                                                              final newLen =
                                                                  state
                                                                      .cartItems
                                                                      .length -
                                                                  1;
                                                              _selectedCartIndex =
                                                                  newLen > 1
                                                                  ? (index <
                                                                            newLen
                                                                        ? index
                                                                        : newLen -
                                                                              1)
                                                                  : -1;
                                                            });
                                                          },
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  3,
                                                                ),
                                                            child: const Icon(
                                                              Icons.close,
                                                              color: Colors
                                                                  .redAccent,
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),

                              // Cart Totals & Payment
                              const Divider(height: 1, color: borderGrey),
                              Container(
                                color: const Color(0xFFF8FAFC),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Summary row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Items: ${state.cartItems.length} | Qty: ${state.cartItems.fold(0, (sum, i) => sum + i.quantity)}',
                                          style: const TextStyle(
                                            color: softGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Subtotal: ₹${state.cartSubtotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: softGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Discount row
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: DropdownButtonFormField<String>(
                                            initialValue: _discountType,
                                            isExpanded: true,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: textDark,
                                            ),
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: '₹ Flat',
                                                child: Text('₹ Flat'),
                                              ),
                                              DropdownMenuItem(
                                                value: '% Percent',
                                                child: Text('% Percent'),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null)
                                                setState(
                                                  () => _discountType = val,
                                                );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 3,
                                          child: FocusTraversalOrder(
                                            order: const NumericFocusOrder(5),
                                            child: TextFormField(
                                              focusNode: _discountFocusNode,
                                              controller: _discountController,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: textDark,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Discount (Ctrl+D)',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onFieldSubmitted: (_) {
                                                _applyCalculatedDiscount();
                                                final currentMethod = ref
                                                    .read(
                                                      billingNotifierProvider,
                                                    )
                                                    .paymentMethod;
                                                if (currentMethod == 'CASH') {
                                                  _receivedFocusNode
                                                      .requestFocus();
                                                }
                                                // For UPI/CARD no received field needed — shortcut to checkout
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 4,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '- ₹${state.discount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Payment Methods with shortcut hints
                                    Row(
                                      children: [
                                        _buildPaymentButton(
                                          'CASH',
                                          'F5',
                                          state.paymentMethod == 'CASH',
                                          primaryTeal,
                                          borderGrey,
                                          textDark,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPaymentButton(
                                          'UPI',
                                          'F6',
                                          state.paymentMethod == 'UPI',
                                          primaryTeal,
                                          borderGrey,
                                          textDark,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPaymentButton(
                                          'CARD',
                                          'F7',
                                          state.paymentMethod == 'CARD',
                                          primaryTeal,
                                          borderGrey,
                                          textDark,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Received amount (CASH only)
                                    if (state.paymentMethod == 'CASH') ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FocusTraversalOrder(
                                              order: const NumericFocusOrder(6),
                                              child: TextFormField(
                                                focusNode: _receivedFocusNode,
                                                controller:
                                                    _receivedAmountController,
                                                keyboardType:
                                                    TextInputType.number,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: textDark,
                                                ),
                                                decoration: InputDecoration(
                                                  labelText: 'Received (F4)',
                                                  labelStyle: const TextStyle(
                                                    fontSize: 11,
                                                    color: softGrey,
                                                  ),
                                                  prefixIcon: const Icon(
                                                    Icons.currency_rupee,
                                                    size: 16,
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                ),
                                                onFieldSubmitted: (_) {
                                                  // Enter after received amount → checkout
                                                  _triggerCheckout();
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'CHANGE RETURN',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: softGrey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${(_receivedAmount - state.cartTotal).clamp(0.0, double.infinity).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Grand Total & Checkout button
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'GRAND TOTAL',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: softGrey,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: primaryTeal.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '₹${state.cartTotal.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  color: primaryTeal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed:
                                                state.cartItems.isEmpty ||
                                                    state.isLoading
                                                ? null
                                                : _triggerCheckout,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryTeal,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 20,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: state.isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            Colors.white,
                                                          ),
                                                    ),
                                                  )
                                                : const Text(
                                                    'BILL & PRINT (F8)',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ════ RIGHT PANEL ════════════════════════════════════════
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search field
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(4),
                                  child: TextField(
                                    focusNode: _searchFocusNode,
                                    controller: _searchController,
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search medicine or scan barcode (F2)',
                                      hintStyle: const TextStyle(
                                        color: softGrey,
                                        fontSize: 16,
                                      ),
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Icon(
                                          Icons.search,
                                          color: primaryTeal,
                                          size: 28,
                                        ),
                                      ),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_searchQuery.isNotEmpty)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                                color: softGrey,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                _searchFocusNode.requestFocus();
                                              },
                                            ),
                                          IconButton(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            icon: const Icon(
                                              Icons.qr_code_scanner,
                                              color: softGrey,
                                              size: 26,
                                            ),
                                            onPressed: () {},
                                          ),
                                        ],
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: borderGrey,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: borderGrey,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: primaryTeal,
                                          width: 2.5,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 22,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Category tabs
                              SizedBox(
                                height: 36,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildCategoryTab(
                                      'All',
                                      _selectedCategory == 'All',
                                    ),
                                    ...allCategories.map(
                                      (cat) => _buildCategoryTab(
                                        cat.name,
                                        _selectedCategory == cat.id,
                                        id: cat.id,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Products Grid — 3 states: loading / empty / results
                              Expanded(
                                child: isInventoryLoading
                                    ? _buildSkeletonGrid()
                                    : filteredMeds.isEmpty
                                    ? _buildProductsEmptyState()
                                    : GridView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              childAspectRatio: 3.2,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 8,
                                            ),
                                        itemCount: filteredMeds.length,
                                        itemBuilder: (context, index) {
                                          final med = filteredMeds[index];
                                          final recBatch = _getRecommendedBatch(
                                            med,
                                          );
                                          final double displayMrp =
                                              recBatch != null
                                              ? (double.tryParse(
                                                      recBatch.mrp.toString(),
                                                    ) ??
                                                    med.mrp)
                                              : med.mrp;
                                          final int displayStock =
                                              _getTotalActiveStock(med);
                                          final hasStock = displayStock > 0;
                                          final isSelected =
                                              index == _selectedProductIndex;

                                          return Stack(
                                            children: [
                                              InkWell(
                                                onTap: hasStock
                                                    ? () =>
                                                          _handleProductAdd(med)
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: !hasStock
                                                        ? const Color(
                                                            0xFFF8FAFC,
                                                          )
                                                        : isSelected
                                                        ? primaryTeal
                                                              .withValues(
                                                                alpha: 0.05,
                                                              )
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: !hasStock
                                                          ? const Color(
                                                              0xFFE2E8F0,
                                                            )
                                                          : isSelected
                                                          ? primaryTeal
                                                          : borderGrey,
                                                      width: isSelected ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              med.name,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                                color: hasStock
                                                                    ? textDark
                                                                    : const Color(
                                                                        0xFFADB5BD,
                                                                      ),
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '\u20b9${displayMrp.toStringAsFixed(2)}',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color:
                                                                        hasStock
                                                                        ? softGrey
                                                                        : const Color(
                                                                            0xFFCED4DA,
                                                                          ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  ' \u00b7 $displayStock',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color:
                                                                        hasStock
                                                                        ? softGrey
                                                                        : const Color(
                                                                            0xFFCED4DA,
                                                                          ),
                                                                  ),
                                                                ),
                                                                if (hasStock &&
                                                                    med.reorderLevel !=
                                                                        null &&
                                                                    med.stock <=
                                                                        med.reorderLevel!) ...[
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  const Text(
                                                                    'LOW',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          8,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .orange,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (hasStock)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                5,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isSelected
                                                                ? primaryTeal
                                                                : primaryTeal
                                                                      .withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.add,
                                                            color: isSelected
                                                                ? Colors.white
                                                                : primaryTeal,
                                                            size: 14,
                                                          ),
                                                        )
                                                      else
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                5,
                                                              ),
                                                          decoration:
                                                              const BoxDecoration(
                                                                color: Color(
                                                                  0xFFE9ECEF,
                                                                ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: const Icon(
                                                            Icons.block,
                                                            color: Color(
                                                              0xFFADB5BD,
                                                            ),
                                                            size: 14,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Dim overlay for out-of-stock
                                              if (!hasStock)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Keyboard HUD Overlay ────────────────────────────────────
                if (_showHud)
                  Positioned(bottom: 16, right: 16, child: _buildKeyboardHud()),

                // ─── HUD toggle button ────────────────────────────────────────
                Positioned(
                  bottom: 16,
                  right: _showHud ? 16 + 300 + 8 : 16,
                  child: Tooltip(
                    message: 'Keyboard Shortcuts (?)',
                    child: InkWell(
                      onTap: () => setState(() => _showHud = !_showHud),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _showHud
                              ? const Color(0xFF0D9488)
                              : const Color(0xFF1E293B).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showHud ? Icons.close : Icons.keyboard,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showHud ? 'Close' : 'Shortcuts (?)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Payment Button Builder ──────────────────────────────────────────────────
  Widget _buildPaymentButton(
    String method,
    String shortcut,
    bool isSelected,
    Color primaryTeal,
    Color borderGrey,
    Color textDark,
  ) {
    final IconData icon = method == 'CASH'
        ? Icons.payments_outlined
        : method == 'UPI'
        ? Icons.qr_code_2
        : Icons.credit_card_outlined;

    return Expanded(
      child: InkWell(
        onTap: () =>
            ref.read(billingNotifierProvider.notifier).setPaymentMethod(method),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46,
          decoration: BoxDecoration(
            // Selected: solid teal fill. Unselected: white with subtle border.
            color: isSelected ? primaryTeal : Colors.white,
            border: Border.all(
              color: isSelected ? primaryTeal : borderGrey,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryTeal.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    method,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    shortcut,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Skeleton loader for product grid (shown while inventory loads) ──────────
  Widget _buildSkeletonGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12, // fixed number of shimmer placeholders
      itemBuilder: (context, index) => _buildSkeletonCard(index),
    );
  }

  Widget _buildSkeletonCard(int index) {
    // Stagger the animation phase so cards don't pulse in sync
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 900 + (index % 4) * 120),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 0.4),
          duration: Duration(milliseconds: 900 + (index % 4) * 120),
          curve: Curves.easeInOut,
          builder: (context, value2, _) {
            final opacity = (value * value2).clamp(0.3, 1.0);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Medicine name placeholder
                        Opacity(
                          opacity: opacity,
                          child: Container(
                            height: 11,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Price + stock placeholder
                        Opacity(
                          opacity: opacity * 0.7,
                          child: Container(
                            height: 9,
                            width: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add button placeholder
                  Opacity(
                    opacity: opacity * 0.6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Empty state (shown post-load when no medicines match) ───────────────────
  Widget _buildProductsEmptyState() {
    // Distinguish: user searched but got no results, vs truly no inventory
    final hasSearchQuery = _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchQuery
                ? Icons.search_off_rounded
                : Icons.medication_outlined,
            size: 48,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearchQuery
                ? 'No medicines found for "$_searchQuery"'
                : 'No medicines available',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasSearchQuery
                ? 'Try a different name, barcode or generic name'
                : 'Add medicines in the Stock module first',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Keyboard HUD ────────────────────────────────────────────────────────────
  Widget _buildKeyboardHud() {
    const bg = Color(0xFF0F172A);
    const accent = Color(0xFF0D9488);

    final shortcuts = [
      ('F2', 'Search / Scan'),
      ('↑↓←→', 'Navigate medicines'),
      ('Enter', 'Add to cart (FEFO auto)'),
      ('Esc', 'Clear search'),
      ('Q', 'Edit quantity'),
      ('B', 'Change batch in cart'),
      ('Delete', 'Remove item'),
      ('Ctrl+D', 'Discount'),
      ('F4', 'Received amount'),
      ('F5', 'Cash'),
      ('F6', 'UPI'),
      ('F7', 'Card'),
      ('F8', 'Bill & Print'),
      ('Ctrl+N', 'New bill'),
      ('Ctrl+B', 'Hold bill'),
      ('Ctrl+R', 'Return bill'),
      ('?', 'Toggle this HUD'),
    ];

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.keyboard, color: Color(0xFF0D9488), size: 16),
              SizedBox(width: 8),
              Text(
                'KEYBOARD SHORTCUTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 10),
          ...shortcuts.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 90),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        entry.$1,
                        style: const TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.$2,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category Tab ────────────────────────────────────────────────────────────
  Widget _buildCategoryTab(String title, bool isSelected, {String? id}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = id ?? 'All';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0D9488)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
