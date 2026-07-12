
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
import '../../../core/services/background_transfer_service.dart';

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
    final cachedFolders = _repo.getCachedFolderTree(parentId: widget.folderId);
    final cachedFiles = _repo.getCachedFiles(folderId: widget.folderId);
    final hasCache = cachedFolders != null || cachedFiles != null;

    if (hasCache) {
      setState(() {
        if (cachedFolders != null) _subFolders = cachedFolders;
        if (cachedFiles != null) _files = cachedFiles;
        _loading = false;
      });
    } else {
      setState(() => _loading = true);
    }

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
      if (mounted && _files.isEmpty && _subFolders.isEmpty) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result == null) return;

    final service = BackgroundTransferService();

    for (final file in result.files) {
      if (file.path == null) continue;
      final notificationId = file.path.hashCode;
      await service.startTransfer();
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path!, filename: file.name,
          ),
          'folder_id': widget.folderId,
        });
        await DioClient.instance.dio.post(
          ApiConstants.filesUpload,
          data: formData,
          onSendProgress: (sent, total) {
            if (total > 0) {
              service.showProgressNotification(
                id: notificationId,
                fileName: file.name,
                progress: sent / total,
                isUpload: true,
              );
            }
          },
        );
        await service.showProgressNotification(
          id: notificationId,
          fileName: file.name,
          progress: 1.0,
          isUpload: true,
        );
      } catch (e) {
        await service.showFailedNotification(
          id: notificationId,
          fileName: file.name,
          error: e.toString(),
          isUpload: true,
        );
      } finally {
        await service.stopTransfer();
      }
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
