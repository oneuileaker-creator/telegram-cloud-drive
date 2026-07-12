import 'package:photo_manager/photo_manager.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/cache/cache_service.dart';
import 'dart:io';

class BackupService {
  static const _backupBox    = 'backup_state';
  static const _backedUpKey  = 'backed_up_ids';
  static const _enabledKey   = 'backup_enabled';
  static const _wifiOnlyKey  = 'wifi_only';
  static const _lastRunKey   = 'last_backup_run';

  final _dio = DioClient.instance.dio;

  // ── Settings ──────────────────────────────────────────────

  static Future<void> initBox() async {
    await Hive.openBox(_backupBox);
  }

  bool get isEnabled =>
    Hive.box(_backupBox).get(_enabledKey, defaultValue: false);

  bool get wifiOnly =>
    Hive.box(_backupBox).get(_wifiOnlyKey, defaultValue: true);

  Future<void> setEnabled(bool value) async {
    await Hive.box(_backupBox).put(_enabledKey, value);
    if (value) await _requestPermissions();
  }

  Future<void> setWifiOnly(bool value) async {
    await Hive.box(_backupBox).put(_wifiOnlyKey, value);
  }

  Set<String> get _backedUpIds {
    final list = Hive.box(_backupBox)
      .get(_backedUpKey, defaultValue: <String>[]);
    return Set<String>.from(list);
  }

  Future<void> _markAsBackedUp(String assetId) async {
    final ids = _backedUpIds..add(assetId);
    await Hive.box(_backupBox).put(_backedUpKey, ids.toList());
  }

  // ── Permissions ───────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  // ── Backup Run ────────────────────────────────────────────

  Future<BackupResult> runBackup({
    void Function(int done, int total)? onProgress,
  }) async {
    if (!isEnabled) {
      return BackupResult(skipped: 0, uploaded: 0, failed: 0);
    }
    if (!ConnectivityService.instance.isOnline) {
      return BackupResult(skipped: 0, uploaded: 0, failed: 0, offline: true);
    }

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      return BackupResult(skipped: 0, uploaded: 0, failed: 0, noPermission: true);
    }

    // Get new assets since last backup
    final newAssets = await _getNewAssets();
    int uploaded = 0;
    int failed   = 0;
    int total    = newAssets.length;

    for (int i = 0; i < newAssets.length; i++) {
      final asset = newAssets[i];
      onProgress?.call(i + 1, total);

      try {
        final file = await asset.originFile;
        if (file == null) continue;

        await _uploadAsset(asset, file);
        await _markAsBackedUp(asset.id);
        uploaded++;
      } catch (_) {
        failed++;
      }
    }

    await Hive.box(_backupBox).put(
      _lastRunKey,
      DateTime.now().toIso8601String(),
    );

    return BackupResult(
      skipped: 0,
      uploaded: uploaded,
      failed: failed,
    );
  }

  Future<List<AssetEntity>> _getNewAssets() async {
    final backedUp = _backedUpIds;

    // Get recent photos and videos from device
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      ),
    );

    if (albums.isEmpty) return [];

    final recentAssets = await albums.first.getAssetListRange(
      start: 0,
      end: 500,
    );

    // Filter out already backed up
    return recentAssets
      .where((a) => !backedUp.contains(a.id))
      .toList();
  }

  Future<void> _uploadAsset(AssetEntity asset, File file) async {
    final mimeType = asset.mimeType ?? 'application/octet-stream';
    final title    = asset.title ?? '${asset.id}.jpg';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: title,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    await _dio.post(ApiConstants.filesUpload, data: formData);
  }

  // ── Stats ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBackupStats() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return {'error': 'No permission'};

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    int totalDevice  = 0;
    for (final album in albums) {
      totalDevice += await album.assetCountAsync;
    }

    return {
      'total_device': totalDevice,
      'backed_up': _backedUpIds.length,
      'pending': totalDevice - _backedUpIds.length,
      'last_run': Hive.box(_backupBox).get(_lastRunKey),
      'enabled': isEnabled,
      'wifi_only': wifiOnly,
    };
  }
}

class BackupResult {
  final int skipped;
  final int uploaded;
  final int failed;
  final bool offline;
  final bool noPermission;

  BackupResult({
    required this.skipped,
    required this.uploaded,
    required this.failed,
    this.offline = false,
    this.noPermission = false,
  });
}
