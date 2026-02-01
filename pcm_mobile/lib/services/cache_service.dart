import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'pcm_cache';
  static const String _keyCourts = 'courts';
  static const String _keyProfile = 'profile';
  static const String _keyNotifications = 'notifications';

  static Box? _box;

  /// Khởi tạo Hive (gọi ở main.dart)
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    debugPrint('Hive initialized & box opened');
  }

  /// Cache danh sách sân
  static Future<void> cacheCourts(List<dynamic> courts) async {
    if (_box == null) return;
    try {
      // Convert list objects to json string if needed, or just store list of maps
      // Assuming courts is List<Map<String, dynamic>> or List<CourtModel>
      // For simplicity, we'll store as JSON string
      final jsonString = jsonEncode(courts);
      await _box!.put(_keyCourts, jsonString);
      debugPrint('Cached ${courts.length} courts');
    } catch (e) {
      debugPrint('Error caching courts: $e');
    }
  }

  /// Lấy danh sách sân từ cache
  static List<dynamic>? getCachedCourts() {
    if (_box == null) return null;
    final jsonString = _box!.get(_keyCourts);
    if (jsonString != null && jsonString is String) {
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        debugPrint('Error decoding cached courts: $e');
      }
    }
    return null;
  }

  /// Cache thông tin user
  static Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    if (_box == null) return;
    try {
      final jsonString = jsonEncode(profile);
      await _box!.put(_keyProfile, jsonString);
      debugPrint('Cached user profile');
    } catch (e) {
      debugPrint('Error caching profile: $e');
    }
  }

  /// Lấy thông tin user từ cache
  static Map<String, dynamic>? getCachedUserProfile() {
    if (_box == null) return null;
    final jsonString = _box!.get(_keyProfile);
    if (jsonString != null && jsonString is String) {
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        debugPrint('Error decoding cached profile: $e');
      }
    }
    return null;
  }

  /// Xóa cache (khi logout)
  static Future<void> clear() async {
    if (_box != null) {
      await _box!.clear();
    }
  }
}
