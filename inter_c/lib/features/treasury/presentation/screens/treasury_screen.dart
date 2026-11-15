import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/treasury_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(treasurySummaryProvider);
    final txAsync = ref.watch(treasuryTransactionsProvider(1));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('Treasury Vault')),
      body: summaryAsync.when(
        loading: () =>
            const GcLoadingIndicator(message: 'Loading treasury...'),
        error: (e, _) => GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(treasurySummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          color: GoldCraftColors.jewelryGold,
          onRefresh: () async {
            ref.invalidate(treasurySummaryProvider);
            ref.invalidate(treasuryTransactionsProvider(1));
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C1F0A), Color(0xFF4A3218)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Gold',
                        style: TextStyle(
                            fontSize: 13, color: Colors.white54)),
                    const SizedBox(height: 6),
                    Text(
                      '${summary.availableGoldGrams.toStringAsFixed(3)} g',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: summary.reserveRemainingPercent / 100,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            GoldCraftColors.jewelryGold),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _vaultStat('Opening',
                            '${summary.openingReserveGrams.toStringAsFixed(1)} g'),
                        _vaultStat('Issued',
                            '${summary.issuedGoldGrams.toStringAsFixed(1)} g',
                            color: const Color(0xFFFFB74D)),
                        _vaultStat('In Circulation',
                            '${summary.inCirculationGrams.toStringAsFixed(1)} g',
                            color: const Color(0xFFEF9A9A)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Recent Transactions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: GoldCraftColors.charcoal)),
              const SizedBox(height: 12),
              txAsync.when(
                loading: () => const GcLoadingIndicator(),
                error: (e, _) =>
                    GcErrorState(message: e.toString()),
                data: (data) {
                  final items = data['items'] as List<dynamic>? ?? [];
                  if (items.isEmpty) {
                    return const GcEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Transactions',
                      subtitle: 'Treasury transactions will appear here.',
                    );
                  }
                  return Column(
                    children: items
                        .map((t) => _TxTile(tx: t as Map<String, dynamic>))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vaultStat(String label, String value, {Color color = Colors.white}) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.white38)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      );
}

class _TxTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final type = tx['type'] as String;
    final amountMg = (tx['amountMg'] as num).toDouble();
    final balanceMg = (tx['balanceAfterMg'] as num).toDouble();
    final isDebit = amountMg < 0;
    final date = DateTime.parse(tx['createdAt'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GoldCraftColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDebit
                  ? GoldCraftColors.softAmber
                  : GoldCraftColors.softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDebit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isDebit
                  ? GoldCraftColors.softAmberText
                  : GoldCraftColors.softGreenText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] as String? ?? type,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GoldCraftColors.charcoal)),
                Text(DateFormat('d MMM, HH:mm').format(date),
                    style: const TextStyle(
                        fontSize: 11, color: GoldCraftColors.textHint)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? '-' : '+'}${(amountMg.abs() / 1000).toStringAsFixed(3)} g',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDebit
                        ? GoldCraftColors.softAmberText
                        : GoldCraftColors.softGreenText),
              ),
              Text(
                'Bal: ${(balanceMg / 1000).toStringAsFixed(3)} g',
                style: const TextStyle(
                    fontSize: 11, color: GoldCraftColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
