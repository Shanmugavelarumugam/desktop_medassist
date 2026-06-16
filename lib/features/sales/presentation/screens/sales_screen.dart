import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../billing_pos/presentation/notifier/billing_notifier.dart';
import '../../../billing_pos/domain/models/invoice.dart';
import '../../../billing_pos/presentation/widgets/invoice_builder_dialog.dart';

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
  int _activeTab = 0; // 0 = Daily Sales, 1 = Customer Bills, 2 = Sales Returns
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedDateRange;

  Invoice? _selectedInvoice; // For receipt detail side drawer/dialog
  String? _hoveredInvoiceId; // For row hover highlight
  final ScrollController _kpiScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final billingState = ref.read(billingNotifierProvider);
      if (billingState.invoices.isEmpty) {
        ref.read(billingNotifierProvider.notifier).loadInvoices();
      }
      if (billingState.dailySummary.isEmpty) {
        ref.read(billingNotifierProvider.notifier).loadAnalytics();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kpiScrollController.dispose();
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

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (_) {
      return '—';
    }
  }

  String _formatMedicines(List<InvoiceItem> items) {
    if (items.isEmpty) return '—';
    return items.map((item) => '${item.name} (x${item.qty})').join(', ');
  }

  List<Invoice> _getFilteredInvoices(List<Invoice> invoices) {
    return invoices.where((inv) {
      // 1. Search Query filter (matches invoice number, patient name, or phone)
      final numberMatch = inv.invoiceNumber.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final nameMatch = inv.patientName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final phoneMatch = inv.patientPhone.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      if (_searchQuery.isNotEmpty && !numberMatch && !nameMatch && !phoneMatch) {
        return false;
      }

      // 2. Tab specific filters
      try {
        final invDate = DateTime.parse(inv.date);

        if (_activeTab == 0) {
          // Daily Sales: exact selected date
          return invDate.year == _selectedDate.year &&
              invDate.month == _selectedDate.month &&
              invDate.day == _selectedDate.day;
        } else if (_activeTab == 1) {
          // Customer Bills: Date Range & Finalized status
          if (inv.status == 'CANCELLED') return false;
          if (_selectedDateRange != null) {
            final start = DateTime(
              _selectedDateRange!.start.year,
              _selectedDateRange!.start.month,
              _selectedDateRange!.start.day,
            );
            final end = DateTime(
              _selectedDateRange!.end.year,
              _selectedDateRange!.end.month,
              _selectedDateRange!.end.day,
              23,
              59,
              59,
            );
            return invDate.isAfter(start) && invDate.isBefore(end);
          }
        } else if (_activeTab == 2) {
          // Sales Returns: Cancelled status
          if (inv.status != 'CANCELLED') return false;
          if (_selectedDateRange != null) {
            final start = DateTime(
              _selectedDateRange!.start.year,
              _selectedDateRange!.start.month,
              _selectedDateRange!.start.day,
            );
            final end = DateTime(
              _selectedDateRange!.end.year,
              _selectedDateRange!.end.month,
              _selectedDateRange!.end.day,
              23,
              59,
              59,
            );
            return invDate.isAfter(start) && invDate.isBefore(end);
          }
        }
      } catch (_) {}

      return true;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _activeTab = 1; // Auto switch to Customer Bills to see range
      });
    }
  }

  void _exportSalesReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Exporting sales report... PDF and CSV download started.',
        ),
        backgroundColor: primaryTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCancelDialog(Invoice invoice) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Cancel Invoice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textDark,
                ),
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
                style: const TextStyle(color: textDark, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Cancellation Reason *',
                  labelStyle: const TextStyle(fontSize: 13, color: softGrey),
                  hintText: 'e.g. Customer returned, incorrect items billed',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back',
                style: TextStyle(color: softGrey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

                final success = await ref
                    .read(billingNotifierProvider.notifier)
                    .cancelInvoice(invoice.id, reason);
                if (!context.mounted) return;
                if (success) {
                  setState(() {
                    _selectedInvoice = null; // Close details drawer
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Invoice ${invoice.invoiceNumber} cancelled successfully.',
                      ),
                      backgroundColor: const Color(0xFF0D9488),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  final err =
                      ref.read(billingNotifierProvider).errorMessage ??
                      'Cancellation failed';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text(
                'Void Transaction',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingNotifierProvider);
    final filteredInvoices = _getFilteredInvoices(billingState.invoices);
    final now = DateTime.now();

    // Calculations for KPIs
    double todaySales = 0.0;
    double rangeSales = 0.0;
    int rangeBillsCount = 0;
    double rangeReturns = 0.0;

    for (final inv in billingState.invoices) {
      DateTime? invDate;
      try {
        invDate = DateTime.parse(inv.date);
      } catch (_) {}

      final isFinalized = inv.status == 'FINALIZED' || inv.status == 'APPROVED';
      final isCancelled = inv.status == 'CANCELLED';

      // Today's Sales (Finalized)
      if (invDate != null &&
          invDate.year == now.year &&
          invDate.month == now.month &&
          invDate.day == now.day &&
          isFinalized) {
        todaySales += inv.total;
      }

      // Range filtering for metric calculations
      bool inRange = true;
      if (_selectedDateRange != null && invDate != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        inRange = invDate.isAfter(start) && invDate.isBefore(end);
      } else if (invDate != null) {
        // Default range: current calendar month if no range is selected
        inRange = invDate.year == now.year && invDate.month == now.month;
      }

      if (inRange) {
        if (isFinalized) {
          rangeSales += inv.total;
          rangeBillsCount++;
        } else if (isCancelled) {
          rangeReturns += inv.total;
        }
      }
    }

    return Container(
      color: bgGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER (Title, Subtitle & Actions)
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
                  children: const [
                    Text(
                      'Sales Management',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Daily records, customer bills, and return processing.',
                      style: TextStyle(
                        color: softGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textDark,
                        side: const BorderSide(color: borderGrey, width: 1.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _selectDateRange,
                      icon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: softGrey,
                      ),
                      label: Text(
                        _selectedDateRange == null
                            ? 'Date Range'
                            : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textDark,
                        side: const BorderSide(color: borderGrey, width: 1.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _exportSalesReport,
                      icon: const Icon(
                        Icons.file_download_outlined,
                        size: 18,
                        color: softGrey,
                      ),
                      label: const Text(
                        'Export',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const InvoiceBuilderDialog(),
                        );
                      },
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text(
                        'Generate Invoice',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TAB SELECTION & CONTROLS BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderGrey)),
            ),
            child: Row(
              children: [
                _buildTabBar(),
                const Spacer(),
                // Search Input Box
                SizedBox(
                  width: 320,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search analytics, stock, or bills...',
                      hintStyle: const TextStyle(color: softGrey, fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: softGrey,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
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
                  ),
                ),
              ],
            ),
          ),

          // 3. MAIN CONTENT
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Panel
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // KPI CARDS RIBBON
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 24, 40, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(
                                title: "TODAY'S SALES",
                                value: '₹${todaySales.toStringAsFixed(0)}',
                                icon: Icons.trending_up,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKpiCard(
                                title: _selectedDateRange == null
                                    ? 'THIS MONTH'
                                    : 'SELECTED RANGE',
                                value: '₹${rangeSales.toStringAsFixed(2)}',
                                icon: Icons.calendar_today_rounded,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKpiCard(
                                title: 'TOTAL BILLS',
                                value: '$rangeBillsCount',
                                icon: Icons.receipt_long_rounded,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKpiCard(
                                title: 'RETURNS',
                                value: '₹${rangeReturns.toStringAsFixed(0)}',
                                icon: Icons.keyboard_return_rounded,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // DAILY DATE NAVIGATOR & SUMMARY BAR
                      if (_activeTab == 0) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
                          child: Row(children: [_buildDateNavigator()]),
                        ),
                      ],

                      // SUMMARY BAR (DYNAMIC STRIP)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 16, 40, 0),
                        child: _buildSummaryBar(filteredInvoices),
                      ),

                      // TABLE VIEW
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 16, 40, 40),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Table Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    border: Border(
                                      bottom: BorderSide(color: borderGrey),
                                    ),
                                  ),
                                  child: Row(
                                    children: const [
                                      Expanded(
                                        flex: 2,
                                        child: _TableHeaderText('TIME'),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: _TableHeaderText('PATIENT'),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: _TableHeaderText('MEDICINES'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: _TableHeaderText('DISC'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: _TableHeaderText('GST'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: _TableHeaderText('TOTAL'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: _TableHeaderText('PAYMENT'),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: _TableHeaderText(
                                          'ACTIONS',
                                          alignRight: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Scrollable Body
                                Expanded(
                                  child: billingState.isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: primaryTeal,
                                          ),
                                        )
                                      : filteredInvoices.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No sales recorded for this selection',
                                            style: TextStyle(
                                              color: softGrey,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          padding: EdgeInsets.zero,
                                          itemCount: filteredInvoices.length,
                                          separatorBuilder: (context, index) =>
                                              const Divider(
                                                height: 1,
                                                color: borderGrey,
                                              ),
                                          itemBuilder: (context, index) {
                                            final inv = filteredInvoices[index];
                                            final isSelected =
                                                _selectedInvoice?.id == inv.id;
                                            final isHovered =
                                                _hoveredInvoiceId == inv.id;

                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              onEnter: (_) => setState(
                                                () =>
                                                    _hoveredInvoiceId = inv.id,
                                              ),
                                              onExit: (_) => setState(
                                                () => _hoveredInvoiceId = null,
                                              ),
                                              child: InkWell(
                                                onTap: () =>
                                                    _showSalesDetailDialog(inv),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12,
                                                      ),
                                                  color: isSelected
                                                      ? const Color(0xFFCCFBF1)
                                                      : isHovered
                                                      ? const Color(0xFFF8FBFB)
                                                      : Colors.white,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          _formatTime(inv.date),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: softGrey,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                          inv.patientName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 12,
                                                                color: textDark,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 4,
                                                        child: Text(
                                                          _formatMedicines(
                                                            inv.items,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: softGrey,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          '₹${inv.discount.toStringAsFixed(1)}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: softGrey,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          '₹${inv.gst.toStringAsFixed(1)}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: softGrey,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          '₹${inv.total.toStringAsFixed(1)}',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                fontSize: 13,
                                                                color: textDark,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child:
                                                            _buildPaymentMethodBadge(
                                                              inv.paymentMethod,
                                                            ),
                                                      ),
                                                      Expanded(
                                                        flex: 4,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              IconButton(
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                constraints:
                                                                    const BoxConstraints(
                                                                      minWidth:
                                                                          28,
                                                                      minHeight:
                                                                          28,
                                                                    ),
                                                                icon: const Icon(
                                                                  Icons
                                                                      .print_outlined,
                                                                  size: 16,
                                                                ),
                                                                tooltip:
                                                                    'Reprint Bill',
                                                                onPressed: () {
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        'Receipt ${inv.invoiceNumber} sent to printer...',
                                                                      ),
                                                                      backgroundColor:
                                                                          primaryTeal,
                                                                      behavior:
                                                                          SnackBarBehavior
                                                                              .floating,
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                               IconButton(
                                                                 padding:
                                                                     EdgeInsets
                                                                         .zero,
                                                                 constraints:
                                                                     const BoxConstraints(
                                                                       minWidth:
                                                                           28,
                                                                       minHeight:
                                                                           28,
                                                                     ),
                                                                 icon: const Icon(
                                                                   Icons
                                                                       .visibility_outlined,
                                                                   size: 16,
                                                                 ),
                                                                 tooltip:
                                                                     'View Details',
                                                                 onPressed: () =>
                                                                     _showSalesDetailDialog(inv),
                                                               ),
                                                              if (inv.status !=
                                                                  'CANCELLED') ...[
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                IconButton(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  constraints:
                                                                      const BoxConstraints(
                                                                        minWidth:
                                                                            28,
                                                                        minHeight:
                                                                            28,
                                                                      ),
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .cancel_outlined,
                                                                    size: 16,
                                                                    color: Color(
                                                                      0xFFEF4444,
                                                                    ),
                                                                  ),
                                                                  tooltip:
                                                                      'Void Bill',
                                                                  onPressed: () =>
                                                                      _showCancelDialog(
                                                                        inv,
                                                                      ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Detail Side Panel
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  width: _selectedInvoice != null ? 340 : 0,
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 340,
                      maxWidth: 340,
                      alignment: Alignment.topRight,
                      child: _selectedInvoice != null
                          ? Container(
                              width: 340,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  left: BorderSide(
                                    color: borderGrey,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: _buildReceiptPanel(_selectedInvoice!),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(0, 'Daily Sales'),
          _buildTabButton(1, 'Customer Bills'),
          _buildTabButton(2, 'Sales Returns'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _activeTab = index;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primaryTeal : softGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: softGrey,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator() {
    final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderGrey, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: softGrey,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateStr,
              style: const TextStyle(
                color: textDark,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: softGrey,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(List<Invoice> activeInvoices) {
    final finalized = activeInvoices
        .where((inv) => inv.status != 'CANCELLED')
        .toList();
    final totalRevenue = finalized.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderGrey, width: 1.2),
      ),
      child: Row(
        children: [
          const Text(
            'Total Bills: ',
            style: TextStyle(
              color: softGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${finalized.length}',
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24),
          const Text(
            'Revenue: ',
            style: TextStyle(
              color: softGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '₹${totalRevenue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBadge(String method) {
    IconData icon;
    Color color;
    switch (method.toUpperCase()) {
      case 'UPI':
        icon = Icons.phone_android_rounded;
        color = const Color(0xFF2563EB);
        break;
      case 'CARD':
        icon = Icons.credit_card_rounded;
        color = const Color(0xFFD97706);
        break;
      default:
        icon = Icons.payments_rounded;
        color = const Color(0xFF0D9488);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          method,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showSalesDetailDialog(Invoice inv) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 780,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSalesDialogHeader(inv),
                Flexible(
                  child: Container(
                    color: bgGrey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSalesSectionLabel('Patient Info', Icons.person_outline_rounded),
                          const SizedBox(height: 12),
                          _buildSalesInfoGrid([
                            _SalesInfoField(icon: Icons.person_rounded, label: 'Name', value: inv.patientName),
                            _SalesInfoField(icon: Icons.phone_rounded, label: 'Phone', value: inv.patientPhone),
                          ]),
                          const SizedBox(height: 20),
                          _buildSalesSectionLabel('Invoice Items', Icons.inventory_2_outlined),
                          const SizedBox(height: 12),
                          _buildSalesItemsTable(inv),
                          const SizedBox(height: 20),
                          _buildSalesTotals(inv),
                          const SizedBox(height: 20),
                          _buildSalesPaymentInfo(inv),
                          if (inv.notes != null && inv.notes!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildSalesSectionLabel('Notes', Icons.notes_rounded),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderGrey),
                              ),
                              child: Text(inv.notes!, style: const TextStyle(fontSize: 13, color: softGrey, height: 1.5)),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildSalesDialogFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesDialogHeader(Invoice inv) {
    final date = DateTime.parse(inv.date).toLocal();
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F4C45), Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.receipt_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(inv.invoiceNumber, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _salesStatusBadge(inv.status),
                    const SizedBox(width: 8),
                    _salesDetailBadge(
                      color: Colors.white,
                      bgColor: Colors.white.withValues(alpha: 0.15),
                      label: inv.paymentMethod,
                      icon: inv.paymentMethod.toUpperCase() == 'UPI'
                          ? Icons.phone_android_rounded
                          : inv.paymentMethod.toUpperCase() == 'CARD'
                              ? Icons.credit_card_rounded
                              : Icons.payments_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _salesStatusBadge(String status) {
    final isCancelled = status.toUpperCase() == 'CANCELLED';
    final color = isCancelled ? const Color(0xFFF87171) : const Color(0xFF4ADE80);
    return _salesDetailBadge(
      color: color,
      bgColor: color.withValues(alpha: 0.2),
      label: isCancelled ? 'CANCELLED' : 'FINALIZED',
      dot: true,
    );
  }

  Widget _salesDetailBadge({required Color color, required Color bgColor, required String label, bool dot = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
          else if (icon != null)
            Icon(icon, size: 12, color: color),
          if (dot || icon != null) const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildSalesSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: primaryTeal),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13, letterSpacing: 0.2)),
      ],
    );
  }

  Widget _buildSalesInfoGrid(List<_SalesInfoField> fields) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: List.generate(fields.length, (i) {
          return Padding(
            padding: EdgeInsets.only(top: i > 0 ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: primaryTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(fields[i].icon, size: 15, color: primaryTeal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fields[i].label, style: const TextStyle(fontSize: 10, color: softGrey, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                      const SizedBox(height: 2),
                      Text(fields[i].value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSalesItemsTable(Invoice inv) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: const Border(bottom: BorderSide(color: borderGrey)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: softGrey, letterSpacing: 0.3))),
                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: softGrey, letterSpacing: 0.3))),
                Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: softGrey, letterSpacing: 0.3))),
                Expanded(flex: 1, child: Text('GST%', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: softGrey, letterSpacing: 0.3))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: softGrey, letterSpacing: 0.3)))),
              ],
            ),
          ),
          ...List.generate(inv.items.length, (i) {
            final item = inv.items[i];
            final isLast = i == inv.items.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: borderGrey))),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textDark))),
                  Expanded(flex: 1, child: Text('${item.qty}', style: const TextStyle(fontSize: 13, color: softGrey))),
                  Expanded(flex: 2, child: Text('\u20B9${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: softGrey))),
                  Expanded(flex: 1, child: Text('${item.gst.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, color: softGrey))),
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('\u20B9${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textDark)))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSalesTotals(Invoice inv) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          _salesTotalRow('Subtotal', '\u20B9${inv.subtotal.toStringAsFixed(2)}', false),
          if (inv.discount > 0) ...[
            const Divider(height: 24, color: borderGrey),
            _salesTotalRow('Discount', '-\u20B9${inv.discount.toStringAsFixed(2)}', false, valueColor: const Color(0xFFEF4444)),
          ],
          const Divider(height: 24, color: borderGrey),
          _salesTotalRow('GST', '\u20B9${inv.gst.toStringAsFixed(2)}', false),
          const Divider(height: 24, color: borderGrey),
          _salesTotalRow('Grand Total', '\u20B9${inv.total.toStringAsFixed(2)}', true),
        ],
      ),
    );
  }

  Widget _salesTotalRow(String label, String value, bool isBold, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: isBold ? textDark : softGrey)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: valueColor ?? (isBold ? primaryTeal : textDark))),
      ],
    );
  }

  Widget _buildSalesPaymentInfo(Invoice inv) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalesSectionLabel('Payment', Icons.payments_rounded),
          const SizedBox(height: 12),
          _buildSalesInfoGrid([
            _SalesInfoField(icon: Icons.account_balance_wallet_rounded, label: 'Method', value: inv.paymentMethod),
            _SalesInfoField(icon: Icons.check_circle_rounded, label: 'Payment Status', value: inv.paymentStatus),
            _SalesInfoField(icon: Icons.currency_rupee_rounded, label: 'Paid Amount', value: '\u20B9${inv.paidAmount.toStringAsFixed(2)}'),
            _SalesInfoField(icon: inv.balanceAmount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, label: 'Balance', value: inv.balanceAmount > 0 ? '\u20B9${inv.balanceAmount.toStringAsFixed(2)}' : '\u20B90.00'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSalesDialogFooter(BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderGrey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPanel(Invoice invoice) {
    final isCancelled = invoice.status == 'CANCELLED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Receipt Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.invoiceNumber,
                    style: TextStyle(
                      color: primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFFDF2F2)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCancelled
                          ? const Color(0xFFFDE8E8)
                          : const Color(0xFFDCFCE7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCancelled
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: isCancelled
                            ? const Color(0xFFEF4444)
                            : primaryTeal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCancelled
                                  ? 'TRANSACTION VOIDED'
                                  : 'TRANSACTION FINALIZED',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isCancelled
                                    ? const Color(0xFFEF4444)
                                    : primaryTeal,
                              ),
                            ),
                            if (invoice.notes != null &&
                                invoice.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                invoice.notes!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CUSTOMER PROFILE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: softGrey,
                    letterSpacing: 0.5,
                  ),
                ),
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
                      _buildReceiptRow(
                        'Timestamp',
                        _formatDateTime(invoice.date),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BILLED MEDICINES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: softGrey,
                    letterSpacing: 0.5,
                  ),
                ),
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
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: borderGrey),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Batch: ${item.batchNumber}  |  GST: ${item.gst}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: softGrey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.qty} units x ₹${(item.mrp).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: softGrey,
                                  ),
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
                const Text(
                  'PAYMENT SUMMARY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: softGrey,
                    letterSpacing: 0.5,
                  ),
                ),
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
                      _buildReceiptRow(
                        'Subtotal',
                        '₹${invoice.subtotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildReceiptRow(
                        'Discount',
                        '-₹${invoice.discount.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildReceiptRow(
                        'Taxes (GST)',
                        '₹${invoice.gst.toStringAsFixed(2)}',
                      ),
                      const Divider(height: 24, color: borderGrey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount Billed',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: textDark,
                            ),
                          ),
                          Text(
                            '₹${invoice.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: primaryTeal,
                            ),
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
        const Divider(height: 1, color: borderGrey),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print Bill'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Receipt sent to primary POS printer queue...',
                        ),
                        backgroundColor: primaryTeal,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }
}

class _SalesInfoField {
  final IconData icon;
  final String label;
  final String value;

  const _SalesInfoField({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _TableHeaderText extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _TableHeaderText(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    );
  }
}
