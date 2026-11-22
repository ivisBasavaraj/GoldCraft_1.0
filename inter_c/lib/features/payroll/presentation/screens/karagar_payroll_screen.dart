import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/payroll_provider.dart';
import '../../../advances/data/advances_provider.dart';
import '../../../advances/domain/advance_model.dart';
import '../../domain/payroll_model.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../../core/theme/colors.dart';
import '../../../../features/jobs/presentation/screens/karagar_home_screen.dart'
    show KaragarBottomNav;

enum _Range { all, thisMonth, last30, last3Months, custom }

class KaragarPayrollScreen extends ConsumerStatefulWidget {
  const KaragarPayrollScreen({super.key});

  @override
  ConsumerState<KaragarPayrollScreen> createState() =>
      _KaragarPayrollScreenState();
}

class _KaragarPayrollScreenState extends ConsumerState<KaragarPayrollScreen> {
  int _tab = 0; // 0 = Salary History (default), 1 = Advances
  _Range _range = _Range.all;
  DateTimeRange? _custom;

  // ── Date filtering / sorting ────────────────────────────────────────────

  DateTimeRange? _activeRange() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_range) {
      case _Range.all:
        return null;
      case _Range.thisMonth:
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1), end: endOfToday);
      case _Range.last30:
        return DateTimeRange(
            start: DateTime(now.year, now.month, now.day)
                .subtract(const Duration(days: 30)),
            end: endOfToday);
      case _Range.last3Months:
        return DateTimeRange(
            start: DateTime(now.year, now.month - 3, now.day), end: endOfToday);
      case _Range.custom:
        final c = _custom;
        if (c == null) return null;
        return DateTimeRange(
          start: c.start,
          end: DateTime(c.end.year, c.end.month, c.end.day, 23, 59, 59),
        );
    }
  }

  List<T> _apply<T>(List<T> items, DateTime Function(T) dateOf) {
    final r = _activeRange();
    final out = items.where((e) {
      if (r == null) return true;
      final d = dateOf(e);
      return !d.isBefore(r.start) && !d.isAfter(r.end);
    }).toList();
    out.sort((a, b) => dateOf(b).compareTo(dateOf(a)));
    return out;
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _custom,
    );
    if (picked != null) {
      setState(() {
        _custom = picked;
        _range = _Range.custom;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final payrollsAsync = ref.watch(myPayrollsProvider);
    final advancesAsync = ref.watch(myAdvancesProvider);

    return GcScaffold(
      isAdmin: false,
      bottomNav: const KaragarBottomNav(currentIndex: 2),
      header: GcPageHeader(
        title: 'My Earnings',
        showBack: context.canPop(),
      ),
      body: Column(
        children: [
          GcSegmentToggle(
            labels: const ['Salary History', 'Advances'],
            icons: const [
              Icons.payments_outlined,
              Icons.currency_rupee_rounded
            ],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              color: GcUi.green,
              onRefresh: () async {
                ref.invalidate(myPayrollsProvider);
                ref.invalidate(myAdvancesProvider);
              },
              child: _tab == 0
                  ? _salaryList(payrollsAsync)
                  : _advanceList(advancesAsync),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    final fmt = DateFormat('d MMM');
    final customLabel = (_range == _Range.custom && _custom != null)
        ? '${fmt.format(_custom!.start)} – ${fmt.format(_custom!.end)}'
        : 'Custom';

    final presets = <(_Range, String)>[
      (_Range.all, 'All time'),
      (_Range.thisMonth, 'This month'),
      (_Range.last30, 'Last 30 days'),
      (_Range.last3Months, 'Last 3 months'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in presets)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterPill(
                        label: p.$2,
                        selected: _range == p.$1,
                        onTap: () => setState(() => _range = p.$1),
                      ),
                    ),
                  _FilterPill(
                    label: customLabel,
                    icon: Icons.date_range_rounded,
                    selected: _range == _Range.custom,
                    onTap: _pickCustom,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Salary tab ──────────────────────────────────────────────────────────

  Widget _salaryList(AsyncValue<List<Payroll>> async) {
    return async.when(
      loading: () => _scroll(
          const [GcLoadingIndicator(message: 'Loading salary...')]),
      error: (e, _) => _scroll([
        GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(myPayrollsProvider),
        )
      ]),
      data: (all) {
        if (all.isEmpty) {
          return _scroll(const [
            _EmptyCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'No salary records yet.',
            )
          ]);
        }
        final payrolls = _apply<Payroll>(all, (p) => p.periodEnd);
        if (payrolls.isEmpty) return _scroll([_noMatch()]);
        final totalPaid = payrolls.fold(0.0, (s, p) => s + p.paidRupees);
        return _scroll([
          _summaryBanner(
            'Total Paid',
            '₹${_fmt(totalPaid)}',
            Icons.payments_rounded,
            filled: true,
          ),
          const SizedBox(height: 12),
          ...payrolls.map((p) => _SalaryCard(payroll: p)),
        ]);
      },
    );
  }

  // ── Advances tab ────────────────────────────────────────────────────────

  Widget _advanceList(AsyncValue<List<Advance>> async) {
    return async.when(
      loading: () => _scroll(
          const [GcLoadingIndicator(message: 'Loading advances...')]),
      error: (e, _) => _scroll([
        GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(myAdvancesProvider),
        )
      ]),
      data: (all) {
        if (all.isEmpty) {
          return _scroll(const [
            _EmptyCard(
              icon: Icons.payments_outlined,
              label: 'No advances disbursed yet.',
            )
          ]);
        }
        final advances = _apply<Advance>(all, (a) => a.createdAt);
        if (advances.isEmpty) return _scroll([_noMatch()]);
        final totalOutstanding = advances
            .where((a) => !a.fullyRepaid)
            .fold(0.0, (s, a) => s + a.outstandingRupees);
        return _scroll([
          if (totalOutstanding > 0) ...[
            _summaryBanner(
              'Outstanding Balance',
              '₹${_fmt(totalOutstanding)}',
              Icons.warning_amber_rounded,
              filled: false,
            ),
            const SizedBox(height: 12),
          ],
          ...advances.map((a) => _AdvanceCard(advance: a)),
        ]);
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _scroll(List<Widget> children) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: children,
      );

  Widget _noMatch() => const _EmptyCard(
        icon: Icons.event_busy_rounded,
        label: 'No records in the selected date range.',
      );

  Widget _summaryBanner(String label, String value, IconData icon,
      {required bool filled}) {
    final fg = filled ? Colors.white : GoldCraftColors.softAmberText;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: filled
            ? const LinearGradient(
                colors: [Color(0xFF0E6B43), Color(0xFF083D28)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: filled ? null : GcUi.goldTint,
        border: filled ? null : Border.all(color: GcUi.border),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: GcUi.greenDark.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.7),
            border: Border.all(color: GcUi.gold, width: 1.5),
          ),
          child: Icon(icon, color: filled ? GcUi.gold : fg, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        color: filled ? Colors.white70 : fg.withValues(alpha: 0.8))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: fg)),
                ),
              ]),
        ),
      ]),
    );
  }

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_IN').format(v.round());
}

