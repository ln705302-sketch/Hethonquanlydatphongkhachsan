import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/promotion.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/hotel_provider.dart';
import '../../../providers/promo_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/promo_card.dart';
import '../../../widgets/service_list.dart';

/// Section "Hạng phòng": bấm để xem phòng trống
class RoomTypeHighlights extends StatelessWidget {
  const RoomTypeHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    final types = context.watch<HotelProvider>().activeRoomTypes;
    void openRooms() =>
        context.go(context.read<SearchProvider>().roomsLocation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Hạng phòng',
          subtitle: 'Chọn hạng phòng phù hợp với kỳ nghỉ của bạn',
          trailing:
              TextButton(onPressed: openRooms, child: const Text('Đặt phòng →')),
        ),
        ResponsiveGrid(
          minItemWidth: 280,
          maxColumns: 3,
          children: [
            for (final t in types)
              HoverCard(
                onTap: openRooms,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NetImage(t.coverImage, height: 170),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${t.area.toStringAsFixed(0)} m² · Tối đa ${t.maxGuests} khách',
                              style: AppTheme.subtitleStyle),
                          const SizedBox(height: 8),
                          Text('${Fmt.vnd(t.pricePerNight)} / đêm',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cta)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Section "Dịch vụ"
class ServiceHighlights extends StatelessWidget {
  const ServiceHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Dịch vụ của khách sạn',
            subtitle: 'Lễ tân ghi nhận dịch vụ trong thời gian bạn lưu trú'),
        ServiceList(),
      ],
    );
  }
}

/// Section "Ưu đãi": bấm vào thẻ để lưu mã (cần đăng nhập)
class Promotions extends StatelessWidget {
  const Promotions({super.key});

  Future<void> _onTap(BuildContext context, Promotion promo) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      showSnack(context, 'Vui lòng đăng nhập để lưu mã ưu đãi', error: true);
      context.go('/login?from=/');
      return;
    }
    final promos = context.read<PromoProvider>();
    if (promos.isSaved(user.id, promo.code)) {
      context.go('/my-promos');
      return;
    }
    if (user.isStaff) {
      showSnack(context, "Mã ưu đãi dành cho tài khoản khách hàng", error: true);
      return;
    }
    final error = await promos.save(user.id, promo.code);
    if (!context.mounted) return;
    showSnack(
        context, error ?? "Đã lưu mã ${promo.code}. Hãy chọn mã này khi đặt phòng",
        error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final promos = context.watch<PromoProvider>();
    final list = promos.activePromotions;
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Ưu đãi dành cho bạn',
            subtitle: 'Bấm vào thẻ để lưu mã, sau đó chọn mã khi đặt phòng'),
        ResponsiveGrid(
          minItemWidth: 300,
          maxColumns: 3,
          children: [
            for (final p in list)
              Builder(builder: (context) {
                final saved = user != null && promos.isSaved(user.id, p.code);
                return PromoCard(
                  promo: p,
                  actionLabel: saved ? 'Đã lưu' : 'Lưu mã',
                  actionIcon: saved ? Icons.check : Icons.bookmark_add_outlined,
                  onTap: () => _onTap(context, p),
                );
              }),
          ],
        ),
      ],
    );
  }
}

/// Section lý do chọn Sunrise Hotel
class WhySunrise extends StatelessWidget {
  const WhySunrise({super.key});

  static const _items = [
    (Icons.verified_outlined, 'Giá công khai', 'Giá phòng niêm yết theo từng hạng'),
    (Icons.flash_on_outlined, 'Giữ phòng ngay', 'Đặt xong là phòng được giữ cho bạn'),
    (Icons.event_available_outlined, 'Hủy linh hoạt', 'Tự hủy đơn trước ngày nhận phòng'),
    (Icons.support_agent, 'Lễ tân 24/7', 'Luôn sẵn sàng giúp bạn'),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      minItemWidth: 240,
      children: [
        for (final i in _items)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(i.$1, color: AppColors.primary),
              ),
              title: Text(i.$2,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(i.$3),
            ),
          ),
      ],
    );
  }
}
