import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/invoice.dart';
import '../../utils/invoice_printer.dart';

/// A premium Invoice Preview dialog shown after successful invoice generation
/// in the Sales module. Displays full invoice details with Print / Download / Close actions.
class InvoicePreviewDialog extends StatefulWidget {
  final Invoice invoice;

  const InvoicePreviewDialog({super.key, required this.invoice});

  /// Shows the dialog and returns when the user closes it.
  static Future<void> show(BuildContext context, Invoice invoice) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InvoicePreviewDialog(invoice: invoice),
    );
  }

  @override
  State<InvoicePreviewDialog> createState() => _InvoicePreviewDialogState();
}

class _InvoicePreviewDialogState extends State<InvoicePreviewDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _isPrinting = false;

  // Parsed metadata from invoice notes
  Map<String, dynamic>? _metadata;
  String _cleanNotes = '';

  // Teal palette
  static const _teal900 = Color(0xFF134E4A);
  static const _teal700 = Color(0xFF0F766E);
  static const _teal600 = Color(0xFF0D9488);
  static const _slate900 = Color(0xFF0F172A);
  static const _slate600 = Color(0xFF475569);
  static const _slate300 = Color(0xFFCBD5E1);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _green600 = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();

    // Parse metadata from notes field
    final notes = widget.invoice.notes;
    if (notes != null && notes.trim().startsWith('{')) {
      try {
        _metadata = jsonDecode(notes) as Map<String, dynamic>;
        _cleanNotes = _metadata?['originalNotes']?.toString() ?? '';
      } catch (_) {
        _cleanNotes = notes;
      }
    } else {
      _cleanNotes = notes ?? '';
    }

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      await InvoicePrinter.printInvoice(widget.invoice);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _handleClose() {
    Navigator.of(context).pop();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDate(String raw) {
    try {
      return DateFormat(
        'dd MMM yyyy, hh:mm a',
      ).format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  /// Consolidate invoice items by name (sum qty + total) for display
  List<_ConsolidatedItem> _consolidatedItems() {
    final map = <String, _ConsolidatedItem>{};
    final order = <String>[];
    for (final item in widget.invoice.items) {
      if (!map.containsKey(item.name)) {
        order.add(item.name);
        map[item.name] = _ConsolidatedItem(
          name: item.name,
          qty: item.qty,
          mrp: item.mrp.toDouble(),
          gst: item.gst.toDouble(),
          discount: 0,
          total: item.total.toDouble(),
          batchNumber: item.batchNumber,
        );
      } else {
        final existing = map[item.name]!;
        final addedQty = existing.qty + item.qty;
        final addedTotal = existing.total + item.total.toDouble();
        map[item.name] = _ConsolidatedItem(
          name: item.name,
          qty: addedQty,
          mrp: addedQty > 0 ? (addedTotal / addedQty) : existing.mrp,
          gst: item.gst.toDouble(),
          discount: 0,
          total: addedTotal,
          batchNumber: '${existing.batchNumber}, ${item.batchNumber}',
        );
      }
    }
    return order.map((k) => map[k]!).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final cgst = inv.gst / 2;
    final sgst = inv.gst / 2;
    final items = _consolidatedItems();

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 820,
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Scaffold(
                backgroundColor: Colors.white,
                body: Column(
                  children: [
                    _buildHeader(inv),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(36, 28, 36, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Success Banner ────────────────────────────────
                            _buildSuccessBanner(inv),
                            const SizedBox(height: 28),

                            // ── Pharmacy + Invoice info ───────────────────────
                            _buildInfoSection(inv),
                            const SizedBox(height: 24),

                            // ── Items Table ───────────────────────────────────
                            _buildItemsTable(items),
                            const SizedBox(height: 24),

                            // ── Totals + Notes ────────────────────────────────
                            _buildTotalsSection(inv, cgst, sgst),
                            if (_cleanNotes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildNotesSection(),
                            ],
                            const SizedBox(height: 16),
                            _buildFooter(),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                    _buildActionBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader(Invoice inv) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_teal900, _teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invoice Generated',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                inv.invoiceNumber,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  inv.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
              size: 22,
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  // ── Success Banner ────────────────────────────────────────────────────────────
  Widget _buildSuccessBanner(Invoice inv) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _green600,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invoice created successfully!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _green600,
                  ),
                ),
                Text(
                  'Review the invoice below before printing or closing.',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          // Copy invoice number
          _CopyButton(label: inv.invoiceNumber, value: inv.invoiceNumber),
        ],
      ),
    );
  }

  // ── Info Section ──────────────────────────────────────────────────────────────
  Widget _buildInfoSection(Invoice inv) {
    final docName = _metadata?['doctorName']?.toString() ?? '';
    final rxNo = _metadata?['prescriptionNo']?.toString() ?? '';
    final gstNo = _metadata?['gstNumber']?.toString() ?? '';
    final address = _metadata?['address']?.toString() ?? '';
    final payTerms =
        _metadata?['paymentTerms']?.toString() ?? inv.paymentMethod;
    final dueDateRaw = _metadata?['dueDate']?.toString() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pharmacy block (left)
        Expanded(
          child: _InfoCard(
            title: 'PHARMACY',
            icon: Icons.local_pharmacy_outlined,
            children: [
              _InfoRow(
                label: '',
                value: 'VIYAN MEDASSIST',
                isBold: true,
                fontSize: 15,
              ),
              const SizedBox(height: 4),
              _InfoRow(label: '', value: '123, Healthcare Street, Bangalore'),
              _InfoRow(label: '', value: 'GSTIN: 29ABCDE1234F1Z1'),
              _InfoRow(label: '', value: 'Ph: +91 98765 43210'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Customer block (middle)
        Expanded(
          child: _InfoCard(
            title: 'BILLED TO',
            icon: Icons.person_outline_rounded,
            children: [
              _InfoRow(
                label: '',
                value: inv.patientName,
                isBold: true,
                fontSize: 14,
              ),
              if (inv.patientPhone.isNotEmpty)
                _InfoRow(label: 'Ph', value: inv.patientPhone),
              if (gstNo.isNotEmpty) _InfoRow(label: 'GSTIN', value: gstNo),
              if (address.isNotEmpty) _InfoRow(label: 'Addr', value: address),
              if (docName.isNotEmpty)
                _InfoRow(label: 'Doctor', value: 'Dr. $docName'),
              if (rxNo.isNotEmpty) _InfoRow(label: 'Rx No', value: rxNo),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Invoice meta block (right)
        Expanded(
          child: _InfoCard(
            title: 'INVOICE DETAILS',
            icon: Icons.receipt_outlined,
            children: [
              _InfoRow(label: 'Inv No', value: inv.invoiceNumber, isBold: true),
              _InfoRow(label: 'Date', value: _formatDate(inv.date)),
              _InfoRow(label: 'Status', value: inv.status.toUpperCase()),
              _InfoRow(label: 'Payment', value: payTerms),
              if (dueDateRaw.isNotEmpty)
                _InfoRow(
                  label: 'Due',
                  value: () {
                    try {
                      return DateFormat(
                        'dd MMM yyyy',
                      ).format(DateTime.parse(dueDateRaw));
                    } catch (_) {
                      return dueDateRaw;
                    }
                  }(),
                ),
              _InfoRow(
                label: 'Paid',
                value: '₹${inv.paidAmount.toStringAsFixed(2)}',
              ),
              if (inv.balanceAmount > 0)
                _InfoRow(
                  label: 'Balance',
                  value: '₹${inv.balanceAmount.toStringAsFixed(2)}',
                  isRed: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Items Table ───────────────────────────────────────────────────────────────
  Widget _buildItemsTable(List<_ConsolidatedItem> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _slate300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: _slate900,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _TableHeader('MEDICINE')),
                Expanded(
                  flex: 2,
                  child: _TableHeader('BATCH', align: TextAlign.center),
                ),
                Expanded(
                  flex: 1,
                  child: _TableHeader('QTY', align: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: _TableHeader('MRP', align: TextAlign.right),
                ),
                Expanded(
                  flex: 1,
                  child: _TableHeader('GST', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _TableHeader('TOTAL', align: TextAlign.right),
                ),
              ],
            ),
          ),
          // Table Rows
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isEven = idx % 2 == 0;
            return Container(
              decoration: BoxDecoration(
                color: isEven ? Colors.white : _slate100,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _slate900,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.batchNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: _slate600),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item.qty}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _slate900,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.mrp.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, color: _slate600),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item.gst.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: _slate600),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.total.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _teal700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Totals ────────────────────────────────────────────────────────────────────
  Widget _buildTotalsSection(Invoice inv, double cgst, double sgst) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_teal900, _slate900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _TotalRow(
                label: 'Subtotal',
                value: '₹${inv.subtotal.toStringAsFixed(2)}',
              ),
              if (inv.discount > 0) ...[
                const SizedBox(height: 6),
                _TotalRow(
                  label: 'Discount',
                  value: '-₹${inv.discount.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF4ADE80),
                ),
              ],
              const SizedBox(height: 6),
              _TotalRow(label: 'CGST', value: '₹${cgst.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _TotalRow(label: 'SGST', value: '₹${sgst.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL DUE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '₹${inv.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF5EEAD4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────────
  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sticky_note_2_outlined,
            size: 16,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _cleanNotes,
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return const Center(
      child: Text(
        'Thank you for visiting! Get well soon. 🙏',
        style: TextStyle(
          fontSize: 12,
          color: _slate600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ── Action Bar ────────────────────────────────────────────────────────────────
  Widget _buildActionBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _slate300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Close button (left)
          OutlinedButton.icon(
            onPressed: _handleClose,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Close'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _slate600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              side: const BorderSide(color: _slate300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Spacer(),
          // Print button
          OutlinedButton.icon(
            onPressed: _isPrinting ? null : _handlePrint,
            icon: _isPrinting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _teal600,
                    ),
                  )
                : const Icon(Icons.print_rounded, size: 18),
            label: Text(
              _isPrinting ? 'Preparing PDF...' : 'Print / Download PDF',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              side: const BorderSide(color: _teal600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Print & Close button (primary)
          ElevatedButton.icon(
            onPressed: _isPrinting
                ? null
                : () async {
                    await _handlePrint();
                    if (mounted) Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Print & Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting data class ─────────────────────────────────────────────────────

class _ConsolidatedItem {
  final String name;
  final int qty;
  final double mrp;
  final double gst;
  final double discount;
  final double total;
  final String batchNumber;

  const _ConsolidatedItem({
    required this.name,
    required this.qty,
    required this.mrp,
    required this.gst,
    required this.discount,
    required this.total,
    required this.batchNumber,
  });
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF0F766E)),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isRed;
  final double fontSize;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isRed = false,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: label.isEmpty
          ? Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isRed
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF0F172A),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    '$label:',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      color: isRed
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _TableHeader(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: valueColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String label;
  final String value;

  const _CopyButton({required this.label, required this.value});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _copied ? const Color(0xFFDCFCE7) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _copied ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 13,
              color: _copied
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'Copied!' : widget.label,
              style: TextStyle(
                fontSize: 11,
                color: _copied
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
