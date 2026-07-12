
class FolderModel {
  final String id;
  final String name;
  final String? parentId;
  final String path;
  final String color;
  final String icon;
  final int childrenCount;
  final int fileCount;
  final DateTime createdAt;

  const FolderModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.path,
    required this.color,
    required this.icon,
    required this.childrenCount,
    required this.fileCount,
    required this.createdAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) => FolderModel(
    id:             json['id'],
    name:           json['name'],
    parentId:       json['parent_id'],
    path:           json['path'],
    color:          json['color'] ?? '#4ECDC4',
    icon:           json['icon'] ?? 'folder',
    childrenCount:  json['children_count'] ?? 0,
    fileCount:      json['file_count'] ?? 0,
    createdAt:      DateTime.parse(json['created_at']),
  );
}
