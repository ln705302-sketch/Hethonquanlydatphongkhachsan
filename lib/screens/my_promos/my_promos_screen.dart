import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/promo_card.dart';

/// Mã ưu đãi của tôi: danh sách mã đã lưu
class MyPromosScreen extends StatelessWidget {
  const MyPromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const AppScaffold(child: SizedBox());
    final promoProv = context.watch<PromoProvider>();
    final bookings = context.watch<BookingProvider>();
    final promos = promoProv.savedOf(user.id);

    return AppScaffold(
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Mã ưu đãi của tôi',
                  subtitle: 'Chọn mã ở bước đặt phòng để được giảm giá'),
              if (promos.isEmpty)
                Card(
                  child: EmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'Bạn chưa lưu mã ưu đãi nào',
                    message: 'Bấm vào thẻ ưu đãi ở trang chủ để lưu mã.',
                    action: ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Về trang chủ'),
                    ),
                  ),
                )
              else
                ResponsiveGrid(
                  minItemWidth: 340,
                  maxColumns: 2,
                  children: [
                    for (final p in promos)
                      Builder(builder: (context) {
                        final used = bookings.isPromoUsed(user.id, p.code);
                        return PromoCard(
                          promo: p,
                          actionLabel: used ? 'Đã sử dụng' : 'Dùng ngay',
                          actionIcon:
                              used ? Icons.check : Icons.arrow_forward,
                          onTap: used ? null : () => context.go('/rooms'),
                          onRemove: () async {
                            final error = await promoProv.remove(user.id, p.code);
                            if (!context.mounted) return;
                            showSnack(context, error ?? "Đã bỏ lưu mã ${p.code}",
                                error: error != null);
                          },
                        );
                      }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
