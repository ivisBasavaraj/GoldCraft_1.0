import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/jobs_provider.dart';
import '../../domain/job_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_ui.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  String? _statusFilter;

  static const _statuses = [
    (null, 'All'),
    ('assigned', 'Assigned'),
    ('inProgress', 'In Progress'),
    ('qualityCheck', 'QC'),
    ('completed', 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(allJobsProvider(_statusFilter));
    // Used only to show the counts on the filter pills.
    final allJobs = ref.watch(allJobsProvider(null)).valueOrNull;
    final isAdmin = ref.watch(authUserProvider).valueOrNull?.isAdmin == true;

    return GcScaffold(
      isAdmin: isAdmin,
      bottomNav: GcBottomNav(currentIndex: 2, isAdmin: isAdmin),
      header: GcPageHeader(
        title: 'Jobs',
        onBack: () => context.go('/dashboard'),
        actions: [
          GcCircleButton(
            icon: Icons.add_rounded,
            tooltip: 'New job',
            color: GcUi.primary(isAdmin),
            onPressed: () => context.push('/jobs/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(allJobs, isAdmin),
          Expanded(
            child: jobsAsync.when(
              loading: () =>
                  const GcLoadingIndicator(message: 'Loading jobs...'),
              error: (e, _) => GcErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(allJobsProvider(_statusFilter)),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return const GcEmptyState(
                    icon: Icons.work_outline_rounded,
                    title: 'No Jobs Found',
                    subtitle: 'Try a different filter or assign a new job.',
                  );
                }
                return RefreshIndicator(
                  color: GcUi.accent(isAdmin),
                  onRefresh: () async =>
                      ref.invalidate(allJobsProvider(_statusFilter)),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _JobListTile(job: jobs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _label(String base, String? key, List<Job>? all) {
    if (all == null) return base;
    final n = key == null
        ? all.length
        : all.where((j) => j.status.name == key).length;
    return '$base ($n)';
  }

  Widget _buildFilterBar(List<Job>? all, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(6),
      decoration: GcUi.card(radius: 30, color: GcUi.ivory),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statuses
              .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _StatusPill(
                      label: _label(s.$2, s.$1, all),
                      selected: _statusFilter == s.$1,
                      primary: GcUi.primary(isAdmin),
                      onTap: () => setState(() => _statusFilter = s.$1),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Filter pill (all colours set explicitly so text is always visible)
// -----------------------------------------------------------------------------
class _StatusPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? primary : Colors.white;
    final Color border = selected ? primary : GcUi.border;
    final Color textColor = selected ? Colors.white : GcUi.ink;

    return Material(
      color: bg,
      elevation: selected ? 2 : 0,
      shadowColor: Colors.black26,
      shape: StadiumBorder(side: BorderSide(color: border, width: 1.2)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 18, color: textColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Job card with a coloured accent strip (gold, or red-orange when overdue)
// -----------------------------------------------------------------------------
class _JobListTile extends StatelessWidget {
  final Job job;
  const _JobListTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final isOverdue = job.dueDate.isBefore(DateTime.now()) &&
        job.status != JobStatus.completed &&
        job.status != JobStatus.cancelled;
    final accent = isOverdue ? const Color(0xFFE2571F) : GcUi.gold;
    final dueColor = isOverdue ? GoldCraftColors.softRedText : GcUi.muted;

    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        decoration: GcUi.card(radius: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: GcUi.goldTint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.diamond_outlined,
                              color: GcUi.goldDark, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(job.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: GcUi.ink)),
                                  ),
                                  _statusBadge(job.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 17, color: GcUi.muted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${job.karagarName} · #${job.jobNumber}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13, color: GcUi.muted),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_outlined,
                                      size: 17, color: dueColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Due ${DateFormat('d MMM').format(job.dueDate)}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: dueColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: GcUi.ink, size: 26),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(JobStatus status) {
    final (type, label) = switch (status) {
      JobStatus.assigned => (GoldCraftBadgeType.info, 'Assigned'),
      JobStatus.inProgress => (GoldCraftBadgeType.warning, 'In Progress'),
      JobStatus.qualityCheck => (GoldCraftBadgeType.warning, 'QC'),
      JobStatus.completed => (GoldCraftBadgeType.success, 'Done'),
      JobStatus.cancelled => (GoldCraftBadgeType.error, 'Cancelled'),
    };
    return GoldCraftBadge(label: label, type: type);
  }
}