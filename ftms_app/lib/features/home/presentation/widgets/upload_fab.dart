import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/upload/secure_uploader.dart';
import '../../../../core/encryption/encryption_service.dart';
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
  final _uploader = SecureUploader();
  bool _encryptionAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkEncryption();
  }

  Future<void> _checkEncryption() async {
    final has = await EncryptionService.instance.hasKey();
    if (mounted) setState(() => _encryptionAvailable = has);
  }

  Future<void> _pickAndUpload({bool encrypt = false}) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    setState(() { _uploading = true; _progress = 0; });

    final service = BackgroundTransferService();
    final notificationId = file.path!.hashCode;
    await service.startTransfer();

    try {
      await _uploader.uploadFile(
        localPath:  file.path!,
        fileName:   file.name,
        encrypt:    encrypt,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
          service.showProgressNotification(
            id: notificationId,
            fileName: file.name,
            progress: p,
            isUpload: true,
          );
        },
      );

      await service.showProgressNotification(
        id: notificationId,
        fileName: file.name,
        progress: 1.0,
        isUpload: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              Icon(
                encrypt
                  ? Icons.lock_rounded
                  : Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                encrypt
                  ? '${file.name} uploaded (encrypted)'
                  : '${file.name} uploaded',
              ),
            ],
          ),
          backgroundColor: encrypt
            ? AppColors.codeColor
            : AppColors.success,
        ));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      await service.stopTransfer();
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Upload File', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 20),

              // Normal upload
              _UploadOption(
                icon: Icons.upload_rounded,
                title: 'Normal Upload',
                subtitle: 'Standard upload to your Telegram storage',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(encrypt: false);
                },
              ),
              const SizedBox(height: 12),

              // Encrypted upload
              _UploadOption(
                icon: Icons.lock_rounded,
                title: 'Encrypted Upload',
                subtitle: _encryptionAvailable
                  ? 'File encrypted on device before upload\n'
                    'Only YOU can decrypt it'
                  : 'Set up encryption key in Settings first',
                color: AppColors.codeColor,
                enabled: _encryptionAvailable,
                badge: 'E2EE',
                onTap: _encryptionAvailable
                  ? () {
                      Navigator.pop(context);
                      _pickAndUpload(encrypt: true);
                    }
                  : null,
              ),

              if (!_encryptionAvailable) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Go to Settings → Encryption to generate your key',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _uploading ? null : _showUploadOptions,
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
        _uploading
          ? '${(_progress * 100).toInt()}%'
          : 'Upload',
        style: AppTextStyles.titleMedium.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  final String? badge;

  const _UploadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.enabled = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: AppTextStyles.titleMedium),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withOpacity(0.5),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
