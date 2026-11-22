import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/karagars_provider.dart';
import '../../domain/karagar_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../widgets/karagar_avatar.dart';

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
    final isAdmin = ref.watch(authUserProvider).valueOrNull?.isAdmin == true;

    return GcScaffold(
      isAdmin: isAdmin,
      bottomNav: GcBottomNav(currentIndex: 1, isAdmin: isAdmin),
      header: GcPageHeader(
        title: 'Karagars',
        onBack: () => context.go('/dashboard'),
        actions: [
          GcCircleButton(
            icon: Icons.person_add_outlined,
            tooltip: 'Add karagar',
            color: GcUi.primary(isAdmin),
            onPressed: () => context.push('/karagars/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: karagarsAsync.when(
              loading: () =>
                  const GcLoadingIndicator(message: 'Loading artisans...'),
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _KaragarCard(karagar: filtered[i], isAdmin: isAdmin),
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: GcUi.card(radius: 30),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name or employee code...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          prefixIcon:
              const Icon(Icons.search_rounded, color: GcUi.muted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _KaragarCard extends StatelessWidget {
  final Karagar karagar;
  final bool isAdmin;
  const _KaragarCard({required this.karagar, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final accent = karagar.isActive ? GcUi.gold : GcUi.border;

    return GestureDetector(
      onTap: () => context.push('/karagars/${karagar.id}'),
      child: Container(
        decoration: GcUi.card(radius: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Avatar
                        KaragarAvatar(
                          name: karagar.name,
                          imageUrl: karagar.avatarUrl,
                          size: 56,
                          backgroundColor: karagar.isActive
                              ? GcUi.goldTint
                              : GoldCraftColors.warmIvory,
                          foregroundColor:
                              karagar.isActive ? GcUi.ink : GcUi.muted,
                          borderColor:
                              karagar.isActive ? GcUi.gold : GcUi.border,
                          borderWidth: 2,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: GcUi.ink,
                                      ),
                                    ),
                                  ),
                                  GoldCraftBadge(
                                    label:
                                        karagar.isActive ? 'Active' : 'Inactive',
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
                                    fontSize: 13, color: GcUi.muted),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  _StatChip(
                                    icon: Icons.work_outline_rounded,
                                    label: '${karagar.activeJobCount} jobs',
                                  ),
                                  _StatChip(
                                    icon: Icons.swap_horiz_rounded,
                                    label:
                                        '${karagar.outstandingCustodyGrams.toStringAsFixed(1)} g custody',
                                    color: karagar.outstandingCustodyGrams > 0
                                        ? GoldCraftColors.softAmberText
                                        : GoldCraftColors.softGreenText,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: GcUi.ink, size: 26),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    this.color = GcUi.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}