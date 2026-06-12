import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import '../notifier/inventory_notifier.dart';
import '../widgets/add_medicine_dialog.dart';
import '../widgets/add_batch_dialog.dart';
import '../../domain/models/medicine.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 15;
  int? _hoveredRowIndex; // Track hovered row for table effect
  Timer? _debounceTimer;
  Medicine? _selectedMedicineForDetails;
  final FocusNode _focusNode = FocusNode();
  final _kpiScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    Future.microtask(() {
      final currentMedicines = ref.read(inventoryNotifierProvider).medicines;
      if (currentMedicines.isEmpty) {
        ref.read(inventoryNotifierProvider.notifier).loadInventory(limit: 1000);
      }
    });
    // Synchronize search text input with notifier state with debouncing
    _searchController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref
              .read(inventoryNotifierProvider.notifier)
              .setSearch(_searchController.text);
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

  String _formatExpiryDate(String? expiryString) {
    if (expiryString == null || expiryString.isEmpty) return '—';
    try {
      final date = DateTime.parse(expiryString);
      return DateFormat('MMM yyyy').format(date);
    } catch (_) {
      return expiryString;
    }
  }

  bool _isDateExpired(String? expiryString) {
    if (expiryString == null || expiryString.isEmpty) return false;
    try {
      final date = DateTime.parse(expiryString);
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _isNearExpiry(String? expiryString) {
    if (expiryString == null || expiryString.isEmpty) return false;
    try {
      final date = DateTime.parse(expiryString);
      final now = DateTime.now();
      // Near expiry if within 180 days (6 months) and not yet expired
      return date.isAfter(now) &&
          date.isBefore(now.add(const Duration(days: 180)));
    } catch (_) {
      return false;
    }
  }

  void _showAddMedicineDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddMedicineDialog(),
    ).then((success) {
      if (success == true) {
        // Refresh is handled inside dialog
      }
    });
  }

  void _showEditMedicineDialog(Medicine medicine) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddMedicineDialog(medicine: medicine),
    ).then((success) {
      if (success == true) {
        // Handled inside
      }
    });
  }

  void _confirmDeleteMedicine(Medicine medicine) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Medicine',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${medicine.name}? This action cannot be undone.',
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(inventoryNotifierProvider.notifier)
                  .deleteMedicine(id: medicine.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${medicine.name} deleted successfully!'),
                      backgroundColor: const Color(0xFF0D9488),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  final error =
                      ref.read(inventoryNotifierProvider).errorMessage ??
                      'Failed to delete medicine';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
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
    const primaryTeal = Color(0xFF0F766E); // Deep elegant teal
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF4F7FA); // Soft background

    final state = ref.watch(inventoryNotifierProvider);
    final medicines = state.filteredMedicines;

    // Find the latest selected medicine from state to ensure updated values are displayed
    final selectedMed = _selectedMedicineForDetails != null
        ? state.medicines.firstWhere(
            (m) => m.id == _selectedMedicineForDetails!.id,
            orElse: () => _selectedMedicineForDetails!,
          )
        : null;

    // Pagination calculations
    final totalItems = medicines.length;
    final totalPages = totalItems > 0 ? (totalItems / _pageSize).ceil() : 1;
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final paginatedMedicines = medicines.sublist(
      startIndex,
      endIndex > totalItems ? totalItems : endIndex,
    );

    // List of category names for dropdown
    final categoryList = [
      'All Categories',
      ...state.categories.map((c) => c.name),
    ];
    const statusList = [
      'All Status',
      'In Stock',
      'Low Stock',
      'Out of Stock',
      'Expired',
    ];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (_selectedMedicineForDetails != null) {
              setState(() {
                _selectedMedicineForDetails = null;
              });
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (_selectedMedicineForDetails != null) {
              final currentIndex = paginatedMedicines.indexWhere(
                (m) => m.id == _selectedMedicineForDetails!.id,
              );
              if (currentIndex >= 0 &&
                  currentIndex < paginatedMedicines.length - 1) {
                setState(() {
                  _selectedMedicineForDetails =
                      paginatedMedicines[currentIndex + 1];
                });
                return KeyEventResult.handled;
              }
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (_selectedMedicineForDetails != null) {
              final currentIndex = paginatedMedicines.indexWhere(
                (m) => m.id == _selectedMedicineForDetails!.id,
              );
              if (currentIndex > 0) {
                setState(() {
                  _selectedMedicineForDetails =
                      paginatedMedicines[currentIndex - 1];
                });
                return KeyEventResult.handled;
              }
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
                          'Stock Management',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage pharmaceutical stock, track batches and monitor expiry dates.',
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
                        // Export CSV Button
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('CSV Export started...'),
                                backgroundColor: primaryTeal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
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
                        // Add Medicine Button
                        ElevatedButton.icon(
                          onPressed: _showAddMedicineDialog,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Add Medicine'),
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
                            // 2. MODERN STATS CARDS (Horizontal Scrollable Ribbon)
                            Scrollbar(
                              controller: _kpiScrollController,
                              thumbVisibility: false,
                              trackVisibility: false,
                              child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context)
                                    .copyWith(
                                      dragDevices: {
                                        ...ScrollConfiguration.of(
                                          context,
                                        ).dragDevices,
                                        PointerDeviceKind.mouse,
                                      },
                                    ),
                                child: SingleChildScrollView(
                                  controller: _kpiScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 230,
                                        height: 140,
                                        child: _buildStatCard(
                                          'Total Products',
                                          state.totalSKU.toString(),
                                          Icons.layers_outlined,
                                          const Color(0xFF3B82F6),
                                          () {
                                            ref
                                                .read(
                                                  inventoryNotifierProvider
                                                      .notifier,
                                                )
                                                .setStatus('All Status');
                                            setState(() => _currentPage = 1);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 230,
                                        height: 140,
                                        child: _buildStatCard(
                                          'In Stock',
                                          state.inStockCount.toString(),
                                          Icons.check_circle_outline,
                                          const Color(0xFF10B981),
                                          () {
                                            ref
                                                .read(
                                                  inventoryNotifierProvider
                                                      .notifier,
                                                )
                                                .setStatus('In Stock');
                                            setState(() => _currentPage = 1);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 230,
                                        height: 140,
                                        child: _buildStatCard(
                                          'Low Stock',
                                          state.lowStockCount.toString(),
                                          Icons.warning_amber_rounded,
                                          const Color(0xFFF59E0B),
                                          () {
                                            ref
                                                .read(
                                                  inventoryNotifierProvider
                                                      .notifier,
                                                )
                                                .setStatus('Low Stock');
                                            setState(() => _currentPage = 1);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 230,
                                        height: 140,
                                        child: _buildStatCard(
                                          'Out of Stock',
                                          state.outOfStockCount.toString(),
                                          Icons.cancel_outlined,
                                          const Color(0xFFEF4444),
                                          () {
                                            ref
                                                .read(
                                                  inventoryNotifierProvider
                                                      .notifier,
                                                )
                                                .setStatus('Out of Stock');
                                            setState(() => _currentPage = 1);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 230,
                                        height: 140,
                                        child: _buildStatCard(
                                          'Expired',
                                          state.expiredCount.toString(),
                                          Icons.calendar_today_outlined,
                                          const Color(0xFF9F1239),
                                          () {
                                            ref
                                                .read(
                                                  inventoryNotifierProvider
                                                      .notifier,
                                                )
                                                .setStatus('Expired');
                                            setState(() => _currentPage = 1);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 230,
                                        height: 140,
                                        child: _buildStatCard(
                                          'Inventory Value',
                                          _formatLargeCurrency(
                                            state.inventoryValue,
                                          ),
                                          Icons.currency_rupee,
                                          primaryTeal,
                                          () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 3. UNIFIED CONTROL BAR (Search & Filters)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 800;

                                Widget searchField = TextField(
                                  controller: _searchController,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search medicine, generic or batch',
                                    hintStyle: TextStyle(
                                      color: softGrey.withValues(alpha: 0.7),
                                      fontSize: 15,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: softGrey.withValues(alpha: 0.7),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                );

                                Widget categoryDropdown =
                                    DropdownButtonFormField<String>(
                                      initialValue: state.selectedCategory,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: softGrey,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 6,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: textDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items: categoryList
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(c),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref
                                              .read(
                                                inventoryNotifierProvider
                                                    .notifier,
                                              )
                                              .setCategory(val);
                                          setState(() => _currentPage = 1);
                                        }
                                      },
                                    );

                                Widget statusDropdown =
                                    DropdownButtonFormField<String>(
                                      initialValue: state.selectedStatus,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: softGrey,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 6,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: textDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items: statusList
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref
                                              .read(
                                                inventoryNotifierProvider
                                                    .notifier,
                                              )
                                              .setStatus(val);
                                          setState(() => _currentPage = 1);
                                        }
                                      },
                                    );

                                if (isNarrow) {
                                  return Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: searchField,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE2E8F0,
                                                  ),
                                                ),
                                              ),
                                              child: categoryDropdown,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE2E8F0,
                                                  ),
                                                ),
                                              ),
                                              child: statusDropdown,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                } else {
                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.03,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: searchField),
                                        Container(
                                          width: 1,
                                          height: 30,
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: categoryDropdown,
                                        ),
                                        Container(
                                          width: 1,
                                          height: 30,
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: statusDropdown,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 24),

                            // 4. PREMIUM DATA TABLE
                            LayoutBuilder(
                              builder: (context, tableConstraints) {
                                final showDrawer = selectedMed != null;
                                final double minTableWidth = showDrawer
                                    ? 860.0
                                    : 1100.0;
                                final useScroll =
                                    tableConstraints.maxWidth < minTableWidth;

                                Widget cell(
                                  Widget child,
                                  double width,
                                  int flex,
                                ) {
                                  return useScroll
                                      ? SizedBox(width: width, child: child)
                                      : Expanded(flex: flex, child: child);
                                }

                                Widget tableContent = Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                            bottom: BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            cell(
                                              const _TableHeaderText(
                                                'MEDICINE',
                                              ),
                                              260,
                                              26,
                                            ),
                                            if (!showDrawer)
                                              cell(
                                                const _TableHeaderText(
                                                  'CATEGORY',
                                                ),
                                                120,
                                                12,
                                              ),
                                            cell(
                                              const _TableHeaderText(
                                                'BATCH & EXPIRY',
                                              ),
                                              180,
                                              18,
                                            ),
                                            cell(
                                              const _TableHeaderText('STOCK'),
                                              90,
                                              9,
                                            ),
                                            if (!showDrawer)
                                              cell(
                                                const _TableHeaderText('MRP'),
                                                120,
                                                12,
                                              ),
                                            cell(
                                              const _TableHeaderText('STATUS'),
                                              140,
                                              14,
                                            ),
                                            const SizedBox(
                                              width: 140,
                                              child: _TableHeaderText(
                                                'ACTIONS',
                                                alignRight: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Table Body
                                      state.isLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(40.0),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: primaryTeal,
                                                    ),
                                              ),
                                            )
                                          : state.errorMessage != null
                                          ? _buildErrorState(
                                              state.errorMessage!,
                                            )
                                          : medicines.isEmpty
                                          ? _buildEmptyState()
                                          : ListView.separated(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              padding: EdgeInsets.zero,
                                              itemCount:
                                                  paginatedMedicines.length,
                                              separatorBuilder:
                                                  (context, index) =>
                                                      const Divider(
                                                        height: 1,
                                                        color: Color(
                                                          0xFFF1F5F9,
                                                        ),
                                                      ),
                                              itemBuilder: (context, index) {
                                                final med =
                                                    paginatedMedicines[index];
                                                return MouseRegion(
                                                  onEnter: (_) => setState(
                                                    () => _hoveredRowIndex =
                                                        index,
                                                  ),
                                                  onExit: (_) => setState(
                                                    () =>
                                                        _hoveredRowIndex = null,
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedMedicineForDetails =
                                                            med;
                                                      });
                                                    },
                                                    child: Container(
                                                      color:
                                                          selectedMed?.id ==
                                                              med.id
                                                          ? const Color(
                                                              0xFFE6F4F1,
                                                            ) // Selected soft teal-like highlight
                                                          : _hoveredRowIndex ==
                                                                index
                                                          ? const Color(
                                                              0xFFF8FAFC,
                                                            )
                                                          : Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 24,
                                                            vertical: 24,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          // Medicine Info
                                                          cell(
                                                            Row(
                                                              children: [
                                                                _buildAvatar(
                                                                  med.name,
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        med.name,
                                                                        style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                          color:
                                                                              textDark,
                                                                          fontSize:
                                                                              15,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            4,
                                                                      ),
                                                                      Text(
                                                                        med.genericName ??
                                                                            'No Generic',
                                                                        style: TextStyle(
                                                                          color: softGrey.withValues(
                                                                            alpha:
                                                                                0.8,
                                                                          ),
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            260,
                                                            26,
                                                          ),
                                                          // Category
                                                          if (!showDrawer)
                                                            cell(
                                                              Align(
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(
                                                                      0xFFEFF6FF,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          6,
                                                                        ),
                                                                    border: Border.all(
                                                                      color: const Color(
                                                                        0xFFBFDBFE,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    med.category?.name ??
                                                                        'Uncategorized',
                                                                    style: const TextStyle(
                                                                      color: Color(
                                                                        0xFF1D4ED8,
                                                                      ),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              120,
                                                              12,
                                                            ),
                                                          // Batch & Expiry
                                                          cell(
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  med.batchNumber ??
                                                                      '—',
                                                                  style: const TextStyle(
                                                                    color:
                                                                        textDark,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .event_outlined,
                                                                      size: 12,
                                                                      color: softGrey.withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 4,
                                                                    ),
                                                                    Text(
                                                                      _formatExpiryDate(
                                                                        med.expiryDate,
                                                                      ),
                                                                      style: TextStyle(
                                                                        color:
                                                                            _isDateExpired(
                                                                              med.expiryDate,
                                                                            )
                                                                            ? const Color(
                                                                                0xFFEF4444,
                                                                              )
                                                                            : _isNearExpiry(
                                                                                med.expiryDate,
                                                                              )
                                                                            ? const Color(
                                                                                0xFFF59E0B,
                                                                              )
                                                                            : const Color(
                                                                                0xFF10B981,
                                                                              ),
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            180,
                                                            18,
                                                          ),
                                                          // Stock
                                                          cell(
                                                            Text(
                                                              med.stock
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color:
                                                                    med.stock ==
                                                                        0
                                                                    ? const Color(
                                                                        0xFFEF4444,
                                                                      )
                                                                    : med.stock <=
                                                                          (med.reorderLevel ??
                                                                              10)
                                                                    ? const Color(
                                                                        0xFFF59E0B,
                                                                      )
                                                                    : const Color(
                                                                        0xFF10B981,
                                                                      ),
                                                              ),
                                                            ),
                                                            90,
                                                            9,
                                                          ),
                                                          // MRP
                                                          if (!showDrawer)
                                                            cell(
                                                              Text(
                                                                '₹${med.mrp.toStringAsFixed(2)}',
                                                                style: const TextStyle(
                                                                  color:
                                                                      textDark,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              120,
                                                              12,
                                                            ),
                                                          // Status
                                                          cell(
                                                            _buildStatusBadge(
                                                              med,
                                                            ),
                                                            140,
                                                            14,
                                                          ),
                                                          // Actions
                                                          SizedBox(
                                                            width: 140,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                _ActionButton(
                                                                  icon: Icons
                                                                      .remove_red_eye_outlined,
                                                                  tooltip:
                                                                      'View Details',
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      _selectedMedicineForDetails =
                                                                          med;
                                                                    });
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                _ActionButton(
                                                                  icon: Icons
                                                                      .edit_outlined,
                                                                  tooltip:
                                                                      'Edit Medicine',
                                                                  onPressed: () =>
                                                                      _showEditMedicineDialog(
                                                                        med,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                _ActionButton(
                                                                  icon: Icons
                                                                      .delete_outline_rounded,
                                                                  tooltip:
                                                                      'Delete Medicine',
                                                                  iconColor:
                                                                      const Color(
                                                                        0xFFEF4444,
                                                                      ),
                                                                  onPressed: () =>
                                                                      _confirmDeleteMedicine(
                                                                        med,
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
                                              },
                                            ),
                                      // Pagination Footer
                                      if (medicines.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.vertical(
                                              bottom: Radius.circular(16),
                                            ),
                                            border: Border(
                                              top: BorderSide(
                                                color: Color(0xFFE2E8F0),
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Showing ${startIndex + 1} to ${endIndex > totalItems ? totalItems : endIndex} of $totalItems entries',
                                                style: const TextStyle(
                                                  color: softGrey,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: safePage > 1
                                                        ? () => setState(
                                                            () => _currentPage =
                                                                safePage - 1,
                                                          )
                                                        : null,
                                                    style: OutlinedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      side: const BorderSide(
                                                        color: Color(
                                                          0xFFE2E8F0,
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Previous',
                                                      style: TextStyle(
                                                        color: textDark,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF1F5F9,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$safePage / $totalPages',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textDark,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  OutlinedButton(
                                                    onPressed:
                                                        safePage < totalPages
                                                        ? () => setState(
                                                            () => _currentPage =
                                                                safePage + 1,
                                                          )
                                                        : null,
                                                    style: OutlinedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      side: const BorderSide(
                                                        color: Color(
                                                          0xFFE2E8F0,
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Next',
                                                      style: TextStyle(
                                                        color: textDark,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );

                                if (useScroll) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: minTableWidth,
                                      child: tableContent,
                                    ),
                                  );
                                } else {
                                  return tableContent;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedMed != null) _buildDetailsPanel(selectedMed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBatchDialog(Medicine medicine) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddBatchDialog(medicine: medicine),
    ).then((success) {
      if (success == true) {
        // Handled inside
      }
    });
  }

  Widget _buildDetailsPanel(Medicine med) {
    const primaryTeal = Color(0xFF0F766E);
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.33).clamp(450.0, 600.0);

    return Container(
      width: drawerWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: borderGrey, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderGrey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MEDICINE DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: softGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: softGrey),
                  onPressed: () {
                    setState(() {
                      _selectedMedicineForDetails = null;
                    });
                  },
                ),
              ],
            ),
          ),

          // Drawer Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Medicine Info
                  _buildSectionHeader('Basic Info'),
                  _buildDetailRow('Generic Name', med.genericName ?? '—'),
                  _buildDetailRow(
                    'Category',
                    med.category?.name ?? 'Uncategorized',
                  ),
                  _buildDetailRow(
                    'Reorder Level',
                    med.reorderLevel?.toString() ?? '10',
                  ),
                  _buildDetailRow(
                    'Prescription Req.',
                    (med.prescriptionRequired ?? false) ? 'Yes (Rx)' : 'No',
                    valueColor: (med.prescriptionRequired ?? false)
                        ? const Color(0xFFEF4444)
                        : textDark,
                  ),
                  const Divider(height: 32),

                  // Section 2: Batch Details
                  _buildSectionHeader('Batch & Stock Details'),
                  if (med.inventoryBatches != null &&
                      med.inventoryBatches!.isNotEmpty) ...[
                    ...med.inventoryBatches!.map((batch) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batch: ${batch.batchNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Expiry: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: softGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                _buildExpiryBadge(batch.expiryDate),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Stock: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: softGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${batch.availableQuantity}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: batch.availableQuantity == 0
                                            ? Colors.red
                                            : textDark,
                                      ),
                                    ),
                                    Text(
                                      ' / ${batch.quantity}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: softGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'MRP: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: softGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '₹${(double.tryParse(batch.mrp?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    // Fallback to single batch info on Medicine
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderGrey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batch: ${med.batchNumber ?? '—'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'Expiry: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: softGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _buildExpiryBadge(med.expiryDate),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Stock: ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: softGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${med.stock}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: med.stock == 0
                                          ? Colors.red
                                          : textDark,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'MRP: ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: softGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '₹${med.mrp.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 32),

                  // Section 3: Supplier Info
                  _buildSectionHeader('Supplier Information'),
                  _buildDetailRow(
                    'Supplier',
                    (med.supplier != null && med.supplier!.isNotEmpty)
                        ? med.supplier!
                        : 'No supplier information available',
                    valueColor:
                        (med.supplier != null && med.supplier!.isNotEmpty)
                        ? textDark
                        : softGrey,
                  ),
                  if (med.manufacturer != null) ...[
                    _buildDetailRow('Manufacturer', med.manufacturer!.name),
                    _buildDetailRow(
                      'Contact Phone',
                      (med.manufacturer!.phone != null &&
                              med.manufacturer!.phone!.isNotEmpty)
                          ? med.manufacturer!.phone!
                          : 'No phone available',
                      valueColor:
                          (med.manufacturer!.phone != null &&
                              med.manufacturer!.phone!.isNotEmpty)
                          ? textDark
                          : softGrey,
                    ),
                  ] else ...[
                    _buildDetailRow(
                      'Manufacturer',
                      'No manufacturer information available',
                      valueColor: softGrey,
                    ),
                    _buildDetailRow(
                      'Contact Phone',
                      'No phone available',
                      valueColor: softGrey,
                    ),
                  ],
                  const Divider(height: 32),

                  // Section 4: Inventory Metrics
                  _buildSectionHeader('Inventory Metrics'),
                  _buildDetailRow('HSN Code', med.hsnCode ?? '—'),
                  _buildDetailRow('Barcode', med.barcode ?? '—'),
                  _buildDetailRow(
                    'GST Rate',
                    med.gstPercentage != null ? '${med.gstPercentage}%' : '12%',
                  ),
                  _buildDetailRow(
                    'Added On',
                    med.createdAt.isNotEmpty
                        ? _formatTimestamp(med.createdAt)
                        : '—',
                  ),
                  _buildDetailRow(
                    'Last Updated',
                    med.updatedAt.isNotEmpty
                        ? _formatTimestamp(med.updatedAt)
                        : '—',
                  ),
                ],
              ),
            ),
          ),

          // Drawer Footer Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: borderGrey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditMedicineDialog(med),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: borderGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showAddBatchDialog(med),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Adjust Stock',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildExpiryBadge(String? expiryString) {
    if (expiryString == null || expiryString.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'No Expiry',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    try {
      final expiry = DateTime.parse(expiryString);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;

      final Color bgColor;
      final Color textColor;
      if (difference <= 0) {
        // Expired (🔴)
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
      } else if (difference < 180) {
        // Near expiry < 6 months (🟡)
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
      } else if (difference < 365) {
        // Mild warning < 12 months (🟠)
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFEA580C);
      } else {
        // Safe > 12 months (🟢)
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatExpiryDate(expiryString),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      );
    } catch (_) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatExpiryDate(expiryString),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F766E),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF0F172A),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
    } catch (_) {
      return timestamp;
    }
  }

  String _formatLargeCurrency(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)}L';
    } else {
      return '₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2).format(value).trim()}';
    }
  }

  Widget _buildStatusBadge(Medicine med) {
    String text = 'IN STOCK';
    Color color = const Color(0xFF10B981);

    if (med.stock == 0) {
      text = 'OUT OF STOCK';
      color = const Color(0xFFEF4444);
    } else if (_isDateExpired(med.expiryDate)) {
      text = 'EXPIRED';
      color = const Color(0xFFEF4444);
    } else if (med.stock <= (med.reorderLevel ?? 10)) {
      text = 'LOW STOCK';
      color = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20), // Pill shape for modern look
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAvatar(String name) {
    String initials = '';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      initials += parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
      if (parts.length > 1) {
        initials += parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
      }
    }
    if (initials.isEmpty) initials = '?';

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF0D9488),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withValues(alpha: 0.02),
        splashColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
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
                        fontSize: 12,
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
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No medicines found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(inventoryNotifierProvider.notifier).loadInventory(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _TableHeaderText(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          hoverColor: iconColor != null
              ? iconColor!.withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(
                color: iconColor != null
                    ? iconColor!.withValues(alpha: 0.2)
                    : const Color(0xFFE2E8F0),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor ?? const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
