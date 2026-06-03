import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/purchase.dart';
import '../notifier/purchase_notifier.dart';
import '../widgets/create_po_dialog.dart';
import '../widgets/create_supplier_dialog.dart';
import '../widgets/receive_po_dialog.dart';

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
          // 1. HEADER WITH TABS
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
                        const Text(
                          'Purchases & Procurement',
                          style: TextStyle(
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
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Tab switcher
                Row(
                  children: [
                    _buildTabButton(
                      label: 'Purchase Orders',
                      isActive: activeTab == 0,
                      onTap: () {
                        _searchController.clear();
                        ref.read(purchaseNotifierProvider.notifier).setActiveTab(0);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      label: 'Suppliers',
                      isActive: activeTab == 1,
                      onTap: () {
                        _searchController.clear();
                        ref.read(purchaseNotifierProvider.notifier).setActiveTab(1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

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

                // Status Filter Dropdown (Only for Purchase Orders)
                if (activeTab == 0) ...[
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
                        items: const [
                          DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                          DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                          DropdownMenuItem(value: 'PENDING_APPROVAL', child: Text('Pending Approval')),
                          DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                          DropdownMenuItem(value: 'RECEIVED', child: Text('Received')),
                          DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(purchaseNotifierProvider.notifier).setSelectedStatus(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Refresh Button
                IconButton(
                  icon: const Icon(Icons.refresh, color: primaryTeal),
                  tooltip: 'Refresh list',
                  onPressed: () {
                    ref.read(purchaseNotifierProvider.notifier).loadData();
                  },
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

  Widget _buildTabButton({required String label, required bool isActive, required VoidCallback onTap}) {
    const primaryTeal = Color(0xFF0F766E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0FDF4) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFFBBF7D0) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? primaryTeal : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
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
              Expanded(flex: 2, child: _TableHeaderText('GST NUMBER')),
              Expanded(flex: 4, child: _TableHeaderText('ADDRESS')),
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
              child: Container(
                color: _hoveredRowIndex == index ? const Color(0xFFF8FAFC) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    // Supplier Name
                    Expanded(
                      flex: 3,
                      child: Text(
                        sup.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14),
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
                      child: Text(
                        sup.email,
                        style: const TextStyle(color: softGrey, fontSize: 13),
                      ),
                    ),
                    // GST Number
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sup.gstNumber,
                          style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    // Address
                    Expanded(
                      flex: 4,
                      child: Text(
                        sup.address,
                        style: const TextStyle(color: softGrey, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                title: const Text('Cancel Purchase Order'),
                content: Text('Are you sure you want to cancel order ${po.orderNumber}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
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
