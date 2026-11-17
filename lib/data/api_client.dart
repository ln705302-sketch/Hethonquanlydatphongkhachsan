import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Địa chỉ API, đổi khi build: --dart-define=API_URL=https://.../api
const kApiUrl =
    String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080/api');

/// Lỗi trả về từ server ({ "error": "..." }) hoặc lỗi mạng
class ApiException implements Exception {
  const ApiException(this.message, [this.status = 0]);
  final String message;
  final int status; // 0 = không kết nối được máy chủ

  @override
  String toString() => message;
}

/// Gọi REST API của server Sunrise Hotel, tự gắn token đăng nhập (JWT)
class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = kApiUrl})
      : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;
  String? token;

  /// Gọi khi server báo phiên đăng nhập không còn hợp lệ (401)
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 20);

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final http.Response res;
    try {
      res = await http.Response.fromStream(
          await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu, vui lòng thử lại');
    } catch (_) {
      throw const ApiException(
          'Không kết nối được máy chủ. Hãy kiểm tra server đã chạy chưa');
    }
    final text = utf8.decode(res.bodyBytes);
    final data = text.isEmpty ? null : jsonDecode(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : 'Lỗi máy chủ (${res.statusCode})';
    if (res.statusCode == 401 && token != null && !path.startsWith('/auth/login')) {
      onUnauthorized?.call();
    }
    throw ApiException(message, res.statusCode);
  }
}

/// Chạy [action], trả về thông báo lỗi (null nếu thành công)
Future<String?> guard(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } on ApiException catch (e) {
    return e.message;
  }
}

/// 'yyyy-MM-dd' gửi lên server
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
