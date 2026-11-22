import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/auth_provider.dart';
import '../../../../shared/widgets/gc_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref.read(authUserProvider.notifier).login(
          username: _userCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authUserProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          final route = user.isKaragar ? '/home' : '/dashboard';
          context.go(route);
        }
      },
      error: (e, _) {
        final msg =
            e.toString().contains('Internet') || e.toString().contains('Network')
                ? 'Cannot reach server. Check your internet connection.'
                : e.toString();
        gcSnack(context, msg, error: true);
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GcUi.bg,
      body: GcWaveBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: GcUi.heroGradient(false),
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: GcUi.greenDark.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.diamond_outlined, color: GcUi.gold, size: 42),
        ),
        const SizedBox(height: 18),
        const Text(
          'GoldCraft',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: GcUi.ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
              color: GcUi.gold, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Jewelry Manufacturing ERP',
          style: TextStyle(
              fontSize: 14, color: GcUi.muted, letterSpacing: 0.4),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(24),
      decoration: GcUi.card(radius: 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sign In',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: GcUi.ink)),
            const SizedBox(height: 4),
            const Text('Enter your credentials to continue',
                style: TextStyle(fontSize: 14, color: GcUi.muted)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _userCtrl,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              decoration: GcUi.input(
                  label: 'Username', icon: Icons.person_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Username is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: GcUi.input(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: GcUi.muted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: 24),
            GcPrimaryButton(
              label: 'Sign In',
              loading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            // Demo role quick-login for development
            _buildDemoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSection() {
    void fill(String u) {
      _userCtrl.text = u;
      _passCtrl.text = 'demo1234';
    }

    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: GcUi.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Demo Access',
                  style: TextStyle(fontSize: 12, color: GcUi.muted)),
            ),
            Expanded(child: Divider(color: GcUi.border)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DemoButton(
                label: 'Admin',
                icon: Icons.admin_panel_settings_outlined,
                onTap: () => fill('admin'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DemoButton(
                label: 'Manager',
                icon: Icons.manage_accounts_outlined,
                onTap: () => fill('manager'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DemoButton(
                label: 'Karagar',
                icon: Icons.handyman_outlined,
                onTap: () => fill('karagar1'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DemoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DemoButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: GcUi.ivory,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: GcUi.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: GcUi.green),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: GcUi.ink)),
            ),
          ],
        ),
      ),
    );
  }
}