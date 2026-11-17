import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/api_client.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/promotion.dart';
import '../models/room.dart';
import '../models/room_type.dart';
import '../models/service.dart';
import '../models/user.dart';
import 'hotel_provider.dart';

/// Chi tiết giá lúc đặt phòng
class PriceBreakdown {
  const PriceBreakdown(this.subtotal, this.discount);
  final double subtotal;
  final double discount;
  double get total => subtotal - discount;
}

/// Bảng kê tiền khi trả phòng
class Bill {
  const Bill({
    required this.nights,
    required this.roomCharge,
    required this.serviceCharge,
    required this.discount,
  });

  final int nights;
  final double roomCharge;
  final double serviceCharge;
  final double discount;
  double get total => roomCharge + serviceCharge - discount;
}

enum RevenuePeriod {
  day('Theo ngày'),
  month('Theo tháng'),
  year('Theo năm');

  const RevenuePeriod(this.label);
  final String label;
}

/// Một dòng báo cáo doanh thu
class RevenueRow {
  RevenueRow(this.label);
  final String label;
  int invoices = 0;
  double roomRevenue = 0;
  double serviceRevenue = 0;
  double total = 0;
}

/// Vòng đời đơn đặt phòng: đặt, hủy, nhận phòng, dịch vụ, trả phòng, hóa đơn.
/// Server quyết định mọi nghiệp vụ (transaction + khóa dòng trên Oracle);
/// client giữ bản sao để hiển thị và tính trước bảng kê / báo cáo.
/// Khách chỉ nhận được đơn của mình, nhân viên nhận tất cả.
class BookingProvider extends ChangeNotifier {
  BookingProvider(this._api, this._hotels);

  final ApiClient _api;
  final HotelProvider _hotels;
  List<Booking> _bookings = [];
  List<ServiceUsage> _usages = [];
  List<Invoice> _invoices = [];

  /// Số phòng trống theo khoảng ngày: 'yyyy-MM-dd|yyyy-MM-dd' -> {typeId: số}
  final Map<String, Map<String, int>> _availability = {};
  final Set<String> _loadingAvailability = {};

