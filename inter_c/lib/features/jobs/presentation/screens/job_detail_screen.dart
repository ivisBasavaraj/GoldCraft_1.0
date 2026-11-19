import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../data/jobs_provider.dart';
import '../../domain/job_model.dart';
import '../../../material_issuance/data/issuance_provider.dart';
import '../../../material_receipts/data/receipts_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/gc_badge.dart';
import '../../../../shared/widgets/gc_states.dart';
import '../../../../core/theme/colors.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../shared/widgets/scale_camera_screen.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final isKaragar = user?.isKaragar == true;
    final jobsAsync = isKaragar
        ? ref.watch(myJobsProvider)
        : ref.watch(allJobsProvider(null));

    return jobsAsync.when(
      loading: () => const Scaffold(
          body: GcLoadingIndicator(message: 'Loading job...')),
      error: (e, _) =>
          Scaffold(body: GcErrorState(message: e.toString())),
      data: (jobs) {
        final job = jobs.where((j) => j.id == jobId).firstOrNull;
        if (job == null) {
          return const Scaffold(
              body: GcErrorState(message: 'Job not found'));
        }
        return _JobDetailView(job: job, isKaragar: isKaragar);
      },
    );
  }
}

class _JobDetailView extends ConsumerWidget {
  final Job job;
  final bool isKaragar;
  const _JobDetailView({required this.job, required this.isKaragar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuancesAsync = isKaragar
        ? ref.watch(myIssuancesProvider(job.id))
        : ref.watch(issuancesProvider(job.id));
    final receiptsAsync = isKaragar
        ? ref.watch(myReceiptsProvider(job.id))
        : ref.watch(receiptsProvider(job.id));

    return Scaffold(
      backgroundColor: GoldCraftColors.background,
      appBar: AppBar(
        title: Text('Job #${job.jobNumber}'),
        actions: [
          if (isKaragar) _StatusUpdateButton(job: job),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1F0A), Color(0xFF4A3218)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(job.title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  _statusBadge(job.status),
                ]),
                const SizedBox(height: 6),
                Text('#${job.jobNumber}',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white60)),
                const SizedBox(height: 16),
                Row(children: [
                  _headerStat('Weight',
                      '${job.requiredWeightGrams.toStringAsFixed(1)} g'),
                  _headerStat('Issued',
                      '${job.issuedWeightGrams.toStringAsFixed(1)} g'),
                  _headerStat('Outstanding',
                      '${job.outstandingGrams.toStringAsFixed(1)} g'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details
            _infoCard([
            _infoRow('Karagar', job.karagarName,
                icon: Icons.person_outline_rounded),
            _infoRow('Due Date',
                DateFormat('d MMM yyyy').format(job.dueDate),
                icon: Icons.calendar_today_outlined),
            if (job.notes != null)
              _infoRow('Notes', job.notes!,
                  icon: Icons.notes_rounded),
          ]),
          const SizedBox(height: 20),

          // Gold tracking
          _sectionTitle('Gold Tracking'),
          const SizedBox(height: 12),
          Row(children: [
            _goldStat('Issued',
                '${job.issuedWeightGrams.toStringAsFixed(2)} g',
                GoldCraftColors.softAmber, GoldCraftColors.softAmberText),
            const SizedBox(width: 12),
            _goldStat('Returned',
                '${job.returnedWeightGrams.toStringAsFixed(2)} g',
                GoldCraftColors.softGreen, GoldCraftColors.softGreenText),
            const SizedBox(width: 12),
            _goldStat('Outstanding',
                '${job.outstandingGrams.toStringAsFixed(2)} g',
                job.outstandingGrams > 0
                    ? GoldCraftColors.softRed
                    : GoldCraftColors.softGreen,
                job.outstandingGrams > 0
                    ? GoldCraftColors.softRedText
                    : GoldCraftColors.softGreenText),
          ]),
          const SizedBox(height: 24),

          // Quick actions — manager only
          if (!isKaragar &&
              job.status != JobStatus.completed &&
              job.status != JobStatus.cancelled) ...[
            _sectionTitle('Actions'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/material-issuance/new?jobId=${job.id}'),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: const Text('Issue Gold'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/material-receipts/new?jobId=${job.id}'),
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  label: const Text('Receive Gold'),
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ],

          // Issuance history
          _sectionTitle('Gold Issued'),
          const SizedBox(height: 12),
          issuancesAsync.when(
            loading: () => const GcLoadingIndicator(),
            error: (e, _) => GcErrorState(message: e.toString()),
            data: (items) => items.isEmpty
                ? const _EmptyHistory(label: 'No gold issued yet')
                : _TxTable(items: items.map((i) => _TxRow(
                      txId: i.transactionId,
                      weightGrams: i.physicalWeightGrams,
                      isDebit: true,
                      dateTime: i.ocrCapturedAt ?? i.createdAt,
                      ocrImageUrl: i.ocrImageUrl,
                      ocrReading: i.managerOcrGrams,
                      ocrCapturedAt: i.ocrCapturedAt,
                    )).toList()),
          ),
          const SizedBox(height: 20),

          // Receipt history
          _sectionTitle('Gold Received'),
          const SizedBox(height: 12),
          receiptsAsync.when(
            loading: () => const GcLoadingIndicator(),
            error: (e, _) => GcErrorState(message: e.toString()),
            data: (items) => items.isEmpty
                ? const _EmptyHistory(label: 'No gold received yet')
                : _TxTable(items: items.map((i) => _TxRow(
                      txId: i.transactionId,
                      weightGrams: i.physicalWeightGrams,
                      isDebit: false,
                      dateTime: i.createdAt,
                      type: i.receiptType,
                    )).toList()),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: GoldCraftColors.charcoal));

  Widget _headerStat(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Colors.white38)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
      );

  Widget _infoCard(List<Widget> rows) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GoldCraftColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GoldCraftColors.divider),
        ),
        child: Column(children: rows),
      );

