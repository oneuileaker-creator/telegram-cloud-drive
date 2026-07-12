
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
