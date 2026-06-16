import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifier/purchase_notifier.dart';
import '../widgets/create_supplier_dialog.dart';
import '../widgets/edit_supplier_dialog.dart';
import '../../domain/models/purchase.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 15;
  int? _hoveredRowIndex;
  Timer? _debounceTimer;
  Supplier? _selectedSupplierForDetails;
  final FocusNode _focusNode = FocusNode();
  final _kpiScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    Future.microtask(() {
      final currentSuppliers = ref.read(purchaseNotifierProvider).suppliers;
      if (currentSuppliers.isEmpty) {
        ref.read(purchaseNotifierProvider.notifier).loadSuppliers();
      }
    });

    _searchController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(purchaseNotifierProvider.notifier).setSearchQuery(_searchController.text);
          if (_currentPage != 1) {
            setState(() {
              _currentPage = 1;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _focusNode.dispose();
    _kpiScrollController.dispose();
    super.dispose();
  }

  void _showRegisterSupplierDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateSupplierDialog(),
    );
  }

  void _showEditSupplierDialog(Supplier supplier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditSupplierDialog(supplier: supplier),
    );
  }

  void _confirmDeleteSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Supplier',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${supplier.name}? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(purchaseNotifierProvider.notifier).deleteSupplierLocal(supplier.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${supplier.name} deleted successfully!'),
                  backgroundColor: const Color(0xFF0D9488),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const primaryTeal = Color(0xFF0F766E);
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF4F7FA);

    final state = ref.watch(purchaseNotifierProvider);
    final suppliers = state.filteredSuppliers;

    final selectedSup = _selectedSupplierForDetails != null
        ? state.suppliers.firstWhere(
            (s) => s.id == _selectedSupplierForDetails!.id,
            orElse: () => _selectedSupplierForDetails!,
          )
        : null;

    // Pagination
    final totalItems = suppliers.length;
    final totalPages = totalItems > 0 ? (totalItems / _pageSize).ceil() : 1;
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final paginatedSuppliers = suppliers.sublist(
      startIndex,
      endIndex > totalItems ? totalItems : endIndex,
    );

    const statusList = [
      'All Status',
      'ACTIVE',
      'INACTIVE',
      'BLACKLISTED',
    ];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (_selectedSupplierForDetails != null) {
              setState(() {
                _selectedSupplierForDetails = null;
              });
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: bgGrey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. DYNAMIC HEADER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, const Color(0xFFF8FAFC)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suppliers',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register and manage your pharmaceutical and medical suppliers.',
                          style: TextStyle(
                            color: softGrey,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Export CSV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _showRegisterSupplierDialog,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Add Supplier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: primaryTeal.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 2. MODERN STATS CARDS
                            Scrollbar(
                              controller: _kpiScrollController,
                              child: SingleChildScrollView(
                                controller: _kpiScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    _buildStatCard(
                                      'Total Suppliers',
                                      state.suppliers.length.toString(),
                                      Icons.group_outlined,
                                      const Color(0xFF3B82F6),
                                      () {},
                                    ),
                                    const SizedBox(width: 16),
                                    _buildStatCard(
                                      'Active Suppliers',
                                      state.suppliers.where((s) => s.status.toUpperCase() == 'ACTIVE').length.toString(),
                                      Icons.check_circle_outline,
                                      const Color(0xFF10B981),
                                      () {},
                                    ),
                                    const SizedBox(width: 16),
                                    _buildStatCard(
                                      'Pending Payments',
                                      '₹${_formatLargeValue(state.suppliers.fold<double>(0, (sum, s) => sum + (s.outstandingBalance ?? 0.0)))}',
                                      Icons.pending_actions_rounded,
                                      const Color(0xFFF59E0B),
                                      () {},
                                    ),
                                    const SizedBox(width: 16),
                                    _buildStatCard(
                                      'Total Purchase Value',
                                      '₹${_formatLargeValue(state.suppliers.fold<double>(0, (sum, s) => sum + (s.totalPurchases ?? 0.0)))}',
                                      Icons.shopping_bag_outlined,
                                      primaryTeal,
                                      () {},
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 3. UNIFIED CONTROL BAR
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search by name, phone, or email...',
                                        hintStyle: TextStyle(color: softGrey.withValues(alpha: 0.7), fontSize: 15),
                                        prefixIcon: Icon(Icons.search_rounded, color: softGrey.withValues(alpha: 0.7)),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                    ),
                                  ),
                                  Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: state.selectedStatus,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: softGrey),
                                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20)),
                                      style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
                                      items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref.read(purchaseNotifierProvider.notifier).setSelectedStatus(val);
                                          setState(() => _currentPage = 1);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => ref.read(purchaseNotifierProvider.notifier).loadSuppliers(forceRefresh: true),
                                    icon: const Icon(Icons.refresh_rounded, color: primaryTeal),
                                    tooltip: 'Refresh',
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 4. PREMIUM DATA TABLE
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Table Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    child: Row(
                                      children: const [
                                        Expanded(flex: 3, child: _TableHeaderText('SUPPLIER NAME')),
                                        Expanded(flex: 2, child: _TableHeaderText('CONTACT PERSON')),
                                        Expanded(flex: 2, child: _TableHeaderText('PHONE')),
                                        Expanded(flex: 2, child: _TableHeaderText('EMAIL')),
                                        Expanded(flex: 2, child: _TableHeaderText('OUTSTANDING')),
                                        Expanded(flex: 2, child: _TableHeaderText('STATUS')),
                                        SizedBox(width: 140, child: _TableHeaderText('ACTIONS', alignRight: true)),
                                      ],
                                    ),
                                  ),
                                  // Table Body
                                  state.isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(40.0),
                                          child: Center(child: CircularProgressIndicator(color: primaryTeal)),
                                        )
                                      : paginatedSuppliers.isEmpty
                                          ? _buildEmptyState()
                                          : ListView.separated(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: paginatedSuppliers.length,
                                              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                              itemBuilder: (context, index) {
                                                final sup = paginatedSuppliers[index];
                                                return MouseRegion(
                                                  onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                                  onExit: (_) => setState(() => _hoveredRowIndex = null),
                                                  child: InkWell(
                                                    onTap: () => setState(() => _selectedSupplierForDetails = sup),
                                                    child: Container(
                                                      color: selectedSup?.id == sup.id
                                                          ? const Color(0xFFE6F4F1)
                                                          : _hoveredRowIndex == index
                                                              ? const Color(0xFFF8FAFC)
                                                              : Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: Row(
                                                              children: [
                                                                _buildAvatar(sup.name),
                                                                const SizedBox(width: 12),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(sup.name, style: const TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 14)),
                                                                      if (sup.isPreferred) ...[
                                                                        const SizedBox(height: 4),
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                                                                          child: const Text('Preferred', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(flex: 2, child: Text(sup.contactPerson ?? '—', style: const TextStyle(color: textDark, fontSize: 13))),
                                                          Expanded(flex: 2, child: Text(sup.phone, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600))),
                                                          Expanded(flex: 2, child: Text(sup.email, style: const TextStyle(color: softGrey, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                                          Expanded(flex: 2, child: Text('₹${(sup.outstandingBalance ?? 0).toStringAsFixed(2)}', style: TextStyle(color: (sup.outstandingBalance ?? 0) > 0 ? const Color(0xFFEF4444) : textDark, fontWeight: FontWeight.bold, fontSize: 14))),
                                                          Expanded(flex: 2, child: _buildStatusBadge(sup.status)),
                                                          SizedBox(
                                                            width: 140,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                              children: [
                                                                _ActionButton(icon: Icons.remove_red_eye_outlined, tooltip: 'View Details', onPressed: () => setState(() => _selectedSupplierForDetails = sup)),
                                                                const SizedBox(width: 8),
                                                                _ActionButton(icon: Icons.edit_outlined, tooltip: 'Edit Supplier', onPressed: () => _showEditSupplierDialog(sup)),
                                                                const SizedBox(width: 8),
                                                                _ActionButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete Supplier', iconColor: const Color(0xFFEF4444), onPressed: () => _confirmDeleteSupplier(sup)),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                  // Pagination Footer
                                  if (suppliers.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Showing ${startIndex + 1} to ${endIndex > totalItems ? totalItems : endIndex} of $totalItems entries', style: const TextStyle(color: softGrey, fontSize: 14, fontWeight: FontWeight.w500)),
                                          Row(
                                            children: [
                                              OutlinedButton(
                                                onPressed: safePage > 1 ? () => setState(() => _currentPage = safePage - 1) : null,
                                                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                child: const Text('Previous', style: TextStyle(color: textDark)),
                                              ),
                                              const SizedBox(width: 16),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                                                child: Text('$safePage / $totalPages', style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                                              ),
                                              const SizedBox(width: 16),
                                              OutlinedButton(
                                                onPressed: safePage < totalPages ? () => setState(() => _currentPage = safePage + 1) : null,
                                                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                child: const Text('Next', style: TextStyle(color: textDark)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedSup != null) _buildDetailsPanel(selectedSup),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(Supplier sup) {
    const primaryTeal = Color(0xFF0F766E);
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);

    return Container(
      width: 450,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: borderGrey, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: borderGrey))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SUPPLIER DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: softGrey, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Text(sup.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded, color: softGrey), onPressed: () => setState(() => _selectedSupplierForDetails = null)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('General Info'),
                  _buildDetailRow('Supplier Code', sup.supplierCode ?? '—'),
                  _buildDetailRow('Contact Person', sup.contactPerson ?? '—'),
                  _buildDetailRow('Phone', sup.phone),
                  _buildDetailRow('Email', sup.email),
                  _buildDetailRow('Address', sup.address),
                  const Divider(height: 32),
                  _buildSectionHeader('Compliance'),
                  _buildDetailRow('GST Number', sup.gstNumber.isEmpty ? '—' : sup.gstNumber),
                  _buildDetailRow('Drug License', sup.drugLicenseNumber ?? '—'),
                  _buildDetailRow('Lead Time', '${sup.leadTimeDays} Days'),
                  const Divider(height: 32),
                  _buildSectionHeader('Financials'),
                  _buildDetailRow('Outstanding', '₹${(sup.outstandingBalance ?? 0).toStringAsFixed(2)}', valueColor: (sup.outstandingBalance ?? 0) > 0 ? Colors.red : primaryTeal),
                  _buildDetailRow('Credit Limit', '₹${(sup.creditLimit ?? 0).toStringAsFixed(2)}'),
                  _buildDetailRow('Total Purchases', '₹${(sup.totalPurchases ?? 0).toStringAsFixed(2)}'),
                  const Divider(height: 32),
                  _buildSectionHeader('Bank Details'),
                  _buildDetailRow('Bank Name', sup.bankName ?? '—'),
                  _buildDetailRow('Account No.', sup.accountNumber ?? '—'),
                  _buildDetailRow('IFSC Code', sup.ifscCode ?? '—'),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: borderGrey))),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditSupplierDialog(sup),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: borderGrey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Edit', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: primaryTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                    child: const Text('Purchase History', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                    child: const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F766E), letterSpacing: 0.5)),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF0F172A), fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
            ],
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    String initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFF0D9488).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text = status.toUpperCase();
    switch (text) {
      case 'ACTIVE':
        color = const Color(0xFF10B981);
        break;
      case 'INACTIVE':
        color = const Color(0xFF64748B);
        break;
      case 'BLACKLISTED':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(80.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text('No suppliers found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            SizedBox(height: 8),
            Text('Try adjusting your search or filters to find what you are looking for.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  String _formatLargeValue(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
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
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12, letterSpacing: 0.5)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _ActionButton({required this.icon, required this.tooltip, required this.onPressed, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (iconColor ?? const Color(0xFF0F766E)).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconColor ?? const Color(0xFF0F766E)),
        ),
      ),
    );
  }
}
