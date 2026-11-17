import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/booking_detail_dialog.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

/// Trang đặt phòng thành công, hiển thị mã đặt phòng
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final b = context.watch<BookingProvider>().bookingById(bookingId);
    // Chỉ chủ đơn hoặc nhân viên được xem
    final allowed = b != null && (b.userId == user?.id || user?.isStaff == true);

    return AppScaffold(
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: !allowed
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Không tìm thấy đơn đặt phòng',
                      action: ElevatedButton(
                        onPressed: () => context.go('/my-bookings'),
                        child: const Text('Đơn của tôi'),
                      ),
                    )
                  : _SuccessCard(booking: b),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.successLight,
              child: Icon(Icons.check_rounded, size: 44, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text('Đặt phòng thành công!', style: AppTheme.titleStyle),
            const SizedBox(height: 6),
            Text(
              'Phòng đã được giữ cho bạn. Hãy đến quầy lễ tân vào ngày nhận phòng.',
              textAlign: TextAlign.center,
              style: AppTheme.subtitleStyle,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppTheme.radius,
              ),
              child: Column(children: [
                const Text('Mã đặt phòng', style: AppTheme.subtitleStyle),
                SelectableText(
                  Fmt.bookingCode(b.id),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                StatusChip(b.status),
              ]),
            ),
            const SizedBox(height: 16),
            InfoRow('Phòng', '${b.roomNumber} (${b.roomTypeName})'),
            InfoRow('Thời gian',
                '${Fmt.date(b.checkIn)} - ${Fmt.date(b.checkOut)} (${b.nights} đêm)'),
            InfoRow('Dự kiến thanh toán', b.paymentMethod.label),
            if (b.promoCode != null)
              InfoRow('Mã ưu đãi', '${b.promoCode} (-${Fmt.vnd(b.discount)})'),
            InfoRow('Tiền phòng tạm tính', Fmt.vnd(b.totalPrice), bold: true),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Về trang chủ'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/my-bookings'),
                  child: const Text('Xem đơn của tôi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
