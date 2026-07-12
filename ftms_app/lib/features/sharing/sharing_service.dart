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
