import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/advances_provider.dart';
import '../../domain/advance_model.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';

class AdvancesScreen extends ConsumerWidget {
  const AdvancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancesAsync = ref.watch(advancesProvider(null));

    return GcScaffold(
      isAdmin: false,
      header: GcPageHeader(
        title: 'Advances',
        subtitle: 'Money given to karagars',
        showBell: false,
        actions: [
          GcCircleButton(
            icon: Icons.add_rounded,
            tooltip: 'New advance',
            onPressed: () => context.push('/advances/new'),
          ),
        ],
      ),
      bottomNav: const GcBottomNav(currentIndex: -1),
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
            color: GcUi.green,
            onRefresh: () async => ref.invalidate(advancesProvider(null)),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: advances.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final repaid = advance.fullyRepaid;
    final fg = repaid ? GcUi.green : GcUi.goldDark;
    final bg = repaid ? GcUi.greenTint : GcUi.goldTint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GcUi.card(),
      child: Row(
        children: [
          GcIconTile(
            icon: repaid
                ? Icons.check_circle_outline_rounded
                : Icons.payments_outlined,
            fg: fg,
            bg: bg,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(advance.karagarName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: GcUi.ink)),
                    ),
                    const SizedBox(width: 6),
                    GcPill(
                      label: repaid ? 'REPAID' : 'OUTSTANDING',
                      fg: fg,
                      bg: bg,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${advance.amountRupees.toStringAsFixed(0)} · ${advance.transactionId}',
                  style: const TextStyle(fontSize: 12.5, color: GcUi.muted),
                ),
                if (!repaid) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Outstanding: ₹${advance.outstandingRupees.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: GcUi.goldDark),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy').format(advance.createdAt),
                  style: const TextStyle(fontSize: 11, color: GcUi.hint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}