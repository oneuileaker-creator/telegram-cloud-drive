
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../features/files/data/file_repository.dart';
import '../../../features/files/models/file_model.dart';
import '../../../features/files/presentation/widgets/file_card.dart';
import '../../../shared/widgets/loading_widget.dart';

const _categories = [
  'all', 'image', 'video', 'audio', 'document', 'code', 'archive'
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repo = FileRepository();
  final _ctrl = TextEditingController();
  List<FileModel> _results = [];
  bool _loading = false;
  String _selectedCategory = 'all';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _repo.search(
        query: q,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      final files = (res['files'] as List)
        .map((f) => FileModel.fromJson(f))
        .toList();
      if (mounted) setState(() {
        _results = files;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openFile(FileModel file) {
    switch (file.fileType) {
      case 'video': context.push('/video-player', extra: file); break;
      case 'audio': context.push('/audio-player', extra: file); break;
      case 'document': context.push('/pdf-viewer', extra: file); break;
      case 'image': context.push('/photo-viewer', extra: {
        'files': [file], 'index': 0,
      }); break;
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              onChanged: (v) => _search(v),
              decoration: InputDecoration(
                hintText: 'Search files, folders...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _results = []);
                      },
                    )
                  : null,
              ),
            ),
          ),

          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                final color = cat == 'all'
                  ? AppColors.primary
                  : FileUtils.getCategoryColor(cat);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    if (_ctrl.text.isNotEmpty) _search(_ctrl.text);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.2) : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? color : AppColors.surfaceLight,
                      ),
                    ),
                    child: Text(
                      cat == 'all'
                        ? 'All'
                        : FileUtils.getCategoryLabel(cat),
                      style: AppTextStyles.label.copyWith(
                        color: selected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Results
          Expanded(
            child: _loading
              ? const LoadingList()
              : _results.isEmpty && _ctrl.text.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results for "${_ctrl.text}"',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search your files',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => FileCard(
                        file: _results[i],
                        onTap: () => _openFile(_results[i]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
