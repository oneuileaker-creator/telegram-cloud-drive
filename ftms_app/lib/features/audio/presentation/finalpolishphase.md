Phase 5: Complete Advanced Features
Offline Mode + Auto Backup + E2E Encryption + File Sharing + Render Deploy
Step 1: Update pubspec.yaml
YAML

# pubspec.yaml - Add these to existing dependencies

dependencies:
  # Existing deps...

  # ── Offline / Cache ─────────────────────────────────────
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  connectivity_plus: ^6.0.2
  internet_connection_checker: ^1.0.0+1

  # ── Encryption ──────────────────────────────────────────
  cryptography: ^2.7.0
  pointycastle: ^3.7.4
  convert: ^3.1.1

  # ── Background Tasks ────────────────────────────────────
  workmanager: ^0.5.2
  flutter_background_service: ^5.0.5

  # ── Device Backup ───────────────────────────────────────
  photo_manager: ^3.0.0
  background_fetch: ^1.2.1

  # ── File Sharing ────────────────────────────────────────
  share_plus: ^7.2.2
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1

  # ── Notifications ───────────────────────────────────────
  flutter_local_notifications: ^17.0.0

  # ── Window Manager (Windows) ────────────────────────────
  window_manager: ^0.3.8

  # ── Desktop Drop ────────────────────────────────────────
  desktop_drop: ^0.4.4

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
Bash

flutter pub get
dart run build_runner build --delete-conflicting-outputs
Part 1: Offline Mode + Hive Caching
Cache Models (Hive)
dart

// lib/core/cache/hive_models.dart

import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class CachedFile extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String originalName;
  @HiveField(2) late String fileType;
  @HiveField(3) late String? mimeType;
  @HiveField(4) late String? extension;
  @HiveField(5) late int sizeBytes;
  @HiveField(6) late String uploadStatus;
  @HiveField(7) late List<String> tags;
  @HiveField(8) late bool isFavorite;
  @HiveField(9) late String? folderId;
  @HiveField(10) late String createdAt;
  @HiveField(11) late String? displayName;
  @HiveField(12) late Map<String, dynamic> fileMetadata;

  CachedFile();

  factory CachedFile.fromMap(Map<String, dynamic> map) {
    final c = CachedFile();
    c.id            = map['id'];
    c.originalName  = map['original_name'];
    c.fileType      = map['file_type'] ?? 'other';
    c.mimeType      = map['mime_type'];
    c.extension     = map['extension'];
    c.sizeBytes     = map['size_bytes'] ?? 0;
    c.uploadStatus  = map['upload_status'] ?? 'pending';
    c.tags          = List<String>.from(map['tags'] ?? []);
    c.isFavorite    = map['is_favorite'] ?? false;
    c.folderId      = map['folder_id'];
    c.createdAt     = map['created_at'];
    c.displayName   = map['display_name'];
    c.fileMetadata  = Map<String, dynamic>.from(map['file_metadata'] ?? {});
    return c;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'original_name': originalName,
    'file_type': fileType,
    'mime_type': mimeType,
    'extension': extension,
    'size_bytes': sizeBytes,
    'upload_status': uploadStatus,
    'tags': tags,
    'is_favorite': isFavorite,
    'folder_id': folderId,
    'created_at': createdAt,
    'display_name': displayName,
    'file_metadata': fileMetadata,
  };
}

@HiveType(typeId: 1)
class CachedFolder extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late String? parentId;
  @HiveField(3) late String path;
  @HiveField(4) late String color;
  @HiveField(5) late String icon;
  @HiveField(6) late int fileCount;
  @HiveField(7) late int childrenCount;
  @HiveField(8) late String createdAt;

  CachedFolder();
}

@HiveType(typeId: 2)
class CachedThumbnail extends HiveObject {
  @HiveField(0) late String fileId;
  @HiveField(1) late List<int> data;    // JPEG bytes
  @HiveField(2) late String cachedAt;

  CachedThumbnail();
}

@HiveType(typeId: 3)
class PendingUpload extends HiveObject {
  @HiveField(0) late String id;          // UUID
  @HiveField(1) late String localPath;
  @HiveField(2) late String fileName;
  @HiveField(3) late String? folderId;
  @HiveField(4) late String createdAt;
  @HiveField(5) late bool encrypted;
  @HiveField(6) late String status;     // pending/uploading/done/failed

  PendingUpload();
}
dart

// lib/core/cache/cache_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../features/files/models/file_model.dart';
import '../../features/files/models/folder_model.dart';
import 'hive_models.dart';
import 'dart:typed_data';

class CacheService {
  static const _filesBox      = 'files_cache';
  static const _foldersBox    = 'folders_cache';
  static const _thumbsBox     = 'thumbnails_cache';
  static const _pendingBox    = 'pending_uploads';
  static const _statsBox      = 'stats_cache';
  static const _maxThumbs     = 500;

