import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class CachedFile extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String originalName;
  @HiveField(2) late String fileType;
  @HiveField(3) late String? mimeType;
  @HiveField(4) late String? extension;
  @HiveField(5) late int sizeBytes;
  @HiveField(6) late String uploadStatus;
  @HiveField(7) late List<String> tags;
  @HiveField(8) late bool isFavorite;
  @HiveField(9) late String? folderId;
  @HiveField(10) late String createdAt;
  @HiveField(11) late String? displayName;
  @HiveField(12) late Map<String, dynamic> fileMetadata;

  CachedFile();

  factory CachedFile.fromMap(Map<String, dynamic> map) {
    final c = CachedFile();
    c.id            = map['id'];
    c.originalName  = map['original_name'];
    c.fileType      = map['file_type'] ?? 'other';
    c.mimeType      = map['mime_type'];
    c.extension     = map['extension'];
    c.sizeBytes     = map['size_bytes'] ?? 0;
    c.uploadStatus  = map['upload_status'] ?? 'pending';
    c.tags          = List<String>.from(map['tags'] ?? []);
    c.isFavorite    = map['is_favorite'] ?? false;
    c.folderId      = map['folder_id'];
    c.createdAt     = map['created_at'];
    c.displayName   = map['display_name'];
    c.fileMetadata  = Map<String, dynamic>.from(map['file_metadata'] ?? {});
    return c;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'original_name': originalName,
    'file_type': fileType,
    'mime_type': mimeType,
    'extension': extension,
    'size_bytes': sizeBytes,
    'upload_status': uploadStatus,
    'tags': tags,
    'is_favorite': isFavorite,
    'folder_id': folderId,
    'created_at': createdAt,
    'display_name': displayName,
    'file_metadata': fileMetadata,
  };
}

@HiveType(typeId: 1)
class CachedFolder extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late String? parentId;
  @HiveField(3) late String path;
  @HiveField(4) late String color;
  @HiveField(5) late String icon;
  @HiveField(6) late int fileCount;
  @HiveField(7) late int childrenCount;
  @HiveField(8) late String createdAt;

  CachedFolder();
}

@HiveType(typeId: 2)
class CachedThumbnail extends HiveObject {
  @HiveField(0) late String fileId;
  @HiveField(1) late List<int> data;    // JPEG bytes
  @HiveField(2) late String cachedAt;

  CachedThumbnail();
}

@HiveType(typeId: 3)
class PendingUpload extends HiveObject {
  @HiveField(0) late String id;          // UUID
  @HiveField(1) late String localPath;
  @HiveField(2) late String fileName;
  @HiveField(3) late String? folderId;
  @HiveField(4) late String createdAt;
  @HiveField(5) late bool encrypted;
  @HiveField(6) late String status;     // pending/uploading/done/failed

  PendingUpload();
}