// -----------------------------------------------------------------------------
// Filter pill
// -----------------------------------------------------------------------------
class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : GcUi.ink;
    return Material(
      color: selected ? GcUi.greenDark : Colors.white,
      elevation: selected ? 2 : 0,
      shadowColor: Colors.black26,
      shape: StadiumBorder(
        side: BorderSide(
            color: selected ? GcUi.greenDark : GcUi.border, width: 1.2),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Salary card
// -----------------------------------------------------------------------------
class _SalaryCard extends StatelessWidget {
  final Payroll payroll;
  const _SalaryCard({required this.payroll});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final shortFmt = DateFormat('d MMM yy');
    final period =
        '${shortFmt.format(payroll.periodStart)} – ${shortFmt.format(payroll.periodEnd)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: GcUi.card(radius: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: GcUi.gold),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.calendar_month_outlined,
                            size: 20, color: GcUi.goldDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(period,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: GcUi.ink)),
                        ),
                        _statusBadge(payroll.status),
                      ]),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: GcUi.border),
                      const SizedBox(height: 10),
                      Row(children: [
                        _stat('Paid', '₹${_fmt(payroll.paidRupees)}',
                            GoldCraftColors.softGreenText),
                        _stat('Net Payable',
                            '₹${_fmt(payroll.netPayableRupees)}', GcUi.ink),
                        _stat('Generated', dateFmt.format(payroll.createdAt),
                            GcUi.muted),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: GcUi.muted)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ]),
      );

  GoldCraftBadge _statusBadge(String status) {
    final (type, label) = switch (status) {
      'paid' => (GoldCraftBadgeType.success, 'Paid'),
      'partiallyPaid' => (GoldCraftBadgeType.warning, 'Partial'),
      'approved' => (GoldCraftBadgeType.info, 'Approved'),
      _ => (GoldCraftBadgeType.neutral, 'Pending'),
    };
    return GoldCraftBadge(label: label, type: type);
  }

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_IN').format(v.round());
}

// -----------------------------------------------------------------------------
// Advance card
// -----------------------------------------------------------------------------
class _AdvanceCard extends StatelessWidget {
  final Advance advance;
  const _AdvanceCard({required this.advance});

  @override
  Widget build(BuildContext context) {
    final repaid = advance.fullyRepaid;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: GcUi.card(radius: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                  width: 5,
                  color: repaid ? GcUi.green : const Color(0xFFE2571F)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: repaid
                            ? GoldCraftColors.softGreen
                            : GoldCraftColors.softAmber,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        repaid
                            ? Icons.check_circle_outline_rounded
                            : Icons.currency_rupee_rounded,
                        color: repaid
                            ? GoldCraftColors.softGreenText
                            : GoldCraftColors.softAmberText,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                '₹${_fmt(advance.amountRupees)}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: GcUi.ink),
                              ),
                            ),
                            GoldCraftBadge(
                              label: repaid ? 'Repaid' : 'Outstanding',
                              type: repaid
                                  ? GoldCraftBadgeType.success
                                  : GoldCraftBadgeType.warning,
                            ),
                          ]),
                          const SizedBox(height: 4),
                          if (!repaid)
                            Text(
                              'Outstanding: ₹${_fmt(advance.outstandingRupees)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: GoldCraftColors.softAmberText),
                            ),
                          Text(
                            '${advance.transactionId} · ${DateFormat('d MMM yyyy').format(advance.createdAt)}',
                            style: const TextStyle(
                                fontSize: 12, color: GcUi.muted),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_IN').format(v.round());
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GcUi.card(radius: 20, color: GcUi.ivory),
      child: Row(children: [
        Icon(icon, size: 24, color: GcUi.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 14, color: GcUi.muted)),
        ),
      ]),
    );
  }
}