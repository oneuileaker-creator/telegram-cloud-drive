Phase 4: Files Browser + Folder System + Windows Polish
Complete File Management Experience
Step 1: Files Screen (Full File Browser)
dart

// lib/features/files/presentation/files_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/file_utils.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../data/file_repository.dart';
import '../models/file_model.dart';
import '../models/folder_model.dart';
import 'widgets/file_card.dart';
import 'widgets/folder_card.dart';
import 'widgets/file_grid_item.dart';
import 'widgets/create_folder_sheet.dart';
import 'widgets/file_options_sheet.dart';
import 'widgets/upload_progress_sheet.dart';

enum ViewMode { list, grid }
enum SortBy { name, date, size, type }

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _repo = FileRepository();

  List<FolderModel> _folders = [];
  List<FileModel>   _files   = [];
  bool _loading    = true;
  bool _loadingMore= false;
  int  _page       = 1;
  bool _hasMore    = true;
  ViewMode _viewMode = ViewMode.list;
  SortBy   _sortBy   = SortBy.date;
  bool     _sortAsc  = false;

  // Upload tracking
  List<_UploadTask> _uploads = [];

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
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 300) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _page = 1; });
    try {
      final folders = await _repo.getFolderTree();
      final files   = await _repo.getFiles(page: 1, limit: 50);
      if (mounted) {
        setState(() {
          _folders  = folders;
          _files    = files;
          _loading  = false;
          _hasMore  = files.length == 50;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final files = await _repo.getFiles(page: ++_page, limit: 50);
      if (mounted) {
        setState(() {
          _files.addAll(files);
          _loadingMore = false;
          _hasMore = files.length == 50;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<FileModel> get _sortedFiles {
    final list = List<FileModel>.from(_files);
    switch (_sortBy) {
      case SortBy.name:
        list.sort((a, b) => _sortAsc
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name));
        break;
      case SortBy.date:
        list.sort((a, b) => _sortAsc
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));
        break;
      case SortBy.size:
        list.sort((a, b) => _sortAsc
          ? a.sizeBytes.compareTo(b.sizeBytes)
          : b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case SortBy.type:
        list.sort((a, b) => _sortAsc
          ? a.fileType.compareTo(b.fileType)
          : b.fileType.compareTo(a.fileType));
        break;
    }
    return list;
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if (file.path == null) continue;
      final task = _UploadTask(
        fileName: file.name,
        filePath: file.path!,
      );
      setState(() => _uploads.add(task));
      _uploadFile(task);
    }

    // Show progress sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => UploadProgressSheet(uploads: _uploads),
      );
    }
  }

  Future<void> _uploadFile(_UploadTask task) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          task.filePath,
          filename: task.fileName,
        ),
      });
      await DioClient.instance.dio.post(
        ApiConstants.filesUpload,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => task.progress = sent / total);
          }
        },
      );
      if (mounted) {
        setState(() => task.done = true);
        _load();
      }
    } catch (e) {
      if (mounted) setState(() => task.error = e.toString());
    }
  }

  void _createFolder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CreateFolderSheet(
        onCreated: (name, color) async {
          await _repo.createFolder(name: name, color: color);
          _load();
        },
      ),
    );
  }

  void _showFileOptions(FileModel file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FileOptionsSheet(
        file: file,
        onFavorite: () async {
          await _repo.toggleFavorite(file.id, !file.isFavorite);
          _load();
        },
        onDelete: () async {
          await _repo.deleteFile(file.id);
          _load();
        },
        onOpen: () => _openFile(file),
      ),
    );
  }

  void _openFile(FileModel file) {
    switch (file.fileType) {
      case 'video':    context.push('/video-player', extra: file); break;
      case 'audio':    context.push('/audio-player', extra: file); break;
      case 'document': context.push('/pdf-viewer',   extra: file); break;
      case 'image':
        context.push('/photo-viewer', extra: {
          'files': _files
            .where((f) => f.fileType == 'image')
            .toList(),
          'index': _files
            .where((f) => f.fileType == 'image')
            .toList()
            .indexWhere((f) => f.id == file.id),
        });
        break;
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scroll,
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            floating: true,
            title: const Text('Files'),
            actions: [
              // Sort button
              PopupMenuButton<SortBy>(
                icon: const Icon(Icons.sort_rounded),
                color: AppColors.bgCard,
                onSelected: (v) => setState(() => _sortBy = v),
                itemBuilder: (_) => [
                  _sortItem(SortBy.date, 'Date', Icons.calendar_today_rounded),
                  _sortItem(SortBy.name, 'Name', Icons.sort_by_alpha_rounded),
                  _sortItem(SortBy.size, 'Size', Icons.data_usage_rounded),
                  _sortItem(SortBy.type, 'Type', Icons.category_rounded),
                ],
              ),
              // View toggle
              IconButton(
                icon: Icon(
                  _viewMode == ViewMode.list
                    ? Icons.grid_view_rounded
                    : Icons.list_rounded,
                ),
                onPressed: () => setState(() => _viewMode =
                  _viewMode == ViewMode.list
                    ? ViewMode.grid
                    : ViewMode.list,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: _loading
          ? const LoadingList()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [

                  // ── Active Uploads ──────────────────────
                  if (_uploads.any((u) => !u.done && u.error == null))
                    SliverToBoxAdapter(
                      child: _ActiveUploadsBar(uploads: _uploads),
                    ),

                  // ── Folders Section ─────────────────────
                  if (_folders.isNotEmpty) ...[
                    _sectionHeader('Folders', _folders.length),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.2,
                          ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => FolderCard(
                            folder: _folders[i],
                            onTap: () => context.push(
                              '/files/folder/${_folders[i].id}',
                              extra: {'name': _folders[i].name},
                            ),
                            onLongPress: () =>
                              _showFolderOptions(_folders[i]),
                          ),
                          childCount: _folders.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8),
                    ),
                  ],

                  // ── Files Section ───────────────────────
                  _sectionHeader('Files', _files.length),

                  if (_files.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        icon: Icons.folder_open_rounded,
                        title: 'No files yet',
                        subtitle: 'Tap + to upload your first file',
                      ),
                    )
                  else
                    _viewMode == ViewMode.list
                      ? SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: FileCard(
                                  file: _sortedFiles[i],
                                  onTap: () => _openFile(_sortedFiles[i]),
                                  onLongPress: () =>
                                    _showFileOptions(_sortedFiles[i]),
                                ),
                              ),
                              childCount: _sortedFiles.length,
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => FileGridItem(
                                file: _sortedFiles[i],
                                onTap: () => _openFile(_sortedFiles[i]),
                                onLongPress: () =>
                                  _showFileOptions(_sortedFiles[i]),
                              ),
                              childCount: _sortedFiles.length,
                            ),
                          ),
                        ),

                  // ── Load more indicator ─────────────────
                  if (_loadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
      ),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'folder_fab',
            mini: true,
            backgroundColor: AppColors.bgCard,
            onPressed: _createFolder,
            child: const Icon(
              Icons.create_new_folder_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'upload_fab',
            backgroundColor: AppColors.primary,
            onPressed: _pickAndUpload,
            icon: const Icon(Icons.upload_rounded, color: Colors.white),
            label: const Text(
              'Upload',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            Text(title, style: AppTextStyles.headlineMedium),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<SortBy> _sortItem(
    SortBy value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodyLarge),
          const Spacer(),
          if (_sortBy == value)
            Icon(
              _sortAsc
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
              size: 16,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  void _showFolderOptions(FolderModel folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FolderOptionsSheet(
        folder: folder,
        onDelete: () async {
          await _repo.deleteFolder(folder.id);
          _load();
        },
        onRename: () => _renameFolder(folder),
      ),
    );
  }

  void _renameFolder(FolderModel folder) {
    final ctrl = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Rename Folder'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Call rename API
              await DioClient.instance.dio.patch(
                '${ApiConstants.folders}/${folder.id}/rename',
                queryParameters: {'new_name': ctrl.text.trim()},
              );
              _load();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

// Upload task model
class _UploadTask {
  final String fileName;
  final String filePath;
  double progress = 0;
  bool done = false;
  String? error;

  _UploadTask({required this.fileName, required this.filePath});
}

// Active uploads indicator bar
class _ActiveUploadsBar extends StatelessWidget {
  final List<_UploadTask> uploads;
  const _ActiveUploadsBar({required this.uploads});

  @override
  Widget build(BuildContext context) {
    final active = uploads.where((u) => !u.done && u.error == null).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Uploading ${active.length} file(s)...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderOptionsSheet extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _FolderOptionsSheet({
    required this.folder,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      folder.name,
                      style: AppTextStyles.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            _OptionTile(
              icon: Icons.drive_file_rename_outline_rounded,
              label: 'Rename',
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Folder',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: c)),
      onTap: onTap,
    );
  }
}
Step 2: Folder Screen (Drill Down)
dart

// lib/features/files/presentation/folder_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../data/file_repository.dart';
import '../models/file_model.dart';
import '../models/folder_model.dart';
import 'widgets/file_card.dart';
import 'widgets/folder_card.dart';
import 'widgets/file_options_sheet.dart';

class FolderScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const FolderScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final _repo = FileRepository();
  List<FolderModel> _subFolders = [];
  List<FileModel>   _files      = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final folders = await _repo.getFolderTree(parentId: widget.folderId);
      final files   = await _repo.getFiles(
        folderId: widget.folderId,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _subFolders = folders;
          _files      = files;
          _loading    = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    for (final file in result.files) {
      if (file.path == null) continue;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path!, filename: file.name,
        ),
        'folder_id': widget.folderId,
      });
      await DioClient.instance.dio.post(
        ApiConstants.filesUpload,
        data: formData,
      );
    }
    _load();
  }

  void _openFile(FileModel file) {
    switch (file.fileType) {
      case 'video':    context.push('/video-player', extra: file); break;
      case 'audio':    context.push('/audio-player', extra: file); break;
      case 'document': context.push('/pdf-viewer',   extra: file); break;
      case 'image':
        final images = _files.where((f) => f.fileType == 'image').toList();
        context.push('/photo-viewer', extra: {
          'files': images,
          'index': images.indexWhere((f) => f.id == file.id),
        });
        break;
      default: break;
    }
  }

  void _showFileOptions(FileModel file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FileOptionsSheet(
        file: file,
        onFavorite: () async {
          await _repo.toggleFavorite(file.id, !file.isFavorite);
          _load();
        },
        onDelete: () async {
          await _repo.deleteFile(file.id);
          _load();
        },
        onOpen: () => _openFile(file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_rounded),
            onPressed: _upload,
          ),
        ],
      ),
      body: _loading
        ? const LoadingList()
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: _subFolders.isEmpty && _files.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.folder_open_rounded,
                  title: 'Folder is empty',
                  subtitle: 'Upload files to this folder',
                  actionLabel: 'Upload',
                  onAction: _upload,
                )
              : CustomScrollView(
                  slivers: [
                    // Sub-folders
                    if (_subFolders.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Folders',
                            style: AppTextStyles.headlineMedium,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                            ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => FolderCard(
                              folder: _subFolders[i],
                              onTap: () => context.push(
                                '/files/folder/${_subFolders[i].id}',
                                extra: {'name': _subFolders[i].name},
                              ),
                              onLongPress: () {},
                            ),
                            childCount: _subFolders.length,
                          ),
                        ),
                      ),
                    ],

                    // Files
                    if (_files.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Files',
                            style: AppTextStyles.headlineMedium,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: FileCard(
                                file: _files[i],
                                onTap: () => _openFile(_files[i]),
                                onLongPress: () =>
                                  _showFileOptions(_files[i]),
                              ),
                            ),
                            childCount: _files.length,
                          ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
          ),
    );
  }
}
Step 3: Folder Card Widget
dart

