
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

// Add to pubspec.yaml:
// window_manager: ^0.3.8

Future<void> setupWindowsWindow() async {
  if (!Platform.isWindows) return;

  // Uncomment when window_manager is added:
  // await windowManager.ensureInitialized();
  // WindowOptions windowOptions = const WindowOptions(
  //   size: Size(1200, 800),
  //   minimumSize: Size(900, 600),
  //   center: true,
  //   title: 'FTMS - File Type Management System',
  //   titleBarStyle: TitleBarStyle.hidden,
  // );
  // await windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   await windowManager.show();
  //   await windowManager.focus();
  // });
}
