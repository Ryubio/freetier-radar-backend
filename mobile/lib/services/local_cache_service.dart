import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class LocalCacheService {
  static const String _servicesBoxName = 'services_cache';
  static const String _alertsBoxName = 'alerts_cache';
  static const String _metaBoxName = 'cache_meta';

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
    await Hive.openBox<String>(_servicesBoxName);
    await Hive.openBox<String>(_alertsBoxName);
    await Hive.openBox<int>(_metaBoxName);
  }

  Future<void> cacheServices(String cacheKey, Map<String, dynamic> data) async {
    final box = Hive.box<String>(_servicesBoxName);
    final metaBox = Hive.box<int>(_metaBoxName);
    await box.put(cacheKey, jsonEncode(data));
    await metaBox.put(cacheKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>?> getCachedServices(String cacheKey) async {
    final box = Hive.box<String>(_servicesBoxName);
    final data = box.get(cacheKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheAlerts(List<Map<String, dynamic>> data) async {
    final box = Hive.box<String>(_alertsBoxName);
    final metaBox = Hive.box<int>(_metaBoxName);
    await box.put('alerts', jsonEncode(data));
    await metaBox.put('alerts', DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>?> getCachedAlerts() async {
    final box = Hive.box<String>(_alertsBoxName);
    final data = box.get('alerts');
    if (data == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  bool isCacheStale(String cacheKey, {Duration maxAge = const Duration(minutes: 30)}) {
    final metaBox = Hive.box<int>(_metaBoxName);
    final timestamp = metaBox.get(cacheKey);
    if (timestamp == null) return true;
    
    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cachedTime) > maxAge;
  }

  Future<void> clearAll() async {
    await Hive.box<String>(_servicesBoxName).clear();
    await Hive.box<String>(_alertsBoxName).clear();
    await Hive.box<int>(_metaBoxName).clear();
  }

  String getCacheSizeEstimate() {
    int totalBytes = 0;
    
    final servicesBox = Hive.box<String>(_servicesBoxName);
    for (var key in servicesBox.keys) {
      final val = servicesBox.get(key);
      if (val != null) {
        totalBytes += val.length;
      }
    }
    
    final alertsBox = Hive.box<String>(_alertsBoxName);
    final alertsVal = alertsBox.get('alerts');
    if (alertsVal != null) {
      totalBytes += alertsVal.length;
    }

    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
