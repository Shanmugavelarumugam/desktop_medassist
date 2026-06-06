import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../notifier/billing_notifier.dart';
import '../../domain/models/invoice.dart';
import '../../data/repository/billing_repository_impl.dart';
import '../../utils/invoice_printer.dart';

class InvoiceBuilderRow {
  Medicine? medicine;
  List<MedicineBatch> batches = [];
  MedicineBatch? selectedBatch;
  int qty = 1;
  double mrp = 0.0;
  double discount = 0.0;
  double gstPercentage = 12.0;

  double get totalAmount {
    final raw = (mrp * qty) - discount;
    return raw > 0 ? raw : 0.0;
  }
}

class InvoiceBuilderDialog extends ConsumerStatefulWidget {
  final String initialTemplate;
  const InvoiceBuilderDialog({super.key, this.initialTemplate = 'classic'});

  @override
  ConsumerState<InvoiceBuilderDialog> createState() => _InvoiceBuilderDialogState();
}

class _InvoiceBuilderDialogState extends ConsumerState<InvoiceBuilderDialog> {
  final _formKey = GlobalKey<FormState>();

  // Colors
  static const primaryTeal = Color(0xFF0F766E);
  static const textDark = Color(0xFF0F172A);
  static const textSlate = Color(0xFF475569);
  static const borderGrey = Color(0xFFE2E8F0);
  static const bgLight = Color(0xFFF8FAFC);
  static const softShadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  // Customer & Prescriber Controllers
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _prescriptionNoController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentTerms = 'Cash'; // Cash, UPI, Card, Due
  DateTime? _dueDate;

  // Medicine Rows
  final List<InvoiceBuilderRow> _rows = [InvoiceBuilderRow()];

  // Preview Toggle
  bool _showPreview = false;
  bool _isSaving = false;
  late String _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate;
    _dueDate = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _doctorNameController.dispose();
    _prescriptionNoController.dispose();
    _gstNumberController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Calculate totals
  double get subtotal {
    double sum = 0.0;
    for (final row in _rows) {
      if (row.medicine != null) {
        final rowTotal = row.mrp * row.qty;
        final gstRate = row.gstPercentage / 100.0;
        final rowSubtotal = rowTotal / (1.0 + gstRate);
        sum += rowSubtotal;
      }
    }
    return sum;
  }

  double get discount {
    double sum = 0.0;
    for (final row in _rows) {
      if (row.medicine != null) {
        sum += row.discount;
      }
    }
    return sum;
  }

  double get gst {
    double sum = 0.0;
    for (final row in _rows) {
      if (row.medicine != null) {
        final rowTotal = row.mrp * row.qty;
        final gstRate = row.gstPercentage / 100.0;
        final rowSubtotal = rowTotal / (1.0 + gstRate);
        final rowGst = rowTotal - rowSubtotal;
        sum += rowGst;
      }
    }
    return sum;
  }

  double get total {
    double sum = 0.0;
    for (final row in _rows) {
      if (row.medicine != null) {
        sum += row.totalAmount;
      }
    }
    return sum;
  }

