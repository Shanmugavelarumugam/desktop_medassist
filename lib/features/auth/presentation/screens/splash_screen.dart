import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_medassist/app/router/route_paths.dart';
import 'package:desktop_medassist/features/auth/presentation/controller/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> _loadingMessages = [
    'Initializing pharmacy system...',
    'Connecting pharmacy database...',
    'Loading inventory • Billing • Reports',
    'Preparing billing engine...',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Rotate loading messages
    _messageTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted) {
        setState(() {
          if (_currentMessageIndex < _loadingMessages.length - 1) {
            _currentMessageIndex++;
          }
        });
      }
    });

    // Trigger auto-login initialization in the background
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).initialize();
    });

    // Navigate to correct Screen after a delay based on authentication
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        final isAuthenticated = ref
            .read(authControllerProvider)
            .isAuthenticated;
        if (isAuthenticated) {
          context.go(RoutePaths.dashboard);
        } else {
          context.go(RoutePaths.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // The primary teal used in the app
    const primaryTeal = Color(0xFF0D9488);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF7FAFC), const Color(0xFFEEF2F7)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Modern Logo Frame
                          Container(
                            padding: const EdgeInsets.all(
                              12,
                            ), // Even smaller padding
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryTeal.withValues(
                                    alpha: isDark ? 0.1 : 0.05,
                                  ), // Softer shadow
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: primaryTeal.withValues(alpha: 0.1),
                                width: 1.0, // Subtle border
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/logo/image.png',
                                width: 85, // 15% smaller
                                height: 85,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.medical_services_rounded,
                                    size: 60,
                                    color: primaryTeal,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Premium Typography
                          Text(
                            'VIYAN MEDASSIST',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pharmacy Billing & Inventory System',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 60),

                          // Dynamic Loading Messages
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _loadingMessages[_currentMessageIndex],
                              key: ValueKey<int>(_currentMessageIndex),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Sleek Linear Progress
                          SizedBox(
                            width: 260,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const LinearProgressIndicator(
                                backgroundColor: Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryTeal,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom copyright/branding
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Version 1.0.0 • © 2026 Viyan MedAssist',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
