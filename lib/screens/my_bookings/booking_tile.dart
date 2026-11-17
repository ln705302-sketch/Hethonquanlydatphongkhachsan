import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_detail_dialog.dart';
import '../../widgets/feedback.dart';

/// Một đơn trong danh sách "Đơn của tôi"
class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking});

  final Booking booking;

  Future<void> _cancel(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hủy đơn đặt phòng?',
      message:
          'Bạn chắc chắn muốn hủy đơn ${Fmt.bookingCode(booking.id)}? Thao tác này không thể hoàn tác.',
      confirmText: 'Hủy đơn',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<BookingProvider>().cancelByCustomer(booking.id);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã hủy đơn thành công', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final prov = context.watch<BookingProvider>();
    final invoice = prov.invoiceOf(b.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('Phòng ${b.roomNumber} · ${b.roomTypeName}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              StatusChip(b.status),
            ]),
            const SizedBox(height: 4),
            Text('Mã đơn: ${Fmt.bookingCode(b.id)}',
                style: AppTheme.subtitleStyle),
            const SizedBox(height: 8),
            Wrap(spacing: 18, runSpacing: 6, children: [
              _meta(Icons.calendar_today_outlined,
                  '${Fmt.date(b.checkIn)} - ${Fmt.date(b.checkOut)} · ${b.nights} đêm'),
              _meta(Icons.people_outline, '${b.guests} khách'),
            ]),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(Fmt.vnd(invoice?.total ?? b.totalPrice),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cta)),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => showBookingDetail(context, b),
                  child: const Text('Chi tiết'),
                ),
                if (b.status == BookingStatus.checkedOut)
                  TextButton.icon(
                    onPressed: () => context.go('/about'),
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Đánh giá'),
                  ),
                if (prov.canCancel(b))
                  TextButton(
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () => _cancel(context),
                    child: const Text('Hủy đơn'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(child: Text(text)),
        ],
      );
}
