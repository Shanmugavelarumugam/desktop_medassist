import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifier/inventory_notifier.dart';
import '../../domain/models/medicine.dart';

class AddMedicineDialog extends ConsumerStatefulWidget {
  final Medicine? medicine;
  const AddMedicineDialog({super.key, this.medicine});

  @override
  ConsumerState<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends ConsumerState<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _mrpController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiryDateController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedManufacturerId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      _nameController.text = widget.medicine!.name;
      _genericNameController.text = widget.medicine!.genericName ?? '';
      _selectedCategoryId = widget.medicine!.categoryId;
      _selectedManufacturerId = widget.medicine!.manufacturerId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _mrpController.dispose();
    _purchasePriceController.dispose();
    _batchNumberController.dispose();
    _quantityController.dispose();
    _expiryDateController.dispose();
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
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      setState(() => _submitting = true);

      final bool success;
      if (widget.medicine != null) {
        // Edit mode
        success = await ref.read(inventoryNotifierProvider.notifier).updateMedicine(
          id: widget.medicine!.id,
          name: _nameController.text.trim(),
          genericName: _genericNameController.text.trim(),
          categoryId: _selectedCategoryId!,
          manufacturerId: _selectedManufacturerId,
        );
      } else {
        // Add mode
        success = await ref.read(inventoryNotifierProvider.notifier).createMedicine(
          name: _nameController.text.trim(),
          genericName: _genericNameController.text.trim(),
          mrp: double.parse(_mrpController.text.trim()),
          purchasePrice: double.parse(_purchasePriceController.text.trim()),
          batchNumber: _batchNumberController.text.trim(),
          quantity: int.parse(_quantityController.text.trim()),
          expiryDate: DateTime.parse(_expiryDateController.text).toUtc().toIso8601String(),
          categoryId: _selectedCategoryId!,
          manufacturerId: _selectedManufacturerId,
        );
      }

      if (mounted) {
        setState(() => _submitting = false);
        if (success) {
          Navigator.of(context).pop(true); // Return true on success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.medicine != null 
                  ? 'Medicine updated successfully!' 
                  : 'Medicine added successfully!'),
              backgroundColor: const Color(0xFF0D9488),
            ),
          );
        } else {
          final error = ref.read(inventoryNotifierProvider).errorMessage ?? 
              (widget.medicine != null ? 'Failed to update medicine' : 'Failed to add medicine');
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

    final categories = ref.watch(inventoryNotifierProvider).categories;
    final manufacturers = ref.watch(inventoryNotifierProvider).manufacturers;
    final isEditMode = widget.medicine != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
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
                  Text(
                    isEditMode ? 'Edit Medicine' : 'Add New Medicine',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: softGrey),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Form fields grid
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'MEDICINE NAME',
                              hint: 'e.g. Paracetamol 650',
                              controller: _nameController,
                              validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'GENERIC NAME',
                              hint: 'e.g. Paracetamol',
                              controller: _genericNameController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CATEGORY',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCategoryId,
                                  hint: const Text('Select category', style: TextStyle(fontSize: 14, color: softGrey)),
                                  isExpanded: true,
                                  decoration: InputDecoration(
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
                                  style: const TextStyle(color: textDark, fontSize: 14),
                                  items: categories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat.id,
                                      child: Text(cat.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Manufacturer Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MANUFACTURER',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedManufacturerId,
                                  hint: const Text('Select manufacturer', style: TextStyle(fontSize: 14, color: softGrey)),
                                  isExpanded: true,
                                  decoration: InputDecoration(
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
                                  style: const TextStyle(color: textDark, fontSize: 14),
                                  items: manufacturers.map((man) {
                                    return DropdownMenuItem<String>(
                                      value: man.id,
                                      child: Text(man.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedManufacturerId = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Only show batch creation fields when NOT in Edit Mode
                      if (!isEditMode) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'BATCH NUMBER',
                                hint: 'e.g. B89080379',
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                label: 'PURCHASE PRICE (₹)',
                                hint: 'e.g. 95.50',
                                controller: _purchasePriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Enter price';
                                  if (double.tryParse(val) == null) return 'Must be a number';
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
                                label: 'MRP (₹)',
                                hint: 'e.g. 144.68',
                                controller: _mrpController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Enter MRP';
                                  if (double.tryParse(val) == null) return 'Must be a number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Spacer(), // Empty space to match the grid
                          ],
                        ),
                      ],
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
                        : Text(isEditMode ? 'Save Changes' : 'Add Medicine', style: const TextStyle(fontWeight: FontWeight.bold)),
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
