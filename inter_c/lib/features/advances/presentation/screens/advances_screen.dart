import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/advances_provider.dart';
import '../../domain/advance_model.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';

class AdvancesScreen extends ConsumerWidget {
  const AdvancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancesAsync = ref.watch(advancesProvider(null));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: const Text('Advances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/advances/new'),
          ),
        ],
      ),
      body: advancesAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading advances...'),
        error: (e, _) => GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(advancesProvider(null)),
        ),
        data: (advances) {
          if (advances.isEmpty) {
            return const GcEmptyState(
              icon: Icons.payments_outlined,
              title: 'No Advances',
              subtitle: 'No advances have been disbursed yet.',
            );
          }
          return RefreshIndicator(
            color: GoldCraftColors.jewelryGold,
            onRefresh: () async => ref.invalidate(advancesProvider(null)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: advances.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AdvanceTile(advance: advances[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AdvanceTile extends StatelessWidget {
  final Advance advance;
  const _AdvanceTile({required this.advance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GoldCraftColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: advance.fullyRepaid
                  ? GoldCraftColors.softGreen
                  : GoldCraftColors.softAmber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              advance.fullyRepaid
                  ? Icons.check_circle_outline_rounded
                  : Icons.payments_outlined,
              color: advance.fullyRepaid
                  ? GoldCraftColors.softGreenText
                  : GoldCraftColors.softAmberText,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(advance.karagarName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: GoldCraftColors.charcoal)),
                    ),
                    GoldCraftBadge(
                      label: advance.fullyRepaid ? 'Repaid' : 'Outstanding',
                      type: advance.fullyRepaid
                          ? GoldCraftBadgeType.success
                          : GoldCraftBadgeType.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${advance.amountRupees.toStringAsFixed(0)} · ${advance.transactionId}',
                  style: const TextStyle(
                      fontSize: 12, color: GoldCraftColors.textSecondary),
                ),
                if (!advance.fullyRepaid) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Outstanding: ₹${advance.outstandingRupees.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GoldCraftColors.softAmberText),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy').format(advance.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: GoldCraftColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
