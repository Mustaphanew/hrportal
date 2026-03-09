import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/attendance/presentation/screens/attendance_screen.dart';
import '../features/leave/presentation/screens/leaves_screen.dart';
import '../features/leave/presentation/screens/create_leave_screen.dart';
import '../features/payroll/presentation/screens/payroll_screens.dart';
import '../features/requests/presentation/screens/request_screens.dart';

/// Global navigator key for SessionManager callback.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter configuration.
///
/// Auth redirect logic:
/// - If [AuthStatus.unknown] → stay on /splash
/// - If [AuthStatus.unauthenticated] → redirect to /login
/// - If [AuthStatus.authenticated] and on /splash or /login → redirect to /
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,

    redirect: (context, state) {
      final auth = authState;
      final location = state.matchedLocation;

      // Still checking session → stay on splash.
      if (auth.isUnknown) {
        return location == '/splash' ? null : '/splash';
      }

      // Not authenticated → force login.
      if (auth.isUnauthenticated) {
        if (location == '/login') return null;
        return '/login';
      }

      // Authenticated but on splash or login → go home.
      if (auth.isAuthenticated) {
        if (location == '/splash' || location == '/login') return '/';
      }

      return null; // No redirect needed.
    },

    routes: [
      // ── Auth ──
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ── Main App (with bottom nav shell) ──
      ShellRoute(
        builder: (context, state, child) =>
            _MainShell(state: state, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(
            path: '/attendance',
            builder: (_, __) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/leaves',
            builder: (_, __) => const LeavesScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateLeaveScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/payroll',
            builder: (_, __) => const PayrollScreen(),
            routes: [
              GoRoute(
                path: ':month',
                builder: (_, state) =>
                    PayslipDetailScreen(month: state.pathParameters['month']!),
              ),
            ],
          ),
          GoRoute(
            path: '/requests',
            builder: (_, __) => const RequestsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateRequestScreen(),
              ),
            ],
          ),

          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});

// ═══════════════════════════════════════════════════════════════════
// Main Shell (Bottom Navigation)
// ═══════════════════════════════════════════════════════════════════

class _MainShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const _MainShell({required this.state, required this.child});

  int get _currentIndex {
    final location = state.matchedLocation;
    if (location.startsWith('/attendance')) return 1;
    if (location.startsWith('/leaves')) return 2;
    if (location.startsWith('/payroll')) return 3;
    if (location.startsWith('/requests')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/attendance');
              break;
            case 2:
              context.go('/leaves');
              break;
            case 3:
              context.go('/payroll');
              break;
            case 4:
              context.go('/requests');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: 'Home'.tr(context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.fingerprint_outlined),
            selectedIcon: const Icon(Icons.fingerprint),
            label: 'Attendance'.tr(context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.beach_access_outlined),
            selectedIcon: const Icon(Icons.beach_access),
            label: 'Leaves'.tr(context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: 'Payroll'.tr(context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description),
            label: 'Requests'.tr(context),
          ),
        ],
      ),
    );
  }
}
