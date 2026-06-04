import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../billing_pos/presentation/notifier/billing_notifier.dart';
import '../../../billing_pos/domain/models/invoice.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  static const primaryTeal = Color(0xFF0F766E);
  static const textDark = Color(0xFF0F172A);
  static const softGrey = Color(0xFF64748B);
  static const bgGrey = Color(0xFFF4F7FA);
  static const borderGrey = Color(0xFFE2E8F0);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'FINALIZED', 'CANCELLED'
  String _dateFilter = 'Today'; // 'Today', 'Yesterday', 'Last 7 Days', 'All'

  Invoice? _selectedInvoice; // For receipt detail side drawer/dialog

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingNotifierProvider.notifier).loadInvoices();
      ref.read(billingNotifierProvider.notifier).loadAnalytics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    final now = DateTime.now();
    return invoices.where((inv) {
      // 1. Search Query filter (matches invoice number, patient name, or phone)
      final numberMatch = inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final nameMatch = inv.patientName.toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatch = inv.patientPhone.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!numberMatch && !nameMatch && !phoneMatch) return false;

      // 2. Status filter
      if (_statusFilter != 'All' && inv.status != _statusFilter) return false;

      // 3. Date filter
      try {
        final invDate = DateTime.parse(inv.date);
        final difference = now.difference(invDate).inDays;

        if (_dateFilter == 'Today') {
          return invDate.year == now.year && invDate.month == now.month && invDate.day == now.day;
        } else if (_dateFilter == 'Yesterday') {
          final yesterday = now.subtract(const Duration(days: 1));
          return invDate.year == yesterday.year && invDate.month == yesterday.month && invDate.day == yesterday.day;
        } else if (_dateFilter == 'Last 7 Days') {
          return difference <= 7;
        }
      } catch (_) {}

      return true;
    }).toList();
  }

  void _showCancelDialog(Invoice invoice) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
              SizedBox(width: 12),
              Text(
                'Cancel Invoice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to void Invoice ${invoice.invoiceNumber}? This will restore the stock level of all items in this receipt.',
                style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Cancellation Reason *',
                  labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  hintText: 'e.g. Customer returned, incorrect items billed',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a cancellation reason.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }
                Navigator.pop(context); // Close dialog

                final success = await ref.read(billingNotifierProvider.notifier).cancelInvoice(invoice.id, reason);
                if (!context.mounted) return;
                if (success) {
                  setState(() {
                    _selectedInvoice = null; // Close details drawer
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invoice ${invoice.invoiceNumber} cancelled successfully.'),
                      backgroundColor: const Color(0xFF0D9488),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  final err = ref.read(billingNotifierProvider).errorMessage ?? 'Cancellation failed';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Void Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingNotifierProvider);
    final filteredInvoices = _filterInvoices(billingState.invoices);

    // Extract stats
    final summary = billingState.dailySummary['summary'];
    final double todayRevenue = (summary?['netRevenue'] != null)
        ? (summary['netRevenue'] is num ? (summary['netRevenue'] as num).toDouble() : double.tryParse(summary['netRevenue'].toString()) ?? 0.0)
        : 0.0;
    final int todayInvoicesCount = summary?['totalInvoices'] ?? 0;
    final int todayRefundsCount = summary?['totalRefunds'] ?? 0;

    // payment method breakdown
    final breakdown = billingState.paymentBreakdown['payments'] as List? ?? [];
    double cashAmount = 0.0;
    double upiAmount = 0.0;
    double cardAmount = 0.0;
    for (final pay in breakdown) {
      final method = (pay['method'] ?? '').toString().toUpperCase();
      final double amt = pay['amount'] is num ? (pay['amount'] as num).toDouble() : double.tryParse(pay['amount'].toString()) ?? 0.0;
      if (method == 'CASH') cashAmount += amt;
      if (method == 'UPI') upiAmount += amt;
      if (method == 'CARD') cardAmount += amt;
    }

    return Container(
      color: bgGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderGrey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales History & Reports',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitor daily revenue, view invoices registry, and void transaction history.',
                      style: TextStyle(color: softGrey, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: primaryTeal),
                  tooltip: 'Reload Sales History',
                  onPressed: () {
                    ref.read(billingNotifierProvider.notifier).loadInvoices();
                    ref.read(billingNotifierProvider.notifier).loadAnalytics();
                  },
                ),
              ],
            ),
          ),

          // 2. MAIN LAYOUT
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Area: Stats & Invoice List
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Stats Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                label: "TODAY'S NET REVENUE",
                                value: '₹${todayRevenue.toStringAsFixed(2)}',
                                icon: Icons.currency_rupee,
                                iconColor: const Color(0xFF0F766E),
                                bgGradient: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildMetricCard(
                                label: 'INVOICES BILLED',
                                value: '$todayInvoicesCount transactions',
                                icon: Icons.receipt_long_outlined,
                                iconColor: const Color(0xFF2563EB),
                                bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildMetricCard(
                                label: 'VOIDED INVOICES',
                                value: '$todayRefundsCount voided',
                                icon: Icons.cancel_presentation_outlined,
                                iconColor: const Color(0xFFEF4444),
                                bgGradient: const [Color(0xFFFDF2F2), Color(0xFFFDE8E8)],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildPaymentBreakdownCard(
                                cash: cashAmount,
                                upi: upiAmount,
                                card: cardAmount,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Filters & Search Bar
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderGrey),
                          ),
                          child: Row(
                            children: [
                              // Search input
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search, color: softGrey, size: 20),
                                    hintText: 'Search by Invoice #, Patient Name, Phone...',
                                    hintStyle: const TextStyle(color: softGrey, fontSize: 13),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),

                              // Date Filter dropdown
                              DropdownButton<String>(
                                value: _dateFilter,
                                underline: const SizedBox(),
                                style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13),
                                items: const [
                                  DropdownMenuItem(value: 'Today', child: Text('Billed Today')),
                                  DropdownMenuItem(value: 'Yesterday', child: Text('Billed Yesterday')),
                                  DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                                  DropdownMenuItem(value: 'All', child: Text('All Dates')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _dateFilter = val);
                                },
                              ),
                              const SizedBox(width: 24),

                              // Status Filter dropdown
                              DropdownButton<String>(
                                value: _statusFilter,
                                underline: const SizedBox(),
                                style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                                  DropdownMenuItem(value: 'FINALIZED', child: Text('Finalized')),
                                  DropdownMenuItem(value: 'CANCELLED', child: Text('Voided')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _statusFilter = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Invoices Table Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderGrey),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'REGISTRY RECORDS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Divider(height: 1, color: borderGrey),

                              billingState.isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(80.0),
                                      child: Center(
                                        child: CircularProgressIndicator(color: primaryTeal),
                                      ),
                                    )
                                  : filteredInvoices.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(80.0),
                                          child: Center(
                                            child: Text(
                                              'No matching invoices found in this period.',
                                              style: TextStyle(color: softGrey, fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : DataTable(
                                          showCheckboxColumn: false,
                                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                          horizontalMargin: 24,
                                          columnSpacing: 24,
                                          columns: const [
                                            DataColumn(label: Text('INVOICE #', style: TextStyle(fontWeight: FontWeight.bold, color: softGrey, fontSize: 11))),
                                            DataColumn(label: Text('DATE & TIME', style: TextStyle(fontWeight: FontWeight.bold, color: softGrey, fontSize: 11))),
                                            DataColumn(label: Text('PATIENT', style: TextStyle(fontWeight: FontWeight.bold, color: softGrey, fontSize: 11))),
                                            DataColumn(label: Text('METHOD', style: TextStyle(fontWeight: FontWeight.bold, color: softGrey, fontSize: 11))),
                                            DataColumn(label: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: softGrey, fontSize: 11))),
                                            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: softGrey, fontSize: 11))),
                                          ],
                                          rows: filteredInvoices.map((inv) {
                                            return DataRow(
                                              selected: _selectedInvoice?.id == inv.id,
                                              onSelectChanged: (_) {
                                                setState(() {
                                                  _selectedInvoice = inv;
                                                });
                                              },
                                              cells: [
                                                DataCell(Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark))),
                                                DataCell(Text(_formatDateTime(inv.date), style: const TextStyle(fontSize: 13, color: softGrey))),
                                                DataCell(
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(inv.patientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textDark)),
                                                      if (inv.patientPhone != 'N/A')
                                                        Text(inv.patientPhone, style: const TextStyle(fontSize: 11, color: softGrey)),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(Text(inv.paymentMethod, style: const TextStyle(fontSize: 13, color: textDark))),
                                                DataCell(Text('₹${inv.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark))),
                                                DataCell(_buildStatusBadge(inv.status)),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Area: Receipt Detail Side Panel
                if (_selectedInvoice != null)
                  Container(
                    width: 440,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: borderGrey, width: 1.5)),
                    ),
                    child: _buildReceiptPanel(_selectedInvoice!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required List<Color> bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: bgGradient),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownCard({required double cash, required double upi, required double card}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "TODAY'S PAYMENTS SPLIT",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          _buildBreakdownRow('Cash Billed', cash, const Color(0xFF0D9488)),
          const SizedBox(height: 6),
          _buildBreakdownRow('UPI Billed', upi, const Color(0xFF2563EB)),
          const SizedBox(height: 6),
          _buildBreakdownRow('Card Billed', card, const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color indicator) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: indicator, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    if (status == 'CANCELLED') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFEF4444);
    } else {
      bg = const Color(0xFFE6F4F1);
      text = const Color(0xFF0F766E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 'CANCELLED' ? 'VOIDED' : 'FINALIZED',
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildReceiptPanel(Invoice invoice) {
    final isCancelled = invoice.status == 'CANCELLED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drawer Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Receipt Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textDark)),
                  const SizedBox(height: 4),
                  Text(invoice.invoiceNumber, style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: softGrey),
                onPressed: () => setState(() => _selectedInvoice = null),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: borderGrey),

        // Scrollable Receipt Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCancelled ? const Color(0xFFFDF2F2) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isCancelled ? const Color(0xFFFDE8E8) : const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCancelled ? Icons.error_outline : Icons.check_circle_outline,
                        color: isCancelled ? const Color(0xFFEF4444) : const Color(0xFF0F766E),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCancelled ? 'TRANSACTION VOIDED' : 'TRANSACTION FINALIZED',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isCancelled ? const Color(0xFFEF4444) : const Color(0xFF0F766E),
                              ),
                            ),
                            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(invoice.notes!, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Patient Details Card
                const Text('CUSTOMER PROFILE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderGrey),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Name', invoice.patientName),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Phone', invoice.patientPhone),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Timestamp', _formatDateTime(invoice.date)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Itemized Medicine Table
                const Text('BILLED MEDICINES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderGrey),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoice.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: borderGrey),
                    itemBuilder: (context, index) {
                      final item = invoice.items[index];
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
                                  ),
                                ),
                                Text(
                                  '₹${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Batch: ${item.batchNumber}  |  GST: ${item.gst}%',
                                  style: const TextStyle(fontSize: 11, color: softGrey),
                                ),
                                Text(
                                  '${item.qty} units x ₹${(item.mrp).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, color: softGrey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Financial Breakdown
                const Text('PAYMENT SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderGrey),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Subtotal', '₹${invoice.subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Discount', '-₹${invoice.discount.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Taxes (GST)', '₹${invoice.gst.toStringAsFixed(2)}'),
                      const Divider(height: 24, color: borderGrey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount Billed', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textDark)),
                          Text(
                            '₹${invoice.total.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: primaryTeal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Method', invoice.paymentMethod),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Buttons at Bottom
        const Divider(height: 1, color: borderGrey),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print Bill'),
                  onPressed: () {
                    // Simulating bill print success SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt sent to primary POS printer queue...'),
                        backgroundColor: Color(0xFF0F766E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              if (!isCancelled) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Cancel Bill'),
                    onPressed: () => _showCancelDialog(invoice),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}
