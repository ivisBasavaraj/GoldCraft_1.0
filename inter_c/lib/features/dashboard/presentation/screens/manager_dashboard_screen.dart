import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/dashboard_provider.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../features/treasury/domain/treasury_model.dart';

// -----------------------------------------------------------------------------
// Shared neutrals (same for every role)
// -----------------------------------------------------------------------------
class _C {
  static const card = Colors.white;
  static const ink = Color(0xFF0F2A1D);
  static const muted = Color(0xFF6B7280);
  static const track = Color(0xFFE7ECE8);
  static const border = Color(0xFFEDE8DF);
  static const gold = Color(0xFFE7B53A);
  static const goldDark = Color(0xFFB7791F);
  static const goldTint = Color(0xFFFBF0D9);
}

// -----------------------------------------------------------------------------
// Role-specific dashboard labels and data live here; the color palette is shared.
// -----------------------------------------------------------------------------
class _RT {
  final bool isAdmin;
  final String roleLabel;
  final String title;
  final String heroLabel;
  final String pulseTitle;
  final Color bg;
  final Color primary; // buttons, nav pill, accents
  final Color primaryLight; // links, refresh indicator
  final Color tint; // soft backgrounds
  final List<Color> heroGradient;
  final Color tileAFg;
  final Color tileABg;
  final Color tileBFg;
  final Color tileBBg;
  final List<Color> pulseColors;
  final Color workshopBg;
  final Color workshopBorder;

  const _RT({
    required this.isAdmin,
    required this.roleLabel,
    required this.title,
    required this.heroLabel,
    required this.pulseTitle,
    required this.bg,
    required this.primary,
    required this.primaryLight,
    required this.tint,
    required this.heroGradient,
    required this.tileAFg,
    required this.tileABg,
    required this.tileBFg,
    required this.tileBBg,
    required this.pulseColors,
    required this.workshopBg,
    required this.workshopBorder,
  });

  static const manager = _RT(
    isAdmin: false,
    roleLabel: 'MANAGER',
    title: 'Dashboard',
    heroLabel: 'Available Gold',
    pulseTitle: 'Production Pulse',
    bg: Color(0xFFFBF8F3),
    primary: Color(0xFF0B4D32),
    primaryLight: Color(0xFF117A4D),
    tint: Color(0xFFE6F2EA),
    heroGradient: [Color(0xFF0E6B43), Color(0xFF083D28)],
    tileAFg: Color(0xFF117A4D),
    tileABg: Color(0xFFE6F2EA),
    tileBFg: _C.goldDark,
    tileBBg: _C.goldTint,
    pulseColors: [
      Color(0xFF8DB8A0),
      Color(0xFF117A4D),
      _C.gold,
      Color(0xFF117A4D),
    ],
    workshopBg: Color(0x99E6F2EA),
    workshopBorder: _C.border,
  );

  static const admin = _RT(
    isAdmin: true,
    roleLabel: 'ADMIN',
    title: 'Admin Dashboard',
    heroLabel: 'Vault Balance',
    pulseTitle: 'Production Overview',
    bg: Color(0xFFFBF8F3),
    primary: Color(0xFF0B4D32),
    primaryLight: Color(0xFF117A4D),
    tint: Color(0xFFE6F2EA),
    heroGradient: [Color(0xFF0E6B43), Color(0xFF083D28)],
    tileAFg: Color(0xFF117A4D),
    tileABg: Color(0xFFE6F2EA),
    tileBFg: _C.goldDark,
    tileBBg: _C.goldTint,
    pulseColors: [
      Color(0xFF8DB8A0),
      Color(0xFF117A4D),
      _C.gold,
      Color(0xFF117A4D),
    ],
    workshopBg: Color(0x99E6F2EA),
    workshopBorder: _C.border,
  );

  /// Works whether `role` is a String or an enum.
  static _RT fromRole(Object? role) =>
      role.toString().toLowerCase().contains('admin') ? admin : manager;
}

// -----------------------------------------------------------------------------
// View-model
// -----------------------------------------------------------------------------
class _DashVm {
  final double availableGold;
  final double inCirculation;
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

// -----------------------------------------------------------------------------
// Screen
// -----------------------------------------------------------------------------
class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final name = user?.name.trim();
    final greeting = name?.isNotEmpty == true ? 'Welcome, $name' : 'Welcome';

    // NOTE: assumes your user model exposes `role`. Adjust if named differently.
    final rt = _RT.fromRole(user?.role);

