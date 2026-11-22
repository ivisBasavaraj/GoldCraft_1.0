import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../karagars/data/karagars_provider.dart';
import '../../data/advances_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';

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
      gcSnack(context, 'Please select a karagar', error: true);
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
      gcSnack(context, 'Advance disbursed successfully');
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
      isAdmin: false,
      header: const GcPageHeader(
        title: 'New Advance',
        subtitle: 'Disburse money to a karagar',
        showBell: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const GcSectionLabel('Karagar'),
            karagarsAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (karagars) => DropdownButtonFormField<String>(
                value: _selectedKaragarId,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                decoration: GcUi.input(
                    hint: 'Select karagar',
                    icon: Icons.person_outline_rounded),
                items: karagars
                    .where((k) => k.isActive)
                    .map((k) => DropdownMenuItem(
                          value: k.id,
                          child: Text('${k.name} (${k.employeeCode})',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedKaragarId = v),
              ),
            ),
            const SizedBox(height: 20),
            const GcSectionLabel('Amount (₹)'),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: GcUi.ink),
              decoration: GcUi.input(
                  hint: '5000', icon: Icons.currency_rupee_rounded),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null) return 'Invalid amount';
                if (n <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const GcSectionLabel('Payment Mode'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes
                  .map((m) => GcChoiceChip(
                        label: m.$2,
                        selected: _paymentMode == m.$1,
                        onTap: () => setState(() => _paymentMode = m.$1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const GcSectionLabel('Purpose (optional)'),
            TextFormField(
              controller: _purposeCtrl,
              decoration: GcUi.input(
                  hint: 'e.g. Medical emergency', icon: Icons.notes_rounded),
            ),
            const SizedBox(height: 16),
            const GcSectionLabel('Reference Number (optional)'),
            TextFormField(
              controller: _refCtrl,
              decoration: GcUi.input(
                  hint: 'UPI/transaction ref', icon: Icons.tag_rounded),
            ),
            const SizedBox(height: 32),
            GcPrimaryButton(
              label: 'Disburse Advance',
              icon: Icons.payments_outlined,
              loading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}