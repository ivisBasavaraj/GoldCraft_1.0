import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/auth_provider.dart';
import '../../../../core/theme/colors.dart';

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
        final msg = e.toString().contains('Internet') || e.toString().contains('Network')
            ? 'Cannot reach server. Check your internet connection.'
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: GoldCraftColors.softRedText,
          ),
        );
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoldCraftColors.charcoal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                _buildCard(),
              ],
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: GoldCraftColors.jewelryGold,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: GoldCraftColors.jewelryGold.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.diamond_outlined,
            color: GoldCraftColors.pureWhite,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'GoldCraft',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: GoldCraftColors.pureWhite,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Jewelry Manufacturing ERP',
          style: TextStyle(
            fontSize: 14,
            color: GoldCraftColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: GoldCraftColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your credentials to continue',
              style: TextStyle(
                fontSize: 14,
                color: GoldCraftColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _userCtrl,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: GoldCraftColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: GoldCraftColors.pureWhite,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Sign In'),
              ),
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
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Demo Access',
                style: TextStyle(fontSize: 12, color: GoldCraftColors.textHint),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DemoButton(
                label: 'Admin',
                icon: Icons.admin_panel_settings_outlined,
                onTap: () {
                  _userCtrl.text = 'admin';
                  _passCtrl.text = 'demo1234';
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DemoButton(
                label: 'Manager',
                icon: Icons.manage_accounts_outlined,
                onTap: () {
                  _userCtrl.text = 'manager';
                  _passCtrl.text = 'demo1234';
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DemoButton(
                label: 'Karagar',
                icon: Icons.handyman_outlined,
                onTap: () {
                  _userCtrl.text = 'karagar1';
                  _passCtrl.text = 'demo1234';
                },
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
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: const BorderSide(color: GoldCraftColors.border),
        foregroundColor: GoldCraftColors.textSecondary,
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
