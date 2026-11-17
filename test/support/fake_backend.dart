import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sunrise_hotel/models/booking.dart';
import 'package:sunrise_hotel/models/promotion.dart';
import 'package:sunrise_hotel/models/user.dart';

import 'mock_data.dart';

/// Backend giả trong bộ nhớ cho widget test: trả dữ liệu mẫu theo đúng định
/// dạng JSON của server thật, phân quyền theo token. Chỉ hỗ trợ các thao tác
/// mà smoke test cần (xem trang, đăng nhập, lưu mã ưu đãi).
class FakeBackend {
  FakeBackend();

  static const _passwords = {
    'admin@sunrisehotel.local': 'admin123',
    'letan01@sunrisehotel.local': 'letan123',
    'an@example.com': 'user123',
    'binh@example.com': 'binh123',
  };

  final _users = MockData.users();
  final _bookings = MockData.bookings();
  final _usages = MockData.serviceUsages();
  final _invoices = MockData.invoices();
  final _saved = <String, Set<String>>{};

  late final http.Client client = MockClient(_handle);

  User? _userOf(http.Request req) {
    final auth = req.headers['Authorization'] ?? '';
    if (!auth.startsWith('Bearer tok-')) return null;
    final id = auth.substring('Bearer tok-'.length);
    return _users.where((u) => u.id == id).firstOrNull;
  }

  http.Response _json(Object? body, [int status = 200]) => http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  http.Response _error(String message, int status) =>
      _json({'error': message}, status);

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api', '');
    final me = _userOf(req);
    final staff = me?.isStaff ?? false;
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body);

    if (req.method == 'GET') {
      switch (path) {
        case '/hotel':
          return _json(MockData.hotel().toJson());
        case '/room-types':
          return _json([for (final t in MockData.roomTypes()) t.toJson()]);
        case '/rooms':
          return _json([for (final r in MockData.rooms()) r.toJson()]);
        case '/services':
          return _json([for (final s in MockData.services()) s.toJson()]);
        case '/reviews':
          return _json([for (final r in MockData.reviews()) r.toJson()]);
        case '/promotions':
          return _json([for (final p in kPromotions) p.toJson()]);
        case '/availability':
          return _json([
            for (final t in MockData.roomTypes()) {'typeId': t.id, 'available': 1}
          ]);
        case '/auth/me':
          return me == null ? _error('Vui lòng đăng nhập', 401) : _json(me.toJson());
        case '/bookings':
          return _json([
            for (final b in _bookings)
              if (staff || b.userId == me?.id) b.toJson()
          ]);
        case '/usages':
          final mine = {
            for (final b in _bookings)
              if (staff || b.userId == me?.id) b.id
          };
          return _json([
            for (final u in _usages)
              if (mine.contains(u.bookingId)) u.toJson()
          ]);
        case '/invoices':
          final mine = {
            for (final b in _bookings)
              if (staff || b.userId == me?.id) b.id
          };
          return _json([
            for (final i in _invoices)
              if (mine.contains(i.bookingId)) i.toJson()
          ]);
        case '/customers':
          if (!staff) return _error('Chỉ nhân viên', 403);
          return _json([for (final u in _users) if (!u.isStaff) u.toJson()]);
        case '/staff':
          if (!(me?.isManager ?? false)) return _error('Chỉ Quản lý', 403);
          return _json([for (final u in _users) if (u.isStaff) u.toJson()]);
        case '/me/saved-promos':
          return _json([...?_saved[me?.id]]);
      }
    }

    if (req.method == 'POST' && path == '/auth/login') {
      final email = (body['email'] as String).toLowerCase();
      final user = _users.where((u) => u.email == email).firstOrNull;
      if (user == null || _passwords[email] != body['password']) {
        return _error('Email hoặc mật khẩu không đúng', 401);
      }
      return _json({'token': 'tok-${user.id}', 'user': user.toJson()});
    }
    if (req.method == 'POST' && path == '/me/saved-promos') {
      _saved.putIfAbsent(me!.id, () => {}).add(body['code'] as String);
      return _json({'ok': true}, 201);
    }
    if (req.method == 'DELETE' && path.startsWith('/me/saved-promos/')) {
      _saved[me?.id]?.remove(path.split('/').last);
      return _json({'ok': true});
    }
    return _error('Fake backend chưa hỗ trợ ${req.method} $path', 404);
  }

  /// Đơn mẫu theo id (để test mở dialog)
  Booking booking(String id) => _bookings.firstWhere((b) => b.id == id);
}
