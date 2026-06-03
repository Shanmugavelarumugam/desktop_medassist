import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/auth/presentation/controller/auth_controller.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Use a custom RouterRefreshNotifier to signal GoRouter to re-evaluate redirect
  // without rebuilding the GoRouter provider instance itself.
  final refreshNotifier = RouterRefreshNotifier();
  ref.listen(authControllerProvider, (previous, next) {
    // Notify GoRouter when authentication state changes
    refreshNotifier.refresh();
  });

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isSplash = state.matchedLocation == RoutePaths.splash;
      final isLogin = state.matchedLocation == RoutePaths.login;
      final isSignUp = state.matchedLocation == RoutePaths.signup;

      // Debug prints as requested (only in debug mode)
      if (kDebugMode) {
        print("AUTH STATUS IN REDIRECT:");
        print("isAuthenticated: $isLoggedIn");
        print("matchedLocation: ${state.matchedLocation}");
      }

      // While splash screen animation runs, do not redirect immediately.
      // After animation completes, we transition according to authState.
      if (isSplash) {
        return null;
      }

      // Re-route users if unauthenticated
      if (!isLoggedIn && !isLogin && !isSignUp) {
        return RoutePaths.login;
      }

      // Prevent logged-in users from seeing Auth screens
      if (isLoggedIn && (isLogin || isSignUp)) {
        return RoutePaths.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(showSignUpInitially: false),
      ),
      GoRoute(
        path: RoutePaths.signup,
        builder: (context, state) => const LoginScreen(showSignUpInitially: true),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
});
