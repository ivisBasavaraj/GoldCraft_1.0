import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/payroll_provider.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../core/theme/colors.dart';

class PayrollDetailScreen extends ConsumerWidget {
  final String payrollId;
  const PayrollDetailScreen({super.key, required this.payrollId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollAsync = ref.watch(payrollDetailProvider(payrollId));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('Payroll Detail')),
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
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: GoldCraftColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GoldCraftColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(payroll.karagarName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: GoldCraftColors.charcoal)),
                      ),
                      GoldCraftBadge(label: badgeLabel, type: badgeType),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      '${fmt.format(payroll.periodStart)} \u2013 ${fmt.format(payroll.periodEnd)}',
                      style: const TextStyle(
                          fontSize: 13, color: GoldCraftColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
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
                    const Divider(height: 24),
                    _row('Net Payable',
                        '\u20b9${payroll.netPayableRupees.toStringAsFixed(0)}',
                        bold: true),
                    _row('Paid',
                        '\u20b9${payroll.paidRupees.toStringAsFixed(0)}',
                        color: GoldCraftColors.softGreenText),
                    if (payroll.remainingRupees > 0)
                      _row('Remaining',
                          '\u20b9${payroll.remainingRupees.toStringAsFixed(0)}',
                          color: GoldCraftColors.softRedText, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GoldCraftColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GoldCraftColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wastage',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: GoldCraftColors.charcoal)),
                    const SizedBox(height: 12),
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

  Widget _row(String label, String value, {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: GoldCraftColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? GoldCraftColors.charcoal)),
        ]),
      );
}

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
        onPressed: _loading
            ? null
            : () async {
                final ctrl = TextEditingController(
                    text: widget.remaining.toStringAsFixed(0));
                final messenger = ScaffoldMessenger.of(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Record Payment'),
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
