import 'package:sunrise_hotel/core/utils/formatters.dart';
import 'package:sunrise_hotel/models/booking.dart';
import 'package:sunrise_hotel/models/hotel.dart';
import 'package:sunrise_hotel/models/invoice.dart';
import 'package:sunrise_hotel/models/review.dart';
import 'package:sunrise_hotel/models/room.dart';
import 'package:sunrise_hotel/models/room_type.dart';
import 'package:sunrise_hotel/models/service.dart';
import 'package:sunrise_hotel/models/user.dart';

/// Tạo link ảnh Unsplash theo id
String unsplash(String id, {int w = 1000}) =>
    'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=$w&q=70';

const _comments = [
  ('Minh Anh', 8.8, 'Phòng sạch sẽ, nhân viên rất nhiệt tình. Vị trí thuận tiện đi lại.'),
  ('Quốc Bảo', 8.5, 'Bữa sáng ngon, nhiều món. Sẽ quay lại lần sau!'),
  ('Thu Hà', 7.9, 'Giá hợp lý so với chất lượng, view đẹp. Wifi hơi chậm vào buổi tối.'),
  ('Hoàng Nam', 9.2, 'Check-in nhanh, phòng thơm tho, giường êm. Rất hài lòng.'),
];

/// Dữ liệu mẫu, khớp với phần DEMO DATA của SUNRISE_HOTEL_ORACLE23AI.sql
class MockData {
  MockData._();

  static Hotel hotel() => Hotel(
        name: 'Sunrise Hotel',
        city: 'TP. Hồ Chí Minh',
        address: '1 Đường Bình Minh, Quận 1',
        phone: '1900 1234',
        email: 'support@sunrisehotel.local',
        description:
            'Sunrise Hotel là khách sạn 3 sao với các hạng phòng Standard, Deluxe '
            'và Suite, phục vụ khách du lịch, gia đình và khách công tác. Khách sạn '
            'có dịch vụ ăn sáng, giặt ủi và đưa đón sân bay.',
        stars: 3,
        images: [
          for (final id in const [
            '1566073771259-6a8506099945',
            '1551882547-ff40c63fe5fa',
            '1542314831-068cd1dbfeeb',
            '1582719478250-c89cae4dc85b',
            '1590490360182-c33d57733427',
          ])
            unsplash(id),
        ],
        amenities: const ['wifi', 'restaurant', 'parking', 'airport'],
      );

  static List<RoomType> roomTypes() => [
        RoomType(
          id: 'rt-standard',
          name: 'Standard',
          description: 'Phòng tiêu chuẩn, tiện nghi cơ bản',
          bedType: '1 giường đôi',
          maxGuests: 2,
          area: 22,
          pricePerNight: 650000,
          amenities: const ['Điều hòa', 'TV', 'Vòi sen'],
          images: [unsplash('1611892440504-42a792e24d32', w: 800)],
        ),
        RoomType(
          id: 'rt-deluxe',
          name: 'Deluxe',
          description: 'Phòng cao cấp, không gian rộng',
          bedType: '1 giường King',
          maxGuests: 3,
          area: 30,
          pricePerNight: 950000,
          amenities: const ['Điều hòa', 'Smart TV', 'Minibar', 'Bồn tắm'],
          images: [unsplash('1618773928121-c32242e63f39', w: 800)],
        ),
        RoomType(
          id: 'rt-suite',
          name: 'Suite',
          description: 'Phòng Suite cao cấp với phòng khách riêng',
          bedType: '2 giường Queen',
          maxGuests: 4,
          area: 45,
          pricePerNight: 1600000,
          amenities: const ['Điều hòa', 'Smart TV', 'Minibar', 'Bồn tắm', 'Phòng khách riêng'],
          images: [unsplash('1631049307264-da0ec9d70304', w: 800)],
        ),
      ];

