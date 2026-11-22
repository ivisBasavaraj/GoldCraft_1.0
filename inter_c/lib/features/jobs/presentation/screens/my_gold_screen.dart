import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../material_issuance/data/issuance_provider.dart';
import '../../../material_receipts/data/receipts_provider.dart';
import '../../data/jobs_provider.dart';
import '../../domain/job_model.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
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

    return GcScaffold(
      isAdmin: false,
      bottomNav: const KaragarBottomNav(currentIndex: 1),
      header: GcPageHeader(
        title: 'Gold Given to Me',
        showBack: context.canPop(),
      ),
      body: Column(
        children: [
          GcSegmentToggle(
            labels: const ['Issued to Me', 'Returned'],
            icons: const [Icons.diamond_outlined, Icons.reply_rounded],
            index: _tab.index,
            onChanged: (i) => _tab.animateTo(i),
          ),
          Expanded(
            child: TabBarView(
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
                    final totalGrams = filtered.fold(
                        0.0, (s, i) => s + i.physicalWeightGrams);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _jobFilter(jobsAsync),
                        _summaryBanner('Total Issued', totalGrams),
                        Expanded(
                          child: filtered.isEmpty
                              ? const GcEmptyState(
                                  icon: Icons.arrow_upward_rounded,
                                  title: 'No Gold Issued',
                                  subtitle:
                                      'Gold issued to you will appear here.',
                                )
                              : SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                  child: Column(
                                    children: [
                                      _IssuedTable(
                                        items: filtered,
                                        jobNamesById: jobNamesById,
                                      ),
                                      const SizedBox(height: 12),
                                      const _InfoNote(
                                          'Total weight includes all gold issued to you across all jobs.'),
                                    ],
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
                    final filtered = _selectedJob == null
                        ? items
                        : items
                            .where((i) => i.jobId == _selectedJob!.id)
                            .toList();
                    final totalGrams = filtered.fold(
                        0.0, (s, i) => s + i.physicalWeightGrams);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _jobFilter(jobsAsync),
                        _summaryBanner('Total Returned', totalGrams),
                        Expanded(
                          child: filtered.isEmpty
                              ? const GcEmptyState(
                                  icon: Icons.arrow_downward_rounded,
                                  title: 'No Gold Returned',
                                  subtitle: 'No returns for the selected job.',
                                )
                              : SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                  child: _GoldTable(
                                    items: filtered
                                        .map((i) => _GoldRow(
                                              txId: i.transactionId,
                                              jobId: i.jobId,
                                              jobTitle: i.jobTitle,
                                              weightGrams:
                                                  i.physicalWeightGrams,
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
          ),
        ],
      ),
    );
  }

  /// Same job filter on both tabs (hidden when there are no jobs).
  Widget _jobFilter(AsyncValue<List<Job>> jobsAsync) {
    final jobs = jobsAsync.valueOrNull ?? const <Job>[];
    if (jobs.isEmpty) return const SizedBox.shrink();
    return _JobFilterDropdown(
      jobs: jobs,
      selected: _selectedJob,
      onChanged: (j) => setState(() => _selectedJob = j),
    );
  }

  Widget _summaryBanner(String label, double grams) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF0E6B43), Color(0xFF083D28)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: GcUi.greenDark.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: GcUi.gold, width: 1.5),
            ),
            child: const Icon(Icons.layers_rounded, color: GcUi.gold, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.white70)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('${grams.toStringAsFixed(3)} g',
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ]),
          ),
        ]),
      );
}

class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: GcUi.card(radius: 20, color: GcUi.ivory),
        child: Row(children: [
          const Icon(Icons.info_rounded, color: GcUi.greenDark, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: GcUi.ink)),
          ),
        ]),
      );
}

// ── Job Filter (card + bottom-sheet picker) ──────────────────────────────────

class _Pick {
  final Job? job; // null = "All Jobs"
  const _Pick(this.job);
}

class _JobFilterDropdown extends StatelessWidget {
  final List<Job> jobs;
  final Job? selected;
  final ValueChanged<Job?> onChanged;