  Future<void> _submitInvoice({bool printDirectly = false, bool isDraft = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final validRows = _rows.where((r) => r.medicine != null && r.selectedBatch != null).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one medicine with a batch.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully! (Simulated)'),
          backgroundColor: Colors.teal,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final itemsPayload = validRows.map((row) {
        final rowTotal = row.totalAmount;
        final gstRate = row.gstPercentage / 100.0;
        final rowSubtotal = rowTotal / (1.0 + gstRate);
        final rowGst = rowTotal - rowSubtotal;

        return {
          'medicineId': row.medicine!.id,
          'batchId': row.selectedBatch!.id,
          'qty': row.qty,
          'price': rowSubtotal,
          'unitPrice': rowSubtotal,
          'mrp': row.mrp,
          'gst': rowGst,
          'gstAmount': rowGst,
          'total': rowTotal,
          'totalPrice': rowTotal,
          'batchNumber': row.selectedBatch!.batchNumber,
          'name': row.medicine!.name,
        };
      }).toList();

      final metadata = {
        'doctorName': _doctorNameController.text.trim(),
        'prescriptionNo': _prescriptionNoController.text.trim(),
        'gstNumber': _gstNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'paymentTerms': _paymentTerms,
        'dueDate': _dueDate?.toIso8601String() ?? '',
        'isProfessionalInvoice': true,
        'templateType': _selectedTemplate,
        'originalNotes': _notesController.text.trim(),
      };

      final paymentMethod = _paymentTerms.toUpperCase() == 'DUE' ? 'CASH' : _paymentTerms.toUpperCase();

      final repository = ref.read(billingRepositoryProvider);
      final invoice = await repository.createInvoice(
        items: itemsPayload,
        subtotal: subtotal,
        discount: discount,
        gst: gst,
        total: total,
        paymentMethod: paymentMethod,
        notes: jsonEncode(metadata),
      );

      ref.read(inventoryNotifierProvider.notifier).loadInventory();
      ref.read(billingNotifierProvider.notifier).loadInvoices();
      ref.read(billingNotifierProvider.notifier).loadAnalytics();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice generated successfully!'),
          backgroundColor: Color(0xFF0D9488),
        ),
      );

      if (printDirectly) {
        await InvoicePrinter.printInvoice(invoice);
        if (!mounted) return;
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryNotifierProvider);
    final medicines = inventoryState.medicines;

