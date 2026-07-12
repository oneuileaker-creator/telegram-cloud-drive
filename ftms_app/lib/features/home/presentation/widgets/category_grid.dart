
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';

class CategoryItem {
  final String category;
  final String label;
  final String route;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.category,
    required this.label,
    required this.route,
    required this.icon,
    required this.color,
  });
}

const _categories = [
  CategoryItem(
    category: 'image',
    label: 'Photos',
    route: '/photos',
    icon: Icons.image_rounded,
    color: AppColors.imageColor,
  ),
  CategoryItem(
    category: 'video',
    label: 'Videos',
    route: '/videos',
    icon: Icons.videocam_rounded,
    color: AppColors.videoColor,
  ),
  CategoryItem(
    category: 'audio',
    label: 'Music',
    route: '/audio',
    icon: Icons.music_note_rounded,
    color: AppColors.audioColor,
  ),
  CategoryItem(
    category: 'document',
    label: 'Docs',
    route: '/documents',
    icon: Icons.description_rounded,
    color: AppColors.documentColor,
  ),
  CategoryItem(
    category: 'code',
    label: 'Code',
    route: '/files',
    icon: Icons.code_rounded,
    color: AppColors.codeColor,
  ),
  CategoryItem(
    category: 'archive',
    label: 'Archives',
    route: '/files',
    icon: Icons.folder_zip_rounded,
    color: AppColors.archiveColor,
  ),
];

class CategoryGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const CategoryGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (ctx, i) {
        final cat = _categories[i];
        final catStats = stats[cat.category] as Map<String, dynamic>?;
        final count = catStats?['count'] ?? 0;

        return _CategoryCard(
          item: cat,
          count: count,
          onTap: () => context.go(cat.route),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem item;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.item,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.categoryGradient(item.color),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$count files',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
