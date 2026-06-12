import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isFormValid = false;
  bool _autoGenerateBarcode = false;

  final FocusNode _batchNumberFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _purchasePriceFocus = FocusNode();
  final FocusNode _mrpFocus = FocusNode();

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

  @override
  void initState() {
    super.initState();
    final nextYear = DateTime.now().add(const Duration(days: 365));
    _selectedMonth = _months[nextYear.month - 1];
    _selectedYear = nextYear.year;
    _updateExpiryDate();

    _batchNumberController.addListener(_validateFormQuietly);
    _quantityController.addListener(_validateFormQuietly);
    _purchasePriceController.addListener(_validateFormQuietly);
    _mrpController.addListener(_validateFormQuietly);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateFormQuietly();
    });
  }

  void _updateExpiryDate() {
    if (_selectedMonth != null && _selectedYear != null) {
      final monthIndex = _months.indexOf(_selectedMonth!) + 1;
      final monthStr = monthIndex.toString().padLeft(2, '0');
      _expiryDateController.text = '$_selectedYear-$monthStr-01';
    }
  }

  void _validateFormQuietly() {
    final batch = _batchNumberController.text.trim();
    final qtyStr = _quantityController.text.trim();
    final purchaseStr = _purchasePriceController.text.trim();
    final mrpStr = _mrpController.text.trim();

    bool isValid = true;
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

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _batchNumberController.removeListener(_validateFormQuietly);
    _quantityController.removeListener(_validateFormQuietly);
    _purchasePriceController.removeListener(_validateFormQuietly);
    _mrpController.removeListener(_validateFormQuietly);

    _batchNumberController.dispose();
    _quantityController.dispose();
    _expiryDateController.dispose();
    _purchasePriceController.dispose();
    _mrpController.dispose();
    _batchNumberFocus.dispose();
    _quantityFocus.dispose();
    _purchasePriceFocus.dispose();
    _mrpFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_isFormValid) return;
    if (_formKey.currentState!.validate()) {
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

      setState(() => _submitting = true);

      final bool success = await ref
          .read(inventoryNotifierProvider.notifier)
          .addBatch(
            medicineId: widget.medicine.id,
            batchNumber: _batchNumberController.text.trim(),
            quantity: int.parse(_quantityController.text.trim()),
            expiryDate: DateTime.parse(
              _expiryDateController.text,
            ).toUtc().toIso8601String(),
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
          final error =
              ref.read(inventoryNotifierProvider).errorMessage ??
              'Failed to add batch';
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Dialog(
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
                    ),
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
                                autofocus: true,
                                focusNode: _batchNumberFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_quantityFocus),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Enter batch number'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EXPIRY DATE',
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
                                            fillColor: Colors.white,
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
                                          style: const TextStyle(
                                            color: textDark,
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
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedMonth = val;
                                              _updateExpiryDate();
                                              _validateFormQuietly();
                                            });
                                          },
                                          validator: (val) => val == null
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
                                            fillColor: Colors.white,
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
                                          style: const TextStyle(
                                            color: textDark,
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
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedYear = val;
                                              _updateExpiryDate();
                                              _validateFormQuietly();
                                            });
                                          },
                                          validator: (val) {
                                            if (val == null) {
                                              return 'Select year';
                                            }
                                            if (_selectedMonth != null) {
                                              final now = DateTime.now();
                                              final selectedDate = DateTime(
                                                val,
                                                _months.indexOf(
                                                      _selectedMonth!,
                                                    ) +
                                                    1,
                                              );
                                              final currentMonthDate = DateTime(
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
                                label: 'QUANTITY',
                                hint: 'e.g. 100',
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                focusNode: _quantityFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_purchasePriceFocus),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (val) {
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                focusNode: _purchasePriceFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_mrpFocus),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Enter price';
                                  }
                                  if (double.tryParse(val) == null) {
                                    return 'Must be a number';
                                  }
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                focusNode: _mrpFocus,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Enter MRP';
                                  }
                                  final mrpVal = double.tryParse(val);
                                  if (mrpVal == null) return 'Must be a number';
                                  final purchaseVal =
                                      double.tryParse(
                                        _purchasePriceController.text.trim(),
                                      ) ??
                                      0.0;
                                  if (mrpVal < purchaseVal) {
                                    return 'MRP cannot be less than purchase price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        side: const BorderSide(color: borderGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: softGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (_submitting || !_isFormValid)
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
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
                      child: _submitting
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
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  '+ Add Batch',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
          focusNode: focusNode,
          autofocus: autofocus,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onFieldSubmitted,
          textInputAction: textInputAction,
          style: const TextStyle(color: textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: softGrey, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
