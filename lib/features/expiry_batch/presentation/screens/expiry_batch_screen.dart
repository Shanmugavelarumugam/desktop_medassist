import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../notifier/expiry_batch_notifier.dart';

class ExpiryBatchScreen extends ConsumerStatefulWidget {
  const ExpiryBatchScreen({super.key});

  @override
  ConsumerState<ExpiryBatchScreen> createState() => _ExpiryBatchScreenState();
}

class _ExpiryBatchScreenState extends ConsumerState<ExpiryBatchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchController = TextEditingController();
  final _kpiScrollController = ScrollController();
  int? _hoveredRowIndex;
  int _currentPage = 1;
  static const int _pageSize = 15;
  String _daysSubFilter = 'All Soon';
  DateTime _lastUpdated = DateTime.now();

  // ─── Colours ────────────────────────────────────────────────────────────────
  static const _teal = Color(0xFF0D9488);
  static const _textDark = Color(0xFF0F172A);
  static const _softGrey = Color(0xFF64748B);
  static const _borderGrey = Color(0xFFE2E8F0);
  static const _bgGrey = Color(0xFFF4F7FA);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref
          .read(expiryBatchNotifierProvider.notifier)
          .setSearchQuery(_searchController.text);
      if (_currentPage != 1) setState(() => _currentPage = 1);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kpiScrollController.dispose();
    super.dispose();
  }

  Widget _buildSubFilterChip(String label) {
    final isSelected = _daysSubFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _daysSubFilter = label;
          _currentPage = 1;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _teal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _teal : _borderGrey, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? _teal : _softGrey,
          ),
        ),
      ),
    );
  }

  // ─── Confirm Dialog ──────────────────────────────────────────────────────────
  void _showActionConfirmDialog({
    required String title,
    required String content,
    required Color actionColor,
    required IconData actionIcon,
    required String actionLabel,
    required Future<bool> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(actionIcon, color: actionColor, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _textDark,
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(color: _softGrey, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _softGrey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await onConfirm();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Action completed successfully.'
                        : 'Action failed. Please try again.',
                  ),
                  backgroundColor: success ? _teal : const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(expiryBatchNotifierProvider);
    final medicines = ref.watch(inventoryNotifierProvider).medicines;
    final medMap = {for (final m in medicines) m.id: m};
    final now = DateTime.now();

    // ── Metrics & Risk Values ────────────────────────────────────────────────
    int totalBatches = state.batches.length;
    int expiredCount = 0;
    int nearExpiryCount = 0;
    int quarantinedCount = 0;
    double expiredValue = 0.0;
    double nearExpiryValue = 0.0;

    for (final b in state.batches) {
      final isQ = b.status == 'QUARANTINED' || b.status == 'quarantined';
      if (isQ) {
        quarantinedCount++;
        continue;
      }
      final mrp = double.tryParse(b.mrp) ?? 0.0;
      final qty = b.availableQuantity;
      try {
        final expiry = DateTime.parse(b.expiryDate);
        if (expiry.isBefore(now)) {
          expiredCount++;
          expiredValue += (qty * mrp);
        } else if (expiry.difference(now).inDays <= 90) {
          nearExpiryCount++;
          nearExpiryValue += (qty * mrp);
        }
      } catch (_) {}
    }

    // ── Filter ───────────────────────────────────────────────────────────────
    final filtered = state.batches.where((b) {
      final med = medMap[b.medicineId];
      final backendMedName = (b.medicineName ?? b.medicine?['name'] as String?)
          ?.toLowerCase();
      final backendGenName = (b.medicine?['genericName'] as String?)
          ?.toLowerCase();

      final medName = backendMedName ?? med?.name.toLowerCase() ?? '';
      final genName = backendGenName ?? med?.genericName?.toLowerCase() ?? '';
      final batchNo = b.batchNumber.toLowerCase();
      final query = state.searchQuery.toLowerCase();

      if (query.isNotEmpty &&
          !medName.contains(query) &&
          !genName.contains(query) &&
          !batchNo.contains(query)) {
        return false;
      }

      final isQ = b.status == 'QUARANTINED' || b.status == 'quarantined';
      final isR = b.status == 'RECALLED' || b.status == 'recalled';
      bool isExp = false;
      bool isNear = false;
      int daysLeft = 0;
      try {
        final exp = DateTime.parse(b.expiryDate);
        isExp = exp.isBefore(now);
        if (!isExp) {
          daysLeft = exp.difference(now).inDays;
          isNear = daysLeft <= 90;
        }
      } catch (_) {}

      switch (state.filterStatus) {
        case 'Expired':
          return isExp && !isQ && !isR;
        case 'Near Expiry':
          if (!isNear || isQ || isR) return false;
          if (_daysSubFilter == '< 30 Days') return daysLeft <= 30;
          if (_daysSubFilter == '30–60 Days') {
            return daysLeft > 30 && daysLeft <= 60;
          }
          if (_daysSubFilter == '60–90 Days') {
            return daysLeft > 60 && daysLeft <= 90;
          }
          return true; // 'All Soon'
        case 'Quarantined':
          return isQ;
        case 'Recalled':
          return isR;
        case 'Active':
          return !isExp && !isNear && !isQ && !isR;
        default:
          return true;
      }
    }).toList();

    // ── Pagination ────────────────────────────────────────────────────────────
    final totalItems = filtered.length;
    final totalPages = totalItems > 0 ? (totalItems / _pageSize).ceil() : 1;
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pageItems = filtered.sublist(startIndex, endIndex);

    final String lastUpdatedStr = DateFormat('hh:mm a').format(_lastUpdated);

    return Container(
      color: _bgGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Gradient Header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFF8FAFC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(bottom: BorderSide(color: _borderGrey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Expiry & Batch Control',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Monitor shelf-life, manage recalls and quarantine batch inventory.',
                      style: TextStyle(
                        color: _softGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Last sync: $lastUpdatedStr  ',
                      style: const TextStyle(
                        color: _softGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _lastUpdated = DateTime.now();
                        });
                        ref
                            .read(expiryBatchNotifierProvider.notifier)
                            .loadBatches();
                      },
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text(
                        'Sync Inventory',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: _teal.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. Scrollable body ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Stat Cards Horizontal Ribbon ───────────────────────────
                  Scrollbar(
                    controller: _kpiScrollController,
                    thumbVisibility: false,
                    trackVisibility: false,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          ...ScrollConfiguration.of(context).dragDevices,
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
                                'Total Batches',
                                totalBatches.toString(),
                                Icons.layers_outlined,
                                const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 230,
                              height: 140,
                              child: _buildStatCard(
                                'Expired',
                                expiredCount.toString(),
                                Icons.error_outline_rounded,
                                const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 230,
                              height: 140,
                              child: _buildStatCard(
                                'Expiring Soon',
                                nearExpiryCount.toString(),
                                Icons.warning_amber_rounded,
                                const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 230,
                              height: 140,
                              child: _buildStatCard(
                                'Quarantined',
                                quarantinedCount.toString(),
                                Icons.health_and_safety_outlined,
                                const Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 230,
                              height: 140,
                              child: _buildStatCard(
                                'Expired Value',
                                '₹${expiredValue.toStringAsFixed(0)}',
                                Icons.money_off_rounded,
                                const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 230,
                              height: 140,
                              child: _buildStatCard(
                                'At Risk (Soon)',
                                '₹${nearExpiryValue.toStringAsFixed(0)}',
                                Icons.monetization_on_outlined,
                                const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Control Bar (Search + Filter tabs) ─────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Search Field
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textDark,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search by medicine name or batch number...',
                              hintStyle: TextStyle(
                                color: _softGrey.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: _softGrey.withValues(alpha: 0.7),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 30, color: _borderGrey),
                        const SizedBox(width: 12),
                        // Segmented Filter
                        _FilterTabs(
                          selected: state.filterStatus,
                          onChanged: (s) {
                            ref
                                .read(expiryBatchNotifierProvider.notifier)
                                .setFilterStatus(s);
                            setState(() => _currentPage = 1);
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),

                  // Secondary Quick Filters chips for Near Expiry
                  if (state.filterStatus == 'Near Expiry') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSubFilterChip('All Soon'),
                        const SizedBox(width: 8),
                        _buildSubFilterChip('< 30 Days'),
                        const SizedBox(width: 8),
                        _buildSubFilterChip('30–60 Days'),
                        const SizedBox(width: 8),
                        _buildSubFilterChip('60–90 Days'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Table Container ────────────────────────────────────────
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
                      border: Border.all(color: _borderGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            border: Border(
                              bottom: BorderSide(color: _borderGrey),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: _HeaderText('MEDICINE')),
                              Expanded(
                                flex: 2,
                                child: _HeaderText('BATCH NUMBER'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _HeaderText('EXPIRY DATE'),
                              ),
                              Expanded(flex: 1, child: _HeaderText('QTY')),
                              Expanded(flex: 2, child: _HeaderText('MRP')),
                              Expanded(flex: 2, child: _HeaderText('STATUS')),
                              SizedBox(
                                width: 80,
                                child: _HeaderText('ACTION', alignRight: true),
                              ),
                            ],
                          ),
                        ),

                        // Table Body
                        state.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(60),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(_teal),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : filtered.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pageItems.length,
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                itemBuilder: (context, index) {
                                  final batch = pageItems[index];
                                  final med = medMap[batch.medicineId];

                                  // ── Status logic ──────────────────────
                                  final isQ =
                                      batch.status == 'QUARANTINED' ||
                                      batch.status == 'quarantined';
                                  final isR =
                                      batch.status == 'RECALLED' ||
                                      batch.status == 'recalled';
                                  bool isExp = false;
                                  bool isNear = false;
                                  int daysLeft = 0;
                                  try {
                                    final expiry = DateTime.parse(
                                      batch.expiryDate,
                                    );
                                    isExp = expiry.isBefore(now);
                                    if (!isExp) {
                                      daysLeft = expiry.difference(now).inDays;
                                      isNear = daysLeft <= 90;
                                    }
                                  } catch (_) {}

                                  String statusLabel;
                                  Color statusColor;
                                  IconData statusIcon;
                                  if (isQ) {
                                    statusLabel = 'Quarantined';
                                    statusColor = const Color(0xFF6366F1);
                                    statusIcon =
                                        Icons.health_and_safety_outlined;
                                  } else if (isR) {
                                    statusLabel = 'Recalled';
                                    statusColor = const Color(0xFFEF4444);
                                    statusIcon =
                                        Icons.assignment_return_outlined;
                                  } else if (isExp) {
                                    statusLabel = 'Expired';
                                    statusColor = const Color(0xFFEF4444);
                                    statusIcon = Icons.error_outline_rounded;
                                  } else if (isNear) {
                                    statusLabel = 'Expiring Soon';
                                    statusColor = const Color(0xFFF59E0B);
                                    statusIcon = Icons.warning_amber_rounded;
                                  } else {
                                    statusLabel = 'Active';
                                    statusColor = const Color(0xFF10B981);
                                    statusIcon =
                                        Icons.check_circle_outline_rounded;
                                  }

                                  // Expiry string
                                  String formattedExpiry = batch.expiryDate;
                                  try {
                                    formattedExpiry = DateFormat(
                                      'MMM yyyy',
                                    ).format(DateTime.parse(batch.expiryDate));
                                  } catch (_) {}

                                  // Severity Background color calculations
                                  final Color rowColor;
                                  if (_hoveredRowIndex == index) {
                                    rowColor = const Color(0xFFF0FDFA);
                                  } else if (isExp || isR) {
                                    rowColor = const Color(
                                      0xFFFEF2F2,
                                    ); // Red tint for Expired/Recalled
                                  } else if (isNear && daysLeft <= 30) {
                                    rowColor = const Color(
                                      0xFFFFF7ED,
                                    ); // Orange tint for Expires < 30 days
                                  } else if (isNear && daysLeft <= 90) {
                                    rowColor = const Color(
                                      0xFFFEFCE8,
                                    ); // Yellow tint for Expires < 90 days
                                  } else {
                                    rowColor = Colors.white;
                                  }

                                  return MouseRegion(
                                    onEnter: (_) => setState(
                                      () => _hoveredRowIndex = index,
                                    ),
                                    onExit: (_) =>
                                        setState(() => _hoveredRowIndex = null),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      color: rowColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 10,
                                      ), // Denser vertical padding
                                      child: Row(
                                        children: [
                                          // Medicine
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  batch.medicineName ??
                                                      (batch.medicine?['name']
                                                          as String?) ??
                                                      med?.name ??
                                                      'Unknown Medicine',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: _textDark,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  (batch.medicine?['genericName']
                                                          as String?) ??
                                                      med?.genericName ??
                                                      '—',
                                                  style: TextStyle(
                                                    color: _softGrey.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Batch Number
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                batch.batchNumber,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF334155),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Expiry Date
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.event_outlined,
                                                  size: 13,
                                                  color: isExp
                                                      ? const Color(0xFFEF4444)
                                                      : isNear
                                                      ? const Color(0xFFF59E0B)
                                                      : _softGrey,
                                                ),
                                                const SizedBox(width: 5),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      formattedExpiry,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isExp
                                                            ? const Color(
                                                                0xFFEF4444,
                                                              )
                                                            : isNear
                                                            ? const Color(
                                                                0xFFF59E0B,
                                                              )
                                                            : _textDark,
                                                      ),
                                                    ),
                                                    if (!isExp && isNear)
                                                      Text(
                                                        '$daysLeft days left',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: daysLeft <= 30
                                                              ? const Color(
                                                                  0xFFEA580C,
                                                                )
                                                              : const Color(
                                                                  0xFFD97706,
                                                                ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    if (isExp)
                                                      const Text(
                                                        'Already expired',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Color(
                                                            0xFFEF4444,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Qty
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              batch.availableQuantity
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    batch.availableQuantity == 0
                                                    ? const Color(0xFFEF4444)
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),

                                          // MRP
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '₹${double.tryParse(batch.mrp)?.toStringAsFixed(2) ?? batch.mrp}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _textDark,
                                              ),
                                            ),
                                          ),

                                          // Status Badge
                                          Expanded(
                                            flex: 2,
                                            child: _StatusBadge(
                                              label: statusLabel,
                                              color: statusColor,
                                              icon: statusIcon,
                                            ),
                                          ),

                                          // Action Menu
                                          SizedBox(
                                            width: 80,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Tooltip(
                                                message: 'Batch actions',
                                                child: PopupMenuButton<String>(
                                                  offset: const Offset(0, 36),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    side: const BorderSide(
                                                      color: _borderGrey,
                                                    ),
                                                  ),
                                                  color: Colors.white,
                                                  tooltip: 'Batch actions',
                                                  icon: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _hoveredRowIndex ==
                                                              index
                                                          ? const Color(
                                                              0xFFE2E8F0,
                                                            )
                                                          : const Color(
                                                              0xFFF1F5F9,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.more_horiz_rounded,
                                                      color: _softGrey,
                                                      size: 18,
                                                    ),
                                                  ),
                                                  onSelected: (val) {
                                                    if (val == 'quarantine') {
                                                      _showActionConfirmDialog(
                                                        title:
                                                            'Quarantine Batch',
                                                        content:
                                                            'Are you sure you want to quarantine batch "${batch.batchNumber}"? This will freeze it and make it unavailable for billing.',
                                                        actionColor:
                                                            const Color(
                                                              0xFFF59E0B,
                                                            ),
                                                        actionIcon: Icons
                                                            .health_and_safety_outlined,
                                                        actionLabel:
                                                            'Quarantine',
                                                        onConfirm: () => ref
                                                            .read(
                                                              expiryBatchNotifierProvider
                                                                  .notifier,
                                                            )
                                                            .quarantineBatch(
                                                              batch.id,
                                                            ),
                                                      );
                                                    } else if (val ==
                                                        'release') {
                                                      _showActionConfirmDialog(
                                                        title: 'Release Batch',
                                                        content:
                                                            'Release batch "${batch.batchNumber}" so it becomes active for billing again?',
                                                        actionColor: _teal,
                                                        actionIcon: Icons
                                                            .verified_outlined,
                                                        actionLabel: 'Release',
                                                        onConfirm: () => ref
                                                            .read(
                                                              expiryBatchNotifierProvider
                                                                  .notifier,
                                                            )
                                                            .releaseBatch(
                                                              batch.id,
                                                            ),
                                                      );
                                                    } else if (val ==
                                                        'recall') {
                                                      _showActionConfirmDialog(
                                                        title: 'Recall Batch',
                                                        content:
                                                            'Are you sure you want to recall batch "${batch.batchNumber}"? This will alert users to pull stock from shelves.',
                                                        actionColor:
                                                            const Color(
                                                              0xFFEF4444,
                                                            ),
                                                        actionIcon: Icons
                                                            .assignment_return_outlined,
                                                        actionLabel: 'Recall',
                                                        onConfirm: () => ref
                                                            .read(
                                                              expiryBatchNotifierProvider
                                                                  .notifier,
                                                            )
                                                            .recallBatch(
                                                              batch.id,
                                                            ),
                                                      );
                                                    }
                                                  },
                                                  itemBuilder: (_) => [
                                                    if (!isQ)
                                                      _menuItem(
                                                        'quarantine',
                                                        Icons
                                                            .health_and_safety_outlined,
                                                        'Quarantine Batch',
                                                        const Color(0xFFF59E0B),
                                                      ),
                                                    if (isQ)
                                                      _menuItem(
                                                        'release',
                                                        Icons.verified_outlined,
                                                        'Release Batch',
                                                        _teal,
                                                      ),
                                                    if (!isR)
                                                      _menuItem(
                                                        'recall',
                                                        Icons
                                                            .assignment_return_outlined,
                                                        'Recall Batch',
                                                        const Color(0xFFEF4444),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Pagination Footer
                        if (!state.isLoading && filtered.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                              border: Border(
                                top: BorderSide(color: _borderGrey),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${startIndex + 1}–$endIndex of $totalItems batches',
                                  style: const TextStyle(
                                    color: _softGrey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: safePage > 1
                                          ? () => setState(
                                              () => _currentPage = safePage - 1,
                                            )
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        side: const BorderSide(
                                          color: _borderGrey,
                                        ),
                                      ),
                                      child: const Text(
                                        'Previous',
                                        style: TextStyle(color: _textDark),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$safePage / $totalPages',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      onPressed: safePage < totalPages
                                          ? () => setState(
                                              () => _currentPage = safePage + 1,
                                            )
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        side: const BorderSide(
                                          color: _borderGrey,
                                        ),
                                      ),
                                      child: const Text(
                                        'Next',
                                        style: TextStyle(color: _textDark),
                                      ),
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

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  PopupMenuItem<String> _menuItem(
    String val,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: val,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: _textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _softGrey,
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
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _textDark,
              letterSpacing: -0.5,
            ),
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
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No batches found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search or filter selection.',
            style: TextStyle(color: _softGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _HeaderText extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _HeaderText(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterTabs({required this.selected, required this.onChanged});

  static const _filters = [
    'All',
    'Active',
    'Near Expiry',
    'Expired',
    'Quarantined',
    'Recalled',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: _filters.map((f) {
          final isSelected = selected == f;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
