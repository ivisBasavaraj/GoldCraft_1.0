import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/karagar_model.dart';

Map<String, dynamic> _safe(dynamic data) {
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return (data as Map<String, dynamic>?) ?? {};
}

final karagarsProvider = FutureProvider<List<Karagar>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/karagars');
    final d = _safe(res.data);
    final inner = d['data'] as Map<String, dynamic>? ?? {};
    final list = (inner['items'] as List<dynamic>?) ?? [];
    return list.map((k) => Karagar.fromJson(k as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});
