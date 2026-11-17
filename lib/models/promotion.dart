import 'dart:math';

/// Mã ưu đãi: giảm theo % hoặc số tiền cố định, kèm điều kiện áp dụng
class Promotion {
  const Promotion({
    required this.code,
    required this.title,
    required this.description,
    this.percent = 0,
    this.fixedAmount = 0,
    this.minNights = 1,
    this.firstBookingOnly = false,
    this.isActive = true,
  });

  final String code;
  final String title;
  final String description;
  final double percent; // VD: 15 = giảm 15%
  final double fixedAmount; // Số tiền giảm cố định (VNĐ)
  final int minNights;
  final bool firstBookingOnly;
  final bool isActive; // Quản lý có thể tạm ngừng áp dụng mã

  Promotion copyWith({bool? isActive}) => Promotion(
        code: code,
        title: title,
        description: description,
        percent: percent,
        fixedAmount: fixedAmount,
        minNights: minNights,
        firstBookingOnly: firstBookingOnly,
        isActive: isActive ?? this.isActive,
      );

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        percent: (json['percent'] as num? ?? 0).toDouble(),
        fixedAmount: (json['fixedAmount'] as num? ?? 0).toDouble(),
        minNights: json['minNights'] as int? ?? 1,
        firstBookingOnly: json['firstBookingOnly'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'description': description,
        'percent': percent,
        'fixedAmount': fixedAmount,
        'minNights': minNights,
        'firstBookingOnly': firstBookingOnly,
        'isActive': isActive,
      };

  /// Số tiền được giảm trên tiền phòng (không vượt quá tiền phòng)
  double discountFor(double subtotal) =>
      min(subtotal * percent / 100 + fixedAmount, subtotal);
}

/// Mã ưu đãi mẫu (dữ liệu ban đầu, Quản lý có thể thêm / sửa / xóa)
const kPromotions = [
  Promotion(
    code: 'SUNRISE15',
    title: 'Giảm 15% kỳ nghỉ dài',
    description: 'Giảm 15% tiền phòng cho đơn từ 3 đêm',
    percent: 15,
    minNights: 3,
  ),
  Promotion(
    code: 'WEEKEND300',
    title: 'Ưu đãi cuối tuần',
    description: 'Giảm 300.000 ₫ cho đơn từ 2 đêm',
    fixedAmount: 300000,
    minNights: 2,
  ),
  Promotion(
    code: 'XINCHAO10',
    title: 'Thành viên mới',
    description: 'Giảm 10% cho lần đặt phòng đầu tiên',
    percent: 10,
    firstBookingOnly: true,
  ),
];
