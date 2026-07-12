// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedFileAdapter extends TypeAdapter<CachedFile> {
  @override
  final int typeId = 0;

  @override
  CachedFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedFile()
      ..id = fields[0] as String
      ..originalName = fields[1] as String
      ..fileType = fields[2] as String
      ..mimeType = fields[3] as String?
      ..extension = fields[4] as String?
      ..sizeBytes = fields[5] as int
      ..uploadStatus = fields[6] as String
      ..tags = (fields[7] as List).cast<String>()
      ..isFavorite = fields[8] as bool
      ..folderId = fields[9] as String?
      ..createdAt = fields[10] as String
      ..displayName = fields[11] as String?
      ..fileMetadata = (fields[12] as Map).cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, CachedFile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalName)
      ..writeByte(2)
      ..write(obj.fileType)
      ..writeByte(3)
      ..write(obj.mimeType)
      ..writeByte(4)
      ..write(obj.extension)
      ..writeByte(5)
      ..write(obj.sizeBytes)
      ..writeByte(6)
      ..write(obj.uploadStatus)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.isFavorite)
      ..writeByte(9)
      ..write(obj.folderId)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.displayName)
      ..writeByte(12)
      ..write(obj.fileMetadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedFolderAdapter extends TypeAdapter<CachedFolder> {
  @override
  final int typeId = 1;

  @override
  CachedFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedFolder()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..parentId = fields[2] as String?
      ..path = fields[3] as String
      ..color = fields[4] as String
      ..icon = fields[5] as String
      ..fileCount = fields[6] as int
      ..childrenCount = fields[7] as int
      ..createdAt = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, CachedFolder obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.path)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.icon)
      ..writeByte(6)
      ..write(obj.fileCount)
      ..writeByte(7)
      ..write(obj.childrenCount)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedThumbnailAdapter extends TypeAdapter<CachedThumbnail> {
  @override
  final int typeId = 2;

  @override
  CachedThumbnail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedThumbnail()
      ..fileId = fields[0] as String
      ..data = (fields[1] as List).cast<int>()
      ..cachedAt = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, CachedThumbnail obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.fileId)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedThumbnailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PendingUploadAdapter extends TypeAdapter<PendingUpload> {
  @override
  final int typeId = 3;

  @override
  PendingUpload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingUpload()
      ..id = fields[0] as String
      ..localPath = fields[1] as String
      ..fileName = fields[2] as String
      ..folderId = fields[3] as String?
      ..createdAt = fields[4] as String
      ..encrypted = fields[5] as bool
      ..status = fields[6] as String;
  }

  @override
  void write(BinaryWriter writer, PendingUpload obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.localPath)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.folderId)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.encrypted)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingUploadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
