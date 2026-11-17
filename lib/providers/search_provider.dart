import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/utils/formatters.dart';

/// Điều kiện tìm phòng trống: ngày nhận, ngày trả, số khách
class SearchProvider extends ChangeNotifier {
  DateTime checkIn = Fmt.today.add(const Duration(days: 1));
  DateTime checkOut = Fmt.today.add(const Duration(days: 2));
  int guests = 2;

  int get nights => Fmt.nights(checkIn, checkOut);

  /// Cập nhật điều kiện tìm kiếm
  void updateCriteria({DateTime? checkIn, DateTime? checkOut, int? guests}) {
    this.checkIn = checkIn ?? this.checkIn;
    this.checkOut = checkOut ?? this.checkOut;
    this.guests = guests ?? this.guests;
    _normalizeDates();
    notifyListeners();
  }

  /// Đọc điều kiện từ query URL (không notify vì gọi trong initState)
  void applyQuery(Map<String, String> q) {
    checkIn = Fmt.parseIsoDate(q['checkIn']) ?? checkIn;
    checkOut = Fmt.parseIsoDate(q['checkOut']) ?? checkOut;
    guests = (int.tryParse(q['guests'] ?? '') ?? guests)
        .clamp(1, AppConstants.maxGuests);
    _normalizeDates();
  }

  /// Không cho ngày quá khứ, ngày trả luôn sau ngày nhận
  void _normalizeDates() {
    final today = Fmt.today;
    checkIn = Fmt.dateOnly(checkIn);
    checkOut = Fmt.dateOnly(checkOut);
    if (checkIn.isBefore(today)) checkIn = today;
    if (!checkOut.isAfter(checkIn)) {
      checkOut = checkIn.add(const Duration(days: 1));
    }
  }

  Map<String, String> get stayQuery => {
        'checkIn': Fmt.isoDate(checkIn),
        'checkOut': Fmt.isoDate(checkOut),
        'guests': '$guests',
      };

  /// URL trang phòng theo điều kiện hiện tại
  String get roomsLocation =>
      Uri(path: '/rooms', queryParameters: stayQuery).toString();
}
