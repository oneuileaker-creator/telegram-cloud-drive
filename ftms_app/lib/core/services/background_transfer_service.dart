import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';

class BackgroundTransferService {
  static final BackgroundTransferService _instance = BackgroundTransferService._internal();
  factory BackgroundTransferService() => _instance;
  BackgroundTransferService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  int _activeTransfers = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(settings: initializationSettings);

    // 2. Initialize Flutter Background
    if (Platform.isAndroid) {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "FTMS Storage Active Transfers",
        notificationText: "Running uploads and downloads in background...",
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
      );
      await FlutterBackground.initialize(androidConfig: androidConfig);
    }

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.storage.request();
    }
  }

  Future<void> startTransfer() async {
    await initialize();
    _activeTransfers++;
    if (_activeTransfers == 1 && Platform.isAndroid) {
      await requestPermissions();
      await FlutterBackground.enableBackgroundExecution();
    }
  }

  Future<void> stopTransfer() async {
    _activeTransfers = (_activeTransfers - 1).clamp(0, 999999);
    if (_activeTransfers == 0 && Platform.isAndroid) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }

  Future<String?> getDownloadDirectoryPath() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory.path;
      }
      final extDir = await getExternalStorageDirectory();
      return extDir?.path;
    } else {
      final directory = await getDownloadsDirectory();
      return directory?.path;
    }
  }

  Future<void> downloadFile({
    required String fileId,
    required String fileName,
    required BuildContext context,
  }) async {
    final notificationId = fileId.hashCode;
    await startTransfer();

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception("Storage permission denied");
        }
      }

      final baseDir = await getDownloadDirectoryPath();
      if (baseDir == null) {
        throw Exception("Could not locate download directory");
      }

      String savePath = '$baseDir/$fileName';
      int count = 1;
      final String nameWithoutExtension = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      final String extension = fileName.contains('.')
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '';

      while (await File(savePath).exists()) {
        savePath = '$baseDir/${nameWithoutExtension}_$count$extension';
        count++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting download: $fileName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await DioClient.instance.dio.download(
        '${ApiConstants.filesDownload}/$fileId',
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            showProgressNotification(
              id: notificationId,
              fileName: fileName,
              progress: received / total,
              isUpload: false,
            );
          }
        },
      );

      await showProgressNotification(
        id: notificationId,
        fileName: fileName,
        progress: 1.0,
        isUpload: false,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: $fileName'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      await showFailedNotification(
        id: notificationId,
        fileName: fileName,
        error: e.toString(),
        isUpload: false,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      await stopTransfer();
    }
  }

  Future<void> showProgressNotification({
    required int id,
    required String fileName,
    required double progress,
    required bool isUpload,
  }) async {
    if (!_isInitialized) await initialize();

    final int progressPct = (progress * 100).toInt().clamp(0, 100);
    final String typeStr = isUpload ? "Uploading" : "Downloading";

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'file_transfer_channel',
      'File Transfers',
      channelDescription: 'Progress of active file uploads and downloads',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progressPct,
      ongoing: progressPct < 100,
    );

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    if (progressPct >= 100) {
      await _notificationsPlugin.show(
        id: id,
        title: "$typeStr Complete",
        body: fileName,
        notificationDetails: platformDetails,
      );
      Future.delayed(const Duration(seconds: 3), () {
        _notificationsPlugin.cancel(id: id);
      });
    } else {
      await _notificationsPlugin.show(
        id: id,
        title: "$typeStr $progressPct% - $fileName",
        body: "Transferring...",
        notificationDetails: platformDetails,
      );
    }
  }

  Future<void> showFailedNotification({
    required int id,
    required String fileName,
    required String error,
    required bool isUpload,
  }) async {
    if (!_isInitialized) await initialize();

    final String typeStr = isUpload ? "Upload" : "Download";

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'file_transfer_channel',
      'File Transfers',
      channelDescription: 'Progress of active file uploads and downloads',
      importance: Importance.high,
      priority: Priority.high,
    );

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: id,
      title: "$typeStr Failed",
      body: "$fileName: $error",
      notificationDetails: platformDetails,
    );
  }
}