  Widget _infoRow(String label, String value, {IconData? icon}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: GoldCraftColors.textHint),
            const SizedBox(width: 10),
          ],
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: GoldCraftColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GoldCraftColors.charcoal)),
        ]),
      );

  Widget _goldStat(String label, String value, Color bg, Color fg) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: fg.withOpacity(0.7))),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
          ]),
        ),
      );

  Widget _statusBadge(JobStatus status) {
    final (type, label) = switch (status) {
      JobStatus.assigned => (GoldCraftBadgeType.info, 'Assigned'),
      JobStatus.inProgress => (GoldCraftBadgeType.warning, 'In Progress'),
      JobStatus.qualityCheck => (GoldCraftBadgeType.warning, 'QC'),
      JobStatus.completed => (GoldCraftBadgeType.success, 'Done'),
      JobStatus.cancelled => (GoldCraftBadgeType.error, 'Cancelled'),
    };
    return GoldCraftBadge(label: label, type: type);
  }
}

class _StatusUpdateButton extends ConsumerWidget {
  final Job job;
  const _StatusUpdateButton({required this.job});

  static const _nextStatus = {
    'assigned': ('inProgress', 'Start Work'),
    'inProgress': ('qualityCheck', 'Send to QC'),
    'qualityCheck': ('completed', 'Mark Complete'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = _nextStatus[job.status.name];
    if (next == null) return const SizedBox.shrink();
    return TextButton(
      onPressed: () async {
        // Starting a job requires OCR verification
        if (job.status == JobStatus.assigned) {
          await _startWithOcr(context, ref);
        } else {
          await _updateStatus(context, ref, next.$1, next.$2);
        }
      },
      child: Text(next.$2,
          style: const TextStyle(
              color: GoldCraftColors.jewelryGold,
              fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _startWithOcr(BuildContext context, WidgetRef ref) async {
    // Step 1: open camera
    final result = await Navigator.of(context).push<OcrResult>(
      MaterialPageRoute(builder: (_) => const ScaleCameraScreen()),
    );
    if (result == null || !context.mounted) return;

    // Step 2: send to backend for verification
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/jobs/${job.id}/verify-ocr',
        data: FormData.fromMap({
          'karagarOcrGrams': result.valueGrams,
          'karagarOcrImage': await MultipartFile.fromFile(
            result.imagePath,
            filename: 'karagar-scale-capture.jpg',
          ),
        }),
      );

      // Step 3: verification passed — update status
      if (context.mounted) {
        await _updateStatus(context, ref, 'inProgress', 'Start Work');
      }
    } on DioException catch (e) {
      if (!context.mounted) return;
      final body = e.response?.data;
      final msg = (body is Map ? body['message'] : null) ??
          mapDioError(e).message;
      if (e.response?.statusCode == 409) {
        await _showOcrMismatchDialog(context, body, msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: GoldCraftColors.softRedText,
        ));
      }
    }
  }

  Future<void> _showOcrMismatchDialog(
    BuildContext context,
    dynamic body,
    String fallbackMessage,
  ) {
    final data = body is Map ? body['data'] : null;
    final managerReading = data is Map ? data['managerOcrGrams'] : null;
    final karagarReading = data is Map ? data['karagarOcrGrams'] : null;
    final difference = data is Map ? data['diff'] : null;
    final tolerance = data is Map ? data['tolerance'] : null;

    String grams(dynamic value) => value is num
        ? '${value.toStringAsFixed(3)} g'
        : 'Unavailable';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: GoldCraftColors.softRedText, size: 38),
        title: const Text('Weight does not match'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'The scale reading must match the manager’s issued-gold reading before work can start.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          _mismatchReading('Manager OCR', grams(managerReading)),
          _mismatchReading('Your OCR', grams(karagarReading)),
          const Divider(height: 24),
          _mismatchReading('Difference', grams(difference),
              valueColor: GoldCraftColors.softRedText),
          _mismatchReading('Allowed tolerance', grams(tolerance)),
          const SizedBox(height: 12),
          Text(fallbackMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: GoldCraftColors.textSecondary)),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mismatchReading(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: GoldCraftColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? GoldCraftColors.charcoal)),
        ]),
      );

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String status, String label) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/jobs/${job.id}/status', data: {'status': status});
      ref.invalidate(myJobsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $label')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: GoldCraftColors.softRedText,
        ));
      }
    }
  }
}

