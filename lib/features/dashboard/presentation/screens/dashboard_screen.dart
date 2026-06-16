import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:desktop_medassist/app/theme/app_colors.dart';
import 'package:desktop_medassist/app/theme/app_radius.dart';

import 'package:desktop_medassist/app/constants/app_constants.dart';
import 'package:desktop_medassist/app/router/route_paths.dart';
import 'package:desktop_medassist/features/auth/presentation/controller/auth_controller.dart';
import 'package:desktop_medassist/features/inventory/presentation/screens/stock_screen.dart';
import 'package:desktop_medassist/features/billing_pos/presentation/screens/billing_pos_screen.dart';
import 'package:desktop_medassist/features/purchase/presentation/screens/purchases_screen.dart';
import 'package:desktop_medassist/features/purchase/presentation/notifier/purchase_notifier.dart';
import 'package:desktop_medassist/features/import/presentation/screens/import_screen.dart';
import 'package:desktop_medassist/features/sales/presentation/screens/sales_screen.dart';
import 'package:desktop_medassist/features/expiry_batch/presentation/screens/expiry_batch_screen.dart';
import 'package:desktop_medassist/features/expiry_batch/presentation/notifier/expiry_batch_notifier.dart';
import 'package:desktop_medassist/features/barcode/presentation/screens/barcode_screen.dart';
import 'package:desktop_medassist/features/barcode/presentation/notifier/barcode_notifier.dart';
import 'package:desktop_medassist/features/billing_pos/presentation/notifier/billing_notifier.dart';
import 'package:desktop_medassist/features/inventory/presentation/notifier/inventory_notifier.dart';
import 'package:desktop_medassist/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:desktop_medassist/features/profile/presentation/screens/shop_profile_screen.dart';

class ActiveRouteNotifier extends Notifier<String> {
  @override
  String build() => 'Dashboard';

  void changeRoute(String route) {
    state = route;
  }
}

