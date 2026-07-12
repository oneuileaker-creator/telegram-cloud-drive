
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/files/models/file_model.dart';

class PhotoViewer extends StatefulWidget {
  final List<FileModel> files;
  final int initialIndex;

  const PhotoViewer({
    super.key,
    required this.files,
    required this.initialIndex,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late PageController _pageCtrl;
  late int _current;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.files[_current];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Text(
          '${_current + 1} / ${widget.files.length}',
          style: AppTextStyles.titleMedium,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outlined,
              color: _showInfo ? AppColors.primary : Colors.white,
            ),
            onPressed: () => setState(() => _showInfo = !_showInfo),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Photo Gallery
          PhotoViewGallery.builder(
            pageController: _pageCtrl,
            itemCount: widget.files.length,
            onPageChanged: (i) => setState(() => _current = i),
            builder: (ctx, i) {
              final f = widget.files[i];
              final downloadUrl =
                '${ApiConstants.baseUrl}${ApiConstants.filesDownload}/${f.id}'
                '${DioClient.authToken != null ? "?token=${DioClient.authToken}" : ""}';
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(downloadUrl),
                heroAttributes: PhotoViewHeroAttributes(tag: 'photo_${f.id}'),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
              );
            },
            loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),

          // Info Panel
          if (_showInfo)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name, style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          FileUtils.formatSize(file.sizeBytes),
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Text(' • ', style: TextStyle(
                          color: AppColors.textHint,
                        )),
                        Text(
                          FTMSDateUtils.formatDateTime(file.createdAt),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    // EXIF data
                    if (file.fileMetadata.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      if (file.fileMetadata['camera'] != null)
                        Text(
                          '📷 ${file.fileMetadata['camera']}',
                          style: AppTextStyles.caption,
                        ),
                      if (file.fileMetadata['width'] != null)
                        Text(
                          '📐 ${file.fileMetadata['width']} × ${file.fileMetadata['height']}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
