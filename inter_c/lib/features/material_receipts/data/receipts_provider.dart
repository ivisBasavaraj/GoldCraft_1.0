import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/receipt_model.dart';

Map<String, dynamic> _safe(dynamic data) {
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return (data as Map<String, dynamic>?) ?? {};
}

final receiptsProvider =
    FutureProvider.family<List<MaterialReceipt>, String?>((ref, jobId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/material-receipts', queryParameters: {
      if (jobId != null) 'jobId': jobId,
      'limit': '100',
    });
    final body = _safe(res.data);
    final data = _safe(body['data']);
    final list = (data['items'] as List<dynamic>?) ?? [];
    return list
        .map((r) => MaterialReceipt.fromJson(r as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

/// Fetches receipts scoped to a karagar — used on My Gold screen.
final myReceiptsProvider =
    FutureProvider.family<List<MaterialReceipt>, String?>((ref, jobId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/material-receipts/my', queryParameters: {
      if (jobId != null) 'jobId': jobId,
      'limit': '100',
    });
    final body = _safe(res.data);
    final data = _safe(body['data']);
    final list = (data['items'] as List<dynamic>?) ?? [];
    return list
        .map((r) => MaterialReceipt.fromJson(r as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

class ReceiptRepository {
  final Dio _dio;
  ReceiptRepository(this._dio);

  Future<MaterialReceipt> create({
    required String jobId,
    required String receiptType,
    required double physicalWeightMg,
    String? notes,
  }) async {
    try {
      final res = await _dio.post('/material-receipts', data: {
        'jobId': jobId,
        'receiptType': receiptType,
        'physicalWeightMg': physicalWeightMg,
        if (notes != null) 'notes': notes,
      });
      final data = _safe(res.data);
      return MaterialReceipt.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepository(ref.read(dioProvider)),
);