    final dialogWidth = _showPreview ? 1350.0 : 850.0;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      backgroundColor: bgLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. PREMIUM HEADER / APP BAR
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(bottom: BorderSide(color: borderGrey)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Breadcrumbs
                    const Icon(Icons.receipt_long_rounded, color: primaryTeal, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Sales',
                      style: TextStyle(
                        color: textSlate,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'New Professional Bill',
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),

                    // Template Selector Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgLight,
                        border: Border.all(color: borderGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTemplate,
                          icon: const Icon(Icons.style_rounded, color: primaryTeal, size: 16),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                          items: const [
                            DropdownMenuItem(value: 'classic', child: Text('Classic A4')),
                            DropdownMenuItem(value: 'modern', child: Text('Modern Corporate')),
                            DropdownMenuItem(value: 'thermal', child: Text('Thermal POS')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedTemplate = val;
                                _showPreview = true;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Live Preview Toggle Button
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPreview = !_showPreview;
                        });
                      },
                      icon: Icon(
                        _showPreview ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 16,
                      ),
                      label: Text(_showPreview ? 'Hide Live Preview' : 'Live Preview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showPreview ? Colors.white : primaryTeal,
                        foregroundColor: _showPreview ? primaryTeal : Colors.white,
                        elevation: 0,
                        side: BorderSide(color: primaryTeal, width: _showPreview ? 1.5 : 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close, color: textSlate),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 2. MAIN LAYOUT
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT COLUMN: Forms and Tables
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // A. Patient & Prescriber Form Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderGrey),
                                boxShadow: const [softShadow],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: primaryTeal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.person_outline, color: primaryTeal, size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'CUSTOMER & BILLING DETAILS',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textDark,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildTextField(
                                                    label: 'Customer Name',
                                                    controller: _customerNameController,
                                                    hint: 'Patient full name',
                                                    icon: Icons.person_rounded,
                                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: _buildTextField(
                                                    label: 'Phone Number',
                                                    controller: _phoneController,
                                                    hint: 'Mobile number',
                                                    icon: Icons.phone_android_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: _buildTextField(
                                                    label: 'Address',
                                                    controller: _addressController,
                                                    hint: 'Patient full home address',
                                                    icon: Icons.location_on_outlined,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  flex: 1,
                                                  child: _buildTextField(
                                                    label: 'GST Number',
                                                    controller: _gstNumberController,
                                                    hint: 'GSTIN',
                                                    icon: Icons.description_outlined,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildTextField(
                                                    label: 'Doctor Name',
                                                    controller: _doctorNameController,
                                                    hint: 'Prescribing doctor',
                                                    icon: Icons.medical_services_outlined,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: _buildTextField(
                                                    label: 'Prescription No',
                                                    controller: _prescriptionNoController,
                                                    hint: 'Rx number',
                                                    icon: Icons.edit_note_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildDropdownField(
                                                    label: 'Payment Terms',
                                                    value: _paymentTerms,
                                                    items: const ['Cash', 'UPI', 'Card', 'Due'],
                                                    icon: Icons.payment_rounded,
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() {
                                                          _paymentTerms = val;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: _buildDatePickerField(
                                                    label: 'Due Date',
                                                    selectedDate: _dueDate,
                                                    onTap: () async {
                                                      final chosen = await showDatePicker(
                                                        context: context,
                                                        initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                                                        firstDate: DateTime.now(),
                                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                                      );
                                                      if (chosen != null) {
                                                        setState(() {
                                                          _dueDate = chosen;
                                                        });
                                                      }
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // B. Medicine Table Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderGrey),
                                boxShadow: const [softShadow],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: primaryTeal.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.medication_liquid_rounded, color: primaryTeal, size: 16),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'MEDICINE ITEMS LIST',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: textDark,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _rows.add(InvoiceBuilderRow());
                                          });
                                        },
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        label: const Text('Add Row'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryTeal,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Styled Header Row
                                  Container(
                                    decoration: BoxDecoration(
                                      color: primaryTeal.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: primaryTeal.withValues(alpha: 0.15)),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    child: const Row(
                                      children: [
                                        Expanded(flex: 4, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTeal))),
                                        SizedBox(width: 12),
                                        Expanded(flex: 3, child: Text('Batch Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTeal))),
                                        SizedBox(width: 12),
                                        Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTeal), textAlign: TextAlign.center)),
                                        SizedBox(width: 12),
                                        Expanded(flex: 2, child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTeal), textAlign: TextAlign.right)),
                                        SizedBox(width: 12),
                                        Expanded(flex: 1, child: Text('Disc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTeal), textAlign: TextAlign.right)),
                                        SizedBox(width: 12),
                                        Expanded(flex: 1, child: Text('GST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTeal), textAlign: TextAlign.right)),
                                        SizedBox(width: 12),
                                        Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryTeal), textAlign: TextAlign.right)),
                                        SizedBox(width: 48), // Action column spacer
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _rows.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1, color: borderGrey),
                                    itemBuilder: (context, index) {
                                      final row = _rows[index];
                                      return _buildInvoiceRow(row, index, medicines);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // C. Summary Cards and Action Buttons
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                // Action Buttons
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 12,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _isSaving ? null : () => _submitInvoice(isDraft: true),
                                      icon: const Icon(Icons.archive_outlined, size: 18),
                                      label: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: textSlate,
                                        side: const BorderSide(color: borderGrey, width: 1.5),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _isSaving ? null : () => _submitInvoice(printDirectly: false),
                                      icon: const Icon(Icons.save_rounded, size: 18),
                                      label: const Text('Generate Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryTeal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _isSaving ? null : () => _submitInvoice(printDirectly: true),
                                      icon: const Icon(Icons.print_rounded, size: 18),
                                      label: const Text('Print A4 Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D9488),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Calculated Breakdown summary
                                Container(
                                  width: 320,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderGrey),
                                    boxShadow: const [softShadow],
                                  ),
                                  child: Column(
                                    children: [
                                      _buildSummaryLine('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                                      const SizedBox(height: 6),
                                      _buildSummaryLine('Discount', '-₹${discount.toStringAsFixed(2)}', color: Colors.green),
                                      const SizedBox(height: 6),
                                      _buildSummaryLine('GST Taxes', '₹${gst.toStringAsFixed(2)}'),
                                      const Divider(height: 16, color: borderGrey),
                                      _buildSummaryLine('Total Amount', '₹${total.toStringAsFixed(2)}', isBold: true, color: primaryTeal),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // RIGHT COLUMN: Live Paper Preview
                    if (_showPreview) ...[
                      const VerticalDivider(width: 1, color: borderGrey),
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
                            child: Card(
                              elevation: 6,
                              shadowColor: Colors.black26,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              color: Colors.white,
                              child: Container(
                                width: _selectedTemplate == 'thermal' ? 380 : 595, // Simulate A4 width or Thermal POS width
                                padding: EdgeInsets.all(_selectedTemplate == 'thermal' ? 20 : 32),
                                child: _buildLivePreviewContent(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewContent() {
    switch (_selectedTemplate) {
      case 'modern':
        return _buildModernPreview();
      case 'thermal':
        return _buildThermalPreview();
      case 'classic':
      default:
        return _buildClassicPreview();
    }
  }

  Widget _buildClassicPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VIYAN MEDASSIST',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryTeal, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '123, Healthcare Street, Medical Hub, Bangalore',
                  style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                ),
                Text(
                  'GSTIN: 29ABCDE1234F1Z1 | Ph: +91 98765 43210',
                  style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TAX INVOICE',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.black45, height: 1),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BILLED TO:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    _customerNameController.text.isEmpty ? 'Walk-in Customer' : _customerNameController.text,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  if (_phoneController.text.isNotEmpty)
                    Text('Ph: ${_phoneController.text}', style: const TextStyle(fontSize: 9)),
                  if (_gstNumberController.text.isNotEmpty)
                    Text('GSTIN: ${_gstNumberController.text}', style: const TextStyle(fontSize: 9)),
                  if (_addressController.text.isNotEmpty)
                    Text('Address: ${_addressController.text}', style: const TextStyle(fontSize: 9)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Invoice No: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
                      Text('INV-${DateFormat('yyyyMMdd').format(DateTime.now())}-XXXX', style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Invoice Date: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
                      Text(DateFormat('dd-MMM-yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                  if (_dueDate != null)
                    Row(
                      children: [
                        const Text('Due Date: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
                        Text(DateFormat('dd-MMM-yyyy').format(_dueDate!), style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  Row(
                    children: [
                      const Text('Payment Terms: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
                      Text(_paymentTerms, style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                  if (_doctorNameController.text.isNotEmpty || _prescriptionNoController.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Text('PRESCRIPTION:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    if (_doctorNameController.text.isNotEmpty)
                      Text('Doctor: ${_doctorNameController.text}', style: const TextStyle(fontSize: 9)),
                    if (_prescriptionNoController.text.isNotEmpty)
                      Text('Rx No: ${_prescriptionNoController.text}', style: const TextStyle(fontSize: 9)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.black45, height: 1),
        const SizedBox(height: 8),

        // Items Table
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(0.8),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: primaryTeal.withValues(alpha: 0.05),
                border: Border(bottom: BorderSide(color: primaryTeal.withValues(alpha: 0.2), width: 1.5)),
              ),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: primaryTeal))),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: primaryTeal))),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: primaryTeal), textAlign: TextAlign.center)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: primaryTeal), textAlign: TextAlign.right)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Disc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: primaryTeal), textAlign: TextAlign.right)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('GST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: primaryTeal), textAlign: TextAlign.right)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: primaryTeal), textAlign: TextAlign.right)),
              ],
            ),
            ..._rows.where((r) => r.medicine != null).map((row) {
              return TableRow(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(row.medicine?.name ?? '', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(row.selectedBatch?.batchNumber ?? '-', style: const TextStyle(fontSize: 8))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(row.qty.toString(), style: const TextStyle(fontSize: 8), textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('₹${row.mrp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8), textAlign: TextAlign.right)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('₹${row.discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8), textAlign: TextAlign.right)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('${row.gstPercentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 8), textAlign: TextAlign.right)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('₹${row.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Summary Total Pane
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  _buildPreviewSummaryLine('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                  if (discount > 0)
                    _buildPreviewSummaryLine('Discount', '-₹${discount.toStringAsFixed(2)}', isGreen: true),
                  _buildPreviewSummaryLine('GST Taxes', '₹${gst.toStringAsFixed(2)}'),
                  const Divider(height: 12),
                  _buildPreviewSummaryLine('TOTAL', '₹${total.toStringAsFixed(2)}', isBold: true),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),
        const Center(
          child: Text(
            'Thank you for visiting! Get well soon.',
            style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildModernPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bold corporate top banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VIYAN MEDASSIST',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '123, Healthcare Street, Medical Hub, Bangalore',
                    style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                  ),
                  const Text(
                    'GSTIN: 29ABCDE1234F1Z1 | Ph: +91 98765 43210',
                    style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryTeal,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TAX INVOICE',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Side-by-side details cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BILLED TO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryTeal)),
                    const SizedBox(height: 6),
                    Text(
                      _customerNameController.text.isEmpty ? 'Walk-in Customer' : _customerNameController.text,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textDark),
                    ),
                    const SizedBox(height: 2),
                    if (_phoneController.text.isNotEmpty)
                      Text('Ph: ${_phoneController.text}', style: const TextStyle(fontSize: 9, color: textSlate)),
                    if (_gstNumberController.text.isNotEmpty)
                      Text('GSTIN: ${_gstNumberController.text}', style: const TextStyle(fontSize: 9, color: textSlate)),
                    if (_addressController.text.isNotEmpty)
                      Text('Address: ${_addressController.text}', style: const TextStyle(fontSize: 9, color: textSlate)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INVOICE INFO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryTeal)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Inv Number:', style: TextStyle(fontSize: 9, color: textSlate)),
                        Text('INV-${DateFormat('yyyyMMdd').format(DateTime.now())}-XXXX', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date:', style: TextStyle(fontSize: 9, color: textSlate)),
                        Text(DateFormat('dd-MMM-yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_dueDate != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Due Date:', style: TextStyle(fontSize: 9, color: textSlate)),
                          Text(DateFormat('dd-MMM-yyyy').format(_dueDate!), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Terms:', style: TextStyle(fontSize: 9, color: textSlate)),
                        Text(_paymentTerms, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_doctorNameController.text.isNotEmpty || _prescriptionNoController.text.isNotEmpty) ...[
                      const Divider(height: 12),
                      if (_doctorNameController.text.isNotEmpty)
                        Text('Dr. ${_doctorNameController.text}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textDark)),
                      if (_prescriptionNoController.text.isNotEmpty)
                        Text('Rx: ${_prescriptionNoController.text}', style: const TextStyle(fontSize: 9, color: textSlate)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Shaded table rows
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(0.8),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(4),
              ),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white))),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Text('Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white))),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white), textAlign: TextAlign.center)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white), textAlign: TextAlign.right)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Text('Disc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white), textAlign: TextAlign.right)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Text('GST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white), textAlign: TextAlign.right)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white), textAlign: TextAlign.right)),
              ],
            ),
            ..._rows.asMap().entries.where((entry) => entry.value.medicine != null).map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isEven = index % 2 == 0;
              return TableRow(
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                  border: const Border(bottom: BorderSide(color: borderGrey)),
                ),
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(row.medicine?.name ?? '', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(row.selectedBatch?.batchNumber ?? '-', style: const TextStyle(fontSize: 8))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(row.qty.toString(), style: const TextStyle(fontSize: 8), textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('₹${row.mrp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8), textAlign: TextAlign.right)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('₹${row.discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8), textAlign: TextAlign.right)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('${row.gstPercentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 8), textAlign: TextAlign.right)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('₹${row.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: primaryTeal), textAlign: TextAlign.right)),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Shaded total card
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                      Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 9, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (discount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount', style: TextStyle(fontSize: 9, color: Colors.green)),
                        Text('-₹${discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST Taxes', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                      Text('₹${gst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 9, color: Colors.white)),
                    ],
                  ),
                  const Divider(height: 12, color: Color(0xFF334155)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL DUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2DD4BF))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Center(
          child: Text(
            'Thank you for visiting! Get well soon.',
            style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildThermalPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text(
            'VIYAN MEDASSIST',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
          ),
        ),
        const Center(
          child: Text(
            '123, Healthcare Street, Medical Hub',
            style: TextStyle(fontSize: 8, color: textSlate),
          ),
        ),
        const Center(
          child: Text(
            'Ph: +91 98765 43210 | GSTIN: 29ABCDE1234F1Z1',
            style: TextStyle(fontSize: 8, color: textSlate),
          ),
        ),
        const SizedBox(height: 8),
        Text('-' * 45, style: const TextStyle(fontSize: 8, color: borderGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'INV: INV-${DateFormat('yyyyMMdd').format(DateTime.now())}-XXXX\n'
          'DATE: ${DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now())}\n'
          'CUST: ${_customerNameController.text.isEmpty ? 'Walk-in Customer' : _customerNameController.text}\n'
          'TERMS: $_paymentTerms',
          style: const TextStyle(fontSize: 8, fontFamily: 'monospace', height: 1.3),
        ),
        if (_doctorNameController.text.isNotEmpty)
          Text('DOC: Dr. ${_doctorNameController.text}', style: const TextStyle(fontSize: 8, fontFamily: 'monospace')),
        const SizedBox(height: 4),
        Text('-' * 45, style: const TextStyle(fontSize: 8, color: borderGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),

        // Table
        Table(
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.8),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: borderGrey, style: BorderStyle.solid))),
              children: const [
                Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
                Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8), textAlign: TextAlign.center),
                Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8), textAlign: TextAlign.right),
                Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8), textAlign: TextAlign.right),
              ],
            ),
            ..._rows.where((r) => r.medicine != null).map((row) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${row.medicine?.name}', style: const TextStyle(fontSize: 7, fontFamily: 'monospace')),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${row.qty}', style: const TextStyle(fontSize: 7, fontFamily: 'monospace'), textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('₹${row.mrp.toStringAsFixed(1)}', style: const TextStyle(fontSize: 7, fontFamily: 'monospace'), textAlign: TextAlign.right),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('₹${row.totalAmount.toStringAsFixed(1)}', style: const TextStyle(fontSize: 7, fontFamily: 'monospace', fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 4),
        Text('-' * 45, style: const TextStyle(fontSize: 8, color: borderGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),

        // Calculations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal:', style: TextStyle(fontSize: 8, fontFamily: 'monospace')),
            Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8, fontFamily: 'monospace')),
          ],
        ),
        if (discount > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount:', style: TextStyle(fontSize: 8, fontFamily: 'monospace', color: Colors.green)),
              Text('-₹${discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8, fontFamily: 'monospace', color: Colors.green)),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('GST Taxes:', style: TextStyle(fontSize: 8, fontFamily: 'monospace')),
            Text('₹${gst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 8, fontFamily: 'monospace')),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL AMOUNT:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ],
        ),
        const SizedBox(height: 8),
        Text('-' * 45, style: const TextStyle(fontSize: 8, color: borderGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Simulated Barcode
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(24, (index) => Container(
            width: (index % 4 == 0 || index % 5 == 0) ? 3.0 : 1.5,
            height: 26,
            color: Colors.black,
            margin: const EdgeInsets.symmetric(horizontal: 1),
          )),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text('*INV-POS-XXXX*', style: TextStyle(fontSize: 7, fontFamily: 'monospace')),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Thank you for shopping!\nVisit again.',
            style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Row helper widget builder
  Widget _buildInvoiceRow(InvoiceBuilderRow row, int index, List<Medicine> medicines) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          // Medicine Autocomplete Search
          Expanded(
            flex: 4,
            child: Autocomplete<Medicine>(
              displayStringForOption: (option) => option.name,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Medicine>.empty();
                }
                return medicines.where((med) {
                  return med.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search medicine...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
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
                      borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                    ),
                  ),
                );
              },
              onSelected: (Medicine selection) async {
                row.medicine = selection;
                row.gstPercentage = (selection.gstPercentage ?? 12.0).toDouble();
                row.batches = [];
                row.selectedBatch = null;

                // Load batches
                final fetched = await ref.read(billingNotifierProvider.notifier).fetchBatches(selection.id);
                setState(() {
                  row.batches = fetched;
                  if (fetched.isNotEmpty) {
                    row.selectedBatch = fetched.first;
                    row.mrp = double.tryParse(fetched.first.mrp.toString()) ?? 0.0;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Batch dropdown selector
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<MedicineBatch>(
              initialValue: row.selectedBatch,
              isExpanded: true,
              hint: const Text('Select Batch', style: TextStyle(fontSize: 12, color: textSlate)),
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
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
                  borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                ),
              ),
              items: row.batches.map((batch) {
                final isExpired = DateTime.parse(batch.expiryDate).isBefore(DateTime.now());
                return DropdownMenuItem<MedicineBatch>(
                  value: batch,
                  enabled: !isExpired && batch.availableQuantity > 0,
                  child: Text(
                    '${batch.batchNumber} (${batch.availableQuantity} left${isExpired ? ' - Exp' : ''})',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.red : (batch.availableQuantity == 0 ? Colors.grey : const Color(0xFF0F172A)),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    row.selectedBatch = val;
                    row.mrp = double.tryParse(val.mrp.toString()) ?? 0.0;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // Qty Input field
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: row.qty.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
                  borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                ),
                isDense: true,
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 1;
                setState(() {
                  row.qty = parsed;
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // MRP Display/Input
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('mrp_${row.selectedBatch?.id}_${row.mrp}'),
              initialValue: row.mrp.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                  borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                ),
                isDense: true,
                prefixText: '₹',
                prefixStyle: const TextStyle(fontSize: 12, color: textSlate),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                setState(() {
                  row.mrp = parsed;
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Discount Input field
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: row.discount.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
                  borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                ),
                isDense: true,
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                setState(() {
                  row.discount = parsed;
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // GST Rate Input field
          Expanded(
            flex: 1,
            child: TextFormField(
              key: ValueKey('gst_${row.medicine?.id}_${row.gstPercentage}'),
              initialValue: row.gstPercentage.toStringAsFixed(0),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
                  borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                ),
                isDense: true,
                suffixText: '%',
                suffixStyle: const TextStyle(fontSize: 12, color: textSlate),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 12.0;
                setState(() {
                  row.gstPercentage = parsed;
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Calculated Row total Amount Display
          Expanded(
            flex: 2,
            child: Text(
              '₹${row.totalAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
            ),
          ),
          const SizedBox(width: 12),

          // Action: Delete Row
          SizedBox(
            width: 48,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () {
                  setState(() {
                    if (_rows.length > 1) {
                      _rows.removeAt(index);
                    } else {
                      _rows[0] = InvoiceBuilderRow();
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // General TextFormField Builder
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSlate)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, color: primaryTeal.withValues(alpha: 0.7), size: 16),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              borderSide: const BorderSide(color: primaryTeal, width: 1.5),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // Dropdown Field builder helper
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSlate)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          style: const TextStyle(fontSize: 13, color: textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryTeal.withValues(alpha: 0.7), size: 16),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              borderSide: const BorderSide(color: primaryTeal, width: 1.5),
            ),
            isDense: true,
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // DatePicker Input selector helper
  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSlate)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderGrey),
              borderRadius: BorderRadius.circular(8),
            ),
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: primaryTeal.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDate == null ? 'Select Date' : DateFormat('dd-MMM-yyyy').format(selectedDate),
                    style: const TextStyle(fontSize: 13, color: textDark),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16, color: textSlate),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryLine(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: textSlate,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
            color: color ?? textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSummaryLine(String label, String value, {bool isBold = false, bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 10 : 8,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 10 : 8,
            fontWeight: FontWeight.bold,
            color: isGreen ? Colors.green : (isBold ? primaryTeal : Colors.black),
          ),
        ),
      ],
    );
  }
}
