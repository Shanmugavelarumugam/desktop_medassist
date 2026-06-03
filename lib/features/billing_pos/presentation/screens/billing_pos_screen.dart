import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../notifier/billing_notifier.dart';
import '../../domain/models/invoice.dart';

class BillingPosScreen extends ConsumerStatefulWidget {
  const BillingPosScreen({super.key});

  @override
  ConsumerState<BillingPosScreen> createState() => _BillingPosScreenState();
}

class _BillingPosScreenState extends ConsumerState<BillingPosScreen> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _discountController.addListener(() {
      final discountVal = double.tryParse(_discountController.text) ?? 0.0;
      ref.read(billingNotifierProvider.notifier).setDiscount(discountVal);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showBatchSelector(Medicine medicine) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Batch for ${medicine.name}'),
        content: FutureBuilder<List<MedicineBatch>>(
          future: ref
              .read(billingNotifierProvider.notifier)
              .fetchBatches(medicine.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF0D9488)),
                  ),
                ),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No active batches found for this medicine.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              );
            }

            final batches = snapshot.data!;
            return SizedBox(
              width: 400,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: batches.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final batch = batches[index];
                  final expiryDate = DateTime.parse(batch.expiryDate);
                  final now = DateTime.now();
                  final bool expired = expiryDate.isBefore(now);
                  final int daysToExpiry = expiryDate.difference(now).inDays;
                  final bool nearExpiry = !expired && daysToExpiry <= 30;

                  final formattedExpiry = DateFormat(
                    'MMM yyyy',
                  ).format(expiryDate);
                  final batchMrp = double.tryParse(batch.mrp) ?? 0.0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Batch: ${batch.batchNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '₹${batchMrp.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Expiry: $formattedExpiry',
                                style: TextStyle(
                                  color: expired
                                      ? Colors.red
                                      : nearExpiry
                                      ? Colors.orange
                                      : const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: (expired || nearExpiry)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (nearExpiry) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Expiring in $daysToExpiry days',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ] else if (expired) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'EXPIRED',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'Stock: ${batch.availableQuantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    enabled: !expired && batch.availableQuantity > 0,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(billingNotifierProvider.notifier)
                          .addToCart(
                            medicine: medicine,
                            batchId: batch.id,
                            batchNumber: batch.batchNumber,
                            mrp: batchMrp,
                            quantity: 1,
                            availableStock: batch.availableQuantity,
                            expiryDate: batch.expiryDate,
                          );
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ],
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
        const borderGrey = Color(0xFFE2E8F0);
        const softGrey = Color(0xFF64748B);

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF10B981),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Transaction Successful',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Invoice ${invoice.invoiceNumber} has been finalized.',
                  style: const TextStyle(color: softGrey, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderGrey, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('PAYMENT METHOD', invoice.paymentMethod),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: borderGrey, thickness: 1.5),
                      ),
                      _buildReceiptRow(
                        'SUBTOTAL',
                        '₹${invoice.subtotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildReceiptRow(
                        'DISCOUNT',
                        '₹${invoice.discount.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildReceiptRow(
                        'TAX/GST (INCL.)',
                        '₹${invoice.gst.toStringAsFixed(2)}',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: borderGrey, thickness: 1.5),
                      ),
                      _buildReceiptRow(
                        'TOTAL AMOUNT',
                        '₹${invoice.total.toStringAsFixed(2)}',
                        isBold: true,
                        valueColor: primaryTeal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Printing receipt...'),
                              backgroundColor: primaryTeal,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
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
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
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
                          ref
                              .read(billingNotifierProvider.notifier)
                              .clearCart();
                          _discountController.text = '0';
                          _notesController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: primaryTeal.withValues(alpha: 0.4),
                        ),
                        child: const Text(
                          'Close POS',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  void _triggerCheckout() async {
    final notifier = ref.read(billingNotifierProvider.notifier);
    final success = await notifier.checkoutCart(notes: _notesController.text);

    if (mounted) {
      if (success) {
        final state = ref.read(billingNotifierProvider);
        if (state.lastCreatedInvoice != null) {
          _showCheckoutSuccessDialog(state.lastCreatedInvoice!);
        }
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

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF8FAFC);

    final allMedicines = ref.watch(inventoryNotifierProvider).medicines;
    final state = ref.watch(billingNotifierProvider);

    // Apply local search filtering on allMedicines
    final filteredMeds = allMedicines.where((med) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return med.name.toLowerCase().contains(q) ||
          (med.genericName != null &&
              med.genericName!.toLowerCase().contains(q)) ||
          (med.batchNumber != null &&
              med.batchNumber!.toLowerCase().contains(q));
    }).toList();

    return Container(
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
                  // Cart Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              color: primaryTeal,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Checkout Cart',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        if (state.cartItems.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              ref
                                  .read(billingNotifierProvider.notifier)
                                  .clearCart();
                              _discountController.text = '0';
                            },
                            icon: const Icon(
                              Icons.delete_sweep_outlined,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            label: const Text(
                              'Clear Cart',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: borderGrey),

                  // Cart Items list
                  Expanded(
                    child: state.cartItems.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_shopping_cart_rounded,
                                  size: 48,
                                  color: softGrey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Your checkout cart is empty.',
                                  style: TextStyle(
                                    color: softGrey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Search and add medicines from the right panel.',
                                  style: TextStyle(
                                    color: softGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: state.cartItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final item = state.cartItems[index];
                              final totalItemPrice = item.mrp * item.quantity;
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderGrey),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.medicine.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          (() {
                                            final itemExpiryDate =
                                                DateTime.parse(item.expiryDate);
                                            final itemDaysToExpiry =
                                                itemExpiryDate
                                                    .difference(DateTime.now())
                                                    .inDays;
                                            final itemIsNearExpiry =
                                                itemDaysToExpiry > 0 &&
                                                itemDaysToExpiry <= 30;
                                            return Row(
                                              children: [
                                                Text(
                                                  'Batch: ${item.batchNumber}  |  Exp: ${DateFormat('MMM yyyy').format(itemExpiryDate)}',
                                                  style: TextStyle(
                                                    color: itemIsNearExpiry
                                                        ? Colors.orange
                                                        : softGrey,
                                                    fontSize: 12,
                                                    fontWeight: itemIsNearExpiry
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                if (itemIsNearExpiry) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Colors.orange,
                                                    size: 14,
                                                  ),
                                                ],
                                              ],
                                            );
                                          })(),
                                          const SizedBox(height: 2),
                                          Text(
                                            'MRP: ₹${item.mrp.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: primaryTeal,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quantity Selector
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline_rounded,
                                            color: softGrey,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(
                                                  billingNotifierProvider
                                                      .notifier,
                                                )
                                                .updateQuantity(
                                                  item.batchId,
                                                  item.quantity - 1,
                                                );
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: textDark,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline_rounded,
                                            color: primaryTeal,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(
                                                  billingNotifierProvider
                                                      .notifier,
                                                )
                                                .updateQuantity(
                                                  item.batchId,
                                                  item.quantity + 1,
                                                );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '₹${totalItemPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(
                                              billingNotifierProvider.notifier,
                                            )
                                            .removeFromCart(item.batchId);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Cart Totals and payment options
                  const Divider(height: 1, color: borderGrey),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                color: softGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₹${state.cartSubtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // inclusive GST
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'GST (Incl. in MRP)',
                              style: TextStyle(
                                color: softGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₹${state.cartGst.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: softGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Discount and notes fields
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textDark,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'FLAT DISCOUNT (₹)',
                                  labelStyle: const TextStyle(
                                    fontSize: 10,
                                    color: softGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.local_offer_outlined,
                                    size: 16,
                                    color: softGrey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _notesController,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textDark,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'ADDITIONAL NOTES',
                                  labelStyle: const TextStyle(
                                    fontSize: 10,
                                    color: softGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.edit_note,
                                    size: 18,
                                    color: softGrey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment Methods
                        const Text(
                          'PAYMENT METHOD',
                          style: TextStyle(
                            fontSize: 10,
                            color: softGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ['CASH', 'UPI', 'CARD'].map((method) {
                            final isSelected = state.paymentMethod == method;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: InkWell(
                                  onTap: () => ref
                                      .read(billingNotifierProvider.notifier)
                                      .setPaymentMethod(method),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryTeal.withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryTeal
                                            : borderGrey,
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      method,
                                      style: TextStyle(
                                        color: isSelected
                                            ? primaryTeal
                                            : textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Grand Total & Checkout Button
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GRAND TOTAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: softGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${state.cartTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    state.cartItems.isEmpty || state.isLoading
                                    ? null
                                    : _triggerCheckout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: state.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'FINALIZE BILL & PRINT',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
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

          // ================= RIGHT PANEL: Search Directory & Add to Cart =================
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Directory',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Search products and select batches to add them to invoice checkout.',
                    style: TextStyle(color: softGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Search input
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: textDark, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search products by name or generic name...',
                        hintStyle: const TextStyle(
                          color: softGrey,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: softGrey,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: borderGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: borderGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: primaryTeal,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Products Grid
                  Expanded(
                    child: filteredMeds.isEmpty
                        ? const Center(
                            child: Text(
                              'No products found matching query.',
                              style: TextStyle(
                                color: softGrey,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.5,
                                ),
                            itemCount: filteredMeds.length,
                            itemBuilder: (context, index) {
                              final med = filteredMeds[index];
                              final hasStock = med.stock > 0;
                              final reorderLevel = med.reorderLevel ?? 10;
                              final isLowStock =
                                  med.stock > 0 && med.stock <= reorderLevel;

                              Color stockColor = Colors.green;
                              if (med.stock == 0) {
                                stockColor = Colors.red;
                              } else if (isLowStock) {
                                stockColor = Colors.orange;
                              }

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderGrey),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            med.genericName ?? '',
                                            style: const TextStyle(
                                              color: softGrey,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'MRP: ₹${med.mrp.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: primaryTeal,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: stockColor.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Stock: ${med.stock}',
                                                  style: TextStyle(
                                                    color: stockColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                      height: 16,
                                      color: borderGrey,
                                    ),
                                    Row(
                                      children: [
                                        // Quick Add Button
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed:
                                                !hasStock || med.batchId == null
                                                ? null
                                                : () {
                                                    ref
                                                        .read(
                                                          billingNotifierProvider
                                                              .notifier,
                                                        )
                                                        .addToCart(
                                                          medicine: med,
                                                          batchId: med.batchId!,
                                                          batchNumber:
                                                              med.batchNumber ??
                                                              'DEFAULT',
                                                          mrp: med.mrp,
                                                          quantity: 1,
                                                          availableStock:
                                                              med.stock,
                                                          expiryDate:
                                                              med.expiryDate ??
                                                              DateTime.now()
                                                                  .toIso8601String(),
                                                        );
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryTeal,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              'Quick Add',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // View Batches Button
                                        OutlinedButton(
                                          onPressed: () =>
                                              _showBatchSelector(med),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            side: const BorderSide(
                                              color: borderGrey,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.list_alt_rounded,
                                            color: softGrey,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
    );
  }
}
