Phase 3: Flutter App - Complete Code
Every File, Every Screen
Step 1: Setup
Bash

# Create Flutter project
flutter create ftms_app --platforms=android,windows
cd ftms_app

# Create all folders
mkdir -p lib/core/constants
mkdir -p lib/core/theme
mkdir -p lib/core/router
mkdir -p lib/core/network
mkdir -p lib/core/utils
mkdir -p lib/features/auth/data
mkdir -p lib/features/auth/bloc
mkdir -p lib/features/auth/presentation/widgets
mkdir -p lib/features/home/bloc
mkdir -p lib/features/home/presentation/widgets
mkdir -p lib/features/files/data
mkdir -p lib/features/files/bloc
mkdir -p lib/features/files/models
mkdir -p lib/features/files/presentation/widgets
mkdir -p lib/features/photos/bloc
mkdir -p lib/features/photos/presentation/widgets
mkdir -p lib/features/videos/presentation
mkdir -p lib/features/audio/presentation
mkdir -p lib/features/documents/presentation
mkdir -p lib/features/search/bloc
mkdir -p lib/features/search/presentation
mkdir -p lib/features/settings/presentation
mkdir -p lib/shared/widgets
mkdir -p lib/shared/models
mkdir -p assets/images
mkdir -p assets/animations
mkdir -p assets/icons
Step 2: Core - Constants
dart

// lib/core/constants/api_constants.dart

class ApiConstants {
  ApiConstants._();

  // Change this to your Render URL when deployed
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // Windows
  // static const String baseUrl = 'https://ftms-backend.onrender.com'; // Production

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
dart

// lib/core/constants/app_constants.dart

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
dart

// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary      = Color(0xFF6C63FF);
  static const Color primaryDark  = Color(0xFF4B44CC);
  static const Color accent       = Color(0xFF00D2FF);

  // Background
  static const Color bgDark       = Color(0xFF0F0F1A);
  static const Color bgCard       = Color(0xFF1A1A2E);
  static const Color bgElevated   = Color(0xFF242440);

  // Surface
  static const Color surface      = Color(0xFF1E1E3A);
  static const Color surfaceLight = Color(0xFF2A2A4A);

  // Text
  static const Color textPrimary  = Color(0xFFEEEEFF);
  static const Color textSecondary= Color(0xFF9999BB);
  static const Color textHint     = Color(0xFF5555AA);

  // Status
  static const Color success      = Color(0xFF00C896);
  static const Color warning      = Color(0xFFFFB347);
  static const Color error        = Color(0xFFFF6B6B);
  static const Color info         = Color(0xFF45B7D1);

  // FTMS Category Colors
  static const Color imageColor   = Color(0xFFFF6B6B);
  static const Color videoColor   = Color(0xFF4ECDC4);
  static const Color audioColor   = Color(0xFF45B7D1);
  static const Color documentColor= Color(0xFF96CEB4);
  static const Color codeColor    = Color(0xFFA29BFE);
  static const Color archiveColor = Color(0xFFFFEAA7);
  static const Color fontColor    = Color(0xFFFD79A8);
  static const Color otherColor   = Color(0xFFB2BEC3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Category gradient helper
  static LinearGradient categoryGradient(Color color) => LinearGradient(
    colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
dart

// lib/core/constants/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}
Step 3: Theme
dart

// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    primaryColor: AppColors.primary,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      background: AppColors.bgDark,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headlineMedium,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    // Cards
    cardTheme: CardTheme(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),

    // Bottom Nav
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.bgCard,
      indicatorColor: AppColors.primary.withOpacity(0.2),
      labelTextStyle: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
          ? AppTextStyles.label.copyWith(color: AppColors.primary)
          : AppTextStyles.label,
      ),
      iconTheme: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
          ? const IconThemeData(color: AppColors.primary, size: 24)
          : const IconThemeData(color: AppColors.textSecondary, size: 22),
      ),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.surfaceLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 16
      ),
      hintStyle: AppTextStyles.bodyMedium,
      labelStyle: AppTextStyles.bodyMedium,
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 16
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: AppTextStyles.titleMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.titleMedium,
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceLight,
      thickness: 1,
    ),

    // Icon
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: 22,
    ),

    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      labelSmall: AppTextStyles.caption,
    ),
  );
}
Step 4: Models
dart

// lib/features/files/models/file_model.dart

class FileModel {
  final String id;
  final String originalName;
  final String? displayName;
  final String fileType;
  final String? mimeType;
  final String? extension;
  final int sizeBytes;
  final bool isChunked;
  final int totalChunks;
  final String uploadStatus;
  final List<String> tags;
  final bool isFavorite;
  final Map<String, dynamic> fileMetadata;
  final String? folderId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FileModel({
    required this.id,
    required this.originalName,
    this.displayName,
    required this.fileType,
    this.mimeType,
    this.extension,
    required this.sizeBytes,
    required this.isChunked,
    required this.totalChunks,
    required this.uploadStatus,
    required this.tags,
    required this.isFavorite,
    required this.fileMetadata,
    this.folderId,
    required this.createdAt,
    this.updatedAt,
  });

