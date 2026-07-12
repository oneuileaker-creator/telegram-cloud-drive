
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

// For Windows drag & drop support add to pubspec.yaml:
// desktop_drop: ^0.4.4

class WindowsDropZone extends StatefulWidget {
  final Widget child;
  final void Function(List<String> paths) onFilesDropped;

  const WindowsDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
  });

  @override
  State<WindowsDropZone> createState() => _WindowsDropZoneState();
}

class _WindowsDropZoneState extends State<WindowsDropZone> {
  bool _dragging = false;

  bool get _isDesktop =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return widget.child;

    // Use desktop_drop package when on Windows
    // For now returning child with visual overlay
    return Stack(
      children: [
        widget.child,
        if (_dragging)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_rounded,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Drop files here',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Release to upload',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