final activeRouteProvider = NotifierProvider<ActiveRouteNotifier, String>(() {
  return ActiveRouteNotifier();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String get _activeRoute => ref.watch(activeRouteProvider);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final billingState = ref.watch(billingNotifierProvider);
    final inventoryState = ref.watch(inventoryNotifierProvider);

    // ── Live Dashboard Stats ────────────────────────────────────────────────────
    // Daily summary is a flat map: {netRevenue, totalInvoices, totalSales, ...}
    final summary = billingState.dailySummary;
    double toDouble(dynamic v) => v == null
        ? 0.0
        : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    final double todayRevenue = toDouble(
      summary['netRevenue'] ?? summary['totalRevenue'] ?? summary['totalSales'],
    );
    final int totalSKU = inventoryState.totalSKU;
    final int expiredCount = inventoryState.expiredCount;

    final user = authState.user;
    final fullName = user?.fullName ?? 'User';
    final String initials;
    if (fullName.trim().isEmpty) {
      initials = 'U';
    } else {
      // ignore: deprecated_member_use
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      } else {
        initials = 'U';
      }
    }

    const primaryTeal = Color(0xFF0D9488); // Viyan MedAssist teal
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const backgroundGrey = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: Row(
        children: [
          // 1. LEFT PREMIUM NAVIGATION SIDEBAR
          Container(
            width: AppConstants.sidebarWidth,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branding Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEDASSIST',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Healthcare ERP',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Navigation Sections
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dashboard (always first, standalone)
                        _buildSidebarItem(
                          label: 'Dashboard',
                          icon: Icons.grid_view_rounded,
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(height: 4),

                        // ── INVENTORY SECTION ──
                        _buildSectionHeader('INVENTORY'),
                        _buildSidebarItem(
                          label: 'Stock',
                          icon: Icons.inventory_2_outlined,
                          activeColor: AppColors.primary,
                        ),
                        _buildSidebarItem(
                          label: 'Purchases',
                          icon: Icons.shopping_cart_outlined,
                          activeColor: AppColors.primary,
                        ),
                        _buildSidebarItem(
                          label: 'Suppliers',
                          icon: Icons.local_shipping_outlined,
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(height: 4),

                        // ── SALES SECTION ──
                        _buildSectionHeader('SALES'),
                        _buildSidebarItem(
                          label: 'Billing / POS',
                          icon: Icons.credit_card_outlined,
                          activeColor: AppColors.primary,
                        ),
                        _buildSidebarItem(
                          label: 'Sales',
                          icon: Icons.trending_up_rounded,
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(height: 4),

                        // ── ANALYTICS SECTION ──
                        _buildSectionHeader('ANALYTICS'),
                        _buildSidebarItem(
                          label: 'Reports',
                          icon: Icons.bar_chart_outlined,
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(height: 4),

                        // ── UTILITIES SECTION ──
                        _buildSectionHeader('UTILITIES'),
                        _buildSidebarItem(
                          label: 'Import',
                          icon: Icons.cloud_upload_outlined,
                          activeColor: AppColors.primary,
                        ),
                        _buildSidebarItem(
                          label: 'Barcode & QR',
                          icon: Icons.qr_code_scanner_outlined,
                          activeColor: AppColors.primary,
                        ),
                        _buildSidebarItem(
                          label: 'Expiry & Batch',
                          icon: Icons.calendar_today_outlined,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Menu
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Column(
                    children: [
                      _buildSidebarItem(
                        label: 'Help Center',
                        icon: Icons.help_outline_rounded,
                        activeColor: AppColors.primary,
                        isStatic: true,
                        onTap: () {},
                      ),
                      _buildSidebarItem(
                        label: 'Log Out',
                        icon: Icons.logout_rounded,
                        activeColor: AppColors.error,
                        isStatic: true,
                        onTap: () async {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) {
                            context.go(RoutePaths.login);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. RIGHT WORKSPACE CONTENT AREA (Responsive Desktop Dashboard Workspace)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Container(
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: borderGrey, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _activeRoute,
                        style: const TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: softGrey,
                            ),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          Container(width: 1, height: 24, color: borderGrey),
                          const SizedBox(width: 16),
                          PopupMenuButton<String>(
                            offset: const Offset(0, 45),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: borderGrey,
                                width: 1,
                              ),
                            ),
                            color: Colors.white,
                            tooltip: 'User Profile',
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .logout();
                                if (context.mounted) {
                                  context.go(RoutePaths.login);
                                }
                              } else if (value == 'profile') {
                                ref
                                    .read(activeRouteProvider.notifier)
                                    .changeRoute('Profile Settings');
                              } else if (value == 'shop') {
                                ref
                                    .read(activeRouteProvider.notifier)
                                    .changeRoute('Shop Profile');
                              }
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primaryTeal,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: softGrey,
                                  size: 18,
                                ),
                              ],
                            ),
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: primaryTeal
                                                .withValues(alpha: 0.1),
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                color: primaryTeal,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  fullName,
                                                  style: const TextStyle(
                                                    color: textDark,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  user?.email ?? '',
                                                  style: const TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryTeal.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          (user?.role ?? 'USER').toUpperCase(),
                                          style: const TextStyle(
                                            color: primaryTeal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF64748B),
                                      size: 18,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Profile Settings',
                                      style: TextStyle(
                                        color: textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'shop',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.storefront_outlined,
                                      color: Color(0xFF64748B),
                                      size: 18,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Shop Profile',
                                      style: TextStyle(
                                        color: textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Log Out',
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildActiveScreen(
                    _activeRoute,
                    primaryTeal,
                    textDark,
                    borderGrey,
                    backgroundGrey,
                    initials,
                    fullName,
                    billingState,
                    inventoryState,
                    todayRevenue,
                    totalSKU,
                    expiredCount,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveScreen(
    String activeRoute,
    Color primaryTeal,
    Color textDark,
    Color borderGrey,
    Color backgroundGrey,
    String initials,
    String fullName,
    dynamic billingState,
    dynamic inventoryState,
    double todayRevenue,
    int totalSKU,
    int expiredCount,
  ) {
    switch (activeRoute) {
      case 'Stock':
        return const StockScreen();
      case 'Billing / POS':
        return const BillingPosScreen();
      case 'Purchases':
      case 'Suppliers':
        return const PurchasesScreen();
      case 'Import':
        return const ImportScreen();
      case 'Sales':
        return const SalesScreen();
      case 'Expiry & Batch':
        return const ExpiryBatchScreen();
      case 'Barcode & QR':
        return const BarcodeScreen();
      case 'Profile Settings':
        return const ProfileSettingsScreen();
      case 'Shop Profile':
        return const ShopProfileScreen();
      default:
        return _buildDashboardHome(
          primaryTeal,
          textDark,
          borderGrey,
          backgroundGrey,
          initials,
          fullName,
          billingState,
          inventoryState,
          todayRevenue,
          totalSKU,
          expiredCount,
        );
    }
  }

  Widget _buildDashboardHome(
    Color primaryTeal,
    Color textDark,
    Color borderGrey,
    Color backgroundGrey,
    String initials,
    String fullName,
    dynamic billingState,
    dynamic inventoryState,
    double todayRevenue,
    int totalSKU,
    int expiredCount,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Content welcome card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryTeal, Color(0xFF0F766E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back to MedAssist Control!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All features are active. You have 8 patients and $expiredCount expiry alerts awaiting your clinical confirmation today.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Stats Summary Row
          Row(
            children: [
              Expanded(
                child: HoverSummaryCard(
                  title: 'Total Stock SKUs',
                  value: totalSKU > 0 ? totalSKU.toString() : '—',
                  icon: Icons.inventory_2_outlined,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: HoverSummaryCard(
                  title: "Today's Net Revenue",
                  value: billingState.isLoading
                      ? '…'
                      : '₹${NumberFormat('#,##,##0.00').format(todayRevenue)}',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: HoverSummaryCard(
                  title: 'Expired Batches',
                  value: expiredCount > 0 ? '$expiredCount Alerted' : 'None',
                  icon: Icons.warning_amber_rounded,
                  color: expiredCount > 0
                      ? Colors.amber
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Charts & Recent Activity Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Line Chart
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Redundant Trend',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Revenue trends over the last 7 days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryTeal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Weekly View',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: LineChartPainter(() {
                            final invoices = billingState.invoices;
                            final Map<int, double> dayRevenueMap = {};
                            final now = DateTime.now();

                            for (int i = 0; i < 7; i++) {
                              final targetDate = now.subtract(
                                Duration(days: 6 - i),
                              );
                              dayRevenueMap[targetDate.day] = 0.0;
                            }

                            for (final invoice in invoices) {
                              try {
                                final date = DateTime.parse(
                                  invoice.date,
                                ).toLocal();
                                final difference = now.difference(date).inDays;
                                if (difference >= 0 && difference < 7) {
                                  dayRevenueMap[date.day] =
                                      (dayRevenueMap[date.day] ?? 0.0) +
                                      invoice.total;
                                }
                              } catch (_) {}
                            }

                            return List<double>.generate(7, (i) {
                              final targetDate = now.subtract(
                                Duration(days: 6 - i),
                              );
                              return dayRevenueMap[targetDate.day] ?? 0.0;
                            });
                          }()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final targetDate = DateTime.now().subtract(
                            Duration(days: 6 - i),
                          );
                          final label = DateFormat('E').format(targetDate);
                          return Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Right Panel: Recent Transactions
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  height: 315,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Recent Sales',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(activeRouteProvider.notifier)
                                  .changeRoute('Sales');
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: primaryTeal,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: billingState.invoices.isEmpty
                            ? const Center(
                                child: Text(
                                  'No sales recorded yet',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: billingState.invoices.take(5).length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      height: 16,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                itemBuilder: (context, index) {
                                  final invoice = billingState.invoices[index];
                                  final formattedDate = () {
                                    try {
                                      return DateFormat('hh:mm a').format(
                                        DateTime.parse(invoice.date).toLocal(),
                                      );
                                    } catch (_) {
                                      return '';
                                    }
                                  }();
                                  final isPaid =
                                      invoice.status.toUpperCase() == 'PAID';
                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isPaid
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFFEF2F2),
                                        child: Icon(
                                          isPaid
                                              ? Icons
                                                    .check_circle_outline_rounded
                                              : Icons.cancel_outlined,
                                          color: isPaid
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              invoice.patientName.isEmpty
                                                  ? 'Walk-in Customer'
                                                  : invoice.patientName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '#${invoice.invoiceNumber} • $formattedDate',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${invoice.total.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required String label,
    required IconData icon,
    required Color activeColor,
    bool isStatic = false,
    VoidCallback? onTap,
  }) {
    final bool isActive = !isStatic && _activeRoute == label;

    return _SidebarItemWidget(
      label: label,
      icon: icon,
      activeColor: activeColor,
      isActive: isActive,
      isStatic: isStatic,
      onTap: isStatic
          ? onTap
          : () {
              ref.read(activeRouteProvider.notifier).changeRoute(label);
              if (label == 'Dashboard') {
                ref.read(billingNotifierProvider.notifier).loadAnalytics(forceRefresh: true);
                ref.read(billingNotifierProvider.notifier).loadInvoices(forceRefresh: true);
              } else if (label == 'Suppliers') {
                ref.read(purchaseNotifierProvider.notifier).setActiveTab(1);
                ref.read(purchaseNotifierProvider.notifier).loadSuppliers();
              } else if (label == 'Purchases') {
                ref.read(purchaseNotifierProvider.notifier).setActiveTab(0);
                ref.read(purchaseNotifierProvider.notifier).loadPurchaseOrders();
              } else if (label == 'Expiry & Batch') {
                ref.read(expiryBatchNotifierProvider.notifier).loadBatches();
              } else if (label == 'Barcode & QR') {
                ref.read(barcodeNotifierProvider.notifier).clearLookup();
                ref.read(barcodeNotifierProvider.notifier).clearGenerated();
              }
            },
    );
  }
}

class HoverSummaryCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const HoverSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  State<HoverSummaryCard> createState() => _HoverSummaryCardState();
}

class _HoverSummaryCardState extends State<HoverSummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _isHovered ? widget.color : Colors.transparent,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;

  LineChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (dataPoints.length - 1);
    final double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final double minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    double getY(double val) {
      final double normalized = (val - minVal) / range;
      return size.height - (normalized * (size.height - 40) + 20);
    }

    path.moveTo(0, getY(dataPoints[0]));
    for (int i = 1; i < dataPoints.length; i++) {
      path.lineTo(i * stepX, getY(dataPoints[i]));
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0D9488).withValues(alpha: 0.20),
          const Color(0xFF0D9488).withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    final pointPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.fill;
    final outerRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dataPoints.length; i++) {
      final cx = i * stepX;
      final cy = getY(dataPoints[i]);
      canvas.drawCircle(Offset(cx, cy), 6.5, outerRingPaint);
      canvas.drawCircle(Offset(cx, cy), 4.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}

class _SidebarItemWidget extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isActive;
  final bool isStatic;
  final VoidCallback? onTap;

  const _SidebarItemWidget({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.isActive,
    this.isStatic = false,
    this.onTap,
  });

  @override
  State<_SidebarItemWidget> createState() => _SidebarItemWidgetState();
}

class _SidebarItemWidgetState extends State<_SidebarItemWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.activeColor.withValues(alpha: 0.1)
                : _hovered ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: widget.isActive
                ? Border.all(color: widget.activeColor.withValues(alpha: 0.15))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isActive
                    ? widget.activeColor
                    : _hovered ? AppColors.textSecondary : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isActive
                        ? AppColors.textPrimary
                        : _hovered ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const softGrey = Color(0xFF94A3B8);
