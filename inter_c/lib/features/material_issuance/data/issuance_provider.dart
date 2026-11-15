import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/issuance_model.dart';

Map<String, dynamic> _safe(dynamic data) {
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return (data as Map<String, dynamic>?) ?? {};
}

final issuancesProvider =
    FutureProvider.family<List<MaterialIssuance>, String?>((ref, jobId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/material-issuance', queryParameters: {
      if (jobId != null) 'jobId': jobId,
      'limit': '100',
    });
    final body = _safe(res.data);
    final data = _safe(body['data']);
    final list = (data['items'] as List<dynamic>?) ?? [];
    return list
        .map((i) => MaterialIssuance.fromJson(i as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

/// Fetches issuances scoped to a karagar — used on My Gold screen.
final myIssuancesProvider =
    FutureProvider.family<List<MaterialIssuance>, String?>((ref, jobId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/material-issuance/my', queryParameters: {
      if (jobId != null) 'jobId': jobId,
      'limit': '100',
    });
    final body = _safe(res.data);
    final data = _safe(body['data']);
    final list = (data['items'] as List<dynamic>?) ?? [];
    return list
        .map((i) => MaterialIssuance.fromJson(i as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

class IssuanceRepository {
  final Dio _dio;
  IssuanceRepository(this._dio);

  Future<MaterialIssuance> create({
    required String jobId,
    required double physicalWeightMg,
    String? notes,
    double? managerOcrGrams,
    double? ocrConfidence,
  }) async {
    try {
      final res = await _dio.post('/material-issuance', data: {
        'jobId': jobId,
        'physicalWeightMg': physicalWeightMg,
        if (notes != null) 'notes': notes,
        if (managerOcrGrams != null) 'managerOcrGrams': managerOcrGrams,
        if (ocrConfidence != null) 'ocrConfidence': ocrConfidence,
      });
      final data = _safe(res.data);
      return MaterialIssuance.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final issuanceRepositoryProvider = Provider<IssuanceRepository>(
  (ref) => IssuanceRepository(ref.read(dioProvider)),
);
