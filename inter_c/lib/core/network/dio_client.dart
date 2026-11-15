import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../storage/token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {'Content-Type': 'application/json'},
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(LogInterceptor(responseBody: false));
  dio.interceptors.add(_AuthInterceptor(dio));
  return dio;
});

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only attempt refresh for 401s on non-auth endpoints
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('/auth/');
    if (err.response?.statusCode == 401 && !_isRefreshing && !isAuthEndpoint) {
      _isRefreshing = true;
      try {
        final refreshToken = await TokenStorage.getRefreshToken();
        if (refreshToken == null) {
          await TokenStorage.clearAll();
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final body = response.data is Map && response.data['data'] != null
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final newAccess = body['accessToken'] as String;
        final newRefresh = body['refreshToken'] as String;
        await TokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );

        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await _dio.fetch(err.requestOptions);
        handler.resolve(retried);
      } catch (_) {
        await TokenStorage.clearAll();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
      return;
    }
    handler.next(err);
  }
}

AppException mapDioError(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const NetworkException();
  }
  final status = e.response?.statusCode;
  final data = e.response?.data;
  final msg = data is Map ? data['message'] as String? : null;
  return switch (status) {
    401 => const UnauthorizedException(),
    403 => const ForbiddenException(),
    422 => ValidationException(msg ?? 'Validation failed.'),
    500 => ServerException(msg ?? 'Server error. Please try again.'),
    _ => ServerException(msg ?? 'Something went wrong. Please try again.'),
  };
}
