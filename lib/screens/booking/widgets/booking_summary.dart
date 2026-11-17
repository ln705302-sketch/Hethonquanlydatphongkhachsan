import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/hotel.dart';
import '../../../models/promotion.dart';
import '../../../models/room_type.dart';
import '../../../providers/booking_provider.dart';
import '../../../widgets/booking_detail_dialog.dart';
import '../../../widgets/common.dart';
import '../../../widgets/rating_stars.dart';

/// Tóm tắt đơn: loại phòng, ngày, số đêm, đơn giá, giảm giá, tiền phòng
class BookingSummary extends StatelessWidget {
  const BookingSummary({
    super.key,
    required this.hotel,
    required this.type,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.available,
    this.promo,
    required this.submit,
  });

  final Hotel hotel;
  final RoomType type;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int? available; // null = đang kiểm tra
  final Promotion? promo;
  final Widget submit;

  @override
  Widget build(BuildContext context) {
    final nights = Fmt.nights(checkIn, checkOut);
    final price = BookingProvider.calcPrice(type, nights, promo);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NetImage(type.coverImage, height: 150),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(hotel.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                RatingStars(hotel.stars),
                const SizedBox(height: 4),
                Text(hotel.address, style: AppTheme.subtitleStyle),
                const Divider(height: 28),
                InfoRow('Loại phòng', type.name),
                InfoRow('Nhận phòng', '${Fmt.dayLabel(checkIn)}/${checkIn.year}'),
                InfoRow('Trả phòng', '${Fmt.dayLabel(checkOut)}/${checkOut.year}'),
                InfoRow('Số đêm', '$nights đêm'),
                InfoRow('Số khách', '$guests khách'),
                const Divider(height: 28),
                InfoRow('Đơn giá', '${Fmt.vnd(type.pricePerNight)} / đêm'),
                InfoRow('Tiền phòng', Fmt.vnd(price.subtotal)),
                if (promo != null)
                  InfoRow('Giảm giá (${promo!.code})',
                      '-${Fmt.vnd(price.discount)}'),
                const Divider(height: 28),
                InfoRow('Tạm tính', Fmt.vnd(price.total), bold: true),
                const Text(
                  'Thanh toán khi trả phòng. Tiền dịch vụ sử dụng được cộng vào hóa đơn.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                if (available == 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Loại phòng này đã hết phòng trống.',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                if (type.maxGuests < guests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Phòng này tối đa ${type.maxGuests} khách.',
                        style: const TextStyle(color: AppColors.danger)),
                  ),
                SizedBox(height: 52, child: submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
