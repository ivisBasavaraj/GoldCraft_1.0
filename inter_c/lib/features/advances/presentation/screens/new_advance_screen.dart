import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../karagars/data/karagars_provider.dart';
import '../../data/advances_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';

class NewAdvanceScreen extends ConsumerStatefulWidget {
  const NewAdvanceScreen({super.key});

  @override
  ConsumerState<NewAdvanceScreen> createState() => _NewAdvanceScreenState();
}

class _NewAdvanceScreenState extends ConsumerState<NewAdvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String? _selectedKaragarId;
  String _paymentMode = 'cash';
  bool _isSubmitting = false;

  static const _modes = [
    ('cash', 'Cash'),
    ('upi', 'UPI'),
    ('bankTransfer', 'Bank Transfer'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _purposeCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKaragarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a karagar')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/advances', data: {
        'karagarId': _selectedKaragarId,
        'amountRupees': double.parse(_amountCtrl.text.trim()),
        'amountPaise': (double.parse(_amountCtrl.text.trim()) * 100).round(),
        'paymentMode': _paymentMode,
        if (_purposeCtrl.text.trim().isNotEmpty)
          'purpose': _purposeCtrl.text.trim(),
        if (_refCtrl.text.trim().isNotEmpty)
          'referenceNumber': _refCtrl.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(advancesProvider(null));
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advance disbursed successfully')));
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: GoldCraftColors.softRedText));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final karagarsAsync = ref.watch(karagarsProvider);

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('New Advance')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('Karagar'),
            karagarsAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (karagars) => DropdownButtonFormField<String>(
                value: _selectedKaragarId,
                decoration: const InputDecoration(
                    hintText: 'Select karagar',
                    prefixIcon: Icon(Icons.person_outline_rounded)),
                items: karagars
                    .where((k) => k.isActive)
                    .map((k) => DropdownMenuItem(
                          value: k.id,
                          child: Text('${k.name} (${k.employeeCode})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedKaragarId = v),
              ),
            ),
            const SizedBox(height: 20),
            _label('Amount (₹)'),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  prefixText: '₹ ',
                  hintText: '5000',
                  prefixIcon: Icon(Icons.currency_rupee_rounded)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _label('Payment Mode'),
            Wrap(
              spacing: 8,
              children: _modes
                  .map((m) => ChoiceChip(
                        label: Text(m.$2),
                        selected: _paymentMode == m.$1,
                        onSelected: (_) =>
                            setState(() => _paymentMode = m.$1),
                        selectedColor: GoldCraftColors.jewelryGoldLight,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            _label('Purpose (optional)'),
            TextFormField(
              controller: _purposeCtrl,
              decoration:
                  const InputDecoration(hintText: 'e.g. Medical emergency'),
            ),
            const SizedBox(height: 16),
            _label('Reference Number (optional)'),
            TextFormField(
              controller: _refCtrl,
              decoration:
                  const InputDecoration(hintText: 'UPI/transaction ref'),
            ),
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
                    : const Text('Disburse Advance'),
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
}
