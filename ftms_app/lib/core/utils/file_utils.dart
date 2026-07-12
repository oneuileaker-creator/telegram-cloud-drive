
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FileUtils {

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'image':    return AppColors.imageColor;
      case 'video':    return AppColors.videoColor;
      case 'audio':    return AppColors.audioColor;
      case 'document': return AppColors.documentColor;
      case 'code':     return AppColors.codeColor;
      case 'archive':  return AppColors.archiveColor;
      case 'font':     return AppColors.fontColor;
      default:         return AppColors.otherColor;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'image':    return Icons.image_rounded;
      case 'video':    return Icons.videocam_rounded;
      case 'audio':    return Icons.music_note_rounded;
      case 'document': return Icons.description_rounded;
      case 'code':     return Icons.code_rounded;
      case 'archive':  return Icons.folder_zip_rounded;
      case 'font':     return Icons.font_download_rounded;
      default:         return Icons.insert_drive_file_rounded;
    }
  }

  static String getCategoryLabel(String category) {
    switch (category) {
      case 'image':    return 'Photos';
      case 'video':    return 'Videos';
      case 'audio':    return 'Music';
      case 'document': return 'Documents';
      case 'code':     return 'Code';
      case 'archive':  return 'Archives';
      default:         return 'Other';
    }
  }

  static String formatDuration(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }
}
