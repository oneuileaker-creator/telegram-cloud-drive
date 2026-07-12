
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://telegram-cloud-drive-9yx2.onrender.com'; // Production
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // Windows

  // Auth
  static const String register    = '/api/auth/register';
  static const String login       = '/api/auth/login';
  static const String me          = '/api/auth/me';
  static const String tgConnect   = '/api/auth/telegram/connect';
  static const String tgVerify    = '/api/auth/telegram/verify';
  static const String tgDisconnect= '/api/auth/telegram/disconnect';

  // Files
  static const String filesUpload = '/api/files/upload';
  static const String filesList   = '/api/files/list';
  static const String filesStatus = '/api/files/status';
  static const String filesDownload = '/api/files/download';

  // Folders
  static const String folders     = '/api/folders';
  static const String folderTree  = '/api/folders/tree';

  // Media
  static const String photos      = '/api/media/photos';
  static const String videos      = '/api/media/videos';
  static const String audio       = '/api/media/audio';
  static const String thumbnail   = '/api/media/thumbnail';
  static const String favorites   = '/api/media/favorites';

  // Search
  static const String search      = '/api/search';
  static const String searchStats = '/api/search/stats';
  static const String searchRecent= '/api/search/recent';
}
