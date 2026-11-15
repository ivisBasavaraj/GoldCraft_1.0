import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/job_model.dart';

Map<String, dynamic> _safe(dynamic data) {
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return (data as Map<String, dynamic>?) ?? {};
}

final myJobsProvider = FutureProvider<List<Job>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/jobs/my-jobs');
    final d = _safe(res.data);
    // findMyJobs returns a plain array: { success, data: [...] }
    // findAll returns paginated:        { success, data: { items: [...] } }
    final raw = d['data'];
    final list = raw is List
        ? raw
        : ((raw as Map<String, dynamic>?)?['items'] as List<dynamic>?) ?? [];
    return list.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

final allJobsProvider =
    FutureProvider.family<List<Job>, String?>((ref, status) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/jobs', queryParameters: {
      if (status != null) 'status': status,
    });
    final d = _safe(res.data);
    final inner = d['data'] as Map<String, dynamic>? ?? {};
    final list = (inner['items'] as List<dynamic>?) ?? [];
    return list.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

/// Fetches jobs for a specific karagar — used by manager on profile screen.
final jobsByKaragarProvider =
    FutureProvider.family<List<Job>, String>((ref, karagarId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/jobs', queryParameters: {'karagarId': karagarId});
    final d = _safe(res.data);
    final inner = d['data'] as Map<String, dynamic>? ?? {};
    final list = (inner['items'] as List<dynamic>?) ?? [];
    return list.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});
