import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../../features/jobs/presentation/screens/karagar_home_screen.dart'
    show KaragarBottomNav;

class SettingsScreen extends ConsumerWidget {
  final String title;

  const SettingsScreen({super.key, this.title = 'Settings'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin == true;

    return GcScaffold(
      isAdmin: isAdmin,
      // Karagar keeps its own nav; manager/admin get the same nav as the
      // dashboard (no tab highlighted, since Profile is not one of the tabs).
      bottomNav: user?.isKaragar == true
          ? const KaragarBottomNav(currentIndex: 3)
          : GcBottomNav(currentIndex: -1, isAdmin: isAdmin),
      header: GcPageHeader(
        title: title,
        showBack: context.canPop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: GcUi.heroGradient(isAdmin),
              ),
              boxShadow: [
                BoxShadow(
                  color: GcUi.primary(isAdmin).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GcUi.goldTint,
                    border: Border.all(color: GcUi.gold, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      (user?.name.isNotEmpty == true)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: GcUi.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 18, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '@${user?.username ?? '—'} · ${_roleLabel(user?.role)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (user?.employeeCode != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 18, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(user!.employeeCode!,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // App info cards
          Row(
            children: [
              Expanded(
                child: _infoCard(
                    Icons.smartphone_rounded, 'App Version', '1.0.0', isAdmin),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(Icons.language_rounded, 'API Server',
                    'api.iqonixlabs.io', isAdmin),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (isAdmin) ...[
            _sectionTab(Icons.admin_panel_settings_rounded, 'Admin', isAdmin),
            _tile(
              Icons.manage_accounts_rounded,
              'Manage Users',
              subtitle: 'Add or edit app users',
              onTap: () => context.push('/users'),
              isAdmin: isAdmin,
            ),
            const SizedBox(height: 20),
          ],

          _sectionTab(Icons.account_circle_outlined, 'Account', isAdmin),
          _tile(
            Icons.logout_rounded,
            'Sign Out',
            subtitle: 'Logout from your account',
            color: GoldCraftColors.softRedText,
            iconBg: const Color(0xFFFDE8E8),
            isAdmin: isAdmin,
            onTap: () async {
              await ref.read(authUserProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole? role) => switch (role) {
        UserRole.admin => 'Admin',
        UserRole.manager => 'Manager',
        UserRole.karagar => 'Karagar',
        null => '—',
      };

  Widget _infoCard(IconData icon, String label, String value, bool isAdmin) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: GcUi.card(radius: 20, color: GcUi.ivory),
        child: Row(
          children: [
            Icon(icon, size: 34, color: GcUi.primary(isAdmin)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 13, color: GcUi.muted)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: GcUi.ink)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sectionTab(IconData icon, String label, bool isAdmin) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
            decoration: BoxDecoration(
              color: GcUi.primary(isAdmin),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      );

  Widget _tile(
    IconData icon,
    String label, {
    String? subtitle,
    Color color = GcUi.ink,
    Color? iconBg,
    required bool isAdmin,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: GcUi.card(radius: 22),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg ?? GcUi.greenTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 26,
                    color: color == GcUi.ink ? GcUi.primary(isAdmin) : color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 13, color: GcUi.muted)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    size: 26, color: GcUi.ink),
            ],
          ),
        ),
      );
}