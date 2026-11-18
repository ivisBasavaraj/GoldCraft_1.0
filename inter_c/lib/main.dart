import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/advances/data/advances_provider.dart';
import 'features/auth/domain/auth_provider.dart';
import 'features/dashboard/data/dashboard_provider.dart';
import 'features/jobs/data/jobs_provider.dart';
import 'features/karagars/data/karagars_provider.dart';
import 'features/material_issuance/data/issuance_provider.dart';
import 'features/material_receipts/data/receipts_provider.dart';
import 'features/payroll/data/payroll_provider.dart';
import 'features/treasury/data/treasury_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: GoldCraftApp()));
}

class GoldCraftApp extends ConsumerWidget {
  const GoldCraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'GoldCraft ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => _ApplicationShell(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Keeps business data current while the app is visible. Providers only fetch
/// again when a screen is listening to them, so inactive screens stay idle.
class _ApplicationShell extends ConsumerStatefulWidget {
  final Widget child;

  const _ApplicationShell({required this.child});

  @override
  ConsumerState<_ApplicationShell> createState() => _ApplicationShellState();
}

class _ApplicationShellState extends ConsumerState<_ApplicationShell>
    with WidgetsBindingObserver {
  static const _refreshInterval = Duration(seconds: 20);
  Timer? _refreshTimer;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      _refreshData();
      _configureTimer();
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  void _configureTimer() {
    final isSignedIn = ref.read(authUserProvider).valueOrNull != null;
    if (!isSignedIn || !_isForeground) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
      return;
    }
    _refreshTimer ??= Timer.periodic(_refreshInterval, (_) => _refreshData());
  }

  void _refreshData() {
    if (!mounted || ref.read(authUserProvider).valueOrNull == null) return;
    ref.invalidate(dashboardProvider);
    ref.invalidate(karagarsProvider);
    ref.invalidate(allJobsProvider);
    ref.invalidate(myJobsProvider);
    ref.invalidate(treasurySummaryProvider);
    ref.invalidate(treasuryTransactionsProvider);
    ref.invalidate(advancesProvider);
    ref.invalidate(myAdvancesProvider);
    ref.invalidate(payrollsProvider);
    ref.invalidate(myPayrollsProvider);
    ref.invalidate(issuancesProvider);
    ref.invalidate(myIssuancesProvider);
    ref.invalidate(receiptsProvider);
    ref.invalidate(myReceiptsProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authUserProvider);
    _configureTimer();
    return widget.child;
  }
}
