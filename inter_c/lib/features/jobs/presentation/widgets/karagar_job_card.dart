import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../jobs/domain/job_model.dart';
import '../../../../core/theme/colors.dart';

class KaragarJobCard extends StatelessWidget {
  final Job job;

  const KaragarJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GoldCraftColors.divider),
          boxShadow: const [
            BoxShadow(
              color: GoldCraftColors.shadowLight,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: GoldCraftColors.divider),
            _buildGoldInfo(),
            const Divider(height: 1, color: GoldCraftColors.divider),
            _buildStatusAndAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: GoldCraftColors.jewelryGoldLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.diamond_outlined,
              color: GoldCraftColors.jewelryGoldDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: GoldCraftColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Job #${job.jobNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: GoldCraftColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigned: ${DateFormat('d MMM yyyy, h:mm a').format(job.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: GoldCraftColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldInfo() {
    final dueDate = DateFormat('d MMM').format(job.dueDate);
    final isOverdue = job.dueDate.isBefore(DateTime.now()) &&
        job.status != JobStatus.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gold Given',
                  style: TextStyle(
                    fontSize: 12,
                    color: GoldCraftColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: job.issuedWeightGrams.toStringAsFixed(3),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: GoldCraftColors.charcoal,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const TextSpan(
                        text: ' g',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: GoldCraftColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: GoldCraftColors.divider),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Due Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: GoldCraftColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueDate,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isOverdue
                          ? GoldCraftColors.softRedText
                          : GoldCraftColors.charcoal,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndAction(BuildContext context) {
    final (statusBg, statusFg, statusIcon, statusText) = _statusStyle();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 18, color: statusFg),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusFg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action button
          if (_showActionButton())
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push('/jobs/${job.id}'),
                child: Text(_actionLabel()),
              ),
            ),
        ],
      ),
    );
  }

  (Color, Color, IconData, String) _statusStyle() {
    return switch (job.status) {
      JobStatus.assigned => (
          GoldCraftColors.softBlue,
          GoldCraftColors.softBlueText,
          Icons.assignment_outlined,
          'Assigned — Ready to Start',
        ),
      JobStatus.inProgress => (
          GoldCraftColors.softAmber,
          GoldCraftColors.softAmberText,
          Icons.access_time_rounded,
          'Work in Progress',
        ),
      JobStatus.qualityCheck => (
          GoldCraftColors.softAmber,
          GoldCraftColors.softAmberText,
          Icons.hourglass_top_rounded,
          'Waiting for Checking',
        ),
      JobStatus.completed => (
          GoldCraftColors.softGreen,
          GoldCraftColors.softGreenText,
          Icons.check_circle_outline_rounded,
          'Completed',
        ),
      JobStatus.cancelled => (
          GoldCraftColors.softRed,
          GoldCraftColors.softRedText,
          Icons.cancel_outlined,
          'Cancelled',
        ),
    };
  }

  bool _showActionButton() =>
      job.status == JobStatus.assigned || job.status == JobStatus.inProgress;

  String _actionLabel() => switch (job.status) {
        JobStatus.assigned => 'VIEW MY WORK',
        JobStatus.inProgress => 'UPDATE PROGRESS',
        _ => 'VIEW DETAILS',
      };
}
