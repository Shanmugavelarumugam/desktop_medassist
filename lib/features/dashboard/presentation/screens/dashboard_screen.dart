import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_medassist/app/router/route_paths.dart';
import 'package:desktop_medassist/features/auth/presentation/controller/auth_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _activeRoute = 'Dashboard'; // Track active sidebar route

  @override
  Widget build(BuildContext context) {
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
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: primaryTeal,
                            child: Text(
                              'JD',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Dr. John Doe',
                            style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Workspace Page Area
                Expanded(
                  child: SingleChildScrollView(
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
                                color: primaryTeal.withOpacity(0.12),
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
                                        color: Colors.white.withOpacity(0.9),
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
                                color: Colors.white.withOpacity(0.2),
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
            },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          // Active background teal tint exactly as request screenshot
          color: isActive ? activeColor.withOpacity(0.08) : Colors.transparent,
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
            color: Colors.black.withOpacity(0.01),
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
              color: color.withOpacity(0.08),
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