  static List<Room> rooms() => [
        Room(id: 'r-101', typeId: 'rt-standard', number: '101', floor: 1, note: 'Standard - tầng 1'),
        Room(id: 'r-102', typeId: 'rt-standard', number: '102', floor: 1, note: 'Standard - tầng 1'),
        Room(id: 'r-201', typeId: 'rt-deluxe', number: '201', floor: 2, note: 'Deluxe - tầng 2'),
        Room(id: 'r-202', typeId: 'rt-deluxe', number: '202', floor: 2, note: 'Deluxe - tầng 2', status: RoomStatus.occupied),
        Room(id: 'r-301', typeId: 'rt-suite', number: '301', floor: 3, note: 'Suite - tầng 3'),
      ];

  static List<HotelService> services() => [
        HotelService(id: 'sv-breakfast', name: 'Ăn sáng', description: 'Suất ăn sáng', price: 100000, unit: 'Suất'),
        HotelService(id: 'sv-laundry', name: 'Giặt ủi', description: 'Dịch vụ giặt và ủi quần áo', price: 80000, unit: 'Kg'),
        HotelService(id: 'sv-airport', name: 'Đưa đón sân bay', description: 'Đưa đón một chiều', price: 300000, unit: 'Chuyến'),
      ];

  static List<User> users() => [
        User(
          id: 'u-manager',
          fullName: 'Quản trị viên',
          email: 'admin@sunrisehotel.local',
          phone: '0909000111',
          role: UserRole.manager,
          createdAt: DateTime(2026, 1, 1),
        ),
        User(
          id: 'u-reception',
          fullName: 'Lễ tân 01',
          email: 'letan01@sunrisehotel.local',
          phone: '0909000222',
          role: UserRole.receptionist,
          createdAt: DateTime(2026, 1, 1),
        ),
        User(
          id: 'u-customer',
          fullName: 'Nguyễn Văn An',
          email: 'an@example.com',
          phone: '0900000001',
          cccd: '079098000001',
          address: 'TP. Hồ Chí Minh',
          gender: 'Nam',
          birthDate: DateTime(1998, 5, 12),
          createdAt: DateTime(2026, 3, 15),
        ),
        User(
          id: 'u-binh',
          fullName: 'Trần Thị Bình',
          email: 'binh@example.com',
          phone: '0900000002',
          cccd: '079200000002',
          address: 'TP. Hồ Chí Minh',
          gender: 'Nữ',
          birthDate: DateTime(2000, 9, 20),
          createdAt: DateTime(2026, 5, 20),
        ),
      ];

  static List<Review> reviews() => [
        for (var i = 0; i < _comments.length; i++)
          Review(
            id: 'rv-$i',
            userId: 'mock-reviewer-$i',
            userName: _comments[i].$1,
            score: _comments[i].$2,
            comment: _comments[i].$3,
            createdAt: DateTime(2026, 9 - i, 10 + i),
          ),
      ];

