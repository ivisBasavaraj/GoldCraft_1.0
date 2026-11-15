import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../karagars/data/karagars_provider.dart';
import '../../data/jobs_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';

class AssignJobScreen extends ConsumerStatefulWidget {
  final String? preselectedKaragarId;
  final String? preselectedKaragarName;
  const AssignJobScreen({super.key, this.preselectedKaragarId, this.preselectedKaragarName});

  @override
  ConsumerState<AssignJobScreen> createState() => _AssignJobScreenState();
}

class _AssignJobScreenState extends ConsumerState<AssignJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedKaragarId;
  String? _selectedKaragarName;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedKaragarId = widget.preselectedKaragarId;
    _selectedKaragarName = widget.preselectedKaragarName;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKaragarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a karagar')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/jobs', data: {
        'title': _titleCtrl.text.trim(),
        'requiredWeightMg':
            (double.parse(_weightCtrl.text.trim()) * 1000).round(),
        'karagarId': _selectedKaragarId,
        'dueDate': _dueDate.toIso8601String(),
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(allJobsProvider(null));
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job assigned successfully')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(mapDioError(e).message),
            backgroundColor: GoldCraftColors.softRedText),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final karagarsAsync = ref.watch(karagarsProvider);

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: Text(widget.preselectedKaragarId != null
            ? 'Assign Job to ${widget.preselectedKaragarName ?? 'Karagar'}'
            : 'Assign Work'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section('Job Details'),
            _field(_titleCtrl, 'Job Title', hint: 'e.g. Bangle Work'),
            _weightField(),
            const SizedBox(height: 16),
            _section('Due Date'),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GoldCraftColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GoldCraftColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: GoldCraftColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                      style: const TextStyle(
                          fontSize: 15, color: GoldCraftColors.charcoal),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _section('Assign To'),
            widget.preselectedKaragarId != null
                // Locked — came from karagar profile
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GoldCraftColors.jewelryGoldLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GoldCraftColors.jewelryGold),
                    ),
                    child: Row(children: [
                      const Icon(Icons.person_rounded,
                          color: GoldCraftColors.jewelryGoldDark, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedKaragarName ?? widget.preselectedKaragarName ?? '',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: GoldCraftColors.jewelryGoldDark),
                        ),
                      ),
                      const Icon(Icons.lock_outline_rounded,
                          size: 16, color: GoldCraftColors.jewelryGoldDark),
                    ]),
                  )
                // Free selection dropdown
                : karagarsAsync.when(
                    loading: () => const GcLoadingIndicator(),
                    error: (e, _) => GcErrorState(message: e.toString()),
                    data: (karagars) {
                      final active = karagars.where((k) => k.isActive).toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedKaragarId,
                        decoration: const InputDecoration(
                          hintText: 'Select karagar',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        items: active
                            .map((k) => DropdownMenuItem(
                                  value: k.id,
                                  child: Text('${k.name} (${k.employeeCode})'),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedKaragarId = v),
                      );
                    },
                  ),
            const SizedBox(height: 16),
            _field(_notesCtrl, 'Notes (optional)',
                required: false, maxLines: 3),
            const SizedBox(height: 28),
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
                    : const Text('Assign Job'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _weightField() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (g)',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      );

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GoldCraftColors.textSecondary)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    bool isNumber = false,
    bool required = true,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      );
}


