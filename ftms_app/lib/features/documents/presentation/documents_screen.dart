
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
    final cachedFiles = _repo.getCachedFiles(fileType: 'document');
    final hasCache = cachedFiles != null;

    if (hasCache) {
      setState(() {
        _docs = cachedFiles;
        _loading = false;
      });
    } else {
      setState(() => _loading = true);
    }

    try {
      final files = await _repo.getFiles(fileType: 'document', limit: 100);
      if (mounted) setState(() { _docs = files; _loading = false; });
    } catch (_) {
      if (mounted && _docs.isEmpty) {
        setState(() => _loading = false);
      }
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
