import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/colors.dart';

class OcrResult {
  final double valueGrams;
  final String reading;
  final double confidence;
  const OcrResult({
    required this.valueGrams,
    required this.reading,
    required this.confidence,
  });
}

class ScaleCameraScreen extends ConsumerStatefulWidget {
  const ScaleCameraScreen({super.key});

  @override
  ConsumerState<ScaleCameraScreen> createState() => _ScaleCameraScreenState();
}

class _ScaleCameraScreenState extends ConsumerState<ScaleCameraScreen> {
  CameraController? _ctrl;
  bool _initialising = true;
  bool _scanning = false;
  bool _wakingUp = false;
  String? _error;
  OcrResult? _result;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _initialising = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
          _initialising = false;
        });
        return;
      }
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _ctrl = CameraController(cam, ResolutionPreset.high, enableAudio: false);
      await _ctrl!.initialize();
      if (mounted) setState(() => _initialising = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _initialising = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_ctrl == null || !_ctrl!.value.isInitialized || _scanning) return;
    setState(() {
      _scanning = true;
      _result = null;
      _error = null;
      _wakingUp = false;
    });

    try {
      final xFile = await _ctrl!.takePicture();

      final dio = ref.read(dioProvider);
      final ocrDio = Dio(dio.options.copyWith(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 60),
      ));
      ocrDio.interceptors.addAll(dio.interceptors);

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _scanning) setState(() => _wakingUp = true);
      });

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(xFile.path, filename: 'scale.jpg'),
      });

      final res = await ocrDio.post('/ocr/read-scale', data: formData);
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;

      try {
        File(xFile.path).deleteSync();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _result = OcrResult(
            valueGrams: (data['valueGrams'] as num).toDouble(),
            reading: data['reading'] as String,
            confidence: (data['confidence'] as num).toDouble(),
          );
          _scanning = false;
          _wakingUp = false;
        });
      }
    } on DioException catch (e) {
<<<<<<< HEAD
      if (mounted) setState(() {
        final responseData = e.response?.data;
        final message = responseData is Map
            ? responseData['message'] as String?
            : null;
        _error = e.response?.statusCode == 422
            ? 'Could not read digits — try better lighting or angle'
            : message ?? 'OCR service is unavailable — tap Retry to try again';
        _scanning = false;
        _wakingUp = false;
      });
=======
      if (mounted) {
        setState(() {
          _error = e.response?.statusCode == 422
              ? 'Could not read digits — try better lighting or angle'
              : 'Request timed out — tap Retry to try again';
          _scanning = false;
          _wakingUp = false;
        });
      }
>>>>>>> f60574dbe3e32db7ec2b0ae2557b810ad129e4d7
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: ${e.toString()}';
          _scanning = false;
          _wakingUp = false;
        });
      }
    }
  }

  void _confirm() {
    if (_result != null) Navigator.of(context).pop(_result);
  }

  void _retake() => setState(() {
        _result = null;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Weight Scale'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _initialising
          ? const Center(
              child:
                  CircularProgressIndicator(color: GoldCraftColors.jewelryGold))
          : _error != null && _ctrl == null
              ? _ErrorView(message: _error!, onRetry: _initCamera)
              : Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_ctrl!),
                          CustomPaint(painter: _TargetOverlayPainter()),
                          if (_scanning)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                      color: GoldCraftColors.jewelryGold),
                                  if (_wakingUp) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Processing image...\nThis may take a few seconds',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      color: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: _result != null
                          ? _ResultPanel(
                              result: _result!,
                              onConfirm: _confirm,
                              onRetake: _retake,
                            )
                          : _CapturePanel(
                              onCapture: _scanning ? null : _capture,
                              error: _error,
                              onRetry: _error != null ? _retake : null,
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _TargetOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final targetRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.75,
      height: size.height * 0.18,
    );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), dimPaint);
    canvas.drawRect(targetRect, Paint()..blendMode = BlendMode.clear);

    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(8)),
      Paint()
        ..color = GoldCraftColors.jewelryGold.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    const len = 18.0;
    final corners = [
      [targetRect.topLeft, const Offset(len, 0), const Offset(0, len)],
      [targetRect.topRight, const Offset(-len, 0), const Offset(0, len)],
      [targetRect.bottomLeft, const Offset(len, 0), const Offset(0, -len)],
      [targetRect.bottomRight, const Offset(-len, 0), const Offset(0, -len)],
    ];
    final cornerPaint = Paint()
      ..color = GoldCraftColors.jewelryGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (final c in corners) {
      final origin = c[0];
      canvas.drawLine(origin, origin + c[1], cornerPaint);
      canvas.drawLine(origin, origin + c[2], cornerPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CapturePanel extends StatelessWidget {
  final VoidCallback? onCapture;
  final VoidCallback? onRetry;
  final String? error;
  const _CapturePanel({this.onCapture, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Align the scale display inside the frame\nthen tap Capture',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        if (error != null && onRetry != null)
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _captureButton(onCapture)),
          ])
        else
          _captureButton(onCapture),
      ],
    );
  }

  Widget _captureButton(VoidCallback? onCapture) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onCapture,
          style: ElevatedButton.styleFrom(
            backgroundColor: onCapture != null
                ? GoldCraftColors.jewelryGold
                : Colors.grey.shade700,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.camera_alt_rounded, size: 22),
          label: const Text('Capture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}

class _ResultPanel extends StatelessWidget {
  final OcrResult result;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;
  const _ResultPanel({
    required this.result,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final confPct = (result.confidence * 100).toStringAsFixed(0);
    final confColor = result.confidence >= 0.80
        ? const Color(0xFF81C784)
        : result.confidence >= 0.60
            ? GoldCraftColors.softAmberText
            : Colors.redAccent;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GoldCraftColors.jewelryGold.withValues(alpha: 0.4),
            ),
          ),
          child: Column(children: [
            const Text('Scale Reading',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 6),
            Text(
              '${result.valueGrams.toStringAsFixed(3)} g',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: GoldCraftColors.jewelryGold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.verified_outlined,
                  size: 13, color: Colors.white38),
              const SizedBox(width: 4),
              Text('Confidence: $confPct%',
                  style: TextStyle(fontSize: 12, color: confColor)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRetake,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retake'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: GoldCraftColors.jewelryGold,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Use This'),
            ),
          ),
        ]),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.camera_alt_outlined,
              color: Colors.white38, size: 48),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}
