
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/network/dio_client.dart';
import '../../models/file_model.dart';

class FileCard extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.getCategoryColor(file.fileType);
    final icon  = FileUtils.getCategoryIcon(file.fileType);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: file.fileType == 'image'
                ? CachedNetworkImage(
                    imageUrl: '${ApiConstants.baseUrl}'
                              '${ApiConstants.thumbnail}/${file.id}',
                    httpHeaders: {
                      'Authorization': 'Bearer token', // handled by interceptor
                    },
                    width: 56, height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _IconFallback(color: color, icon: icon),
                    errorWidget: (_, __, ___) => _IconFallback(color: color, icon: icon),
                  )
                : _IconFallback(color: color, icon: icon),
            ),
            const SizedBox(width: 14),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        FileUtils.formatSize(file.sizeBytes),
                        style: AppTextStyles.caption,
                      ),
                      const Text(' • ', style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                      )),
                      Text(
                        FTMSDateUtils.timeAgo(file.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status / Favorite
            if (file.uploadStatus != 'complete')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  file.uploadStatus,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              )
            else if (file.isFavorite)
              const Icon(
                Icons.star_rounded,
                color: AppColors.warning,
                size: 20,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _IconFallback({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