// lib/features/files/presentation/widgets/folder_card.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/folder_model.dart';

class FolderCard extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onLongPress,
  });

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(folder.color);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    folder.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${folder.fileCount} files',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (folder.childrenCount > 0)
              Icon(
                Icons.chevron_right_rounded,
                color: color.withOpacity(0.6),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
Step 4: File Grid Item Widget
dart

// lib/features/files/presentation/widgets/file_grid_item.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../models/file_model.dart';

class FileGridItem extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileGridItem({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.getCategoryColor(file.fileType);
    final icon  = FileUtils.getCategoryIcon(file.fileType);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: file.fileType == 'image'
                  ? CachedNetworkImage(
                      imageUrl: '${ApiConstants.baseUrl}'
                                '${ApiConstants.thumbnail}/${file.id}',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: color.withOpacity(0.1),
                        child: Icon(icon, color: color, size: 32),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: color.withOpacity(0.1),
                        child: Icon(icon, color: color, size: 32),
                      ),
                    )
                  : Container(
                      color: color.withOpacity(0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: 36),
                          if (file.fileType == 'video' &&
                              file.fileMetadata['duration_seconds'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                FileUtils.formatDuration(
                                  file.fileMetadata['duration_seconds']
                                    as double
                                ),
                                style: AppTextStyles.caption.copyWith(
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ),

            // File name
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                file.name,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Step 5: Bottom Sheets
dart

// lib/features/files/presentation/widgets/create_folder_sheet.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

const _colors = [
  '#4ECDC4', '#FF6B6B', '#45B7D1', '#96CEB4',
  '#A29BFE', '#FFEAA7', '#FD79A8', '#6C63FF',
  '#00D2FF', '#00C896', '#FFB347', '#B2BEC3',
];

class CreateFolderSheet extends StatefulWidget {
  final void Function(String name, String color) onCreated;

  const CreateFolderSheet({super.key, required this.onCreated});

  @override
  State<CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<CreateFolderSheet> {
  final _ctrl = TextEditingController();
  String _selectedColor = _colors[0];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
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

              Text('New Folder', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 20),

              // Name input
              TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Folder name',
                  prefixIcon: Icon(Icons.folder_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Color picker
              Text('Color', style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((hex) {
                  final color = _hexColor(hex);
                  final selected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                          ? [BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8, spreadRadius: 2,
                            )]
                          : [],
                      ),
                      child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_ctrl.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    widget.onCreated(
                      _ctrl.text.trim(),
                      _selectedColor,
                    );
                  },
                  child: const Text('Create Folder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
dart

// lib/features/files/presentation/widgets/file_options_sheet.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/file_model.dart';

class FileOptionsSheet extends StatelessWidget {
  final FileModel file;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const FileOptionsSheet({
    super.key,
    required this.file,
    required this.onOpen,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.getCategoryColor(file.fileType);
    final icon  = FileUtils.getCategoryIcon(file.fileType);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // File header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: AppTextStyles.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${FileUtils.formatSize(file.sizeBytes)} • '
                        '${FTMSDateUtils.formatDate(file.createdAt)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Options
          _Option(
            icon: Icons.open_in_new_rounded,
            label: 'Open',
            onTap: () { Navigator.pop(context); onOpen(); },
          ),
          _Option(
            icon: file.isFavorite
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
            label: file.isFavorite
              ? 'Remove from Favorites'
              : 'Add to Favorites',
            color: AppColors.warning,
            onTap: () { Navigator.pop(context); onFavorite(); },
          ),
          _Option(
            icon: Icons.download_rounded,
            label: 'Download',
            onTap: () { Navigator.pop(context); },
          ),
          _Option(
            icon: Icons.info_outline_rounded,
            label: 'File Details',
            onTap: () {
              Navigator.pop(context);
              _showDetails(context);
            },
          ),
          const Divider(height: 8),
          _Option(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete File'),
        content: Text(
          'Delete "${file.name}"?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FileDetailsSheet(file: file),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(color: c),
      ),
      onTap: onTap,
    );
  }
}

class _FileDetailsSheet extends StatelessWidget {
  final FileModel file;
  const _FileDetailsSheet({required this.file});

  @override
  Widget build(BuildContext context) {
    final meta = file.fileMetadata;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        children: [
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
          Text('File Details', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 20),
          _DetailRow('Name', file.originalName),
          _DetailRow('Type', file.fileType.toUpperCase()),
          _DetailRow('Size', FileUtils.formatSize(file.sizeBytes)),
          _DetailRow('Extension', '.${file.extension ?? 'unknown'}'),
          _DetailRow('Upload Date',
            FTMSDateUtils.formatDateTime(file.createdAt)),
          _DetailRow('Status', file.uploadStatus),
          if (file.isChunked)
            _DetailRow('Chunks', '${file.totalChunks} chunks'),
          if (meta['width'] != null)
            _DetailRow('Dimensions',
              '${meta['width']} × ${meta['height']} px'),
          if (meta['duration_seconds'] != null)
            _DetailRow('Duration',
              FileUtils.formatDuration(
                meta['duration_seconds'] as double
              )),
          if (meta['title'] != null)
            _DetailRow('Title', meta['title'].toString()),
          if (meta['artist'] != null)
            _DetailRow('Artist', meta['artist'].toString()),
          if (meta['album'] != null)
            _DetailRow('Album', meta['album'].toString()),
          if (meta['page_count'] != null)
            _DetailRow('Pages', meta['page_count'].toString()),
          if (meta['camera'] != null)
            _DetailRow('Camera', meta['camera'].toString()),
          if (meta['taken_at'] != null)
            _DetailRow('Taken At', meta['taken_at'].toString()),
          if (meta['line_count'] != null)
            _DetailRow('Lines', meta['line_count'].toString()),
          if (meta['file_count'] != null)
            _DetailRow('Files in archive', meta['file_count'].toString()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyLarge),
          ),
        ],
      ),
    );
  }
}
dart

// lib/features/files/presentation/widgets/upload_progress_sheet.dart

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
Step 6: Videos + Audio + Documents List Screens
dart

// lib/features/videos/presentation/videos_screen.dart

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
    setState(() => _loading = true);
    try {
      final files = await _repo.getFiles(fileType: 'video', limit: 100);
      if (mounted) setState(() { _videos = files; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
dart

// lib/features/audio/presentation/audio_screen.dart

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
dart

// lib/features/documents/presentation/documents_screen.dart

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

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _repo = FileRepository();
  List<FileModel> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final files = await _repo.getFiles(fileType: 'document', limit: 100);
      if (mounted) setState(() { _docs = files; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: _loading
        ? const LoadingList()
        : _docs.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.description_outlined,
              title: 'No documents yet',
              subtitle: 'PDF, Word, Excel files will appear here',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _DocCard(
                  doc: _docs[i],
                  onTap: () => _docs[i].mime_type == 'application/pdf'
                    ? context.push('/pdf-viewer', extra: _docs[i])
                    : null,
                ),
              ),
            ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final FileModel doc;
  final VoidCallback? onTap;

  const _DocCard({required this.doc, this.onTap});

  Color _extColor(String? ext) {
    switch (ext) {
      case 'pdf':  return const Color(0xFFFF6B6B);
      case 'docx':
      case 'doc':  return const Color(0xFF2B5CE6);
      case 'xlsx':
      case 'xls':  return const Color(0xFF00C896);
      case 'pptx':
      case 'ppt':  return const Color(0xFFFF9500);
      default:     return AppColors.documentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta  = doc.fileMetadata;
    final color = _extColor(doc.extension);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            // Doc type icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_rounded, color: color, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    (doc.extension ?? '').toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        FileUtils.formatSize(doc.sizeBytes),
                        style: AppTextStyles.caption,
                      ),
                      if (meta['page_count'] != null) ...[
                        const Text(' • ', style: TextStyle(
                          color: AppColors.textHint, fontSize: 11,
                        )),
                        Text(
                          '${meta['page_count']} pages',
                          style: AppTextStyles.caption,
                        ),
                      ],
                      if (meta['author'] != null) ...[
                        const Text(' • ', style: TextStyle(
                          color: AppColors.textHint, fontSize: 11,
                        )),
                        Expanded(
                          child: Text(
                            meta['author'].toString(),
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FTMSDateUtils.timeAgo(doc.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// Fix extension access in doc
extension on FileModel {
  String? get mime_type => mimeType;
}
Step 7: Windows Drag & Drop Upload
dart

// lib/core/utils/windows_drop_zone.dart

import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

// For Windows drag & drop support add to pubspec.yaml:
// desktop_drop: ^0.4.4

class WindowsDropZone extends StatefulWidget {
  final Widget child;
  final void Function(List<String> paths) onFilesDropped;

  const WindowsDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
  });

  @override
  State<WindowsDropZone> createState() => _WindowsDropZoneState();
}

class _WindowsDropZoneState extends State<WindowsDropZone> {
  bool _dragging = false;

  bool get _isDesktop =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return widget.child;

    // Use desktop_drop package when on Windows
    // For now returning child with visual overlay
    return Stack(
      children: [
        widget.child,
        if (_dragging)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_rounded,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Drop files here',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Release to upload',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
dart

// lib/core/utils/platform_utils.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  static bool get isMobile =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static double get sidebarWidth => isDesktop ? 260 : 0;
  static int get photoGridColumns => isDesktop ? 5 : 3;
  static int get fileGridColumns  => isDesktop ? 4 : 3;
  static int get folderGridColumns=> isDesktop ? 4 : 2;
}
Step 8: Windows Responsive Layout
dart

// lib/shared/widgets/responsive_layout.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/platform_utils.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktop && desktop != null) {
      return desktop!;
    }
    return mobile;
  }
}

// Windows sidebar navigation
class DesktopShell extends StatelessWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home'))     return 0;
    if (location.startsWith('/files'))    return 1;
    if (location.startsWith('/photos'))   return 2;
    if (location.startsWith('/videos'))   return 3;
    if (location.startsWith('/audio'))    return 4;
    if (location.startsWith('/documents'))return 5;
    if (location.startsWith('/search'))   return 6;
    if (location.startsWith('/settings')) return 7;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _Sidebar(currentIndex: _currentIndex(context)),
          // Vertical divider
          Container(width: 1, color: AppColors.surfaceLight),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  const _Sidebar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.bgCard,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('FTMS', style: AppTextStyles.headlineMedium),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Nav items
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => context.go('/home'),
          ),
          _NavItem(
            icon: Icons.folder_rounded,
            label: 'Files',
            selected: currentIndex == 1,
            onTap: () => context.go('/files'),
          ),
          const SizedBox(height: 8),
          _SidebarSection('Media'),
          _NavItem(
            icon: Icons.image_rounded,
            label: 'Photos',
            selected: currentIndex == 2,
            onTap: () => context.go('/photos'),
          ),
          _NavItem(
            icon: Icons.videocam_rounded,
            label: 'Videos',
            selected: currentIndex == 3,
            onTap: () => context.go('/videos'),
          ),
          _NavItem(
            icon: Icons.music_note_rounded,
            label: 'Music',
            selected: currentIndex == 4,
            onTap: () => context.go('/audio'),
          ),
          _NavItem(
            icon: Icons.description_rounded,
            label: 'Documents',
            selected: currentIndex == 5,
            onTap: () => context.go('/documents'),
          ),
          const SizedBox(height: 8),
          _SidebarSection('Discover'),
          _NavItem(
            icon: Icons.search_rounded,
            label: 'Search',
            selected: currentIndex == 6,
            onTap: () => context.go('/search'),
          ),

          const Spacer(),
          const Divider(),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            selected: currentIndex == 7,
            onTap: () => context.go('/settings'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
          title: Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  const _SidebarSection(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          letterSpacing: 1.5,
          color: AppColors.textHint,
          fontSize: 10,
        ),
      ),
    );
  }
}
Step 9: Update FTMSShell for Desktop
dart

// lib/shared/widgets/ftms_shell.dart  (UPDATED)

import 'package:flutter/material.dart';
import '../../core/utils/platform_utils.dart';
import 'responsive_layout.dart';
import 'ftms_bottom_nav.dart'; // existing bottom nav

class FTMSShell extends StatelessWidget {
  final Widget child;
  const FTMSShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileShell(child: child),
      desktop: DesktopShell(child: child),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const FTMSBottomNav(),
    );
  }
}
dart

// lib/shared/widgets/ftms_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class FTMSBottomNav extends StatelessWidget {
  const FTMSBottomNav({super.key});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home'))     return 0;
    if (location.startsWith('/files'))    return 1;
    if (location.startsWith('/photos'))   return 2;
    if (location.startsWith('/search'))   return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home');     break;
            case 1: context.go('/files');    break;
            case 2: context.go('/photos');   break;
            case 3: context.go('/search');   break;
            case 4: context.go('/settings'); break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: 'Photos',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
Step 10: Windows Title Bar
dart

// lib/core/utils/window_manager.dart

import 'package:flutter/material.dart';
import 'dart:io' show Platform;

// Add to pubspec.yaml:
// window_manager: ^0.3.8

Future<void> setupWindowsWindow() async {
  if (!Platform.isWindows) return;

  // Uncomment when window_manager is added:
  // await windowManager.ensureInitialized();
  // WindowOptions windowOptions = const WindowOptions(
  //   size: Size(1200, 800),
  //   minimumSize: Size(900, 600),
  //   center: true,
  //   title: 'FTMS - File Type Management System',
  //   titleBarStyle: TitleBarStyle.hidden,
  // );
  // await windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   await windowManager.show();
  //   await windowManager.focus();
  // });
}
Step 11: Final main.dart Update
dart

// lib/main.dart  (UPDATED)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io' show Platform;
import 'app.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive
  await Hive.initFlutter();

  // System UI (Android)
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0F1A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(AuthRepository())
            ..add(CheckAuthStatus()),
        ),
      ],
      child: const FTMSApp(),
    ),
  );
}
Step 12: Build & Run
Bash

# ─── Android ─────────────────────────────────────────────────
flutter run -d android

# Release APK
flutter build apk --release --split-per-abi

# Release App Bundle (Play Store)
flutter build appbundle --release

# ─── Windows ─────────────────────────────────────────────────
flutter run -d windows

# Release EXE
flutter build windows --release

# Output location:
# build/windows/x64/runner/Release/ftms_app.exe

# ─── Both at once (dev) ──────────────────────────────────────
# Terminal 1:
flutter run -d android

# Terminal 2:
flutter run -d windows