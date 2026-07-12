
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
import '../../features/backup/backup_screen.dart';
import '../../features/encryption/encryption_screen.dart';
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
          routes: [
            GoRoute(
              path: 'backup',
              builder: (ctx, state) => const BackupScreen(),
            ),
            GoRoute(
              path: 'encryption',
              builder: (ctx, state) => const EncryptionScreen(),
            ),
          ],
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
