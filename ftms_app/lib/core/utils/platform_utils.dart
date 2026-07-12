
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  static bool get isMobile =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static double get sidebarWidth => isDesktop ? 260 : 0;
  static int get photoGridColumns => isDesktop ? 5 : 3;
  static int get fileGridColumns  => isDesktop ? 4 : 3;
  static int get folderGridColumns=> isDesktop ? 4 : 2;
}
