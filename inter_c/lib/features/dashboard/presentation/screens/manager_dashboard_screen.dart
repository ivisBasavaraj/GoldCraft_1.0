import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/dashboard_provider.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../features/treasury/domain/treasury_model.dart';

// -----------------------------------------------------------------------------
// Local palette for this screen (matches the new green / gold design)
// -----------------------------------------------------------------------------
class _C {
  static const bg = Color(0xFFFBF8F3);
  static const card = Colors.white;
  static const ink = Color(0xFF0F2A1D);
  static const muted = Color(0xFF6B7280);
  static const greenDark = Color(0xFF0B4D32);
  static const green = Color(0xFF117A4D);
  static const greenTint = Color(0xFFE6F2EA);
  static const gold = Color(0xFFE7B53A);
  static const goldDark = Color(0xFFB7791F);
  static const goldTint = Color(0xFFFBF0D9);
  static const track = Color(0xFFE7ECE8);
  static const border = Color(0xFFEDE8DF);
}

// -----------------------------------------------------------------------------
// View-model for dashboard values displayed by this screen.
// -----------------------------------------------------------------------------
class _DashVm {
  final double availableGold; // grams
  final double inCirculation; // grams
  final double reservePercent;
  final double totalExpenses;
  final int activeJobs;
  final int assigned;
  final int inProgress;
  final int qualityCheck;
  final int completed;
  final int totalKaragars;
  final int totalJobs;

  const _DashVm({
    required this.availableGold,
    required this.inCirculation,
    required this.reservePercent,
    required this.totalExpenses,
    required this.activeJobs,
    required this.assigned,
    required this.inProgress,
    required this.qualityCheck,
    required this.completed,
    required this.totalKaragars,
    required this.totalJobs,
  });

  factory _DashVm.from(DashboardSummary summary) => _DashVm(
        availableGold: summary.treasury.availableGoldGrams,
        inCirculation: summary.treasury.inCirculationGrams,
        reservePercent: summary.treasury.reserveRemainingPercent,
        totalExpenses: summary.totalExpensesRupees,
        activeJobs: summary.activeJobs,
        assigned: summary.assignedJobs,
        inProgress: summary.inProgressJobs,
        qualityCheck: summary.qualityCheckJobs,
        completed: summary.completedJobs,
        totalKaragars: summary.totalKaragars,
        totalJobs: summary.totalJobs,
      );
}

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final name = user?.name.trim();
    final greeting = name?.isNotEmpty == true ? 'Welcome, $name' : 'Welcome';

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: dashAsync.when(
          loading: () =>
              const GcLoadingIndicator(message: 'Loading dashboard...'),
          error: (e, _) => GcErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (summary) {
            final vm = _DashVm.from(summary);
            return RefreshIndicator(
              color: _C.green,
              onRefresh: () async => ref.invalidate(dashboardProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _Header(
                    greeting: greeting,
                    unreadCount: 0,
                    onProfile: () => context.push('/profile'),
                    onBell: () => context.push('/notifications'),
                  ),
                  const SizedBox(height: 16),
                  _GoldHeroCard(vm: vm),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          value: vm.activeJobs.toString(),
                          label: 'Active Jobs',
                          icon: Icons.work_outline_rounded,
                          fg: _C.green,
                          bg: _C.greenTint,
                          onTap: () => context.push('/jobs'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: NumberFormat.currency(
                            locale: 'en_IN',
                            symbol: '₹',
                            decimalDigits: 0,
                          ).format(vm.totalExpenses),
                          label: 'Total Expenses',
                          icon: Icons.receipt_long_outlined,
                          fg: _C.goldDark,
                          bg: _C.goldTint,
                          onTap: () => context.push('/reports'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProductionPulseCard(vm: vm),
                  const SizedBox(height: 14),
                  _WorkshopCard(
                    vm: vm,
                    onViewAll: () => context.push('/karagars'),
                    onFollowUps: () => context.push('/jobs'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const _ManagerBottomNav(currentIndex: 0),
    );
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final String greeting;
  final int unreadCount;
  final VoidCallback onBell;
  final VoidCallback onProfile;
  const _Header({
    required this.greeting,
    this.unreadCount = 0,
    required this.onBell,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(fontSize: 15, color: _C.muted),
              ),
              const SizedBox(height: 2),
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _C.ink,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: _C.greenDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderActionButton(
              icon: Icons.person_outline_rounded,
              tooltip: 'Profile',
              onPressed: onProfile,
            ),
            const SizedBox(width: 8),
            _HeaderActionButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              onPressed: onBell,
              showBadge: unreadCount > 0,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showBadge;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black12,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(icon, color: _C.ink, size: 24),
                ),
              ),
            ),
            if (showBadge)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Hero: Available Gold
// -----------------------------------------------------------------------------
class _GoldHeroCard extends StatelessWidget {
  final _DashVm vm;
  const _GoldHeroCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E6B43), Color(0xFF083D28)],
        ),
        boxShadow: [
          BoxShadow(
            color: _C.greenDark.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative gold bars (replace with an Image.asset if you have one)
          Positioned(
            right: 4,
            top: 18,
            child: Icon(
              Icons.layers_rounded,
              size: 96,
              color: _C.gold.withValues(alpha: 0.9),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 9, color: Color(0xFF4ADE80)),
                  SizedBox(width: 6),
                  Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(color: _C.gold, width: 1.5),
                    ),
                    child: const Icon(Icons.layers_rounded,
                        color: _C.gold, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Gold',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${vm.availableGold.toStringAsFixed(3)} g',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 80), // room for the decorative bars
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Ready for controlled issue',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      icon: Icons.sync_rounded,
                      label: 'In Circulation',
                      value: '${vm.inCirculation.toStringAsFixed(3)} g',
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroStat(
                      icon: Icons.storage_rounded,
                      label: 'Reserve Available',
                      value: '${vm.reservePercent.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeroStat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Active Jobs / Payroll Queue tiles
// -----------------------------------------------------------------------------
class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _C.ink,
                            height: 1.1)),
                  ),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: _C.ink)),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded, color: fg, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Production Pulse
// -----------------------------------------------------------------------------
class _ProductionPulseCard extends StatelessWidget {
  final _DashVm vm;
  const _ProductionPulseCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final maxCount = [vm.assigned, vm.inProgress, vm.qualityCheck, vm.completed]
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_outlined,
                  color: _C.greenDark, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text('Production Pulse',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _C.ink)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PulseRow('Assigned', vm.assigned, maxCount, const Color(0xFF8DB8A0)),
          _PulseRow('In Progress', vm.inProgress, maxCount, _C.green),
          _PulseRow('Quality Check', vm.qualityCheck, maxCount, _C.gold),
          _PulseRow('Completed', vm.completed, maxCount, _C.green),
        ],
      ),
    );
  }
}

