import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../data/karagars_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/colors.dart';

class AddKaragarScreen extends ConsumerStatefulWidget {
  const AddKaragarScreen({super.key});

  @override
  ConsumerState<AddKaragarScreen> createState() => _AddKaragarScreenState();
}

class _AddKaragarScreenState extends ConsumerState<AddKaragarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  String _meltingGroup = 'Group A';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    _specCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/karagars', data: {
        'name': _nameCtrl.text.trim(),
        'employeeCode': _codeCtrl.text.trim(),
        'meltingGroup': _meltingGroup,
        'specialization': _specCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(karagarsProvider);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karagar registered successfully')),
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
    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('Add Karagar')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_nameCtrl, 'Full Name', icon: Icons.person_outline_rounded),
            _field(_codeCtrl, 'Employee Code', hint: 'e.g. GC-005', icon: Icons.badge_outlined),
            _field(_phoneCtrl, 'Phone Number', required: false,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            _field(_specCtrl, 'Specialization', hint: 'e.g. Bangles & Chains',
                icon: Icons.diamond_outlined),
            const SizedBox(height: 8),
            _label('Melting Group'),
            Wrap(
              spacing: 8,
              children: ['Group A', 'Group B', 'Group C']
                  .map((g) => ChoiceChip(
                        label: Text(g),
                        selected: _meltingGroup == g,
                        onSelected: (_) => setState(() => _meltingGroup = g),
                        selectedColor: GoldCraftColors.jewelryGoldLight,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Register Karagar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
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
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      );
}
