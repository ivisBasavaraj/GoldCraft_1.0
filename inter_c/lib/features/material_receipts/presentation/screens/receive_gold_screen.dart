import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../jobs/data/jobs_provider.dart';
import '../../../jobs/domain/job_model.dart';
import '../../data/receipts_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../features/auth/domain/auth_provider.dart';

class ReceiveGoldScreen extends ConsumerStatefulWidget {
  final String? initialJobId;
  const ReceiveGoldScreen({super.key, this.initialJobId});

  @override
  ConsumerState<ReceiveGoldScreen> createState() => _ReceiveGoldScreenState();
}

class _ReceiveGoldScreenState extends ConsumerState<ReceiveGoldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedJobId;
  String _receiptType = 'finishedProduct';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedJobId = widget.initialJobId;
  }

  static const _receiptTypes = [
    ('finished', 'Finished Product'),
    ('scrap', 'Scrap / Partial Return'),
    ('wastage', 'Wastage'),
  ];

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJobId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a job')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(receiptRepositoryProvider);
      await repo.create(
        jobId: _selectedJobId!,
        receiptType: _receiptType,
        physicalWeightMg:
            (double.parse(_weightCtrl.text.trim()) * 1000).roundToDouble(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt recorded successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: GoldCraftColors.softRedText));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final isKaragar = user?.isKaragar == true;
    final jobsAsync = isKaragar
        ? ref.watch(myJobsProvider)
        : ref.watch(allJobsProvider(null));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('Receive Gold')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('Select Job'),
            jobsAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (jobs) {
                final active = jobs
                    .where((j) =>
                        j.status == JobStatus.inProgress ||
                        j.status == JobStatus.qualityCheck)
                    .toList();
                return DropdownButtonFormField<String>(
                  value: _selectedJobId,
                  decoration: const InputDecoration(
                      hintText: 'Select job',
                      prefixIcon: Icon(Icons.work_outline_rounded)),
                  items: active
                      .map((j) => DropdownMenuItem(
                            value: j.id,
                            child: Text('${j.title} — ${j.karagarName}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedJobId = v),
                );
              },
            ),
            const SizedBox(height: 20),
            _label('Receipt Type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _receiptTypes
                  .map((t) => ChoiceChip(
                        label: Text(t.$2),
                        selected: _receiptType == t.$1,
                        onSelected: (_) =>
                            setState(() => _receiptType = t.$1),
                        selectedColor: GoldCraftColors.jewelryGoldLight,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            _label('Physical Weight (grams)'),
            TextFormField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 118.200',
                suffixText: 'g',
                prefixIcon: Icon(Icons.scale_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _label('Notes (optional)'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Any remarks...'),
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
                    : const Text('Record Receipt'),
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
