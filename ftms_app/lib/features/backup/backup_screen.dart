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
