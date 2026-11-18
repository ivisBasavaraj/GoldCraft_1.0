import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/dashboard_provider.dart';
import '../widgets/treasury_vault_card.dart';
import '../../../../shared/widgets/gc_metric_card.dart';
import '../../../../shared/widgets/gc_section_header.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../core/theme/colors.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../features/auth/domain/auth_models.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GoldCraft ERP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              'Good ${_greeting()}, ${user?.name.split(' ').first ?? 'Manager'}',
              style: const TextStyle(
                  fontSize: 12,
                  color: GoldCraftColors.textSecondary,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GoldCraftColors.jewelryGoldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: GoldCraftColors.jewelryGoldDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading dashboard...'),
        error: (e, _) => GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (summary) => RefreshIndicator(
          color: GoldCraftColors.jewelryGold,
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Treasury Vault
              TreasuryVaultCard(treasury: summary.treasury),
              const SizedBox(height: 28),

              // KPI Cards
              GcSectionHeader(
                title: 'Workshop Overview',
                actionLabel: 'View Reports',
                onAction: () => context.push('/reports'),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  GcMetricCard(
                    title: 'Total Karagars',
                    value: summary.totalKaragars.toString(),
                    subtitle: 'Active artisans',
                    icon: Icons.people_outline_rounded,
                    iconColor: GoldCraftColors.softBlueText,
                    iconBg: GoldCraftColors.softBlue,
                    onTap: () => context.push('/karagars'),
                  ),
                  GcMetricCard(
                    title: 'Gold Issued',
                    value: '${summary.totalGoldIssuedGrams.toStringAsFixed(1)} g',
                    subtitle: 'Total issued',
                    icon: Icons.swap_horiz_rounded,
                    iconColor: GoldCraftColors.jewelryGoldDark,
                    iconBg: GoldCraftColors.jewelryGoldLight,
                    onTap: () => context.push('/material-issuance'),
                  ),
                  GcMetricCard(
                    title: 'Advances Paid',
                    value: '₹${_formatAmount(summary.totalAdvancePaidRupees)}',
                    subtitle: 'Total disbursed',
                    icon: Icons.payments_outlined,
                    iconColor: GoldCraftColors.softAmberText,
                    iconBg: GoldCraftColors.softAmber,
                    onTap: () => context.push('/advances'),
                  ),
                  GcMetricCard(
                    title: 'Total Salary',
                    value: '₹${_formatAmount(summary.totalSalaryRupees)}',
                    subtitle: 'Calculated payroll',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: GoldCraftColors.softGreenText,
                    iconBg: GoldCraftColors.softGreen,
                    onTap: () => context.push('/payroll'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Quick Actions
              const GcSectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 16),
              _buildQuickActions(context, user),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _ManagerBottomNav(currentIndex: 0, isAdmin: user?.isAdmin == true),
    );
  }

  Widget _buildQuickActions(BuildContext context, AuthUser? user) {
    final actions = [
      (Icons.add_task_rounded, 'Assign Work', '/jobs/new', GoldCraftColors.jewelryGold),
      (Icons.scale_outlined, 'Issue Gold', '/material-issuance/new', GoldCraftColors.softAmberText),
      (Icons.keyboard_return_outlined, 'Receive Gold', '/material-receipts/new', GoldCraftColors.softGreenText),
      (Icons.currency_rupee_rounded, 'Advance', '/advances/new', GoldCraftColors.softBlueText),
      if (user?.isAdmin == true)
        (Icons.person_add_outlined, 'Add User', '/users/new', GoldCraftColors.softRedText),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions
          .map(
            (a) => SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 4,
              child: GestureDetector(
                onTap: () => context.push(a.$3),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: GoldCraftColors.pureWhite,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    border: Border.fromBorderSide(
                        BorderSide(color: GoldCraftColors.divider)),
                  ),
                  child: Column(
                    children: [
                      Icon(a.$1, color: a.$4, size: 26),
                      const SizedBox(height: 8),
                      Text(
                        a.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: GoldCraftColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}

class _ManagerBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isAdmin;
  const _ManagerBottomNav({required this.currentIndex, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final routes = ['/dashboard', '/karagars', '/jobs', '/treasury', '/reports'];
    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
      const BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people_rounded), label: 'Karagars'),
      const BottomNavigationBarItem(icon: Icon(Icons.work_outline_rounded), activeIcon: Icon(Icons.work_rounded), label: 'Jobs'),
      const BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), activeIcon: Icon(Icons.account_balance_rounded), label: 'Treasury'),
      const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
    ];

    if (isAdmin) {
      routes.add('/users');
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.manage_accounts_outlined),
        activeIcon: Icon(Icons.manage_accounts_rounded),
        label: 'Users',
      ));
    }

    return Container(
      decoration: const BoxDecoration(
        color: GoldCraftColors.pureWhite,
        border: Border(top: BorderSide(color: GoldCraftColors.divider)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.length - 1),
        onTap: (i) {
          if (i == currentIndex) return;
          if (i < routes.length) context.push(routes[i]);
        },
        items: items,
      ),
    );
  }
}
