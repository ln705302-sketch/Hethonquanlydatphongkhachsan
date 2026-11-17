enum UserRole {
  customer('Khách hàng'),
  receptionist('Lễ tân'),
  manager('Quản lý');

  const UserRole(this.label);
  final String label;
}

/// Tài khoản: khách hàng (bảng KhachHang, id dạng `KH<n>`) hoặc nhân viên
/// (bảng NhanVien, id dạng `NV<n>`). Mật khẩu chỉ nằm trên server (bcrypt),
/// client chỉ biết tài khoản đã có mật khẩu đăng nhập hay chưa.
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.hasAccount = true,
    this.role = UserRole.customer,
    this.username = '',
    this.cccd = '',
    this.address = '',
    this.gender = '',
    this.birthDate,
    this.isLocked = false,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String email; // Có thể rỗng với khách do lễ tân tạo tại quầy
  final String phone;
  final bool hasAccount; // false = khách tạo tại quầy, chưa đăng nhập online được
  final UserRole role;
  final String username; // Tên đăng nhập của nhân viên
  final String cccd;
  final String address;
  final String gender;
  final DateTime? birthDate;
  final bool isLocked;
  final DateTime createdAt;

  bool get isManager => role == UserRole.manager;
  bool get isStaff => role != UserRole.customer;

  /// Chữ cái đầu tên hiển thị trên avatar
  String get initial =>
      fullName.trim().isEmpty ? '?' : fullName.trim().split(' ').last[0].toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        hasAccount: json['hasAccount'] as bool? ?? true,
        role: UserRole.values.byName(json['role'] as String? ?? 'customer'),
        username: json['username'] as String? ?? '',
        cccd: json['cccd'] as String? ?? '',
        address: json['address'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
        birthDate: json['birthDate'] == null
            ? null
            : DateTime.parse(json['birthDate'] as String),
        isLocked: json['isLocked'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'hasAccount': hasAccount,
        'role': role.name,
        'username': username,
        'cccd': cccd,
        'address': address,
        'gender': gender,
        'birthDate': birthDate?.toIso8601String(),
        'isLocked': isLocked,
        'createdAt': createdAt.toIso8601String(),
      };
}
