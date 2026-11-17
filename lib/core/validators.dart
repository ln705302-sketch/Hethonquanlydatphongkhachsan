/// Các hàm validate dùng cho TextFormField
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _phoneRegex = RegExp(r'^0\d{9}$');

  static String? required(String? v, [String field = 'Trường này']) {
    if (v == null || v.trim().isEmpty) return '$field không được để trống';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    if (!_emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  /// CCCD không bắt buộc, nếu có phải gồm 12 số
  static String? cccd(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!RegExp(r'^\d{12}$').hasMatch(v.trim())) return 'CCCD gồm 12 chữ số';
    return null;
  }

  /// SĐT Việt Nam: 10 số, bắt đầu bằng 0
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!_phoneRegex.hasMatch(v.trim())) {
      return 'Số điện thoại gồm 10 số, bắt đầu bằng 0';
    }
    return null;
  }

  static String? Function(String?) confirm(String Function() original) {
    return (v) {
      if (v == null || v.isEmpty) return 'Vui lòng nhập lại mật khẩu';
      if (v != original()) return 'Mật khẩu nhập lại không khớp';
      return null;
    };
  }

  /// Số nguyên trong khoảng [min, max]
  static String? Function(String?) intRange(int min, int max) {
    return (v) {
      final n = int.tryParse(v?.trim() ?? '');
      if (n == null) return 'Vui lòng nhập số nguyên';
      if (n < min || n > max) return 'Giá trị từ $min đến $max';
      return null;
    };
  }

  /// Số thực trong khoảng [min, max]
  static String? Function(String?) numRange(double min, double max) {
    return (v) {
      final n = double.tryParse(v?.trim().replaceAll(',', '.') ?? '');
      if (n == null) return 'Vui lòng nhập số';
      if (n < min || n > max) return 'Giá trị từ $min đến $max';
      return null;
    };
  }
}
