
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class UploadProgressSheet extends StatefulWidget {
  final List<dynamic> uploads;
  const UploadProgressSheet({super.key, required this.uploads});

  @override
  State<UploadProgressSheet> createState() => _UploadProgressSheetState();
}

class _UploadProgressSheetState extends State<UploadProgressSheet> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Text('Uploading Files', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),

            ...widget.uploads.map((upload) => _UploadItem(upload: upload)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _UploadItem extends StatefulWidget {
  final dynamic upload;
  const _UploadItem({required this.upload});

  @override
  State<_UploadItem> createState() => _UploadItemState();
}

class _UploadItemState extends State<_UploadItem> {
  @override
  Widget build(BuildContext context) {
    final u = widget.upload;
    return StatefulBuilder(
      builder: (ctx, setState) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      u.fileName,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (u.done)
                    const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20,
                    )
                  else if (u.error != null)
                    const Icon(Icons.error_rounded,
                      color: AppColors.error, size: 20,
                    )
                  else
                    Text(
                      '${(u.progress * 100).toInt()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              LinearPercentIndicator(
                lineHeight: 6,
                percent: u.done ? 1.0 : u.progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.bgElevated,
                progressColor: u.error != null
                  ? AppColors.error
                  : u.done
                    ? AppColors.success
                    : AppColors.primary,
                barRadius: const Radius.circular(3),
                padding: EdgeInsets.zero,
                animation: false,
              ),
              if (u.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Failed: ${u.error}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
