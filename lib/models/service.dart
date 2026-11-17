/// Dịch vụ của khách sạn (bảng DichVu)
class HotelService {
  const HotelService({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.unit,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String unit; // Suất, Kg, Chuyến...
  final bool isActive;

  factory HotelService.fromJson(Map<String, dynamic> json) => HotelService(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        unit: json['unit'] as String,
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'unit': unit,
        'isActive': isActive,
      };
}

/// Một lần sử dụng dịch vụ (bảng SuDungDichVu). Đơn giá được chốt tại thời
/// điểm ghi nhận nên đổi giá dịch vụ sau đó không ảnh hưởng hóa đơn.
class ServiceUsage {
  const ServiceUsage({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    required this.serviceName,
    required this.unit,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    this.note = '',
  });

  final String id;
  final String bookingId;
  final String serviceId;
  final String serviceName;
  final String unit;
  final DateTime date;
  final double quantity;
  final double unitPrice;
  final String note;

  double get amount => quantity * unitPrice;

  factory ServiceUsage.fromJson(Map<String, dynamic> json) => ServiceUsage(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        serviceId: json['serviceId'] as String,
        serviceName: json['serviceName'] as String,
        unit: json['unit'] as String,
        date: DateTime.parse(json['date'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        note: json['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'unit': unit,
        'date': date.toIso8601String(),
        'quantity': quantity,
        'unitPrice': unitPrice,
        'note': note,
      };
}
