import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/treasury_model.dart';

Map<String, dynamic> _safe(dynamic data) {
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return (data as Map<String, dynamic>?) ?? {};
}

final treasurySummaryProvider = FutureProvider<TreasurySummary>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/treasury/summary');
    final data = _safe(res.data);
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    return TreasurySummary.fromJson(inner);
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

final treasuryTransactionsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, page) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/treasury/transactions',
        queryParameters: {'page': page, 'limit': 20});
    final data = _safe(res.data);
    return data['data'] as Map<String, dynamic>? ?? data;
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});
