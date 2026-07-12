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
