import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifier/inventory_notifier.dart';
import '../../domain/models/medicine.dart';

class AddBatchDialog extends ConsumerStatefulWidget {
  final Medicine medicine;
  const AddBatchDialog({super.key, required this.medicine});

  @override
  ConsumerState<AddBatchDialog> createState() => _AddBatchDialogState();
}

class _AddBatchDialogState extends ConsumerState<AddBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _mrpController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _batchNumberController.dispose();
    _quantityController.dispose();
    _expiryDateController.dispose();
    _purchasePriceController.dispose();
    _mrpController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
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
        _expiryDateController.text = picked.toUtc().toIso8601String().substring(0, 10);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitting = true);

      final bool success = await ref.read(inventoryNotifierProvider.notifier).addBatch(
        medicineId: widget.medicine.id,
        batchNumber: _batchNumberController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        expiryDate: DateTime.parse(_expiryDateController.text).toUtc().toIso8601String(),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        mrp: double.parse(_mrpController.text.trim()),
      );

      if (mounted) {
        setState(() => _submitting = false);
        if (success) {
          Navigator.of(context).pop(true); // Return true on success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Batch added successfully!'),
              backgroundColor: Color(0xFF0D9488),
            ),
          );
        } else {
          final error = ref.read(inventoryNotifierProvider).errorMessage ?? 'Failed to add batch';
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
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Batch',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.medicine.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: softGrey),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Form fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'BATCH NUMBER',
                              hint: 'e.g. BATCH001',
                              controller: _batchNumberController,
                              validator: (val) => val == null || val.isEmpty ? 'Enter batch number' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EXPIRY DATE',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _expiryDateController,
                                  readOnly: true,
                                  onTap: () => _selectExpiryDate(context),
                                  style: const TextStyle(color: textDark, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'YYYY-MM-DD',
                                    hintStyle: const TextStyle(color: softGrey, fontSize: 14),
                                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: softGrey, size: 16),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: borderGrey, width: 1.2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: borderGrey, width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: primaryTeal, width: 1.8),
                                    ),
                                  ),
                                  validator: (val) => val == null || val.isEmpty ? 'Select expiry date' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'QUANTITY',
                              hint: 'e.g. 100',
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter quantity';
                                if (int.tryParse(val) == null) return 'Must be an integer';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'PURCHASE PRICE (₹)',
                              hint: 'e.g. 18.00',
                              controller: _purchasePriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter price';
                                if (double.tryParse(val) == null) return 'Must be a number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'MRP (₹)',
                              hint: 'e.g. 25.00',
                              controller: _mrpController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter MRP';
                                if (double.tryParse(val) == null) return 'Must be a number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

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
                        : const Text('Add Batch', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: softGrey, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderGrey, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderGrey, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryTeal, width: 1.8),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
