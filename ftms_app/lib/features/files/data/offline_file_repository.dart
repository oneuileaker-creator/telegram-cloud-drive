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
