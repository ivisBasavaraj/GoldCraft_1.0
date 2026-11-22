import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';

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

    return GcScaffold(
      isAdmin: true,
      header: GcPageHeader(
        title: 'Users',
        subtitle: 'Manager & karagar accounts',
        showBell: false,
        onBack: () => context.go('/dashboard'),
        actions: [
          GcCircleButton(
            icon: Icons.person_add_alt_1_rounded,
            tooltip: 'Create user',
            onPressed: () => context.push('/users/new'),
          ),
        ],
      ),
      bottomNav: const GcBottomNav(currentIndex: -1, isAdmin: true),
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
            color: GcUi.green,
            onRefresh: () async => ref.invalidate(usersProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _UserTile(
                user: users[i],
                onDeleted: () => ref.invalidate(usersProvider),
              ),
            ),
          );
        },
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

    final (roleLabel, fg, bg) = switch (role) {
      'admin' => ('ADMIN', GcUi.red, GcUi.redTint),
      'manager' => ('MANAGER', GcUi.goldDark, GcUi.goldTint),
      _ => ('KARAGAR', GcUi.blue, GcUi.blueTint),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GcUi.card(),
      child: Row(
        children: [
          GcIconTile(
            text: name.isEmpty ? '?' : name[0].toUpperCase(),
            fg: fg,
            bg: bg,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: GcUi.ink)),
                  ),
                  const SizedBox(width: 6),
                  GcPill(label: roleLabel, fg: fg, bg: bg),
                ]),
                const SizedBox(height: 3),
                Text('@$username',
                    style:
                        const TextStyle(fontSize: 13, color: GcUi.muted)),
                if (employeeCode != null) ...[
                  const SizedBox(height: 2),
                  Text(employeeCode,
                      style: const TextStyle(fontSize: 12, color: GcUi.hint)),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Created ${DateFormat('d MMM yyyy').format(createdAt)}',
                    style: const TextStyle(fontSize: 11, color: GcUi.hint),
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
                      color: GcUi.green, size: 22),
                  tooltip: 'Change Password',
                  onPressed: () => _changePassword(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: GcUi.red, size: 22),
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
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GcUi.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: GcUi.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const GcIconTile(
                    icon: Icons.key_outlined,
                    fg: GcUi.green,
                    bg: GcUi.greenTint,
                    size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Password',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: GcUi.ink),
                      ),
                      Text('${user['name']} · @${user['username']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: GcUi.muted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: GcUi.ink),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: newPassCtrl,
                obscureText: obscure,
                decoration: GcUi.input(
                  label: 'New Password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: GcUi.muted),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscure,
                decoration: GcUi.input(
                  label: 'Confirm Password',
                  icon: Icons.lock_outline_rounded,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                GcBanner(
                  icon: Icons.error_outline_rounded,
                  text: error!,
                  fg: GcUi.red,
                  bg: GcUi.redTint,
                ),
              ],
              const SizedBox(height: 20),
              GcPrimaryButton(
                label: 'Update Password',
                onPressed: () async {
                  final np = newPassCtrl.text;
                  final cp = confirmCtrl.text;
                  if (np.length < 6) {
                    setState(() => error = 'Minimum 6 characters');
                    return;
                  }
                  if (np != cp) {
                    setState(() => error = 'Passwords do not match');
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.patch('/users/${user['_id']}/password',
                        data: {'password': np});
                    if (context.mounted) {
                      gcSnack(context, 'Password updated for ${user['name']}');
                    }
                  } on DioException catch (e) {
                    if (context.mounted) {
                      gcSnack(context, mapDioError(e).message, error: true);
                    }
                  }
                },
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
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const GcIconTile(
            icon: Icons.delete_outline_rounded,
            fg: GcUi.red,
            bg: GcUi.redTint,
            size: 52),
        title: const Text('Delete User',
            style: TextStyle(fontWeight: FontWeight.w800, color: GcUi.ink)),
        content: Text(
          'Delete "${user['name']}" (@${user['username']})? This cannot be undone.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: GcUi.muted),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: GcUi.muted, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GcUi.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(ctx, true),
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
      if (context.mounted) gcSnack(context, 'User deleted');
    } on DioException catch (e) {
      if (context.mounted) {
        gcSnack(context, mapDioError(e).message, error: true);
      }
    }
  }
}