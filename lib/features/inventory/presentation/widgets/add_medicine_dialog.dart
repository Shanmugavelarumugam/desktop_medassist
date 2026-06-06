import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  final _reorderLevelController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedManufacturerId;
  String _selectedDrugType = 'OTC';
  String _selectedGst = '12%';
  bool _submitting = false;
  bool _addAnother = false;
  double _calculatedMargin = 0.0;
  double _calculatedGstAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _mrpController.addListener(_calculatePricing);
    _purchasePriceController.addListener(_calculatePricing);
    _quantityController.addListener(_calculateReorderLevel);
    if (widget.medicine != null) {
      _nameController.text = widget.medicine!.name;
      _genericNameController.text = widget.medicine!.genericName ?? '';
      _selectedCategoryId = widget.medicine!.categoryId;
      _selectedManufacturerId = widget.medicine!.manufacturerId;
      _selectedDrugType = widget.medicine!.prescriptionRequired == true ? 'Prescription' : 'OTC';
      _reorderLevelController.text = (widget.medicine!.reorderLevel ?? 10).toString();
      _selectedGst = widget.medicine!.gstPercentage != null 
          ? '${widget.medicine!.gstPercentage!.toInt()}%' 
          : '12%';
      _mrpController.text = widget.medicine!.mrp.toString();
      _purchasePriceController.text = widget.medicine!.purchasePrice.toString();
      _batchNumberController.text = widget.medicine!.batchNumber ?? '';
      _quantityController.text = widget.medicine!.stock.toString();
      if (widget.medicine!.expiryDate != null) {
        try {
          final date = DateTime.parse(widget.medicine!.expiryDate!);
          _expiryDateController.text = DateFormat('MMM yyyy').format(date);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _mrpController.removeListener(_calculatePricing);
    _purchasePriceController.removeListener(_calculatePricing);
    _quantityController.removeListener(_calculateReorderLevel);
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

  void _calculatePricing() {
    final mrp = double.tryParse(_mrpController.text.trim()) ?? 0.0;
    final purchase = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final gstRate = double.tryParse(_selectedGst.replaceAll('%', '')) ?? 12.0;

    final gstAmount = mrp - (mrp / (1 + gstRate / 100));
    final profit = mrp - purchase - gstAmount;
    final margin = purchase > 0 ? (profit / purchase) * 100 : 0.0;

    if (mounted) {
      setState(() {
        _calculatedGstAmount = gstAmount;
        _calculatedMargin = margin;
      });
    }
  }

  void _calculateReorderLevel() {
    if (widget.medicine == null && _quantityController.text.isNotEmpty) {
      final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
      final autoReorder = (qty * 0.2).ceil();
      _reorderLevelController.text = autoReorder > 0 ? autoReorder.toString() : '';
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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
        _expiryDateController.text = DateFormat('MMM yyyy').format(picked);
      });
    }
  }

  void _submit({bool addAnother = false}) async {
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

      setState(() {
        _submitting = true;
        _addAnother = addAnother;
      });

      final gstPercentage = double.tryParse(_selectedGst.replaceAll('%', '')) ?? 12.0;
      final reorderLevel = int.tryParse(_reorderLevelController.text.trim()) ?? 10;
      final prescriptionRequired = _selectedDrugType == 'Prescription';

      // Parse Expiry Date from MMM yyyy
      String parsedExpiry = DateTime.now().toUtc().toIso8601String();
      if (_expiryDateController.text.isNotEmpty) {
        try {
          final date = DateFormat('MMM yyyy').parse(_expiryDateController.text);
          parsedExpiry = date.toUtc().toIso8601String();
        } catch (_) {
          // If parsing fails, fallback
        }
      }

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
          mrp: double.tryParse(_mrpController.text.trim()) ?? 0.0,
          purchasePrice: double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
          batchNumber: _batchNumberController.text.trim(),
          quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
          expiryDate: parsedExpiry,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.medicine != null 
                  ? 'Medicine updated successfully!' 
                  : 'Medicine added successfully!'),
              backgroundColor: const Color(0xFF0D9488),
            ),
          );
          
          if (addAnother) {
            // Reset form for next entry
            _formKey.currentState!.reset();
            _nameController.clear();
            _genericNameController.clear();
            _mrpController.clear();
            _purchasePriceController.text = '0.00';
            _batchNumberController.clear();
            _quantityController.text = '0';
            _expiryDateController.clear();
            _barcodeController.clear();
            _supplierController.clear();
            _notesController.clear();
            setState(() {
              _selectedCategoryId = null;
              _selectedManufacturerId = null;
            });
          } else {
            Navigator.of(context).pop(true);
          }
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0D9488)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D9488),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Divider(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8))),
      ],
    );
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
        width: 800,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
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

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- BASIC INFO ---
                      _buildSectionHeader('Basic Info', Icons.info_outline),
                      const SizedBox(height: 20),
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
                              label: 'GENERIC NAME',
                              hint: 'e.g. Amoxicillin',
                              controller: _genericNameController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                                Autocomplete<Manufacturer>(
                                  displayStringForOption: (option) => option.name,
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) return manufacturers;
                                    return manufacturers.where((m) => m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                  },
                                  onSelected: (selection) => setState(() => _selectedManufacturerId = selection.id),
                                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                    if (isEditMode && _selectedManufacturerId != null && controller.text.isEmpty) {
                                      final man = manufacturers.where((m) => m.id == _selectedManufacturerId).firstOrNull;
                                      if (man != null) controller.text = man.name;
                                    }
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      style: const TextStyle(color: textDark, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Select or search manufacturer',
                                        hintStyle: const TextStyle(color: softGrey, fontSize: 14),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal, width: 1.8)),
                                        suffixIcon: const Icon(Icons.arrow_drop_down, color: softGrey),
                                      ),
                                    );
                                  },
                                  optionsViewBuilder: (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(8),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: options.length,
                                            itemBuilder: (context, index) {
                                              final option = options.elementAt(index);
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Text(option.name, style: const TextStyle(color: textDark)),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal, width: 1.8)),
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DRUG TYPE',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: softGrey),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedDrugType,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal, width: 1.8)),
                                  ),
                                  style: const TextStyle(color: textDark, fontSize: 14),
                                  items: const [
                                    DropdownMenuItem(value: 'OTC', child: Text('OTC')),
                                    DropdownMenuItem(value: 'Prescription', child: Text('Prescription')),
                                    DropdownMenuItem(value: 'Controlled Drug', child: Text('Controlled Drug')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedDrugType = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: const SizedBox()), // Spacer
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // --- INVENTORY ---
                      _buildSectionHeader('Inventory', Icons.inventory_2_outlined),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'BATCH NUMBER *',
                              hint: 'e.g. B-20241',
                              controller: _batchNumberController,
                              enabled: !isEditMode,
                              validator: isEditMode ? null : (val) => val == null || val.trim().isEmpty ? 'Enter batch' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                    hintText: 'MMM yyyy',
                                    hintStyle: const TextStyle(color: softGrey, fontSize: 14),
                                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: softGrey, size: 16),
                                    filled: true,
                                    fillColor: isEditMode ? const Color(0xFFF1F5F9) : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal, width: 1.8)),
                                  ),
                                  validator: isEditMode ? null : (val) => val == null || val.isEmpty ? 'Select expiry' : null,
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
                              label: 'STOCK QUANTITY *',
                              hint: '0',
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              enabled: !isEditMode,
                              validator: isEditMode ? null : (val) {
                                if (val == null || val.isEmpty) return 'Enter quantity';
                                if (int.tryParse(val) == null) return 'Must be an integer';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'REORDER LEVEL',
                              hint: '10',
                              controller: _reorderLevelController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- PRICING ---
                      _buildSectionHeader('Pricing', Icons.currency_rupee_outlined),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'MRP *',
                              hint: '0.00',
                              controller: _mrpController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !isEditMode,
                              prefixText: '₹ ',
                              validator: isEditMode ? null : (val) {
                                if (val == null || val.isEmpty) return 'Enter MRP';
                                if (double.tryParse(val) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'PURCHASE COST',
                              hint: '0.00',
                              controller: _purchasePriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !isEditMode,
                              prefixText: '₹ ',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal, width: 1.8)),
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
                                      _calculatePricing();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('PROFIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: softGrey)),
                                      Text(
                                        '${_calculatedMargin.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _calculatedMargin > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('GST AMT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: softGrey)),
                                      Text(
                                        '₹${_calculatedGstAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- OPTIONAL ---
                      _buildSectionHeader('Optional Details', Icons.more_horiz),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'BARCODE / SKU',
                              hint: 'Scan or enter barcode',
                              controller: _barcodeController,
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                                  label: const Text('Scan'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryTeal,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'HSN CODE',
                              hint: 'e.g. 3004',
                              controller: _hsnCodeController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                              hint: 'Any additional notes',
                              controller: _notesController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(color: borderGrey, height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: softGrey, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(width: 16),
                  if (!isEditMode)
                    OutlinedButton(
                      onPressed: _submitting ? null : () => _submit(addAnother: true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _submitting && _addAnother
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(primaryTeal)))
                          : const Text('Save & Add Another', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  if (!isEditMode) const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(addAnother: false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _submitting && !_addAnother
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : Text(isEditMode ? 'Save Changes' : 'Add Medicine', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
    String? prefixText,
    Widget? suffixIcon,
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
            hintStyle: TextStyle(color: softGrey.withValues(alpha: 0.6), fontSize: 14),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal, width: 1.8)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
