import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../jobs/data/jobs_provider.dart';
import '../../../jobs/domain/job_model.dart';
import '../../data/issuance_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/scale_camera_screen.dart';
import '../../../../features/auth/domain/auth_provider.dart';

class IssueGoldScreen extends ConsumerStatefulWidget {
  final String? initialJobId;
  const IssueGoldScreen({super.key, this.initialJobId});

  @override
  ConsumerState<IssueGoldScreen> createState() => _IssueGoldScreenState();
}

class _IssueGoldScreenState extends ConsumerState<IssueGoldScreen> {
  final _notesCtrl  = TextEditingController();

  String? _selectedJobId;
  bool    _isSubmitting = false;

  double? _ocrGrams;
  double? _ocrConfidence;
  String? _ocrImagePath;
  bool    _ocrScanned = false;

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
      _ocrGrams      = result.valueGrams;
      _ocrConfidence = result.confidence;
      _ocrImagePath = result.imagePath;
      _ocrScanned    = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Scale read: ${result.valueGrams.toStringAsFixed(3)} g '
          '(${(result.confidence * 100).toStringAsFixed(0)}% confidence)'),
      backgroundColor: GoldCraftColors.softGreenText,
    ));
  }

  Future<void> _submit() async {
    if (_selectedJobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a job')));
      return;
    }
    if (_ocrGrams == null || _ocrImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Scan the scale before issuing gold'),
        backgroundColor: GoldCraftColors.softRedText,
      ));
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
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gold issued successfully')));
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
    final user      = ref.watch(authUserProvider).valueOrNull;
    final isKaragar = user?.isKaragar == true;
    final jobsAsync = isKaragar
        ? ref.watch(myJobsProvider)
        : ref.watch(allJobsProvider(null));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(title: const Text('Issue Gold')),
      body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('Select Job'),
            jobsAsync.when(
              loading: () => const GcLoadingIndicator(),
              error: (e, _) => GcErrorState(message: e.toString()),
              data: (jobs) {
                final active = jobs
                    .where((j) =>
                        j.status == JobStatus.assigned ||
                        j.status == JobStatus.inProgress)
                    .toList();
                return DropdownButtonFormField<String>(
                  value: _selectedJobId,
                  decoration: const InputDecoration(
                      hintText: 'Select active job',
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

            // ── OCR scan ──────────────────────────────────────────────────
            _label('Scale OCR Verification'),
            _OcrScanCard(
              ocrGrams: _ocrGrams,
              confidence: _ocrConfidence,
              scanned: _ocrScanned,
              onScan: _scanScale,
            ),
            const SizedBox(height: 20),

            // ── Weight (auto-filled by OCR) ───────────────────────────────
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
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Issue Gold'),
              ),
            ),
          ],
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
        color: scanned ? GoldCraftColors.softGreen : GoldCraftColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scanned
              ? GoldCraftColors.softGreenText
              : GoldCraftColors.divider,
          width: scanned ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scanned
                ? GoldCraftColors.softGreenText.withOpacity(0.15)
                : GoldCraftColors.jewelryGoldLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            scanned
                ? Icons.verified_rounded
                : Icons.document_scanner_outlined,
            color: scanned
                ? GoldCraftColors.softGreenText
                : GoldCraftColors.jewelryGoldDark,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: scanned
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scale Verified',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: GoldCraftColors.softGreenText)),
                    Text(
                      '${ocrGrams!.toStringAsFixed(3)} g  ·  '
                      '${(confidence! * 100).toStringAsFixed(0)}% confidence',
                      style: const TextStyle(
                          fontSize: 12,
                          color: GoldCraftColors.softGreenText),
                    ),
                  ],
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Required',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: GoldCraftColors.charcoal)),
                    Text('Point camera at the scale display',
                        style: TextStyle(
                            fontSize: 12,
                            color: GoldCraftColors.textSecondary)),
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
            foregroundColor: scanned
                ? GoldCraftColors.softGreenText
                : GoldCraftColors.jewelryGoldDark,
          ),
        ),
      ]),
    );
  }
}
