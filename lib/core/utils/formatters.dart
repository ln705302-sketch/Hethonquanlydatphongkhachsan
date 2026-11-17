import 'package:intl/intl.dart';

/// Các hàm định dạng tiền, ngày, chuỗi dùng chung
class Fmt {
  Fmt._();

  static final _money = NumberFormat('#,##0', 'en_US');
  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateShort = DateFormat('dd/MM');
  static final _dateTime = DateFormat('HH:mm dd/MM/yyyy');
  static final _iso = DateFormat('yyyy-MM-dd');
  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  /// 1250000 -> "1.250.000 ₫"
  static String vnd(num value) =>
      '${_money.format(value.round()).replaceAll(',', '.')} ₫';

  static String date(DateTime d) => _date.format(d);
  static String dateShort(DateTime d) => _dateShort.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  /// "T7, 01/11"
  static String dayLabel(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_dateShort.format(d)}';

  /// Định dạng ngày dùng trên URL: yyyy-MM-dd
  static String isoDate(DateTime d) => _iso.format(d);

  static DateTime? parseIsoDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime get today => dateOnly(DateTime.now());

  /// Số đêm giữa ngày nhận và trả phòng
  static int nights(DateTime checkIn, DateTime checkOut) =>
      dateOnly(checkOut).difference(dateOnly(checkIn)).inDays;

  /// Nhãn chữ cho điểm đánh giá thang 10
  static String ratingLabel(double score) {
    if (score >= 9) return 'Xuất sắc';
    if (score >= 8) return 'Tuyệt vời';
    if (score >= 7) return 'Rất tốt';
    if (score >= 6) return 'Tốt';
    return 'Hài lòng';
  }

  /// Mã hiển thị từ id: id số (MaDatPhong, MaHoaDon) -> đệm 6 chữ số,
  /// id dạng chuỗi -> 8 ký tự đầu
  static String _code(String prefix, String id) {
    if (RegExp(r'^\d+$').hasMatch(id)) return '$prefix${id.padLeft(6, '0')}';
    final s = id.replaceAll('-', '').toUpperCase();
    return '$prefix${s.length > 8 ? s.substring(0, 8) : s}';
  }

  /// Mã đặt phòng hiển thị cho khách: SRH000012
  static String bookingCode(String id) => _code('SRH', id);

  /// Mã hóa đơn hiển thị: HD000003
  static String invoiceCode(String id) => _code('HD', id);

  /// Số lượng dịch vụ: 2 -> "2", 1.5 -> "1,5"
  static String quantity(double q) =>
      q == q.roundToDouble() ? '${q.round()}' : '$q'.replaceAll('.', ',');

  static String count(int n) => _money.format(n).replaceAll(',', '.');

  static const _accents = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };

  /// Bỏ dấu tiếng Việt + chữ thường, phục vụ tìm kiếm ("Hà Nội" -> "ha noi")
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      var replaced = ch;
      for (final entry in _accents.entries) {
        if (entry.value.contains(ch)) {
          replaced = entry.key;
          break;
        }
      }
      buffer.write(replaced);
    }
    return buffer.toString().replaceAll('.', '').trim();
  }
}
