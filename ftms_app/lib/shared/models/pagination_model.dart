
import '../../features/files/models/file_model.dart';

class PaginatedFiles {
  final List<FileModel> files;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const PaginatedFiles({
    required this.files,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory PaginatedFiles.fromJson(Map<String, dynamic> json) => PaginatedFiles(
    files:   (json['files'] as List)
                .map((f) => FileModel.fromJson(f))
                .toList(),
    total:   json['total'] ?? 0,
    page:    json['page'] ?? 1,
    limit:   json['limit'] ?? 50,
    hasMore: json['has_more'] ?? false,
  );
}