  String get name => displayName ?? originalName;

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
    id:            json['id'],
    originalName:  json['original_name'],
    displayName:   json['display_name'],
    fileType:      json['file_type'] ?? 'other',
    mimeType:      json['mime_type'],
    extension:     json['extension'],
    sizeBytes:     json['size_bytes'] ?? 0,
    isChunked:     json['is_chunked'] ?? false,
    totalChunks:   json['total_chunks'] ?? 1,
    uploadStatus:  json['upload_status'] ?? 'pending',
    tags:          List<String>.from(json['tags'] ?? []),
    isFavorite:    json['is_favorite'] ?? false,
    fileMetadata:  Map<String, dynamic>.from(json['file_metadata'] ?? {}),
    folderId:      json['folder_id'],
    createdAt:     DateTime.parse(json['created_at']),
    updatedAt:     json['updated_at'] != null
                    ? DateTime.parse(json['updated_at'])
                    : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'original_name': originalName,
    'display_name': displayName,
    'file_type': fileType,
    'mime_type': mimeType,
    'extension': extension,
    'size_bytes': sizeBytes,
    'is_chunked': isChunked,
    'total_chunks': totalChunks,
    'upload_status': uploadStatus,
    'tags': tags,
    'is_favorite': isFavorite,
    'file_metadata': fileMetadata,
    'folder_id': folderId,
    'created_at': createdAt.toIso8601String(),
  };

  FileModel copyWith({
    String? displayName,
    List<String>? tags,
    bool? isFavorite,
    String? folderId,
  }) => FileModel(
    id: id,
    originalName: originalName,
    displayName: displayName ?? this.displayName,
    fileType: fileType,
    mimeType: mimeType,
    extension: extension,
    sizeBytes: sizeBytes,
    isChunked: isChunked,
    totalChunks: totalChunks,
    uploadStatus: uploadStatus,
    tags: tags ?? this.tags,
    isFavorite: isFavorite ?? this.isFavorite,
    fileMetadata: fileMetadata,
    folderId: folderId ?? this.folderId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
dart

// lib/features/files/models/folder_model.dart

class FolderModel {
  final String id;
  final String name;
  final String? parentId;
  final String path;
  final String color;
  final String icon;
  final int childrenCount;
  final int fileCount;
  final DateTime createdAt;

  const FolderModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.path,
    required this.color,
    required this.icon,
    required this.childrenCount,
    required this.fileCount,
    required this.createdAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) => FolderModel(
    id:             json['id'],
    name:           json['name'],
    parentId:       json['parent_id'],
    path:           json['path'],
    color:          json['color'] ?? '#4ECDC4',
    icon:           json['icon'] ?? 'folder',
    childrenCount:  json['children_count'] ?? 0,
    fileCount:      json['file_count'] ?? 0,
    createdAt:      DateTime.parse(json['created_at']),
  );
}
dart

// lib/features/auth/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String username;
  final bool isTelegramConnected;
  final int storageUsedBytes;
  final int totalFiles;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.isTelegramConnected,
    required this.storageUsedBytes,
    required this.totalFiles,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:                   json['id'],
    email:                json['email'],
    username:             json['username'],
    isTelegramConnected:  json['is_telegram_connected'] ?? false,
    storageUsedBytes:     json['storage_used_bytes'] ?? 0,
    totalFiles:           json['total_files'] ?? 0,
    createdAt:            DateTime.parse(json['created_at']),
  );
}
dart

// lib/shared/models/pagination_model.dart

import '../../features/files/models/file_model.dart';

class PaginatedFiles {
  final List<FileModel> files;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const PaginatedFiles({
    required this.files,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory PaginatedFiles.fromJson(Map<String, dynamic> json) => PaginatedFiles(
    files:   (json['files'] as List)
                .map((f) => FileModel.fromJson(f))
                .toList(),
    total:   json['total'] ?? 0,
    page:    json['page'] ?? 1,
    limit:   json['limit'] ?? 50,
    hasMore: json['has_more'] ?? false,
  );
}
Step 5: Network Layer
dart

// lib/core/network/dio_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),  // Large files
        sendTimeout: const Duration(minutes: 30),    // Upload timeout
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      PrettyDioLogger(
        requestHeader: false,
        requestBody: false,
        responseBody: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  static DioClient get instance => _instance ??= DioClient._();
  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired - clear and redirect to login
      _storage.delete(key: AppConstants.tokenKey);
    }
    handler.next(err);
  }
}
dart

// lib/core/network/api_exception.dart

import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromDioError(DioException e) {
    String msg = 'Something went wrong';

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      msg = 'Connection timeout. Check your internet.';
    } else if (e.type == DioExceptionType.connectionError) {
      msg = 'Cannot connect to server';
    } else if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('detail')) {
        msg = data['detail'].toString();
      } else {
        msg = 'Server error (${e.response!.statusCode})';
      }
    }

    return ApiException(
      message: msg,
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
Step 6: Core Utils
dart

// lib/core/utils/file_utils.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FileUtils {

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'image':    return AppColors.imageColor;
      case 'video':    return AppColors.videoColor;
      case 'audio':    return AppColors.audioColor;
      case 'document': return AppColors.documentColor;
      case 'code':     return AppColors.codeColor;
      case 'archive':  return AppColors.archiveColor;
      case 'font':     return AppColors.fontColor;
      default:         return AppColors.otherColor;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'image':    return Icons.image_rounded;
      case 'video':    return Icons.videocam_rounded;
      case 'audio':    return Icons.music_note_rounded;
      case 'document': return Icons.description_rounded;
      case 'code':     return Icons.code_rounded;
      case 'archive':  return Icons.folder_zip_rounded;
      case 'font':     return Icons.font_download_rounded;
      default:         return Icons.insert_drive_file_rounded;
    }
  }

  static String getCategoryLabel(String category) {
    switch (category) {
      case 'image':    return 'Photos';
      case 'video':    return 'Videos';
      case 'audio':    return 'Music';
      case 'document': return 'Documents';
      case 'code':     return 'Code';
      case 'archive':  return 'Archives';
      default:         return 'Other';
    }
  }

  static String formatDuration(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }
}
dart

// lib/core/utils/date_utils.dart

import 'package:intl/intl.dart';

class FTMSDateUtils {

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatDate(DateTime date) =>
    DateFormat('MMM d, yyyy').format(date);

  static String formatDateTime(DateTime date) =>
    DateFormat('MMM d, yyyy • h:mm a').format(date);
}
Step 7: Router
dart

// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/telegram_connect_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/files/presentation/files_screen.dart';
import '../../features/files/presentation/folder_screen.dart';
import '../../features/photos/presentation/photos_screen.dart';
import '../../features/photos/presentation/photo_viewer.dart';
import '../../features/videos/presentation/videos_screen.dart';
import '../../features/videos/presentation/video_player_screen.dart';
import '../../features/audio/presentation/audio_screen.dart';
import '../../features/audio/presentation/audio_player_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/documents/presentation/pdf_viewer_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/ftms_shell.dart';
import '../constants/app_constants.dart';
import '../../features/files/models/file_model.dart';

final _storage = const FlutterSecureStorage();

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final isAuth = token != null;
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                        state.matchedLocation.startsWith('/register');

    if (!isAuth && !isAuthRoute) return '/login';
    if (isAuth && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    // ── Auth Routes ───────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (ctx, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (ctx, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/telegram-connect',
      builder: (ctx, state) => const TelegramConnectScreen(),
    ),

    // ── Main Shell (Bottom Nav) ───────────────────────────
    ShellRoute(
      builder: (ctx, state, child) => FTMSShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (ctx, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/files',
          builder: (ctx, state) => const FilesScreen(),
          routes: [
            GoRoute(
              path: 'folder/:id',
              builder: (ctx, state) => FolderScreen(
                folderId: state.pathParameters['id']!,
                folderName: state.uri.queryParameters['name'] ?? 'Folder',
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/photos',
          builder: (ctx, state) => const PhotosScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (ctx, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (ctx, state) => const SettingsScreen(),
        ),
      ],
    ),

    // ── Media Routes (Full screen - outside shell) ────────
    GoRoute(
      path: '/photo-viewer',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PhotoViewer(
          files: extra['files'] as List<FileModel>,
          initialIndex: extra['index'] as int,
        );
      },
    ),
    GoRoute(
      path: '/video-player',
      builder: (ctx, state) => VideoPlayerScreen(
        file: state.extra as FileModel,
      ),
    ),
    GoRoute(
      path: '/audio-player',
      builder: (ctx, state) => AudioPlayerScreen(
        file: state.extra as FileModel,
      ),
    ),
    GoRoute(
      path: '/pdf-viewer',
      builder: (ctx, state) => PdfViewerScreen(
        file: state.extra as FileModel,
      ),
    ),
    GoRoute(
      path: '/videos',
      builder: (ctx, state) => const VideosScreen(),
    ),
    GoRoute(
      path: '/audio',
      builder: (ctx, state) => const AudioScreen(),
    ),
    GoRoute(
      path: '/documents',
      builder: (ctx, state) => const DocumentsScreen(),
    ),
  ],
);
Step 8: Shared Widgets
dart