  /// Đơn mẫu đủ các trạng thái (ngày tính tương đối so với hôm nay)
  static List<Booking> bookings() {
    final today = Fmt.today;
    final types = {for (final t in roomTypes()) t.id: t};
    final numbers = {for (final r in rooms()) r.id: r};

    Booking make(String id, String userId, String roomId, int startOffset,
        int nights, BookingStatus status,
        {PaymentMethod pay = PaymentMethod.cash}) {
      final room = numbers[roomId]!;
      final type = types[room.typeId]!;
      final checkIn = today.add(Duration(days: startOffset));
      final checkOut = checkIn.add(Duration(days: nights));
      final isBinh = userId == 'u-binh';
      final stayed = status == BookingStatus.checkedIn ||
          status == BookingStatus.checkedOut;
      return Booking(
        id: id,
        userId: userId,
        staffId: stayed ? 'u-reception' : null,
        roomId: room.id,
        roomNumber: room.number,
        roomTypeName: type.name,
        unitPrice: type.pricePerNight,
        checkIn: checkIn,
        checkOut: checkOut,
        actualCheckIn: stayed ? checkIn : null,
        actualCheckOut: status == BookingStatus.checkedOut ? checkOut : null,
        guests: 2,
        guestName: isBinh ? 'Trần Thị Bình' : 'Nguyễn Văn An',
        guestPhone: isBinh ? '0900000002' : '0900000001',
        guestEmail: isBinh ? 'binh@example.com' : 'an@example.com',
        paymentMethod: pay,
        status: status,
        createdAt: checkIn.subtract(const Duration(days: 7)),
      );
    }

    return [
      make('5f3a9c1e-0001-4c1a-9b10-a1b2c3d4e5f6', 'u-customer', 'r-201', -20, 2,
          BookingStatus.checkedOut, pay: PaymentMethod.card),
      make('8b2d7e4f-0002-4d2b-8c21-b2c3d4e5f6a7', 'u-customer', 'r-101', 10, 3,
          BookingStatus.booked, pay: PaymentMethod.bankTransfer),
      make('2c4e6a8b-0003-4e3c-9d32-c3d4e5f6a7b8', 'u-customer', 'r-301', 5, 2,
          BookingStatus.booked),
      make('9d1f3b5c-0004-4f4d-8e43-d4e5f6a7b8c9', 'u-customer', 'r-102', 25, 2,
          BookingStatus.cancelled),
      make('6e8a0c2d-0005-4a5e-9f54-e5f6a7b8c9d0', 'u-binh', 'r-202', -1, 3,
          BookingStatus.checkedIn),
      make('7a9b1d3e-0006-4b6f-8a65-f6a7b8c9d0e1', 'u-binh', 'r-102', 0, 2,
          BookingStatus.booked),
      make('1b3c5d7f-0007-4c70-9b76-a7b8c9d0e1f2', 'u-binh', 'r-301', -40, 1,
          BookingStatus.checkedOut),
    ];
  }

  static List<ServiceUsage> serviceUsages() {
    final today = Fmt.today;
    return [
      ServiceUsage(
        id: 'su-1',
        bookingId: '5f3a9c1e-0001-4c1a-9b10-a1b2c3d4e5f6',
        serviceId: 'sv-breakfast',
        serviceName: 'Ăn sáng',
        unit: 'Suất',
        date: today.subtract(const Duration(days: 19)),
        quantity: 2,
        unitPrice: 100000,
      ),
      ServiceUsage(
        id: 'su-2',
        bookingId: '6e8a0c2d-0005-4a5e-9f54-e5f6a7b8c9d0',
        serviceId: 'sv-laundry',
        serviceName: 'Giặt ủi',
        unit: 'Kg',
        date: today,
        quantity: 1.5,
        unitPrice: 80000,
      ),
    ];
  }

  static List<Invoice> invoices() {
    final today = Fmt.today;
    return [
      Invoice(
        id: 'a1b2c3d4-1001-4a00-8000-000000000001',
        bookingId: '5f3a9c1e-0001-4c1a-9b10-a1b2c3d4e5f6',
        staffId: 'u-reception',
        createdAt: today.subtract(const Duration(days: 18)),
        nights: 2,
        roomCharge: 1900000,
        serviceCharge: 200000,
        discount: 0,
        total: 2100000,
        paidAmount: 2100000,
        change: 0,
        method: PaymentMethod.card,
      ),
      Invoice(
        id: 'b2c3d4e5-1002-4a00-8000-000000000002',
        bookingId: '1b3c5d7f-0007-4c70-9b76-a7b8c9d0e1f2',
        staffId: 'u-reception',
        createdAt: today.subtract(const Duration(days: 39)),
        nights: 1,
        roomCharge: 1600000,
        serviceCharge: 0,
        discount: 0,
        total: 1600000,
        paidAmount: 2000000,
        change: 400000,
        method: PaymentMethod.cash,
      ),
    ];
  }
}
