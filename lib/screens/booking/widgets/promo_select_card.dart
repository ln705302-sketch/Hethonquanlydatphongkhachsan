import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/promotion.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/promo_provider.dart';

/// Card chọn mã ưu đãi đã lưu ở bước đặt phòng
class PromoSelectCard extends StatelessWidget {
  const PromoSelectCard({
    super.key,
    required this.userId,
    required this.nights,
    required this.selected,
    required this.onChanged,
  });

  final String userId;
  final int nights;
  final Promotion? selected;
  final ValueChanged<Promotion?> onChanged;

  @override
  Widget build(BuildContext context) {
    final promos = context.watch<PromoProvider>().savedOf(userId);
    final bookings = context.watch<BookingProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Mã ưu đãi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (promos.isEmpty)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Bạn chưa lưu mã nào.',
                      style: AppTheme.subtitleStyle),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Lưu mã ở trang chủ'),
                  ),
                ],
              ),
            for (final p in promos)
              _PromoTile(
                promo: p,
                error: bookings.promoError(p,
                    userId: userId, nights: nights),
                selected: selected?.code == p.code,
                onTap: () => onChanged(selected?.code == p.code ? null : p),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({
    required this.promo,
    required this.error,
    required this.selected,
    required this.onTap,
  });

  final Promotion promo;
  final String? error; // Lý do không dùng được
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: error == null ? onTap : null,
        borderRadius: AppTheme.radius,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.white,
            borderRadius: AppTheme.radius,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Icon(Icons.local_offer_outlined,
                color: error == null
                    ? AppColors.primary
                    : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${promo.code} · ${promo.title}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    error ?? promo.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: error == null
                          ? AppColors.textSecondary
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            if (error == null)
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
          ]),
        ),
      ),
    );
  }
}