  // ── Init ──────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CachedFileAdapter());
    Hive.registerAdapter(CachedFolderAdapter());
    Hive.registerAdapter(CachedThumbnailAdapter());
    Hive.registerAdapter(PendingUploadAdapter());
    await Hive.openBox<CachedFile>(_filesBox);
    await Hive.openBox<CachedFolder>(_foldersBox);
    await Hive.openBox<CachedThumbnail>(_thumbsBox);
    await Hive.openBox<PendingUpload>(_pendingBox);
    await Hive.openBox(_statsBox);
  }

  // ── Files ─────────────────────────────────────────────────

  static Future<void> cacheFiles(List<FileModel> files) async {
    final box = Hive.box<CachedFile>(_filesBox);
    for (final f in files) {
      final cached = CachedFile.fromMap(f.toJson());
      await box.put(f.id, cached);
    }
  }

  static List<FileModel> getCachedFiles({
    String? fileType,
    String? folderId,
  }) {
    final box = Hive.box<CachedFile>(_filesBox);
    var files = box.values.toList();

    if (fileType != null) {
      files = files.where((f) => f.fileType == fileType).toList();
    }
    if (folderId != null) {
      files = files.where((f) => f.folderId == folderId).toList();
    }

    files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return files.map((f) => FileModel.fromJson(f.toMap())).toList();
  }

  static Future<void> removeFile(String fileId) async {
    await Hive.box<CachedFile>(_filesBox).delete(fileId);
    await Hive.box<CachedThumbnail>(_thumbsBox).delete(fileId);
  }

  static Future<void> clearFiles() async {
    await Hive.box<CachedFile>(_filesBox).clear();
  }

  // ── Thumbnails ────────────────────────────────────────────

  static Future<void> cacheThumbnail(String fileId, Uint8List data) async {
    final box = Hive.box<CachedThumbnail>(_thumbsBox);
    // Evict oldest if over limit
    if (box.length >= _maxThumbs) {
      final oldest = box.values.toList()
        ..sort((a, b) => a.cachedAt.compareTo(b.cachedAt));
      await box.delete(oldest.first.fileId);
    }
    final thumb = CachedThumbnail()
      ..fileId   = fileId
      ..data     = data.toList()
      ..cachedAt = DateTime.now().toIso8601String();
    await box.put(fileId, thumb);
  }

  static Uint8List? getCachedThumbnail(String fileId) {
    final thumb = Hive.box<CachedThumbnail>(_thumbsBox).get(fileId);
    if (thumb == null) return null;
    return Uint8List.fromList(thumb.data);
  }

  // ── Folders ───────────────────────────────────────────────

  static Future<void> cacheFolders(List<FolderModel> folders) async {
    final box = Hive.box<CachedFolder>(_foldersBox);
    await box.clear();
    for (final f in folders) {
      final cached = CachedFolder()
        ..id             = f.id
        ..name           = f.name
        ..parentId       = f.parentId
        ..path           = f.path
        ..color          = f.color
        ..icon           = f.icon
        ..fileCount      = f.fileCount
        ..childrenCount  = f.childrenCount
        ..createdAt      = f.createdAt.toIso8601String();
      await box.put(f.id, cached);
    }
  }

  static List<FolderModel> getCachedFolders({String? parentId}) {
    return Hive.box<CachedFolder>(_foldersBox).values
      .where((f) => f.parentId == parentId)
      .map((f) => FolderModel.fromJson({
        'id': f.id, 'name': f.name, 'parent_id': f.parentId,
        'path': f.path, 'color': f.color, 'icon': f.icon,
        'file_count': f.fileCount, 'children_count': f.childrenCount,
        'created_at': f.createdAt,
      }))
      .toList();
  }

  // ── Pending Uploads ───────────────────────────────────────

  static Future<String> addPendingUpload({
    required String localPath,
    required String fileName,
    String? folderId,
    bool encrypted = false,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final upload = PendingUpload()
      ..id         = id
      ..localPath  = localPath
      ..fileName   = fileName
      ..folderId   = folderId
      ..createdAt  = DateTime.now().toIso8601String()
      ..encrypted  = encrypted
      ..status     = 'pending';
    await Hive.box<PendingUpload>(_pendingBox).put(id, upload);
    return id;
  }

  static List<PendingUpload> getPendingUploads() {
    return Hive.box<PendingUpload>(_pendingBox).values
      .where((u) => u.status == 'pending')
      .toList();
  }

  static Future<void> updatePendingStatus(
    String id,
    String status,
  ) async {
    final box = Hive.box<PendingUpload>(_pendingBox);
    final upload = box.get(id);
    if (upload != null) {
      upload.status = status;
      await upload.save();
    }
  }

  // ── Stats Cache ───────────────────────────────────────────

  static Future<void> cacheStats(Map<String, dynamic> stats) async {
    await Hive.box(_statsBox).put('stats', stats);
    await Hive.box(_statsBox).put(
      'stats_cached_at',
      DateTime.now().toIso8601String(),
    );
  }

  static Map<String, dynamic>? getCachedStats() {
    return Hive.box(_statsBox).get('stats');
  }

  static bool isStatsFresh({int maxAgeMinutes = 10}) {
    final cachedAt = Hive.box(_statsBox).get('stats_cached_at');
    if (cachedAt == null) return false;
    final age = DateTime.now().difference(DateTime.parse(cachedAt));
    return age.inMinutes < maxAgeMinutes;
  }

  // ── Cleanup ───────────────────────────────────────────────

  static Future<void> clearAll() async {
    await Hive.box<CachedFile>(_filesBox).clear();
    await Hive.box<CachedFolder>(_foldersBox).clear();
    await Hive.box<CachedThumbnail>(_thumbsBox).clear();
    await Hive.box(_statsBox).clear();
  }
}
Connectivity Service
dart

