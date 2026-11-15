import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';

final _dashboardReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/reports/dashboard');
    final raw = (res.data as Map<String, dynamic>? ?? {});
    return raw['data'] as Map<String, dynamic>? ?? raw;
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

final _meltingGroupReportProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/reports/melting-groups');
    final raw = (res.data as Map<String, dynamic>? ?? {});
    return raw['data'] as List<dynamic>? ?? [];
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(_dashboardReportProvider);
    final meltingAsync = ref.watch(_meltingGroupReportProvider);

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(_dashboardReportProvider);
              ref.invalidate(_meltingGroupReportProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: GoldCraftColors.jewelryGold,
        onRefresh: () async {
          ref.invalidate(_dashboardReportProvider);
          ref.invalidate(_meltingGroupReportProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Workshop Overview'),
            const SizedBox(height: 12),
            dashAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (data) => _DashboardReport(data: data),
            ),
            const SizedBox(height: 28),
            _sectionTitle('By Melting Group'),
            const SizedBox(height: 12),
            meltingAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (groups) => Column(
                children: groups
                    .map((g) => _MeltingGroupTile(group: g as Map<String, dynamic>))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: GoldCraftColors.charcoal),
      );
}

class _DashboardReport extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DashboardReport({required this.data});

  @override
  Widget build(BuildContext context) {
    final jobs = data['jobs'] as Map<String, dynamic>? ?? {};
    final gold = data['gold'] as Map<String, dynamic>? ?? {};
    final advances = data['advances'] as Map<String, dynamic>? ?? {};
    final byStatus = jobs['byStatus'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        _card([
          _stat('Total Jobs', '${jobs['total'] ?? 0}'),
          _stat('Active Karagars', '${data['activeKaragars'] ?? 0}'),
          _stat('Pending Payrolls', '${data['pendingPayrolls'] ?? 0}'),
        ]),
        const SizedBox(height: 12),
        _card([
          _stat('Gold Issued', '${((gold['totalIssuedGrams'] as num? ?? 0)).toStringAsFixed(1)} g'),
          _stat('Returned', '${((gold['totalReturnedGrams'] as num? ?? 0)).toStringAsFixed(1)} g'),
          _stat('In Circulation', '${((gold['inCirculationGrams'] as num? ?? 0)).toStringAsFixed(1)} g'),
        ]),
        const SizedBox(height: 12),
        _card([
          _stat('Assigned', '${byStatus['assigned'] ?? 0}'),
          _stat('In Progress', '${byStatus['inProgress'] ?? 0}'),
          _stat('Completed', '${byStatus['completed'] ?? 0}'),
        ]),
        const SizedBox(height: 12),
        _card([
          _stat('Outstanding Advances',
              '₹${((advances['totalOutstandingRupees'] as num? ?? 0)).toStringAsFixed(0)}'),
        ]),
      ],
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GoldCraftColors.divider),
        ),
        child: Row(children: children),
      );

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: GoldCraftColors.textHint)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: GoldCraftColors.charcoal)),
          ],
        ),
      );
}

class _MeltingGroupTile extends StatelessWidget {
  final Map<String, dynamic> group;
  const _MeltingGroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GoldCraftColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group['_id'] as String? ?? 'Unknown',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GoldCraftColors.charcoal)),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('Total Jobs', '${group['totalJobs'] ?? 0}'),
              _stat('Active', '${group['activeJobs'] ?? 0}'),
              _stat('Completed', '${group['completedJobs'] ?? 0}'),
              _stat('Issued',
                  '${((group['totalIssuedGrams'] as num? ?? 0)).toStringAsFixed(1)} g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: GoldCraftColors.textHint)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GoldCraftColors.charcoal)),
          ],
        ),
      );
}
