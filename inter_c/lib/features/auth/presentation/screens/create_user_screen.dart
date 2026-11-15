import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../karagars/data/karagars_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'karagar' && _linkedKaragarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please link a Karagar profile')),
      );
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
        if (_codeCtrl.text.trim().isNotEmpty) 'employeeCode': _codeCtrl.text.trim(),
        if (_role == 'karagar' && _linkedKaragarId != null)
          'karagarId': _linkedKaragarId,
      });
      if (!mounted) return;
      ref.invalidate(usersProvider);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_role[0].toUpperCase()}${_role.substring(1)} account created'),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(mapDioError(e).message),
        backgroundColor: GoldCraftColors.softRedText,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final karagarsAsync = ref.watch(karagarsProvider);

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('Create User')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Role selector card
            _sectionLabel('Role'),
            Row(children: [
              _RoleCard(
                label: 'Manager',
                icon: Icons.manage_accounts_outlined,
                description: 'Full workshop access',
                selected: _role == 'manager',
                color: GoldCraftColors.softAmberText,
                bg: GoldCraftColors.softAmber,
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
                color: GoldCraftColors.softBlueText,
                bg: GoldCraftColors.softBlue,
                onTap: () => setState(() => _role = 'karagar'),
              ),
            ]),
            const SizedBox(height: 24),

            // Basic info
            _sectionLabel('Account Details'),
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
              _sectionLabel('Link to Karagar Profile'),
              karagarsAsync.when(
                loading: () => const GcLoadingIndicator(),
                error: (e, _) => GcErrorState(message: e.toString()),
                data: (karagars) {
                  final unlinked = karagars.where((k) => k.isActive).toList();
                  if (unlinked.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: GoldCraftColors.softAmber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No active karagars found. Add a karagar first.',
                        style: TextStyle(color: GoldCraftColors.softAmberText),
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _linkedKaragarId,
                    decoration: const InputDecoration(
                      hintText: 'Select karagar profile',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    items: unlinked
                        .map((k) => DropdownMenuItem(
                              value: k.id,
                              child: Text('${k.name} (${k.employeeCode})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _linkedKaragarId = v),
                    validator: (_) => _linkedKaragarId == null
                        ? 'Please link a karagar profile'
                        : null,
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GoldCraftColors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: GoldCraftColors.softBlueText),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Linking lets the karagar see their own jobs and gold in the app.',
                      style: TextStyle(
                          fontSize: 12, color: GoldCraftColors.softBlueText),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        'Create ${_role[0].toUpperCase()}${_role.substring(1)}'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GoldCraftColors.textSecondary)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    IconData? icon,
    bool required = true,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
          validator: validator ??
              (required
                  ? (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null
                  : null),
        ),
      );

  Widget _passwordField() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
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
            color: selected ? bg : GoldCraftColors.pureWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : GoldCraftColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? color : GoldCraftColors.textHint, size: 28),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : GoldCraftColors.charcoal)),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(
                      fontSize: 11,
                      color: selected ? color.withOpacity(0.7) : GoldCraftColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }
}
