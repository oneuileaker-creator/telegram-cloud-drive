
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/file_model.dart';

class FileOptionsSheet extends StatelessWidget {
  final FileModel file;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const FileOptionsSheet({
    super.key,
    required this.file,
    required this.onOpen,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.getCategoryColor(file.fileType);
    final icon  = FileUtils.getCategoryIcon(file.fileType);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // File header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: AppTextStyles.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${FileUtils.formatSize(file.sizeBytes)} • '
                        '${FTMSDateUtils.formatDate(file.createdAt)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Options
          _Option(
            icon: Icons.open_in_new_rounded,
            label: 'Open',
            onTap: () { Navigator.pop(context); onOpen(); },
          ),
          _Option(
            icon: file.isFavorite
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
            label: file.isFavorite
              ? 'Remove from Favorites'
              : 'Add to Favorites',
            color: AppColors.warning,
            onTap: () { Navigator.pop(context); onFavorite(); },
          ),
          _Option(
            icon: Icons.download_rounded,
            label: 'Download',
            onTap: () { Navigator.pop(context); },
          ),
          _Option(
            icon: Icons.info_outline_rounded,
            label: 'File Details',
            onTap: () {
              Navigator.pop(context);
              _showDetails(context);
            },
          ),
          const Divider(height: 8),
          _Option(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete File'),
        content: Text(
          'Delete "${file.name}"?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FileDetailsSheet(file: file),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(color: c),
      ),
      onTap: onTap,
    );
  }
}

class _FileDetailsSheet extends StatelessWidget {
  final FileModel file;
  const _FileDetailsSheet({required this.file});

  @override
  Widget build(BuildContext context) {
    final meta = file.fileMetadata;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        children: [
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
          Text('File Details', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 20),
          _DetailRow('Name', file.originalName),
          _DetailRow('Type', file.fileType.toUpperCase()),
          _DetailRow('Size', FileUtils.formatSize(file.sizeBytes)),
          _DetailRow('Extension', '.${file.extension ?? 'unknown'}'),
          _DetailRow('Upload Date',
            FTMSDateUtils.formatDateTime(file.createdAt)),
          _DetailRow('Status', file.uploadStatus),
          if (file.isChunked)
            _DetailRow('Chunks', '${file.totalChunks} chunks'),
          if (meta['width'] != null)
            _DetailRow('Dimensions',
              '${meta['width']} × ${meta['height']} px'),
          if (meta['duration_seconds'] != null)
            _DetailRow('Duration',
              FileUtils.formatDuration(
                meta['duration_seconds'] as double
              )),
          if (meta['title'] != null)
            _DetailRow('Title', meta['title'].toString()),
          if (meta['artist'] != null)
            _DetailRow('Artist', meta['artist'].toString()),
          if (meta['album'] != null)
            _DetailRow('Album', meta['album'].toString()),
          if (meta['page_count'] != null)
            _DetailRow('Pages', meta['page_count'].toString()),
          if (meta['camera'] != null)
            _DetailRow('Camera', meta['camera'].toString()),
          if (meta['taken_at'] != null)
            _DetailRow('Taken At', meta['taken_at'].toString()),
          if (meta['line_count'] != null)
            _DetailRow('Lines', meta['line_count'].toString()),
          if (meta['file_count'] != null)
            _DetailRow('Files in archive', meta['file_count'].toString()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyLarge),
          ),
        ],
      ),
    );
  }
}
