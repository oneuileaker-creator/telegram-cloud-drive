import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  static const String _boxName = 'ftms_cache';

  // Saves raw JSON (Map or List) into cache
  static void set(String key, dynamic val) {
    if (Hive.isBoxOpen(_boxName)) {
      Hive.box(_boxName).put(key, val);
    }
  }

  // Gets raw JSON from cache
  static dynamic get(String key) {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName).get(key);
    }
    return null;
  }

  // Helper to clear cache on logout
  static void clear() {
    if (Hive.isBoxOpen(_boxName)) {
      Hive.box(_boxName).clear();
    }
  }
}
