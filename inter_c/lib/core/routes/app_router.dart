import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/manager_dashboard_screen.dart';
import '../../features/jobs/presentation/screens/karagar_home_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/jobs/presentation/screens/assign_job_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/jobs/presentation/screens/my_gold_screen.dart';
import '../../features/payroll/presentation/screens/karagar_payroll_screen.dart';
import '../../features/karagars/presentation/screens/karagars_screen.dart';
import '../../features/karagars/presentation/screens/add_karagar_screen.dart';
import '../../features/karagars/presentation/screens/karagar_profile_screen.dart';
import '../../features/treasury/presentation/screens/treasury_screen.dart';
import '../../features/material_issuance/presentation/screens/issue_gold_screen.dart';
import '../../features/material_receipts/presentation/screens/receive_gold_screen.dart';
import '../../features/advances/presentation/screens/advances_screen.dart';
import '../../features/advances/presentation/screens/new_advance_screen.dart';
import '../../features/payroll/presentation/screens/payroll_screen.dart';
import '../../features/payroll/presentation/screens/payroll_detail_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/screens/users_screen.dart';
import '../../features/auth/presentation/screens/create_user_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authUserProvider);
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final isLogin = state.matchedLocation == '/login';

      if (user == null) return isLogin ? null : '/login';
      if (isLogin) return user.isKaragar ? '/home' : '/dashboard';

      if (user.isKaragar && _isManagerRoute(state.matchedLocation)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ── Manager routes ──────────────────────────────────────────
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const _ExitWrapper(child: ManagerDashboardScreen()),
      ),
      GoRoute(path: '/karagars', builder: (_, __) => const _ExitWrapper(child: KaragarsScreen())),
      GoRoute(path: '/karagars/new', builder: (_, __) => const AddKaragarScreen()),
      GoRoute(
        path: '/karagars/:id',
        builder: (_, s) => KaragarProfileScreen(karagarId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/jobs', builder: (_, __) => const _ExitWrapper(child: JobsScreen())),
      GoRoute(path: '/jobs/new', builder: (_, s) => AssignJobScreen(
        preselectedKaragarId: s.uri.queryParameters['karagarId'],
        preselectedKaragarName: s.uri.queryParameters['karagarName'],
      )),
      GoRoute(
        path: '/jobs/:id',
        builder: (_, s) => JobDetailScreen(jobId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/treasury', builder: (_, __) => const _ExitWrapper(child: TreasuryScreen())),
      GoRoute(
        path: '/material-issuance',
        builder: (_, __) => const IssueGoldScreen(),
      ),
      GoRoute(
        path: '/material-issuance/new',
        builder: (_, s) => IssueGoldScreen(
          initialJobId: s.uri.queryParameters['jobId'],
        ),
      ),
      GoRoute(
        path: '/material-receipts/new',
        builder: (_, s) => ReceiveGoldScreen(
          initialJobId: s.uri.queryParameters['jobId'],
        ),
      ),
      GoRoute(path: '/advances', builder: (_, __) => const _ExitWrapper(child: AdvancesScreen())),
      GoRoute(path: '/advances/new', builder: (_, __) => const NewAdvanceScreen()),
      GoRoute(path: '/payroll', builder: (_, __) => const _ExitWrapper(child: PayrollScreen())),
      GoRoute(
        path: '/payroll/:id',
        builder: (_, s) => PayrollDetailScreen(payrollId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/reports', builder: (_, __) => const _ExitWrapper(child: ReportsScreen())),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/users', builder: (_, __) => const _ExitWrapper(child: UsersScreen())),
      GoRoute(path: '/users/new', builder: (_, __) => const CreateUserScreen()),

      // ── Karagar routes ──────────────────────────────────────────
      GoRoute(path: '/home', builder: (_, __) => const _ExitWrapper(child: KaragarHomeScreen())),
      GoRoute(path: '/my-gold', builder: (_, __) => const _ExitWrapper(child: MyGoldScreen())),
      GoRoute(path: '/my-payroll', builder: (_, __) => const _ExitWrapper(child: KaragarPayrollScreen())),
      GoRoute(path: '/profile', builder: (_, __) => const SettingsScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

// Root screens that should show exit confirmation instead of closing the app
/// Wraps a root screen with Android back-button handling.
/// - If the current route is a root screen → show exit confirmation dialog
/// - Otherwise → let GoRouter pop normally
class _ExitWrapper extends StatelessWidget {
  final Widget child;
  const _ExitWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        // If router can go back, just pop
        if (router.canPop()) {
          router.pop();
          return;
        }
        // Root screen — ask user if they want to exit
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}

bool _isManagerRoute(String loc) => const [
      '/dashboard',
      '/karagars',
      '/treasury',
      '/material-issuance',
      '/material-receipts',
      '/advances',
      '/payroll',
      '/reports',
      '/users',
      '/jobs/new',
    ].any((r) => loc.startsWith(r)) || loc == '/jobs';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authUserProvider, (_, __) => notifyListeners());
  }
}
