import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/payroll_model.dart';

Map<String, dynamic> _safe(dynamic data) {
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return (data as Map<String, dynamic>?) ?? {};
}

final payrollsProvider =
    FutureProvider.family<List<Payroll>, String?>((ref, karagarId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/payroll', queryParameters: {
      if (karagarId != null) 'karagarId': karagarId,
      'limit': '100',
    });
    final data = _safe(res.data);
    final inner = (data['data'] as Map<String, dynamic>?) ?? data;
    final list = (inner['items'] as List<dynamic>?) ?? [];
    return list
        .map((p) => Payroll.fromJson(p as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

/// Fetches payroll records scoped to the logged-in karagar.
final myPayrollsProvider = FutureProvider<List<Payroll>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/payroll/my', queryParameters: {'limit': '100'});
    final data = _safe(res.data);
    final inner = (data['data'] as Map<String, dynamic>?) ?? data;
    final list = (inner['items'] as List<dynamic>?) ?? [];
    return list
        .map((p) => Payroll.fromJson(p as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

final payrollDetailProvider =
    FutureProvider.family<Payroll, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/payroll/$id');
    final data = _safe(res.data);
    final inner = (data['data'] as Map<String, dynamic>?) ?? data;
    return Payroll.fromJson(inner);
  } on DioException catch (e) {
    throw mapDioError(e);
  }
});

class PayrollRepository {
  final Dio _dio;
  PayrollRepository(this._dio);

  /// Creates a payroll record and immediately marks it as paid in one step.
  /// Calls POST /payroll which is the stable existing endpoint.
  Future<Payroll> generate({
    required String karagarId,
    required String periodStart,
    required String periodEnd,
    double amountRupees = 0,
  }) async {
    try {
      final res = await _dio.post('/payroll', data: {
        'karagarId': karagarId,
        'periodStart': periodStart,
        'periodEnd': periodEnd,
        'paidRupees': amountRupees,
      });
      final data = _safe(res.data);
      final inner = data['data'] as Map<String, dynamic>? ?? data;
      return Payroll.fromJson(inner);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Approves the payroll and recalculates net payable on the backend.
  Future<Payroll> approve(String id,
      {double? incentiveRupees, double? penaltyRupees, String? notes}) async {
    try {
      final res = await _dio.post('/payroll/$id/approve', data: {
        if (incentiveRupees != null) 'approvedIncentiveRupees': incentiveRupees,
        if (penaltyRupees != null) 'approvedPenaltyRupees': penaltyRupees,
        if (notes != null) 'notes': notes,
      });
      final data = _safe(res.data);
      final inner = data['data'] as Map<String, dynamic>? ?? data;
      return Payroll.fromJson(inner);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Payroll> recordPayment(String id, double amountRupees) async {
    try {
      final res = await _dio.post('/payroll/$id/payment', data: {
        'amountRupees': amountRupees,
      });
      final data = _safe(res.data);
      final inner = data['data'] as Map<String, dynamic>? ?? data;
      return Payroll.fromJson(inner);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final payrollRepositoryProvider = Provider<PayrollRepository>(
  (ref) => PayrollRepository(ref.read(dioProvider)),
);
