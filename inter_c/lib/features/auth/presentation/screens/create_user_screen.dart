import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../karagars/data/karagars_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
import 'users_screen.dart';

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String _role = 'manager';
  String? _linkedKaragarId;
  bool _obscure = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String get _roleTitle => '${_role[0].toUpperCase()}${_role.substring(1)}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'karagar' && _linkedKaragarId == null) {
      gcSnack(context, 'Please link a Karagar profile', error: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/users', data: {
        'name': _nameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim().toLowerCase(),
        'password': _passwordCtrl.text,
        'role': _role,
        if (_codeCtrl.text.trim().isNotEmpty)
          'employeeCode': _codeCtrl.text.trim(),
        if (_role == 'karagar' && _linkedKaragarId != null)
          'karagarId': _linkedKaragarId,
      });
      if (!mounted) return;
      ref.invalidate(usersProvider);
      gcSnack(context, '$_roleTitle account created');
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      gcSnack(context, mapDioError(e).message, error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final karagarsAsync = ref.watch(karagarsProvider);

    return GcScaffold(
      isAdmin: true,
      header: const GcPageHeader(
        title: 'Create User',
        subtitle: 'Add a manager or karagar login',
        showBell: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const GcSectionLabel('Role'),
            Row(children: [
              _RoleCard(
                label: 'Manager',
                icon: Icons.manage_accounts_outlined,
                description: 'Full workshop access',
                selected: _role == 'manager',
                color: GcUi.goldDark,
                bg: GcUi.goldTint,
                onTap: () => setState(() {
                  _role = 'manager';
                  _linkedKaragarId = null;
                }),
              ),
              const SizedBox(width: 12),
              _RoleCard(
                label: 'Karagar',
                icon: Icons.handyman_outlined,
                description: 'View own jobs & gold',
                selected: _role == 'karagar',
                color: GcUi.blue,
                bg: GcUi.blueTint,
                onTap: () => setState(() => _role = 'karagar'),
              ),
            ]),
            const SizedBox(height: 24),

            const GcSectionLabel('Account Details'),
            _field(_nameCtrl, 'Full Name',
                icon: Icons.person_outline_rounded,
                hint: 'e.g. Ramesh Sharma'),
            _field(_usernameCtrl, 'Username',
                icon: Icons.alternate_email_rounded,
                hint: 'e.g. ramesh01',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().contains(' ')) return 'No spaces allowed';
                  return null;
                }),
            _passwordField(),
            _field(_codeCtrl, 'Employee Code (optional)',
                icon: Icons.badge_outlined,
                hint: 'e.g. MGR-002',
                required: false),

            // Karagar link — only shown when role = karagar
            if (_role == 'karagar') ...[
              const SizedBox(height: 8),
              const GcSectionLabel('Link to Karagar Profile'),
              karagarsAsync.when(
                loading: () => const GcLoadingIndicator(),
                error: (e, _) => GcErrorState(message: e.toString()),
                data: (karagars) {
                  final active = karagars.where((k) => k.isActive).toList();
                  if (active.isEmpty) {
                    return const GcBanner(
                      icon: Icons.warning_amber_rounded,
                      text: 'No active karagars found. Add a karagar first.',
                      fg: GcUi.goldDark,
                      bg: GcUi.goldTint,
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _linkedKaragarId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    decoration: GcUi.input(
                        hint: 'Select karagar profile',
                        icon: Icons.link_rounded),
                    items: active
                        .map((k) => DropdownMenuItem(
                              value: k.id,
                              child: Text('${k.name} (${k.employeeCode})',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _linkedKaragarId = v),
                    validator: (_) => _linkedKaragarId == null
                        ? 'Please link a karagar profile'
                        : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              const GcBanner(
                icon: Icons.info_outline_rounded,
                text:
                    'Linking lets the karagar see their own jobs and gold in the app.',
              ),
            ],

            const SizedBox(height: 32),
            GcPrimaryButton(
              label: 'Create $_roleTitle',
              icon: Icons.person_add_alt_1_rounded,
              loading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    IconData? icon,
    bool required = true,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          decoration: GcUi.input(label: label, hint: hint, icon: icon),
          validator: validator ??
              (required
                  ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                  : null),
        ),
      );

  Widget _passwordField() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          decoration: GcUi.input(
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: GcUi.muted),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 6) return 'Minimum 6 characters';
            return null;
          },
        ),
      );
}

// ── Role Card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool selected;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.description,
    required this.selected,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? bg : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : GcUi.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? color : GcUi.hint, size: 28),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected ? color : GcUi.ink)),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: selected
                          ? color.withValues(alpha: 0.75)
                          : GcUi.muted)),
            ],
          ),
        ),
      ),
    );
  }
}