import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/karagars_provider.dart';
import '../../domain/karagar_model.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';

class KaragarsScreen extends ConsumerStatefulWidget {
  const KaragarsScreen({super.key});

  @override
  ConsumerState<KaragarsScreen> createState() => _KaragarsScreenState();
}

class _KaragarsScreenState extends ConsumerState<KaragarsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Karagar> _filter(List<Karagar> all) {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return all;
    return all.where((k) {
      return k.name.toLowerCase().contains(q) ||
          k.employeeCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final karagarsAsync = ref.watch(karagarsProvider);

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to dashboard',
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Karagars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/karagars/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: karagarsAsync.when(
              loading: () => const GcLoadingIndicator(message: 'Loading artisans...'),
              error: (e, _) => GcErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(karagarsProvider),
              ),
              data: (all) {
                final filtered = _filter(all);
                if (filtered.isEmpty) {
                  return const GcEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Artisans Found',
                    subtitle: 'Try adjusting your search.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _KaragarCard(karagar: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: GoldCraftColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name or employee code...',
          prefixIcon: const Icon(Icons.search_rounded, color: GoldCraftColors.textHint),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _KaragarCard extends StatelessWidget {
  final Karagar karagar;
  const _KaragarCard({required this.karagar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/karagars/${karagar.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GoldCraftColors.divider),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: karagar.isActive
                    ? GoldCraftColors.jewelryGoldLight
                    : GoldCraftColors.warmIvory,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  karagar.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: karagar.isActive
                        ? GoldCraftColors.jewelryGoldDark
                        : GoldCraftColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          karagar.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: GoldCraftColors.charcoal,
                          ),
                        ),
                      ),
                      GoldCraftBadge(
                        label: karagar.isActive ? 'Active' : 'Inactive',
                        type: karagar.isActive
                            ? GoldCraftBadgeType.success
                            : GoldCraftBadgeType.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${karagar.employeeCode} · ${karagar.meltingGroup}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: GoldCraftColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.work_outline_rounded,
                        label: '${karagar.activeJobCount} jobs',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.swap_horiz_rounded,
                        label: '${karagar.outstandingCustodyGrams.toStringAsFixed(1)} g custody',
                        color: karagar.outstandingCustodyGrams > 0
                            ? GoldCraftColors.softAmberText
                            : GoldCraftColors.softGreenText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: GoldCraftColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    this.color = GoldCraftColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