    return Scaffold(
      backgroundColor: rt.bg,
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
            final currency = NumberFormat.currency(
              locale: 'en_IN',
              symbol: '₹',
              decimalDigits: 0,
            ).format(vm.totalExpenses);

            return RefreshIndicator(
              color: rt.primaryLight,
              onRefresh: () async => ref.invalidate(dashboardProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _Header(
                    rt: rt,
                    greeting: greeting,
                    unreadCount: 0,
                    onProfile: () => context.push('/profile'),
                    onBell: () => context.push('/notifications'),
                  ),
                  const SizedBox(height: 16),
                  _GoldHeroCard(vm: vm, rt: rt),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          value: vm.activeJobs.toString(),
                          label: 'Active Jobs',
                          icon: Icons.work_outline_rounded,
                          fg: rt.tileAFg,
                          bg: rt.tileABg,
                          onTap: () => context.push('/jobs'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: currency,
                          label: 'Total Expenses',
                          icon: Icons.receipt_long_outlined,
                          fg: rt.tileBFg,
                          bg: rt.tileBBg,
                          onTap: () => context.push('/payroll'),
                        ),
                      ),
                    ],
                  ),
                  // Admin-only: business-wide overview strip
                  if (rt.isAdmin) ...[
                    const SizedBox(height: 14),
                    _AdminOverviewStrip(vm: vm, rt: rt),
                  ],
                  const SizedBox(height: 14),
                  _ProductionPulseCard(vm: vm, rt: rt),
                  const SizedBox(height: 14),
                  _WorkshopCard(
                    vm: vm,
                    rt: rt,
                    onViewAll: () => context.push('/karagars'),
                    onFollowUps: () => context.push('/jobs'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _ManagerBottomNav(currentIndex: 0, rt: rt),
    );
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final _RT rt;
  final String greeting;
  final int unreadCount;
  final VoidCallback onBell;
  final VoidCallback onProfile;
  const _Header({
    required this.rt,
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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      greeting,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, color: _C.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoleChip(rt: rt),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                rt.title,
                style: const TextStyle(
                  fontSize: 30,
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
                  color: rt.primary,
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

class _RoleChip extends StatelessWidget {
  final _RT rt;
  const _RoleChip({required this.rt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: rt.tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rt.isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.manage_accounts_rounded,
            size: 12,
            color: rt.primary,
          ),
          const SizedBox(width: 4),
          Text(
            rt.roleLabel,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: rt.primary,
            ),
          ),
        ],
      ),
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
  final _RT rt;
  const _GoldHeroCard({required this.vm, required this.rt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rt.heroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: rt.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
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
                    child: Icon(
                      rt.isAdmin
                          ? Icons.account_balance_rounded
                          : Icons.layers_rounded,
                      color: _C.gold,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rt.heroLabel,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
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
                  const SizedBox(width: 80),
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
// Active Jobs / Expenses tiles
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
// Admin-only overview strip (uses data already on the dashboard)
// -----------------------------------------------------------------------------
class _AdminOverviewStrip extends StatelessWidget {
  final _DashVm vm;
  final _RT rt;
  const _AdminOverviewStrip({required this.vm, required this.rt});

  @override
  Widget build(BuildContext context) {
    Widget cell(IconData icon, String value, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: _C.gold, size: 22),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: rt.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          cell(Icons.groups_rounded, '${vm.totalKaragars}', 'Karagars'),
          Container(
              width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
          cell(Icons.folder_copy_outlined, '${vm.totalJobs}', 'Total Jobs'),
          Container(
              width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
          cell(Icons.task_alt_rounded, '${vm.completed}', 'Completed'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Production Pulse
// -----------------------------------------------------------------------------
class _ProductionPulseCard extends StatelessWidget {
  final _DashVm vm;
  final _RT rt;
  const _ProductionPulseCard({required this.vm, required this.rt});

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
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: rt.primary, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(rt.pulseTitle,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _C.ink)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PulseRow('Assigned', vm.assigned, maxCount, rt.pulseColors[0]),
          _PulseRow('In Progress', vm.inProgress, maxCount, rt.pulseColors[1]),
          _PulseRow(
              'Quality Check', vm.qualityCheck, maxCount, rt.pulseColors[2]),
          _PulseRow('Completed', vm.completed, maxCount, rt.pulseColors[3]),
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
  final _RT rt;
  final VoidCallback onViewAll;
  final VoidCallback onFollowUps;
  const _WorkshopCard({
    required this.vm,
    required this.rt,
    required this.onViewAll,
    required this.onFollowUps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rt.workshopBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rt.workshopBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, color: rt.primary, size: 28),
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
                child: Row(
                  children: [
                    Text('View All',
                        style: TextStyle(
                            color: rt.primaryLight,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: rt.primaryLight, size: 18),
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
                        decoration: BoxDecoration(
                            color: rt.tint, shape: BoxShape.circle),
                        child: Icon(Icons.groups_rounded,
                            color: rt.primary, size: 30),
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
                        Icon(Icons.arrow_forward_rounded,
                            color: rt.primaryLight, size: 20),
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
// Bottom navigation (pill-style selected tab, colored per role)
// -----------------------------------------------------------------------------
class _ManagerBottomNav extends StatelessWidget {
  final int currentIndex;
  final _RT rt;
  const _ManagerBottomNav({required this.currentIndex, required this.rt});

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
                        color: rt.primary,
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
