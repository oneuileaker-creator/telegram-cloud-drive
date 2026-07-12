
class UserModel {
  final String id;
  final String email;
  final String username;
  final bool isTelegramConnected;
  final int storageUsedBytes;
  final int totalFiles;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.isTelegramConnected,
    required this.storageUsedBytes,
    required this.totalFiles,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:                   json['id'],
    email:                json['email'],
    username:             json['username'],
    isTelegramConnected:  json['is_telegram_connected'] ?? false,
    storageUsedBytes:     json['storage_used_bytes'] ?? 0,
    totalFiles:           json['total_files'] ?? 0,
    createdAt:            DateTime.parse(json['created_at']),
  );
}
