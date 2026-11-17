import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/promotion.dart';

/// Thẻ mã ưu đãi, bấm vào thẻ để thực hiện [actionLabel]
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.promo,
    required this.actionLabel,
    required this.actionIcon,
    required this.onTap,
    this.onRemove,
  });

  final Promotion promo;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  static const _styles = {
    'SUNRISE15': (AppColors.primary, Icons.wb_sunny_outlined),
    'WEEKEND300': (AppColors.cta, Icons.weekend_outlined),
    'XINCHAO10': (AppColors.success, Icons.card_giftcard),
  };

  Widget _pill(Color color, List<Widget> children) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final (color, icon) =
        _styles[promo.code] ?? (AppColors.primary, Icons.local_offer_outlined);
    final radius = BorderRadius.circular(12);

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient:
              LinearGradient(colors: [color, color.withValues(alpha: 0.75)]),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 130),
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(promo.title,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(promo.description,
                        style: const TextStyle(color: AppColors.heroText)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _pill(color, [Text('Mã: ${promo.code}')]),
                      _pill(color, [
                        Icon(actionIcon, size: 15, color: color),
                        const SizedBox(width: 4),
                        Text(actionLabel),
                      ]),
                    ]),
                  ],
                ),
              ),
              if (onRemove == null)
                Icon(icon, size: 56, color: AppColors.heroText)
              else
                IconButton(
                  tooltip: 'Bỏ lưu mã',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: AppColors.white),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
