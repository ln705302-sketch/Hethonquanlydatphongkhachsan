import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunrise_hotel/data/api_client.dart';
import 'package:sunrise_hotel/data/local_storage.dart';
import 'package:sunrise_hotel/main.dart';
import 'package:sunrise_hotel/providers/auth_provider.dart';
import 'package:sunrise_hotel/providers/booking_provider.dart';
import 'package:sunrise_hotel/screens/admin/customer_form_dialog.dart';
import 'package:sunrise_hotel/screens/admin/desk_booking_dialog.dart';
import 'package:sunrise_hotel/screens/admin/front_desk_dialogs.dart';

import 'support/fake_backend.dart';

/// Smoke test: mở từng trang ở 3 kích thước màn hình, không được có lỗi
/// render (overflow, exception...).
void main() {
  const sizes = {
    'desktop': Size(1400, 900),
    'tablet': Size(820, 1100),
    'mobile': Size(390, 844),
  };
  const customerRoutes = [
    '/',
    '/rooms',
    '/rooms?checkIn=2026-12-01&checkOut=2026-12-03&guests=5',
    '/services',
    '/about',
    '/hotels',
    '/info/help',
    '/info/cancellation',
    '/info/terms',
    '/info/privacy',
    '/info/khong-ton-tai',
    '/login',
    '/register',
  ];
  const userRoutes = [
    '/my-bookings',
    '/my-promos',
    '/profile',
    '/about',
    '/booking?roomTypeId=rt-deluxe&checkIn=2026-12-01&checkOut=2026-12-03&guests=2',
    '/booking?roomTypeId=khong-co&guests=2',
    '/booking/success/5f3a9c1e-0001-4c1a-9b10-a1b2c3d4e5f6',
  ];
  const staffRoutes = [
    '/admin',
    '/admin/bookings',
    '/admin/rooms',
    '/admin/customers',
    '/admin/invoices',
    '/admin/reports',
  ];
  const managerRoutes = [
    '/admin/room-types',
    '/admin/services',
    '/admin/staff',
    '/admin/promotions',
    '/admin/reviews',
    '/admin/hotel',
  ];

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  BuildContext ctx(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).first);

  String path(WidgetTester tester) =>
      GoRouter.of(ctx(tester)).state.uri.path;

  for (final entry in sizes.entries) {
    testWidgets('Tất cả trang hiển thị không lỗi - ${entry.key}',
        (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.init();
      final backend = FakeBackend();
      await tester.pumpWidget(SunriseApp(
          storage: storage, api: ApiClient(client: backend.client)));
      await settle(tester);

      Future<void> visit(String route) async {
        GoRouter.of(ctx(tester)).go(route);
        await settle(tester);
        final error = tester.takeException();
        if (error is Error) debugPrint('$error\n${error.stackTrace}');
        expect(error, isNull, reason: route);
      }

      Future<void> login(String email, String pass) async {
        await ctx(tester).read<AuthProvider>().login(email, pass);
        await settle(tester);
      }

      Future<void> dialog(Widget Function() build) async {
        final navigator = Navigator.of(ctx(tester), rootNavigator: true);
        unawaited(showDialog<void>(context: ctx(tester), builder: (_) => build()));
        await settle(tester);
        final error = tester.takeException();
        if (error is Error) debugPrint('$error\n${error.stackTrace}');
        expect(error, isNull);
        navigator.pop();
        await settle(tester);
      }

      for (final r in customerRoutes) {
        await visit(r);
      }

      await login('an@example.com', 'user123');
      for (final r in userRoutes) {
        await visit(r);
      }
      // Khách thường không vào được trang quản trị
      await visit('/admin');
      expect(path(tester), '/');

      await ctx(tester).read<AuthProvider>().logout();
      await login('letan01@sunrisehotel.local', 'letan123');
      for (final r in staffRoutes) {
        await visit(r);
      }
      // Lễ tân không vào được trang của Quản lý
      for (final r in managerRoutes) {
        await visit(r);
        expect(path(tester), '/admin');
      }

      final bookings = ctx(tester).read<BookingProvider>();
      final staying =
          bookings.bookingById('6e8a0c2d-0005-4a5e-9f54-e5f6a7b8c9d0')!;
      final arrival =
          bookings.bookingById('7a9b1d3e-0006-4b6f-8a65-f6a7b8c9d0e1')!;
      await dialog(() => CheckInDialog(booking: arrival));
      await dialog(() => ServiceUsageDialog(booking: staying));
      await dialog(() => CheckOutDialog(booking: staying));
      await dialog(() => const DeskBookingDialog());
      await dialog(() => const CustomerFormDialog());

      await ctx(tester).read<AuthProvider>().logout();
      await login('admin@sunrisehotel.local', 'admin123');
      for (final r in [...staffRoutes, ...managerRoutes]) {
        await visit(r);
        expect(path(tester), r);
      }

      // Mở các dialog mới bằng nút trên trang
      Future<void> tapAndClose(String route, Finder button,
          {String? menuItem}) async {
        await visit(route);
        await tester.ensureVisible(button.first);
        await tester.pump();
        await tester.tap(button.first);
        await settle(tester);
        if (menuItem != null) {
          await tester.tap(find.text(menuItem).last);
          await settle(tester);
        }
        final error = tester.takeException();
        if (error is Error) debugPrint('$error\n${error.stackTrace}');
        expect(error, isNull, reason: '$route ${menuItem ?? ''}');
        Navigator.of(ctx(tester), rootNavigator: true).pop();
        await settle(tester);
      }

      await tapAndClose('/admin/customers', find.byTooltip('Lịch sử đặt phòng'));
      await tapAndClose('/admin/customers', find.byTooltip('Đặt lại mật khẩu'));
      await tapAndClose('/admin/promotions', find.text('Thêm mã ưu đãi'));
      await tapAndClose('/admin/promotions', find.byTooltip('Sửa'));
      await tapAndClose('/admin/staff', find.byTooltip('Thao tác'),
          menuItem: 'Sửa thông tin');
      await tapAndClose('/admin/staff', find.byTooltip('Thao tác').last,
          menuItem: 'Đặt lại mật khẩu');
    });
  }

  testWidgets('Báo cáo: Lễ tân không thấy doanh thu, Quản lý thì có',
      (tester) async {
    tester.view.physicalSize = sizes['desktop']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.init();
    final backend = FakeBackend();
    await tester.pumpWidget(SunriseApp(
        storage: storage, api: ApiClient(client: backend.client)));
    await settle(tester);

    await ctx(tester).read<AuthProvider>().login('letan01@sunrisehotel.local', 'letan123');
    await settle(tester);
    GoRouter.of(ctx(tester)).go('/admin/reports');
    await settle(tester);
    expect(find.text('Doanh thu'), findsNothing);
    await tester.tap(find.text('Phòng trống'));
    await settle(tester);
    expect(find.text('Số phòng trống'), findsOneWidget);

    await ctx(tester).read<AuthProvider>().logout();
    await ctx(tester).read<AuthProvider>().login('admin@sunrisehotel.local', 'admin123');
    await settle(tester);
    GoRouter.of(ctx(tester)).go('/admin/reports');
    await settle(tester);
    await tester.tap(find.text('Doanh thu'));
    await settle(tester);
    expect(find.text('Doanh thu theo loại phòng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bấm thẻ ưu đãi để lưu mã, bấm link footer để chuyển trang',
      (tester) async {
    tester.view.physicalSize = sizes['desktop']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.init();
    final backend = FakeBackend();
    await tester.pumpWidget(SunriseApp(
        storage: storage, api: ApiClient(client: backend.client)));
    await settle(tester);

    String location() => GoRouter.of(ctx(tester)).state.uri.toString();

    Future<void> tapText(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await settle(tester);
    }

    // Chưa đăng nhập -> chuyển sang trang đăng nhập
    await tapText(find.text('Lưu mã').first);
    expect(location(), startsWith('/login'));

    await ctx(tester).read<AuthProvider>().login('an@example.com', 'user123');
    await settle(tester);
    expect(path(tester), '/');

    // Đã đăng nhập -> lưu mã, bấm lần nữa mở trang mã của tôi
    await tapText(find.text('Lưu mã').first);
    expect(find.text('Đã lưu'), findsOneWidget);
    await tapText(find.text('Đã lưu'));
    expect(location(), '/my-promos');
    expect(find.text('Dùng ngay'), findsOneWidget);

    await tapText(find.text('Chính sách hủy phòng'));
    expect(location(), '/info/cancellation');

    await tapText(find.text('Dịch vụ').last);
    expect(path(tester), '/services');
    expect(find.text('Đưa đón sân bay'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
