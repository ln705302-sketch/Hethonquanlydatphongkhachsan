import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/api_client.dart';
import '../data/local_storage.dart';
import '../models/user.dart';

/// Tài khoản: đăng nhập, đăng ký, hồ sơ; danh sách khách hàng và nhân viên
/// (cho trang quản trị). Mọi kiểm tra quyền và dữ liệu do server thực hiện.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._storage) {
    _api.onUnauthorized = _onSessionExpired;
  }

  final ApiClient _api;
  final LocalStorage _storage;
  User? _currentUser;
  List<User> _customers = [];
  List<User> _staff = [];

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isStaff => _currentUser?.isStaff ?? false;
  bool get isManager => _currentUser?.isManager ?? false;
  List<User> get customers => List.unmodifiable(_customers);
  List<User> get staff => List.unmodifiable(_staff);

  /// Khôi phục phiên đăng nhập từ token đã lưu
  Future<void> init() async {
    final token = _storage.readString(StorageKeys.session);
    if (token == null) return;
    _api.token = token;
    try {
      _currentUser = User.fromJson(await _api.get('/auth/me') as Map<String, dynamic>);
    } on ApiException catch (e) {
      // Không kết nối được thì giữ token để thử lại lần sau
      if (e.status != 0) await _clearSession();
    }
    notifyListeners();
  }

  void _onSessionExpired() {
    if (_currentUser == null) return;
    _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    _customers = [];
    _staff = [];
    _api.token = null;
    await _storage.remove(StorageKeys.session);
  }

  Future<void> _startSession(Map<String, dynamic> data) async {
    _api.token = data['token'] as String;
    _currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.writeString(StorageKeys.session, _api.token!);
    notifyListeners();
  }

  User? findById(String? id) {
    if (id == null) return null;
    if (_currentUser?.id == id) return _currentUser;
    return [..._customers, ..._staff].where((u) => u.id == id).firstOrNull;
  }

  /// Nhân viên tải danh sách khách hàng; Quản lý tải thêm danh sách nhân viên
  Future<void> loadUsers() async {
    if (!isStaff) {
      _customers = [];
      _staff = [];
      notifyListeners();
      return;
    }
    try {
      _customers = [
        for (final j in await _api.get('/customers') as List)
          User.fromJson(j as Map<String, dynamic>)
      ];
      _staff = isManager
          ? [
              for (final j in await _api.get('/staff') as List)
                User.fromJson(j as Map<String, dynamic>)
            ]
          : [];
    } on ApiException {
      // Giữ dữ liệu cũ; trang sẽ hiện lỗi khi người dùng thao tác
    }
    notifyListeners();
  }

  /// Đăng nhập. Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> login(String email, String password) => guard(() async {
        await _startSession(await _api.post('/auth/login',
            {'email': email.trim(), 'password': password}) as Map<String, dynamic>);
      });

  /// Đăng ký tài khoản khách hàng mới và đăng nhập luôn
  Future<String?> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) =>
      guard(() async {
        await _startSession(await _api.post('/auth/register', {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
        }) as Map<String, dynamic>);
      });

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  /// Cập nhật hồ sơ của chính mình
  Future<String?> updateProfile({
    required String fullName,
    required String phone,
    required String cccd,
    required String address,
    String? gender,
    DateTime? birthDate,
  }) =>
      guard(() async {
        final data = await _api.put('/me', {
          'fullName': fullName.trim(),
          'phone': phone.trim(),
          'cccd': cccd.trim(),
          'address': address.trim(),
          'gender': gender ?? '',
          'birthDate': birthDate == null ? null : isoDay(birthDate),
        });
        _currentUser = User.fromJson(data as Map<String, dynamic>);
        notifyListeners();
      });

  Future<String?> changePassword(String oldPassword, String newPassword) =>
      guard(() => _api.put('/me/password',
          {'oldPassword': oldPassword, 'newPassword': newPassword}));

  void _upsert(List<User> list, User u) {
    final i = list.indexWhere((x) => x.id == u.id);
    i == -1 ? list.insert(0, u) : list[i] = u;
    if (_currentUser?.id == u.id) _currentUser = u;
  }

  /// Lễ tân thêm / sửa khách hàng. Trả về (khách, null) hoặc (null, lỗi)
  Future<(User?, String?)> saveCustomer({
    String? id,
    required String fullName,
    required String phone,
    required String email,
    required String cccd,
    required String address,
    required String gender,
  }) async {
    final body = {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'cccd': cccd.trim(),
      'address': address.trim(),
      'gender': gender,
    };
    try {
      final data = id == null
          ? await _api.post('/customers', body)
          : await _api.put('/customers/$id', body);
      final user = User.fromJson(data as Map<String, dynamic>);
      _upsert(_customers, user);
      notifyListeners();
      return (user, null);
    } on ApiException catch (e) {
      return (null, e.message);
    }
  }

  /// Quản lý thêm tài khoản nhân viên
  Future<String?> addStaff({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) =>
      guard(() async {
        final data = await _api.post('/staff', {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
          'role': role.name,
        });
        _staff.add(User.fromJson(data as Map<String, dynamic>));
        notifyListeners();
      });

  /// Quản lý sửa thông tin nhân viên
  Future<String?> updateStaff({
    required String id,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  }) =>
      guard(() async {
        final data = await _api.put('/staff/$id', {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'role': role.name,
        });
        _upsert(_staff, User.fromJson(data as Map<String, dynamic>));
        notifyListeners();
      });

  /// Nhân viên đặt mật khẩu mới cho tài khoản khác
  Future<String?> resetPassword(String userId, String newPassword) =>
      guard(() async {
        final data = await _api
            .post('/users/$userId/reset-password', {'password': newPassword});
        final u = User.fromJson(data as Map<String, dynamic>);
        _upsert(u.isStaff ? _staff : _customers, u);
        notifyListeners();
      });

  /// Quản lý khóa / mở khóa tài khoản khách hàng và lễ tân
  Future<String?> toggleLock(String userId) => guard(() async {
        final data = await _api.post('/users/$userId/toggle-lock');
        final u = User.fromJson(data as Map<String, dynamic>);
        _upsert(u.isStaff ? _staff : _customers, u);
        notifyListeners();
      });
}
