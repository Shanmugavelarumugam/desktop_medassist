import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../domain/models/purchase.dart';
import '../notifier/purchase_notifier.dart';

class CreatePoDialog extends ConsumerStatefulWidget {
  const CreatePoDialog({super.key});

  @override
  ConsumerState<CreatePoDialog> createState() => _CreatePoDialogState();
}

class _CreatePoDialogState extends ConsumerState<CreatePoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _priceController = TextEditingController();
  final _gstController = TextEditingController(text: '12');

  Supplier? _selectedSupplier;
  Medicine? _selectedMedicine;
  final List<Map<String, dynamic>> _items = [];

  double _subtotal = 0.0;
  double _gstAmount = 0.0;
  double _totalAmount = 0.0;

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double sub = 0.0;
    double gst = 0.0;

    for (final item in _items) {
      final int qty = item['quantity'] as int;
      final double price = item['unitPrice'] as double;
      final double gstPct = item['gstPercentage'] as double;

      final double itemSub = qty * price;
      final double itemGst = itemSub * (gstPct / 100);

      sub += itemSub;
      gst += itemGst;
    }

    setState(() {
      _subtotal = sub;
      _gstAmount = gst;
      _totalAmount = sub + gst;
    });
  }

  void _addItem() {
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medicine first.')),
      );
      return;
    }

    final int qty = int.tryParse(_quantityController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final double gstPct = double.tryParse(_gstController.text) ?? 12.0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0.')),
      );
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit price must be greater than 0.')),
      );
      return;
    }

    // Check if item already exists
    final existingIndex = _items.indexWhere((item) => item['medicineId'] == _selectedMedicine!.id);
    final double itemTotal = (qty * price) * (1 + gstPct / 100);

    final itemMap = {
      'medicineId': _selectedMedicine!.id,
      'medicineName': _selectedMedicine!.name,
      'quantity': qty,
      'unitPrice': price,
      'gstPercentage': gstPct,
      'currentStock': _selectedMedicine!.stock,
      'reorderQty': qty,
      'totalAmount': double.parse(itemTotal.toStringAsFixed(2)),
    };

    setState(() {
      if (existingIndex != -1) {
        _items[existingIndex] = itemMap;
      } else {
        _items.add(itemMap);
      }
      // Reset selected medicine fields
      _selectedMedicine = null;
      _priceController.clear();
      _quantityController.text = '100';
      _gstController.text = '12';
    });

    _calculateTotals();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotals();
  }

  Future<void> _submitPO() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the purchase order.')),
      );
      return;
    }

    final success = await ref.read(purchaseNotifierProvider.notifier).createPurchaseOrder(
          supplierId: _selectedSupplier!.id,
          items: _items,
          subtotal: double.parse(_subtotal.toStringAsFixed(2)),
          gstAmount: double.parse(_gstAmount.toStringAsFixed(2)),
          totalAmount: double.parse(_totalAmount.toStringAsFixed(2)),
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase Order created successfully as DRAFT!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      } else {
        final error = ref.read(purchaseNotifierProvider).errorMessage ?? 'Failed to create PO';
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

    final purchaseState = ref.watch(purchaseNotifierProvider);
    final inventoryState = ref.watch(inventoryNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Purchase Order',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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

              // Top row: Supplier selection & Notes
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supplier Dropdown
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Supplier',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Supplier>(
                          initialValue: _selectedSupplier,
                          hint: const Text('Select Supplier'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderGrey),
                            ),
                          ),
                          items: purchaseState.suppliers.map((sup) {
                            return DropdownMenuItem<Supplier>(
                              value: sup,
                              child: Text(sup.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSupplier = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Notes Text Field
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Purchase Notes (Optional)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            hintText: 'Enter any instructions or notes for the supplier...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderGrey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Divider(color: borderGrey, height: 1),
              const SizedBox(height: 20),

              // Medicine search & Add section
              const Text(
                'Add Medicines to Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Medicine Autocomplete
                  Expanded(
                    flex: 3,
                    child: Autocomplete<Medicine>(
                      displayStringForOption: (option) => option.name,
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Medicine>.empty();
                        }
                        return inventoryState.medicines.where((med) {
                          return med.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                              (med.genericName != null &&
                                  med.genericName!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        });
                      },
                      onSelected: (option) {
                        setState(() {
                          _selectedMedicine = option;
                          _priceController.text = option.purchasePrice.toStringAsFixed(2);
                          _gstController.text = (option.gstPercentage ?? 12.0).toStringAsFixed(0);
                        });
                      },
                      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search medicine by name or generic...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixIcon: const Icon(Icons.search, size: 20, color: softGrey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderGrey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Quantity
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Qty',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Unit Price
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Unit Price (₹)',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // GST %
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _gstController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'GST %',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Add Button
                  ElevatedButton(
                    onPressed: _addItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Items table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderGrey),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: _items.isEmpty
                      ? const Center(
                          child: Text(
                            'No items added to the purchase order yet.',
                            style: TextStyle(color: softGrey, fontWeight: FontWeight.w500),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(4),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(2),
                                3: FlexColumnWidth(2),
                                4: FlexColumnWidth(2),
                                5: FixedColumnWidth(60),
                              },
                              children: [
                                // Table Header
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _buildTableHeader('MEDICINE'),
                                    _buildTableHeader('QTY'),
                                    _buildTableHeader('UNIT PRICE (₹)'),
                                    _buildTableHeader('GST %'),
                                    _buildTableHeader('TOTAL (₹)'),
                                    const TableCell(child: SizedBox()),
                                  ],
                                ),
                                // Table Body Rows
                                ..._items.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return TableRow(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      border: Border(bottom: BorderSide(color: borderGrey)),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(
                                          item['medicineName'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.w600, color: textDark),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text('${item['quantity']}'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text('₹${(item['unitPrice'] as double).toStringAsFixed(2)}'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text('${item['gstPercentage']}%'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(
                                          '₹${(item['totalAmount'] as double).toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                                        ),
                                      ),
                                      TableCell(
                                        verticalAlignment: TableCellVerticalAlignment.middle,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () => _removeItem(index),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Section: Summary & Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Totals summary panel
                  Row(
                    children: [
                      _buildTotalSummaryCard('SUBTOTAL', _subtotal),
                      const SizedBox(width: 24),
                      _buildTotalSummaryCard('GST AMOUNT', _gstAmount),
                      const SizedBox(width: 24),
                      _buildTotalSummaryCard('TOTAL AMOUNT', _totalAmount, highlight: true),
                    ],
                  ),

                  // Actions
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          side: const BorderSide(color: borderGrey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _submitPO,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Create PO (Draft)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTotalSummaryCard(String title, double amount, {bool highlight = false}) {
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const softGrey = Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: softGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: highlight ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: highlight ? primaryTeal : textDark,
          ),
        ),
      ],
    );
  }
}
