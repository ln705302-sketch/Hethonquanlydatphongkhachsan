import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunrise_hotel/core/constants.dart';
import 'package:sunrise_hotel/core/utils/formatters.dart';
import 'package:sunrise_hotel/data/api_client.dart';
import 'package:sunrise_hotel/data/local_storage.dart';
import 'package:sunrise_hotel/models/booking.dart';
import 'package:sunrise_hotel/models/promotion.dart';
import 'package:sunrise_hotel/providers/auth_provider.dart';
import 'package:sunrise_hotel/providers/booking_provider.dart';
import 'package:sunrise_hotel/providers/hotel_provider.dart';
import 'package:sunrise_hotel/providers/promo_provider.dart';

import 'support/fake_backend.dart';

/// Logic phía client (hiển thị, tính trước) chạy trên backend giả.
/// Nghiệp vụ thật do server kiểm tra: xem server/test/api.test.js
void main() {
  const staying = '6e8a0c2d-0005-4a5e-9f54-e5f6a7b8c9d0'; // Phòng 202
  const arrivalToday = '7a9b1d3e-0006-4b6f-8a65-f6a7b8c9d0e1'; // Phòng 102

  late LocalStorage storage;
  late ApiClient api;
  late AuthProvider auth;
  late HotelProvider hotels;
  late BookingProvider bookings;
  late PromoProvider promos;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.init();
    api = ApiClient(client: FakeBackend().client);
    auth = AuthProvider(api, storage);
    hotels = HotelProvider(api);
    bookings = BookingProvider(api, hotels);
    promos = PromoProvider(api);
    await hotels.load();
  });

  Future<void> loginAs(String email, String password) async {
    expect(await auth.login(email, password), isNull);
    await bookings.load(loggedIn: true);
    await promos.load(customer: !auth.isStaff);
    await auth.loadUsers();
  }

  test('Mã hiển thị: id số đệm 6 chữ số, id chuỗi lấy 8 ký tự', () {
    expect(Fmt.bookingCode('12'), 'SRH000012');
    expect(Fmt.invoiceCode('3'), 'HD000003');
    expect(Fmt.bookingCode('5f3a9c1e-0001-4c1a'), 'SRH5F3A9C1E');
    expect(Fmt.vnd(1250000), '1.250.000 ₫');
  });

  test('ApiClient: đọc thông báo lỗi, báo hết phiên khi 401, lỗi mạng', () async {
    var expired = false;
    final c = ApiClient(
      client: MockClient((req) async => http.Response(
          '{"error":"Phiên đăng nhập đã hết hạn"}', 401,
          headers: {'content-type': 'application/json; charset=utf-8'})),
    )
      ..token = 'abc'
      ..onUnauthorized = () => expired = true;
    await expectLater(
        c.get('/bookings'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Phiên đăng nhập đã hết hạn')
            .having((e) => e.status, 'status', 401)));
    expect(expired, isTrue);

    final offline = ApiClient(
        client: MockClient((req) async => throw http.ClientException('down')));
    expect(await guard(() => offline.get('/hotel')),
        contains('Không kết nối được máy chủ'));
  });

  test('Đăng nhập lưu token, tải lại app vẫn giữ phiên; sai mật khẩu báo lỗi', () async {
    expect(await auth.login('an@example.com', 'sai'), 'Email hoặc mật khẩu không đúng');
    await loginAs('an@example.com', 'user123');
    expect(storage.readString(StorageKeys.session), isNotNull);

    final restored = AuthProvider(api, storage);
    await restored.init();
    expect(restored.currentUser?.email, 'an@example.com');

    await restored.logout();
    expect(storage.readString(StorageKeys.session), isNull);
  });

  test('Khách chỉ nhận đơn của mình; nhân viên nhận tất cả và danh sách khách', () async {
    await loginAs('an@example.com', 'user123');
    expect(bookings.bookings, isNotEmpty);
    expect(bookings.bookings.every((b) => b.userId == 'u-customer'), isTrue);
    expect(auth.customers, isEmpty);

    await loginAs('letan01@sunrisehotel.local', 'letan123');
    expect(bookings.bookings.length, 7);
    expect(auth.customers.length, 2);
    expect(auth.staff, isEmpty); // Lễ tân không xem danh sách nhân viên
  });

  test('Điều kiện mã ưu đãi và giá phòng (tính trước để hiển thị)', () async {
    await loginAs('an@example.com', 'user123');
    final standard = hotels.roomTypeById('rt-standard')!;
    final longStay = kPromotions.firstWhere((p) => p.code == 'SUNRISE15');
    final first = kPromotions.firstWhere((p) => p.firstBookingOnly);
    expect(BookingProvider.calcPrice(standard, 3, longStay).discount, 292500);
    expect(bookings.promoError(longStay, userId: 'u-customer', nights: 2),
        'Cần đặt từ 3 đêm trở lên');
    expect(bookings.promoError(first, userId: 'u-customer', nights: 1),
        'Chỉ áp dụng cho đơn đặt phòng đầu tiên');
    expect(
        bookings.promoError(longStay.copyWith(isActive: false),
            userId: 'u-customer', nights: 3),
        'Mã đã ngừng áp dụng');
  });

  test('Lưu / bỏ lưu mã ưu đãi gọi server', () async {
    await loginAs('an@example.com', 'user123');
    expect(await promos.save('u-customer', 'SUNRISE15'), isNull);
    expect(promos.isSaved('u-customer', 'SUNRISE15'), isTrue);
    await promos.load(customer: true);
    expect(promos.savedOf('u-customer').single.code, 'SUNRISE15');
    expect(await promos.remove('u-customer', 'SUNRISE15'), isNull);
    expect(promos.savedOf('u-customer'), isEmpty);
  });

  test('Nhân viên: bảng kê, nhận phòng, chọn phòng, báo cáo', () async {
    await loginAs('admin@sunrisehotel.local', 'admin123');
    final stay = bookings.bookingById(staying)!;
    final bill = bookings.billFor(stay);
    expect(bill.nights, 1);
    expect(bill.roomCharge, 950000);
    expect(bill.serviceCharge, 120000);
    expect(bill.total, 1070000);

    final arrival = bookings.bookingById(arrivalToday)!;
    expect(bookings.canCheckIn(arrival), isTrue);
    expect(bookings.canCancel(arrival), isFalse); // Đã đến ngày nhận phòng
    expect(bookings.canStaffCancel(arrival, auth.currentUser!), isTrue); // Quản lý
    expect(bookings.checkInOptions(arrival).map((r) => r.number), ['101', '102']);

    expect(bookings.revenue(), 3700000);
    final byType = bookings.revenueByRoomType();
    expect(byType.first.label, 'Deluxe');
    expect(bookings.arrivals(Fmt.today).single.id, arrivalToday);
    expect(bookings.countByStatus(BookingStatus.checkedIn), 1);
  });
}
