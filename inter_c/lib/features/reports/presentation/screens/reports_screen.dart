import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';

final _dashboardReportProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
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
    final isAdmin = ref.watch(authUserProvider).valueOrNull?.isAdmin == true;
    final primary = GcUi.primary(isAdmin);

    return GcScaffold(
      isAdmin: isAdmin,
      bottomNav: GcBottomNav(currentIndex: 4, isAdmin: isAdmin),
      header: GcPageHeader(
        title: 'Reports',
        onBack: () => context.go('/dashboard'),
      ),
      body: RefreshIndicator(
        color: GcUi.accent(isAdmin),
        onRefresh: () async {
          ref.invalidate(_dashboardReportProvider);
          ref.invalidate(_meltingGroupReportProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _sectionTitle(Icons.insights_rounded, 'Workshop Overview', primary),
            const SizedBox(height: 12),
            dashAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (data) => _DashboardReport(data: data, isAdmin: isAdmin),
            ),
            const SizedBox(height: 26),
            _sectionTitle(Icons.layers_outlined, 'By Melting Group', primary),
            const SizedBox(height: 12),
            meltingAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (groups) => Column(
                children: groups
                    .map((g) => _MeltingGroupTile(
                        group: g as Map<String, dynamic>, isAdmin: isAdmin))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: GcUi.ink)),
        ],
      );
}

class _DashboardReport extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isAdmin;
  const _DashboardReport({required this.data, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final jobs = data['jobs'] as Map<String, dynamic>? ?? {};
    final gold = data['gold'] as Map<String, dynamic>? ?? {};
    final advances = data['advances'] as Map<String, dynamic>? ?? {};
    final byStatus = jobs['byStatus'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        _card('Team & Jobs', Icons.groups_rounded, GcUi.greenTint,
            GcUi.primary(isAdmin), [
          _stat('Total Jobs', '${jobs['total'] ?? 0}'),
          _stat('Active Karagars', '${data['activeKaragars'] ?? 0}'),
          _stat('Pending Payrolls', '${data['pendingPayrolls'] ?? 0}'),
        ]),
        const SizedBox(height: 12),
        _card('Gold', Icons.layers_rounded, GcUi.goldTint, GcUi.goldDark, [
          _stat('Gold Issued',
              '${((gold['totalIssuedGrams'] as num? ?? 0)).toStringAsFixed(1)} g'),
          _stat('Returned',
              '${((gold['totalReturnedGrams'] as num? ?? 0)).toStringAsFixed(1)} g'),
          _stat('In Circulation',
              '${((gold['inCirculationGrams'] as num? ?? 0)).toStringAsFixed(1)} g'),
        ]),
        const SizedBox(height: 12),
        _card('Job Status', Icons.monitor_heart_outlined, GcUi.greenTint,
            GcUi.primary(isAdmin), [
          _stat('Assigned', '${byStatus['assigned'] ?? 0}'),
          _stat('In Progress', '${byStatus['inProgress'] ?? 0}'),
          _stat('Completed', '${byStatus['completed'] ?? 0}'),
        ]),
        const SizedBox(height: 12),
        _card('Advances', Icons.account_balance_wallet_outlined,
            GcUi.goldTint, GcUi.goldDark, [
          _stat('Outstanding Advances',
              '₹${((advances['totalOutstandingRupees'] as num? ?? 0)).toStringAsFixed(0)}'),
        ]),
      ],
    );
  }

  Widget _card(String title, IconData icon, Color bg, Color fg,
          List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: GcUi.card(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, color: fg, size: 19),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GcUi.muted)),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: children),
          ],
        ),
      );

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: GcUi.muted)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: GcUi.ink)),
            ),
          ],
        ),
      );
}

class _MeltingGroupTile extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isAdmin;
  const _MeltingGroupTile({required this.group, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: GcUi.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: GcUi.goldTint, shape: BoxShape.circle),
                child: const Icon(Icons.local_fire_department_outlined,
                    color: GcUi.goldDark, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(group['_id'] as String? ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: GcUi.ink)),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                style: const TextStyle(fontSize: 11, color: GcUi.muted)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: GcUi.ink)),
          ],
        ),
      );
}