import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/karagars_provider.dart';
import '../../../jobs/data/jobs_provider.dart';
import '../../../advances/data/advances_provider.dart';
import '../../../jobs/domain/job_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../../core/theme/colors.dart';
import '../widgets/karagar_avatar.dart';

class KaragarProfileScreen extends ConsumerWidget {
  final String karagarId;
  const KaragarProfileScreen({super.key, required this.karagarId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final karagarsAsync = ref.watch(karagarsProvider);
    final jobsAsync = ref.watch(jobsByKaragarProvider(karagarId));
    final advancesAsync = ref.watch(advancesProvider(karagarId));
    final isAdmin = ref.watch(authUserProvider).valueOrNull?.isAdmin == true;
    final primary = GcUi.primary(isAdmin);

    // Shared shell for loading / error / data states.
    Widget shell({
      required Widget body,
      List<Widget> actions = const [],
      Widget? fab,
    }) =>
        GcScaffold(
          isAdmin: isAdmin,
          bottomNav: GcBottomNav(currentIndex: 1, isAdmin: isAdmin),
          floatingActionButton: fab,
          header: GcPageHeader(
            title: 'Karagar Profile',
            showBack: context.canPop(),
            actions: actions,
          ),
          body: body,
        );

    return karagarsAsync.when(
      loading: () =>
          shell(body: const GcLoadingIndicator(message: 'Loading profile...')),
      error: (e, _) => shell(body: GcErrorState(message: e.toString())),
      data: (karagars) {
        final karagar = karagars.where((k) => k.id == karagarId).firstOrNull;
        if (karagar == null) {
          return shell(body: const GcErrorState(message: 'Karagar not found'));
        }

        void assignJob() => context.push(
              '/jobs/new?karagarId=${karagar.id}&karagarName=${Uri.encodeComponent(karagar.name)}',
            );

        return shell(
          fab: karagar.isActive
              ? FloatingActionButton.extended(
                  onPressed: assignJob,
                  backgroundColor: GcUi.gold,
                  foregroundColor: GcUi.ink,
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Assign Job'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Hero card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: GcUi.heroGradient(isAdmin),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        KaragarAvatar(
                          name: karagar.name,
                          imageUrl: karagar.avatarUrl,
                          size: 76,
                          backgroundColor: GcUi.goldTint,
                          foregroundColor: GcUi.ink,
                          borderColor: GcUi.gold,
                          borderWidth: 3,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(karagar.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                '${karagar.employeeCode} · ${karagar.meltingGroup}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          GoldCraftBadge(
                            label: karagar.isActive ? 'Active' : 'Inactive',
                            type: karagar.isActive
                                ? GoldCraftBadgeType.success
                                : GoldCraftBadgeType.neutral,
                          ),
                          GoldCraftBadge(
                            label: karagar.specialization,
                            type: GoldCraftBadgeType.info,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Contact info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: GcUi.card(radius: 20, color: GcUi.ivory),
                child: Column(
                  children: [
                    if (karagar.phone != null) ...[
                      _infoRow(Icons.phone_outlined, karagar.phone!, primary),
                      const SizedBox(height: 10),
                    ],
                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Joined ${DateFormat('d MMM yyyy').format(karagar.joinedAt)}',
                      primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionTitle(Icons.layers_rounded, 'Gold Custody', primary),
              const SizedBox(height: 12),
              Row(children: [
                _statCard(
                    'Issued',
                    '${karagar.totalIssuedGrams.toStringAsFixed(1)} g',
                    GoldCraftColors.softAmber,
                    GoldCraftColors.softAmberText),
                const SizedBox(width: 12),
                _statCard(
                    'Returned',
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

              _sectionTitle(
                  Icons.account_balance_wallet_outlined, 'Advances', primary),
              const SizedBox(height: 12),
              advancesAsync.when(
                loading: () => const GcLoadingIndicator(),
                error: (e, _) => GcErrorState(message: e.toString()),
                data: (advances) {
                  if (advances.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No advances recorded.',
                          style: TextStyle(color: GcUi.muted)),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: GoldCraftColors.softAmberText,
                                size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Outstanding: ₹${outstanding.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: GoldCraftColors.softAmberText),
                            ),
                          ]),
                        ),
                      ...advances.take(3).map((a) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: GcUi.card(radius: 18),
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${a.amountRupees.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: GcUi.ink),
                                    ),
                                    Text(
                                      DateFormat('d MMM yyyy')
                                          .format(a.createdAt),
                                      style: const TextStyle(
                                          fontSize: 12, color: GcUi.muted),
                                    ),
                                  ],
                                ),
                              ),
                              GoldCraftBadge(
                                label:
                                    a.fullyRepaid ? 'Repaid' : 'Outstanding',
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

              _sectionTitle(Icons.work_outline_rounded, 'Job History', primary),
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
                              style: TextStyle(color: GcUi.muted)),
                        )
                      else
                        ...jobs.map((j) => _JobHistoryTile(job: j)),
                      const SizedBox(height: 12),
                      if (karagar.isActive)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: assignJob,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GcUi.goldDark,
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                  color: GcUi.goldDark, width: 1.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.add_task_rounded, size: 18),
                            label: Text(
                              jobs.isEmpty
                                  ? 'Assign First Job'
                                  : 'Assign Another Job',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) => Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: GcUi.ink)),
        ),
      ]);

  Widget _sectionTitle(IconData icon, String title, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: GcUi.ink)),
        ],
      );

  Widget _statCard(String label, String value, Color bg, Color fg) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GcUi.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: fg.withValues(alpha: 0.8))),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
              ),
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
        decoration: GcUi.card(radius: 18),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: GcUi.goldTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.diamond_outlined,
                color: GcUi.goldDark, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: GcUi.ink)),
                const SizedBox(height: 2),
                Text(
                  '#${job.jobNumber} · ${job.requiredWeightGrams.toStringAsFixed(1)} g',
                  style: const TextStyle(fontSize: 12, color: GcUi.muted),
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