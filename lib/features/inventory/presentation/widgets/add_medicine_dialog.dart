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
  
  // Additional fields controllers
  final _reorderLevelController = TextEditingController(text: '10');
  final _hsnCodeController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedManufacturerId;
  String _selectedSchedule = 'OTC';
  String _selectedGst = '12%';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      _nameController.text = widget.medicine!.name;
      _genericNameController.text = widget.medicine!.genericName ?? '';
      _selectedCategoryId = widget.medicine!.categoryId;
      _selectedManufacturerId = widget.medicine!.manufacturerId;
      _selectedSchedule = widget.medicine!.prescriptionRequired == true ? 'Rx' : 'OTC';
      _reorderLevelController.text = (widget.medicine!.reorderLevel ?? 10).toString();
      _selectedGst = widget.medicine!.gstPercentage != null 
          ? '${widget.medicine!.gstPercentage!.toInt()}%' 
          : '12%';
    } else {
      _quantityController.text = '0';
      _purchasePriceController.text = '0.00';
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
    _reorderLevelController.dispose();
    _hsnCodeController.dispose();
    _barcodeController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
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

      final gstPercentage = double.tryParse(_selectedGst.replaceAll('%', '')) ?? 12.0;
      final reorderLevel = int.tryParse(_reorderLevelController.text.trim()) ?? 10;
      final prescriptionRequired = _selectedSchedule == 'Rx';

      final bool success;
      if (widget.medicine != null) {
        // Edit mode
        success = await ref.read(inventoryNotifierProvider.notifier).updateMedicine(
          id: widget.medicine!.id,
          name: _nameController.text.trim(),
          genericName: _genericNameController.text.trim(),
          categoryId: _selectedCategoryId!,
          manufacturerId: _selectedManufacturerId,
          gstPercentage: gstPercentage,
          reorderLevel: reorderLevel,
          prescriptionRequired: prescriptionRequired,
          hsnCode: _hsnCodeController.text.trim().isEmpty ? null : _hsnCodeController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
          gstPercentage: gstPercentage,
          reorderLevel: reorderLevel,
          prescriptionRequired: prescriptionRequired,
          hsnCode: _hsnCodeController.text.trim().isEmpty ? null : _hsnCodeController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
        width: 750,
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
                      // Row 1: Medicine Name & Generic Name
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'MEDICINE NAME *',
                              hint: 'e.g. Amoxicillin 500mg Capsules',
                              controller: _nameController,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'GENERIC NAME *',
                              hint: 'e.g. Amoxicillin',
                              controller: _genericNameController,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter generic name' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Row 2: Manufacturer & Category
                      Row(
                        children: [
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
                                  hint: const Text('e.g. Cipla Ltd', style: TextStyle(fontSize: 14, color: softGrey)),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CATEGORY *',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCategoryId,
                                  hint: const Text('Select Category', style: TextStyle(fontSize: 14, color: softGrey)),
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
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Row 3: Schedule & Batch Number
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SCHEDULE',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedSchedule,
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
                                  items: const [
                                    DropdownMenuItem(value: 'OTC', child: Text('OTC')),
                                    DropdownMenuItem(value: 'Rx', child: Text('Rx')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedSchedule = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'BATCH NUMBER *',
                              hint: 'e.g. B-20241',
                              controller: _batchNumberController,
                              enabled: !isEditMode,
                              validator: isEditMode 
                                  ? null 
                                  : (val) => val == null || val.trim().isEmpty ? 'Enter batch number' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Row 4: Expiry Date & MRP
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EXPIRY DATE *',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _expiryDateController,
                                  readOnly: true,
                                  enabled: !isEditMode,
                                  onTap: isEditMode ? null : () => _selectExpiryDate(context),
                                  style: TextStyle(color: isEditMode ? softGrey : textDark, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'mm/dd/yyyy',
                                    hintStyle: const TextStyle(color: softGrey, fontSize: 14),
                                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: softGrey, size: 16),
                                    filled: true,
                                    fillColor: isEditMode ? const Color(0xFFF1F5F9) : Colors.white,
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
                                  validator: isEditMode 
                                      ? null 
                                      : (val) => val == null || val.isEmpty ? 'Select expiry date' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'MRP (₹) *',
                              hint: 'e.g. 144.68',
                              controller: _mrpController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !isEditMode,
                              validator: isEditMode ? null : (val) {
                                if (val == null || val.isEmpty) return 'Enter MRP';
                                final numVal = double.tryParse(val);
                                if (numVal == null) return 'Must be a number';
                                if (numVal <= 0) return 'MRP must be greater than 0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Row 5: Purchase Cost & Stock Quantity
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'PURCHASE COST (₹)',
                              hint: '0.00',
                              controller: _purchasePriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !isEditMode,
                              validator: isEditMode ? null : (val) {
                                if (val == null || val.isEmpty) return 'Enter purchase cost';
                                final numVal = double.tryParse(val);
                                if (numVal == null) return 'Must be a number';
                                if (numVal < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'STOCK QUANTITY *',
                              hint: '0',
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              enabled: !isEditMode,
                              validator: isEditMode ? null : (val) {
                                if (val == null || val.isEmpty) return 'Enter quantity';
                                final numVal = int.tryParse(val);
                                if (numVal == null) return 'Must be an integer';
                                if (numVal < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Row 6: Reorder Level & GST %
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'REORDER LEVEL',
                              hint: '10',
                              controller: _reorderLevelController,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val != null && val.isNotEmpty) {
                                  final numVal = int.tryParse(val);
                                  if (numVal == null) return 'Must be an integer';
                                  if (numVal < 0) return 'Cannot be negative';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GST %',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedGst,
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
                                  items: const [
                                    DropdownMenuItem(value: '0%', child: Text('0%')),
                                    DropdownMenuItem(value: '5%', child: Text('5%')),
                                    DropdownMenuItem(value: '12%', child: Text('12%')),
                                    DropdownMenuItem(value: '18%', child: Text('18%')),
                                    DropdownMenuItem(value: '28%', child: Text('28%')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedGst = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Row 7: HSN Code & Barcode / SKU
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'HSN CODE',
                              hint: 'e.g. 3004',
                              controller: _hsnCodeController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'BARCODE / SKU',
                              hint: 'Scan or enter barcode',
                              controller: _barcodeController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Row 8: Supplier & Notes
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'SUPPLIER',
                              hint: 'e.g. Cipla Distributors',
                              controller: _supplierController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'NOTES',
                              hint: 'Notes',
                              controller: _notesController,
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
    bool enabled = true,
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
          enabled: enabled,
          style: TextStyle(color: enabled ? textDark : softGrey, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: softGrey, fontSize: 14),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderGrey, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderGrey, width: 1.2),
            ),
            disabledBorder: OutlineInputBorder(
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
