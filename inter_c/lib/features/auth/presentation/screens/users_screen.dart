import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_states.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/users');
    final raw = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final inner = raw['data'] as Map<String, dynamic>? ?? {};
    final list = inner['items'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/users/new'),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const GcLoadingIndicator(message: 'Loading users...'),
        error: (e, _) => GcErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(usersProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const GcEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No Users',
              subtitle: 'Create a manager or karagar account.',
            );
          }
          return RefreshIndicator(
            color: GoldCraftColors.jewelryGold,
            onRefresh: () async => ref.invalidate(usersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _UserTile(
                user: users[i],
                onDeleted: () => ref.invalidate(usersProvider),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/users/new'),
        backgroundColor: GoldCraftColors.jewelryGold,
        foregroundColor: GoldCraftColors.pureWhite,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Create User'),
      ),
      bottomNavigationBar: _UsersBottomNav(),
    );
  }
}

// ── Bottom Nav (admin) ────────────────────────────────────────────────────────

class _UsersBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GoldCraftColors.pureWhite,
        border: Border(top: BorderSide(color: GoldCraftColors.divider)),
      ),
      child: BottomNavigationBar(
        currentIndex: 5,
        onTap: (i) {
          const routes = ['/dashboard', '/karagars', '/jobs', '/treasury', '/reports', '/users'];
          if (i == 5) return;
          if (i < routes.length) context.push(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people_rounded), label: 'Karagars'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline_rounded), activeIcon: Icon(Icons.work_rounded), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), activeIcon: Icon(Icons.account_balance_rounded), label: 'Treasury'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Users'),
        ],
      ),
    );
  }
}

// ── User Tile ─────────────────────────────────────────────────────────────────

class _UserTile extends ConsumerWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDeleted;

  const _UserTile({required this.user, required this.onDeleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = user['role'] as String? ?? 'karagar';
    final name = user['name'] as String? ?? '—';
    final username = user['username'] as String? ?? '—';
    final employeeCode = user['employeeCode'] as String?;
    final createdAt = user['createdAt'] != null
        ? DateTime.tryParse(user['createdAt'] as String)
        : null;

    final (badgeType, badgeLabel, avatarColor) = switch (role) {
      'admin' => (GoldCraftBadgeType.error, 'Admin', GoldCraftColors.softRed),
      'manager' => (GoldCraftBadgeType.warning, 'Manager', GoldCraftColors.softAmber),
      _ => (GoldCraftBadgeType.info, 'Karagar', GoldCraftColors.softBlue),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GoldCraftColors.divider),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: GoldCraftColors.charcoal,
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
                Row(children: [
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: GoldCraftColors.charcoal)),
                  ),
                  GoldCraftBadge(label: badgeLabel, type: badgeType),
                ]),
                const SizedBox(height: 3),
                Text('@$username',
                    style: const TextStyle(
                        fontSize: 13, color: GoldCraftColors.textSecondary)),
                if (employeeCode != null) ...[
                  const SizedBox(height: 2),
                  Text(employeeCode,
                      style: const TextStyle(
                          fontSize: 12, color: GoldCraftColors.textHint)),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Created ${DateFormat('d MMM yyyy').format(createdAt)}',
                    style: const TextStyle(
                        fontSize: 11, color: GoldCraftColors.textHint),
                  ),
                ],
              ],
            ),
          ),
          // Actions (not for admin accounts)
          if (role != 'admin')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.key_outlined,
                      color: GoldCraftColors.jewelryGoldDark, size: 20),
                  tooltip: 'Change Password',
                  onPressed: () => _changePassword(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: GoldCraftColors.softRedText, size: 20),
                  tooltip: 'Delete User',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GoldCraftColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.key_outlined,
                    color: GoldCraftColors.jewelryGold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reset Password — ${user['name']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
              const SizedBox(height: 4),
              Text('@${user['username']}',
                  style: const TextStyle(
                      fontSize: 13, color: GoldCraftColors.textSecondary)),
              const SizedBox(height: 20),
              TextField(
                controller: newPassCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                  filled: true,
                  fillColor: GoldCraftColors.warmIvory,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: GoldCraftColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  filled: true,
                  fillColor: GoldCraftColors.warmIvory,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: GoldCraftColors.border)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoldCraftColors.jewelryGold,
                    foregroundColor: GoldCraftColors.pureWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final np = newPassCtrl.text;
                    final cp = confirmCtrl.text;
                    if (np.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Minimum 6 characters')));
                      return;
                    }
                    if (np != cp) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Passwords do not match')));
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      final dio = ref.read(dioProvider);
                      await dio.patch(
                          '/users/${user['_id']}/password',
                          data: {'password': np});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Password updated for ${user['name']}'),
                        ));
                      }
                    } on DioException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(mapDioError(e).message),
                          backgroundColor: GoldCraftColors.softRedText,
                        ));
                      }
                    }
                  },
                  child: const Text('Update Password',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    newPassCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Delete "${user['name']}" (@${user['username']})? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GoldCraftColors.softRedText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/users/${user['_id']}');
      onDeleted();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: GoldCraftColors.softRedText,
        ));
      }
    }
  }
}
