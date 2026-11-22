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
import '../../../../shared/widgets/gc_states.dart';
import '../../../../shared/widgets/gc_ui.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../shared/widgets/scale_camera_screen.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  Widget _shell(Widget body) => GcScaffold(
        isAdmin: false,
        header: const GcPageHeader(title: 'Job Details', showBell: false),
        body: body,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final isKaragar = user?.isKaragar == true;
    final jobsAsync = isKaragar
        ? ref.watch(myJobsProvider)
        : ref.watch(allJobsProvider(null));

    return jobsAsync.when(
      loading: () =>
          _shell(const GcLoadingIndicator(message: 'Loading job...')),
      error: (e, _) => _shell(GcErrorState(message: e.toString())),
      data: (jobs) {
        final job = jobs.where((j) => j.id == jobId).firstOrNull;
        if (job == null) {
          return _shell(const GcErrorState(message: 'Job not found'));
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

    return GcScaffold(
      isAdmin: false,
      header: GcPageHeader(
        title: 'Job Details',
        subtitle: '#${job.jobNumber}',
        showBell: false,
        actions: [
          if (isKaragar) _StatusUpdateButton(job: job),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: GcUi.heroGradient(false),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: GcUi.greenDark.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(job.title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  _statusPill(job.status),
                ]),
                const SizedBox(height: 4),
                Text('#${job.jobNumber}',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 16),
                Row(children: [
                  _headerStat('Weight',
                      '${job.requiredWeightGrams.toStringAsFixed(1)} g'),
                  Container(
                      width: 1,
                      height: 34,
                      color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(width: 12),
                  _headerStat('Issued',
                      '${job.issuedWeightGrams.toStringAsFixed(1)} g'),
                  Container(
                      width: 1,
                      height: 34,
                      color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(width: 12),
                  _headerStat('Outstanding',
                      '${job.outstandingGrams.toStringAsFixed(1)} g',
                      highlight: true),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details
          _infoCard([
            _infoRow('Karagar', job.karagarName,
                icon: Icons.person_outline_rounded),
            _infoRow('Due Date', DateFormat('d MMM yyyy').format(job.dueDate),
                icon: Icons.calendar_today_outlined),
            if (job.notes != null)
              _infoRow('Notes', job.notes!, icon: Icons.notes_rounded),
          ]),
          const SizedBox(height: 22),

          // Gold tracking
          _sectionTitle('Gold Tracking', Icons.scale_outlined),
          const SizedBox(height: 12),
          Row(children: [
            _goldStat('Issued', '${job.issuedWeightGrams.toStringAsFixed(2)} g',
                GcUi.goldTint, GcUi.goldDark),
            const SizedBox(width: 10),
            _goldStat(
                'Returned',
                '${job.returnedWeightGrams.toStringAsFixed(2)} g',
                GcUi.greenTint,
                GcUi.green),
            const SizedBox(width: 10),
            _goldStat(
                'Outstanding',
                '${job.outstandingGrams.toStringAsFixed(2)} g',
                job.outstandingGrams > 0 ? GcUi.redTint : GcUi.greenTint,
                job.outstandingGrams > 0 ? GcUi.red : GcUi.green),
          ]),
          const SizedBox(height: 24),

          // Quick actions — manager only
          if (!isKaragar &&
              job.status != JobStatus.completed &&
              job.status != JobStatus.cancelled) ...[
            _sectionTitle('Actions', Icons.bolt_rounded),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _ActionButton(
                  label: 'Issue Gold',
                  icon: Icons.arrow_upward_rounded,
                  filled: true,
                  onTap: () =>
                      context.push('/material-issuance/new?jobId=${job.id}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Receive Gold',
                  icon: Icons.arrow_downward_rounded,
                  filled: false,
                  onTap: () =>
                      context.push('/material-receipts/new?jobId=${job.id}'),
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ],

          // Issuance history
          _sectionTitle('Gold Issued', Icons.north_east_rounded),
          const SizedBox(height: 12),
          issuancesAsync.when(
            loading: () => const GcLoadingIndicator(),
            error: (e, _) => GcErrorState(message: e.toString()),
            data: (items) => items.isEmpty
                ? const _EmptyHistory(label: 'No gold issued yet')
                : _TxTable(
                    showOcrEvidence: true,
                    items: items
                        .map((i) => _TxRow(
                              txId: i.transactionId,
                              weightGrams: i.physicalWeightGrams,
                              isDebit: true,
                              dateTime: i.ocrCapturedAt ?? i.createdAt,
                              ocrImageUrl: i.ocrImageUrl,
                              ocrReading: i.managerOcrGrams,
                              ocrCapturedAt: i.ocrCapturedAt,
                            ))
                        .toList()),
          ),
          const SizedBox(height: 22),

          // Receipt history
          _sectionTitle('Gold Received', Icons.south_west_rounded),
          const SizedBox(height: 12),
          receiptsAsync.when(
            loading: () => const GcLoadingIndicator(),
            error: (e, _) => GcErrorState(message: e.toString()),
            data: (items) => items.isEmpty
                ? const _EmptyHistory(label: 'No gold received yet')
                : _TxTable(
                    items: items
                        .map((i) => _TxRow(
                              txId: i.transactionId,
                              weightGrams: i.physicalWeightGrams,
                              isDebit: false,
                              dateTime: i.createdAt,
                              type: i.receiptType,
                            ))
                        .toList()),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, IconData icon) => Row(children: [
        Icon(icon, size: 20, color: GcUi.green),
        const SizedBox(width: 8),
        Text(t,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: GcUi.ink)),
      ]);

  Widget _headerStat(String label, String value, {bool highlight = false}) =>
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: highlight ? GcUi.gold : Colors.white)),
          ),
        ]),
      );

  Widget _infoCard(List<Widget> rows) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: GcUi.card(),
        child: Column(children: rows),
      );

  Widget _infoRow(String label, String value, {IconData? icon}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: GcUi.green),
            const SizedBox(width: 10),
          ],
          Text(label,
              style: const TextStyle(fontSize: 13, color: GcUi.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GcUi.ink)),
          ),
        ]),
      );

  Widget _goldStat(String label, String value, Color bg, Color fg) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GcUi.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
            ),
          ]),
        ),
      );

  Widget _statusPill(JobStatus status) {
    final (label, fg, bg) = switch (status) {
      JobStatus.assigned => ('ASSIGNED', GcUi.blue, GcUi.blueTint),
      JobStatus.inProgress => ('IN PROGRESS', GcUi.goldDark, GcUi.goldTint),
      JobStatus.qualityCheck => ('QC', GcUi.goldDark, GcUi.goldTint),
      JobStatus.completed => ('DONE', GcUi.green, GcUi.greenTint),
      JobStatus.cancelled => ('CANCELLED', GcUi.red, GcUi.redTint),
    };
    return GcPill(label: label, fg: fg, bg: bg);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const StadiumBorder(),
          backgroundColor: filled ? GcUi.greenDark : Colors.white,
          foregroundColor: filled ? Colors.white : GcUi.goldDark,
          side: BorderSide(color: filled ? GcUi.greenDark : GcUi.gold, width: 1.4),
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StatusUpdateButton extends ConsumerWidget {
  final Job job;
  const _StatusUpdateButton({required this.job});

  static const _nextStatus = {
    'assigned': ('inProgress', 'Start Work'),
    'inProgress': ('qualityCheck', 'Send to QC'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = _nextStatus[job.status.name];
    if (next == null) return const SizedBox.shrink();
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: GcUi.greenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
      onPressed: () async {
        // Starting a job requires OCR verification
        if (job.status == JobStatus.assigned) {
          await _startWithOcr(context, ref);
        } else {
          await _updateStatus(context, ref, next.$1, next.$2);
        }
      },
      child: Text(next.$2),
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
      final msg =
          (body is Map ? body['message'] : null) ?? mapDioError(e).message;
      if (e.response?.statusCode == 409) {
        await _showOcrMismatchDialog(context, body, msg);
      } else {
        gcSnack(context, msg.toString(), error: true);
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

    String grams(dynamic value) =>
        value is num ? '${value.toStringAsFixed(3)} g' : 'Unavailable';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const GcIconTile(
            icon: Icons.warning_amber_rounded,
            fg: GcUi.red,
            bg: GcUi.redTint,
            size: 56),
        title: const Text('Weight does not match',
            style: TextStyle(fontWeight: FontWeight.w800, color: GcUi.ink)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'The scale reading must match the manager’s issued-gold reading before work can start.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GcUi.muted),
          ),
          const SizedBox(height: 18),
          _mismatchReading('Manager OCR', grams(managerReading)),
          _mismatchReading('Your OCR', grams(karagarReading)),
          const Divider(height: 24, color: GcUi.border),
          _mismatchReading('Difference', grams(difference),
              valueColor: GcUi.red),
          _mismatchReading('Allowed tolerance', grams(tolerance)),
          const SizedBox(height: 12),
          Text(fallbackMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: GcUi.muted)),
        ]),
        actions: [
          GcPrimaryButton(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _mismatchReading(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 13, color: GcUi.muted)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? GcUi.ink)),
        ]),
      );

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String status, String label) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/jobs/${job.id}/status', data: {'status': status});
      ref.invalidate(myJobsProvider);
      if (context.mounted) {
        gcSnack(context, 'Status updated to $label');
        context.pop();
      }
    } on DioException catch (e) {
      if (context.mounted) {
        gcSnack(context, mapDioError(e).message, error: true);
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
  final bool showOcrEvidence;
  const _TxTable({
    required this.items,
    this.showOcrEvidence = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final timeFmt = DateFormat('h:mm a');
    final hasOcrEvidence =
        showOcrEvidence || items.any((r) => r.ocrImageUrl != null);
    final hasType = items.any((r) => r.type != null);

    return Container(
      decoration: GcUi.card(radius: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(GcUi.ivory),
            dataRowColor: WidgetStateProperty.all(Colors.white),
            dividerThickness: 1,
            columnSpacing: 16,
            headingTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: GcUi.muted,
              letterSpacing: 0.4,
            ),
            dataTextStyle: const TextStyle(fontSize: 12, color: GcUi.ink),
            border: const TableBorder(
              horizontalInside: BorderSide(color: GcUi.border),
            ),
            columns: [
              const DataColumn(label: Text('TX ID')),
              const DataColumn(label: Text('WEIGHT'), numeric: true),
              if (hasType) const DataColumn(label: Text('TYPE')),
              if (hasOcrEvidence) const DataColumn(label: Text('OCR EVIDENCE')),
              const DataColumn(label: Text('DATE')),
              const DataColumn(label: Text('TIME')),
            ],
            rows: items.map((r) {
              final color = r.isDebit ? GcUi.goldDark : GcUi.green;
              return DataRow(cells: [
                DataCell(Text(r.txId,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color))),
                DataCell(Text(
                  '${r.weightGrams.toStringAsFixed(3)} g',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                )),
                if (hasType)
                  DataCell(Text(r.type ?? '—',
                      style:
                          const TextStyle(fontSize: 11, color: GcUi.muted))),
                if (hasOcrEvidence)
                  DataCell(r.ocrImageUrl == null
                      ? const Center(
                          child: Text(
                            '-',
                            style: TextStyle(fontSize: 11, color: GcUi.hint),
                          ),
                        )
                      : _OcrEvidenceCell(
                          imageUrl: r.ocrImageUrl!,
                          reading: r.ocrReading,
                          capturedAt: r.ocrCapturedAt ?? r.dateTime,
                        )),
                DataCell(Text(dateFmt.format(r.dateTime),
                    style: const TextStyle(fontSize: 11, color: GcUi.muted))),
                DataCell(Text(timeFmt.format(r.dateTime),
                    style: const TextStyle(fontSize: 11, color: GcUi.hint))),
              ]);
            }).toList(),
          ),
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

  String get _absoluteImageUrl {
    final imageUri = Uri.parse(imageUrl);
    if (imageUri.hasScheme) return imageUri.toString();

    final baseUrl = AppConstants.apiBaseUrl.endsWith('/')
        ? AppConstants.apiBaseUrl
        : '${AppConstants.apiBaseUrl}/';
    final relativePath = imageUrl.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse(baseUrl).resolve(relativePath).toString();
  }

  @override
  Widget build(BuildContext context) {
    final capturedLabel =
        DateFormat('d MMM yyyy, h:mm:ss a').format(capturedAt);
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(_absoluteImageUrl,
                    fit: BoxFit.cover,
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: GcUi.ink),
                    ),
                    const SizedBox(height: 4),
                    Text('Captured: $capturedLabel',
                        style: const TextStyle(
                            fontSize: 12, color: GcUi.muted)),
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
            borderRadius: BorderRadius.circular(8),
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
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: GcUi.card(radius: 18, color: GcUi.ivory),
      child: Text(label,
          style: const TextStyle(fontSize: 13, color: GcUi.muted)),
    );
  }
}