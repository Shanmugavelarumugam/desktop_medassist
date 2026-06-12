import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isFormValid = false;
  bool _autoGenerateBarcode = false;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _genericNameFocus = FocusNode();
  final FocusNode _batchNumberFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _reorderLevelFocus = FocusNode();
  final FocusNode _mrpFocus = FocusNode();
  final FocusNode _purchasePriceFocus = FocusNode();
  final FocusNode _barcodeFocus = FocusNode();
  final FocusNode _hsnCodeFocus = FocusNode();
  final FocusNode _supplierFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  final List<String> _months = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final List<int> _years = List.generate(
    15,
    (index) => DateTime.now().year + index,
  );

  String? _selectedMonth;
  int? _selectedYear;

  void _updateExpiryDate() {
    if (_selectedMonth != null && _selectedYear != null) {
      _expiryDateController.text = '$_selectedMonth $_selectedYear';
    }
  }

  void _validateFormQuietly() {
    bool isValid = true;
    if (_nameController.text.trim().isEmpty) isValid = false;
    if (_selectedCategoryId == null) isValid = false;

    if (widget.medicine == null) {
      // Add mode fields validation
      final batch = _batchNumberController.text.trim();
      final qtyStr = _quantityController.text.trim();
      final purchaseStr = _purchasePriceController.text.trim();
      final mrpStr = _mrpController.text.trim();

      if (batch.isEmpty) isValid = false;

      final qty = int.tryParse(qtyStr);
      if (qty == null || qty <= 0) isValid = false;

      final purchase = double.tryParse(purchaseStr);
      if (purchase == null || purchase < 0) isValid = false;

      final mrp = double.tryParse(mrpStr);
      if (mrp == null || mrp < 0 || (purchase != null && mrp < purchase)) {
        isValid = false;
      }

      if (_selectedMonth == null || _selectedYear == null) {
        isValid = false;
      } else {
        final now = DateTime.now();
        final selectedDate = DateTime(
          _selectedYear!,
          _months.indexOf(_selectedMonth!) + 1,
        );
        final currentMonthDate = DateTime(now.year, now.month);
        if (selectedDate.isBefore(currentMonthDate)) {
          isValid = false;
        }
      }
    }

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _mrpController.addListener(_calculatePricing);
    _purchasePriceController.addListener(_calculatePricing);
    _quantityController.addListener(_calculateReorderLevel);

    _nameController.addListener(_validateFormQuietly);
    _batchNumberController.addListener(_validateFormQuietly);
    _quantityController.addListener(_validateFormQuietly);
    _mrpController.addListener(_validateFormQuietly);
    _purchasePriceController.addListener(_validateFormQuietly);

    if (widget.medicine != null) {
      _nameController.text = widget.medicine!.name;
      _genericNameController.text = widget.medicine!.genericName ?? '';
      _selectedCategoryId = widget.medicine!.categoryId;
      _selectedManufacturerId = widget.medicine!.manufacturerId;
      _selectedDrugType = widget.medicine!.prescriptionRequired == true
          ? 'Prescription'
          : 'OTC';
      _reorderLevelController.text = (widget.medicine!.reorderLevel ?? 10)
          .toString();
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
          _selectedMonth = _months[date.month - 1];
          _selectedYear = date.year;
        } catch (_) {}
      }
    } else {
      final nextYear = DateTime.now().add(const Duration(days: 365));
      _selectedMonth = _months[nextYear.month - 1];
      _selectedYear = nextYear.year;
      _updateExpiryDate();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateFormQuietly();
    });
  }

  @override
  void dispose() {
    _mrpController.removeListener(_calculatePricing);
    _purchasePriceController.removeListener(_calculatePricing);
    _quantityController.removeListener(_calculateReorderLevel);

    _nameController.removeListener(_validateFormQuietly);
    _batchNumberController.removeListener(_validateFormQuietly);
    _quantityController.removeListener(_validateFormQuietly);
    _mrpController.removeListener(_validateFormQuietly);
    _purchasePriceController.removeListener(_validateFormQuietly);

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
    _nameFocus.dispose();
    _genericNameFocus.dispose();
    _batchNumberFocus.dispose();
    _quantityFocus.dispose();
    _reorderLevelFocus.dispose();
    _mrpFocus.dispose();
    _purchasePriceFocus.dispose();
    _barcodeFocus.dispose();
    _hsnCodeFocus.dispose();
    _supplierFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _calculatePricing() {
    final mrp = double.tryParse(_mrpController.text.trim()) ?? 0.0;
    final purchase =
        double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
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
      _reorderLevelController.text = autoReorder > 0
          ? autoReorder.toString()
          : '';
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

      if (widget.medicine == null) {
        final now = DateTime.now();
        final selectedDate = DateTime(
          _selectedYear!,
          _months.indexOf(_selectedMonth!) + 1,
        );
        final currentMonthDate = DateTime(now.year, now.month);
        if (selectedDate.isBefore(currentMonthDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expiry date cannot be in the past'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
      }

      final double purchasePrice =
          double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
      final double mrp = double.tryParse(_mrpController.text.trim()) ?? 0.0;
      if (mrp < purchasePrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MRP cannot be less than purchase price'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      setState(() {
        _submitting = true;
        _addAnother = addAnother;
      });

      final gstPercentage =
          double.tryParse(_selectedGst.replaceAll('%', '')) ?? 12.0;
      final reorderLevel =
          int.tryParse(_reorderLevelController.text.trim()) ?? 10;
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
        success = await ref
            .read(inventoryNotifierProvider.notifier)
            .updateMedicine(
              id: widget.medicine!.id,
              name: _nameController.text.trim(),
              genericName: _genericNameController.text.trim(),
              categoryId: _selectedCategoryId!,
              manufacturerId: _selectedManufacturerId,
              gstPercentage: gstPercentage,
              reorderLevel: reorderLevel,
              prescriptionRequired: prescriptionRequired,
              hsnCode: _hsnCodeController.text.trim().isEmpty
                  ? null
                  : _hsnCodeController.text.trim(),
              barcode: _barcodeController.text.trim().isEmpty
                  ? null
                  : _barcodeController.text.trim(),
              supplier: _supplierController.text.trim().isEmpty
                  ? null
                  : _supplierController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      } else {
        // Add mode
        success = await ref
            .read(inventoryNotifierProvider.notifier)
            .createMedicine(
              name: _nameController.text.trim(),
              genericName: _genericNameController.text.trim(),
              mrp: double.tryParse(_mrpController.text.trim()) ?? 0.0,
              purchasePrice:
                  double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
              batchNumber: _batchNumberController.text.trim(),
              quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
              expiryDate: parsedExpiry,
              categoryId: _selectedCategoryId!,
              manufacturerId: _selectedManufacturerId,
              gstPercentage: gstPercentage,
              reorderLevel: reorderLevel,
              prescriptionRequired: prescriptionRequired,
              hsnCode: _hsnCodeController.text.trim().isEmpty
                  ? null
                  : _hsnCodeController.text.trim(),
              barcode: _barcodeController.text.trim().isEmpty
                  ? null
                  : _barcodeController.text.trim(),
              supplier: _supplierController.text.trim().isEmpty
                  ? null
                  : _supplierController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      }

      if (mounted) {
        setState(() => _submitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.medicine != null
                    ? 'Medicine updated successfully!'
                    : 'Medicine added successfully!',
              ),
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
          final error =
              ref.read(inventoryNotifierProvider).errorMessage ??
              (widget.medicine != null
                  ? 'Failed to update medicine'
                  : 'Failed to add medicine');
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
        Expanded(
          child: Divider(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
        ),
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
            _submit(addAnother: false),
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () =>
            _submit(addAnother: false),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 800,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
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
                    ),
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
                                autofocus: true,
                                focusNode: _nameFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_genericNameFocus),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'Enter name'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                label: 'GENERIC NAME',
                                hint: 'e.g. Amoxicillin',
                                controller: _genericNameController,
                                focusNode: _genericNameFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_batchNumberFocus),
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: softGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Autocomplete<Manufacturer>(
                                    displayStringForOption: (option) =>
                                        option.name,
                                    optionsBuilder: (textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return manufacturers;
                                      }
                                      return manufacturers.where(
                                        (m) => m.name.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        ),
                                      );
                                    },
                                    onSelected: (selection) => setState(
                                      () => _selectedManufacturerId =
                                          selection.id,
                                    ),
                                    fieldViewBuilder:
                                        (
                                          context,
                                          controller,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          if (isEditMode &&
                                              _selectedManufacturerId != null &&
                                              controller.text.isEmpty) {
                                            final man = manufacturers
                                                .where(
                                                  (m) =>
                                                      m.id ==
                                                      _selectedManufacturerId,
                                                )
                                                .firstOrNull;
                                            if (man != null) {
                                              controller.text = man.name;
                                            }
                                          }
                                          return TextFormField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            style: const TextStyle(
                                              color: textDark,
                                              fontSize: 14,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Select or search manufacturer',
                                              hintStyle: const TextStyle(
                                                color: softGrey,
                                                fontSize: 14,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: borderGrey,
                                                  width: 1.2,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: borderGrey,
                                                  width: 1.2,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: primaryTeal,
                                                  width: 1.8,
                                                ),
                                              ),
                                              suffixIcon: const Icon(
                                                Icons.arrow_drop_down,
                                                color: softGrey,
                                              ),
                                            ),
                                          );
                                        },
                                    optionsViewBuilder:
                                        (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 4,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 200,
                                                      maxWidth: 300,
                                                    ),
                                                child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  itemCount: options.length,
                                                  itemBuilder: (context, index) {
                                                    final option = options
                                                        .elementAt(index);
                                                    return InkWell(
                                                      onTap: () =>
                                                          onSelected(option),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              16.0,
                                                            ),
                                                        child: Text(
                                                          option.name,
                                                          style:
                                                              const TextStyle(
                                                                color: textDark,
                                                              ),
                                                        ),
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: softGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedCategoryId,
                                    hint: const Text(
                                      'Select Category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: softGrey,
                                      ),
                                    ),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: borderGrey,
                                          width: 1.2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: borderGrey,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: primaryTeal,
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 14,
                                    ),
                                    items: categories.map((cat) {
                                      return DropdownMenuItem<String>(
                                        value: cat.id,
                                        child: Text(cat.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCategoryId = val;
                                        _validateFormQuietly();
                                      });
                                    },
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: softGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedDrugType,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: borderGrey,
                                          width: 1.2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: borderGrey,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: primaryTeal,
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 14,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'OTC',
                                        child: Text('OTC'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Prescription',
                                        child: Text('Prescription'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Controlled Drug',
                                        child: Text('Controlled Drug'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedDrugType = val);
                                      }
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
                        _buildSectionHeader(
                          'Inventory',
                          Icons.inventory_2_outlined,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'BATCH NUMBER *',
                                hint: 'e.g. B-20241',
                                controller: _batchNumberController,
                                enabled: !isEditMode,
                                focusNode: _batchNumberFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_quantityFocus),
                                validator: isEditMode
                                    ? null
                                    : (val) => val == null || val.trim().isEmpty
                                          ? 'Enter batch'
                                          : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EXPIRY DATE *',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: softGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedMonth,
                                          isExpanded: true,
                                          hint: const Text(
                                            'Month',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: softGrey,
                                            ),
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: isEditMode
                                                ? const Color(0xFFF1F5F9)
                                                : Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: borderGrey,
                                                width: 1.2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: borderGrey,
                                                width: 1.2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: primaryTeal,
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: isEditMode
                                                ? softGrey
                                                : textDark,
                                            fontSize: 14,
                                          ),
                                          items: _months
                                              .map(
                                                (m) => DropdownMenuItem(
                                                  value: m,
                                                  child: Text(m),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: isEditMode
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    _selectedMonth = val;
                                                    _updateExpiryDate();
                                                    _validateFormQuietly();
                                                  });
                                                },
                                          validator: isEditMode
                                              ? null
                                              : (val) => val == null
                                                    ? 'Select month'
                                                    : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 6,
                                        child: DropdownButtonFormField<int>(
                                          initialValue: _selectedYear,
                                          isExpanded: true,
                                          hint: const Text(
                                            'Year',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: softGrey,
                                            ),
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: isEditMode
                                                ? const Color(0xFFF1F5F9)
                                                : Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: borderGrey,
                                                width: 1.2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: borderGrey,
                                                width: 1.2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: primaryTeal,
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: isEditMode
                                                ? softGrey
                                                : textDark,
                                            fontSize: 14,
                                          ),
                                          items: _years
                                              .map(
                                                (y) => DropdownMenuItem(
                                                  value: y,
                                                  child: Text(y.toString()),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: isEditMode
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    _selectedYear = val;
                                                    _updateExpiryDate();
                                                    _validateFormQuietly();
                                                  });
                                                },
                                          validator: isEditMode
                                              ? null
                                              : (val) {
                                                  if (val == null) {
                                                    return 'Select year';
                                                  }
                                                  if (_selectedMonth != null) {
                                                    final now = DateTime.now();
                                                    final selectedDate =
                                                        DateTime(
                                                          val,
                                                          _months.indexOf(
                                                                _selectedMonth!,
                                                              ) +
                                                              1,
                                                        );
                                                    final currentMonthDate =
                                                        DateTime(
                                                          now.year,
                                                          now.month,
                                                        );
                                                    if (selectedDate.isBefore(
                                                      currentMonthDate,
                                                    )) {
                                                      return 'Past expiry';
                                                    }
                                                  }
                                                  return null;
                                                },
                                        ),
                                      ),
                                    ],
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
                                focusNode: _quantityFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_reorderLevelFocus),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: isEditMode
                                    ? null
                                    : (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'Enter quantity';
                                        }
                                        if (int.tryParse(val) == null) {
                                          return 'Must be an integer';
                                        }
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
                                focusNode: _reorderLevelFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_mrpFocus),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // --- PRICING ---
                        _buildSectionHeader(
                          'Pricing',
                          Icons.currency_rupee_outlined,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'MRP *',
                                hint: '0.00',
                                controller: _mrpController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                enabled: !isEditMode,
                                prefixText: '₹ ',
                                focusNode: _mrpFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_purchasePriceFocus),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                validator: isEditMode
                                    ? null
                                    : (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'Enter MRP';
                                        }
                                        final mrpVal = double.tryParse(val);
                                        if (mrpVal == null) {
                                          return 'Invalid number';
                                        }
                                        final purchaseVal =
                                            double.tryParse(
                                              _purchasePriceController.text
                                                  .trim(),
                                            ) ??
                                            0.0;
                                        if (mrpVal < purchaseVal) {
                                          return 'MRP cannot be less than purchase price';
                                        }
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                enabled: !isEditMode,
                                prefixText: '₹ ',
                                focusNode: _purchasePriceFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_barcodeFocus),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
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
                                    'GST %',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: softGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedGst,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: borderGrey,
                                          width: 1.2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: borderGrey,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: primaryTeal,
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 14,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: '0%',
                                        child: Text('0%'),
                                      ),
                                      DropdownMenuItem(
                                        value: '5%',
                                        child: Text('5%'),
                                      ),
                                      DropdownMenuItem(
                                        value: '12%',
                                        child: Text('12%'),
                                      ),
                                      DropdownMenuItem(
                                        value: '18%',
                                        child: Text('18%'),
                                      ),
                                      DropdownMenuItem(
                                        value: '28%',
                                        child: Text('28%'),
                                      ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'PROFIT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: softGrey,
                                          ),
                                        ),
                                        Text(
                                          '${_calculatedMargin.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _calculatedMargin > 0
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: const Color(0xFFCBD5E1),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'GST AMT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: softGrey,
                                          ),
                                        ),
                                        Text(
                                          '₹${_calculatedGstAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textDark,
                                          ),
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
                        _buildSectionHeader(
                          'Optional Details',
                          Icons.more_horiz,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'BARCODE / SKU',
                                hint: 'Scan or enter barcode',
                                controller: _barcodeController,
                                focusNode: _barcodeFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_hsnCodeFocus),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: TextButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Scan'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: primaryTeal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
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
                                focusNode: _hsnCodeFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_supplierFocus),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _autoGenerateBarcode,
                                onChanged: (val) {
                                  setState(() {
                                    _autoGenerateBarcode = val ?? false;
                                  });
                                },
                                activeColor: primaryTeal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Auto-generate batch barcode',
                              style: TextStyle(
                                fontSize: 13,
                                color: textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'SUPPLIER',
                                hint: 'e.g. Cipla Distributors',
                                controller: _supplierController,
                                focusNode: _supplierFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_notesFocus),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                label: 'NOTES',
                                hint: 'Any additional notes',
                                controller: _notesController,
                                focusNode: _notesFocus,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _submit(addAnother: false),
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
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: softGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isEditMode)
                      OutlinedButton(
                        onPressed: (_submitting || !_isFormValid)
                            ? null
                            : () => _submit(addAnother: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _submitting && _addAnother
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    primaryTeal,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save & Add Another',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    if (!isEditMode) const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: (_submitting || !_isFormValid)
                          ? null
                          : () => _submit(addAnother: false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryTeal.withValues(
                          alpha: 0.5,
                        ),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _submitting && !_addAnother
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isEditMode ? Icons.save_rounded : Icons.add,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isEditMode
                                      ? 'Save Changes'
                                      : '+ Add Medicine',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
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
    FocusNode? focusNode,
    bool autofocus = false,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onFieldSubmitted,
    TextInputAction? textInputAction,
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: softGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          focusNode: focusNode,
          autofocus: autofocus,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onFieldSubmitted,
          textInputAction: textInputAction,
          style: TextStyle(color: enabled ? textDark : softGrey, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: softGrey.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            suffixIcon: suffixIcon,
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
