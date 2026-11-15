import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/advance_model.dart';

Map<String, dynamic> _safe(dynamic data) {
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return (data as Map<String, dynamic>?) ?? {};
}

final advancesProvider =
    FutureProvider.family<List<Advance>, String?>((ref, karagarId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/advances', queryParameters: {
      if (karagarId != null) 'karagarId': karagarId,
      'limit': '100',
    });
    final data = _safe(res.data);
    final inner = (data['data'] as Map<String, dynamic>?) ?? data;
    final list = (inner['items'] as List<dynamic>?)
        ?? (data['items'] as List<dynamic>?)
        ?? [];
    return list.map((a) => Advance.fromJson(a as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

/// Fetches advances scoped to the logged-in karagar.
final myAdvancesProvider = FutureProvider<List<Advance>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/advances/my', queryParameters: {'limit': '100'});
    final data = _safe(res.data);
    final inner = (data['data'] as Map<String, dynamic>?) ?? data;
    final list = (inner['items'] as List<dynamic>?)
        ?? (data['items'] as List<dynamic>?)
        ?? [];
    return list.map((a) => Advance.fromJson(a as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

final advanceDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/advances/$id');
    final data = _safe(res.data);
    return data['data'] as Map<String, dynamic>;
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

final karagarAdvanceBalanceProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, karagarId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/advances/karagar/$karagarId/balance');
    final data = _safe(res.data);
    return data['data'] as Map<String, dynamic>;
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});
