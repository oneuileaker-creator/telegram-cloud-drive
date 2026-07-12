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
