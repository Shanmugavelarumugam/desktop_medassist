import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_medassist/app/router/route_paths.dart';
import 'package:desktop_medassist/features/auth/presentation/controller/auth_controller.dart';
import 'package:desktop_medassist/features/inventory/presentation/screens/stock_screen.dart';
import 'package:desktop_medassist/features/billing_pos/presentation/screens/billing_pos_screen.dart';
import 'package:desktop_medassist/features/purchase/presentation/screens/purchases_screen.dart';
import 'package:desktop_medassist/features/purchase/presentation/notifier/purchase_notifier.dart';
import 'package:desktop_medassist/features/import/presentation/screens/import_screen.dart';
import 'package:desktop_medassist/features/sales/presentation/screens/sales_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _activeRoute = 'Dashboard'; // Track active sidebar route

  @override
  Widget build(BuildContext context) {
    ref.listen(purchaseNotifierProvider, (previous, next) {
      if ((_activeRoute == 'Purchases' || _activeRoute == 'Suppliers') && previous?.activeTab != next.activeTab) {
        setState(() {
          _activeRoute = next.activeTab == 1 ? 'Suppliers' : 'Purchases';
        });
      }
    });

    final authState = ref.watch(authControllerProvider);
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
          // 1. LEFT PREMIUM NAVIGATION SIDEBAR (Exactly as requested in screenshot)
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: borderGrey, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branding Header (Logo + Name)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logo/image.png',
                        width: 200,
                        height: 70,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (context, error, stackTrace) => const Row(
                          children: [
                            Icon(
                              Icons.medical_services_rounded,
                              size: 44,
                              color: primaryTeal,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'MEDASSIST',
                              style: TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation Items List
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSidebarItem(
                          label: 'Dashboard',
                          icon: Icons.grid_view_rounded,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Stock',
                          icon: Icons.inventory_2_outlined,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Billing / POS',
                          icon: Icons.credit_card_outlined,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Purchases',
                          icon: Icons.shopping_cart_outlined,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Suppliers',
                          icon: Icons.local_shipping_outlined,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Import',
                          icon: Icons.cloud_upload_outlined,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Sales',
                          icon: Icons.trending_up_rounded,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Reports',
                          icon: Icons.bar_chart_outlined,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Expiry & Batch',
                          icon: Icons.calendar_today_outlined,
                          activeColor: primaryTeal,
                        ),
                        _buildSidebarItem(
                          label: 'Barcode & QR',
                          icon: Icons.qr_code_scanner_outlined,
                          activeColor: primaryTeal,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Menu (Help & Log Out)
                const Divider(height: 1, color: borderGrey),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      _buildSidebarItem(
                        label: 'Help Center',
                        icon: Icons.help_outline_rounded,
                        activeColor: primaryTeal,
                        isStatic: true,
                        onTap: () {},
                      ),
                      _buildSidebarItem(
                        label: 'Log Out',
                        icon: Icons.logout_rounded,
                        activeColor: primaryTeal,
                        isStatic: true,
                        onTap: () async {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) {
                            context.go(RoutePaths.login);
                          }
                        },
                      ),
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
                            icon: const Icon(Icons.notifications_none_rounded, color: softGrey),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 1,
                            height: 24,
                            color: borderGrey,
                          ),
                          const SizedBox(width: 16),
                          PopupMenuButton<String>(
                            offset: const Offset(0, 45),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: borderGrey, width: 1),
                            ),
                            color: Colors.white,
                            tooltip: 'User Profile',
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await ref.read(authControllerProvider.notifier).logout();
                                if (context.mounted) {
                                  context.go(RoutePaths.login);
                                }
                              } else if (value == 'profile') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile Settings coming soon!')),
                                );
                              } else if (value == 'shop') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Shop Profile coming soon!')),
                                );
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
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: primaryTeal.withValues(alpha: 0.1),
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
                                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primaryTeal.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
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
                                    Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 18),
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
                                    Icon(Icons.storefront_outlined, color: Color(0xFF64748B), size: 18),
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
                                    Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
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

                // Main Workspace Page Area
                Expanded(
                  child: _activeRoute == 'Stock'
                      ? const StockScreen()
                      : _activeRoute == 'Billing / POS'
                          ? const BillingPosScreen()
                          : (_activeRoute == 'Purchases' || _activeRoute == 'Suppliers')
                              ? const PurchasesScreen()
                              : _activeRoute == 'Import'
                                  ? const ImportScreen()
                                  : _activeRoute == 'Sales'
                                      ? const SalesScreen()
                                      : SingleChildScrollView(
                                  padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dynamic Content welcome card
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [primaryTeal, Color(0xFF0F766E)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryTeal.withValues(alpha: 0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
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
                                            'Welcome back to MedAssist clinical control!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'All features are active. You have 8 patients and 4 expiry updates awaiting your clinical confirmation today.',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.health_and_safety_outlined,
                                      size: 70,
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Stats Summary Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Active Stock Items',
                                      value: '2,482',
                                      icon: Icons.inventory_2_outlined,
                                      color: primaryTeal,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Daily Sales',
                                      value: '\$1,540.25',
                                      icon: Icons.trending_up_rounded,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      title: 'Expired Batches',
                                      value: '4 Alerted',
                                      icon: Icons.warning_amber_rounded,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildSidebarItem({
    required String label,
    required IconData icon,
    required Color activeColor,
    bool isStatic = false,
    VoidCallback? onTap,
  }) {
    final bool isActive = !isStatic && _activeRoute == label;

    return InkWell(
      onTap: isStatic
          ? onTap
          : () {
              setState(() {
                _activeRoute = label;
              });
              if (label == 'Suppliers') {
                ref.read(purchaseNotifierProvider.notifier).setActiveTab(1);
              } else if (label == 'Purchases') {
                ref.read(purchaseNotifierProvider.notifier).setActiveTab(0);
              }
            },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          // Active background teal tint exactly as request screenshot
          color: isActive ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            // Left vertical active tab indicator
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Icon(
              icon,
              color: isActive ? activeColor : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : const Color(0xFF475569),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

const softGrey = Color(0xFF94A3B8);
