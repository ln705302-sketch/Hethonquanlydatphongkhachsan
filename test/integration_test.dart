@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunrise_hotel/core/utils/formatters.dart';
import 'package:sunrise_hotel/data/api_client.dart';
import 'package:sunrise_hotel/data/local_storage.dart';
import 'package:sunrise_hotel/models/booking.dart';
import 'package:sunrise_hotel/models/invoice.dart';
import 'package:sunrise_hotel/models/promotion.dart';
import 'package:sunrise_hotel/models/room.dart';
import 'package:sunrise_hotel/providers/auth_provider.dart';
import 'package:sunrise_hotel/providers/booking_provider.dart';
import 'package:sunrise_hotel/providers/hotel_provider.dart';
import 'package:sunrise_hotel/providers/promo_provider.dart';

/// Test end-to-end: provider của app -> Node server -> Oracle.
/// Cần server chạy trên schema test (dữ liệu sẽ bị khôi phục về mẫu):
///   cd server && DB_USER=SUNRISE_TEST PORT=8081 node src/server.js
///   flutter test test/integration_test.dart --dart-define=API_URL=http://localhost:8081/api
/// Không có server -> test được bỏ qua.
void main() {
  late LocalStorage storage;

  /// Một "phiên trình duyệt" với đầy đủ provider như trong app
  Future<(AuthProvider, HotelProvider, BookingProvider, PromoProvider)> session(
      String email, String password) async {
    final api = ApiClient();
    final auth = AuthProvider(api, storage);
    final hotels = HotelProvider(api);
    final bookings = BookingProvider(api, hotels);
    final promos = PromoProvider(api);
    expect(await auth.login(email, password), isNull);
    await hotels.load();
    await bookings.load(loggedIn: true);
    await promos.load(customer: !auth.isStaff);
    await auth.loadUsers();
    return (auth, hotels, bookings, promos);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.init();
  });

  Future<bool> serverUp() async =>
      await guard(() => ApiClient().get('/health')) == null;

  test('Toàn bộ quy trình đặt phòng -> nhận phòng -> dịch vụ -> trả phòng', () async {
    // Test này khôi phục dữ liệu mẫu nên chỉ chạy khi chỉ định rõ server test,
    // tránh chạy nhầm vào server dữ liệu thật (mặc định localhost:8080)
    if (!const bool.hasEnvironment('API_URL')) {
      markTestSkipped('Cần --dart-define=API_URL=<server test>');
      return;
    }
    if (!await serverUp()) {
      markTestSkipped('Không có server tại $kApiUrl');
      return;
    }
    // Quản lý khôi phục dữ liệu mẫu để test luôn chạy trên cùng dữ liệu
    var (auth, hotels, bookings, promos) =
        await session('admin@sunrisehotel.local', 'admin123');
    expect(await bookings.resetToSeed(), isNull);

    // 1. Khách mới đăng ký, xem phòng trống, đặt phòng với mã thành viên mới
    final reg = AuthProvider(ApiClient(), storage);
    final email = 'e2e${DateTime.now().millisecondsSinceEpoch}@example.com';
    expect(
        await reg.register(
            fullName: 'Khách E2E', email: email, phone: '0987654321', password: 'abc123'),
        isNull);
    (auth, hotels, bookings, promos) = await session(email, 'abc123');
    final standard = hotels.roomTypes.firstWhere((t) => t.name == 'Standard');
    final checkIn = Fmt.today.add(const Duration(days: 30));
    final checkOut = checkIn.add(const Duration(days: 2));
    expect(bookings.availableRooms(standard, checkIn, checkOut), isNull); // đang tải
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(bookings.availableRooms(standard, checkIn, checkOut), 2);

    expect(await promos.save(auth.currentUser!.id, 'XINCHAO10'), isNull);
    final promo = promos.savedOf(auth.currentUser!.id).single;
    final (booking, error) = await bookings.createBooking(
      userId: auth.currentUser!.id,
      type: standard,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: 2,
      guestName: 'Khách E2E',
      guestPhone: '0987654321',
      guestEmail: email,
      note: '',
      paymentMethod: PaymentMethod.bankTransfer,
      promo: promo,
    );
    expect(error, isNull);
    expect(booking!.discount, 130000); // 10% của 2 x 650.000
    expect(bookings.bookings.single.id, booking.id);
    // Mã đã dùng -> client và server cùng từ chối lần hai
    expect(bookings.promoError(promo, userId: auth.currentUser!.id, nights: 2), isNotNull);
    expect(await bookings.cancelByCustomer(booking.id), isNull);
    expect(bookings.bookingById(booking.id)!.status, BookingStatus.cancelled);

    // 2. Lễ tân nhận phòng đơn hôm nay, ghi dịch vụ, trả phòng
    (auth, hotels, bookings, promos) =
        await session('letan01@sunrisehotel.local', 'letan123');
    final arrival = bookings.arrivals(Fmt.today).single;
    expect(await bookings.checkIn(arrival.id, staffId: auth.currentUser!.id), isNull);
    expect(hotels.roomById(arrival.roomId)!.status, RoomStatus.occupied);
    final breakfast = hotels.services.firstWhere((s) => s.name == 'Ăn sáng');
    expect(await bookings.addService(arrival.id, breakfast, 2), isNull);
    final bill = bookings.billFor(bookings.bookingById(arrival.id)!);
    expect(bill.total, 650000 + 200000);
    final short = await bookings.checkOut(arrival.id,
        staffId: auth.currentUser!.id, paidAmount: 100, method: PaymentMethod.cash);
    expect(short.$2, 'Số tiền khách trả chưa đủ');
    final (invoice, outError) = await bookings.checkOut(arrival.id,
        staffId: auth.currentUser!.id, paidAmount: 1000000, method: PaymentMethod.cash);
    expect(outError, isNull);
    expect(invoice!.total, bill.total); // server tính giống bảng kê client
    expect(invoice.change, 1000000 - bill.total);
    expect(bookings.bookingById(arrival.id)!.status, BookingStatus.checkedOut);
    expect(hotels.roomById(arrival.roomId)!.status, RoomStatus.available);
    // Lễ tân không hoàn tiền được
    expect(await bookings.refund(invoice.id, auth.currentUser!), isNotNull);

    // 3. Quản lý: hoàn tiền, mã ưu đãi, nhân viên, đánh giá
    (auth, hotels, bookings, promos) =
        await session('admin@sunrisehotel.local', 'admin123');
    expect(await bookings.refund(invoice.id, auth.currentUser!), isNull);
    expect(bookings.invoices.firstWhere((i) => i.id == invoice.id).status,
        InvoiceStatus.refunded);
    expect(
        await promos.savePromotion(const Promotion(
            code: 'E2E50', title: 'Test', description: '', fixedAmount: 50000)),
        isNull);
    expect(await promos.toggleActive('E2E50'), isNull);
    expect(promos.byCode('E2E50')!.isActive, isFalse);
    expect(await promos.deletePromotion('E2E50'), isNull);
    final review = hotels.allReviews.first;
    expect(await hotels.toggleReviewHidden(review.id), isNull);
    expect(hotels.reviews.any((r) => r.id == review.id), isFalse);
    expect(
        await auth.updateStaff(
            id: auth.currentUser!.id,
            fullName: 'QTV',
            email: 'admin@sunrisehotel.local',
            phone: '0909000111',
            role: auth.currentUser!.role == auth.staff.first.role
                ? auth.staff.last.role
                : auth.staff.first.role),
        'Bạn không thể tự đổi vai trò của mình');

    // 4. Khách cũ (đã từng ở) viết đánh giá
    (auth, hotels, bookings, promos) = await session('an@example.com', 'user123');
    expect(bookings.hasCompletedStay(auth.currentUser!.id), isTrue);
    expect(await hotels.addReview(user: auth.currentUser!, score: 9, comment: 'Rất hài lòng với kỳ nghỉ'),
        isNull);
    expect(hotels.reviewOf(auth.currentUser!.id)!.score, 9);

    // Khôi phục lại dữ liệu mẫu cho lần chạy sau
    (auth, hotels, bookings, promos) =
        await session('admin@sunrisehotel.local', 'admin123');
    expect(await bookings.resetToSeed(), isNull);
  });
}
