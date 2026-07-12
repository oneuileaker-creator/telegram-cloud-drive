import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../encryption/encryption_service.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';

class SecureUploader {
  final _dio = DioClient.instance.dio;
  final _enc = EncryptionService.instance;

  // ── Upload with optional encryption ───────────────────────

  Future<UploadResult> uploadFile({
    required String localPath,
    required String fileName,
    String? folderId,
    bool encrypt = false,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(localPath);
    Uint8List fileBytes = await file.readAsBytes();

    String uploadFileName = fileName;
    bool wasEncrypted = false;

    // Encrypt before upload if requested
    if (encrypt && await _enc.hasKey()) {
      fileBytes = await _enc.encryptToBytes(fileBytes);
      // Mark filename so we know it's encrypted on download
      uploadFileName = '__enc__$fileName';
      wasEncrypted = true;
    }

    // Create multipart with (possibly encrypted) bytes
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: uploadFileName,
      ),
      if (folderId != null) 'folder_id': folderId,
      'is_encrypted': wasEncrypted.toString(),
    });

    final res = await _dio.post(
      ApiConstants.filesUpload,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );

    return UploadResult(
      fileId:    res.data['file_id'],
      encrypted: wasEncrypted,
    );
  }

  // ── Download with automatic decryption ────────────────────

  Future<Uint8List> downloadFile({
    required String fileId,
    required String fileName,
    bool isEncrypted = false,
    void Function(double progress)? onProgress,
  }) async {
    final res = await _dio.get(
      '${ApiConstants.filesDownload}/$fileId',
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );

    Uint8List bytes = Uint8List.fromList(res.data);

    // Decrypt if needed
    final needsDecrypt = isEncrypted ||
      fileName.startsWith('__enc__');

    if (needsDecrypt && await _enc.hasKey()) {
      bytes = await _enc.decryptFromBytes(bytes);
    }

    return bytes;
  }
}

class UploadResult {
  final String fileId;
  final bool encrypted;
  const UploadResult({required this.fileId, required this.encrypted});
}
