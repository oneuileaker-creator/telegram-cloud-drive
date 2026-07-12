
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
import '../../../core/services/background_transfer_service.dart';


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
    final cachedFolders = _repo.getCachedFolderTree();
    final cachedFiles = _repo.getCachedFiles();
    final hasCache = cachedFolders != null || cachedFiles != null;

    setState(() {
      _page = 1;
      if (!hasCache) {
        _loading = true;
      } else {
        if (cachedFolders != null) _folders = cachedFolders;
        if (cachedFiles != null) {
          _files = cachedFiles;
          _hasMore = cachedFiles.length == 50;
        }
        _loading = false;
      }
    });

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
      if (mounted && _files.isEmpty && _folders.isEmpty) {
        setState(() => _loading = false);
      }
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
    final result = await FilePicker.pickFiles(
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
    final service = BackgroundTransferService();
    final notificationId = task.hashCode;
    await service.startTransfer();
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
          if (total > 0) {
            task.progress = sent / total;
            service.showProgressNotification(
              id: notificationId,
              fileName: task.fileName,
              progress: task.progress,
              isUpload: true,
            );
          }
        },
      );
      task.done = true;
      await service.showProgressNotification(
        id: notificationId,
        fileName: task.fileName,
        progress: 1.0,
        isUpload: true,
      );
      if (mounted) {
        setState(() {});
        _load();
      }
    } catch (e) {
      task.error = e.toString();
      await service.showFailedNotification(
        id: notificationId,
        fileName: task.fileName,
        error: e.toString(),
        isUpload: true,
      );
      if (mounted) {
        setState(() {});
      }
    } finally {
      await service.stopTransfer();
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
        onDownload: () {
          BackgroundTransferService().downloadFile(
            fileId: file.id,
            fileName: file.name,
            context: context,
          );
        },
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
class _UploadTask extends ChangeNotifier {
  final String fileName;
  final String filePath;
  double _progress = 0;
  bool _done = false;
  String? _error;

  double get progress => _progress;
  set progress(double val) {
    if (_progress != val) {
      _progress = val;
      notifyListeners();
    }
  }

  bool get done => _done;
  set done(bool val) {
    if (_done != val) {
      _done = val;
      notifyListeners();
    }
  }

  String? get error => _error;
  set error(String? val) {
    if (_error != val) {
      _error = val;
      notifyListeners();
    }
  }

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
