import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../jobs/data/jobs_provider.dart';
import '../../../jobs/domain/job_model.dart';
import '../../data/receipts_provider.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
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
  // Was 'finishedProduct', which matched none of the chips below.
  String _receiptType = 'finished';
  bool _isSubmitting = false;

  static const _receiptTypes = [
    ('finished', 'Finished Product'),
    ('scrap', 'Scrap / Partial Return'),
    ('wastage', 'Wastage'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedJobId = widget.initialJobId;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJobId == null) {
      gcSnack(context, 'Please select a job', error: true);
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
      gcSnack(context, 'Receipt recorded successfully');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      gcSnack(context, e.toString(), error: true);
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

    return GcScaffold(
      isAdmin: false,
      header: const GcPageHeader(
        title: 'Receive Gold',
        subtitle: 'Record gold returned from a job',
        showBell: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const GcSectionLabel('Select Job'),
            jobsAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (jobs) {
                final active = jobs
                    .where((j) =>
                        j.status == JobStatus.inProgress ||
                        j.status == JobStatus.qualityCheck)
                    .toList();
                // Guard: dropdown asserts if the selected id isn't listed
                final current = active.any((j) => j.id == _selectedJobId)
                    ? _selectedJobId
                    : null;
                return DropdownButtonFormField<String>(
                  value: current,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  decoration: GcUi.input(
                      hint: 'Select job', icon: Icons.work_outline_rounded),
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
            const GcSectionLabel('Receipt Type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _receiptTypes
                  .map((t) => GcChoiceChip(
                        label: t.$2,
                        selected: _receiptType == t.$1,
                        onTap: () => setState(() => _receiptType = t.$1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const GcSectionLabel('Physical Weight (grams)'),
            TextFormField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: GcUi.ink),
              decoration: GcUi.input(
                hint: 'e.g. 118.200',
                icon: Icons.scale_outlined,
              ).copyWith(suffixText: 'g'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null) return 'Invalid number';
                if (n < 0) return 'Cannot be negative';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const GcSectionLabel('Notes (optional)'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: GcUi.input(hint: 'Any remarks...'),
            ),
            const SizedBox(height: 32),
            GcPrimaryButton(
              label: 'Record Receipt',
              icon: Icons.arrow_downward_rounded,
              loading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}