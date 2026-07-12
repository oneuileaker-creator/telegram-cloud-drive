
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/files/models/file_model.dart';
import '../../../core/utils/file_utils.dart';

class AudioPlayerScreen extends StatefulWidget {
  final FileModel file;
  const AudioPlayerScreen({super.key, required this.file});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _player = AudioPlayer();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url =
      '${ApiConstants.baseUrl}${ApiConstants.filesDownload}/${widget.file.id}';
    await _player.setUrl(url);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.file.fileMetadata;
    final title  = meta['title'] ?? widget.file.name;
    final artist = meta['artist'] ?? 'Unknown Artist';
    final album  = meta['album'] ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Now Playing',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Album Art
              Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  color: AppColors.audioColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.audioColor.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  size: 100,
                  color: AppColors.audioColor,
                ),
              ),
              const SizedBox(height: 40),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headlineLarge,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (album.isNotEmpty)
                      Text(album, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (ctx, durSnap) {
                    final duration = durSnap.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (ctx, posSnap) {
                        final position = posSnap.data ?? Duration.zero;
                        return Column(
                          children: [
                            Slider(
                              value: position.inMilliseconds.toDouble().clamp(
                                0, duration.inMilliseconds.toDouble()
                              ),
                              max: duration.inMilliseconds.toDouble(),
                              activeColor: AppColors.audioColor,
                              inactiveColor: AppColors.bgElevated,
                              onChanged: (v) => _player.seek(
                                Duration(milliseconds: v.toInt())
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmt(position),
                                    style: AppTextStyles.caption,
                                  ),
                                  Text(
                                    _fmt(duration),
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle_rounded),
                    iconSize: 28,
                    onPressed: () {},
                    color: AppColors.textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (ctx, snap) {
                      final playing = snap.data?.playing ?? false;
                      return Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.audioColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.audioColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressed: () {
                            playing ? _player.pause() : _player.play();
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat_rounded),
                    iconSize: 28,
                    onPressed: () {},
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
