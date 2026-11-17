enum BookingStatus {
  booked('Đã đặt'),
  checkedIn('Đã nhận phòng'),
  checkedOut('Đã trả phòng'),
  cancelled('Đã hủy');

  const BookingStatus(this.label);
  final String label;
}

enum PaymentMethod {
  cash('Tiền mặt'),
  bankTransfer('Chuyển khoản'),
  card('Thẻ');

  const PaymentMethod(this.label);
  final String label;
}

/// Phiếu đặt phòng (bảng DatPhong): mỗi phiếu gắn với đúng một phòng
class Booking {
  const Booking({
    required this.id,
    required this.userId,
    this.staffId,
    required this.roomId,
    required this.roomNumber,
    required this.roomTypeName,
    required this.unitPrice,
    required this.checkIn,
    required this.checkOut,
    this.actualCheckIn,
    this.actualCheckOut,
    required this.guests,
    required this.guestName,
    required this.guestPhone,
    required this.guestEmail,
    this.note = '',
    this.promoCode,
    this.discount = 0,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? staffId; // Lễ tân lập phiếu hoặc làm thủ tục
  final String roomId;
  final String roomNumber;
  final String roomTypeName;
  final double unitPrice; // Đơn giá chốt lúc đặt
  final DateTime checkIn;
  final DateTime checkOut;
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final int guests;
  final String guestName;
  final String guestPhone;
  final String guestEmail;
  final String note;
  final String? promoCode;
  final double discount; // Số tiền được giảm từ mã ưu đãi
  final PaymentMethod paymentMethod; // Phương thức dự kiến khi trả phòng
  final BookingStatus status;
  final DateTime createdAt;

  int get nights => checkOut.difference(checkIn).inDays;

  /// Tiền phòng dự kiến theo lịch đặt, chưa gồm dịch vụ
  double get totalPrice => unitPrice * nights - discount;

  /// Đơn chưa hủy
  bool get isActive => status != BookingStatus.cancelled;

  /// Đơn đang giữ phòng: chỉ các đơn này mới chặn lịch của phòng
  bool get holdsRoom =>
      status == BookingStatus.booked || status == BookingStatus.checkedIn;

  Booking copyWith({
    BookingStatus? status,
    String? staffId,
    String? roomId,
    String? roomNumber,
    DateTime? actualCheckIn,
    DateTime? actualCheckOut,
  }) =>
      Booking(
        id: id,
        userId: userId,
        staffId: staffId ?? this.staffId,
        roomId: roomId ?? this.roomId,
        roomNumber: roomNumber ?? this.roomNumber,
        roomTypeName: roomTypeName,
        unitPrice: unitPrice,
        checkIn: checkIn,
        checkOut: checkOut,
        actualCheckIn: actualCheckIn ?? this.actualCheckIn,
        actualCheckOut: actualCheckOut ?? this.actualCheckOut,
        guests: guests,
        guestName: guestName,
        guestPhone: guestPhone,
        guestEmail: guestEmail,
        note: note,
        promoCode: promoCode,
        discount: discount,
        paymentMethod: paymentMethod,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        userId: json['userId'] as String,
        staffId: json['staffId'] as String?,
        roomId: json['roomId'] as String,
        roomNumber: json['roomNumber'] as String,
        roomTypeName: json['roomTypeName'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        checkIn: DateTime.parse(json['checkIn'] as String),
        checkOut: DateTime.parse(json['checkOut'] as String),
        actualCheckIn: _date(json['actualCheckIn']),
        actualCheckOut: _date(json['actualCheckOut']),
        guests: json['guests'] as int,
        guestName: json['guestName'] as String,
        guestPhone: json['guestPhone'] as String,
        guestEmail: json['guestEmail'] as String? ?? '',
        note: json['note'] as String? ?? '',
        promoCode: json['promoCode'] as String?,
        discount: (json['discount'] as num? ?? 0).toDouble(),
        paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
        status: BookingStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'staffId': staffId,
        'roomId': roomId,
        'roomNumber': roomNumber,
        'roomTypeName': roomTypeName,
        'unitPrice': unitPrice,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'actualCheckIn': actualCheckIn?.toIso8601String(),
        'actualCheckOut': actualCheckOut?.toIso8601String(),
        'guests': guests,
        'guestName': guestName,
        'guestPhone': guestPhone,
        'guestEmail': guestEmail,
        'note': note,
        'promoCode': promoCode,
        'discount': discount,
        'paymentMethod': paymentMethod.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };
}