  /// Tất cả đơn, mới nhất trước
  List<Booking> get bookings =>
      [..._bookings]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Tất cả hóa đơn, mới nhất trước
  List<Invoice> get invoices =>
      [..._invoices]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) f) =>
      [for (final e in data as List) f(e as Map<String, dynamic>)];

  /// Tải đơn, dịch vụ đã dùng, hóa đơn của người đang đăng nhập
  Future<void> load({required bool loggedIn}) async {
    _availability.clear();
    if (!loggedIn) {
      _bookings = [];
      _usages = [];
      _invoices = [];
      notifyListeners();
      return;
    }
    try {
      final r = await Future.wait(
          [_api.get('/bookings'), _api.get('/usages'), _api.get('/invoices')]);
      _bookings = _list(r[0], Booking.fromJson);
      _usages = _list(r[1], ServiceUsage.fromJson);
      _invoices = _list(r[2], Invoice.fromJson);
    } on ApiException {
      // Giữ dữ liệu cũ
    }
    notifyListeners();
  }

  void _upsertBooking(Booking b) {
    final i = _bookings.indexWhere((x) => x.id == b.id);
    i == -1 ? _bookings.add(b) : _bookings[i] = b;
  }

  Booking? bookingById(String id) =>
      _bookings.where((b) => b.id == id).firstOrNull;

  List<Booking> bookingsOfUser(String userId) =>
      bookings.where((b) => b.userId == userId).toList();

  int countByUser(String userId) =>
      _bookings.where((b) => b.userId == userId).length;

  // ---------- Giá và mã ưu đãi ----------

  /// Tiền phòng = đơn giá × số đêm - giảm giá
  static PriceBreakdown calcPrice(RoomType type, int nights, [Promotion? promo]) {
    final subtotal = type.pricePerNight * nights;
    return PriceBreakdown(subtotal, promo?.discountFor(subtotal).roundToDouble() ?? 0);
  }

  /// Mã đã dùng cho một đơn chưa hủy (đơn bị hủy thì mã được dùng lại)
  bool isPromoUsed(String userId, String code) => _bookings
      .any((b) => b.userId == userId && b.promoCode == code && b.isActive);

  /// Số đơn chưa hủy đã dùng mã (thống kê cho Quản lý)
  int promoUsageCount(String code) =>
      _bookings.where((b) => b.promoCode == code && b.isActive).length;

  /// Lý do không dùng được mã (kiểm tra trước để hiển thị; server kiểm tra lại)
  String? promoError(
    Promotion promo, {
    required String userId,
    required int nights,
  }) {
    if (!promo.isActive) return 'Mã đã ngừng áp dụng';
    if (isPromoUsed(userId, promo.code)) return 'Mã này đã được sử dụng';
    if (nights < promo.minNights) {
      return 'Cần đặt từ ${promo.minNights} đêm trở lên';
    }
    if (promo.firstBookingOnly &&
        _bookings.any((b) => b.userId == userId && b.isActive)) {
      return 'Chỉ áp dụng cho đơn đặt phòng đầu tiên';
    }
    return null;
  }

  // ---------- Phòng trống ----------

  static String _key(DateTime a, DateTime b) => '${isoDay(a)}|${isoDay(b)}';

  /// Số phòng trống của [type] trong [checkIn, checkOut) theo server.
  /// Trả về null khi đang tải (lần đầu gọi sẽ tự tải rồi thông báo).
  int? availableRooms(RoomType type, DateTime checkIn, DateTime checkOut) {
    final key = _key(checkIn, checkOut);
    final cached = _availability[key];
    if (cached != null) return cached[type.id] ?? 0;
    if (Fmt.nights(checkIn, checkOut) > 0 && _loadingAvailability.add(key)) {
      _fetchAvailability(key, checkIn, checkOut);
    }
    return null;
  }

  Future<void> _fetchAvailability(String key, DateTime a, DateTime b) async {
    try {
      final data = await _api
          .get('/availability?checkIn=${isoDay(a)}&checkOut=${isoDay(b)}') as List;
      _availability[key] = {
        for (final r in data.cast<Map<String, dynamic>>())
          r['typeId'] as String: r['available'] as int
      };
    } on ApiException {
      _availability[key] = {};
    } finally {
      _loadingAvailability.remove(key);
    }
    notifyListeners();
  }

  /// Phòng có lịch trùng với [checkIn, checkOut) hay không (dữ liệu của nhân viên)
  bool _isTaken(String roomId, DateTime checkIn, DateTime checkOut,
          {String? exceptBookingId}) =>
      _bookings.any((b) =>
          b.id != exceptBookingId &&
          b.roomId == roomId &&
          b.holdsRoom &&
          b.checkIn.isBefore(checkOut) &&
          checkIn.isBefore(b.checkOut));

  /// Phòng trống của một loại, tính từ danh sách đơn nhân viên đang có
  /// (dùng cho báo cáo và chọn phòng khi nhận phòng)
  List<Room> freeRooms(String typeId, DateTime checkIn, DateTime checkOut,
          {String? exceptBookingId}) =>
      _hotels
          .roomsOfType(typeId)
          .where((r) =>
              r.isBookable &&
              !_isTaken(r.id, checkIn, checkOut,
                  exceptBookingId: exceptBookingId))
          .toList();

  // ---------- Đặt phòng ----------

  /// Tạo đơn. Khách đặt cho mình; nhân viên ([staffId] != null) đặt cho [userId].
  /// Server xếp phòng trống và khóa dòng để không trùng phòng.
  Future<(Booking?, String?)> createBooking({
    required String userId,
    String? staffId,
    required RoomType type,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String guestName,
    required String guestPhone,
    required String guestEmail,
    required String note,
    required PaymentMethod paymentMethod,
    Promotion? promo,
  }) async {
    try {
      final data = await _api.post('/bookings', {
        'userId': userId,
        'roomTypeId': type.id,
        'checkIn': isoDay(checkIn),
        'checkOut': isoDay(checkOut),
        'guests': guests,
        'guestName': guestName.trim(),
        'guestPhone': guestPhone.trim(),
        'guestEmail': guestEmail.trim(),
        'note': note.trim(),
        'paymentMethod': paymentMethod.name,
        'promoCode': promo?.code,
      });
      final booking = Booking.fromJson(data as Map<String, dynamic>);
      _upsertBooking(booking);
      _availability.clear();
      notifyListeners();
      return (booking, null);
    } on ApiException catch (e) {
      _availability.clear();
      notifyListeners();
      return (null, e.message);
    }
  }

  // ---------- Hủy đơn ----------

  /// Khách và lễ tân hủy được đơn "Đã đặt" trước ngày nhận phòng
  bool canCancel(Booking b) =>
      b.status == BookingStatus.booked && Fmt.today.isBefore(b.checkIn);

  /// Từ ngày nhận phòng trở đi là trường hợp đặc biệt, cần Quản lý
  bool canStaffCancel(Booking b, User staff) =>
      canCancel(b) || (b.status == BookingStatus.booked && staff.isManager);

  Future<String?> _cancel(String bookingId) => guard(() async {
        _upsertBooking(Booking.fromJson(
            await _api.post('/bookings/$bookingId/cancel') as Map<String, dynamic>));
        _availability.clear();
        notifyListeners();
      });

  Future<String?> cancelByCustomer(String bookingId) => _cancel(bookingId);

  Future<String?> cancelByStaff(String bookingId, User staff) =>
      _cancel(bookingId);

  // ---------- Nhận phòng ----------

  bool canCheckIn(Booking b) =>
      b.status == BookingStatus.booked &&
      !Fmt.today.isBefore(b.checkIn) &&
      Fmt.today.isBefore(b.checkOut);

  /// Các phòng có thể xếp cho đơn khi nhận phòng (cùng loại, đang trống)
  List<Room> checkInOptions(Booking b) {
    final current = _hotels.roomById(b.roomId);
    if (current == null) return const [];
    return freeRooms(current.typeId, b.checkIn, b.checkOut,
            exceptBookingId: b.id)
        .where((r) => r.status == RoomStatus.available)
        .toList();
  }

  /// Đơn -> "Đã nhận phòng", phòng -> "Đang ở" (server làm trong một transaction)
  Future<String?> checkIn(String bookingId,
          {required String staffId, String? roomId}) =>
      guard(() async {
        _upsertBooking(Booking.fromJson(await _api.post(
            '/bookings/$bookingId/check-in',
            {'roomId': roomId}) as Map<String, dynamic>));
        await _hotels.loadRooms();
        notifyListeners();
      });

  // ---------- Dịch vụ sử dụng ----------

  List<ServiceUsage> usagesOf(String bookingId) => _usages
      .where((u) => u.bookingId == bookingId)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  /// Chỉ đơn "Đã nhận phòng" mới được ghi nhận dịch vụ
  Future<String?> addService(
          String bookingId, HotelService service, double quantity,
          {String note = ''}) =>
      guard(() async {
        _usages.add(ServiceUsage.fromJson(await _api.post(
            '/bookings/$bookingId/usages', {
          'serviceId': service.id,
          'quantity': quantity,
          'note': note.trim(),
        }) as Map<String, dynamic>));
        notifyListeners();
      });

  Future<String?> removeUsage(String usageId) => guard(() async {
        await _api.delete('/usages/$usageId');
        _usages.removeWhere((u) => u.id == usageId);
        notifyListeners();
      });

  /// Dịch vụ đã phát sinh trong đơn thì không được xóa
  Future<String?> deleteService(String serviceId) =>
      _hotels.deleteService(serviceId);

  /// Phòng đã phát sinh trong đơn thì không được xóa
  Future<String?> deleteRoom(String roomId) => _hotels.deleteRoom(roomId);

  // ---------- Trả phòng và hóa đơn ----------

  /// Bảng kê dự kiến (công thức giống server): tiền phòng theo số đêm lưu trú
  /// thực tế (tối thiểu 1 đêm) + tiền dịch vụ - giảm giá
  Bill billFor(Booking b) {
    final nights =
        max(1, Fmt.nights(b.actualCheckIn ?? b.checkIn, DateTime.now()));
    final roomCharge = b.unitPrice * nights;
    return Bill(
      nights: nights,
      roomCharge: roomCharge,
      serviceCharge: usagesOf(b.id).fold(0, (sum, u) => sum + u.amount),
      discount: min(b.discount, roomCharge),
    );
  }

  Invoice? invoiceOf(String bookingId) =>
      _invoices.where((i) => i.bookingId == bookingId).firstOrNull;

  /// Lập hóa đơn, đơn -> "Đã trả phòng", phòng -> "Trống" (một transaction)
  Future<(Invoice?, String?)> checkOut(
    String bookingId, {
    required String staffId,
    required double paidAmount,
    required PaymentMethod method,
    String note = '',
  }) async {
    try {
      final data = await _api.post('/bookings/$bookingId/check-out', {
        'paidAmount': paidAmount,
        'method': method.name,
        'note': note.trim(),
      }) as Map<String, dynamic>;
      final invoice = Invoice.fromJson(data['invoice'] as Map<String, dynamic>);
      _invoices.add(invoice);
      _upsertBooking(Booking.fromJson(data['booking'] as Map<String, dynamic>));
      await _hotels.loadRooms();
      notifyListeners();
      return (invoice, null);
    } on ApiException catch (e) {
      return (null, e.message);
    }
  }

  /// Hoàn tiền đặc biệt: chỉ Quản lý được phê duyệt
  Future<String?> refund(String invoiceId, User staff) => guard(() async {
        final inv = Invoice.fromJson(
            await _api.post('/invoices/$invoiceId/refund') as Map<String, dynamic>);
        final i = _invoices.indexWhere((e) => e.id == invoiceId);
        if (i != -1) _invoices[i] = inv;
        notifyListeners();
      });

  // ---------- Đánh giá ----------

  /// User đã trả phòng ít nhất một lần -> được viết đánh giá
  bool hasCompletedStay(String userId) => _bookings.any(
      (b) => b.userId == userId && b.status == BookingStatus.checkedOut);

  // ---------- Thống kê và báo cáo (dữ liệu của nhân viên) ----------

  int countByStatus(BookingStatus s) =>
      _bookings.where((b) => b.status == s).length;

  List<Booking> latest([int n = 5]) => bookings.take(n).toList();

  /// Khách sẽ nhận phòng vào ngày [date]
  List<Booking> arrivals(DateTime date) => _bookings
      .where((b) => b.status == BookingStatus.booked && b.checkIn == date)
      .toList();

  /// Khách sẽ trả phòng vào ngày [date]
  List<Booking> departures(DateTime date) => _bookings
      .where((b) => b.status == BookingStatus.checkedIn && b.checkOut == date)
      .toList();

  /// Hóa đơn đã thanh toán, lọc theo ngày lập (tính cả [to])
  Iterable<Invoice> _paid(DateTime? from, DateTime? to) =>
      _invoices.where((i) {
        final day = Fmt.dateOnly(i.createdAt);
        return i.status == InvoiceStatus.paid &&
            (from == null || !day.isBefore(from)) &&
            (to == null || !day.isAfter(to));
      });

  double revenue({DateTime? from, DateTime? to}) =>
      _paid(from, to).fold(0, (sum, i) => sum + i.total);

  List<RevenueRow> _group(
    Iterable<Invoice> invoices,
    String Function(Invoice) keyOf,
    String Function(Invoice) labelOf,
  ) {
    final rows = <String, RevenueRow>{};
    for (final i in invoices) {
      rows.putIfAbsent(keyOf(i), () => RevenueRow(labelOf(i)))
        ..invoices += 1
        ..roomRevenue += i.roomCharge
        ..serviceRevenue += i.serviceCharge
        ..total += i.total;
    }
    final keys = rows.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) rows[k]!];
  }

  List<RevenueRow> revenueByPeriod(RevenuePeriod period,
      {DateTime? from, DateTime? to}) {
    String key(Invoice i) => switch (period) {
          RevenuePeriod.day => Fmt.isoDate(i.createdAt),
          RevenuePeriod.month => Fmt.isoDate(i.createdAt).substring(0, 7),
          RevenuePeriod.year => '${i.createdAt.year}',
        };
    String label(Invoice i) => switch (period) {
          RevenuePeriod.day => Fmt.date(i.createdAt),
          RevenuePeriod.month => Fmt.date(i.createdAt).substring(3),
          RevenuePeriod.year => '${i.createdAt.year}',
        };
    return _group(_paid(from, to), key, label);
  }

  List<RevenueRow> revenueByRoomType({DateTime? from, DateTime? to}) {
    String typeOf(Invoice i) => bookingById(i.bookingId)?.roomTypeName ?? '-';
    return _group(_paid(from, to), typeOf, typeOf)
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// Quản lý khôi phục dữ liệu mẫu trên server
  Future<String?> resetToSeed() => guard(() => _api.post('/admin/reset'));
}
