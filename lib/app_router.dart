import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/about/about_screen.dart';
import 'screens/admin/admin_layout.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/hotel_info_screen.dart';
import 'screens/admin/manage_bookings_screen.dart';
import 'screens/admin/manage_customers_screen.dart';
import 'screens/admin/manage_invoices_screen.dart';
import 'screens/admin/manage_promotions_screen.dart';
import 'screens/admin/manage_reviews_screen.dart';
import 'screens/admin/manage_room_types_screen.dart';
import 'screens/admin/manage_rooms_screen.dart';
import 'screens/admin/manage_services_screen.dart';
import 'screens/admin/manage_staff_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/booking/booking_success_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/info/info_screen.dart';
import 'screens/my_bookings/my_bookings_screen.dart';
import 'screens/my_promos/my_promos_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/rooms/rooms_screen.dart';
import 'screens/services/services_screen.dart';

/// Các route cần đăng nhập
const _protectedPrefixes = [
  '/booking',
  '/my-bookings',
  '/my-promos',
  '/profile',
  '/admin',
];

/// Các trang chỉ Quản lý được vào: giá, dịch vụ, nhân viên, thông tin khách sạn
const _managerPrefixes = [
  '/admin/hotel',
  '/admin/room-types',
  '/admin/services',
  '/admin/staff',
  '/admin/promotions',
  '/admin/reviews',
];

/// Trang không có hiệu ứng chuyển cảnh (cảm giác giống web)
Page<void> _page(GoRouterState state, Widget child) =>
    NoTransitionPage(key: state.pageKey, child: child);

/// Tạo router với route guard dựa trên AuthProvider
GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final needLogin = _protectedPrefixes.any(path.startsWith);

      // Chưa đăng nhập -> chuyển sang login, nhớ trang cần quay lại
      if (!auth.isLoggedIn && needLogin) {
        return Uri(
          path: '/login',
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      // Đã đăng nhập mà vào login/register -> quay về trang trước đó
      if (auth.isLoggedIn && (path == '/login' || path == '/register')) {
        final from = state.uri.queryParameters['from'];
        return (from != null && from.startsWith('/')) ? from : '/';
      }
      // Chỉ nhân viên mới vào được khu quản trị
      if (path.startsWith('/admin') && !auth.isStaff) return '/';
      if (_managerPrefixes.any(path.startsWith) && !auth.isManager) {
        return '/admin';
      }
      return null;
    },
    errorPageBuilder: (context, state) =>
        _page(state, const NotFoundScreen()),
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (c, s) => _page(s, const HomeScreen()),
      ),
      GoRoute(
        path: '/rooms',
        pageBuilder: (c, s) =>
            _page(s, RoomsScreen(query: s.uri.queryParameters)),
      ),
      GoRoute(
        path: '/services',
        pageBuilder: (c, s) => _page(s, const ServicesScreen()),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (c, s) => _page(s, const AboutScreen()),
      ),
      GoRoute(
        path: '/booking',
        pageBuilder: (c, s) =>
            _page(s, BookingScreen(query: s.uri.queryParameters)),
        routes: [
          GoRoute(
            path: 'success/:id',
            pageBuilder: (c, s) => _page(
                s, BookingSuccessScreen(bookingId: s.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/my-bookings',
        pageBuilder: (c, s) => _page(s, const MyBookingsScreen()),
      ),
      GoRoute(
        path: '/my-promos',
        pageBuilder: (c, s) => _page(s, const MyPromosScreen()),
      ),
      GoRoute(
        path: '/info/:slug',
        pageBuilder: (c, s) =>
            _page(s, InfoScreen(slug: s.pathParameters['slug']!)),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (c, s) => _page(s, const ProfileScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) =>
            _page(s, LoginScreen(from: s.uri.queryParameters['from'])),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (c, s) =>
            _page(s, RegisterScreen(from: s.uri.queryParameters['from'])),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (c, s) => _page(s, const DashboardScreen()),
          ),
          GoRoute(
            path: '/admin/bookings',
            pageBuilder: (c, s) => _page(s, const ManageBookingsScreen()),
          ),
          GoRoute(
            path: '/admin/rooms',
            pageBuilder: (c, s) => _page(s, const ManageRoomsScreen()),
          ),
          GoRoute(
            path: '/admin/customers',
            pageBuilder: (c, s) => _page(s, const ManageCustomersScreen()),
          ),
          GoRoute(
            path: '/admin/invoices',
            pageBuilder: (c, s) => _page(s, const ManageInvoicesScreen()),
          ),
          GoRoute(
            path: '/admin/reports',
            pageBuilder: (c, s) => _page(s, const ReportsScreen()),
          ),
          GoRoute(
            path: '/admin/room-types',
            pageBuilder: (c, s) => _page(s, const ManageRoomTypesScreen()),
          ),
          GoRoute(
            path: '/admin/services',
            pageBuilder: (c, s) => _page(s, const ManageServicesScreen()),
          ),
          GoRoute(
            path: '/admin/staff',
            pageBuilder: (c, s) => _page(s, const ManageStaffScreen()),
          ),
          GoRoute(
            path: '/admin/promotions',
            pageBuilder: (c, s) => _page(s, const ManagePromotionsScreen()),
          ),
          GoRoute(
            path: '/admin/reviews',
            pageBuilder: (c, s) => _page(s, const ManageReviewsScreen()),
          ),
          GoRoute(
            path: '/admin/hotel',
            pageBuilder: (c, s) => _page(s, const HotelInfoScreen()),
          ),
        ],
      ),
    ],
  );
}
