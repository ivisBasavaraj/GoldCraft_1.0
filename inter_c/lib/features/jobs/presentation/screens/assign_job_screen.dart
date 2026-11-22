import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../karagars/data/karagars_provider.dart';
import '../../data/jobs_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';

class AssignJobScreen extends ConsumerStatefulWidget {
  final String? preselectedKaragarId;
  final String? preselectedKaragarName;
  const AssignJobScreen(
      {super.key, this.preselectedKaragarId, this.preselectedKaragarName});

  @override
  ConsumerState<AssignJobScreen> createState() => _AssignJobScreenState();
}

class _AssignJobScreenState extends ConsumerState<AssignJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
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
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: GcUi.greenDark,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: GcUi.ink,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
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
      await dio.post('/jobs', data: {
        'title': _titleCtrl.text.trim(),
        'karagarId': _selectedKaragarId,
        'dueDate': _dueDate.toIso8601String(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(allJobsProvider(null));
      gcSnack(context, 'Job assigned successfully');
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
    final locked = widget.preselectedKaragarId != null;

    return GcScaffold(
      isAdmin: false,
      header: GcPageHeader(
        title: locked ? 'Assign Job' : 'Assign Work',
        subtitle: locked
            ? 'to ${widget.preselectedKaragarName ?? 'Karagar'}'
            : 'Give a job to a karagar',
        showBell: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const GcSectionLabel('Job Details'),
            TextFormField(
              controller: _titleCtrl,
              decoration: GcUi.input(
                  label: 'Job Title',
                  hint: 'e.g. Bangle Work',
                  icon: Icons.work_outline_rounded),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            const GcSectionLabel('Due Date'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GcUi.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: GcUi.muted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('EEE, d MMM yyyy').format(_dueDate),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: GcUi.ink),
                      ),
                    ),
                    const Icon(Icons.edit_calendar_outlined,
                        color: GcUi.green, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const GcSectionLabel('Assign To'),
            locked
                // Locked — came from karagar profile
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GcUi.goldTint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GcUi.gold),
                    ),
                    child: Row(children: [
                      const Icon(Icons.person_rounded,
                          color: GcUi.goldDark, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedKaragarName ??
                              widget.preselectedKaragarName ??
                              '',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: GcUi.goldDark),
                        ),
                      ),
                      const Icon(Icons.lock_outline_rounded,
                          size: 16, color: GcUi.goldDark),
                    ]),
                  )
                // Free selection dropdown
                : karagarsAsync.when(
                    loading: () => const GcLoadingIndicator(),
                    error: (e, _) => GcErrorState(message: e.toString()),
                    data: (karagars) {
                      final active =
                          karagars.where((k) => k.isActive).toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedKaragarId,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        decoration: GcUi.input(
                            hint: 'Select karagar',
                            icon: Icons.person_outline_rounded),
                        items: active
                            .map((k) => DropdownMenuItem(
                                  value: k.id,
                                  child: Text('${k.name} (${k.employeeCode})',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedKaragarId = v),
                      );
                    },
                  ),
            const SizedBox(height: 20),

            const GcSectionLabel('Notes (optional)'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: GcUi.input(hint: 'Any instructions...'),
            ),
            const SizedBox(height: 32),

            GcPrimaryButton(
              label: 'Assign Job',
              icon: Icons.assignment_turned_in_outlined,
              loading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}