class AppConstants {
  AppConstants._();

  static const String appName = 'GoldCraft ERP';
  static const String appVersion = '1.0.0';

  // API — change to your server IP/domain in production
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.iqonixlabs.io/api/v1',
  );
  static const Duration apiTimeout = Duration(seconds: 60);

  // Storage keys
  static const String keyAccessToken = 'gc_access_token';
  static const String keyRefreshToken = 'gc_refresh_token';
  static const String keyUser = 'gc_user';

  // Pagination
  static const int defaultPageSize = 20;

  // Gold precision — store as milligrams (integer), display as grams (3dp)
  static const int mgPerGram = 1000;
}
