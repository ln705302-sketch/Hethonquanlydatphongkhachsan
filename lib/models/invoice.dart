import 'booking.dart';

enum InvoiceStatus {
  unpaid('Chưa thanh toán'),
  paid('Đã thanh toán'),
  refunded('Đã hoàn tiền');

  const InvoiceStatus(this.label);
  final String label;
}

/// Hóa đơn (bảng HoaDon): mỗi phiếu đặt phòng chỉ có một hóa đơn
class Invoice {
  const Invoice({
    required this.id,
    required this.bookingId,
    this.staffId,
    required this.createdAt,
    required this.nights,
    required this.roomCharge,
    required this.serviceCharge,
    required this.discount,
    required this.total,
    required this.paidAmount,
    required this.change,
    required this.method,
    this.status = InvoiceStatus.paid,
    this.note = '',
  });

  final String id;
  final String bookingId;
  final String? staffId;
  final DateTime createdAt;
  final int nights;
  final double roomCharge;
  final double serviceCharge;
  final double discount;
  final double total;
  final double paidAmount;
  final double change;
  final PaymentMethod method;
  final InvoiceStatus status;
  final String note;

  Invoice copyWith({InvoiceStatus? status}) => Invoice(
        id: id,
        bookingId: bookingId,
        staffId: staffId,
        createdAt: createdAt,
        nights: nights,
        roomCharge: roomCharge,
        serviceCharge: serviceCharge,
        discount: discount,
        total: total,
        paidAmount: paidAmount,
        change: change,
        method: method,
        status: status ?? this.status,
        note: note,
      );

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        staffId: json['staffId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        nights: json['nights'] as int,
        roomCharge: (json['roomCharge'] as num).toDouble(),
        serviceCharge: (json['serviceCharge'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        method: PaymentMethod.values.byName(json['method'] as String),
        status: InvoiceStatus.values.byName(json['status'] as String),
        note: json['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'staffId': staffId,
        'createdAt': createdAt.toIso8601String(),
        'nights': nights,
        'roomCharge': roomCharge,
        'serviceCharge': serviceCharge,
        'discount': discount,
        'total': total,
        'paidAmount': paidAmount,
        'change': change,
        'method': method.name,
        'status': status.name,
        'note': note,
      };
}
