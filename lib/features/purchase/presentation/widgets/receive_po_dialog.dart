import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/purchase.dart';
import '../notifier/purchase_notifier.dart';

class ReceivePoDialog extends ConsumerStatefulWidget {
  final PurchaseOrder purchaseOrder;
  const ReceivePoDialog({super.key, required this.purchaseOrder});

  @override
  ConsumerState<ReceivePoDialog> createState() => _ReceivePoDialogState();
}

class _ReceivePoDialogState extends ConsumerState<ReceivePoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late final List<Map<String, dynamic>> _itemInputs;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _itemInputs = widget.purchaseOrder.items.map((item) {
      return {
        'purchaseOrderItemId': item.id,
        'medicineId': item.medicineId,
        'medicineName': item.medicineName,
        'orderedQuantity': item.quantity,
        'receivedQuantityController': TextEditingController(text: item.quantity.toString()),
        'batchNumberController': TextEditingController(),
        'expiryDateController': TextEditingController(),
      };
    }).toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final input in _itemInputs) {
      (input['receivedQuantityController'] as TextEditingController).dispose();
      (input['batchNumberController'] as TextEditingController).dispose();
      (input['expiryDateController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _selectExpiryDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // up to 10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D9488),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final dateStr = picked.toUtc().toIso8601String().substring(0, 10);
        (_itemInputs[index]['expiryDateController'] as TextEditingController).text = dateStr;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitting = true);

      final List<Map<String, dynamic>> receivedItems = [];
      for (final input in _itemInputs) {
        final int qty = int.tryParse((input['receivedQuantityController'] as TextEditingController).text) ?? 0;
        final String batch = (input['batchNumberController'] as TextEditingController).text.trim();
        final String expiry = (input['expiryDateController'] as TextEditingController).text.trim();

        receivedItems.add({
          'purchaseOrderItemId': input['purchaseOrderItemId'],
          'medicineId': input['medicineId'],
          'receivedQuantity': qty,
          'batchNumber': batch,
          'expiryDate': DateTime.parse(expiry).toUtc().toIso8601String(),
        });
      }

      final success = await ref.read(purchaseNotifierProvider.notifier).receivePurchaseOrder(
            id: widget.purchaseOrder.id,
            receivedItems: receivedItems,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );

      if (mounted) {
        setState(() => _submitting = false);
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goods Received Note (GRN) created successfully! Stock updated.'),
              backgroundColor: Color(0xFF0D9488),
            ),
          );
        } else {
          final error = ref.read(purchaseNotifierProvider).errorMessage ?? 'Failed to receive goods';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        height: 680,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receive Purchase Order',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order Number: ${widget.purchaseOrder.orderNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: softGrey),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Notes field for Receiving
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECEIVING REMARKS (OPTIONAL)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Received in good condition, checked box seal...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: borderGrey),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: borderGrey),
              const SizedBox(height: 12),

              const Text(
                'Verify Received Batches & Quantities',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 12),

              // Scrollable list of items
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderGrey),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _itemInputs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final input = _itemInputs[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              input['medicineName'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ordered Qty (Display)
                                SizedBox(
                                  width: 90,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ORDERED QTY',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: softGrey),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: borderGrey),
                                        ),
                                        child: Text(
                                          '${input['orderedQuantity']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: softGrey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Received Qty (Input)
                                SizedBox(
                                  width: 100,
                                  child: _buildItemField(
                                    label: 'RECEIVED QTY',
                                    hint: 'Qty',
                                    controller: input['receivedQuantityController'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Required';
                                      final numVal = int.tryParse(val);
                                      if (numVal == null || numVal <= 0) return 'Must be > 0';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Batch Number (Input)
                                Expanded(
                                  flex: 2,
                                  child: _buildItemField(
                                    label: 'BATCH NUMBER',
                                    hint: 'e.g. BAT1029',
                                    controller: input['batchNumberController'] as TextEditingController,
                                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Expiry Date (Input)
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'EXPIRY DATE',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: softGrey),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: input['expiryDateController'] as TextEditingController,
                                        readOnly: true,
                                        onTap: () => _selectExpiryDate(context, index),
                                        style: const TextStyle(color: textDark, fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'YYYY-MM-DD',
                                          hintStyle: const TextStyle(color: softGrey, fontSize: 13),
                                          prefixIcon: const Icon(Icons.calendar_today_outlined, color: softGrey, size: 14),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: borderGrey, width: 1.1),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: borderGrey, width: 1.1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: primaryTeal, width: 1.6),
                                          ),
                                        ),
                                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                      ),
                                    ],
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
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      side: const BorderSide(color: borderGrey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: softGrey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Confirm Receipt (GRN)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    const primaryTeal = Color(0xFF0D9488);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const textDark = Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: softGrey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: textDark, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: softGrey, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderGrey, width: 1.1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderGrey, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryTeal, width: 1.6),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
