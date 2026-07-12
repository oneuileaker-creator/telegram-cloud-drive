
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../models/file_model.dart';
import '../models/folder_model.dart';
import '../../../core/services/cache_manager.dart';


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
      if (page == 1) {
        final cacheKey = 'files_list_${folderId ?? ""}_${fileType ?? ""}';
        CacheManager.set(cacheKey, files);
      }
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
      CacheManager.set('recent_files', files);
      return files.map((f) => FileModel.fromJson(f)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final res = await _dio.get(ApiConstants.searchStats);
      CacheManager.set('storage_stats', res.data);
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
      final cacheKey = 'folder_tree_${parentId ?? ""}';
      CacheManager.set(cacheKey, folders);
      return folders.map((f) => FolderModel.fromJson(f)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Cache Read Methods ─────────────────────────────────────

  List<FileModel>? getCachedFiles({String? folderId, String? fileType}) {
    final cacheKey = 'files_list_${folderId ?? ""}_${fileType ?? ""}';
    final cached = CacheManager.get(cacheKey);
    if (cached != null && cached is List) {
      return cached.map((f) => FileModel.fromJson(Map<String, dynamic>.from(f))).toList();
    }
    return null;
  }

  List<FolderModel>? getCachedFolderTree({String? parentId}) {
    final cacheKey = 'folder_tree_${parentId ?? ""}';
    final cached = CacheManager.get(cacheKey);
    if (cached != null && cached is List) {
      return cached.map((f) => FolderModel.fromJson(Map<String, dynamic>.from(f))).toList();
    }
    return null;
  }

  List<FileModel>? getCachedRecentFiles() {
    final cached = CacheManager.get('recent_files');
    if (cached != null && cached is List) {
      return cached.map((f) => FileModel.fromJson(Map<String, dynamic>.from(f))).toList();
    }
    return null;
  }

  Map<String, dynamic>? getCachedStorageStats() {
    final cached = CacheManager.get('storage_stats');
    if (cached != null && cached is Map) {
      return Map<String, dynamic>.from(cached);
    }
    return null;
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
