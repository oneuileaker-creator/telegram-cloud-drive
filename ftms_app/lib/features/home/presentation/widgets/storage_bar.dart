
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';

class StorageBar extends StatelessWidget {
  final int usedBytes;
  final int totalFiles;
  final Map<String, dynamic> byCategory;

  const StorageBar({
    super.key,
    required this.usedBytes,
    required this.totalFiles,
    required this.byCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A3E), Color(0xFF242460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Storage Used', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    FileUtils.formatSize(usedBytes),
                    style: AppTextStyles.headlineLarge,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Files', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$totalFiles',
                    style: AppTextStyles.headlineLarge,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category color bar
          if (byCategory.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: _CategoryBar(
                  byCategory: byCategory,
                  totalBytes: usedBytes,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: byCategory.entries
                .where((e) => (e.value['count'] ?? 0) > 0)
                .map((e) => _LegendItem(
                  color: FileUtils.getCategoryColor(e.key),
                  label: FileUtils.getCategoryLabel(e.key),
                  count: e.value['count'] ?? 0,
                ))
                .toList(),
            ),
          ] else ...[
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload files to see storage breakdown',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final Map<String, dynamic> byCategory;
  final int totalBytes;

  const _CategoryBar({
    required this.byCategory,
    required this.totalBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (totalBytes == 0) return const SizedBox.shrink();

    return Row(
      children: byCategory.entries
        .where((e) => (e.value['size_bytes'] ?? 0) > 0)
        .map((e) {
          final bytes = e.value['size_bytes'] as int;
          final fraction = bytes / totalBytes;
          return Expanded(
            flex: (fraction * 1000).toInt(),
            child: Container(
              color: FileUtils.getCategoryColor(e.key),
            ),
          );
        })
        .toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
