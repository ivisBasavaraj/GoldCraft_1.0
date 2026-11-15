import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final p = await _prefs;
    await p.setString(AppConstants.keyAccessToken, accessToken);
    await p.setString(AppConstants.keyRefreshToken, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final p = await _prefs;
    return p.getString(AppConstants.keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final p = await _prefs;
    return p.getString(AppConstants.keyRefreshToken);
  }

  static Future<void> clearAll() async {
    final p = await _prefs;
    await p.remove(AppConstants.keyAccessToken);
    await p.remove(AppConstants.keyRefreshToken);
    await p.remove(AppConstants.keyUser);
  }
}
