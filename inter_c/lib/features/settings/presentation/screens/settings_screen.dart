import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../../core/theme/colors.dart';
import '../../../../features/jobs/presentation/screens/karagar_home_screen.dart'
    show KaragarBottomNav;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('Settings')),
      bottomNavigationBar: user?.isKaragar == true
          ? const KaragarBottomNav(currentIndex: 3)
          : null,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GoldCraftColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GoldCraftColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: GoldCraftColors.jewelryGoldLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      (user?.name.isNotEmpty == true)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: GoldCraftColors.jewelryGoldDark),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '—',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: GoldCraftColors.charcoal)),
                      const SizedBox(height: 4),
                      Text(
                        '@${user?.username ?? '—'} · ${_roleLabel(user?.role)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: GoldCraftColors.textSecondary),
                      ),
                      if (user?.employeeCode != null) ...[
                        const SizedBox(height: 2),
                        Text(user!.employeeCode!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: GoldCraftColors.textHint)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _sectionLabel('App'),
          _tile(Icons.info_outline_rounded, 'Version', trailing: '1.0.0'),
          _tile(Icons.language_rounded, 'API Server',
              trailing: 'api.iqonixlabs.io'),
          const SizedBox(height: 20),
          if (user?.isAdmin == true) ...[
            _sectionLabel('Admin'),
            _tile(
              Icons.manage_accounts_rounded,
              'Manage Users',
              icon2: Icons.chevron_right_rounded,
              onTap: () => context.push('/users'),
            ),
            const SizedBox(height: 20),
          ],
          _sectionLabel('Account'),
          _tile(
            Icons.logout_rounded,
            'Sign Out',
            color: GoldCraftColors.softRedText,
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

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GoldCraftColors.textHint,
                letterSpacing: 0.8)),
      );

  Widget _tile(
    IconData icon,
    String label, {
    String? trailing,
    IconData? icon2,
    Color color = GoldCraftColors.charcoal,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: GoldCraftColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GoldCraftColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: color))),
              if (trailing != null)
                Text(trailing,
                    style: const TextStyle(
                        fontSize: 13, color: GoldCraftColors.textHint)),
              if (icon2 != null)
                Icon(icon2, size: 18, color: GoldCraftColors.textHint),
            ],
          ),
        ),
      );
}
