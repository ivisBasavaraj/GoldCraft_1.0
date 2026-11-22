import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/payroll_provider.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../../core/theme/colors.dart';

class PayrollDetailScreen extends ConsumerWidget {
  final String payrollId;
  const PayrollDetailScreen({super.key, required this.payrollId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollAsync = ref.watch(payrollDetailProvider(payrollId));

    return GcScaffold(
      isAdmin: false,
      header: GcPageHeader(
        title: 'Payroll Detail',
        showBack: context.canPop(),
      ),
      body: payrollAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading payroll...'),
        error: (e, _) => GcErrorState(message: e.toString()),
        data: (payroll) {
          final fmt = DateFormat('d MMM yyyy');
          final (badgeType, badgeLabel) = switch (payroll.status) {
            'draft' => (GoldCraftBadgeType.neutral, 'Draft'),
            'underReview' => (GoldCraftBadgeType.info, 'Under Review'),
            'approved' => (GoldCraftBadgeType.warning, 'Approved'),
            'partiallyPaid' => (GoldCraftBadgeType.warning, 'Partial'),
            'paid' => (GoldCraftBadgeType.success, 'Paid'),
            _ => (GoldCraftBadgeType.neutral, payroll.status),
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ── Hero card ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: GcUi.heroGradient(false),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GcUi.greenDark.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(color: GcUi.gold, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            payroll.karagarName.isNotEmpty
                                ? payroll.karagarName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: GcUi.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(payroll.karagarName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.calendar_month_outlined,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${fmt.format(payroll.periodStart)} \u2013 ${fmt.format(payroll.periodEnd)}',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.white70),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      GoldCraftBadge(label: badgeLabel, type: badgeType),
                    ]),
                    const SizedBox(height: 18),
                    const Text('Net Payable',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '\u20b9${payroll.netPayableRupees.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: _heroStat('Paid',
                            '\u20b9${payroll.paidRupees.toStringAsFixed(0)}',
                            const Color(0xFF86EFAC)),
                      ),
                      Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _heroStat(
                          'Remaining',
                          '\u20b9${payroll.remainingRupees.toStringAsFixed(0)}',
                          payroll.remainingRupees > 0
                              ? GcUi.gold
                              : Colors.white,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Breakdown ──────────────────────────────────────────────
              _sectionTitle(Icons.receipt_long_outlined, 'Breakdown'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: GcUi.card(radius: 22),
                child: Column(
                  children: [
                    _row('Jobs Done', '${payroll.jobsDone}'),
                    _row('Gross Labor',
                        '\u20b9${payroll.grossLaborRupees.toStringAsFixed(0)}'),
                    _row('Incentive',
                        '+ \u20b9${payroll.approvedIncentiveRupees.toStringAsFixed(0)}',
                        color: GoldCraftColors.softGreenText),
                    _row('Penalty',
                        '- \u20b9${payroll.approvedPenaltyRupees.toStringAsFixed(0)}',
                        color: GoldCraftColors.softRedText),
                    _row('Advance Deduction',
                        '- \u20b9${payroll.advanceDeductionRupees.toStringAsFixed(0)}',
                        color: GoldCraftColors.softAmberText),
                    const Divider(height: 24, color: GcUi.border),
                    _row('Net Payable',
                        '\u20b9${payroll.netPayableRupees.toStringAsFixed(0)}',
                        bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Wastage ────────────────────────────────────────────────
              _sectionTitle(Icons.scale_outlined, 'Wastage'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: GcUi.card(radius: 22),
                child: Column(
                  children: [
                    _row('Allowed',
                        '${payroll.allowedWastageGrams.toStringAsFixed(2)} g'),
                    _row('Actual',
                        '${payroll.actualWastageGrams.toStringAsFixed(2)} g'),
                    _row(
                      'Status',
                      payroll.wastageStatus == 'withinAllowance'
                          ? 'Within Limit'
                          : 'Excess',
                      color: payroll.wastageStatus == 'withinAllowance'
                          ? GoldCraftColors.softGreenText
                          : GoldCraftColors.softRedText,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (payroll.status == 'draft' || payroll.status == 'underReview')
                _ApproveButton(payrollId: payrollId),
              if (payroll.status == 'approved' ||
                  payroll.status == 'partiallyPaid')
                _RecordPaymentButton(
                    payrollId: payrollId, remaining: payroll.remainingRupees),
            ],
          );
        },
      ),
    );
  }

  Widget _heroStat(String label, String value, Color valueColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: valueColor)),
          ),
        ],
      );

  Widget _sectionTitle(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: GcUi.greenDark, size: 24),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: GcUi.ink)),
        ],
      );

  Widget _row(String label, String value, {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: GcUi.muted)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? GcUi.ink)),
        ]),
      );
}

ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: GcUi.greenDark,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

class _ApproveButton extends ConsumerStatefulWidget {
  final String payrollId;
  const _ApproveButton({required this.payrollId});

  @override
  ConsumerState<_ApproveButton> createState() => _ApproveButtonState();
}

class _ApproveButtonState extends ConsumerState<_ApproveButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        style: _primaryButtonStyle(),
        onPressed: _loading
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _loading = true);
                try {
                  await ref
                      .read(payrollRepositoryProvider)
                      .approve(widget.payrollId);
                  ref.invalidate(payrollDetailProvider(widget.payrollId));
                  ref.invalidate(payrollsProvider(null));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Payroll approved')),
                  );
                } catch (e) {
                  messenger.showSnackBar(SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: GoldCraftColors.softRedText,
                  ));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('Approve Payroll'),
      ),
    );
  }
}

class _RecordPaymentButton extends ConsumerStatefulWidget {
  final String payrollId;
  final double remaining;
  const _RecordPaymentButton(
      {required this.payrollId, required this.remaining});

  @override
  ConsumerState<_RecordPaymentButton> createState() =>
      _RecordPaymentButtonState();
}

class _RecordPaymentButtonState extends ConsumerState<_RecordPaymentButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        style: _primaryButtonStyle(),
        onPressed: _loading
            ? null
            : () async {
                final ctrl = TextEditingController(
                    text: widget.remaining.toStringAsFixed(0));
                final messenger = ScaffoldMessenger.of(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    title: const Text('Record Payment',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: GcUi.ink)),
                    content: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Amount (\u20b9)', prefixText: '\u20b9 '),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GcUi.greenDark,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Record')),
                    ],
                  ),
                );
                if (confirmed != true) return;
                final amount = double.tryParse(ctrl.text.trim());
                if (amount == null || amount <= 0) return;
                setState(() => _loading = true);
                try {
                  await ref
                      .read(payrollRepositoryProvider)
                      .recordPayment(widget.payrollId, amount);
                  ref.invalidate(payrollDetailProvider(widget.payrollId));
                  ref.invalidate(payrollsProvider(null));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Payment recorded')),
                  );
                } catch (e) {
                  messenger.showSnackBar(SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: GoldCraftColors.softRedText,
                  ));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Record Payment'),
      ),
    );
  }
}