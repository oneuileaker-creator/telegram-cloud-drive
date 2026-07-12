
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/files/models/file_model.dart';
import '../../../core/utils/file_utils.dart';

class VideoPlayerScreen extends StatefulWidget {
  final FileModel file;
  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initPlayer() async {
    final url =
      '${ApiConstants.baseUrl}${ApiConstants.filesDownload}/${widget.file.id}';

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller!.initialize();

    _chewie = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primary,
        backgroundColor: AppColors.bgElevated,
        bufferedColor: AppColors.primary.withOpacity(0.3),
      ),
    );

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewie?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.file.name),
      ),
      body: Column(
        children: [
          // Video player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _initialized && _chewie != null
              ? Chewie(controller: _chewie!)
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
          ),

          // File Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.file.name, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    FileUtils.formatSize(widget.file.sizeBytes),
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (widget.file.fileMetadata['duration_seconds'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${FileUtils.formatDuration(
                        widget.file.fileMetadata['duration_seconds'] as double
                      )}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                  if (widget.file.fileMetadata['width'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Resolution: ${widget.file.fileMetadata['width']} × ${widget.file.fileMetadata['height']}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
