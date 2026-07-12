
class FileModel {
  final String id;
  final String originalName;
  final String? displayName;
  final String fileType;
  final String? mimeType;
  final String? extension;
  final int sizeBytes;
  final bool isChunked;
  final int totalChunks;
  final String uploadStatus;
  final List<String> tags;
  final bool isFavorite;
  final Map<String, dynamic> fileMetadata;
  final String? folderId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FileModel({
    required this.id,
    required this.originalName,
    this.displayName,
    required this.fileType,
    this.mimeType,
    this.extension,
    required this.sizeBytes,
    required this.isChunked,
    required this.totalChunks,
    required this.uploadStatus,
    required this.tags,
    required this.isFavorite,
    required this.fileMetadata,
    this.folderId,
    required this.createdAt,
    this.updatedAt,
  });

  String get name => displayName ?? originalName;

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
    id:            json['id'],
    originalName:  json['original_name'],
    displayName:   json['display_name'],
    fileType:      json['file_type'] ?? 'other',
    mimeType:      json['mime_type'],
    extension:     json['extension'],
    sizeBytes:     json['size_bytes'] ?? 0,
    isChunked:     json['is_chunked'] ?? false,
    totalChunks:   json['total_chunks'] ?? 1,
    uploadStatus:  json['upload_status'] ?? 'pending',
    tags:          List<String>.from(json['tags'] ?? []),
    isFavorite:    json['is_favorite'] ?? false,
    fileMetadata:  Map<String, dynamic>.from(json['file_metadata'] ?? {}),
    folderId:      json['folder_id'],
    createdAt:     DateTime.parse(json['created_at']),
    updatedAt:     json['updated_at'] != null
                    ? DateTime.parse(json['updated_at'])
                    : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'original_name': originalName,
    'display_name': displayName,
    'file_type': fileType,
    'mime_type': mimeType,
    'extension': extension,
    'size_bytes': sizeBytes,
    'is_chunked': isChunked,
    'total_chunks': totalChunks,
    'upload_status': uploadStatus,
    'tags': tags,
    'is_favorite': isFavorite,
    'file_metadata': fileMetadata,
    'folder_id': folderId,
    'created_at': createdAt.toIso8601String(),
  };

  FileModel copyWith({
    String? displayName,
    List<String>? tags,
    bool? isFavorite,
    String? folderId,
  }) => FileModel(
    id: id,
    originalName: originalName,
    displayName: displayName ?? this.displayName,
    fileType: fileType,
    mimeType: mimeType,
    extension: extension,
    sizeBytes: sizeBytes,
    isChunked: isChunked,
    totalChunks: totalChunks,
    uploadStatus: uploadStatus,
    tags: tags ?? this.tags,
    isFavorite: isFavorite ?? this.isFavorite,
    fileMetadata: fileMetadata,
    folderId: folderId ?? this.folderId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