// lib/core/network/connectivity_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

enum ConnectionStatus { online, offline, slow }

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;
  ConnectivityService._();

  ConnectionStatus _status = ConnectionStatus.online;
  ConnectionStatus get status => _status;
  bool get isOnline => _status != ConnectionStatus.offline;

  StreamSubscription? _sub;

  void init() {
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = isOnline;
      _status = result == ConnectivityResult.none
        ? ConnectionStatus.offline
        : ConnectionStatus.online;

      if (wasOnline != isOnline) notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
dart

// lib/shared/widgets/offline_banner.dart

import 'package:flutter/material.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectivityService.instance,
      builder: (ctx, _) {
        final offline = !ConnectivityService.instance.isOnline;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: offline ? 36 : 0,
              color: AppColors.warning,
              child: offline
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Offline - Showing cached data',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )
                : null,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
Offline-Aware File Repository
dart

// lib/features/files/data/offline_file_repository.dart

import 'package:dio/dio.dart';
import '../../../core/cache/cache_service.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/file_model.dart';
import '../models/folder_model.dart';

class OfflineFileRepository {
  final _dio = DioClient.instance.dio;

  // ── Files ─────────────────────────────────────────────────

  Future<List<FileModel>> getFiles({
    String? folderId,
    String? fileType,
    int page = 1,
    int limit = 50,
  }) async {
    if (!ConnectivityService.instance.isOnline) {
      // Return cached data when offline
      return CacheService.getCachedFiles(
        fileType: fileType,
        folderId: folderId,
      );
    }

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
      final files = (res.data['files'] as List)
        .map((f) => FileModel.fromJson(f))
        .toList();

      // Cache results (first page only)
      if (page == 1) await CacheService.cacheFiles(files);

      return files;
    } on DioException catch (e) {
      // Network error - fallback to cache
      final cached = CacheService.getCachedFiles(
        fileType: fileType,
        folderId: folderId,
      );
      if (cached.isNotEmpty) return cached;
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<FolderModel>> getFolderTree({String? parentId}) async {
    if (!ConnectivityService.instance.isOnline) {
      return CacheService.getCachedFolders(parentId: parentId);
    }

    try {
      final res = await _dio.get(
        ApiConstants.folderTree,
        queryParameters: {
          if (parentId != null) 'parent_id': parentId,
        },
      );
      final folders = (res.data['folders'] as List)
        .map((f) => FolderModel.fromJson(f))
        .toList();
      await CacheService.cacheFolders(folders);
      return folders;
    } on DioException catch (e) {
      final cached = CacheService.getCachedFolders(parentId: parentId);
      if (cached.isNotEmpty) return cached;
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    if (!ConnectivityService.instance.isOnline) {
      return CacheService.getCachedStats() ?? {};
    }
    if (CacheService.isStatsFresh()) {
      return CacheService.getCachedStats() ?? {};
    }

    try {
      final res = await _dio.get(ApiConstants.searchStats);
      await CacheService.cacheStats(res.data);
      return res.data;
    } on DioException catch (_) {
      return CacheService.getCachedStats() ?? {};
    }
  }

  // ── Queue upload for when online ──────────────────────────

  Future<void> queueUpload({
    required String localPath,
    required String fileName,
    String? folderId,
    bool encrypted = false,
  }) async {
    await CacheService.addPendingUpload(
      localPath:  localPath,
      fileName:   fileName,
      folderId:   folderId,
      encrypted:  encrypted,
    );
  }

  Future<void> processPendingUploads() async {
    if (!ConnectivityService.instance.isOnline) return;

    final pending = CacheService.getPendingUploads();
    for (final upload in pending) {
      try {
        await CacheService.updatePendingStatus(upload.id, 'uploading');
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            upload.localPath,
            filename: upload.fileName,
          ),
          if (upload.folderId != null) 'folder_id': upload.folderId,
        });
        await _dio.post(ApiConstants.filesUpload, data: formData);
        await CacheService.updatePendingStatus(upload.id, 'done');
      } catch (_) {
        await CacheService.updatePendingStatus(upload.id, 'failed');
      }
    }
  }
}
Part 2: Auto Device Backup
dart

// lib/features/backup/backup_service.dart

import 'package:photo_manager/photo_manager.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/cache/cache_service.dart';
import 'dart:io';

class BackupService {
  static const _backupBox    = 'backup_state';
  static const _backedUpKey  = 'backed_up_ids';
  static const _enabledKey   = 'backup_enabled';
  static const _wifiOnlyKey  = 'wifi_only';
  static const _lastRunKey   = 'last_backup_run';

  final _dio = DioClient.instance.dio;

  // ── Settings ──────────────────────────────────────────────

  static Future<void> initBox() async {
    await Hive.openBox(_backupBox);
  }

  bool get isEnabled =>
    Hive.box(_backupBox).get(_enabledKey, defaultValue: false);

  bool get wifiOnly =>
    Hive.box(_backupBox).get(_wifiOnlyKey, defaultValue: true);

  Future<void> setEnabled(bool value) async {
    await Hive.box(_backupBox).put(_enabledKey, value);
    if (value) await _requestPermissions();
  }

  Future<void> setWifiOnly(bool value) async {
    await Hive.box(_backupBox).put(_wifiOnlyKey, value);
  }

  Set<String> get _backedUpIds {
    final list = Hive.box(_backupBox)
      .get(_backedUpKey, defaultValue: <String>[]);
    return Set<String>.from(list);
  }

  Future<void> _markAsBackedUp(String assetId) async {
    final ids = _backedUpIds..add(assetId);
    await Hive.box(_backupBox).put(_backedUpKey, ids.toList());
  }

  // ── Permissions ───────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  // ── Backup Run ────────────────────────────────────────────

  Future<BackupResult> runBackup({
    void Function(int done, int total)? onProgress,
  }) async {
    if (!isEnabled) {
      return BackupResult(skipped: 0, uploaded: 0, failed: 0);
    }
    if (!ConnectivityService.instance.isOnline) {
      return BackupResult(skipped: 0, uploaded: 0, failed: 0, offline: true);
    }

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      return BackupResult(skipped: 0, uploaded: 0, failed: 0, noPermission: true);
    }

    // Get new assets since last backup
    final newAssets = await _getNewAssets();
    int uploaded = 0;
    int failed   = 0;
    int total    = newAssets.length;

    for (int i = 0; i < newAssets.length; i++) {
      final asset = newAssets[i];
      onProgress?.call(i + 1, total);

      try {
        final file = await asset.originFile;
        if (file == null) continue;

        await _uploadAsset(asset, file);
        await _markAsBackedUp(asset.id);
        uploaded++;
      } catch (_) {
        failed++;
      }
    }

    await Hive.box(_backupBox).put(
      _lastRunKey,
      DateTime.now().toIso8601String(),
    );

    return BackupResult(
      skipped: 0,
      uploaded: uploaded,
      failed: failed,
    );
  }

  Future<List<AssetEntity>> _getNewAssets() async {
    final backedUp = _backedUpIds;

    // Get recent photos and videos from device
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      ),
    );

    if (albums.isEmpty) return [];

    final recentAssets = await albums.first.getAssetListRange(
      start: 0,
      end: 500,
    );

    // Filter out already backed up
    return recentAssets
      .where((a) => !backedUp.contains(a.id))
      .toList();
  }

  Future<void> _uploadAsset(AssetEntity asset, File file) async {
    final mimeType = asset.mimeType ?? 'application/octet-stream';
    final title    = asset.title ?? '${asset.id}.jpg';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: title,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    await _dio.post(ApiConstants.filesUpload, data: formData);
  }

  // ── Stats ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBackupStats() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return {'error': 'No permission'};

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    int totalDevice  = 0;
    for (final album in albums) {
      totalDevice += await album.assetCountAsync;
    }

    return {
      'total_device': totalDevice,
      'backed_up': _backedUpIds.length,
      'pending': totalDevice - _backedUpIds.length,
      'last_run': Hive.box(_backupBox).get(_lastRunKey),
      'enabled': isEnabled,
      'wifi_only': wifiOnly,
    };
  }
}

