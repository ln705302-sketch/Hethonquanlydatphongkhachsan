import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils/formatters.dart';

/// Hàng sao hạng khách sạn
class RatingStars extends StatelessWidget {
  const RatingStars(this.stars, {super.key, this.size = 16});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        stars,
        (_) => Icon(Icons.star_rounded, size: size, color: AppColors.star),
      ),
    );
  }
}

/// Huy hiệu điểm đánh giá: [8.9] Tuyệt vời · 1.234 đánh giá
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.large = false,
  });

  final double rating;
  final int? reviewCount;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: large ? 12 : 8, vertical: large ? 8 : 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: large ? 20 : 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Fmt.ratingLabel(rating),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: large ? 16 : 14,
                ),
              ),
              if (reviewCount != null)
                Text(
                  '${Fmt.count(reviewCount!)} đánh giá',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
