
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/files/models/file_model.dart';

class PhotoGrid extends StatelessWidget {
  final List<FileModel> photos;
  final ScrollController? controller;
  final void Function(int index) onPhotoTap;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.controller,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      controller: controller,
      crossAxisCount: 3,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      padding: EdgeInsets.zero,
      itemCount: photos.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => onPhotoTap(i),
        child: Hero(
          tag: 'photo_${photos[i].id}',
          child: CachedNetworkImage(
            imageUrl: '${ApiConstants.baseUrl}'
                      '${ApiConstants.thumbnail}/${photos[i].id}'
                      '${DioClient.authToken != null ? "?token=${DioClient.authToken}" : ""}',
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 120,
              color: AppColors.bgCard,
            ),
            errorWidget: (_, __, ___) => Container(
              height: 120,
              color: AppColors.bgCard,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