class _PulseRow extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;
  final Color color;
  const _PulseRow(this.label, this.count, this.maxCount, this.color);

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 14, color: _C.ink)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(height: 10, color: _C.track),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(height: 10, color: color),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _C.ink)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Workshop & Operations
// -----------------------------------------------------------------------------
class _WorkshopCard extends StatelessWidget {
  final _DashVm vm;
  final VoidCallback onViewAll;
  final VoidCallback onFollowUps;
  const _WorkshopCard({
    required this.vm,
    required this.onViewAll,
    required this.onFollowUps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.greenTint.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.settings_outlined,
                  color: _C.greenDark, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Workshop & Operations',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _C.ink)),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Text('View All',
                        style: TextStyle(
                            color: _C.green,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: _C.green, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                            color: Color(0xFFD5E8DB), shape: BoxShape.circle),
                        child: const Icon(Icons.groups_rounded,
                            color: _C.greenDark, size: 30),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Live workshop status',
                                style:
                                    TextStyle(fontSize: 12, color: _C.muted)),
                            Text('${vm.totalKaragars} karagars',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _C.ink)),
                            Text(
                                '${vm.activeJobs} active jobs • ${vm.totalJobs} total ledger',
                                style: const TextStyle(
                                    fontSize: 11, color: _C.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 20, color: _C.border),
                Expanded(
                  child: GestureDetector(
                    onTap: onFollowUps,
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                              color: _C.goldDark, shape: BoxShape.circle),
                          child: const Icon(Icons.priority_high_rounded,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Quality check',
                                  style:
                                      TextStyle(fontSize: 12, color: _C.muted)),
                              Text('${vm.qualityCheck} jobs',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _C.ink)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: _C.green, size: 20),
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
}

// -----------------------------------------------------------------------------
// Bottom navigation (pill-style selected tab)
// -----------------------------------------------------------------------------
class _ManagerBottomNav extends StatelessWidget {
  final int currentIndex;
  const _ManagerBottomNav({required this.currentIndex});

  static const _routes = [
    '/dashboard',
    '/karagars',
    '/jobs',
    '/treasury',
    '/reports',
  ];

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.people_outline, Icons.people_rounded, 'Karagars'),
    (Icons.work_outline_rounded, Icons.work_rounded, 'Jobs'),
    (Icons.account_balance_outlined, Icons.account_balance_rounded, 'Treasury'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _C.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            for (int i = 0; i < _items.length; i++)
              i == currentIndex
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _C.greenDark,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_items[i].$2, color: Colors.white, size: 24),
                          const SizedBox(height: 2),
                          Text(_items[i].$3,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  : Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => context.go(_routes[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_items[i].$1, color: _C.muted, size: 24),
                              const SizedBox(height: 2),
                              Text(_items[i].$3,
                                  style: const TextStyle(
                                      color: _C.muted, fontSize: 12)),
                            ],
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