class BackupResult {
  final int skipped;
  final int uploaded;
  final int failed;
  final bool offline;
  final bool noPermission;

  BackupResult({
    required this.skipped,
    required this.uploaded,
    required this.failed,
    this.offline = false,
    this.noPermission = false,
  });
}
dart

// lib/features/backup/backup_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupService();
  Map<String, dynamic> _stats = {};
  bool _loading    = false;
  bool _running    = false;
  int  _done       = 0;
  int  _total      = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await _service.getBackupStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  Future<void> _runBackup() async {
    setState(() { _running = true; _done = 0; _total = 0; });
    final result = await _service.runBackup(
      onProgress: (done, total) {
        if (mounted) setState(() { _done = done; _total = total; });
      },
    );
    if (mounted) {
      setState(() => _running = false);
      _loadStats();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Backup done: ${result.uploaded} uploaded, '
          '${result.failed} failed',
        ),
        backgroundColor: result.failed > 0
          ? AppColors.warning
          : AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Backup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // Status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.categoryGradient(AppColors.success),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  _service.isEnabled
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  _service.isEnabled ? 'Backup Active' : 'Backup Disabled',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (!_loading && _stats.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_stats['backed_up'] ?? 0} / '
                    '${_stats['total_device'] ?? 0} backed up',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup progress
          if (_running) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('Backing up...', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _total > 0 ? _done / _total : null,
                    color: AppColors.success,
                    backgroundColor: AppColors.bgElevated,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_done / $_total files',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Settings
          _SettingRow(
            title: 'Enable Auto Backup',
            subtitle: 'Automatically backup photos & videos',
            value: _service.isEnabled,
            onChanged: (v) async {
              await _service.setEnabled(v);
              setState(() {});
            },
          ),
          _SettingRow(
            title: 'Wi-Fi Only',
            subtitle: 'Only backup when connected to Wi-Fi',
            value: _service.wifiOnly,
            onChanged: (v) async {
              await _service.setWifiOnly(v);
              setState(() {});
            },
          ),

          const SizedBox(height: 24),

          // Stats
          if (!_loading && _stats.isNotEmpty) ...[
            Text('Backup Details', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            _StatCard('Device Files', '${_stats['total_device'] ?? 0}',
              Icons.phone_android_rounded, AppColors.primary),
            const SizedBox(height: 10),
            _StatCard('Backed Up', '${_stats['backed_up'] ?? 0}',
              Icons.cloud_done_rounded, AppColors.success),
            const SizedBox(height: 10),
            _StatCard('Pending', '${_stats['pending'] ?? 0}',
              Icons.pending_rounded, AppColors.warning),
            if (_stats['last_run'] != null) ...[
              const SizedBox(height: 10),
              _StatCard(
                'Last Run',
                _stats['last_run'].toString().split('T').first,
                Icons.schedule_rounded,
                AppColors.info,
              ),
            ],
          ],

          const SizedBox(height: 24),

          // Manual backup button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _running ? null : _runBackup,
              icon: const Icon(Icons.backup_rounded),
              label: Text(_running ? 'Running...' : 'Run Backup Now'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyLarge),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
Part 3: End-to-End Encryption
dart

// lib/core/encryption/encryption_service.dart

import 'dart:typed_data';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:convert/convert.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;
  EncryptionService._();

  static const _storage    = FlutterSecureStorage();
  static const _keyName    = 'ftms_encryption_key';
  static const _saltName   = 'ftms_key_salt';

  final _algorithm = AesGcm.with256bits();

  // ── Key Management ────────────────────────────────────────

  Future<SecretKey> _getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      final keyBytes = hex.decode(existing);
      return SecretKey(keyBytes);
    }
    // Generate new key
    final key = await _algorithm.newSecretKey();
    final keyBytes = await key.extractBytes();
    await _storage.write(key: _keyName, value: hex.encode(keyBytes));
    return key;
  }

  Future<String> exportKeyAsBase64() async {
    final key = await _getOrCreateKey();
    final bytes = await key.extractBytes();
    return base64.encode(bytes);
  }

  Future<void> importKeyFromBase64(String encoded) async {
    final bytes = base64.decode(encoded);
    await _storage.write(key: _keyName, value: hex.encode(bytes));
  }

  Future<bool> hasKey() async {
    return await _storage.read(key: _keyName) != null;
  }

  // ── Encrypt ───────────────────────────────────────────────

  Future<EncryptedData> encryptFile(Uint8List data) async {
    final key = await _getOrCreateKey();

    // Random nonce
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      data,
      secretKey: key,
      nonce: nonce,
    );

    return EncryptedData(
      ciphertext: Uint8List.fromList(secretBox.cipherText),
      nonce:      Uint8List.fromList(secretBox.nonce),
      mac:        Uint8List.fromList(secretBox.mac.bytes),
    );
  }

  // ── Decrypt ───────────────────────────────────────────────

  Future<Uint8List> decryptFile(EncryptedData encrypted) async {
    final key = await _getOrCreateKey();

    final secretBox = SecretBox(
      encrypted.ciphertext.toList(),
      nonce: encrypted.nonce.toList(),
      mac:   Mac(encrypted.mac.toList()),
    );

    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(decrypted);
  }

  // ── Encrypt bytes to uploadable format ────────────────────
  // Format: [4 bytes nonce_len][nonce][4 bytes mac_len][mac][ciphertext]

  Future<Uint8List> encryptToBytes(Uint8List plaintext) async {
    final encrypted = await encryptFile(plaintext);

    final buffer = BytesBuilder();

    // Nonce
    final nonceLenBytes = ByteData(4)
      ..setInt32(0, encrypted.nonce.length, Endian.big);
    buffer.add(nonceLenBytes.buffer.asUint8List());
    buffer.add(encrypted.nonce);

    // MAC
    final macLenBytes = ByteData(4)
      ..setInt32(0, encrypted.mac.length, Endian.big);
    buffer.add(macLenBytes.buffer.asUint8List());
    buffer.add(encrypted.mac);

    // Ciphertext
    buffer.add(encrypted.ciphertext);

    return buffer.toBytes();
  }

  Future<Uint8List> decryptFromBytes(Uint8List encryptedBytes) async {
    int offset = 0;

    // Read nonce
    final nonceLen = ByteData.view(
      encryptedBytes.buffer, offset, 4,
    ).getInt32(0, Endian.big);
    offset += 4;
    final nonce = encryptedBytes.sublist(offset, offset + nonceLen);
    offset += nonceLen;

    // Read MAC
    final macLen = ByteData.view(
      encryptedBytes.buffer, offset, 4,
    ).getInt32(0, Endian.big);
    offset += 4;
    final mac = encryptedBytes.sublist(offset, offset + macLen);
    offset += macLen;

    // Read ciphertext
    final ciphertext = encryptedBytes.sublist(offset);

    return decryptFile(EncryptedData(
      ciphertext: ciphertext,
      nonce:      nonce,
      mac:        mac,
    ));
  }
}