  const _JobFilterDropdown({
    required this.jobs,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<_Pick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _JobPickerSheet(jobs: jobs, selectedId: selected?.id),
    );
    if (result != null) onChanged(result.job);
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = selected != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: isFiltered ? GcUi.greenTint : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isFiltered ? GcUi.green : GcUi.border,
            width: isFiltered ? 1.5 : 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFiltered ? GcUi.greenDark : GcUi.greenTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.filter_list_rounded,
                      color: isFiltered ? Colors.white : GcUi.greenDark,
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FILTER BY JOB',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: GcUi.muted)),
                      const SizedBox(height: 2),
                      Text(
                        isFiltered
                            ? '${selected!.jobNumber} — ${selected!.title}'
                            : 'All Jobs',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: GcUi.ink),
                      ),
                    ],
                  ),
                ),
                if (isFiltered)
                  IconButton(
                    tooltip: 'Clear filter',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded,
                        color: GcUi.greenDark, size: 22),
                    onPressed: () => onChanged(null),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GcUi.goldTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${jobs.length}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: GcUi.goldDark)),
                  ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: GcUi.ink, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobPickerSheet extends StatelessWidget {
  final List<Job> jobs;
  final String? selectedId;
  const _JobPickerSheet({required this.jobs, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.6;

    Widget option({
      required IconData icon,
      required String title,
      String? subtitle,
      required bool selected,
      required Job? job,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: selected ? GcUi.greenTint : GcUi.ivory,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pop(context, _Pick(job)),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: selected ? GcUi.green : GcUi.border,
                      width: selected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected ? GcUi.greenDark : GcUi.goldTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          size: 22,
                          color: selected ? Colors.white : GcUi.goldDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: GcUi.ink)),
                          if (subtitle != null)
                            Text(subtitle,
                                style: const TextStyle(
                                    fontSize: 12, color: GcUi.muted)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: GcUi.green, size: 24),
                  ],
                ),
              ),
            ),
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GcUi.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Filter by Job',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: GcUi.ink)),
            const SizedBox(height: 2),
            Text('${jobs.length} job${jobs.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 13, color: GcUi.muted)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: ListView(
                shrinkWrap: true,
                children: [
                  option(
                    icon: Icons.layers_outlined,
                    title: 'All Jobs',
                    selected: selectedId == null,
                    job: null,
                  ),
                  ...jobs.map((j) => option(
                        icon: Icons.diamond_outlined,
                        title: j.title,
                        subtitle: 'Job #${j.jobNumber}',
                        selected: selectedId == j.id,
                        job: j,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared table styling ─────────────────────────────────────────────────────

Widget _styledTable({
  required List<DataColumn> columns,
  required List<DataRow> rows,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Container(
      decoration: GcUi.card(radius: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(GcUi.greenDark),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          dividerThickness: 1,
          columnSpacing: 18,
          headingTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          dataTextStyle: const TextStyle(fontSize: 12, color: GcUi.ink),
          border: const TableBorder(
            horizontalInside: BorderSide(color: GcUi.border),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    ),
  );
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

    return _styledTable(
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
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: GcUi.goldDark))),
          DataCell(Text(jobLabel, style: const TextStyle(fontSize: 12))),
          DataCell(Text(
            '${i.physicalWeightGrams.toStringAsFixed(3)} g',
            style: const TextStyle(fontWeight: FontWeight.w800),
          )),
          DataCell(Text(dateFmt.format(i.createdAt),
              style: const TextStyle(fontSize: 12, color: GcUi.muted))),
          DataCell(Text(timeFmt.format(i.createdAt),
              style: const TextStyle(fontSize: 12, color: GcUi.muted))),
        ]);
      }).toList(),
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

    return _styledTable(
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
                  fontSize: 12, fontWeight: FontWeight.w800, color: color))),
          DataCell(Text(jobLabel, style: const TextStyle(fontSize: 12))),
          DataCell(Text(
            '${r.weightGrams.toStringAsFixed(3)} g',
            style: const TextStyle(fontWeight: FontWeight.w800),
          )),
          if (hasType)
            DataCell(Text(r.type ?? '—',
                style: const TextStyle(fontSize: 12, color: GcUi.muted))),
          DataCell(Text(dateFmt.format(r.dateTime),
              style: const TextStyle(fontSize: 12, color: GcUi.muted))),
          DataCell(Text(timeFmt.format(r.dateTime),
              style: const TextStyle(fontSize: 12, color: GcUi.muted))),
        ]);
      }).toList(),
    );
  }
}