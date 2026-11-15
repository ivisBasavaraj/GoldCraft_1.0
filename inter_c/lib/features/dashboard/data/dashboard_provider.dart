import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/treasury/domain/treasury_model.dart';

final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/reports/dashboard');
    final raw = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : (res.data as Map<String, dynamic>? ?? {});
    final data = raw['data'] as Map<String, dynamic>? ?? raw;

    final treasuryRes = await dio.get('/treasury/summary');
    final treasuryRaw = treasuryRes.data is String
        ? jsonDecode(treasuryRes.data as String) as Map<String, dynamic>
        : (treasuryRes.data as Map<String, dynamic>? ?? {});
    final treasuryData = treasuryRaw['data'] as Map<String, dynamic>? ?? treasuryRaw;

    return DashboardSummary.fromApiJson(data, treasuryData);
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});
