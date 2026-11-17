import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lớp bọc shared_preferences: lưu/đọc danh sách object dạng JSON
class LocalStorage {
  LocalStorage._(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorage> init() async =>
      LocalStorage._(await SharedPreferences.getInstance());

  /// Đọc danh sách; trả về null nếu chưa có dữ liệu hoặc dữ liệu hỏng
  List<T>? readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    return _prefs.setString(key, jsonEncode(items.map(toJson).toList()));
  }

  String? readString(String key) => _prefs.getString(key);

  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}
