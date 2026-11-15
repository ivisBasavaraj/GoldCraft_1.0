import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/karagars_provider.dart';
import '../../../jobs/data/jobs_provider.dart';
import '../../../advances/data/advances_provider.dart';
import '../../../jobs/domain/job_model.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../core/theme/colors.dart';

class KaragarProfileScreen extends ConsumerWidget {
  final String karagarId;
  const KaragarProfileScreen({super.key, required this.karagarId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final karagarsAsync = ref.watch(karagarsProvider);
    final jobsAsync = ref.watch(jobsByKaragarProvider(karagarId));
    final advancesAsync = ref.watch(advancesProvider(karagarId));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      body: karagarsAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading profile...'),
        error: (e, _) => GcErrorState(message: e.toString()),
        data: (karagars) {
          final karagar = karagars.where((k) => k.id == karagarId).firstOrNull;
          if (karagar == null) {
            return const GcErrorState(message: 'Karagar not found');
          }
          return Scaffold(
            backgroundColor: GoldCraftColors.background,
            floatingActionButton: karagar.isActive
                ? FloatingActionButton.extended(
                    onPressed: () => context.push(
                      '/jobs/new?karagarId=${karagar.id}&karagarName=${Uri.encodeComponent(karagar.name)}',
                    ),
                    backgroundColor: GoldCraftColors.jewelryGold,
                    foregroundColor: GoldCraftColors.pureWhite,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Assign Job'),
                  )
                : null,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: GoldCraftColors.pureWhite,
                  foregroundColor: GoldCraftColors.charcoal,
                  actions: [
                    if (karagar.isActive)
                      TextButton.icon(
                        onPressed: () => context.push(
                          '/jobs/new?karagarId=${karagar.id}&karagarName=${Uri.encodeComponent(karagar.name)}',
                        ),
                        icon: const Icon(Icons.add_task_rounded,
                            color: GoldCraftColors.jewelryGold, size: 18),
                        label: const Text('Assign Job',
                            style: TextStyle(
                                color: GoldCraftColors.jewelryGold,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {},
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2C1F0A), Color(0xFF4A3218)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: GoldCraftColors.jewelryGoldLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  karagar.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: GoldCraftColors.jewelryGoldDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(karagar.name,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              '${karagar.employeeCode} · ${karagar.meltingGroup}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GoldCraftBadge(
                              label: karagar.isActive ? 'Active' : 'Inactive',
                              type: karagar.isActive
                                  ? GoldCraftBadgeType.success
                                  : GoldCraftBadgeType.neutral,
                            ),
                            const SizedBox(width: 8),
                            GoldCraftBadge(
                              label: karagar.specialization,
                              type: GoldCraftBadgeType.info,
                            ),
                          ],
                        ),
                        if (karagar.phone != null) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.phone_outlined,
                                size: 16, color: GoldCraftColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(karagar.phone!,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: GoldCraftColors.textSecondary)),
                          ]),
                        ],
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 16, color: GoldCraftColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Joined ${DateFormat('d MMM yyyy').format(karagar.joinedAt)}',
                            style: const TextStyle(
                                fontSize: 14,
                                color: GoldCraftColors.textSecondary),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        _sectionTitle('Gold Custody'),
                        const SizedBox(height: 12),
                        Row(children: [
                          _statCard('Issued',
                              '${karagar.totalIssuedGrams.toStringAsFixed(1)} g',
                              GoldCraftColors.softAmber,
                              GoldCraftColors.softAmberText),
                          const SizedBox(width: 12),
                          _statCard('Returned',
                              '${karagar.totalReturnedGrams.toStringAsFixed(1)} g',
                              GoldCraftColors.softGreen,
                              GoldCraftColors.softGreenText),
                          const SizedBox(width: 12),
                          _statCard(
                              'Outstanding',
                              '${karagar.outstandingCustodyGrams.toStringAsFixed(1)} g',
                              karagar.outstandingCustodyGrams > 0
                                  ? GoldCraftColors.softRed
                                  : GoldCraftColors.softGreen,
                              karagar.outstandingCustodyGrams > 0
                                  ? GoldCraftColors.softRedText
                                  : GoldCraftColors.softGreenText),
                        ]),
                        const SizedBox(height: 24),

                        _sectionTitle('Advances'),
                        const SizedBox(height: 12),
                        advancesAsync.when(
                          loading: () => const GcLoadingIndicator(),
                          error: (e, _) => GcErrorState(message: e.toString()),
                          data: (advances) {
                            if (advances.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('No advances recorded.',
                                    style: TextStyle(
                                        color: GoldCraftColors.textHint)),
                              );
                            }
                            final outstanding = advances
                                .where((a) => !a.fullyRepaid)
                                .fold(0.0, (s, a) => s + a.outstandingRupees);
                            return Column(
                              children: [
                                if (outstanding > 0)
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: GoldCraftColors.softAmber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          color: GoldCraftColors.softAmberText,
                                          size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Outstanding: ₹${outstanding.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: GoldCraftColors.softAmberText),
                                      ),
                                    ]),
                                  ),
                                ...advances.take(3).map((a) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: GoldCraftColors.pureWhite,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: GoldCraftColors.divider),
                                      ),
                                      child: Row(children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '₹${a.amountRupees.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: GoldCraftColors.charcoal),
                                              ),
                                              Text(
                                                DateFormat('d MMM yyyy')
                                                    .format(a.createdAt),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: GoldCraftColors.textHint),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GoldCraftBadge(
                                          label: a.fullyRepaid
                                              ? 'Repaid'
                                              : 'Outstanding',
                                          type: a.fullyRepaid
                                              ? GoldCraftBadgeType.success
                                              : GoldCraftBadgeType.warning,
                                        ),
                                      ]),
                                    )),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        _sectionTitle('Job History'),
                        const SizedBox(height: 12),
                        jobsAsync.when(
                          loading: () => const GcLoadingIndicator(),
                          error: (e, _) => GcErrorState(message: e.toString()),
                          data: (jobs) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (jobs.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('No jobs assigned yet.',
                                        style: TextStyle(
                                            color: GoldCraftColors.textHint)),
                                  )
                                else
                                  ...jobs.map((j) => _JobHistoryTile(job: j)),
                                const SizedBox(height: 12),
                                if (karagar.isActive)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => context.push(
                                        '/jobs/new?karagarId=${karagar.id}&karagarName=${Uri.encodeComponent(karagar.name)}',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            GoldCraftColors.jewelryGold,
                                        side: const BorderSide(
                                            color: GoldCraftColors.jewelryGold),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.add_task_rounded,
                                          size: 18),
                                      label: Text(
                                        jobs.isEmpty
                                            ? 'Assign First Job'
                                            : 'Assign Another Job',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: GoldCraftColors.charcoal));

  Widget _statCard(String label, String value, Color bg, Color fg) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: fg.withOpacity(0.7))),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      );
}

class _JobHistoryTile extends StatelessWidget {
  final Job job;
  const _JobHistoryTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final (type, label) = switch (job.status) {
      JobStatus.assigned => (GoldCraftBadgeType.info, 'Assigned'),
      JobStatus.inProgress => (GoldCraftBadgeType.warning, 'In Progress'),
      JobStatus.qualityCheck => (GoldCraftBadgeType.warning, 'QC'),
      JobStatus.completed => (GoldCraftBadgeType.success, 'Done'),
      JobStatus.cancelled => (GoldCraftBadgeType.error, 'Cancelled'),
    };
    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GoldCraftColors.divider),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: GoldCraftColors.charcoal)),
                const SizedBox(height: 2),
                Text(
                  '#${job.jobNumber} · ${job.requiredWeightGrams.toStringAsFixed(1)} g',
                  style: const TextStyle(
                      fontSize: 12, color: GoldCraftColors.textSecondary),
                ),
              ],
            ),
          ),
          GoldCraftBadge(label: label, type: type),
        ]),
      ),
    );
  }
}