class _TxRow {
  final String txId;
  final double weightGrams;
  final bool isDebit;
  final DateTime dateTime;
  final String? type;
  final String? ocrImageUrl;
  final double? ocrReading;
  final DateTime? ocrCapturedAt;
  const _TxRow({
    required this.txId,
    required this.weightGrams,
    required this.isDebit,
    required this.dateTime,
    this.type,
    this.ocrImageUrl,
    this.ocrReading,
    this.ocrCapturedAt,
  });
}

class _TxTable extends StatelessWidget {
  final List<_TxRow> items;
  const _TxTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final timeFmt = DateFormat('h:mm a');
    final hasOcrEvidence = items.any((r) => r.ocrImageUrl != null);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(GoldCraftColors.background),
          dataRowColor: WidgetStateProperty.all(GoldCraftColors.pureWhite),
          dividerThickness: 1,
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: GoldCraftColors.textSecondary,
            letterSpacing: 0.4,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 12,
            color: GoldCraftColors.charcoal,
          ),
          border: TableBorder.all(
            color: GoldCraftColors.divider,
            borderRadius: BorderRadius.circular(12),
          ),
          columns: [
            const DataColumn(label: Text('TX ID')),
            const DataColumn(label: Text('WEIGHT'), numeric: true),
            if (items.any((r) => r.type != null))
              const DataColumn(label: Text('TYPE')),
            if (hasOcrEvidence) const DataColumn(label: Text('OCR EVIDENCE')),
            const DataColumn(label: Text('DATE')),
            const DataColumn(label: Text('TIME')),
          ],
          rows: items.map((r) {
            final color = r.isDebit
                ? GoldCraftColors.softAmberText
                : GoldCraftColors.softGreenText;
            return DataRow(cells: [
              DataCell(Text(r.txId,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color))),
              DataCell(Text(
                '${r.weightGrams.toStringAsFixed(3)} g',
                style: const TextStyle(fontWeight: FontWeight.w700),
              )),
              if (items.any((x) => x.type != null))
                DataCell(Text(r.type ?? '—',
                    style: const TextStyle(
                        fontSize: 11,
                        color: GoldCraftColors.textSecondary))),
              if (hasOcrEvidence)
                DataCell(r.ocrImageUrl == null
                    ? const Text('No scan',
                        style: TextStyle(
                            fontSize: 11, color: GoldCraftColors.textHint))
                    : _OcrEvidenceCell(
                        imageUrl: r.ocrImageUrl!,
                        reading: r.ocrReading,
                        capturedAt: r.ocrCapturedAt ?? r.dateTime,
                      )),
              DataCell(Text(dateFmt.format(r.dateTime),
                  style: const TextStyle(
                      fontSize: 11,
                      color: GoldCraftColors.textSecondary))),
              DataCell(Text(timeFmt.format(r.dateTime),
                  style: const TextStyle(
                      fontSize: 11,
                      color: GoldCraftColors.textHint))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _OcrEvidenceCell extends StatelessWidget {
  final String imageUrl;
  final double? reading;
  final DateTime capturedAt;
  const _OcrEvidenceCell({
    required this.imageUrl,
    required this.reading,
    required this.capturedAt,
  });

  String get _absoluteImageUrl =>
      Uri.parse(AppConstants.apiBaseUrl).resolve(imageUrl).toString();

  @override
  Widget build(BuildContext context) {
    final capturedLabel =
        DateFormat('d MMM yyyy, h:mm:ss a').format(capturedAt);
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(_absoluteImageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                        child: Text('Evidence image unavailable'))),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reading == null
                          ? 'Scale capture'
                          : 'Live scale: ${reading!.toStringAsFixed(3)} g',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('Captured: $capturedLabel',
                        style: const TextStyle(
                            fontSize: 12, color: GoldCraftColors.textSecondary)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
      child: SizedBox(
        width: 132,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(_absoluteImageUrl,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(Icons.broken_image_outlined, size: 18))),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              reading == null
                  ? DateFormat('h:mm:ss a').format(capturedAt)
                  : '${reading!.toStringAsFixed(3)} g\n${DateFormat('h:mm:ss a').format(capturedAt)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final String label;
  const _EmptyHistory({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13, color: GoldCraftColors.textHint)),
    );
  }
}
