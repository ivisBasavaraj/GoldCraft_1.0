import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<({AuthUser user, AuthTokens tokens})> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      // Express returns: { accessToken, refreshToken, user }
      // NestJS returns:  { success, data: { accessToken, refreshToken, user } }
      final body = res.data is Map && res.data['data'] != null
          ? res.data['data'] as Map<String, dynamic>
          : res.data as Map<String, dynamic>;

      final tokens = AuthTokens.fromJson(body);
      final user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
      await TokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return (user: user, tokens: tokens);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthUser> getMe() async {
    try {
      final res = await _dio.get('/auth/me');
      // Express returns user directly; NestJS wraps in data
      final body = res.data is Map && res.data['data'] != null
          ? res.data['data'] as Map<String, dynamic>
          : res.data as Map<String, dynamic>;
      return AuthUser.fromJson(body);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Always clear local tokens even if server call fails
    } finally {
      await TokenStorage.clearAll();
    }
  }
}