// lib/shared/widgets/ftms_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class FTMSShell extends StatelessWidget {
  final Widget child;
  const FTMSShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home'))    return 0;
    if (location.startsWith('/files'))   return 1;
    if (location.startsWith('/photos'))  return 2;
    if (location.startsWith('/search'))  return 3;
    if (location.startsWith('/settings'))return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(currentIndex: _currentIndex(context)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceLight,
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home');     break;
            case 1: context.go('/files');    break;
            case 2: context.go('/photos');   break;
            case 3: context.go('/search');   break;
            case 4: context.go('/settings'); break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: 'Photos',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
dart

// lib/shared/widgets/loading_widget.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class LoadingGrid extends StatelessWidget {
  final int count;
  const LoadingGrid({super.key, this.count = 9});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: count,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.bgCard,
        highlightColor: AppColors.bgElevated,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  final int count;
  const LoadingList({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.bgCard,
        highlightColor: AppColors.bgElevated,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class FTMSLoader extends StatelessWidget {
  final String? message;
  const FTMSLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
dart

// lib/shared/widgets/empty_state_widget.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
Step 9: Auth Feature
dart

// lib/features/auth/data/auth_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _dio = DioClient.instance.dio;
  final _storage = const FlutterSecureStorage();

  Future<String> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.register, data: {
        'email': email,
        'username': username,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: AppConstants.tokenKey, value: token);
      return token;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: AppConstants.tokenKey, value: token);
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> getToken() =>
    _storage.read(key: AppConstants.tokenKey);

  // Telegram
  Future<Map<String, dynamic>> telegramConnect({
    required int apiId,
    required String apiHash,
    required String phoneNumber,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.tgConnect, data: {
        'api_id': apiId,
        'api_hash': apiHash,
        'phone_number': phoneNumber,
      });
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> telegramVerify({
    required String phoneNumber,
    required String code,
    required String phoneCodeHash,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.tgVerify, data: {
        'phone_number': phoneNumber,
        'code': code,
        'phone_code_hash': phoneCodeHash,
      });
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
dart

// lib/features/auth/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
  @override List<Object?> get props => [email, password];
}
class RegisterRequested extends AuthEvent {
  final String email, username, password;
  RegisterRequested(this.email, this.username, this.password);
}
class LogoutRequested extends AuthEvent {}
class CheckAuthStatus extends AuthEvent {}
class TelegramConnectRequested extends AuthEvent {
  final int apiId;
  final String apiHash, phoneNumber;
  TelegramConnectRequested(this.apiId, this.apiHash, this.phoneNumber);
}
class TelegramVerifyRequested extends AuthEvent {
  final String phoneNumber, code, phoneCodeHash;
  TelegramVerifyRequested(this.phoneNumber, this.code, this.phoneCodeHash);
}

// States
abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}
class TelegramCodeSent extends AuthState {
  final String phoneCodeHash;
  TelegramCodeSent(this.phoneCodeHash);
}
class TelegramConnected extends AuthState {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {

    on<CheckAuthStatus>((event, emit) async {
      final token = await _repo.getToken();
      if (token != null) {
        try {
          final user = await _repo.getMe();
          emit(AuthAuthenticated(user));
        } catch (_) {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _repo.login(
          email: event.email,
          password: event.password,
        );
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _repo.register(
          email: event.email,
          username: event.username,
          password: event.password,
        );
        final user = await _repo.getMe();
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await _repo.logout();
      emit(AuthUnauthenticated());
    });

    on<TelegramConnectRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final result = await _repo.telegramConnect(
          apiId: event.apiId,
          apiHash: event.apiHash,
          phoneNumber: event.phoneNumber,
        );
        emit(TelegramCodeSent(result['phone_code_hash']));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<TelegramVerifyRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _repo.telegramVerify(
          phoneNumber: event.phoneNumber,
          code: event.code,
          phoneCodeHash: event.phoneCodeHash,
        );
        final user = await _repo.getMe();
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
dart

// lib/features/auth/presentation/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(_emailCtrl.text.trim(), _passCtrl.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (!state.user.isTelegramConnected) {
              context.go('/telegram-connect');
            } else {
              context.go('/home');
            }
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Logo
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.cloud_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text('Welcome back', style: AppTextStyles.displayMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your FTMS account',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 40),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => v!.contains('@')
                        ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => v!.length >= 8
                        ? null : 'Min 8 characters',
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _submit,
                        child: state is AuthLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
dart

// lib/features/auth/presentation/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(RegisterRequested(
        _emailCtrl.text.trim(),
        _usernameCtrl.text.trim(),
        _passCtrl.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/telegram-connect');
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    IconButton(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                    ),
                    const SizedBox(height: 24),
                    Text('Create account', style: AppTextStyles.displayMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Your unlimited cloud starts here',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 40),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                        v!.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 16),

                    // Username
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (v) =>
                        v!.length >= 3 ? null : 'Min 3 characters',
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                        v!.length >= 8 ? null : 'Min 8 characters',
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _submit,
                        child: state is AuthLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTextStyles.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
dart

// lib/features/auth/presentation/telegram_connect_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../bloc/auth_bloc.dart';

class TelegramConnectScreen extends StatefulWidget {
  const TelegramConnectScreen({super.key});

  @override
  State<TelegramConnectScreen> createState() => _TelegramConnectScreenState();
}

class _TelegramConnectScreenState extends State<TelegramConnectScreen> {
  final _apiIdCtrl    = TextEditingController();
  final _apiHashCtrl  = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _codeCtrl     = TextEditingController();

  bool _codeSent = false;
  String _phoneCodeHash = '';
  int _step = 0; // 0=credentials, 1=code

  @override
  void dispose() {
    _apiIdCtrl.dispose();
    _apiHashCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is TelegramCodeSent) {
            setState(() {
              _phoneCodeHash = state.phoneCodeHash;
              _step = 1;
            });
          }
          if (state is AuthAuthenticated) {
            context.go('/home');
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Telegram Icon Header
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2AABEE).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.telegram,
                        color: Color(0xFF2AABEE),
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'Connect Telegram',
                      style: AppTextStyles.displayMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Your Telegram account will be used\nas unlimited cloud storage',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Step indicator
                  Row(
                    children: [
                      _StepChip(label: '1', title: 'Credentials', active: _step == 0, done: _step > 0),
                      Expanded(child: Divider(color: AppColors.surfaceLight)),
                      _StepChip(label: '2', title: 'Verify', active: _step == 1, done: false),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Step 0: Credentials
                  if (_step == 0) ...[
                    _infoCard(),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _apiIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'API ID',
                        prefixIcon: Icon(Icons.tag_rounded),
                        hintText: 'e.g. 12345678',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apiHashCtrl,
                      decoration: const InputDecoration(
                        labelText: 'API Hash',
                        prefixIcon: Icon(Icons.key_rounded),
                        hintText: 'e.g. abc123...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_rounded),
                        hintText: '+1234567890',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : () {
                          context.read<AuthBloc>().add(
                            TelegramConnectRequested(
                              int.parse(_apiIdCtrl.text.trim()),
                              _apiHashCtrl.text.trim(),
                              _phoneCtrl.text.trim(),
                            ),
                          );
                        },
                        child: state is AuthLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            )
                          : const Text('Send Code'),
                      ),
                    ),
                  ],

                  // Step 1: Verify code
                  if (_step == 1) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sms_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Code sent to ${_phoneCtrl.text}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayMedium.copyWith(
                        letterSpacing: 12,
                      ),
                      maxLength: 5,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        counterText: '',
                        hintText: '· · · · ·',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : () {
                          context.read<AuthBloc>().add(
                            TelegramVerifyRequested(
                              _phoneCtrl.text.trim(),
                              _codeCtrl.text.trim(),
                              _phoneCodeHash,
                            ),
                          );
                        },
                        child: state is AuthLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            )
                          : const Text('Verify & Connect'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _step = 0),
                        child: const Text('← Change number'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('How to get API credentials',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. Go to my.telegram.org\n'
            '2. Log in with your phone number\n'
            '3. Click "API Development Tools"\n'
            '4. Create an app to get API ID & Hash',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final String title;
  final bool active;
  final bool done;

  const _StepChip({
    required this.label,
    required this.title,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: active || done
              ? AppColors.primary
              : AppColors.bgCard,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textHint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: active ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
Step 10: Home Screen
dart

// lib/features/home/presentation/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/files/data/file_repository.dart';
import '../../../features/files/models/file_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../files/presentation/widgets/file_card.dart';
import 'widgets/category_grid.dart';
import 'widgets/storage_bar.dart';
import 'widgets/upload_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fileRepo = FileRepository();
  List<FileModel> _recentFiles = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final recent = await _fileRepo.getRecentFiles();
      final stats  = await _fileRepo.getStorageStats();
      if (mounted) {
        setState(() {
          _recentFiles = recent;
          _stats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state is AuthAuthenticated)
      ? (context.watch<AuthBloc>().state as AuthAuthenticated).user
      : null;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              title: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('FTMS'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      user?.username.substring(0, 1).toUpperCase() ?? 'U',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  onPressed: () => context.go('/settings'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Greeting ──────────────────────────
                    Text(
                      'Hey ${user?.username ?? 'there'} 👋',
                      style: AppTextStyles.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your unlimited cloud is ready',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // ── Storage Bar ───────────────────────
                    StorageBar(
                      usedBytes: _stats['total_size_bytes'] ?? 0,
                      totalFiles: _stats['total_files'] ?? 0,
                      byCategory: _stats['by_category'] ?? {},
                    ),
                    const SizedBox(height: 28),

                    // ── Categories ────────────────────────
                    Text('Browse', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    CategoryGrid(stats: _stats['by_category'] ?? {}),
                    const SizedBox(height: 28),

                    // ── Recent Files ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent', style: AppTextStyles.headlineMedium),
                        TextButton(
                          onPressed: () => context.go('/files'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Recent Files List ──────────────────────────
            if (_loading)
              const SliverToBoxAdapter(child: SizedBox(height: 200))
            else if (_recentFiles.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateWidget(
                  icon: Icons.cloud_upload_outlined,
                  title: 'No files yet',
                  subtitle: 'Upload your first file to get started',
                  actionLabel: 'Upload File',
                  onAction: () {},
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FileCard(
                        file: _recentFiles[i],
                        onTap: () => _openFile(_recentFiles[i]),
                      ),
                    ),
                    childCount: _recentFiles.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: UploadFAB(onUploaded: _loadData),
    );
  }

  void _openFile(FileModel file) {
    switch (file.fileType) {
      case 'video':
        context.push('/video-player', extra: file);
        break;
      case 'audio':
        context.push('/audio-player', extra: file);
        break;
      case 'document':
        context.push('/pdf-viewer', extra: file);
        break;
      case 'image':
        context.push('/photo-viewer', extra: {
          'files': [file],
          'index': 0,
        });
        break;
      default:
        break;
    }
  }
}
dart

// lib/features/home/presentation/widgets/category_grid.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';

class CategoryItem {
  final String category;
  final String label;
  final String route;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.category,
    required this.label,
    required this.route,
    required this.icon,
    required this.color,
  });
}

const _categories = [
  CategoryItem(
    category: 'image',
    label: 'Photos',
    route: '/photos',
    icon: Icons.image_rounded,
    color: AppColors.imageColor,
  ),
  CategoryItem(
    category: 'video',
    label: 'Videos',
    route: '/videos',
    icon: Icons.videocam_rounded,
    color: AppColors.videoColor,
  ),
  CategoryItem(
    category: 'audio',
    label: 'Music',
    route: '/audio',
    icon: Icons.music_note_rounded,
    color: AppColors.audioColor,
  ),
  CategoryItem(
    category: 'document',
    label: 'Docs',
    route: '/documents',
    icon: Icons.description_rounded,
    color: AppColors.documentColor,
  ),
  CategoryItem(
    category: 'code',
    label: 'Code',
    route: '/files',
    icon: Icons.code_rounded,
    color: AppColors.codeColor,
  ),
  CategoryItem(
    category: 'archive',
    label: 'Archives',
    route: '/files',
    icon: Icons.folder_zip_rounded,
    color: AppColors.archiveColor,
  ),
];

class CategoryGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const CategoryGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (ctx, i) {
        final cat = _categories[i];
        final catStats = stats[cat.category] as Map<String, dynamic>?;
        final count = catStats?['count'] ?? 0;

        return _CategoryCard(
          item: cat,
          count: count,
          onTap: () => context.go(cat.route),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem item;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.item,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.categoryGradient(item.color),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$count files',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
dart

// lib/features/home/presentation/widgets/storage_bar.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';

class StorageBar extends StatelessWidget {
  final int usedBytes;
  final int totalFiles;
  final Map<String, dynamic> byCategory;

  const StorageBar({
    super.key,
    required this.usedBytes,
    required this.totalFiles,
    required this.byCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A3E), Color(0xFF242460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Storage Used', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    FileUtils.formatSize(usedBytes),
                    style: AppTextStyles.headlineLarge,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Files', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$totalFiles',
                    style: AppTextStyles.headlineLarge,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category color bar
          if (byCategory.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: _CategoryBar(
                  byCategory: byCategory,
                  totalBytes: usedBytes,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: byCategory.entries
                .where((e) => (e.value['count'] ?? 0) > 0)
                .map((e) => _LegendItem(
                  color: FileUtils.getCategoryColor(e.key),
                  label: FileUtils.getCategoryLabel(e.key),
                  count: e.value['count'] ?? 0,
                ))
                .toList(),
            ),
          ] else ...[
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload files to see storage breakdown',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final Map<String, dynamic> byCategory;
  final int totalBytes;

  const _CategoryBar({
    required this.byCategory,
    required this.totalBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (totalBytes == 0) return const SizedBox.shrink();

    return Row(
      children: byCategory.entries
        .where((e) => (e.value['size_bytes'] ?? 0) > 0)
        .map((e) {
          final bytes = e.value['size_bytes'] as int;
          final fraction = bytes / totalBytes;
          return Expanded(
            flex: (fraction * 1000).toInt(),
            child: Container(
              color: FileUtils.getCategoryColor(e.key),
            ),
          );
        })
        .toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
dart

// lib/features/home/presentation/widgets/upload_fab.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class UploadFAB extends StatefulWidget {
  final VoidCallback? onUploaded;
  const UploadFAB({super.key, this.onUploaded});

  @override
  State<UploadFAB> createState() => _UploadFABState();
}

class _UploadFABState extends State<UploadFAB> {
  bool _uploading = false;
  double _progress = 0;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      });

      await DioClient.instance.dio.post(
        ApiConstants.filesUpload,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() => _progress = sent / total);
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} uploaded!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onUploaded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _uploading ? null : _pickAndUpload,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: _uploading
        ? SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              value: _progress > 0 ? _progress : null,
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : const Icon(Icons.upload_rounded),
      label: Text(
        _uploading ? '${(_progress * 100).toInt()}%' : 'Upload',
        style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
      ),
    );
  }
}
Step 11: File Repository + File Card
dart

// lib/features/files/data/file_repository.dart

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../models/file_model.dart';
import '../models/folder_model.dart';

class FileRepository {
  final _dio = DioClient.instance.dio;

  // ── Files ──────────────────────────────────────────────────

  Future<List<FileModel>> getFiles({
    String? folderId,
    String? fileType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.filesList,
        queryParameters: {
          if (folderId != null) 'folder_id': folderId,
          if (fileType != null) 'file_type': fileType,
          'page': page,
          'limit': limit,
        },
      );
      final files = res.data['files'] as List;
      return files.map((f) => FileModel.fromJson(f)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<FileModel>> getRecentFiles({int days = 7}) async {
    try {
      final res = await _dio.get(
        ApiConstants.searchRecent,
        queryParameters: {'days': days, 'limit': 10},
      );
      final files = res.data['files'] as List;
      return files.map((f) => FileModel.fromJson(f)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final res = await _dio.get(ApiConstants.searchStats);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> getDownloadUrl(String fileId) {
    return Future.value(
      '${_dio.options.baseUrl}${ApiConstants.filesDownload}/$fileId'
    );
  }

  Future<void> toggleFavorite(String fileId, bool isFavorite) async {
    try {
      await _dio.patch(
        '/api/files/$fileId',
        data: {'is_favorite': isFavorite},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _dio.delete('/api/files/$fileId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Folders ────────────────────────────────────────────────

  Future<List<FolderModel>> getFolderTree({String? parentId}) async {
    try {
      final res = await _dio.get(
        ApiConstants.folderTree,
        queryParameters: {
          if (parentId != null) 'parent_id': parentId,
        },
      );
      final folders = res.data['folders'] as List;
      return folders.map((f) => FolderModel.fromJson(f)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FolderModel> createFolder({
    required String name,
    String? parentId,
    String color = '#4ECDC4',
  }) async {
    try {
      final res = await _dio.post(ApiConstants.folders, data: {
        'name': name,
        if (parentId != null) 'parent_id': parentId,
        'color': color,
      });
      return FolderModel.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      await _dio.delete('${ApiConstants.folders}/$folderId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Search ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> search({
    required String query,
    String? category,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.search,
        queryParameters: {
          'q': query,
          if (category != null) 'category': category,
          'page': page,
          'limit': limit,
        },
      );
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
dart

// lib/features/files/presentation/widgets/file_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/network/dio_client.dart';
import '../../models/file_model.dart';

class FileCard extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.getCategoryColor(file.fileType);
    final icon  = FileUtils.getCategoryIcon(file.fileType);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: file.fileType == 'image'
                ? CachedNetworkImage(
                    imageUrl: '${ApiConstants.baseUrl}'
                              '${ApiConstants.thumbnail}/${file.id}',
                    httpHeaders: {
                      'Authorization': 'Bearer token', // handled by interceptor
                    },
                    width: 56, height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _IconFallback(color: color, icon: icon),
                    errorWidget: (_, __, ___) => _IconFallback(color: color, icon: icon),
                  )
                : _IconFallback(color: color, icon: icon),
            ),
            const SizedBox(width: 14),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        FileUtils.formatSize(file.sizeBytes),
                        style: AppTextStyles.caption,
                      ),
                      const Text(' • ', style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                      )),
                      Text(
                        FTMSDateUtils.timeAgo(file.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status / Favorite
            if (file.uploadStatus != 'complete')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  file.uploadStatus,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              )
            else if (file.isFavorite)
              const Icon(
                Icons.star_rounded,
                color: AppColors.warning,
                size: 20,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _IconFallback({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
Step 12: Photos Screen
dart

// lib/features/photos/presentation/photos_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/files/data/file_repository.dart';
import '../../../features/files/models/file_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import 'widgets/photo_grid.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final _repo = FileRepository();
  List<FileModel> _photos = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _page = 1; });
    try {
      final files = await _repo.getFiles(fileType: 'image', page: 1, limit: 60);
      if (mounted) setState(() {
        _photos = files;
        _loading = false;
        _hasMore = files.length == 60;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final files = await _repo.getFiles(
        fileType: 'image', page: ++_page, limit: 60,
      );
      if (mounted) setState(() {
        _photos.addAll(files);
        _loadingMore = false;
        _hasMore = files.length == 60;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
        ? const LoadingGrid()
        : _photos.isEmpty
          ? EmptyStateWidget(
              icon: Icons.photo_library_outlined,
              title: 'No photos yet',
              subtitle: 'Your uploaded images will appear here',
              onAction: () {},
              actionLabel: 'Upload Photo',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: PhotoGrid(
                photos: _photos,
                controller: _scroll,
                onPhotoTap: (index) => context.push(
                  '/photo-viewer',
                  extra: {'files': _photos, 'index': index},
                ),
              ),
            ),
    );
  }
}
dart

// lib/features/photos/presentation/widgets/photo_grid.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/files/models/file_model.dart';

class PhotoGrid extends StatelessWidget {
  final List<FileModel> photos;
  final ScrollController? controller;
  final void Function(int index) onPhotoTap;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.controller,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      controller: controller,
      crossAxisCount: 3,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      padding: EdgeInsets.zero,
      itemCount: photos.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => onPhotoTap(i),
        child: Hero(
          tag: 'photo_${photos[i].id}',
          child: CachedNetworkImage(
            imageUrl: '${ApiConstants.baseUrl}'
                      '${ApiConstants.thumbnail}/${photos[i].id}',
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 120,
              color: AppColors.bgCard,
            ),
            errorWidget: (_, __, ___) => Container(
              height: 120,
              color: AppColors.bgCard,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
dart

// lib/features/photos/presentation/photo_viewer.dart

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/file_utils.dart';
import '../../../features/files/models/file_model.dart';

class PhotoViewer extends StatefulWidget {
  final List<FileModel> files;
  final int initialIndex;

  const PhotoViewer({
    super.key,
    required this.files,
    required this.initialIndex,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late PageController _pageCtrl;
  late int _current;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.files[_current];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Text(
          '${_current + 1} / ${widget.files.length}',
          style: AppTextStyles.titleMedium,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outlined,
              color: _showInfo ? AppColors.primary : Colors.white,
            ),
            onPressed: () => setState(() => _showInfo = !_showInfo),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Photo Gallery
          PhotoViewGallery.builder(
            pageController: _pageCtrl,
            itemCount: widget.files.length,
            onPageChanged: (i) => setState(() => _current = i),
            builder: (ctx, i) {
              final f = widget.files[i];
              final downloadUrl =
                '${ApiConstants.baseUrl}${ApiConstants.filesDownload}/${f.id}';
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(downloadUrl),
                heroAttributes: PhotoViewHeroAttributes(tag: 'photo_${f.id}'),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
              );
            },
            loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),

          // Info Panel
          if (_showInfo)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name, style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          FileUtils.formatSize(file.sizeBytes),
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Text(' • ', style: TextStyle(
                          color: AppColors.textHint,
                        )),
                        Text(
                          FTMSDateUtils.formatDateTime(file.createdAt),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    // EXIF data
                    if (file.fileMetadata.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      if (file.fileMetadata['camera'] != null)
                        Text(
                          '📷 ${file.fileMetadata['camera']}',
                          style: AppTextStyles.caption,
                        ),
                      if (file.fileMetadata['width'] != null)
                        Text(
                          '📐 ${file.fileMetadata['width']} × ${file.fileMetadata['height']}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
Step 13: Video + Audio + Documents
dart

// lib/features/videos/presentation/video_player_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/files/models/file_model.dart';
import '../../../core/utils/file_utils.dart';

class VideoPlayerScreen extends StatefulWidget {
  final FileModel file;
  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initPlayer() async {
    final url =
      '${ApiConstants.baseUrl}${ApiConstants.filesDownload}/${widget.file.id}';

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller!.initialize();

    _chewie = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primary,
        backgroundColor: AppColors.bgElevated,
        bufferedColor: AppColors.primary.withOpacity(0.3),
      ),
    );

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewie?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.file.name),
      ),
      body: Column(
        children: [
          // Video player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _initialized && _chewie != null
              ? Chewie(controller: _chewie!)
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
          ),

          // File Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.file.name, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    FileUtils.formatSize(widget.file.sizeBytes),
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (widget.file.fileMetadata['duration_seconds'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${FileUtils.formatDuration(
                        widget.file.fileMetadata['duration_seconds'] as double
                      )}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                  if (widget.file.fileMetadata['width'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Resolution: ${widget.file.fileMetadata['width']} × ${widget.file.fileMetadata['height']}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
dart

// lib/features/audio/presentation/audio_player_screen.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/files/models/file_model.dart';
import '../../../core/utils/file_utils.dart';

class AudioPlayerScreen extends StatefulWidget {
  final FileModel file;
  const AudioPlayerScreen({super.key, required this.file});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _player = AudioPlayer();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url =
      '${ApiConstants.baseUrl}${ApiConstants.filesDownload}/${widget.file.id}';
    await _player.setUrl(url);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.file.fileMetadata;
    final title  = meta['title'] ?? widget.file.name;
    final artist = meta['artist'] ?? 'Unknown Artist';
    final album  = meta['album'] ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Now Playing',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Album Art
              Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  color: AppColors.audioColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.audioColor.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  size: 100,
                  color: AppColors.audioColor,
                ),
              ),
              const SizedBox(height: 40),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headlineLarge,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (album.isNotEmpty)
                      Text(album, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (ctx, durSnap) {
                    final duration = durSnap.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (ctx, posSnap) {
                        final position = posSnap.data ?? Duration.zero;
                        return Column(
                          children: [
                            Slider(
                              value: position.inMilliseconds.toDouble().clamp(
                                0, duration.inMilliseconds.toDouble()
                              ),
                              max: duration.inMilliseconds.toDouble(),
                              activeColor: AppColors.audioColor,
                              inactiveColor: AppColors.bgElevated,
                              onChanged: (v) => _player.seek(
                                Duration(milliseconds: v.toInt())
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmt(position),
                                    style: AppTextStyles.caption,
                                  ),
                                  Text(
                                    _fmt(duration),
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle_rounded),
                    iconSize: 28,
                    onPressed: () {},
                    color: AppColors.textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (ctx, snap) {
                      final playing = snap.data?.playing ?? false;
                      return Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.audioColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.audioColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressed: () {
                            playing ? _player.pause() : _player.play();
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat_rounded),
                    iconSize: 28,
                    onPressed: () {},
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
dart

// lib/features/documents/presentation/pdf_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/files/models/file_model.dart';
import '../../../core/network/dio_client.dart';

class PdfViewerScreen extends StatefulWidget {
  final FileModel file;
  const PdfViewerScreen({super.key, required this.file});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _loading = true;
  int _pages = 0;
  int _currentPage = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final url =
        '${ApiConstants.baseUrl}${ApiConstants.filesDownload}/${widget.file.id}';

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${widget.file.id}.pdf';
      final file = File(path);

      if (!await file.exists()) {
        await DioClient.instance.dio.download(
          url,
          path,
          onReceiveProgress: (received, total) {},
        );
      }

      if (mounted) setState(() {
        _localPath = path;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          if (_pages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '$_currentPage / $_pages',
                style: AppTextStyles.bodyMedium,
              ),
            ),
        ],
      ),
      body: _loading
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Loading PDF...'),
              ],
            ),
          )
        : _error != null
          ? Center(child: Text('Error: $_error'))
          : PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: true,
              onPageCount: (count) => setState(() => _pages = count ?? 0),
              onPageChanged: (page, _) =>
                setState(() => _currentPage = (page ?? 0) + 1),
              onError: (e) => setState(() => _error = e.toString()),
            ),
    );
  }
}
Step 14: Search Screen
dart

// lib/features/search/presentation/search_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../features/files/data/file_repository.dart';
import '../../../features/files/models/file_model.dart';
import '../../../features/files/presentation/widgets/file_card.dart';
import '../../../shared/widgets/loading_widget.dart';

const _categories = [
  'all', 'image', 'video', 'audio', 'document', 'code', 'archive'
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repo = FileRepository();
  final _ctrl = TextEditingController();
  List<FileModel> _results = [];
  bool _loading = false;
  String _selectedCategory = 'all';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _repo.search(
        query: q,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      final files = (res['files'] as List)
        .map((f) => FileModel.fromJson(f))
        .toList();
      if (mounted) setState(() {
        _results = files;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openFile(FileModel file) {
    switch (file.fileType) {
      case 'video': context.push('/video-player', extra: file); break;
      case 'audio': context.push('/audio-player', extra: file); break;
      case 'document': context.push('/pdf-viewer', extra: file); break;
      case 'image': context.push('/photo-viewer', extra: {
        'files': [file], 'index': 0,
      }); break;
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              onChanged: (v) => _search(v),
              decoration: InputDecoration(
                hintText: 'Search files, folders...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _results = []);
                      },
                    )
                  : null,
              ),
            ),
          ),

          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                final color = cat == 'all'
                  ? AppColors.primary
                  : FileUtils.getCategoryColor(cat);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    if (_ctrl.text.isNotEmpty) _search(_ctrl.text);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.2) : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? color : AppColors.surfaceLight,
                      ),
                    ),
                    child: Text(
                      cat == 'all'
                        ? 'All'
                        : FileUtils.getCategoryLabel(cat),
                      style: AppTextStyles.label.copyWith(
                        color: selected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Results
          Expanded(
            child: _loading
              ? const LoadingList()
              : _results.isEmpty && _ctrl.text.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results for "${_ctrl.text}"',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search your files',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => FileCard(
                        file: _results[i],
                        onTap: () => _openFile(_results[i]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
Step 15: Settings Screen
dart

// lib/features/settings/presentation/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../features/auth/bloc/auth_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthAuthenticated ? state.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          if (user != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.categoryGradient(AppColors.primary),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user.email,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.totalFiles} files • ${FileUtils.formatSize(user.storageUsedBytes)}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Telegram Status
          _SectionTitle('Telegram Storage'),
          _SettingTile(
            icon: Icons.telegram,
            iconColor: const Color(0xFF2AABEE),
            title: 'Telegram Account',
            subtitle: user?.isTelegramConnected == true
              ? 'Connected ✓'
              : 'Not connected',
            trailing: user?.isTelegramConnected == true
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: () => context.go('/telegram-connect'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Connect'),
                ),
            onTap: null,
          ),
          const SizedBox(height: 8),

          // App Settings
          _SectionTitle('App'),
          _SettingTile(
            icon: Icons.dark_mode_rounded,
            iconColor: AppColors.primary,
            title: 'Dark Mode',
            subtitle: 'Always on',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.notifications_rounded,
            iconColor: AppColors.warning,
            title: 'Notifications',
            subtitle: 'Upload & download alerts',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.storage_rounded,
            iconColor: AppColors.info,
            title: 'Cache',
            subtitle: 'Clear thumbnail cache',
            onTap: () {},
          ),
          const SizedBox(height: 8),

          // About
          _SectionTitle('About'),
          _SettingTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          _SettingTile(
            icon: Icons.code_rounded,
            iconColor: AppColors.codeColor,
            title: 'Open Source',
            subtitle: 'GitHub repository',
            onTap: () {},
          ),
          const SizedBox(height: 8),

          // Logout
          _SectionTitle('Account'),
          _SettingTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Sign Out',
            subtitle: 'Log out of FTMS',
            titleColor: AppColors.error,
            onTap: () => _confirmLogout(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
              context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: titleColor,
          ),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.bodyMedium),
        trailing: trailing ?? (onTap != null
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            )
          : null),
      ),
    );
  }
}
Step 16: Main Entry Point
dart

// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(AuthRepository())
            ..add(CheckAuthStatus()),
        ),
      ],
      child: const FTMSApp(),
    ),
  );
}
dart

// lib/app.dart

import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class FTMSApp extends StatelessWidget {
  const FTMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FTMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
Step 17: Android Permissions
XML

<!-- android/app/src/main/AndroidManifest.xml -->
<!-- Add inside <manifest> tag -->

<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
Step 18: Run
Bash

# Install dependencies
flutter pub get

# Run on Android
flutter run

# Run on Windows
flutter run -d windows

# Build Android APK
flutter build apk --release

# Build Windows EXE
flutter build windows --release