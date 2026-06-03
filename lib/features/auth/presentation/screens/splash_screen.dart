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

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    // Trigger auto-login initialization in the background
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).initialize();
    });

    // Navigate to correct Screen after a delay based on authentication
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A), // Sleek Dark Slate
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFF8FAFC), // Sleek Soft Grey
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow in background for premium look
            if (isDark)
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.08),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
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
                          // Modern Logo Frame with subtle glow shadow
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF1E293B).withOpacity(0.7)
                                  : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF007AFF).withOpacity(isDark ? 0.15 : 0.08),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFF007AFF).withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/logo/image.png',
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback in case of asset loading issues
                                  return const Icon(
                                    Icons.medical_services_rounded,
                                    size: 100,
                                    color: Color(0xFF007AFF),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Premium Typography
                          Text(
                            'MedAssist',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Smart Healthcare Assistant',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Sleek Linear Progress
                          SizedBox(
                            width: 160,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                                minHeight: 3,
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
                  '© 2026 MedAssist. All rights reserved.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                    fontSize: 11,
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
