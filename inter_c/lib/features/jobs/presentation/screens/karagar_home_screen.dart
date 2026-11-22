import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/jobs_provider.dart';
import '../widgets/karagar_job_card.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../../features/auth/domain/auth_provider.dart';

class KaragarHomeScreen extends ConsumerWidget {
  const KaragarHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myJobsProvider);
    final user = ref.watch(authUserProvider).valueOrNull;

    return GcScaffold(
      isAdmin: false,
      bottomNav: const KaragarBottomNav(currentIndex: 0),
      header: GcPageHeader(
        title: user?.name ?? 'My Work',
        subtitle:
            user?.employeeCode != null ? 'ID: ${user!.employeeCode}' : null,
        showBack: false,
      ),
      body: jobsAsync.when(
        loading: () =>
            const GcLoadingIndicator(message: 'Loading your work...'),
        error: (e, _) => GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(myJobsProvider),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const GcEmptyState(
              icon: Icons.work_outline_rounded,
              title: 'No Work Assigned',
              subtitle: 'You have no active jobs right now.\nCheck back later.',
            );
          }

          final activeJobs = jobs
              .where((j) =>
                  j.status.name != 'completed' && j.status.name != 'cancelled')
              .toList();
          final doneJobs = jobs
              .where((j) =>
                  j.status.name == 'completed' || j.status.name == 'cancelled')
              .toList();

          return RefreshIndicator(
            color: GcUi.green,
            onRefresh: () async => ref.invalidate(myJobsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildSummaryBanner(jobs.length, activeJobs.length),
                const SizedBox(height: 22),
                if (activeJobs.isNotEmpty) ...[
                  _sectionTitle(Icons.handyman_outlined, 'My Work'),
                  const SizedBox(height: 14),
                  ...activeJobs.map((j) => KaragarJobCard(job: j)),
                ],
                if (doneJobs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _sectionTitle(Icons.task_alt_rounded, 'Completed Work'),
                  const SizedBox(height: 14),
                  ...doneJobs.map((j) => KaragarJobCard(job: j)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: GcUi.goldDark, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: GcUi.ink)),
              const SizedBox(height: 3),
              Container(
                width: 56,
                height: 3,
                decoration: BoxDecoration(
                  color: GcUi.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildSummaryBanner(int total, int active) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E6B43), Color(0xFF083D28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: GcUi.greenDark.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: GcUi.gold, width: 1.5),
            ),
            child: const Icon(Icons.work_rounded, color: GcUi.gold, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Work Summary',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$active active job${active != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
              width: 1,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: Colors.white.withValues(alpha: 0.3)),
          Column(
            children: [
              Text('$total',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
              const Text('Total',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Karagar bottom navigation: same floating pill card as admin / manager,
// with the karagar's own four buttons and routes.
// -----------------------------------------------------------------------------
class KaragarBottomNav extends StatelessWidget {
  final int currentIndex;
  const KaragarBottomNav({super.key, required this.currentIndex});

  static const _routes = ['/home', '/my-gold', '/my-payroll', '/profile'];

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'My Work'),
    (Icons.swap_horiz_outlined, Icons.swap_horiz_rounded, 'Gold Given'),
    (Icons.payments_outlined, Icons.payments_rounded, 'Earnings'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'My Profile'),
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
          border: Border.all(color: GcUi.border),
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
                        color: GcUi.greenDark,
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
                          const SizedBox(height: 2),
                          Container(
                            width: 24,
                            height: 2,
                            decoration: BoxDecoration(
                              color: GcUi.gold,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => context.push(_routes[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_items[i].$1, color: GcUi.muted, size: 24),
                              const SizedBox(height: 2),
                              Text(_items[i].$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: GcUi.muted, fontSize: 12)),
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