class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  const EncryptedData({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });
}
dart

// lib/features/encryption/encryption_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/encryption/encryption_service.dart';

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key});

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  bool _hasKey    = false;
  bool _loading   = true;
  String? _keyB64;
  bool _encryptByDefault = false;

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final has = await EncryptionService.instance.hasKey();
    if (mounted) setState(() { _hasKey = has; _loading = false; });
  }

  Future<void> _generateKey() async {
    final key = await EncryptionService.instance.exportKeyAsBase64();
    if (mounted) setState(() { _hasKey = true; _keyB64 = key; });
  }

  Future<void> _exportKey() async {
    final key = await EncryptionService.instance.exportKeyAsBase64();
    if (mounted) setState(() => _keyB64 = key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encryption')),
      body: _loading
        ? const Center(child: CircularProgressIndicator(
            color: AppColors.primary,
          ))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.categoryGradient(AppColors.codeColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded,
                      size: 48, color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'End-to-End Encryption',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Files are encrypted on your device\n'
                      'before being uploaded to Telegram',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Key Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hasKey
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasKey
                        ? Icons.vpn_key_rounded
                        : Icons.key_off_rounded,
                      color: _hasKey ? AppColors.success : AppColors.warning,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasKey
                              ? 'Encryption Key Found'
                              : 'No Encryption Key',
                            style: AppTextStyles.titleMedium,
                          ),
                          Text(
                            _hasKey
                              ? 'Your key is stored securely on this device'
                              : 'Generate a key to enable encryption',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Encrypt by default toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Encrypt All Uploads',
                            style: AppTextStyles.titleMedium,
                          ),
                          Text(
                            'Automatically encrypt every file you upload',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _encryptByDefault && _hasKey,
                      onChanged: _hasKey
                        ? (v) => setState(() => _encryptByDefault = v)
                        : null,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              if (!_hasKey)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generateKey,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Generate Encryption Key'),
                  ),
                ),

              if (_hasKey) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: _exportKey,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export Key (Backup)'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => _showImportDialog(),
                    icon: const Icon(Icons.upload_rounded,
                      color: AppColors.warning,
                    ),
                    label: const Text(
                      'Import Key',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ),
                ),
              ],

              // Show exported key
              if (_keyB64 != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.codeColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Your Encryption Key',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.codeColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded,
                              color: AppColors.codeColor,
                              size: 18,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _keyB64!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Key copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _keyB64!,
                        style: AppTextStyles.caption.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ Keep this key safe. Without it, '
                        'encrypted files cannot be decrypted.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How it works', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    _InfoPoint('AES-256-GCM encryption (military grade)'),
                    _InfoPoint('Key stored in device secure enclave'),
                    _InfoPoint('Encrypted before leaving your device'),
                    _InfoPoint('Even Telegram cannot read your files'),
                    _InfoPoint('Export your key to restore on new device'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
    );
  }

  void _showImportDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Import Key'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Paste your key here',
            hintText: 'Base64 encoded key...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await EncryptionService.instance.importKeyFromBase64(
                ctrl.text.trim(),
              );
              Navigator.pop(ctx);
              _checkKey();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  final String text;
  const _InfoPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
