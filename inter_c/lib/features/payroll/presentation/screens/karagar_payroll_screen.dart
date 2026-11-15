import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/payroll_provider.dart';
import '../../../advances/data/advances_provider.dart';
import '../../../advances/domain/advance_model.dart';
import '../../domain/payroll_model.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../core/theme/colors.dart';
import '../../../../features/jobs/presentation/screens/karagar_home_screen.dart'
    show KaragarBottomNav;

class KaragarPayrollScreen extends ConsumerWidget {
  const KaragarPayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollsAsync = ref.watch(myPayrollsProvider);
    final advancesAsync = ref.watch(myAdvancesProvider);

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('My Earnings')),
      bottomNavigationBar: const KaragarBottomNav(currentIndex: 2),
      body: RefreshIndicator(
        color: GoldCraftColors.jewelryGold,
        onRefresh: () async {
          ref.invalidate(myPayrollsProvider);
          ref.invalidate(myAdvancesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Salary Section ──────────────────────────────────────
            _sectionHeader(
              Icons.payments_outlined,
              'Salary History',
              GoldCraftColors.softGreenText,
            ),
            const SizedBox(height: 12),
            payrollsAsync.when(
              loading: () =>
                  const GcLoadingIndicator(message: 'Loading salary...'),
              error: (e, _) => GcErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(myPayrollsProvider),
              ),
              data: (payrolls) {
                if (payrolls.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'No salary records yet.',
                  );
                }
                final totalPaid =
                    payrolls.fold(0.0, (s, p) => s + p.paidRupees);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryBanner(
                      'Total Paid',
                      '₹${_fmt(totalPaid)}',
                      GoldCraftColors.softGreen,
                      GoldCraftColors.softGreenText,
                      Icons.payments_outlined,
                    ),
                    const SizedBox(height: 12),
                    ...payrolls.map((p) => _SalaryCard(payroll: p)),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Advances Section ─────────────────────────────────────
            _sectionHeader(
              Icons.currency_rupee_rounded,
              'My Advances',
              GoldCraftColors.softAmberText,
            ),
            const SizedBox(height: 12),
            advancesAsync.when(
              loading: () =>
                  const GcLoadingIndicator(message: 'Loading advances...'),
              error: (e, _) => GcErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(myAdvancesProvider),
              ),
              data: (advances) {
                if (advances.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.payments_outlined,
                    label: 'No advances disbursed yet.',
                  );
                }
                final totalOutstanding = advances
                    .where((a) => !a.fullyRepaid)
                    .fold(0.0, (s, a) => s + a.outstandingRupees);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (totalOutstanding > 0) ...[
                      _summaryBanner(
                        'Outstanding Balance',
                        '₹${_fmt(totalOutstanding)}',
                        GoldCraftColors.softAmber,
                        GoldCraftColors.softAmberText,
                        Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: 12),
                    ],
                    ...advances.map((a) => _AdvanceCard(advance: a)),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: GoldCraftColors.charcoal,
            ),
          ),
        ],
      );

  Widget _summaryBanner(
    String label,
    String value,
    Color bg,
    Color fg,
    IconData icon,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7))),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: fg)),
          ]),
        ]),
      );

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_IN').format(v.round());
}

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
          Row(children: [
            Expanded(
              child: Text(period,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: GoldCraftColors.charcoal)),
            ),
            _statusBadge(payroll.status),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: GoldCraftColors.divider),
          const SizedBox(height: 10),
          Row(children: [
            _stat('Paid', '₹${_fmt(payroll.paidRupees)}',
                GoldCraftColors.softGreenText),
            _stat('Net Payable', '₹${_fmt(payroll.netPayableRupees)}',
                GoldCraftColors.charcoal),
            _stat('Generated', dateFmt.format(payroll.createdAt),
                GoldCraftColors.textSecondary),
          ]),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: GoldCraftColors.textHint)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
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

class _AdvanceCard extends StatelessWidget {
  final Advance advance;
  const _AdvanceCard({required this.advance});

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
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: advance.fullyRepaid
                ? GoldCraftColors.softGreen
                : GoldCraftColors.softAmber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            advance.fullyRepaid
                ? Icons.check_circle_outline_rounded
                : Icons.currency_rupee_rounded,
            color: advance.fullyRepaid
                ? GoldCraftColors.softGreenText
                : GoldCraftColors.softAmberText,
            size: 22,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: GoldCraftColors.charcoal),
                  ),
                ),
                GoldCraftBadge(
                  label: advance.fullyRepaid ? 'Repaid' : 'Outstanding',
                  type: advance.fullyRepaid
                      ? GoldCraftBadgeType.success
                      : GoldCraftBadgeType.warning,
                ),
              ]),
              const SizedBox(height: 4),
              if (!advance.fullyRepaid)
                Text(
                  'Outstanding: ₹${_fmt(advance.outstandingRupees)}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GoldCraftColors.softAmberText),
                ),
              Text(
                '${advance.transactionId} · ${DateFormat('d MMM yyyy').format(advance.createdAt)}',
                style: const TextStyle(
                    fontSize: 11, color: GoldCraftColors.textHint),
              ),
            ],
          ),
        ),
      ]),
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
      decoration: BoxDecoration(
        color: GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GoldCraftColors.divider),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: GoldCraftColors.textHint),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: GoldCraftColors.textHint)),
      ]),
    );
  }
}
