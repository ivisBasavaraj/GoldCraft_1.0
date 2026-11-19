import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../material_issuance/data/issuance_provider.dart';
import '../../../material_receipts/data/receipts_provider.dart';
import '../../data/jobs_provider.dart';
import '../../domain/job_model.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../core/theme/colors.dart';
import 'karagar_home_screen.dart' show KaragarBottomNav;

class MyGoldScreen extends ConsumerStatefulWidget {
  const MyGoldScreen({super.key});

  @override
  ConsumerState<MyGoldScreen> createState() => _MyGoldScreenState();
}

class _MyGoldScreenState extends ConsumerState<MyGoldScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Job? _selectedJob;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _selectedJob = null));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(myJobsProvider);
    final issuancesAsync = ref.watch(myIssuancesProvider(null));
    final receiptsAsync = ref.watch(myReceiptsProvider(null));
    final jobNamesById = {
      for (final job in jobsAsync.valueOrNull ?? <Job>[]) job.id: job.title,
    };

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: const Text('Gold Given to Me'),
        bottom: TabBar(
          controller: _tab,
          labelColor: GoldCraftColors.jewelryGold,
          unselectedLabelColor: GoldCraftColors.textHint,
          indicatorColor: GoldCraftColors.jewelryGold,
          tabs: const [
            Tab(text: 'Issued to Me'),
            Tab(text: 'Returned'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Issued ──
          issuancesAsync.when(
            loading: () =>
                const GcLoadingIndicator(message: 'Loading records...'),
            error: (e, _) => GcErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(myIssuancesProvider(null)),
            ),
            data: (items) {
              final filtered = _selectedJob == null
                  ? items
                  : items
                      .where((i) => i.jobId == _selectedJob!.id)
                      .toList();
              final totalGrams =
                  filtered.fold(0.0, (s, i) => s + i.physicalWeightGrams);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Job filter dropdown
                  jobsAsync.whenData((jobs) => jobs).maybeWhen(
                        data: (jobs) => jobs.isEmpty
                            ? const SizedBox.shrink()
                            : _JobFilterDropdown(
                                jobs: jobs,
                                selected: _selectedJob,
                                onChanged: (j) =>
                                    setState(() => _selectedJob = j),
                              ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                  _summaryBanner('Total Issued', totalGrams,
                      GoldCraftColors.softAmberText),
                  Expanded(
                    child: filtered.isEmpty
                        ? const GcEmptyState(
                            icon: Icons.arrow_upward_rounded,
                            title: 'No Gold Issued',
                            subtitle: 'Gold issued to you will appear here.',
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _IssuedTable(
                              items: filtered,
                              jobNamesById: jobNamesById,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),

          // ── Returned ──
          receiptsAsync.when(
            loading: () =>
                const GcLoadingIndicator(message: 'Loading records...'),
            error: (e, _) => GcErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(myReceiptsProvider(null)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const GcEmptyState(
                  icon: Icons.arrow_downward_rounded,
                  title: 'No Gold Returned',
                  subtitle: 'Gold returned by you will appear here.',
                );
              }
              final totalGrams =
                  items.fold(0.0, (s, i) => s + i.physicalWeightGrams);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summaryBanner('Total Returned', totalGrams,
                      GoldCraftColors.softGreenText),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _GoldTable(
                        items: items
                            .map((i) => _GoldRow(
                                  txId: i.transactionId,
                                  jobId: i.jobId,
                                  jobTitle: i.jobTitle,
                                  weightGrams: i.physicalWeightGrams,
                                  isDebit: false,
                                  dateTime: i.createdAt,
                                  type: i.receiptType,
                                ))
                            .toList(),
                        jobNamesById: jobNamesById,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const KaragarBottomNav(currentIndex: 1),
    );
  }

  Widget _summaryBanner(String label, double grams, Color color) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GoldCraftColors.divider),
        ),
        child: Row(children: [
          Icon(Icons.scale_outlined, color: color, size: 22),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: GoldCraftColors.textSecondary)),
            Text('${grams.toStringAsFixed(3)} g',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          ]),
        ]),
      );
}

// ── Job Filter Dropdown ──────────────────────────────────────────────────────

class _JobFilterDropdown extends StatelessWidget {
  final List<Job> jobs;
  final Job? selected;
  final ValueChanged<Job?> onChanged;

  const _JobFilterDropdown({
    required this.jobs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldCraftColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Job?>(
          isExpanded: true,
          value: selected,
          hint: Row(children: const [
            Icon(Icons.filter_list_rounded,
                size: 16, color: GoldCraftColors.textSecondary),
            SizedBox(width: 8),
            Text('Filter by Job',
                style: TextStyle(
                    fontSize: 13, color: GoldCraftColors.textSecondary)),
          ]),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: GoldCraftColors.textSecondary),
          items: [
            const DropdownMenuItem<Job?>(
              value: null,
              child: Text('All Jobs',
                  style: TextStyle(
                      fontSize: 13, color: GoldCraftColors.textSecondary)),
            ),
            ...jobs.map((j) => DropdownMenuItem<Job?>(
                  value: j,
                  child: Text(
                    '${j.jobNumber} — ${j.title}',
                    style: const TextStyle(
                        fontSize: 13, color: GoldCraftColors.charcoal),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Issued Table (with Job Name column) ─────────────────────────────────────

class _IssuedTable extends StatelessWidget {
  final List items; // List<MaterialIssuance>
  final Map<String, String> jobNamesById;
  const _IssuedTable({required this.items, required this.jobNamesById});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final timeFmt = DateFormat('h:mm a');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(GoldCraftColors.background),
          dataRowColor: WidgetStateProperty.all(GoldCraftColors.pureWhite),
          dividerThickness: 1,
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: GoldCraftColors.textSecondary,
            letterSpacing: 0.4,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 12,
            color: GoldCraftColors.charcoal,
          ),
          border: TableBorder.all(
            color: GoldCraftColors.divider,
            borderRadius: BorderRadius.circular(12),
          ),
          columns: const [
            DataColumn(label: Text('TX ID')),
            DataColumn(label: Text('JOB')),
            DataColumn(label: Text('WEIGHT'), numeric: true),
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('TIME')),
          ],
          rows: items.map((i) {
            final jobLabel = (i.jobTitle != null && i.jobTitle!.isNotEmpty)
                ? i.jobTitle!
                : jobNamesById[i.jobId]?.isNotEmpty == true
                    ? jobNamesById[i.jobId]!
                : i.jobId.length > 8
                    ? '${i.jobId.substring(0, 8)}…'
                    : i.jobId;
            return DataRow(cells: [
              DataCell(Text(i.transactionId,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: GoldCraftColors.softAmberText))),
              DataCell(Text(jobLabel,
                  style: const TextStyle(
                      fontSize: 11, color: GoldCraftColors.textSecondary))),
              DataCell(Text(
                '${i.physicalWeightGrams.toStringAsFixed(3)} g',
                style: const TextStyle(fontWeight: FontWeight.w700),
              )),
              DataCell(Text(dateFmt.format(i.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: GoldCraftColors.textSecondary))),
              DataCell(Text(timeFmt.format(i.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: GoldCraftColors.textHint))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ── Generic Returned Table ───────────────────────────────────────────────────

class _GoldRow {
  final String txId;
  final String jobId;
  final String? jobTitle;
  final double weightGrams;
  final bool isDebit;
  final DateTime dateTime;
  final String? type;
  const _GoldRow({
    required this.txId,
    required this.jobId,
    this.jobTitle,
    required this.weightGrams,
    required this.isDebit,
    required this.dateTime,
    this.type,
  });
}

class _GoldTable extends StatelessWidget {
  final List<_GoldRow> items;
  final Map<String, String> jobNamesById;
  const _GoldTable({required this.items, required this.jobNamesById});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final timeFmt = DateFormat('h:mm a');
    final hasType = items.any((r) => r.type != null);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(GoldCraftColors.background),
          dataRowColor: WidgetStateProperty.all(GoldCraftColors.pureWhite),
          dividerThickness: 1,
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: GoldCraftColors.textSecondary,
            letterSpacing: 0.4,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 12,
            color: GoldCraftColors.charcoal,
          ),
          border: TableBorder.all(
            color: GoldCraftColors.divider,
            borderRadius: BorderRadius.circular(12),
          ),
          columns: [
            const DataColumn(label: Text('TX ID')),
            const DataColumn(label: Text('JOB')),
            const DataColumn(label: Text('WEIGHT'), numeric: true),
            if (hasType) const DataColumn(label: Text('TYPE')),
            const DataColumn(label: Text('DATE')),
            const DataColumn(label: Text('TIME')),
          ],
          rows: items.map((r) {
            final color = r.isDebit
                ? GoldCraftColors.softAmberText
                : GoldCraftColors.softGreenText;
            final jobLabel = (r.jobTitle?.isNotEmpty ?? false)
                ? r.jobTitle!
                : jobNamesById[r.jobId]?.isNotEmpty == true
                    ? jobNamesById[r.jobId]!
                    : r.jobId.length > 8
                        ? '${r.jobId.substring(0, 8)}…'
                        : r.jobId;
            return DataRow(cells: [
              DataCell(Text(r.txId,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color))),
              DataCell(Text(jobLabel,
                  style: const TextStyle(
                      fontSize: 11, color: GoldCraftColors.textSecondary))),
              DataCell(Text(
                '${r.weightGrams.toStringAsFixed(3)} g',
                style: const TextStyle(fontWeight: FontWeight.w700),
              )),
              if (hasType)
                DataCell(Text(r.type ?? '—',
                    style: const TextStyle(
                        fontSize: 11,
                        color: GoldCraftColors.textSecondary))),
              DataCell(Text(dateFmt.format(r.dateTime),
                  style: const TextStyle(
                      fontSize: 11, color: GoldCraftColors.textSecondary))),
              DataCell(Text(timeFmt.format(r.dateTime),
                  style: const TextStyle(
                      fontSize: 11, color: GoldCraftColors.textHint))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
