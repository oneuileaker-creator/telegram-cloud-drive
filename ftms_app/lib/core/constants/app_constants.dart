
class AppConstants {
  AppConstants._();

  static const String appName     = 'FTMS';
  static const String appVersion  = '1.0.0';
  static const String tokenKey    = 'ftms_token';
  static const String userKey     = 'ftms_user';
  static const String themeKey    = 'ftms_theme';

  // Pagination
  static const int defaultPageSize = 50;
  static const int photoPageSize   = 60;

  // Cache
  static const int thumbnailCacheSize = 100;
  static const Duration tokenExpiry = Duration(hours: 24);

  // File size limits (display)
  static const int maxUploadGB = 10;
}
