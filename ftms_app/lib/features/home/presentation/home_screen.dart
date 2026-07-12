
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/files/data/file_repository.dart';
import '../../../features/files/models/file_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../files/presentation/widgets/file_card.dart';
import 'widgets/category_grid.dart';
import 'widgets/storage_bar.dart';
import 'widgets/upload_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fileRepo = FileRepository();
  List<FileModel> _recentFiles = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cachedRecent = _fileRepo.getCachedRecentFiles();
    final cachedStats = _fileRepo.getCachedStorageStats();
    if (cachedRecent != null || cachedStats != null) {
      if (mounted) {
        setState(() {
          if (cachedRecent != null) _recentFiles = cachedRecent;
          if (cachedStats != null) _stats = cachedStats;
          _loading = false;
        });
      }
    }

    try {
      final recent = await _fileRepo.getRecentFiles();
      final stats  = await _fileRepo.getStorageStats();
      if (mounted) {
        setState(() {
          _recentFiles = recent;
          _stats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && _recentFiles.isEmpty && _stats.isEmpty) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state is AuthAuthenticated)
      ? (context.watch<AuthBloc>().state as AuthAuthenticated).user
      : null;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              title: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('FTMS'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      user?.username.substring(0, 1).toUpperCase() ?? 'U',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  onPressed: () => context.go('/settings'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Greeting ──────────────────────────
                    Text(
                      'Hey ${user?.username ?? 'there'} 👋',
                      style: AppTextStyles.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your unlimited cloud is ready',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // ── Storage Bar ───────────────────────
                    StorageBar(
                      usedBytes: _stats['total_size_bytes'] ?? 0,
                      totalFiles: _stats['total_files'] ?? 0,
                      byCategory: _stats['by_category'] ?? {},
                    ),
                    const SizedBox(height: 28),

                    // ── Categories ────────────────────────
                    Text('Browse', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    CategoryGrid(stats: _stats['by_category'] ?? {}),
                    const SizedBox(height: 28),

                    // ── Recent Files ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent', style: AppTextStyles.headlineMedium),
                        TextButton(
                          onPressed: () => context.go('/files'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Recent Files List ──────────────────────────
            if (_loading)
              const SliverToBoxAdapter(child: SizedBox(height: 200))
            else if (_recentFiles.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateWidget(
                  icon: Icons.cloud_upload_outlined,
                  title: 'No files yet',
                  subtitle: 'Upload your first file to get started',
                  actionLabel: 'Upload File',
                  onAction: () {},
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FileCard(
                        file: _recentFiles[i],
                        onTap: () => _openFile(_recentFiles[i]),
                      ),
                    ),
                    childCount: _recentFiles.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: UploadFAB(onUploaded: _loadData),
    );
  }

  void _openFile(FileModel file) {
    switch (file.fileType) {
      case 'video':
        context.push('/video-player', extra: file);
        break;
      case 'audio':
        context.push('/audio-player', extra: file);
        break;
      case 'document':
        context.push('/pdf-viewer', extra: file);
        break;
      case 'image':
        context.push('/photo-viewer', extra: {
          'files': [file],
          'index': 0,
        });
        break;
      default:
        break;
    }
  }
}
