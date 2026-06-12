import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/purchase.dart';
import '../notifier/purchase_notifier.dart';
import '../widgets/create_po_dialog.dart';
import '../widgets/create_supplier_dialog.dart';
import '../widgets/receive_po_dialog.dart';
import '../widgets/edit_supplier_dialog.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _searchController = TextEditingController();
  int? _hoveredRowIndex; // For table hover row highlight

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(purchaseNotifierProvider.notifier).setSearchQuery(_searchController.text);
    });
    Future.microtask(() {
      if (mounted) {
        final state = ref.read(purchaseNotifierProvider);
        if (state.purchaseOrders.isEmpty || state.suppliers.isEmpty) {
          ref.read(purchaseNotifierProvider.notifier).loadData();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _showCreatePoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreatePoDialog(),
    );
  }

  void _showRegisterSupplierDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateSupplierDialog(),
    );
  }

  void _showReceivePoDialog(PurchaseOrder po) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceivePoDialog(purchaseOrder: po),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    final cleanStatus = status.toUpperCase();

    switch (cleanStatus) {
      case 'DRAFT':
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        break;
      case 'PENDING_APPROVAL':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        break;
      case 'APPROVED':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF2563EB);
        break;
      case 'RECEIVED':
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF059669);
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cleanStatus.replaceAll('_', ' '),
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0F766E); // Matches design guidelines
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF4F7FA);
    const borderGrey = Color(0xFFE2E8F0);

    final state = ref.watch(purchaseNotifierProvider);
    final activeTab = state.activeTab;

    return Container(
      color: bgGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. DYNAMIC HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderGrey)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeTab == 0 ? 'Purchases & Procurement' : 'Supplier Directory',
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeTab == 0
                              ? 'Manage and track purchase orders, approvals, and stock receipts.'
                              : 'Register and manage your pharmaceutical and medical suppliers.',
                          style: const TextStyle(color: softGrey, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: activeTab == 0 ? _showCreatePoDialog : _showRegisterSupplierDialog,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(activeTab == 0 ? 'Create Purchase Order' : 'Register Supplier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: primaryTeal.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // KPI CARDS ROW FOR SUPPLIERS
          if (activeTab == 1) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, top: 24),
              child: Row(
                children: [
                  Expanded(child: _buildKpiCard('Total Suppliers', state.suppliers.length.toString(), Icons.group_outlined, const Color(0xFF3B82F6))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKpiCard('Active', state.suppliers.where((s) => s.status.toUpperCase() == 'ACTIVE').length.toString(), Icons.check_circle_outline_rounded, const Color(0xFF0F766E))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKpiCard('GST Verified', state.suppliers.where((s) => s.gstNumber.isNotEmpty && s.gstNumber.toUpperCase() != 'NONE' && s.gstNumber.toUpperCase() != 'N/A').length.toString(), Icons.verified_user_outlined, const Color(0xFF6366F1))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKpiCard('Outstanding Payables', _formatOutstandingPayables(state.suppliers.fold<double>(0, (sum, s) => sum + (s.outstandingBalance ?? 0.0))), Icons.account_balance_wallet_outlined, const Color(0xFFF59E0B))),
                ],
              ),
            ),
          ],

          // 2. SEARCH & FILTERING BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderGrey)),
            ),
            child: Row(
              children: [
                // Search Input Box
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: activeTab == 0
                          ? 'Search by Order Number or Supplier name...'
                          : 'Search by Supplier name, phone, or email...',
                      hintStyle: const TextStyle(color: softGrey, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: softGrey, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
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
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderGrey, width: 1.2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.selectedStatus,
                      items: activeTab == 0
                          ? const [
                              DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                              DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                              DropdownMenuItem(value: 'PENDING_APPROVAL', child: Text('Pending Approval')),
                              DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                              DropdownMenuItem(value: 'RECEIVED', child: Text('Received')),
                              DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                            ]
                          : const [
                              DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                              DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                              DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                              DropdownMenuItem(value: 'BLACKLISTED', child: Text('Blacklisted')),
                            ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(purchaseNotifierProvider.notifier).setSelectedStatus(val);
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Styled Refresh Button
                Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      ref.read(purchaseNotifierProvider.notifier).loadData();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderGrey, width: 1.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, color: primaryTeal, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Refresh',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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

          // 3. TABLE/LIST CONTENT AREA
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: state.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(80.0),
                        child: Center(
                          child: CircularProgressIndicator(color: primaryTeal),
                        ),
                      )
                    : state.errorMessage != null
                        ? _buildErrorState(state.errorMessage!)
                        : activeTab == 0
                            ? _buildPurchaseOrdersTable(state.filteredPurchaseOrders)
                            : _buildSuppliersTable(state.filteredSuppliers),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              'An error occurred: $message',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(purchaseNotifierProvider.notifier).loadData(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOrdersTable(List<PurchaseOrder> orders) {
    const textDark = Color(0xFF0F172A);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);

    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(80.0),
        child: Center(
          child: Text(
            'No purchase orders found.',
            style: TextStyle(color: softGrey, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: borderGrey)),
          ),
          child: Row(
            children: const [
              Expanded(flex: 2, child: _TableHeaderText('ORDER NUMBER')),
              Expanded(flex: 3, child: _TableHeaderText('SUPPLIER')),
              Expanded(flex: 3, child: _TableHeaderText('DATE')),
              Expanded(flex: 2, child: _TableHeaderText('TOTAL AMOUNT')),
              Expanded(flex: 2, child: _TableHeaderText('STATUS')),
              Expanded(flex: 3, child: _TableHeaderText('ACTIONS', alignRight: true)),
            ],
          ),
        ),
        // Table Body
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: borderGrey),
          itemBuilder: (context, index) {
            final po = orders[index];
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredRowIndex = index),
              onExit: (_) => setState(() => _hoveredRowIndex = null),
              child: Container(
                color: _hoveredRowIndex == index ? const Color(0xFFF8FAFC) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    // Order Number
                    Expanded(
                      flex: 2,
                      child: Text(
                        po.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14),
                      ),
                    ),
                    // Supplier Name
                    Expanded(
                      flex: 3,
                      child: Text(
                        po.supplier?.name ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 14),
                      ),
                    ),
                    // Created Date
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatDate(po.createdAt),
                        style: const TextStyle(color: softGrey, fontSize: 13),
                      ),
                    ),
                    // Total Amount
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${po.totalAmountDouble.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14),
                      ),
                    ),
                    // Status Chip
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStatusChip(po.status),
                      ),
                    ),
                    // Actions Panel
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          children: _buildPoActionButtons(po),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuppliersTable(List<Supplier> suppliers) {
    const textDark = Color(0xFF0F172A);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const primaryTeal = Color(0xFF0F766E);

    if (suppliers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(80.0),
        child: Center(
          child: Text(
            'No suppliers registered.',
            style: TextStyle(color: softGrey, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: borderGrey)),
          ),
          child: Row(
            children: const [
              Expanded(flex: 3, child: _TableHeaderText('SUPPLIER NAME')),
              Expanded(flex: 2, child: _TableHeaderText('PHONE')),
              Expanded(flex: 3, child: _TableHeaderText('EMAIL')),
              Expanded(flex: 3, child: _TableHeaderText('GST NUMBER')),
              Expanded(flex: 2, child: _TableHeaderText('STATUS')),
              Expanded(flex: 2, child: _TableHeaderText('ACTIONS', alignRight: true)),
            ],
          ),
        ),
        // Table Body
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suppliers.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: borderGrey),
          itemBuilder: (context, index) {
            final sup = suppliers[index];
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredRowIndex = index),
              onExit: (_) => setState(() => _hoveredRowIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: _hoveredRowIndex == index ? const Color(0xFFF8FBFB) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: InkWell(
                  onTap: () => _showSupplierDetailsDialog(sup),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                  children: [
                    // Supplier Name
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryTeal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              sup.name.isNotEmpty ? sup.name[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                color: primaryTeal,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sup.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14),
                                ),
                                if (sup.isPreferred) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Preferred',
                                      style: TextStyle(color: Color(0xFFD97706), fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Phone
                    Expanded(
                      flex: 2,
                      child: Text(
                        sup.phone,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 13),
                      ),
                    ),
                    // Email
                    Expanded(
                      flex: 3,
                      child: Tooltip(
                        message: sup.email,
                        child: Text(
                          sup.email,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(color: softGrey, fontSize: 13),
                        ),
                      ),
                    ),
                    // GST Number
                    Expanded(
                      flex: 3,
                      child: sup.gstNumber.isEmpty || sup.gstNumber.toLowerCase() == 'none' || sup.gstNumber.toLowerCase() == 'n/a'
                          ? const Text('—', style: TextStyle(color: softGrey, fontSize: 13))
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: sup.gstNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('GST Number "${sup.gstNumber}" copied to clipboard'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: primaryTeal,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Tooltip(
                                  message: 'Click to copy GST',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFDBEAFE)),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            sup.gstNumber,
                                            style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.copy_rounded, size: 10, color: Color(0xFF2563EB)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    // Status
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildSupplierStatusChip(sup.status),
                      ),
                    ),

                    // Actions Panel
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0F766E)),
                              tooltip: 'View Details',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showSupplierDetailsDialog(sup),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)),
                              tooltip: 'Edit Supplier',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showEditSupplierDialog(sup),
                            ),
                            const SizedBox(width: 12),

                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                              tooltip: 'Delete Supplier',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showDeleteSupplierConfirm(sup),
                            ),
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
      ],
    );
  }

  List<Widget> _buildPoActionButtons(PurchaseOrder po) {
    final list = <Widget>[];
    final notifier = ref.read(purchaseNotifierProvider.notifier);
    final status = po.status.toUpperCase();

    if (status == 'DRAFT') {
      list.add(
        _ActionTextButton(
          label: 'Submit',
          color: const Color(0xFF0F766E),
          onPressed: () => notifier.updateStatus(po.id, 'PENDING_APPROVAL'),
        ),
      );
    }

    if (status == 'PENDING_APPROVAL') {
      list.add(
        _ActionTextButton(
          label: 'Approve',
          color: const Color(0xFF2563EB),
          onPressed: () => notifier.approvePurchaseOrder(po.id),
        ),
      );
    }

    if (status == 'APPROVED') {
      list.add(
        _ActionTextButton(
          label: 'Receive Stock',
          color: const Color(0xFF059669),
          onPressed: () => _showReceivePoDialog(po),
        ),
      );
    }

    // Cancel Button allowed for Draft, Pending Approval, or Approved
    if (status == 'DRAFT' || status == 'PENDING_APPROVAL' || status == 'APPROVED') {
      list.add(
        _ActionTextButton(
          label: 'Cancel',
          color: const Color(0xFFEF4444),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  'Cancel Purchase Order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                content: Text(
                  'Are you sure you want to cancel order ${po.orderNumber}?',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 15,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'No',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Cancel Order',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              notifier.updateStatus(po.id, 'CANCELLED');
            }
          },
        ),
      );
    }

    return list;
  }

  Widget _buildSupplierStatusChip(String status) {
    Color color;
    final cleanStatus = status.toUpperCase();
    switch (cleanStatus) {
      case 'ACTIVE':
        color = const Color(0xFF0D9488); // Teal
        break;
      case 'INACTIVE':
        color = const Color(0xFF64748B); // Grey
        break;
      case 'BLACKLISTED':
        color = const Color(0xFFEF4444); // Red
        break;
      default:
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            cleanStatus,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showSupplierDetailsDialog(Supplier sup) {
    final bool isActive = sup.status.toUpperCase() == 'ACTIVE';
    final String initial = sup.name.isNotEmpty ? sup.name[0].toUpperCase() : 'S';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 680,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ══════════════════════════════════════════════════
                // HERO HEADER — gradient + avatar + name + badges
                // ══════════════════════════════════════════════════
                Container(
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
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name + code + badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              sup.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sup.supplierCode ?? 'No Code',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isActive
                                          ? const Color(0xFF4ADE80).withValues(alpha: 0.5)
                                          : Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6, height: 6,
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFF4ADE80) : Colors.white60,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        sup.status.toUpperCase(),
                                        style: TextStyle(
                                          color: isActive ? const Color(0xFF4ADE80) : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (sup.isPreferred) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                                        SizedBox(width: 4),
                                        Text(
                                          'PREFERRED',
                                          style: TextStyle(
                                            color: Color(0xFFFBBF24),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (sup.supplierType != null && sup.supplierType!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      sup.supplierType!.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Close button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // ══════════════════════════════════════════════════
                // SCROLLABLE BODY
                // ══════════════════════════════════════════════════
                Flexible(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── General & Contact ──────────────────────────
                          _buildSectionLabel('General & Contact Info', Icons.person_outline_rounded),
                          const SizedBox(height: 12),
                          _buildInfoGrid([
                            _SupplierField(icon: Icons.phone_rounded, label: 'Phone', value: sup.phone),
                            _SupplierField(icon: Icons.email_outlined, label: 'Email', value: sup.email),
                            _SupplierField(icon: Icons.badge_outlined, label: 'Contact Person', value: sup.contactPerson ?? '—'),
                            _SupplierField(icon: Icons.location_on_outlined, label: 'Address', value: sup.address, fullWidth: true),
                          ]),

                          const SizedBox(height: 20),

                          // ── Compliance & Terms ─────────────────────────
                          _buildSectionLabel('Compliance & Terms', Icons.verified_outlined),
                          const SizedBox(height: 12),
                          _buildInfoGrid([
                            _SupplierField(icon: Icons.receipt_long_outlined, label: 'GST Number', value: sup.gstNumber, isMono: true),
                            _SupplierField(icon: Icons.local_pharmacy_outlined, label: 'Drug License', value: sup.drugLicenseNumber ?? '—'),
                            _SupplierField(icon: Icons.schedule_rounded, label: 'Lead Time', value: '${sup.leadTimeDays} Days'),
                            _SupplierField(icon: Icons.payment_rounded, label: 'Payment Terms', value: '${sup.paymentTermsDays} Days'),
                            if (sup.licenseExpiry != null && sup.licenseExpiry!.isNotEmpty)
                              _SupplierField(icon: Icons.event_rounded, label: 'License Expiry', value: sup.licenseExpiry!),
                          ]),

                          const SizedBox(height: 20),

                          // ── Financial Summary ──────────────────────────
                          _buildSectionLabel('Financial Summary', Icons.account_balance_wallet_outlined),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildFinancialCard(
                                label: 'Outstanding Balance',
                                value: '₹${sup.outstandingBalance?.toStringAsFixed(2) ?? '0.00'}',
                                icon: Icons.pending_actions_rounded,
                                color: (sup.outstandingBalance ?? 0) > 0 ? const Color(0xFFEF4444) : const Color(0xFF0F766E),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialCard(
                                label: 'Credit Limit',
                                value: '₹${sup.creditLimit?.toStringAsFixed(2) ?? '0.00'}',
                                icon: Icons.credit_score_rounded,
                                color: const Color(0xFF7C3AED),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialCard(
                                label: 'Total Purchases',
                                value: '₹${sup.totalPurchases?.toStringAsFixed(2) ?? '0.00'}',
                                icon: Icons.shopping_bag_outlined,
                                color: const Color(0xFF0891B2),
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Rating bar
                          if (sup.rating != null)
                            _buildRatingCard(sup.rating!),

                          // ── Bank Details ───────────────────────────────
                          if (sup.bankName != null && sup.bankName!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildSectionLabel('Bank Details', Icons.account_balance_outlined),
                            const SizedBox(height: 12),
                            _buildInfoGrid([
                              _SupplierField(icon: Icons.business_rounded, label: 'Bank Name', value: sup.bankName ?? ''),
                              _SupplierField(icon: Icons.credit_card_rounded, label: 'Account Number', value: sup.accountNumber ?? '', isMono: true),
                              _SupplierField(icon: Icons.tag_rounded, label: 'IFSC Code', value: sup.ifscCode ?? '', isMono: true),
                            ]),
                          ],

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),

                // ══════════════════════════════════════════════════
                // ACTION BAR
                // ══════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showEditSupplierDialog(sup);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit Supplier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
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
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF0F766E)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Info grid card ────────────────────────────────────────────────────────
  Widget _buildInfoGrid(List<_SupplierField> fields) {
    final regular = fields.where((f) => !f.fullWidth).toList();
    final full    = fields.where((f) =>  f.fullWidth).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Pair regular fields in rows of 2
          ...() {
            final rows = <Widget>[];
            for (int i = 0; i < regular.length; i += 2) {
              if (i > 0) rows.add(const Divider(height: 20, color: Color(0xFFF1F5F9)));
              rows.add(Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFieldCell(regular[i])),
                  if (i + 1 < regular.length) ...[
                    const VerticalDivider(width: 24, color: Color(0xFFF1F5F9)),
                    Expanded(child: _buildFieldCell(regular[i + 1])),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ));
            }
            return rows;
          }(),
          // Full-width fields
          ...full.map((f) {
            return Column(
              children: [
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildFieldCell(f),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFieldCell(_SupplierField f) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(f.icon, size: 15, color: const Color(0xFF0F766E)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
              const SizedBox(height: 2),
              Text(
                f.value.isEmpty ? '—' : f.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: f.value.isEmpty ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
                  fontFamily: f.isMono ? 'monospace' : null,
                  letterSpacing: f.isMono ? 0.6 : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Financial highlight card ───────────────────────────────────────────────
  Widget _buildFinancialCard({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Rating card ────────────────────────────────────────────────────────────
  Widget _buildRatingCard(double rating) {
    final filled = rating.round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Supplier Rating', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: i < filled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                  )),
                  const SizedBox(width: 8),
                  Text(
                    '${rating.toStringAsFixed(1)} / 5.0',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showEditSupplierDialog(Supplier sup) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditSupplierDialog(supplier: sup),
    );
  }

  void _showDeleteSupplierConfirm(Supplier sup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Supplier',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        content: Text(
          'Are you sure you want to delete supplier "${sup.name}"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(purchaseNotifierProvider.notifier).deleteSupplierLocal(sup.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Supplier "${sup.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatOutstandingPayables(double value) {
    if (value >= 100000) {
      return '₹${(value / 100000.0).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '₹${(value / 1000.0).toStringAsFixed(1)}K';
    } else {
      return '₹${value.toStringAsFixed(0)}';
    }
  }
}

class _TableHeaderText extends StatelessWidget {
  final String label;
  final bool alignRight;
  const _TableHeaderText(this.label, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
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
}

class _ActionTextButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionTextButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        backgroundColor: color.withValues(alpha: 0.05),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

/// Simple data class for a supplier info field used in the detail dialog grid.
class _SupplierField {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;
  final bool isMono;

  const _SupplierField({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.isMono = false,
  });
}
