
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../files/data/file_repository.dart';
import '../../files/models/file_model.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final _repo = FileRepository();
  List<FileModel> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cachedFiles = _repo.getCachedFiles(fileType: 'video');
    final hasCache = cachedFiles != null;

    if (hasCache) {
      setState(() {
        _videos = cachedFiles;
        _loading = false;
      });
    } else {
      setState(() => _loading = true);
    }

    try {
      final files = await _repo.getFiles(fileType: 'video', limit: 100);
      if (mounted) setState(() { _videos = files; _loading = false; });
    } catch (_) {
      if (mounted && _videos.isEmpty) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Videos')),
      body: _loading
        ? const LoadingList()
        : _videos.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.videocam_outlined,
              title: 'No videos yet',
              subtitle: 'Your uploaded videos will appear here',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _videos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _VideoCard(
                  video: _videos[i],
                  onTap: () => context.push(
                    '/video-player',
                    extra: _videos[i],
                  ),
                ),
              ),
            ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final FileModel video;
  final VoidCallback onTap;

  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = video.fileMetadata;
    final duration = meta['duration_seconds'] != null
      ? FileUtils.formatDuration(meta['duration_seconds'] as double)
      : null;
    final resolution = meta['width'] != null
      ? '${meta['width']}×${meta['height']}'
      : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 80,
                    color: AppColors.videoColor.withOpacity(0.1),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: AppColors.videoColor,
                      size: 36,
                    ),
                  ),
                  if (duration != null)
                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (resolution != null)
                          _Tag(resolution, AppColors.videoColor),
                        if (meta['video_codec'] != null)
                          _Tag(
                            meta['video_codec'].toString().toUpperCase(),
                            AppColors.textHint,
                          ),
                        _Tag(
                          FileUtils.formatSize(video.sizeBytes),
                          AppColors.textHint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FTMSDateUtils.timeAgo(video.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),

            // Play button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.videoColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.videoColor,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
