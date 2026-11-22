import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../jobs/data/jobs_provider.dart';
import '../../../jobs/domain/job_model.dart';
import '../../data/issuance_provider.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../../shared/widgets/scale_camera_screen.dart';
import '../../../../features/auth/domain/auth_provider.dart';

class IssueGoldScreen extends ConsumerStatefulWidget {
  final String? initialJobId;
  const IssueGoldScreen({super.key, this.initialJobId});

  @override
  ConsumerState<IssueGoldScreen> createState() => _IssueGoldScreenState();
}

class _IssueGoldScreenState extends ConsumerState<IssueGoldScreen> {
  final _notesCtrl = TextEditingController();

  String? _selectedJobId;
  bool _isSubmitting = false;

  double? _ocrGrams;
  double? _ocrConfidence;
  String? _ocrImagePath;
  bool _ocrScanned = false;

  @override
  void initState() {
    super.initState();
    _selectedJobId = widget.initialJobId;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanScale() async {
    final result = await Navigator.of(context).push<OcrResult>(
      MaterialPageRoute(builder: (_) => const ScaleCameraScreen()),
    );
    if (result == null || !mounted) return;
    setState(() {
      _ocrGrams = result.valueGrams;
      _ocrConfidence = result.confidence;
      _ocrImagePath = result.imagePath;
      _ocrScanned = true;
    });
    gcSnack(
      context,
      'Scale read: ${result.valueGrams.toStringAsFixed(3)} g '
      '(${(result.confidence * 100).toStringAsFixed(0)}% confidence)',
    );
  }

  Future<void> _submit() async {
    if (_selectedJobId == null) {
      gcSnack(context, 'Please select a job', error: true);
      return;
    }
    if (_ocrGrams == null || _ocrImagePath == null) {
      gcSnack(context, 'Scan the scale before issuing gold', error: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(issuanceRepositoryProvider);
      await repo.create(
        jobId: _selectedJobId!,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        managerOcrGrams: _ocrGrams,
        ocrConfidence: _ocrConfidence,
        ocrImagePath: _ocrImagePath,
      );
      if (!mounted) return;
      gcSnack(context, 'Gold issued successfully');
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
        title: 'Issue Gold',
        subtitle: 'Weigh on the scale & issue to a job',
        showBell: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const GcSectionLabel('Select Job'),
          jobsAsync.when(
            loading: () => const GcLoadingIndicator(),
            error: (e, _) => GcErrorState(message: e.toString()),
            data: (jobs) {
              final active = jobs
                  .where((j) =>
                      j.status == JobStatus.assigned ||
                      j.status == JobStatus.inProgress)
                  .toList();
              // Guard: dropdown asserts if the selected id isn't in the list
              final current = active.any((j) => j.id == _selectedJobId)
                  ? _selectedJobId
                  : null;
              return DropdownButtonFormField<String>(
                value: current,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                decoration: GcUi.input(
                    hint: 'Select active job',
                    icon: Icons.work_outline_rounded),
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

          // ── OCR scan ──────────────────────────────────────────────────
          const GcSectionLabel('Scale OCR Verification'),
          _OcrScanCard(
            ocrGrams: _ocrGrams,
            confidence: _ocrConfidence,
            scanned: _ocrScanned,
            onScan: _scanScale,
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
            label: 'Issue Gold',
            icon: Icons.arrow_upward_rounded,
            loading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Reusable OCR scan card ────────────────────────────────────────────────────

class _OcrScanCard extends StatelessWidget {
  final double? ocrGrams;
  final double? confidence;
  final bool scanned;
  final VoidCallback onScan;

  const _OcrScanCard({
    required this.ocrGrams,
    required this.confidence,
    required this.scanned,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scanned ? GcUi.greenTint : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scanned ? GcUi.green : GcUi.border,
          width: scanned ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        GcIconTile(
          icon: scanned
              ? Icons.verified_rounded
              : Icons.document_scanner_outlined,
          fg: scanned ? GcUi.green : GcUi.goldDark,
          bg: scanned ? Colors.white : GcUi.goldTint,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: scanned
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scale Verified',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: GcUi.green)),
                    const SizedBox(height: 2),
                    Text(
                      '${ocrGrams!.toStringAsFixed(3)} g  ·  '
                      '${(confidence! * 100).toStringAsFixed(0)}% confidence',
                      style:
                          const TextStyle(fontSize: 12.5, color: GcUi.green),
                    ),
                  ],
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Required',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: GcUi.ink)),
                    SizedBox(height: 2),
                    Text('Point camera at the scale display',
                        style: TextStyle(fontSize: 12.5, color: GcUi.muted)),
                  ],
                ),
        ),
        TextButton.icon(
          onPressed: onScan,
          icon: Icon(
              scanned ? Icons.refresh_rounded : Icons.camera_alt_rounded,
              size: 18),
          label: Text(scanned ? 'Rescan' : 'Scan'),
          style: TextButton.styleFrom(
            foregroundColor: scanned ? GcUi.green : GcUi.goldDark,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    );
  }
}