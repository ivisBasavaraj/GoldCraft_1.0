import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/jobs_provider.dart';
import '../../domain/job_model.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';

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

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: const Text('Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/jobs/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: jobsAsync.when(
              loading: () => const GcLoadingIndicator(message: 'Loading jobs...'),
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
                  color: GoldCraftColors.jewelryGold,
                  onRefresh: () async =>
                      ref.invalidate(allJobsProvider(_statusFilter)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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

  Widget _buildFilterBar() {
    return Container(
      color: GoldCraftColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statuses
              .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.$2),
                      selected: _statusFilter == s.$1,
                      onSelected: (_) =>
                          setState(() => _statusFilter = s.$1),
                      selectedColor: GoldCraftColors.jewelryGoldLight,
                      checkmarkColor: GoldCraftColors.jewelryGoldDark,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _JobListTile extends StatelessWidget {
  final Job job;
  const _JobListTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final isOverdue = job.dueDate.isBefore(DateTime.now()) &&
        job.status != JobStatus.completed &&
        job.status != JobStatus.cancelled;

    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GoldCraftColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: GoldCraftColors.jewelryGoldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.diamond_outlined,
                  color: GoldCraftColors.jewelryGoldDark, size: 24),
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
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: GoldCraftColors.charcoal)),
                      ),
                      _statusBadge(job.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                  '${job.karagarName} · #${job.jobNumber}',
                  style: const TextStyle(
                      fontSize: 12, color: GoldCraftColors.textSecondary),
                ),
                  const SizedBox(height: 4),
                  Text(
                    'Due ${DateFormat('d MMM').format(job.dueDate)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isOverdue
                            ? GoldCraftColors.softRedText
                            : GoldCraftColors.textHint),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: GoldCraftColors.textHint),
          ],
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
