
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/files/data/file_repository.dart';
import '../../../features/files/models/file_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import 'widgets/photo_grid.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final _repo = FileRepository();
  List<FileModel> _photos = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _load() async {
    final cachedFiles = _repo.getCachedFiles(fileType: 'image');
    final hasCache = cachedFiles != null;

    setState(() {
      _page = 1;
      if (!hasCache) {
        _loading = true;
      } else {
        _photos = cachedFiles;
        _hasMore = cachedFiles.length == 60;
        _loading = false;
      }
    });

    try {
      final files = await _repo.getFiles(fileType: 'image', page: 1, limit: 60);
      if (mounted) setState(() {
        _photos = files;
        _loading = false;
        _hasMore = files.length == 60;
      });
    } catch (_) {
      if (mounted && _photos.isEmpty) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final files = await _repo.getFiles(
        fileType: 'image', page: ++_page, limit: 60,
      );
      if (mounted) setState(() {
        _photos.addAll(files);
        _loadingMore = false;
        _hasMore = files.length == 60;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
        ? const LoadingGrid()
        : _photos.isEmpty
          ? EmptyStateWidget(
              icon: Icons.photo_library_outlined,
              title: 'No photos yet',
              subtitle: 'Your uploaded images will appear here',
              onAction: () {},
              actionLabel: 'Upload Photo',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: PhotoGrid(
                photos: _photos,
                controller: _scroll,
                onPhotoTap: (index) => context.push(
                  '/photo-viewer',
                  extra: {'files': _photos, 'index': index},
                ),
              ),
            ),
    );
  }
}
