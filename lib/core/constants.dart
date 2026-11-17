import 'package:flutter/material.dart';

/// Hằng số chung của ứng dụng
class AppConstants {
  AppConstants._();

  static const appName = 'Sunrise Hotel';
  static const maxGuests = 10;
  static const maxContentWidth = 1200.0;
}

/// Mốc kích thước màn hình cho responsive
class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}

/// Khóa lưu trữ trong shared_preferences
class StorageKeys {
  StorageKeys._();

  static const users = 'sunrise_users';
  static const session = 'sunrise_session_user';
  static const hotel = 'sunrise_hotel';
  static const roomTypes = 'sunrise_room_types';
  static const rooms = 'sunrise_rooms';
  static const services = 'sunrise_services';
  static const reviews = 'sunrise_reviews';
  static const bookings = 'sunrise_bookings';
  static const serviceUsages = 'sunrise_service_usages';
  static const invoices = 'sunrise_invoices';
  static const savedPromos = 'sunrise_saved_promos';
  static const promotions = 'sunrise_promotions';
}

/// Thông tin hiển thị một tiện nghi khách sạn
class AmenityInfo {
  const AmenityInfo(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Danh sách tiện nghi khách sạn (key lưu trong model)
const Map<String, AmenityInfo> kHotelAmenities = {
  'wifi': AmenityInfo('Wi-Fi miễn phí', Icons.wifi),
  'pool': AmenityInfo('Hồ bơi', Icons.pool),
  'parking': AmenityInfo('Bãi đỗ xe', Icons.local_parking),
  'gym': AmenityInfo('Phòng gym', Icons.fitness_center),
  'restaurant': AmenityInfo('Nhà hàng', Icons.restaurant),
  'airport': AmenityInfo('Đưa đón sân bay', Icons.airport_shuttle),
  'spa': AmenityInfo('Spa', Icons.spa),
  'beach': AmenityInfo('Gần biển', Icons.beach_access),
  'bar': AmenityInfo('Quầy bar', Icons.local_bar),
};

const kHeroImage =
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1920&q=70';
