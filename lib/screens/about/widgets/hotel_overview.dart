import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/hotel_provider.dart';
import '../../../widgets/rating_stars.dart';

/// Thông tin chung: tên, sao, địa chỉ, điểm, giá từ, mô tả, tiện nghi
class HotelOverview extends StatelessWidget {
  const HotelOverview({super.key, required this.onSelectRoom});

  final VoidCallback onSelectRoom;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.isWide(context);
    final prov = context.watch<HotelProvider>();
    final hotel = prov.hotel;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(hotel.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            RatingStars(hotel.stars, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text('${hotel.address}, ${hotel.city}',
                style: AppTheme.subtitleStyle),
          ),
        ]),
        const SizedBox(height: 14),
        RatingBadge(
            rating: prov.rating, reviewCount: prov.reviewCount, large: true),
      ],
    );

    final priceBox = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        const Text('Giá từ', style: AppTheme.subtitleStyle),
        Text(Fmt.vnd(prov.minPrice),
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.cta)),
        const Text('/ đêm', style: AppTheme.subtitleStyle),
        const SizedBox(height: 10),
        ElevatedButton(
          style: AppTheme.ctaButton,
          onPressed: onSelectRoom,
          child: const Text('Chọn phòng'),
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: header), priceBox],
              )
            else ...[
              header,
              const SizedBox(height: 16),
              priceBox,
            ],
            const Divider(height: 36),
            const Text('Giới thiệu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(hotel.description, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 20),
            const Text('Tiện nghi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                for (final key in hotel.amenities)
                  if (kHotelAmenities[key] != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(kHotelAmenities[key]!.icon,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(kHotelAmenities[key]!.label),
                    ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
