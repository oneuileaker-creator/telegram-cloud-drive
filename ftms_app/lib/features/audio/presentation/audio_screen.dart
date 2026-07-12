
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../files/data/file_repository.dart';
import '../../files/models/file_model.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final _repo = FileRepository();
  List<FileModel> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final files = await _repo.getFiles(fileType: 'audio', limit: 100);
      if (mounted) setState(() { _tracks = files; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music')),
      body: _loading
        ? const LoadingList()
        : _tracks.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.music_off_rounded,
              title: 'No music yet',
              subtitle: 'Your uploaded audio files will appear here',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _tracks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _TrackTile(
                  track: _tracks[i],
                  index: i + 1,
                  onTap: () => context.push(
                    '/audio-player',
                    extra: _tracks[i],
                  ),
                ),
              ),
            ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final FileModel track;
  final int index;
  final VoidCallback onTap;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta   = track.fileMetadata;
    final title  = meta['title'] ?? track.name;
    final artist = meta['artist'] ?? 'Unknown Artist';
    final album  = meta['album'];
    final dur    = meta['duration_seconds'] != null
      ? FileUtils.formatDuration(meta['duration_seconds'] as double)
      : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            // Track number / Album art placeholder
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.audioColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: meta['has_cover_art'] == true
                ? const Icon(
                    Icons.album_rounded,
                    color: AppColors.audioColor,
                    size: 28,
                  )
                : Center(
                    child: Text(
                      '$index',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.audioColor,
                      ),
                    ),
                  ),
            ),
            const SizedBox(width: 12),

            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album != null ? '$artist • $album' : artist.toString(),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Duration + play
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (dur != null)
                  Text(dur, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Icon(
                  Icons.play_circle_rounded,
                  color: AppColors.audioColor.withOpacity(0.7),
                  size: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
