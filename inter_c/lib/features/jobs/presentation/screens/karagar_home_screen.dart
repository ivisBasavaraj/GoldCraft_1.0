import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/jobs_provider.dart';
import '../widgets/karagar_job_card.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../features/auth/domain/auth_provider.dart';

class KaragarHomeScreen extends ConsumerWidget {
  const KaragarHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myJobsProvider);
    final user = ref.watch(authUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'My Work',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (user?.employeeCode != null)
              Text(
                'ID: ${user!.employeeCode}',
                style: const TextStyle(
                  fontSize: 12,
                  color: GoldCraftColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: jobsAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading your work...'),
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
            color: GoldCraftColors.jewelryGold,
            onRefresh: () async => ref.invalidate(myJobsProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Summary banner
                _buildSummaryBanner(jobs.length, activeJobs.length),
                const SizedBox(height: 24),

                // Active jobs
                if (activeJobs.isNotEmpty) ...[
                  const Text(
                    'My Work',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: GoldCraftColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...activeJobs.map((j) => KaragarJobCard(job: j)),
                ],

                // Completed jobs
                if (doneJobs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Completed Work',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GoldCraftColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...doneJobs.map((j) => KaragarJobCard(job: j)),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const KaragarBottomNav(currentIndex: 0),
    );
  }

  Widget _buildSummaryBanner(int total, int active) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [GoldCraftColors.jewelryGold, GoldCraftColors.jewelryGoldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.work_outline_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Work Summary',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$active active job${active != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'total',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KaragarBottomNav extends StatelessWidget {
  final int currentIndex;
  const KaragarBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GoldCraftColors.pureWhite,
        border: Border(top: BorderSide(color: GoldCraftColors.divider)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) {
          const routes = ['/home', '/my-gold', '/my-payroll', '/profile'];
          if (i == currentIndex) return;
          if (i < routes.length) context.push(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'My Work',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz_rounded),
            label: 'Gold Given',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
}
