import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/payroll_provider.dart';
import '../../domain/payroll_model.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../karagars/data/karagars_provider.dart';

enum _SortBy { newest, oldest, netHigh, netLow, karagarAz }

const _sortLabels = {
  _SortBy.newest: 'Newest first',
  _SortBy.oldest: 'Oldest first',
  _SortBy.netHigh: 'Highest net pay',
  _SortBy.netLow: 'Lowest net pay',
  _SortBy.karagarAz: 'Karagar A–Z',
};

const _statusLabels = {
  'draft': 'Draft',
  'underReview': 'Under review',
  'approved': 'Approved',
  'partiallyPaid': 'Partially paid',
  'paid': 'Paid',
};

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  // Holds newly paid payrolls injected immediately after payment
  // so the table updates without waiting for a re-fetch
  final List<Payroll> _pendingPayrolls = [];

  // ── Filter state ───────────────────────────────────────────────────────────
  String? _karagarFilter; // karagar name
  String? _statusFilter; // payroll status key
  DateTimeRange? _dateRange; // filters on "generated" date
  _SortBy _sort = _SortBy.newest;

  bool get _hasActiveFilters =>
      _karagarFilter != null || _statusFilter != null || _dateRange != null;

  void _clearFilters() => setState(() {
        _karagarFilter = null;
        _statusFilter = null;
        _dateRange = null;
        _sort = _SortBy.newest;
      });

  List<Payroll> _applyFilters(List<Payroll> all) {
    final list = all.where((p) {
      if (_karagarFilter != null && p.karagarName != _karagarFilter) {
        return false;
      }
      if (_statusFilter != null && p.status != _statusFilter) return false;
      if (_dateRange != null) {
        final d =
            DateTime(p.createdAt.year, p.createdAt.month, p.createdAt.day);
        if (d.isBefore(_dateRange!.start) || d.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_sort) {
      case _SortBy.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortBy.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortBy.netHigh:
        list.sort((a, b) => b.netPayableRupees.compareTo(a.netPayableRupees));
      case _SortBy.netLow:
        list.sort((a, b) => a.netPayableRupees.compareTo(b.netPayableRupees));
      case _SortBy.karagarAz:
        list.sort((a, b) =>
            a.karagarName.toLowerCase().compareTo(b.karagarName.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final payrollsAsync = ref.watch(payrollsProvider(null));

    return GcScaffold(
      isAdmin: false,
      bottomNav: const GcBottomNav(currentIndex: -1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaySalarySheet(context),
        backgroundColor: GcUi.gold,
        foregroundColor: GcUi.ink,
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Pay Salary',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      header: GcPageHeader(
        title: 'Salary History',
        showBack: context.canPop(),
      ),
      body: payrollsAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading payrolls...'),
        error: (e, _) => GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(payrollsProvider(null)),
        ),
        data: (payrolls) {
          // Merge pending (newly paid) payrolls at the top, deduplicating by id
          final existingIds = payrolls.map((p) => p.id).toSet();
          final merged = [
            ..._pendingPayrolls.where((p) => !existingIds.contains(p.id)),
            ...payrolls,
          ];
          if (merged.isEmpty) {
            return const GcEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Payrolls',
              subtitle: 'Tap "Pay Salary" to generate a payroll.',
            );
          }

          final filtered = _applyFilters(merged);

          return Column(
            children: [
              _buildFilterBar(merged, filtered.length),
              Expanded(
                child: filtered.isEmpty
                    ? const GcEmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No Matching Records',
                        subtitle: 'Try changing or clearing your filters.',
                      )
                    : RefreshIndicator(
                        color: GcUi.green,
                        onRefresh: () async {
                          setState(() => _pendingPayrolls.clear());
                          ref.invalidate(payrollsProvider(null));
                        },
                        child: _SalaryTable(
                          payrolls: filtered,
                          onRowTap: (p) => context.push('/payroll/${p.id}'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar(List<Payroll> all, int shownCount) {
    final names = all.map((p) => p.karagarName).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: GcUi.card(radius: 24, color: GcUi.ivory),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  icon: Icons.person_outline_rounded,
                  label: _karagarFilter ?? 'All karagars',
                  active: _karagarFilter != null,
                  onTap: () => _pickKaragar(names),
                  onClear: () => setState(() => _karagarFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  icon: Icons.date_range_rounded,
                  label: _dateRange == null
                      ? 'Any date'
                      : _formatRange(_dateRange!),
                  active: _dateRange != null,
                  onTap: _pickDate,
                  onClear: () => setState(() => _dateRange = null),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  icon: Icons.flag_outlined,
                  label: _statusFilter == null
                      ? 'All status'
                      : _statusLabels[_statusFilter] ?? _statusFilter!,
                  active: _statusFilter != null,
                  onTap: _pickStatus,
                  onClear: () => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  icon: Icons.sort_rounded,
                  label: _sortLabels[_sort]!,
                  active: _sort != _SortBy.newest,
                  onTap: _pickSort,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Showing $shownCount of ${all.length} records',
                  style: const TextStyle(fontSize: 12, color: GcUi.muted),
                ),
              ),
              if (_hasActiveFilters || _sort != _SortBy.newest)
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: GcUi.goldDark,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRange(DateTimeRange r) {
    final f = DateFormat('d MMM');
    final fy = DateFormat('d MMM yy');
    if (r.start == r.end) return fy.format(r.start);
    return '${f.format(r.start)} – ${fy.format(r.end)}';
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<String?> _pickFromSheet({
    required String title,
    required List<(String, String)> options, // (key, label)
    required String? selectedKey,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: GcUi.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: GcUi.ink,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    for (final o in options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color:
                              o.$1 == selectedKey ? GcUi.greenTint : GcUi.ivory,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(ctx, o.$1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: o.$1 == selectedKey
                                      ? GcUi.green
                                      : GcUi.border,
                                  width: o.$1 == selectedKey ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                          o.$2,
                          style: TextStyle(
                                        fontSize: 15,
                            fontWeight: o.$1 == selectedKey
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: GcUi.ink,
                                      ),
                                    ),
                                  ),
                                  if (o.$1 == selectedKey)
                                    const Icon(Icons.check_circle_rounded,
                                        color: GcUi.green, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickKaragar(List<String> names) async {
    final key = await _pickFromSheet(
      title: 'Filter by Karagar',
      selectedKey: _karagarFilter ?? '__all__',
      options: [
        ('__all__', 'All karagars'),
        for (final n in names) (n, n),
      ],
    );
    if (key == null) return;
    setState(() => _karagarFilter = key == '__all__' ? null : key);
  }

  Future<void> _pickStatus() async {
    final key = await _pickFromSheet(
      title: 'Filter by Status',
      selectedKey: _statusFilter ?? '__all__',
      options: [
        ('__all__', 'All status'),
        for (final e in _statusLabels.entries) (e.key, e.value),
      ],
    );
    if (key == null) return;
    setState(() => _statusFilter = key == '__all__' ? null : key);
  }

  Future<void> _pickSort() async {
    final key = await _pickFromSheet(
      title: 'Sort by',
      selectedKey: _sort.name,
      options: [
        for (final e in _sortLabels.entries) (e.key.name, e.value),
      ],
    );
    if (key == null) return;
    setState(() => _sort = _SortBy.values.firstWhere((s) => s.name == key));
  }

  Future<void> _pickDate() async {
    final key = await _pickFromSheet(
      title: 'Filter by Date Generated',
      selectedKey: null,
      options: const [
        ('all', 'Any date'),
        ('today', 'Today'),
        ('7d', 'Last 7 days'),
        ('30d', 'Last 30 days'),
        ('thisMonth', 'This month'),
        ('lastMonth', 'Last month'),
        ('custom', 'Custom range…'),
      ],
    );
    if (key == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (key) {
      case 'all':
        setState(() => _dateRange = null);
      case 'today':
        setState(() => _dateRange = DateTimeRange(start: today, end: today));
      case '7d':
        setState(() => _dateRange = DateTimeRange(
            start: today.subtract(const Duration(days: 6)), end: today));
      case '30d':
        setState(() => _dateRange = DateTimeRange(
            start: today.subtract(const Duration(days: 29)), end: today));
      case 'thisMonth':
        setState(() => _dateRange = DateTimeRange(
            start: DateTime(today.year, today.month, 1), end: today));
      case 'lastMonth':
        setState(() => _dateRange = DateTimeRange(
              start: DateTime(today.year, today.month - 1, 1),
              end: DateTime(today.year, today.month, 0),
            ));
      case 'custom':
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: today,
          initialDateRange: _dateRange,
        );
        if (picked != null) setState(() => _dateRange = picked);
    }
  }

  void _showPaySalarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaySalarySheet(
        ref: ref,
        onPaid: (paid) {
          setState(() => _pendingPayrolls.insert(0, paid));
          // Also invalidate so background re-fetch updates eventually
          ref.invalidate(payrollsProvider(null));
        },
      ),
    );
  }
}

// ── Filter pill ───────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : GcUi.ink;

    return Material(
      color: active ? GcUi.greenDark : Colors.white,
      elevation: active ? 2 : 0,
      shadowColor: Colors.black26,
      shape: StadiumBorder(
        side: BorderSide(
          color: active ? GcUi.greenDark : GcUi.border,
          width: 1.2,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (active && onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded, size: 17, color: fg),
                )
              else
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pay Salary bottom sheet ───────────────────────────────────────────────────

class _PaySalarySheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final void Function(Payroll paid) onPaid;
  const _PaySalarySheet({required this.ref, required this.onPaid});

  @override
  ConsumerState<_PaySalarySheet> createState() => _PaySalarySheetState();
}

class _PaySalarySheetState extends ConsumerState<_PaySalarySheet> {
  String? _karagarId;
  String? _karagarName;
  DateTime _periodStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _periodEnd = DateTime.now();
  final _amountCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_karagarId == null) {
      setState(() => _error = 'Please select a karagar');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(payrollRepositoryProvider);
      // Single call: create payroll with paidRupees set immediately
      final paid = await repo.generate(
        karagarId: _karagarId!,
        periodStart: _periodStart.toIso8601String(),
        periodEnd: _periodEnd.toIso8601String(),
        amountRupees: amount,
      );
      if (!mounted) return;
      widget.onPaid(paid);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Salary of ₹${paid.paidRupees.toStringAsFixed(0)} paid to $_karagarName'),
          backgroundColor: GoldCraftColors.softGreenText,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _periodStart : _periodEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _periodStart = picked;
        } else {
          _periodEnd = picked;
        }
      });
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: GcUi.muted)),
      );

  @override
  Widget build(BuildContext context) {
    final karagarsAsync = ref.watch(karagarsProvider);
    final dateFmt = DateFormat('d MMM yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: GcUi.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: GcUi.greenTint, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.payments_rounded, color: GcUi.greenDark),
                ),
                const SizedBox(width: 14),
          const Text('Pay Salary',
              style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: GcUi.ink)),
              ],
            ),
          const SizedBox(height: 20),

          // Karagar selector
            _label('Karagar'),
          karagarsAsync.when(
            loading: () => const GcLoadingIndicator(),
            error: (e, _) => GcErrorState(message: e.toString()),
            data: (karagars) {
              final active = karagars.where((k) => k.isActive).toList();
              return DropdownButtonFormField<String>(
                value: _karagarId,
                decoration: const InputDecoration(
                  hintText: 'Select karagar',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                items: active
                    .map((k) => DropdownMenuItem(
                          value: k.id,
                          child: Text('${k.name} (${k.employeeCode})'),
                        ))
                    .toList(),
                onChanged: (v) {
                  final k = active.firstWhere((k) => k.id == v);
                  setState(() {
                    _karagarId = v;
                    _karagarName = k.name;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Period
            _label('Pay Period'),
          Row(children: [
            Expanded(
              child: _DateTile(
                label: 'From',
                date: dateFmt.format(_periodStart),
                onTap: () => _pickDate(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateTile(
                label: 'To',
                date: dateFmt.format(_periodEnd),
                onTap: () => _pickDate(false),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Amount
            _label('Amount to Pay (₹)'),
          TextFormField(
            controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'e.g. 5000',
              prefixText: '₹ ',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GoldCraftColors.softRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                style: const TextStyle(
                    color: GoldCraftColors.softRedText, fontSize: 13)),
              ),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
              height: 54,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: GcUi.greenDark,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 3,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.payments_outlined),
              label: Text(_loading ? 'Processing...' : 'Generate & Pay'),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: GcUi.card(radius: 16, color: GcUi.ivory),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 18, color: GcUi.greenDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                    style: const TextStyle(fontSize: 11, color: GcUi.muted)),
              Text(date,
                  style: const TextStyle(
                      fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: GcUi.ink)),
            ],
          ),
          ),
        ]),
      ),
    );
  }
}

// ── Shared salary table used by both manager and karagar ─────────────────────

class _SalaryTable extends StatelessWidget {
  final List<Payroll> payrolls;
  final void Function(Payroll)? onRowTap;
  final bool showKaragarColumn;

  const _SalaryTable({
    required this.payrolls,
    this.onRowTap,
    this.showKaragarColumn = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final shortFmt = DateFormat('d MMM yy');

    // Summary totals row (reflects whatever list is passed in, so it
    // updates automatically when filters are applied)
    final totalGross = payrolls.fold(0.0, (s, p) => s + p.grossLaborRupees);
    final totalNet = payrolls.fold(0.0, (s, p) => s + p.netPayableRupees);
    final totalPaid = payrolls.fold(0.0, (s, p) => s + p.paidRupees);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Summary strip ───────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: GcUi.heroGradient(false),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: GcUi.greenDark.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(children: [
            _summaryCell(
                'Records', '${payrolls.length}', Colors.white70, Colors.white),
            _summaryCell(
                'Gross', '₹${_fmt(totalGross)}', Colors.white70, Colors.white),
            _summaryCell(
                'Net', '₹${_fmt(totalNet)}', Colors.white70, GcUi.gold),
            _summaryCell('Paid', '₹${_fmt(totalPaid)}', Colors.white70,
                const Color(0xFF86EFAC)),
          ]),
        ),

        // ── Table ───────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: GcUi.card(radius: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(GcUi.greenDark),
                    dataRowColor: WidgetStateProperty.all(Colors.white),
                    dividerThickness: 1,
                    columnSpacing: 20,
                    headingTextStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    dataTextStyle:
                        const TextStyle(fontSize: 13, color: GcUi.ink),
                    border: const TableBorder(
                      horizontalInside: BorderSide(color: GcUi.border),
                    ),
                    columns: [
                      if (showKaragarColumn)
                        const DataColumn(label: Text('KARAGAR')),
                      const DataColumn(label: Text('PERIOD')),
                      const DataColumn(label: Text('GENERATED')),
                      const DataColumn(label: Text('JOBS'), numeric: true),
                      const DataColumn(label: Text('GROSS ₹'), numeric: true),
                      const DataColumn(label: Text('NET ₹'), numeric: true),
                      const DataColumn(label: Text('PAID ₹'), numeric: true),
                      const DataColumn(label: Text('STATUS')),
                    ],
                    rows: payrolls.map((p) {
                      final period =
                          '${shortFmt.format(p.periodStart)} – ${shortFmt.format(p.periodEnd)}';
                      final generated = dateFmt.format(p.createdAt);
                      final (badgeType, badgeLabel) = _badge(p.status);
                      final onTap =
                          onRowTap == null ? null : () => onRowTap!(p);

                      return DataRow(
                        cells: [
                          if (showKaragarColumn)
                            DataCell(
                              Text(
                                p.karagarName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              onTap: onTap,
                            ),
                          DataCell(
                            Text(
                              period,
                              style:
                                  const TextStyle(fontSize: 12, color: GcUi.muted),
                            ),
                            onTap: onTap,
                          ),
                          DataCell(
                            Text(
                              generated,
                              style:
                                  const TextStyle(fontSize: 12, color: GcUi.muted),
                            ),
                            onTap: onTap,
                          ),
                          DataCell(Text('${p.jobsDone}'), onTap: onTap),
                          DataCell(
                            Text('₹${_fmt(p.grossLaborRupees)}'),
                            onTap: onTap,
                          ),
                          DataCell(
                            Text(
                              '₹${_fmt(p.netPayableRupees)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800),
                            ),
                            onTap: onTap,
                          ),
                          DataCell(
                            Text(
                              '₹${_fmt(p.paidRupees)}',
                              style: TextStyle(
                                color: p.paidRupees >= p.netPayableRupees
                                    ? GoldCraftColors.softGreenText
                                    : GoldCraftColors.softAmberText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: onTap,
                          ),
                          DataCell(
                            GoldCraftBadge(
                                label: badgeLabel, type: badgeType),
                            onTap: onTap,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCell(
          String label, String value, Color labelColor, Color valueColor) =>
      Expanded(
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
              style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  color: valueColor)),
          ),
        ]),
      );

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_IN').format(v.round());

  static (GoldCraftBadgeType, String) _badge(String status) => switch (status) {
        'draft' => (GoldCraftBadgeType.neutral, 'Draft'),
        'underReview' => (GoldCraftBadgeType.info, 'Review'),
        'approved' => (GoldCraftBadgeType.warning, 'Approved'),
        'partiallyPaid' => (GoldCraftBadgeType.warning, 'Partial'),
        'paid' => (GoldCraftBadgeType.success, 'Paid'),
        _ => (GoldCraftBadgeType.neutral, status),
      };
}

// ── Karagar salary history table (used inside my_gold_screen tab) ─────────────

class KaragarSalaryTable extends ConsumerWidget {
  const KaragarSalaryTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollsAsync = ref.watch(myPayrollsProvider);

    return payrollsAsync.when(
      loading: () => const GcLoadingIndicator(message: 'Loading salary...'),
      error: (e, _) => GcErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(myPayrollsProvider),
      ),
      data: (payrolls) {
        if (payrolls.isEmpty) {
          return const GcEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No Salary Records',
            subtitle: 'Your salary history will appear here.',
          );
        }
        return _SalaryTable(
          payrolls: payrolls,
          showKaragarColumn: false, // karagar only sees own records
        );
      },
    );
  }
}
