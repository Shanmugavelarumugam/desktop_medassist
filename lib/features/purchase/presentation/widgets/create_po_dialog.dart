import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
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
  final _invoiceDateController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _searchController = TextEditingController();
  final _manualMedicineController = TextEditingController();

  Supplier? _selectedSupplier;
  final List<Map<String, dynamic>> _items = [];
  String _activeTab = 'Recent'; // Scan, Manual, Recent
  String _searchQuery = '';

  double _subtotal = 0.0;
  double _gstAmount = 0.0;
  double _totalAmount = 0.0;

  // File picker state
  PlatformFile? _uploadedFile;
  String? _fileError;
  bool _submitting = false;

  // Simulated scan state
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    // Default invoice date to current date formatted as MM/dd/yyyy
    _invoiceDateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _invoiceDateController.dispose();
    _invoiceNumberController.dispose();
    _searchController.dispose();
    _manualMedicineController.dispose();
    for (final item in _items) {
      (item['qtyController'] as TextEditingController).dispose();
      (item['costController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _calculateTotals() {
    double sub = 0.0;
    double gst = 0.0;

    for (final item in _items) {
      final qtyController = item['qtyController'] as TextEditingController;
      final costController = item['costController'] as TextEditingController;

      final int qty = int.tryParse(qtyController.text) ?? 0;
      final double cost = double.tryParse(costController.text) ?? 0.0;
      final double gstPct = item['gstPercentage'] as double;

      final double itemSub = qty * cost;
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

  Medicine? _findMedicineByName(String name) {
    final inventoryState = ref.read(inventoryNotifierProvider);
    try {
      return inventoryState.medicines.firstWhere(
        (m) => m.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void _addMedicineToItems(Medicine med, {String? customName}) {
    final displayName = customName ?? med.name;
    final existingIndex = _items.indexWhere((item) => item['medicineName'] == displayName);

    if (existingIndex != -1) {
      final item = _items[existingIndex];
      final qtyController = item['qtyController'] as TextEditingController;
      final currentQty = int.tryParse(qtyController.text) ?? 0;
      qtyController.text = (currentQty + 1).toString();
      return;
    }

    final double price = med.purchasePrice > 0 ? med.purchasePrice : 15.00;
    final double gstPct = med.gstPercentage?.toDouble() ?? 12.0;

    final qtyController = TextEditingController(text: '10');
    final costController = TextEditingController(text: price.toStringAsFixed(2));

    final Map<String, dynamic> itemMap = {
      'medicineId': med.id,
      'medicineName': displayName,
      'qtyController': qtyController,
      'costController': costController,
      'gstPercentage': gstPct,
      'currentStock': med.stock,
      'reorderQty': 10,
    };

    qtyController.addListener(() {
      _calculateTotals();
    });
    costController.addListener(() {
      _calculateTotals();
    });

    setState(() {
      _items.add(itemMap);
    });
    _calculateTotals();
  }

  void _removeItem(int index) {
    final item = _items[index];
    (item['qtyController'] as TextEditingController).dispose();
    (item['costController'] as TextEditingController).dispose();
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotals();
  }

  Future<void> _selectInvoiceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F766E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _invoiceDateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          setState(() {
            _fileError = 'File exceeds maximum size of 5MB';
            _uploadedFile = null;
          });
        } else {
          setState(() {
            _uploadedFile = file;
            _fileError = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _fileError = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _savePurchase() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine.')),
      );
      return;
    }

    if (_invoiceNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter supplier invoice number.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final List<Map<String, dynamic>> itemsPayload = [];
    for (final item in _items) {
      final qty = int.tryParse((item['qtyController'] as TextEditingController).text) ?? 0;
      final cost = double.tryParse((item['costController'] as TextEditingController).text) ?? 0.0;
      final gstPct = item['gstPercentage'] as double;
      final itemTotal = (qty * cost) * (1 + gstPct / 100);

      itemsPayload.add({
        'medicineId': item['medicineId'],
        'medicineName': item['medicineName'],
        'quantity': qty,
        'unitPrice': cost,
        'gstPercentage': gstPct,
        'currentStock': item['currentStock'],
        'reorderQty': qty,
        'totalAmount': double.parse(itemTotal.toStringAsFixed(2)),
      });
    }

    final String finalNotes = [
      'Invoice No: ${_invoiceNumberController.text.trim()}',
      'Invoice Date: ${_invoiceDateController.text.trim()}',
      if (_uploadedFile != null) 'File: ${_uploadedFile!.name} (${(_uploadedFile!.size / (1024 * 1024)).toStringAsFixed(2)}MB)',
    ].join(' | ');

    final success = await ref.read(purchaseNotifierProvider.notifier).createPurchaseOrder(
          supplierId: _selectedSupplier!.id,
          items: itemsPayload,
          subtotal: double.parse(_subtotal.toStringAsFixed(2)),
          gstAmount: double.parse(_gstAmount.toStringAsFixed(2)),
          totalAmount: double.parse(_totalAmount.toStringAsFixed(2)),
          notes: finalNotes,
        );

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase registered and stock saved successfully!'),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
      } else {
        final error = ref.read(purchaseNotifierProvider).errorMessage ?? 'Failed to save purchase';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _simulateScan() async {
    setState(() => _scanning = true);
    await Future.delayed(const Duration(seconds: 1));
    final inventoryState = ref.read(inventoryNotifierProvider);
    if (inventoryState.medicines.isNotEmpty) {
      final med = (inventoryState.medicines..shuffle()).first;
      _addMedicineToItems(med);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulated barcode scan: Added ${med.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0F766E),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No medicines registered in inventory to simulate scan.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0F766E);
    const accentTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF0F172A);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF8FAFC);

    final purchaseState = ref.watch(purchaseNotifierProvider);
    final inventoryState = ref.watch(inventoryNotifierProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Form(
        key: _formKey,
        child: Container(
          width: 1000,
          height: 760,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER WITH GRADIENT ACCENT LINE
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.inventory_sharp, color: primaryTeal, size: 26),
                            SizedBox(width: 12),
                            Text(
                              'Register Purchase Receipt',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select supplier, input invoice details, add medications, and upload PDF invoice records.',
                          style: TextStyle(color: softGrey, fontSize: 13),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: softGrey, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: borderGrey, height: 1),

              // SPLIT MAIN CONTENT ROW
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT COLUMN (Main Transaction Form)
                    Expanded(
                      flex: 13,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. SUPPLIER DETAILS Title
                            const Text(
                              'SUPPLIER DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: softGrey,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Supplier Details Input Fields Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Supplier dropdown field
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<Supplier>(
                                    initialValue: _selectedSupplier,
                                    dropdownColor: Colors.white,
                                    hint: const Text('Select Supplier...', style: TextStyle(fontSize: 13, color: softGrey, fontWeight: FontWeight.normal)),
                                    decoration: InputDecoration(
                                      labelText: 'SUPPLIER',
                                      labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: softGrey, letterSpacing: 0.5),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      prefixIcon: const Icon(Icons.business_outlined, color: accentTeal, size: 18),
                                      filled: true,
                                      fillColor: bgGrey,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                                    style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
                                    items: purchaseState.suppliers.map((sup) {
                                      return DropdownMenuItem<Supplier>(
                                        value: sup,
                                        child: Text(sup.name, style: const TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedSupplier = val;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Invoice Date
                                Expanded(
                                  child: TextFormField(
                                    controller: _invoiceDateController,
                                    readOnly: true,
                                    onTap: () => _selectInvoiceDate(context),
                                    style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      labelText: 'INVOICE DATE',
                                      labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: softGrey, letterSpacing: 0.5),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      prefixIcon: const Icon(Icons.calendar_today_outlined, color: accentTeal, size: 15),
                                      filled: true,
                                      fillColor: bgGrey,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Supplier Invoice number
                                Expanded(
                                  child: TextFormField(
                                    controller: _invoiceNumberController,
                                    style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      labelText: 'SUPPLIER INV #',
                                      labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: softGrey, letterSpacing: 0.5),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      hintText: 'e.g. CIP-9921',
                                      hintStyle: const TextStyle(color: softGrey, fontSize: 13, fontWeight: FontWeight.normal),
                                      prefixIcon: const Icon(Icons.receipt_outlined, color: accentTeal, size: 15),
                                      filled: true,
                                      fillColor: bgGrey,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // 2. ADD MEDICINES Title
                            const Text(
                              'ADD MEDICINES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: softGrey,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Search Box Field
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: textDark, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search medicine to add...',
                                    hintStyle: const TextStyle(color: softGrey, fontSize: 13),
                                    prefixIcon: const Icon(Icons.search, size: 20, color: softGrey),
                                    filled: true,
                                    fillColor: bgGrey,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val;
                                    });
                                  },
                                ),

                                // Custom autocomplete overlay
                                if (_searchQuery.isNotEmpty)
                                  Positioned(
                                    top: 50,
                                    left: 0,
                                    right: 0,
                                    child: Material(
                                      elevation: 10,
                                      shadowColor: Colors.black.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: borderGrey),
                                        ),
                                        constraints: const BoxConstraints(maxHeight: 220),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: ListView(
                                            shrinkWrap: true,
                                            children: inventoryState.medicines
                                                .where((med) =>
                                                    med.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                                    (med.genericName != null &&
                                                        med.genericName!.toLowerCase().contains(_searchQuery.toLowerCase())))
                                                .map((med) {
                                              return ListTile(
                                                dense: true,
                                                hoverColor: bgGrey,
                                                title: Text(
                                                  med.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13),
                                                ),
                                                subtitle: med.genericName != null
                                                    ? Text(
                                                        med.genericName!,
                                                        style: const TextStyle(color: softGrey, fontSize: 11),
                                                      )
                                                    : null,
                                                trailing: Text(
                                                  'Stock: ${med.stock}',
                                                  style: const TextStyle(color: softGrey, fontSize: 11),
                                                ),
                                                onTap: () {
                                                  _addMedicineToItems(med);
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchQuery = '';
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Segmented Tabs Container (Scan, Manual, Recent)
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                children: [
                                  _buildSegmentedTab('Recent', Icons.history),
                                  _buildSegmentedTab('Scan', Icons.qr_code_scanner),
                                  _buildSegmentedTab('Manual', Icons.edit_note),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Segment Content Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderGrey, width: 1),
                              ),
                              child: _buildSegmentContent(accentTeal, textDark, softGrey, bgGrey),
                            ),
                            const SizedBox(height: 28),

                            // Table label
                            const Text(
                              'ADDED MEDICINES LIST',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: softGrey,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Table widget
                            _buildItemsTable(textDark, borderGrey, softGrey, bgGrey, accentTeal),
                          ],
                        ),
                      ),
                    ),

                    // MIDDLE SEPARATOR
                    const VerticalDivider(color: borderGrey, width: 1),

                    // RIGHT COLUMN (PDF Upload, Totals, Actions)
                    Expanded(
                      flex: 6,
                      child: Container(
                        color: bgGrey,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. PDF Upload Section Title
                            const Text(
                              'DOCUMENT UPLOAD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: softGrey,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Solid Slate upload zone
                            InkWell(
                              onTap: _pickFile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _fileError != null ? Colors.redAccent : const Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: _uploadedFile == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.picture_as_pdf_outlined, color: accentTeal, size: 38),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Click to upload Invoice PDF',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Max size: 5MB • PDF format',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: softGrey,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.check_circle, color: Colors.green, size: 36),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _uploadedFile!.name,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: textDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${(_uploadedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                                  style: TextStyle(fontSize: 11, color: softGrey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            right: -6,
                                            child: IconButton(
                                              icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                                              onPressed: () {
                                                setState(() {
                                                  _uploadedFile = null;
                                                  _fileError = null;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            if (_fileError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _fileError!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                            const SizedBox(height: 28),

                            // 2. Totals panel
                            const Text(
                              'PURCHASE SUMMARY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: softGrey,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderGrey),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal', style: TextStyle(color: softGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                                      Text('₹${_subtotal.toStringAsFixed(2)}', style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('GST (included)', style: TextStyle(color: softGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                                      Text('₹${_gstAmount.toStringAsFixed(2)}', style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(color: borderGrey, height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total', style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800)),
                                      Text('₹${_totalAmount.toStringAsFixed(2)}', style: TextStyle(color: primaryTeal, fontSize: 20, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),

                            // 3. Actions Panel
                            ElevatedButton(
                              onPressed: _submitting ? null : _savePurchase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                    )
                                  : const Text('Save Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: borderGrey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: softGrey, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTab(String label, IconData icon) {
    final isSelected = _activeTab == label;
    const activeColor = Color(0xFF0F766E);
    const inactiveColor = Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = label;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? activeColor : inactiveColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentContent(Color accentTeal, Color textDark, Color softGrey, Color bgGrey) {
    final inventoryState = ref.watch(inventoryNotifierProvider);
    if (_activeTab == 'Recent') {
      final suggestions = inventoryState.medicines.take(4).map((m) => m.name).toList();
      if (suggestions.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'No medicines registered in inventory yet.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((name) {
          return InkWell(
            onTap: () {
              final med = _findMedicineByName(name);
              if (med != null) {
                _addMedicineToItems(med);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, size: 14, color: accentTeal),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } else if (_activeTab == 'Scan') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_scanner_outlined, color: accentTeal, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _scanning ? 'Simulating barcode scanner scan...' : 'Ready to scan medicine barcode...',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text('Click button to simulate barcode scanner hardware receipt', style: TextStyle(color: softGrey, fontSize: 11)),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _scanning ? null : _simulateScan,
            icon: _scanning
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.sensors, size: 14),
            label: const Text('Simulate Scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
          ),
        ],
      );
    } else {
      // Manual Add
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _manualMedicineController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Type custom medicine name to add manually...',
                hintStyle: TextStyle(color: softGrey, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              style: TextStyle(fontSize: 12, color: textDark),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              final name = _manualMedicineController.text.trim();
              if (name.isNotEmpty) {
                final med = _findMedicineByName(name);
                if (med != null) {
                  _addMedicineToItems(med);
                  _manualMedicineController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Medicine "$name" not found in inventory. Please register it in the Stock catalog first.'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Custom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildItemsTable(Color textDark, Color borderGrey, Color softGrey, Color bgGrey, Color accentTeal) {
    if (_items.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: bgGrey,
          border: Border.all(color: borderGrey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 36, color: softGrey.withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              Text(
                'No medicines added yet.',
                style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Search or pick suggestions from above to build receipt.',
                style: TextStyle(color: softGrey, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(10),
      ),
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Column(
          children: [
            // Table Header row
            Container(
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text('Medicine', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: softGrey, letterSpacing: 0.5))),
                  Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: softGrey, letterSpacing: 0.5))),
                  Expanded(flex: 2, child: Text('Cost', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: softGrey, letterSpacing: 0.5))),
                  Expanded(flex: 2, child: Text('Total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: softGrey, letterSpacing: 0.5))),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Divider(color: borderGrey, height: 1),

            // Scrollable rows
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final qtyController = item['qtyController'] as TextEditingController;
                  final costController = item['costController'] as TextEditingController;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        // Medicine Name
                        Expanded(
                          flex: 4,
                          child: Text(
                            item['medicineName'] as String,
                            style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13),
                          ),
                        ),

                        // Quantity input
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: accentTeal, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Cost input
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: costController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(fontSize: 11, color: softGrey, fontWeight: FontWeight.bold),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: accentTeal, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Row Total
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${((int.tryParse(qtyController.text) ?? 0) * (double.tryParse(costController.text) ?? 0.0)).toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 13),
                          ),
                        ),

                        // Delete button
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            onPressed: () => _removeItem(index),
                          ),
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
    );
  }
}
