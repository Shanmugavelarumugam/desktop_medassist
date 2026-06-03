import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../notifier/inventory_notifier.dart';
import '../widgets/add_medicine_dialog.dart';
import '../../domain/models/medicine.dart';


class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 15;
  int? _hoveredRowIndex; // Track hovered row for table effect

  @override
  void initState() {
    super.initState();
    // Synchronize search text input with notifier state
    _searchController.addListener(() {
      ref
          .read(inventoryNotifierProvider.notifier)
          .setSearch(_searchController.text);
      if (_currentPage != 1) {
        setState(() {
          _currentPage = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      // Near expiry if within 90 days and not yet expired
      return date.isAfter(now) &&
          date.isBefore(now.add(const Duration(days: 90)));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete ${medicine.name}? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0F766E); // Deep elegant teal
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF4F7FA); // Soft background

    final state = ref.watch(inventoryNotifierProvider);
    final medicines = state.filteredMedicines;

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
    final categoryList = ['All Categories', ...state.categories.map((c) => c.name)];
    const statusList = ['All Status', 'In Stock', 'Low Stock', 'Out of Stock', 'Expired'];

    return Container(
      color: bgGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. DYNAMIC HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, const Color(0xFFF8FAFC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
                      style: TextStyle(color: softGrey, fontSize: 15, fontWeight: FontWeight.w500),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. MODERN STATS CARDS
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total SKU', state.totalSKU.toString(), Icons.layers_outlined, const Color(0xFF3B82F6))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('In Stock', state.inStockCount.toString(), Icons.check_circle_outline, const Color(0xFF10B981))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Low Stock', state.lowStockCount.toString(), Icons.warning_amber_rounded, const Color(0xFFF59E0B))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Out of Stock', state.outOfStockCount.toString(), Icons.cancel_outlined, const Color(0xFFEF4444))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Expired', state.expiredCount.toString(), Icons.calendar_today_outlined, const Color(0xFF9F1239))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Inventory Value',
                          '₹${NumberFormat('#,##,###').format(state.inventoryValue)}',
                          Icons.currency_rupee,
                          primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 3. UNIFIED CONTROL BAR (Search & Filters)
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
                        // Search
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: textDark, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search by name, generic, or batch...',
                              hintStyle: TextStyle(color: softGrey.withValues(alpha: 0.7), fontSize: 15),
                              prefixIcon: Icon(Icons.search_rounded, color: softGrey.withValues(alpha: 0.7)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                        // Category Dropdown
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: state.selectedCategory,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: softGrey),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            ),
                            style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
                            items: categoryList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(inventoryNotifierProvider.notifier).setCategory(val);
                                setState(() => _currentPage = 1);
                              }
                            },
                          ),
                        ),
                        Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                        // Status Dropdown
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: state.selectedStatus,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: softGrey),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            ),
                            style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
                            items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(inventoryNotifierProvider.notifier).setStatus(val);
                                setState(() => _currentPage = 1);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. PREMIUM DATA TABLE
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: Column(
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
                              Expanded(flex: 3, child: _TableHeaderText('MEDICINE')),
                              Expanded(flex: 2, child: _TableHeaderText('CATEGORY')),
                              Expanded(flex: 2, child: _TableHeaderText('BATCH & EXPIRY')),
                              Expanded(flex: 1, child: _TableHeaderText('STOCK')),
                              Expanded(flex: 1, child: _TableHeaderText('MRP')),
                              Expanded(flex: 1, child: _TableHeaderText('STATUS')),
                              SizedBox(width: 120, child: _TableHeaderText('ACTIONS', alignRight: true)),
                            ],
                          ),
                        ),
                        // Table Body
                        state.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(color: primaryTeal),
                              )
                            : state.errorMessage != null
                                ? _buildErrorState(state.errorMessage!)
                                : medicines.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: paginatedMedicines.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                        itemBuilder: (context, index) {
                                          final med = paginatedMedicines[index];
                                          return MouseRegion(
                                            onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                            onExit: (_) => setState(() => _hoveredRowIndex = null),
                                            child: Container(
                                              color: _hoveredRowIndex == index ? const Color(0xFFF8FAFC) : Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                              child: Row(
                                                children: [
                                                  // Medicine Info
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 15)),
                                                        const SizedBox(height: 4),
                                                        Text(med.genericName ?? 'No Generic', style: TextStyle(color: softGrey.withValues(alpha: 0.8), fontSize: 12)),
                                                      ],
                                                    ),
                                                  ),
                                                  // Category
                                                  Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEFF6FF),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          med.category?.name ?? '—',
                                                          style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 12),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Batch & Expiry
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(med.batchNumber ?? '—', style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.event_outlined, size: 12, color: softGrey.withValues(alpha: 0.8)),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              _formatExpiryDate(med.expiryDate),
                                                              style: TextStyle(
                                                                color: _isDateExpired(med.expiryDate)
                                                                    ? const Color(0xFFEF4444)
                                                                    : _isNearExpiry(med.expiryDate)
                                                                        ? const Color(0xFFF59E0B)
                                                                        : softGrey,
                                                                fontSize: 12,
                                                                fontWeight: (_isDateExpired(med.expiryDate) || _isNearExpiry(med.expiryDate)) ? FontWeight.bold : FontWeight.normal,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Stock
                                                  Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      med.stock.toString(),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w800,
                                                        color: med.stock == 0
                                                            ? const Color(0xFFEF4444)
                                                            : med.stock <= (med.reorderLevel ?? 10)
                                                                ? const Color(0xFFF59E0B)
                                                                : const Color(0xFF10B981),
                                                      ),
                                                    ),
                                                  ),
                                                  // MRP
                                                  Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      '₹${med.mrp.toStringAsFixed(2)}',
                                                      style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 14),
                                                    ),
                                                  ),
                                                  // Status
                                                  Expanded(
                                                    flex: 1,
                                                    child: _buildStatusBadge(med),
                                                  ),
                                                  // Actions
                                                  SizedBox(
                                                    width: 120,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [

                                                        _ActionButton(
                                                          icon: Icons.edit_rounded,
                                                          color: const Color(0xFF3B82F6),
                                                          tooltip: 'Edit',
                                                          onPressed: () => _showEditMedicineDialog(med),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        _ActionButton(
                                                          icon: Icons.delete_rounded,
                                                          color: const Color(0xFFEF4444),
                                                          tooltip: 'Delete',
                                                          onPressed: () => _confirmDeleteMedicine(med),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                        
                        // Pagination Footer
                        if (medicines.isNotEmpty)
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
                                Text(
                                  'Showing ${startIndex + 1} to ${endIndex > totalItems ? totalItems : endIndex} of $totalItems entries',
                                  style: const TextStyle(color: softGrey, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: safePage > 1 ? () => setState(() => _currentPage = safePage - 1) : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      child: const Text('Previous', style: TextStyle(color: textDark)),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                        '$safePage / $totalPages',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    OutlinedButton(
                                      onPressed: safePage < totalPages ? () => setState(() => _currentPage = safePage + 1) : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
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
        ],
      ),
    );
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
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
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
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.inventory_2_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          const Text('No medicines found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          const Text('Try adjusting your search or filters.', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ref.read(inventoryNotifierProvider.notifier).loadInventory(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
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
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          hoverColor: color.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
