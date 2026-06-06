import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../notifier/billing_notifier.dart';
import '../../domain/models/invoice.dart';
import '../../utils/invoice_printer.dart';

class SearchIntent extends Intent { const SearchIntent(); }
class PaymentIntent extends Intent { const PaymentIntent(); }
class CheckoutIntent extends Intent { const CheckoutIntent(); }
class DiscountIntent extends Intent { const DiscountIntent(); }

class BillingPosScreen extends ConsumerStatefulWidget {
  const BillingPosScreen({super.key});

  @override
  ConsumerState<BillingPosScreen> createState() => _BillingPosScreenState();
}

class _BillingPosScreenState extends ConsumerState<BillingPosScreen> {
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

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _discountType = '₹ Flat'; // '₹ Flat' or '% Percent'
  double _receivedAmount = 0.0;
  int _selectedProductIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _selectedProductIndex = 0; // Reset selection on typing
      });
    });

    _discountController.addListener(_updateDiscount);
    _receivedAmountController.addListener(() {
      setState(() {
        _receivedAmount = double.tryParse(_receivedAmountController.text) ?? 0.0;
      });
    });

    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        final state = ref.read(inventoryNotifierProvider);
        var filteredMeds = state.medicines.where((m) {
          final matchesSearch = m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                (m.genericName != null && m.genericName!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                                (m.barcode != null && m.barcode == _searchQuery);
          final matchesCategory = _selectedCategory == 'All' || m.categoryId == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
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
          if (filteredMeds.isNotEmpty && _selectedProductIndex >= 0 && _selectedProductIndex < filteredMeds.length) {
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
    _discountController.dispose();
    _notesController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _doctorNameController.dispose();
    _receivedAmountController.dispose();
    _searchFocusNode.dispose();
    _receivedFocusNode.dispose();
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

  void _handleProductAdd(Medicine medicine) async {
    // Show a minimal loading state or just fetch (it's usually fast)
    final batches = await ref.read(billingNotifierProvider.notifier).fetchBatches(medicine.id);
    if (!mounted) return;

    var validBatches = batches.where((b) => b.medicineId == medicine.id && b.availableQuantity > 0).toList();
    
    // Filter out strictly expired batches from valid selection
    validBatches = validBatches.where((b) {
      final expiry = DateTime.tryParse(b.expiryDate);
      if (expiry == null) return false;
      return !expiry.isBefore(DateTime.now());
    }).toList();

    if (validBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No active stock batches found for this medicine.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    if (validBatches.length == 1) {
      // Fast path: Auto-add to cart if only 1 batch exists
      final batch = validBatches.first;
      ref.read(billingNotifierProvider.notifier).addToCart(
        medicine: medicine,
        batchId: batch.id,
        batchNumber: batch.batchNumber,
        mrp: double.tryParse(batch.mrp.toString()) ?? 0.0,
        quantity: 1,
        availableStock: batch.availableQuantity,
        expiryDate: batch.expiryDate,
      );
      _searchController.clear();
      _searchFocusNode.requestFocus();
    } else {
      // Sort by FEFO (First Expiry First Out)
      validBatches.sort((a, b) {
        final aExp = DateTime.tryParse(a.expiryDate) ?? DateTime.now();
        final bExp = DateTime.tryParse(b.expiryDate) ?? DateTime.now();
        return aExp.compareTo(bExp);
      });
      _showBatchSelectorDialog(medicine, validBatches);
    }
  }

  void _showBatchSelectorDialog(Medicine medicine, List<MedicineBatch> batches) {
    int selectedBatchIndex = 0;
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            titlePadding: const EdgeInsets.all(20),
            contentPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select Batch - ${medicine.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                const Text('Multiple batches available. Select to add.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
            content: Focus(
              focusNode: focusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent || event is KeyRepeatEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (selectedBatchIndex < batches.length - 1) {
                      setDialogState(() => selectedBatchIndex++);
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (selectedBatchIndex > 0) {
                      setDialogState(() => selectedBatchIndex--);
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    final batch = batches[selectedBatchIndex];
                    Navigator.of(context).pop();
                    ref.read(billingNotifierProvider.notifier).addToCart(
                      medicine: medicine,
                      batchId: batch.id,
                      batchNumber: batch.batchNumber,
                      mrp: double.tryParse(batch.mrp.toString()) ?? 0.0,
                      quantity: 1,
                      availableStock: batch.availableQuantity,
                      expiryDate: batch.expiryDate,
                    );
                    _searchController.clear();
                    _searchFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: SizedBox(
                width: 400,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: batches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final batch = batches[index];
              final expiryDate = DateTime.parse(batch.expiryDate);
              final now = DateTime.now();
              final int daysToExpiry = expiryDate.difference(now).inDays;
              final bool nearExpiry = daysToExpiry <= 30;
              final formattedExpiry = DateFormat('MMM yyyy').format(expiryDate);
              final batchMrp = double.tryParse(batch.mrp.toString()) ?? 0.0;
              final isRecommended = index == selectedBatchIndex; // Highlighting the actively focused one instead of strictly FEFO first

              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(billingNotifierProvider.notifier).addToCart(
                    medicine: medicine,
                    batchId: batch.id,
                    batchNumber: batch.batchNumber,
                    mrp: batchMrp,
                    quantity: 1,
                    availableStock: batch.availableQuantity,
                    expiryDate: batch.expiryDate,
                  );
                  _searchController.clear();
                  _searchFocusNode.requestFocus();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: isRecommended ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0), width: isRecommended ? 2 : 1),
                    borderRadius: BorderRadius.circular(8),
                    color: isRecommended ? const Color(0xFF0D9488).withValues(alpha: 0.05) : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Batch: ${batch.batchNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                if (isRecommended) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('RECOMMENDED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Exp: $formattedExpiry', style: TextStyle(color: nearExpiry ? Colors.orange : const Color(0xFF64748B), fontSize: 12, fontWeight: nearExpiry ? FontWeight.bold : FontWeight.normal)),
                                const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                                Text('Stock: ${batch.availableQuantity}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${batchMrp.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Click to Add', style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ), // Close Focus widget here
      actionsPadding: const EdgeInsets.only(right: 20, bottom: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel (Esc)', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  },
),
);
}

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('VIYAN MEDASSIST', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  const Text('123, Healthcare Street, Medical Hub, Bangalore', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 4),
                  const Text('GSTIN: 29ABCDE1234F1Z1 | Ph: +91 98765 43210', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.black), children: [const TextSpan(text: 'INVOICE # ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: invoice.invoiceNumber)])),
                      RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.black), children: [const TextSpan(text: 'DATE: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: invoice.date)])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.black), children: [const TextSpan(text: 'PATIENT: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: invoice.patientName.isNotEmpty ? invoice.patientName : 'Walk-in Customer')])),
                  const SizedBox(height: 8),
                  RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.black), children: [const TextSpan(text: 'PHONE: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: invoice.patientPhone.isNotEmpty ? invoice.patientPhone : '')])),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.black, thickness: 1.5),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: const [
                        Expanded(flex: 4, child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        Expanded(flex: 2, child: Text('MRP', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.black, thickness: 1.5),

                  ...invoice.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: Text(item.name, style: const TextStyle(fontSize: 14))),
                          Expanded(flex: 1, child: Text(item.qty.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                          Expanded(flex: 2, child: Text('₹${item.mrp.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14))),
                          Expanded(flex: 2, child: Text('₹${item.total.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 250,
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(fontSize: 14)), Text('₹${invoice.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14))]),
                            const SizedBox(height: 6),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('CGST', style: TextStyle(fontSize: 14)), Text('₹${cgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14))]),
                            const SizedBox(height: 6),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('SGST', style: TextStyle(fontSize: 14)), Text('₹${sgst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14))]),
                            if (invoice.discount > 0) ...[
                               const SizedBox(height: 6),
                               Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Discount', style: TextStyle(fontSize: 14, color: Colors.green)), Text('-₹${invoice.discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.green))]),
                            ],
                            const SizedBox(height: 8),
                            const Divider(color: Colors.black, thickness: 1),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('₹${invoice.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.black, thickness: 1),
                  const SizedBox(height: 24),
                  const Text('Thank you for visiting! Get well soon.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 48),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => InvoicePrinter.printInvoice(invoice),
                          icon: const Icon(Icons.print_outlined, size: 20),
                          label: const Text('Print Receipt', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textDark,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ref.read(billingNotifierProvider.notifier).clearCart();
                            _discountController.text = '0';
                            _notesController.clear();
                            _customerNameController.clear();
                            _customerPhoneController.clear();
                            _doctorNameController.clear();
                            _receivedAmountController.clear();
                            _searchController.clear();
                            _searchFocusNode.requestFocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('New Sale', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
    
    // Ensure discount is applied before checkout
    _applyCalculatedDiscount();

    final success = await notifier.checkoutCart(
      patientName: _customerNameController.text.trim(),
      patientPhone: _customerPhoneController.text.trim(),
      notes: finalNotes,
    );

    if (mounted) {
      if (success) {
        final updatedState = ref.read(billingNotifierProvider);
        if (updatedState.lastCreatedInvoice != null) {
          _showCheckoutSuccessDialog(updatedState.lastCreatedInvoice!);
        }
      } else {
        final error = ref.read(billingNotifierProvider).errorMessage ?? 'Checkout failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF8FAFC);

    final allMedicines = ref.watch(inventoryNotifierProvider).medicines;
    final allCategories = ref.watch(inventoryNotifierProvider).categories;
    final state = ref.watch(billingNotifierProvider);
    
    _applyCalculatedDiscount();

    final filteredMeds = allMedicines.where((med) {
      if (_selectedCategory != 'All' && med.categoryId != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return med.name.toLowerCase().contains(q) ||
          (med.genericName != null && med.genericName!.toLowerCase().contains(q)) ||
          (med.batchNumber != null && med.batchNumber!.toLowerCase().contains(q));
    }).toList();

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f2): const SearchIntent(),
        SingleActivator(LogicalKeyboardKey.f4): const PaymentIntent(),
        SingleActivator(LogicalKeyboardKey.f8): const CheckoutIntent(),
        SingleActivator(LogicalKeyboardKey.keyD, control: true): const DiscountIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction<SearchIntent>(onInvoke: (intent) => _searchFocusNode.requestFocus()),
          PaymentIntent: CallbackAction<PaymentIntent>(onInvoke: (intent) => _receivedFocusNode.requestFocus()),
          CheckoutIntent: CallbackAction<CheckoutIntent>(onInvoke: (intent) => _triggerCheckout()),
          DiscountIntent: CallbackAction<DiscountIntent>(onInvoke: (intent) => _discountFocusNode.requestFocus()),
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: FocusScope(
            autofocus: true,
            child: Container(
            color: bgGrey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= LEFT PANEL: Cart, calculations & Checkout =================
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(right: BorderSide(color: borderGrey, width: 1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Details Section
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRESCRIPTION / CUSTOMER DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: softGrey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: FocusTraversalOrder(
                                      order: const NumericFocusOrder(1),
                                      child: TextFormField(
                                        controller: _customerNameController,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Customer Name (Walk-in)',
                                          hintStyle: const TextStyle(fontSize: 13, color: softGrey),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FocusTraversalOrder(
                                      order: const NumericFocusOrder(2),
                                      child: TextFormField(
                                        controller: _customerPhoneController,
                                        keyboardType: TextInputType.phone,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Mobile No.',
                                          hintStyle: const TextStyle(fontSize: 13, color: softGrey),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
                                    hintStyle: const TextStyle(fontSize: 13, color: softGrey),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: borderGrey),

                        // Cart Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: bgGrey,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Checkout Cart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
                              if (state.cartItems.isNotEmpty)
                                InkWell(
                                  onTap: () {
                                    ref.read(billingNotifierProvider.notifier).clearCart();
                                    _discountController.text = '0';
                                  },
                                  child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: borderGrey),

                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.white,
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: Text('Medicine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey))),
                              Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey))),
                              Expanded(flex: 1, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey))),
                              SizedBox(width: 24),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: borderGrey),

                        // Cart Items list
                        Expanded(
                          child: state.cartItems.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_shopping_cart_rounded, size: 56, color: Color(0xFFE2E8F0)),
                                        const SizedBox(height: 16),
                                        const Text('🛒 Cart is Empty', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        const Text('Start typing medicine name (F2)', style: TextStyle(color: softGrey, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        const Text('or Scan barcode to add item', style: TextStyle(color: softGrey, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: state.cartItems.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1, color: borderGrey),
                                  itemBuilder: (context, index) {
                                    final item = state.cartItems[index];
                                    final totalItemPrice = item.mrp * item.quantity;
                                    return Focus(
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent || event is KeyRepeatEvent) {
                                          if (event.logicalKey == LogicalKeyboardKey.numpadAdd || event.logicalKey == LogicalKeyboardKey.equal || event.character == '+') {
                                            ref.read(billingNotifierProvider.notifier).updateQuantity(item.batchId, item.quantity + 1);
                                            return KeyEventResult.handled;
                                          } else if (event.logicalKey == LogicalKeyboardKey.numpadSubtract || event.logicalKey == LogicalKeyboardKey.minus || event.character == '-') {
                                            ref.read(billingNotifierProvider.notifier).updateQuantity(item.batchId, item.quantity - 1);
                                            return KeyEventResult.handled;
                                          } else if (event.logicalKey == LogicalKeyboardKey.delete || event.logicalKey == LogicalKeyboardKey.backspace) {
                                            ref.read(billingNotifierProvider.notifier).removeFromCart(item.batchId);
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: Builder(
                                        builder: (context) {
                                          final isFocused = Focus.of(context).hasFocus;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isFocused ? primaryTeal.withValues(alpha: 0.08) : Colors.transparent,
                                              border: Border(left: BorderSide(color: isFocused ? primaryTeal : Colors.transparent, width: 3)),
                                            ),
                                            child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.medicine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                                                const SizedBox(height: 2),
                                                Text('Batch: ${item.batchNumber} | ₹${item.mrp.toStringAsFixed(2)}', style: const TextStyle(color: softGrey, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          // Quantity Stepper
                                          Container(
                                            decoration: BoxDecoration(border: Border.all(color: borderGrey), borderRadius: BorderRadius.circular(6), color: Colors.white),
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () => ref.read(billingNotifierProvider.notifier).updateQuantity(item.batchId, item.quantity - 1),
                                                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: const BoxDecoration(border: Border(right: BorderSide(color: borderGrey))), child: const Icon(Icons.remove, size: 16, color: softGrey)),
                                                ),
                                                Container(
                                                  width: 32,
                                                  alignment: Alignment.center,
                                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                                                ),
                                                InkWell(
                                                  onTap: () => ref.read(billingNotifierProvider.notifier).updateQuantity(item.batchId, item.quantity + 1),
                                                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: const BoxDecoration(border: Border(left: BorderSide(color: borderGrey))), child: const Icon(Icons.add, size: 16, color: primaryTeal)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: 70,
                                            child: Text('₹${totalItemPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => ref.read(billingNotifierProvider.notifier).removeFromCart(item.batchId),
                                            child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                          ),
                                        ],
                                        ), // End Row
                                      ); // End Container
                                        }, // End Builder.builder
                                      ), // End Builder
                                    ); // End Focus
                                  }, // End ListView.itemBuilder
                                ),
                        ),

                        // Cart Totals and payment options
                        const Divider(height: 1, color: borderGrey),
                        Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Invoice Summary
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Items: ${state.cartItems.length} | Qty: ${state.cartItems.fold(0, (sum, i) => sum + i.quantity)}', style: const TextStyle(color: softGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('Subtotal: ₹${state.cartSubtotal.toStringAsFixed(2)}', style: const TextStyle(color: softGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Discount
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _discountType,
                                      isExpanded: true,
                                      style: const TextStyle(fontSize: 13, color: textDark),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: '₹ Flat', child: Text('₹ Flat')),
                                        DropdownMenuItem(value: '% Percent', child: Text('% Percent')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _discountType = val);
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
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 13, color: textDark),
                                        decoration: InputDecoration(
                                          hintText: 'Discount',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('- ₹${state.discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Payment Methods
                              Row(
                                children: ['CASH', 'UPI', 'CARD'].map((method) {
                                  final isSelected = state.paymentMethod == method;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: InkWell(
                                        onTap: () => ref.read(billingNotifierProvider.notifier).setPaymentMethod(method),
                                        child: Container(
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isSelected ? primaryTeal.withValues(alpha: 0.1) : Colors.white,
                                            border: Border.all(color: isSelected ? primaryTeal : borderGrey, width: isSelected ? 1.5 : 1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(method, style: TextStyle(color: isSelected ? primaryTeal : textDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),

                              // Tendered Amount & Change
                              if (state.paymentMethod == 'CASH') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: FocusTraversalOrder(
                                        order: const NumericFocusOrder(6),
                                        child: TextFormField(
                                          focusNode: _receivedFocusNode,
                                          controller: _receivedAmountController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 13, color: textDark),
                                          decoration: InputDecoration(
                                            labelText: 'Received (F4)',
                                            labelStyle: const TextStyle(fontSize: 11, color: softGrey),
                                            prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('CHANGE RETURN', style: TextStyle(fontSize: 10, color: softGrey, fontWeight: FontWeight.bold)),
                                          Text('₹${(_receivedAmount - state.cartTotal).clamp(0.0, double.infinity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Grand Total & Checkout Button
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('GRAND TOTAL', style: TextStyle(fontSize: 11, color: softGrey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text('₹${state.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryTeal)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: state.cartItems.isEmpty || state.isLoading ? null : _triggerCheckout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryTeal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      child: state.isLoading
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                          : const Text('BILL & PRINT (F8)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

                // ================= RIGHT PANEL: Search Directory & Add to Cart =================
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search input (Hero)
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: FocusTraversalOrder(
                            order: const NumericFocusOrder(4),
                            child: TextField(
                              focusNode: _searchFocusNode,
                              controller: _searchController,
                              style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Search medicine or scan barcode (F2)',
                                hintStyle: const TextStyle(color: softGrey, fontSize: 16),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.search, color: primaryTeal, size: 28),
                                ),
                                suffixIcon: IconButton(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  icon: const Icon(Icons.qr_code_scanner, color: softGrey, size: 26),
                                  onPressed: () {},
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey, width: 1.5)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey, width: 1.5)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryTeal, width: 2.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Tabs
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildCategoryTab('All', _selectedCategory == 'All'),
                              ...allCategories.map((cat) => _buildCategoryTab(cat.name, _selectedCategory == cat.id, id: cat.id)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Products List (Keyboard Optimized)
                        Expanded(
                          child: filteredMeds.isEmpty
                              ? const Center(child: Text('No products found matching query.', style: TextStyle(color: softGrey, fontSize: 14, fontWeight: FontWeight.w500)))
                              : GridView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 3.0,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: filteredMeds.length,
                                  itemBuilder: (context, index) {
                                    final med = filteredMeds[index];
                                    final hasStock = med.stock > 0;
                                    final isSelected = index == _selectedProductIndex;
                                    
                                    return InkWell(
                                      onTap: hasStock ? () => _handleProductAdd(med) : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryTeal.withValues(alpha: 0.05) : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isSelected ? primaryTeal : borderGrey, width: isSelected ? 2 : 1),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Text('₹${med.mrp.toStringAsFixed(2)} • Stock: ${med.stock}', style: const TextStyle(fontSize: 11, color: softGrey)),
                                                      if (hasStock && med.reorderLevel != null && med.stock <= med.reorderLevel!) ...[
                                                        const SizedBox(width: 6),
                                                        const Text('LOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange)),
                                                      ]
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (hasStock)
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                                                child: const Icon(Icons.add, color: primaryTeal, size: 16),
                                              )
                                            else
                                              Row(
                                                children: [
                                                  const Text('Out of Stock', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
                                                    child: const Icon(Icons.add, color: Colors.grey, size: 16),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

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
            border: Border.all(color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
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
