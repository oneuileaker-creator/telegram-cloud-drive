
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/background_transfer_service.dart';

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
    final result = await FilePicker.pickFiles(
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

    final service = BackgroundTransferService();
    final notificationId = file.path.hashCode;
    await service.startTransfer();

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
            final double currentProgress = sent / total;
            if (mounted) {
              setState(() => _progress = currentProgress);
            }
            service.showProgressNotification(
              id: notificationId,
              fileName: file.name,
              progress: currentProgress,
              isUpload: true,
            );
          }
        },
      );

      await service.showProgressNotification(
        id: notificationId,
        fileName: file.name,
        progress: 1.0,
        isUpload: true,
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
      await service.showFailedNotification(
        id: notificationId,
        fileName: file.name,
        error: e.toString(),
        isUpload: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      await service.stopTransfer();
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
