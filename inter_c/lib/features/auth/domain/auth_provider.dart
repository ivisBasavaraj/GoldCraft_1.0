import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import 'auth_models.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/errors/exceptions.dart';

// Holds the currently authenticated user (null = not logged in)
final authUserProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final user = await _repo.getMe();
      state = AsyncValue.data(user);
    } catch (_) {
      await TokenStorage.clearAll();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.login(username: username, password: password);
      state = AsyncValue.data(result.user);
    } on UnauthorizedException catch (_) {
      // 401 on login always means wrong credentials, not expired session
      state = AsyncValue.error(
        const AppException('Invalid username or password.'),
        StackTrace.empty,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}