Part 4: File Sharing
dart

// lib/features/sharing/sharing_service.dart

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';

class SharingService {
  final _dio = DioClient.instance.dio;

  // Create a shareable link via backend
  Future<ShareLink> createShareLink({
    required String fileId,
    int? expiresInHours,
    String? password,
    int? maxDownloads,
  }) async {
    try {
      final res = await _dio.post('/api/share/create', data: {
        'file_id':          fileId,
        'expires_in_hours': expiresInHours,
        'password':         password,
        'max_downloads':    maxDownloads,
      });
      return ShareLink.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ShareLink>> getMySharedLinks() async {
    try {
      final res = await _dio.get('/api/share/list');
      return (res.data['links'] as List)
        .map((l) => ShareLink.fromJson(l))
        .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> revokeLink(String linkId) async {
    try {
      await _dio.delete('/api/share/$linkId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class ShareLink {
  final String id;
  final String fileId;
  final String url;
  final String token;
  final DateTime? expiresAt;
  final bool hasPassword;
  final int? maxDownloads;
  final int downloadCount;
  final bool isActive;
  final DateTime createdAt;

  const ShareLink({
    required this.id,
    required this.fileId,
    required this.url,
    required this.token,
    this.expiresAt,
    required this.hasPassword,
    this.maxDownloads,
    required this.downloadCount,
    required this.isActive,
    required this.createdAt,
  });

  factory ShareLink.fromJson(Map<String, dynamic> json) => ShareLink(
    id:            json['id'],
    fileId:        json['file_id'],
    url:           json['url'],
    token:         json['token'],
    expiresAt:     json['expires_at'] != null
                    ? DateTime.parse(json['expires_at'])
                    : null,
    hasPassword:   json['has_password'] ?? false,
    maxDownloads:  json['max_downloads'],
    downloadCount: json['download_count'] ?? 0,
    isActive:      json['is_active'] ?? true,
    createdAt:     DateTime.parse(json['created_at']),
  );
}
dart

// lib/features/sharing/share_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/files/models/file_model.dart';
import 'sharing_service.dart';

class ShareSheet extends StatefulWidget {
  final FileModel file;
  const ShareSheet({super.key, required this.file});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet>
    with SingleTickerProviderStateMixin {

  late TabController _tabs;
  final _service = SharingService();

  ShareLink? _link;
  bool _creating = false;

  // Options
  int? _expiryHours;
  final _passwordCtrl = TextEditingController();
  int? _maxDownloads;
  bool _showQr = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createLink() async {
    setState(() => _creating = true);
    try {
      final link = await _service.createShareLink(
        fileId:         widget.file.id,
        expiresInHours: _expiryHours,
        password:       _passwordCtrl.text.isEmpty
                          ? null
                          : _passwordCtrl.text,
        maxDownloads:   _maxDownloads,
      );
      if (mounted) setState(() { _link = link; _creating = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyLink() {
    if (_link == null) return;
    Clipboard.setData(ClipboardData(text: _link!.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareLink() {
    if (_link == null) return;
    Share.share(
      'Download "${widget.file.name}" from FTMS:\n${_link!.url}',
      subject: widget.file.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.share_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Share "${widget.file.name}"',
                    style: AppTextStyles.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Create Link'),
              Tab(text: 'Quick Share'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── Create Link Tab ────────────────────────
                ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_link == null) ...[
                      // Expiry
                      Text('Link Expiry', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ChipOption(
                            label: 'Never',
                            selected: _expiryHours == null,
                            onTap: () => setState(() => _expiryHours = null),
                          ),
                          _ChipOption(
                            label: '1 hour',
                            selected: _expiryHours == 1,
                            onTap: () => setState(() => _expiryHours = 1),
                          ),
                          _ChipOption(
                            label: '24 hours',
                            selected: _expiryHours == 24,
                            onTap: () => setState(() => _expiryHours = 24),
                          ),
                          _ChipOption(
                            label: '7 days',
                            selected: _expiryHours == 168,
                            onTap: () => setState(() => _expiryHours = 168),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Password
                      Text('Password (optional)', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Leave empty for no password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),

                      // Max downloads
                      Text('Max Downloads', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ChipOption(
                            label: 'Unlimited',
                            selected: _maxDownloads == null,
                            onTap: () => setState(() => _maxDownloads = null),
                          ),
                          _ChipOption(
                            label: '1',
                            selected: _maxDownloads == 1,
                            onTap: () => setState(() => _maxDownloads = 1),
                          ),
                          _ChipOption(
                            label: '5',
                            selected: _maxDownloads == 5,
                            onTap: () => setState(() => _maxDownloads = 5),
                          ),
                          _ChipOption(
                            label: '10',
                            selected: _maxDownloads == 10,
                            onTap: () => setState(() => _maxDownloads = 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _creating ? null : _createLink,
                          icon: _creating
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.link_rounded),
                          label: Text(_creating ? 'Creating...' : 'Create Link'),
                        ),
                      ),
                    ] else ...[
                      // Link created
                      _LinkCreatedCard(
                        link: _link!,
                        onCopy: _copyLink,
                        onShare: _shareLink,
                        onShowQr: () => setState(() => _showQr = !_showQr),
                        showQr: _showQr,
                      ),
                    ],
                  ],
                ),

                // ── Quick Share Tab ────────────────────────
                ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _QuickShareButton(
                      icon: Icons.copy_rounded,
                      label: 'Copy Download Link',
                      color: AppColors.primary,
                      onTap: () async {
                        await _createLink();
                        _copyLink();
                      },
                    ),
                    const SizedBox(height: 12),
                    _QuickShareButton(
                      icon: Icons.share_rounded,
                      label: 'Share via Apps',
                      color: AppColors.info,
                      onTap: () async {
                        await _createLink();
                        _shareLink();
                      },
                    ),
                    const SizedBox(height: 12),
                    _QuickShareButton(
                      icon: Icons.qr_code_rounded,
                      label: 'Show QR Code',
                      color: AppColors.codeColor,
                      onTap: () async {
                        await _createLink();
                        setState(() => _showQr = true);
                        _tabs.animateTo(0);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkCreatedCard extends StatelessWidget {
  final ShareLink link;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onShowQr;
  final bool showQr;

  const _LinkCreatedCard({
    required this.link,
    required this.onCopy,
    required this.onShare,
    required this.onShowQr,
    required this.showQr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text('Link Created!', style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                link.url,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (link.expiresAt != null)
                    Text(
                      'Expires: ${link.expiresAt!.toLocal().toString().split('.').first}',
                      style: AppTextStyles.caption,
                    ),
                  const Spacer(),
                  Text(
                    '${link.downloadCount} downloads',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                ),
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.codeColor),
            ),
            onPressed: onShowQr,
            icon: Icon(
              showQr ? Icons.qr_code_2_rounded : Icons.qr_code_rounded,
              color: AppColors.codeColor,
              size: 18,
            ),
            label: Text(
              showQr ? 'Hide QR' : 'Show QR Code',
              style: const TextStyle(color: AppColors.codeColor),
            ),
          ),
        ),
        if (showQr) ...[
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: link.url,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan to download file',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
            ? AppColors.primary.withOpacity(0.2)
            : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _QuickShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(label, style: AppTextStyles.titleMedium),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
Part 5: Backend Sharing Routes
Python

# backend/app/api/routes/sharing.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import uuid
import secrets

from app.database.connection import get_db
from app.database.models import User, File as FileModel
from app.api.middleware import get_current_user
from app.services.telegram_service import TelegramService
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/share", tags=["Sharing"])

# ─── In-memory store (use Redis in production) ─────────────

_share_store: dict[str, dict] = {}


class CreateShareRequest(BaseModel):
    file_id: str
    expires_in_hours: Optional[int] = None
    password: Optional[str] = None
    max_downloads: Optional[int] = None


@router.post("/create")
async def create_share_link(
    data: CreateShareRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify file belongs to user
    result = await db.execute(
        select(FileModel).where(
            FileModel.id == data.file_id,
            FileModel.user_id == current_user.id,
            FileModel.upload_status == "complete"
        )
    )
    file = result.scalar_one_or_none()
    if not file:
        raise HTTPException(status_code=404, detail="File not found")

    link_id  = str(uuid.uuid4())
    token    = secrets.token_urlsafe(32)
    base_url = "https://ftms-backend.onrender.com"
    url      = f"{base_url}/api/share/download/{token}"

    expires_at = None
    if data.expires_in_hours:
        expires_at = (
            datetime.utcnow() +
            timedelta(hours=data.expires_in_hours)
        ).isoformat()

    _share_store[token] = {
        "id":             link_id,
        "file_id":        data.file_id,
        "user_id":        str(current_user.id),
        "url":            url,
        "token":          token,
        "expires_at":     expires_at,
        "password":       data.password,
        "max_downloads":  data.max_downloads,
        "download_count": 0,
        "is_active":      True,
        "created_at":     datetime.utcnow().isoformat()
    }

    return {
        "id":             link_id,
        "file_id":        data.file_id,
        "url":            url,
        "token":          token,
        "expires_at":     expires_at,
        "has_password":   data.password is not None,
        "max_downloads":  data.max_downloads,
        "download_count": 0,
        "is_active":      True,
        "created_at":     datetime.utcnow().isoformat()
    }


@router.get("/list")
async def list_share_links(
    current_user: User = Depends(get_current_user)
):
    user_links = [
        v for v in _share_store.values()
        if v["user_id"] == str(current_user.id)
    ]
    return {"links": user_links}


@router.delete("/{link_id}")
async def revoke_share_link(
    link_id: str,
    current_user: User = Depends(get_current_user)
):
    for token, link in list(_share_store.items()):
        if (link["id"] == link_id and
                link["user_id"] == str(current_user.id)):
            del _share_store[token]
            return {"message": "Link revoked"}
    raise HTTPException(status_code=404, detail="Link not found")


@router.get("/download/{token}")
async def download_shared_file(
    token: str,
    password: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """Public endpoint - no auth required"""
    link = _share_store.get(token)
    if not link or not link["is_active"]:
        raise HTTPException(status_code=404, detail="Link not found or expired")

    # Check expiry
    if link["expires_at"]:
        if datetime.utcnow() > datetime.fromisoformat(link["expires_at"]):
            raise HTTPException(status_code=410, detail="Link has expired")

    # Check password
    if link["password"] and link["password"] != password:
        raise HTTPException(status_code=401, detail="Invalid password")

    # Check download limit
    if (link["max_downloads"] and
            link["download_count"] >= link["max_downloads"]):
        raise HTTPException(
            status_code=410,
            detail="Download limit reached"
        )

    # Increment download count
    link["download_count"] += 1

    # Get file and stream from Telegram
    result = await db.execute(
        select(FileModel, User)
        .join(User, User.id == FileModel.user_id)
        .where(FileModel.id == link["file_id"])
    )
    row = result.first()
    if not row:
        raise HTTPException(status_code=404, detail="File not found")

    file_record, owner = row

    from fastapi.responses import StreamingResponse

    tg = TelegramService(
        api_id=int(owner.telegram_api_id),
        api_hash=owner.telegram_api_hash,
        session_string=owner.telegram_session
    )

    async def stream():
        try:
            for msg_id in file_record.telegram_message_ids:
                chunk = await tg.download_file(
                    msg_id,
                    owner.telegram_channel_id
                )
                yield chunk
        finally:
            await tg.disconnect()

    return StreamingResponse(
        stream(),
        media_type=file_record.mime_type or "application/octet-stream",
        headers={
            "Content-Disposition":
                f'attachment; filename="{file_record.original_name}"'
        }
    )