import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/payroll_provider.dart';
import '../../domain/payroll_model.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../karagars/data/karagars_provider.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  // Holds newly paid payrolls injected immediately after payment
  // so the table updates without waiting for a re-fetch
  final List<Payroll> _pendingPayrolls = [];

  @override
  Widget build(BuildContext context) {
    final payrollsAsync = ref.watch(payrollsProvider(null));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('Salary History')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaySalarySheet(context),
        backgroundColor: GoldCraftColors.jewelryGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Pay Salary'),
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
          return RefreshIndicator(
            color: GoldCraftColors.jewelryGold,
            onRefresh: () async {
              setState(() => _pendingPayrolls.clear());
              ref.invalidate(payrollsProvider(null));
            },
            child: _SalaryTable(
              payrolls: merged,
              onRowTap: (p) => context.push('/payroll/${p.id}'),
            ),
          );
        },
      ),
    );
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
  DateTime _periodEnd   = DateTime.now();
  final _amountCtrl     = TextEditingController();
  bool _loading         = false;
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
    setState(() { _loading = true; _error = null; });
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
          content: Text('Salary of ₹${paid.paidRupees.toStringAsFixed(0)} paid to $_karagarName'),
          backgroundColor: GoldCraftColors.softGreenText,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
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

  @override
  Widget build(BuildContext context) {
    final karagarsAsync = ref.watch(karagarsProvider);
    final dateFmt = DateFormat('d MMM yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: GoldCraftColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: GoldCraftColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Pay Salary',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: GoldCraftColors.charcoal)),
          const SizedBox(height: 20),

          // Karagar selector
          const Text('Karagar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: GoldCraftColors.textSecondary)),
          const SizedBox(height: 8),
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
                items: active.map((k) => DropdownMenuItem(
                  value: k.id,
                  child: Text('${k.name} (${k.employeeCode})'),
                )).toList(),
                onChanged: (v) {
                  final k = active.firstWhere((k) => k.id == v);
                  setState(() { _karagarId = v; _karagarName = k.name; });
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Period
          const Text('Pay Period',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: GoldCraftColors.textSecondary)),
          const SizedBox(height: 8),
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
          const Text('Amount to Pay (₹)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: GoldCraftColors.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'e.g. 5000',
              prefixText: '₹ ',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(
                    color: GoldCraftColors.softRedText, fontSize: 13)),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: GoldCraftColors.jewelryGold,
                foregroundColor: Colors.black,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.payments_outlined),
              label: Text(_loading ? 'Processing...' : 'Generate & Pay'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GoldCraftColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: GoldCraftColors.textSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: GoldCraftColors.textSecondary)),
              Text(date,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: GoldCraftColors.charcoal)),
            ],
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

    // Summary totals row
    final totalGross = payrolls.fold(0.0, (s, p) => s + p.grossLaborRupees);
    final totalNet   = payrolls.fold(0.0, (s, p) => s + p.netPayableRupees);
    final totalPaid  = payrolls.fold(0.0, (s, p) => s + p.paidRupees);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Summary strip ───────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C1F0A), Color(0xFF4A3218)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            _summaryCell('Records',   '${payrolls.length}',                    Colors.white70, Colors.white),
            _summaryCell('Gross',     '₹${_fmt(totalGross)}',                  Colors.white70, Colors.white),
            _summaryCell('Net',       '₹${_fmt(totalNet)}',                    Colors.white70, GoldCraftColors.jewelryGold),
            _summaryCell('Paid',      '₹${_fmt(totalPaid)}',                   Colors.white70, const Color(0xFF81C784)),
          ]),
        ),

        // ── Table ───────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(GoldCraftColors.pureWhite),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return GoldCraftColors.jewelryGoldLight.withOpacity(0.3);
                    }
                    return GoldCraftColors.pureWhite;
                  }),
                  dividerThickness: 1,
                  columnSpacing: 20,
                  headingTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: GoldCraftColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 13,
                    color: GoldCraftColors.charcoal,
                  ),
                  border: TableBorder.all(
                    color: GoldCraftColors.divider,
                    borderRadius: BorderRadius.circular(14),
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

                    return DataRow(
                      onSelectChanged: onRowTap != null
                          ? (_) => onRowTap!(p)
                          : null,
                      cells: [
                        if (showKaragarColumn)
                          DataCell(
                            Text(p.karagarName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        DataCell(Text(period,
                            style: const TextStyle(
                                fontSize: 12,
                                color: GoldCraftColors.textSecondary))),
                        DataCell(Text(generated,
                            style: const TextStyle(
                                fontSize: 12,
                                color: GoldCraftColors.textSecondary))),
                        DataCell(Text('${p.jobsDone}')),
                        DataCell(Text('₹${_fmt(p.grossLaborRupees)}')),
                        DataCell(Text(
                          '₹${_fmt(p.netPayableRupees)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )),
                        DataCell(Text(
                          '₹${_fmt(p.paidRupees)}',
                          style: TextStyle(
                            color: p.paidRupees >= p.netPayableRupees
                                ? GoldCraftColors.softGreenText
                                : GoldCraftColors.softAmberText,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(GoldCraftBadge(
                            label: badgeLabel, type: badgeType)),
                      ],
                    );
                  }).toList(),
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
          Text(label,
              style: TextStyle(fontSize: 10, color: labelColor)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ]),
      );

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_IN').format(v.round());

  static (GoldCraftBadgeType, String) _badge(String status) =>
      switch (status) {
        'draft'         => (GoldCraftBadgeType.neutral, 'Draft'),
        'underReview'   => (GoldCraftBadgeType.info,    'Review'),
        'approved'      => (GoldCraftBadgeType.warning,  'Approved'),
        'partiallyPaid' => (GoldCraftBadgeType.warning,  'Partial'),
        'paid'          => (GoldCraftBadgeType.success,  'Paid'),
        _               => (GoldCraftBadgeType.neutral,  status),
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
