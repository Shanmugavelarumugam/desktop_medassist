import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';

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
  int? _hoveredRowIndex;
  int _currentPage = 0;
  int _rowsPerPage = 20;
  String _selectedSupplier = 'All Suppliers';
  DateTimeRange? _dateRange;
  String? _sortColumn;
  bool _sortAscending = true;

  PurchaseOrder? _selectedPurchaseOrder;
  Supplier? _selectedSupplierForDetails;
  int _purchaseSubTab = 0; // 0 = Purchase Invoices, 1 = Purchase Orders, 2 = Supplier Returns

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _currentPage = 0);
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

  void _showEditSupplierDialog(Supplier sup) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditSupplierDialog(supplier: sup),
    );
  }

  // ── Sorted & Paginated Orders ──

  List<PurchaseOrder> get _processedOrders {
    final state = ref.read(purchaseNotifierProvider);
    var orders = List<PurchaseOrder>.from(state.filteredPurchaseOrders);

    if (_purchaseSubTab == 0) {
      // Purchase Invoices
      orders = orders.where((po) {
        final s = po.status.toUpperCase();
        return s == 'RECEIVED' || s == 'PARTIALLY_RECEIVED';
      }).toList();
    } else if (_purchaseSubTab == 1) {
      // Purchase Orders
      orders = orders.where((po) {
        final s = po.status.toUpperCase();
        return s == 'PENDING_APPROVAL' || s == 'APPROVED' || s == 'ORDERED' || s == 'DRAFT';
      }).toList();
    } else if (_purchaseSubTab == 2) {
      // Supplier Returns
      orders = orders.where((po) {
        final s = po.status.toUpperCase();
        return s == 'CANCELLED';
      }).toList();
    }

    if (_selectedSupplier != 'All Suppliers') {
      orders = orders.where((po) => po.supplier?.name == _selectedSupplier).toList();
    }

    if (_dateRange != null) {
      orders = orders.where((po) {
        try {
          final d = DateTime.parse(po.createdAt).toLocal();
          return d.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
              d.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        } catch (_) {
          return true;
        }
      }).toList();
    }

    if (_sortColumn != null) {
      orders.sort((a, b) {
        int cmp;
        switch (_sortColumn) {
          case 'orderNumber':
            cmp = a.orderNumber.compareTo(b.orderNumber);
            break;
          case 'supplier':
            cmp = (a.supplier?.name ?? '').compareTo(b.supplier?.name ?? '');
            break;
          case 'date':
            cmp = a.createdAt.compareTo(b.createdAt);
            break;
          case 'amount':
            cmp = a.totalAmountDouble.compareTo(b.totalAmountDouble);
            break;
          default:
            cmp = 0;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }

    return orders;
  }

  List<PurchaseOrder> get _paginatedOrders {
    final orders = _processedOrders;
    final start = _currentPage * _rowsPerPage;
    if (start >= orders.length) {
      _currentPage = 0;
      return orders.take(_rowsPerPage).toList();
    }
    return orders.skip(start).take(_rowsPerPage).toList();
  }

  int get _totalFiltered => _processedOrders.length;

  void _sortBy(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _currentPage = 0;
    });
  }

  // ── Status Helpers ──

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED':
        return AppColors.success;
      case 'PARTIALLY_RECEIVED':
        return AppColors.warning;
      case 'PENDING_APPROVAL':
        return AppColors.error;
      case 'APPROVED':
      case 'ORDERED':
        return AppColors.info;
      case 'DRAFT':
        return AppColors.textTertiary;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED':
        return AppColors.successLight;
      case 'PARTIALLY_RECEIVED':
        return AppColors.warningLight;
      case 'PENDING_APPROVAL':
        return AppColors.errorLight;
      case 'APPROVED':
      case 'ORDERED':
        return AppColors.infoLight;
      case 'DRAFT':
        return AppColors.divider;
      case 'CANCELLED':
        return AppColors.errorLight;
      default:
        return AppColors.divider;
    }
  }

  Widget _buildSupplierStatusChip(String status) {
    final color = switch (status.toUpperCase()) {
      'ACTIVE' => AppColors.primary,
      'INACTIVE' => AppColors.textTertiary,
      'BLACKLISTED' => AppColors.error,
      _ => AppColors.textTertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseNotifierProvider);

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═══════════════════ HEADER ═══════════════════
          _buildHeader(state.activeTab),

          // ═══════════════════ SUBTABS (PO view only) ═══════════════════
          if (state.activeTab == 0) _buildSubTabsBar(),

          // ═══════════════════ KPI CARDS ═══════════════════
          if (state.activeTab == 0) _buildKpiRow(),

          // ═══════════════════ FILTER BAR ═══════════════════
          _buildFilterBar(state.activeTab),

          // ═══════════════════ TABLE & DETAILS PANEL ═══════════════════
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : state.errorMessage != null
                          ? _buildErrorState(state.errorMessage!)
                          : (state.activeTab == 0
                              ? _buildPurchaseOrdersTable()
                              : _buildSuppliersTable(state.filteredSuppliers)),
                ),
                // Detail Side Panel
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  width: (state.activeTab == 0 ? _selectedPurchaseOrder != null : _selectedSupplierForDetails != null) ? 360 : 0,
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 360,
                      maxWidth: 360,
                      alignment: Alignment.topRight,
                      child: state.activeTab == 0
                          ? (_selectedPurchaseOrder != null
                              ? _buildPurchaseOrderDetailsPanel(_selectedPurchaseOrder!)
                              : const SizedBox.shrink())
                          : (_selectedSupplierForDetails != null
                              ? _buildSupplierDetailsPanel(_selectedSupplierForDetails!)
                              : const SizedBox.shrink()),
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

  Widget _buildSubTabsBar() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSubTabButton(0, 'Purchase Invoices'),
            _buildSubTabButton(1, 'Purchase Orders'),
            _buildSubTabButton(2, 'Supplier Returns'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label) {
    final isSelected = _purchaseSubTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _purchaseSubTab = index;
          _currentPage = 0;
          _selectedPurchaseOrder = null;
        });
      },
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
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int activeTab) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    activeTab == 0 ? 'Purchase Management' : 'Suppliers',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      'v${AppConstants.appVersion}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                activeTab == 0
                    ? 'Supplier invoices, purchase orders, and supplier returns — all in one place.'
                    : 'Manage vendor contacts, payment terms, and credentials.',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Row(
            children: [
              if (activeTab == 0) ...[
                _buildSecondaryButton(
                  label: 'Receive Goods',
                  icon: Icons.assignment_returned_outlined,
                  onPressed: _showReceiveGoodsSelector,
                ),
                const SizedBox(width: 12),
                _buildPrimaryButton(
                  label: 'New Purchase Order',
                  icon: Icons.add_rounded,
                  onPressed: _showCreatePoDialog,
                ),
              ] else
                _buildPrimaryButton(
                  label: 'Register Supplier',
                  icon: Icons.add_rounded,
                  onPressed: _showRegisterSupplierDialog,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.textSecondary),
        label: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showReceiveGoodsSelector() {
    final state = ref.read(purchaseNotifierProvider);
    final eligibleOrders = state.purchaseOrders.where((po) {
      final s = po.status.toUpperCase();
      return s != 'RECEIVED' && s != 'CANCELLED';
    }).toList();

    if (eligibleOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending or approved purchase orders available to receive.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    PurchaseOrder? selectedPo = eligibleOrders[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Select Purchase Order', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose a PO to receive goods against:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PurchaseOrder>(
                        value: selectedPo,
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        items: eligibleOrders.map((po) {
                          return DropdownMenuItem(
                            value: po,
                            child: Text('${po.orderNumber} - ${po.supplier?.name ?? "Unknown"} (₹${po.totalAmountDouble.toStringAsFixed(2)})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedPo = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (selectedPo != null) {
                      _showReceivePoDialog(selectedPo!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Proceed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── KPI ROW ═══════════════════

  Widget _buildKpiRow() {
    final state = ref.watch(purchaseNotifierProvider);
    final now = DateTime.now();

    // 1. THIS MONTH PURCHASES
    double thisMonthPurchases = 0.0;
    for (final po in state.purchaseOrders) {
      final status = po.status.toUpperCase();
      if (status == 'RECEIVED' || status == 'PARTIALLY_RECEIVED') {
        try {
          final date = DateTime.parse(po.createdAt);
          if (date.year == now.year && date.month == now.month) {
            thisMonthPurchases += po.totalAmountDouble;
          }
        } catch (_) {}
      }
    }

    // 2. PENDING POS
    int pendingPosCount = state.purchaseOrders.where((po) {
      final s = po.status.toUpperCase();
      return s == 'PENDING_APPROVAL' || s == 'APPROVED' || s == 'ORDERED';
    }).length;

    // 3. SUPPLIER RETURNS
    double supplierReturnsSum = state.purchaseOrders
        .where((po) => po.status.toUpperCase() == 'CANCELLED')
        .fold<double>(0.0, (sum, po) => sum + po.totalAmountDouble);

    // 4. ACTIVE SUPPLIERS
    int activeSuppliersCount = state.suppliers
        .where((s) => s.status.toUpperCase() == 'ACTIVE')
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: Row(
        children: [
          Expanded(
            child: _kpiCard(
              title: 'THIS MONTH PURCHASES',
              value: '₹${thisMonthPurchases.toStringAsFixed(1)}',
              icon: Icons.shopping_cart_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _kpiCard(
              title: 'PENDING POS',
              value: '$pendingPosCount',
              icon: Icons.schedule_rounded,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _kpiCard(
              title: 'SUPPLIER RETURNS',
              value: '₹${supplierReturnsSum.toStringAsFixed(0)}',
              icon: Icons.keyboard_return_rounded,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _kpiCard(
              title: 'ACTIVE SUPPLIERS',
              value: '$activeSuppliersCount',
              icon: Icons.store_rounded,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
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
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ FILTER BAR ═══════════════════

  Widget _buildFilterBar(int activeTab) {
    final state = ref.watch(purchaseNotifierProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date Range (First)
            _buildDateRangeButton(),
            const SizedBox(width: 12),

            // Supplier Filter (PO tab only) (Second)
            if (activeTab == 0) ...[
              _buildFilterDropdown<String>(
                value: _selectedSupplier,
                items: ['All Suppliers', ...state.suppliers.map((s) => s.name).toSet()],
                label: (v) => v,
                onChanged: (val) {
                  if (val != null) setState(() { _selectedSupplier = val; _currentPage = 0; });
                },
              ),
              const SizedBox(width: 12),
            ],

            // Status Filter (Third)
            _buildFilterDropdown<String>(
              value: state.selectedStatus,
              items: activeTab == 0
                  ? ['All Status', 'DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'RECEIVED', 'CANCELLED']
                  : ['All Status', 'ACTIVE', 'INACTIVE', 'BLACKLISTED'],
              label: (v) => v.replaceAll('_', ' '),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _currentPage = 0);
                  ref.read(purchaseNotifierProvider.notifier).setSelectedStatus(val);
                }
              },
            ),
            const SizedBox(width: 12),

            // Search (Fourth)
            SizedBox(
              width: 240,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: activeTab == 0 ? 'Search by Inv/PO # or Supplier...' : 'Search name, phone, email...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 18),
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ),

            const Spacer(),

            // Refresh
            _buildIconButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh data',
              onPressed: () => ref.read(purchaseNotifierProvider.notifier).loadData(forceRefresh: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textTertiary),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(label(item), overflow: TextOverflow.ellipsis));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    final label = _dateRange == null
        ? 'Date Range'
        : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}';
    return GestureDetector(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _dateRange,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
        if (range != null) {
          setState(() { _dateRange = range; _currentPage = 0; });
        }
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: _dateRange != null ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 16,
              color: _dateRange != null ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _dateRange != null ? AppColors.primary : AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_dateRange != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _dateRange = null),
                child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textTertiary),
              ),
            ] else ...[
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, Color color, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  // ═══════════════════ PURCHASE ORDERS TABLE ═══════════════════

  Widget _buildPurchaseOrdersTable() {
    final orders = _paginatedOrders;
    if (_processedOrders.isEmpty) {
      return _buildEmptyState('No purchase orders found matching your filters.');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Header
            PurchaseTableHeader(
              sortColumn: _sortColumn,
              sortAscending: _sortAscending,
              onSort: _sortBy,
              purchaseSubTab: _purchaseSubTab,
            ),
            // Divider after header
            const Divider(height: 1, color: AppColors.border),
            // Table Body
            Expanded(
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final po = orders[index];
                  return PurchaseRow(
                    po: po,
                    index: index,
                    isHovered: _hoveredRowIndex == index,
                    isSelected: _selectedPurchaseOrder?.id == po.id,
                    onHover: (hovered) => setState(() => _hoveredRowIndex = hovered ? index : null),
                    onReceiveStock: () => _showReceivePoDialog(po),
                    onCancelOrder: () => _showCancelPoDialog(po, ref.read(purchaseNotifierProvider.notifier)),
                    onViewDetails: () => _showPurchaseOrderDetailDialog(po),
                    onTap: () => _showPurchaseOrderDetailDialog(po),
                    purchaseSubTab: _purchaseSubTab,
                  );
                },
              ),
            ),
            // Summary Footer Ribbon
            _buildSummaryRibbon(),
            // Divider before footer
            const Divider(height: 1, color: AppColors.border),
            // Pagination
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRibbon() {
    final filtered = _processedOrders;
    double totalSum = filtered.fold(0.0, (sum, po) => sum + po.totalAmountDouble);
    double gstSum = filtered.fold(0.0, (sum, po) => sum + po.gstAmountDouble);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: const Color(0xFFF1F5F9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Total this period: ',
            style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            '₹${totalSum.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(width: 24),
          const SizedBox(
            height: 16,
            child: VerticalDivider(width: 1, color: AppColors.border),
          ),
          const SizedBox(width: 24),
          const Text(
            'GST input credit: ',
            style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            '₹${gstSum.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showCancelPoDialog(PurchaseOrder po, PurchaseNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Purchase Order', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text('Are you sure you want to cancel order ${po.orderNumber}?', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifier.updateStatus(po.id, 'CANCELLED');
            },
            child: const Text('Cancel Order', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ PAGINATION ═══════════════════

  Widget _buildPagination() {
    final totalPages = (_totalFiltered / _rowsPerPage).ceil().clamp(1, 99999);
    final start = _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, _totalFiltered);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl)),
      ),
      child: Row(
        children: [
          // Records count
          Text(
            'Showing $start\u2013$end of $_totalFiltered Orders',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          // Rows per page
          const Text('Rows per page:', style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  isDense: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textTertiary),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  items: AppConstants.pageSizeOptions.map((size) {
                    return DropdownMenuItem(value: size, child: Text(size.toString()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() { _rowsPerPage = val; _currentPage = 0; });
                  },
                ),
              ),
            ),
          ),
          const Spacer(),
          // Page info
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          // Previous
          _pageButton(
            icon: Icons.chevron_left_rounded,
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          const SizedBox(width: 4),
          // Next
          _pageButton(
            icon: Icons.chevron_right_rounded,
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }

  Widget _pageButton({required IconData icon, VoidCallback? onPressed}) {
    return Tooltip(
      message: onPressed != null ? (icon == Icons.chevron_left_rounded ? 'Previous' : 'Next') : '',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: onPressed != null ? AppColors.border : AppColors.divider),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              size: 18,
              color: onPressed != null ? AppColors.textSecondary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════ SUPPLIERS TABLE ═══════════════════

  Widget _buildSuppliersTable(List<Supplier> suppliers) {
    if (suppliers.isEmpty) {
      return _buildEmptyState('No suppliers registered.');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
              ),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: _TableHeaderText('SUPPLIER NAME')),
                  Expanded(flex: 2, child: _TableHeaderText('PHONE')),
                  Expanded(flex: 3, child: _TableHeaderText('EMAIL')),
                  Expanded(flex: 3, child: _TableHeaderText('GST NUMBER')),
                  Expanded(flex: 2, child: _TableHeaderText('STATUS')),
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: _TableHeaderText('ACTIONS'))),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.separated(
                itemCount: suppliers.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final sup = suppliers[index];
                  final isEven = index.isEven;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hoveredRowIndex = index),
                    onExit: (_) => setState(() => _hoveredRowIndex = null),
                    child: AnimatedContainer(
                      duration: AppConstants.animationFast,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedSupplierForDetails?.id == sup.id
                            ? const Color(0xFFCCFBF1)
                            : _hoveredRowIndex == index
                                ? AppColors.primarySurface
                                : isEven ? AppColors.white : AppColors.surface.withValues(alpha: 0.4),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSupplierForDetails = _selectedSupplierForDetails?.id == sup.id ? null : sup;
                          });
                        },
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      sup.name.isNotEmpty ? sup.name[0].toUpperCase() : 'S',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(sup.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
                                        if (sup.isPreferred)
                                          Container(
                                            margin: const EdgeInsets.only(top: 2),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(3)),
                                            child: const Text('Preferred', style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(sup.phone, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Tooltip(
                                message: sup.email,
                                child: Text(sup.email, overflow: TextOverflow.ellipsis, maxLines: 1,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: sup.gstNumber.isEmpty || sup.gstNumber.toLowerCase() == 'none' || sup.gstNumber.toLowerCase() == 'n/a'
                                  ? const Text('\u2014', style: TextStyle(color: AppColors.textTertiary, fontSize: 13))
                                  : InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: sup.gstNumber));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                          content: Text('GST number copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppColors.primary,
                                        ));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.infoLight,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.infoLight),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(sup.gstNumber, style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600, fontSize: 11)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.copy_rounded, size: 10, color: AppColors.info),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _buildSupplierStatusChip(sup.status),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _actionIcon(Icons.visibility_outlined, 'View Details', AppColors.primary, () => _showSupplierDetailsDialog(sup)),
                                    const SizedBox(width: 2),
                                    _actionIcon(Icons.edit_outlined, 'Edit Supplier', AppColors.info, () => _showEditSupplierDialog(sup)),
                                    const SizedBox(width: 2),
                                    _actionIcon(Icons.delete_outline_rounded, 'Delete Supplier', AppColors.error, () => _showDeleteSupplierConfirm(sup)),
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
    );
  }

  void _showDeleteSupplierConfirm(Supplier sup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Supplier', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete supplier "${sup.name}"? This action cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(purchaseNotifierProvider.notifier).deleteSupplierLocal(sup.id);
      setState(() {
        if (_selectedSupplierForDetails?.id == sup.id) {
          _selectedSupplierForDetails = null;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Supplier "${sup.name}" deleted successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ═══════════════════ SUPPLIER DETAIL DIALOG ═══════════════════

  void _showSupplierDetailsDialog(Supplier sup) {
    final isActive = sup.status.toUpperCase() == 'ACTIVE';
    final initial = sup.name.isNotEmpty ? sup.name[0].toUpperCase() : 'S';

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
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(sup.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                            const SizedBox(height: 4),
                            Text(sup.supplierCode ?? 'No Code', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _detailBadge(
                                  color: isActive ? const Color(0xFF4ADE80) : Colors.white70,
                                  bgColor: isActive ? const Color(0xFF4ADE80).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.15),
                                  label: sup.status.toUpperCase(),
                                  dot: true,
                                ),
                                if (sup.isPreferred) ...[
                                  const SizedBox(width: 8),
                                  _detailBadge(
                                    color: const Color(0xFFFBBF24),
                                    bgColor: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                                    label: 'PREFERRED',
                                    icon: Icons.star_rounded,
                                  ),
                                ],
                                if (sup.supplierType != null && sup.supplierType!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  _detailBadge(
                                    color: Colors.white,
                                    bgColor: Colors.white.withValues(alpha: 0.15),
                                    label: sup.supplierType!.toUpperCase(),
                                  ),
                                ],
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
                ),
                Flexible(
                  child: Container(
                    color: AppColors.surface,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('General & Contact Info', Icons.person_outline_rounded),
                          const SizedBox(height: 12),
                          _buildInfoGrid([
                            _SupplierField(icon: Icons.phone_rounded, label: 'Phone', value: sup.phone),
                            _SupplierField(icon: Icons.email_outlined, label: 'Email', value: sup.email),
                            _SupplierField(icon: Icons.badge_outlined, label: 'Contact Person', value: sup.contactPerson ?? '\u2014'),
                            _SupplierField(icon: Icons.location_on_outlined, label: 'Address', value: sup.address, fullWidth: true),
                          ]),
                          const SizedBox(height: 20),
                          _buildSectionLabel('Compliance & Terms', Icons.verified_outlined),
                          const SizedBox(height: 12),
                          _buildInfoGrid([
                            _SupplierField(icon: Icons.receipt_long_outlined, label: 'GST Number', value: sup.gstNumber, isMono: true),
                            _SupplierField(icon: Icons.local_pharmacy_outlined, label: 'Drug License', value: sup.drugLicenseNumber ?? '\u2014'),
                            _SupplierField(icon: Icons.schedule_rounded, label: 'Lead Time', value: '${sup.leadTimeDays} Days'),
                            _SupplierField(icon: Icons.payment_rounded, label: 'Payment Terms', value: '${sup.paymentTermsDays} Days'),
                            if (sup.licenseExpiry != null && sup.licenseExpiry!.isNotEmpty)
                              _SupplierField(icon: Icons.event_rounded, label: 'License Expiry', value: sup.licenseExpiry!),
                          ]),
                          const SizedBox(height: 20),
                          _buildSectionLabel('Financial Summary', Icons.account_balance_wallet_outlined),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildFinancialCard(
                                label: 'Outstanding Balance',
                                value: '₹${sup.outstandingBalance?.toStringAsFixed(2) ?? '0.00'}',
                                icon: Icons.pending_actions_rounded,
                                color: (sup.outstandingBalance ?? 0) > 0 ? AppColors.error : AppColors.primary,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialCard(
                                label: 'Credit Limit',
                                value: '₹${sup.creditLimit?.toStringAsFixed(2) ?? '0.00'}',
                                icon: Icons.credit_score_rounded,
                                color: AppColors.purple,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialCard(
                                label: 'Total Purchases',
                                value: '₹${sup.totalPurchases?.toStringAsFixed(2) ?? '0.00'}',
                                icon: Icons.shopping_bag_outlined,
                                color: AppColors.info,
                              )),
                            ],
                          ),
                          if (sup.rating != null) ...[
                            const SizedBox(height: 12),
                            _buildRatingCard(sup.rating!),
                          ],
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
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
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
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

  void _showPurchaseOrderDetailDialog(PurchaseOrder po) {
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
                _buildPoDialogHeader(po),
                Flexible(
                  child: Container(
                    color: AppColors.surface,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Supplier Info', Icons.person_outline_rounded),
                          const SizedBox(height: 12),
                          _buildInfoGrid([
                            _SupplierField(icon: Icons.business_rounded, label: 'Supplier', value: po.supplier?.name ?? '\u2014'),
                            _SupplierField(icon: Icons.phone_rounded, label: 'Phone', value: po.supplier?.phone ?? '\u2014'),
                            _SupplierField(icon: Icons.email_outlined, label: 'Email', value: po.supplier?.email ?? '\u2014'),
                            _SupplierField(icon: Icons.receipt_long_outlined, label: 'GST', value: po.supplier?.gstNumber ?? '\u2014'),
                          ]),
                          const SizedBox(height: 20),
                          _buildSectionLabel('Order Items', Icons.inventory_2_outlined),
                          const SizedBox(height: 12),
                          _buildPoItemsTable(po),
                          const SizedBox(height: 20),
                          _buildPoTotalsSection(po),
                          if (po.notes != null && po.notes!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildSectionLabel('Notes', Icons.notes_rounded),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(po.notes!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildPoDialogFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoDialogHeader(PurchaseOrder po) {
    final status = po.status;
    final orderDate = DateTime.parse(po.createdAt).toLocal();
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A365D), Color(0xFF2563EB), Color(0xFF3B82F6)],
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
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(po.orderNumber, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM yyyy').format(orderDate), style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatusBadge(status),
                    if (po.expectedDeliveryDate != null && po.expectedDeliveryDate!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _detailBadge(
                        color: const Color(0xFFFBBF24),
                        bgColor: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                        label: 'Delivery: ${po.expectedDeliveryDate}',
                      ),
                    ],
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

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    switch (status.toUpperCase()) {
      case 'RECEIVED':
        color = const Color(0xFF4ADE80);
        bgColor = const Color(0xFF4ADE80).withValues(alpha: 0.2);
      case 'PARTIALLY_RECEIVED':
      case 'PARTIALLY RECEIVED':
        color = const Color(0xFFFBBF24);
        bgColor = const Color(0xFFFBBF24).withValues(alpha: 0.2);
      case 'DRAFT':
        color = const Color(0xFF94A3B8);
        bgColor = const Color(0xFF94A3B8).withValues(alpha: 0.2);
      case 'PENDING_APPROVAL':
        color = const Color(0xFF60A5FA);
        bgColor = const Color(0xFF60A5FA).withValues(alpha: 0.2);
      case 'APPROVED':
        color = const Color(0xFF34D399);
        bgColor = const Color(0xFF34D399).withValues(alpha: 0.2);
      case 'CANCELLED':
        color = const Color(0xFFF87171);
        bgColor = const Color(0xFFF87171).withValues(alpha: 0.2);
      default:
        color = const Color(0xFF94A3B8);
        bgColor = const Color(0xFF94A3B8).withValues(alpha: 0.2);
    }
    return _detailBadge(color: color, bgColor: bgColor, label: status.replaceAll('_', ' '), dot: true);
  }

  Widget _buildPoItemsTable(PurchaseOrder po) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textTertiary, letterSpacing: 0.3))),
                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textTertiary, letterSpacing: 0.3))),
                Expanded(flex: 2, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textTertiary, letterSpacing: 0.3))),
                Expanded(flex: 1, child: Text('GST%', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textTertiary, letterSpacing: 0.3))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textTertiary, letterSpacing: 0.3)))),
              ],
            ),
          ),
          ...List.generate(po.items.length, (i) {
            final item = po.items[i];
            final qtyReceived = item.receivedQuantity > 0 ? '${item.receivedQuantity}/${item.quantity}' : '${item.quantity}';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: i < po.items.length - 1
                  ? BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider)))
                  : null,
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary))),
                  Expanded(flex: 1, child: Text(qtyReceived, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Text('\u20B9${item.unitPriceDouble.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                  Expanded(flex: 1, child: Text('${item.gstPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('\u20B9${item.totalAmountDouble.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPoTotalsSection(PurchaseOrder po) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', '\u20B9${po.subtotalDouble.toStringAsFixed(2)}', false),
          const Divider(height: 24, color: AppColors.divider),
          _buildTotalRow('GST Amount', '\u20B9${po.gstAmountDouble.toStringAsFixed(2)}', false),
          const Divider(height: 24, color: AppColors.divider),
          _buildTotalRow('Total Amount', '\u20B9${po.totalAmountDouble.toStringAsFixed(2)}', true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: isBold ? AppColors.textPrimary : AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: isBold ? AppColors.primary : AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPoDialogFooter(BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBadge({required Color color, required Color bgColor, required String label, bool dot = false, IconData? icon}) {
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

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13, letterSpacing: 0.2)),
      ],
    );
  }

  Widget _buildInfoGrid(List<_SupplierField> fields) {
    final regular = fields.where((f) => !f.fullWidth).toList();
    final full = fields.where((f) => f.fullWidth).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          ...() {
            final rows = <Widget>[];
            for (int i = 0; i < regular.length; i += 2) {
              if (i > 0) rows.add(const Divider(height: 20, color: AppColors.divider));
              rows.add(Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFieldCell(regular[i])),
                  if (i + 1 < regular.length) ...[
                    const VerticalDivider(width: 24, color: AppColors.divider),
                    Expanded(child: _buildFieldCell(regular[i + 1])),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ));
            }
            return rows;
          }(),
          ...full.map((f) => Column(
            children: [
              const Divider(height: 20, color: AppColors.divider),
              _buildFieldCell(f),
            ],
          )),
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
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(f.icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(
                f.value.isEmpty ? '\u2014' : f.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: f.value.isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
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

  Widget _buildFinancialCard({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRatingCard(double rating) {
    final filled = rating.round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Supplier Rating', style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: i < filled ? AppColors.warning : AppColors.textTertiary,
                  )),
                  const SizedBox(width: 8),
                  Text('${rating.toStringAsFixed(1)} / 5.0', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════ ERROR / EMPTY STATES ═══════════════════

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('An error occurred: $message', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(purchaseNotifierProvider.notifier).loadData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: AppColors.textTertiary, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseOrderDetailsPanel(PurchaseOrder po) {
    final isCancelled = po.status == 'CANCELLED';
    final isReceived = po.status == 'RECEIVED';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(left: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
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
                      'Purchase Order Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      po.orderNumber,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
                  onPressed: () => setState(() => _selectedPurchaseOrder = null),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusBg(po.status),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _statusColor(po.status).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCancelled ? Icons.error_outline : Icons.check_circle_outline,
                          color: _statusColor(po.status),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                po.status.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _statusColor(po.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SUPPLIER DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailField('Name', po.supplier?.name ?? '—'),
                        const SizedBox(height: 8),
                        _buildDetailField('Phone', po.supplier?.phone ?? '—'),
                        const SizedBox(height: 8),
                        _buildDetailField('GSTIN', po.supplier?.gstNumber ?? '—'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ITEMS ORDERED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: po.items.length,
                      separatorBuilder: (_, index) => const Divider(height: 16),
                      itemBuilder: (context, idx) {
                        final item = po.items[idx];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.medicineName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Qty: ${item.quantity} | Recd: ${item.receivedQuantity}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.totalAmountDouble.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ORDER SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailField('Subtotal', '₹${po.subtotalDouble.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildDetailField('GST', '₹${po.gstAmountDouble.toStringAsFixed(2)}'),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                            Text(
                              '₹${po.totalAmountDouble.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (po.notes != null && po.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        po.notes!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isCancelled && !isReceived)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelPoDialog(po, ref.read(purchaseNotifierProvider.notifier)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showReceivePoDialog(po),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Receive Stock', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierDetailsPanel(Supplier sup) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(left: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUPPLIER DETAILS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textTertiary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sup.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
                  onPressed: () => setState(() => _selectedSupplierForDetails = null),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabelText('General Info'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailField('Supplier Code', sup.supplierCode ?? '—'),
                        const SizedBox(height: 8),
                        _buildDetailField('Contact Person', sup.contactPerson ?? '—'),
                        const SizedBox(height: 8),
                        _buildDetailField('Phone', sup.phone),
                        const SizedBox(height: 8),
                        _buildDetailField('Email', sup.email),
                        const SizedBox(height: 8),
                        _buildDetailField('Address', sup.address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabelText('Compliance'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailField('GST Number', sup.gstNumber.isEmpty ? '—' : sup.gstNumber),
                        const SizedBox(height: 8),
                        _buildDetailField('Drug License', sup.drugLicenseNumber ?? '—'),
                        const SizedBox(height: 8),
                        _buildDetailField('Lead Time', '${sup.leadTimeDays} Days'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabelText('Financials'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Outstanding', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text(
                              '₹${(sup.outstandingBalance ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: (sup.outstandingBalance ?? 0) > 0 ? AppColors.error : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailField('Credit Limit', '₹${(sup.creditLimit ?? 0).toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildDetailField('Total Purchases', '₹${(sup.totalPurchases ?? 0).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabelText('Bank Details'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailField('Bank Name', sup.bankName ?? '—'),
                        const SizedBox(height: 8),
                        _buildDetailField('Account No.', sup.accountNumber ?? '—'),
                        const SizedBox(height: 8),
                        _buildDetailField('IFSC Code', sup.ifscCode ?? '—'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditSupplierDialog(sup),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDeleteSupplierConfirm(sup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabelText(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
    );
  }

  Widget _buildDetailField(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
      ],
    );
  }
}

// ═══════════════════ SHARED WIDGETS ═══════════════════

class _TableHeaderText extends StatelessWidget {
  final String label;
  const _TableHeaderText(this.label);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

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

// ═══════════════════ REUSABLE DATA TABLE COMPONENTS ═══════════════════

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusUpper = status.toUpperCase();
    final Color color;
    final Color bg;

    switch (statusUpper) {
      case 'RECEIVED':
        color = const Color(0xFF10B981); // Emerald Green
        bg = const Color(0xFFD1FAE5); // Emerald Green Light
        break;
      case 'PARTIALLY_RECEIVED':
      case 'PARTIALLY RECEIVED':
        color = const Color(0xFFD97706); // Dark Amber/Orange
        bg = const Color(0xFFFEF3C7); // Amber Light
        break;
      case 'DRAFT':
        color = const Color(0xFF64748B); // Slate Gray
        bg = const Color(0xFFF1F5F9);
        break;
      case 'PENDING_APPROVAL':
        color = const Color(0xFF3B82F6); // Blue
        bg = const Color(0xFFDBEAFE);
        break;
      case 'APPROVED':
        color = const Color(0xFF0D9488); // Teal
        bg = const Color(0xFFCCFBF1);
        break;
      case 'CANCELLED':
        color = const Color(0xFFEF4444); // Red
        bg = const Color(0xFFFEE2E2);
        break;
      default:
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF1F5F9);
    }

    final clean = status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              clean,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButtons extends ConsumerWidget {
  final PurchaseOrder po;
  final VoidCallback onReceiveStock;
  final VoidCallback onCancelOrder;
  final VoidCallback onViewDetails;

  const ActionButtons({
    super.key,
    required this.po,
    required this.onReceiveStock,
    required this.onCancelOrder,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(purchaseNotifierProvider.notifier);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'View Details',
          child: Material(
            color: Colors.transparent,
            child:             InkWell(
              onTap: onViewDetails,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildMoreMenu(context, ref, notifier),
      ],
    );
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref, PurchaseNotifier notifier) {
    final status = po.status.toUpperCase();
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.white,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textTertiary),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            break;
          case 'receive':
            onReceiveStock();
            break;
          case 'submit':
            notifier.updateStatus(po.id, 'PENDING_APPROVAL');
            break;
          case 'approve':
            notifier.approvePurchaseOrder(po.id);
            break;
          case 'download':
            break;
          case 'cancel':
            onCancelOrder();
            break;
          case 'duplicate':
            break;
          case 'print':
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Edit PO', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        if (status == 'APPROVED')
          const PopupMenuItem(
            value: 'receive',
            child: Row(
              children: [
                Icon(Icons.inventory_rounded, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Text('Receive Stock', style: TextStyle(fontSize: 13, color: AppColors.success)),
              ],
            ),
          ),
        if (status == 'DRAFT')
          const PopupMenuItem(
            value: 'submit',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: AppColors.info),
                SizedBox(width: 8),
                Text('Submit', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        if (status == 'PENDING_APPROVAL')
          const PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 16, color: AppColors.info),
                SizedBox(width: 8),
                Text('Approve', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download_outlined, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Download PDF', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        if (status == 'DRAFT' || status == 'PENDING_APPROVAL' || status == 'APPROVED')
          PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: const [
                Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text('Cancel Order', style: TextStyle(fontSize: 13, color: AppColors.error)),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Duplicate', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print_rounded, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Print', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class PurchaseTableHeader extends StatelessWidget {
  final String? sortColumn;
  final bool sortAscending;
  final Function(String) onSort;
  final int purchaseSubTab;

  const PurchaseTableHeader({
    super.key,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.purchaseSubTab,
  });

  @override
  Widget build(BuildContext context) {
    String statusHeader = 'STATUS';
    if (purchaseSubTab == 0) {
      statusHeader = 'PAYMENT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: Row(
        children: [
          _sortableHeader('DATE', 'date', flex: 2),
          _sortableHeader('SUPPLIER', 'supplier', flex: 3),
          const Expanded(flex: 3, child: _TableHeaderText('MEDICINES')),
          _sortableHeader('TOTAL', 'amount', flex: 2),
          const Expanded(flex: 2, child: _TableHeaderText('GST')),
          Expanded(flex: 2, child: _TableHeaderText(statusHeader)),
          const Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: _TableHeaderText('ACTIONS'))),
        ],
      ),
    );
  }

  Widget _sortableHeader(String label, String column, {int flex = 1}) {
    final isActive = sortColumn == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(column),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.primary : const Color(0xFF64748B),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PurchaseRow extends ConsumerWidget {
  final PurchaseOrder po;
  final int index;
  final bool isHovered;
  final bool isSelected;
  final ValueChanged<bool> onHover;
  final VoidCallback onReceiveStock;
  final VoidCallback onCancelOrder;
  final VoidCallback onViewDetails;
  final VoidCallback onTap;
  final int purchaseSubTab;

  const PurchaseRow({
    super.key,
    required this.po,
    required this.index,
    required this.isHovered,
    required this.isSelected,
    required this.onHover,
    required this.onReceiveStock,
    required this.onCancelOrder,
    required this.onViewDetails,
    required this.onTap,
    required this.purchaseSubTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEven = index.isEven;

    String medicineSummary = po.items.map((item) => item.medicineName).join(', ');
    if (medicineSummary.isEmpty) medicineSummary = '—';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFCCFBF1)
                : isHovered
                    ? AppColors.primarySurface
                    : isEven
                        ? AppColors.white
                        : AppColors.surface.withValues(alpha: 0.4),
          ),
          child: Row(
            children: [
              // Date
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(po.createdAt).toLocal()),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(DateTime.parse(po.createdAt).toLocal()),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Supplier
              Expanded(
                flex: 3,
                child: Text(
                  po.supplier?.name ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              // Medicines
              Expanded(
                flex: 3,
                child: Tooltip(
                  message: medicineSummary,
                  child: Text(
                    medicineSummary,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              // Amount
              Expanded(
                flex: 2,
                child: Text(
                  '₹${po.totalAmountDouble.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 14),
                ),
              ),
              // GST
              Expanded(
                flex: 2,
                child: Text(
                  '₹${po.gstAmountDouble.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              // Status / Payment
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: purchaseSubTab == 0
                      ? _buildPaymentChip(po.status)
                      : StatusChip(status: po.status),
                ),
              ),
              // Actions
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ActionButtons(
                    po: po,
                    onReceiveStock: onReceiveStock,
                    onCancelOrder: onCancelOrder,
                    onViewDetails: onViewDetails,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String status) {
    final isPaid = status.toUpperCase() == 'RECEIVED';
    final label = isPaid ? 'PAID' : 'PENDING';
    final color = isPaid ? AppColors.success : AppColors.warning;
    final bg = isPaid ? AppColors.successLight : AppColors.warningLight;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
