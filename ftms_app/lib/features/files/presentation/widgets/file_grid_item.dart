
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/network/dio_client.dart';
import '../../models/file_model.dart';

class FileGridItem extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileGridItem({
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
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: file.fileType == 'image'
                  ? CachedNetworkImage(
                      imageUrl: '${ApiConstants.baseUrl}'
                                '${ApiConstants.thumbnail}/${file.id}'
                                '${DioClient.authToken != null ? "?token=${DioClient.authToken}" : ""}',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: color.withOpacity(0.1),
                        child: Icon(icon, color: color, size: 32),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: color.withOpacity(0.1),
                        child: Icon(icon, color: color, size: 32),
                      ),
                    )
                  : Container(
                      color: color.withOpacity(0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: 36),
                          if (file.fileType == 'video' &&
                              file.fileMetadata['duration_seconds'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                FileUtils.formatDuration(
                                  file.fileMetadata['duration_seconds']
                                    as double
                                ),
                                style: AppTextStyles.caption.copyWith(
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ),

            // File name
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                file.name,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
