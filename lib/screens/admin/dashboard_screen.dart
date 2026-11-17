import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../data/app_reloader.dart';
import '../../widgets/booking_detail_dialog.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'widgets/admin_widgets.dart';

/// Tổng quan: tình trạng phòng, khách đến/đi hôm nay, đơn mới nhất
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Khôi phục toàn bộ dữ liệu mẫu (hữu ích khi demo / chấm bài)
  Future<void> _reset(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Khôi phục dữ liệu mẫu?',
      message:
          'Toàn bộ phòng, dịch vụ, đơn, hóa đơn, đánh giá và tài khoản sẽ trở về dữ liệu ban đầu.',
      confirmText: 'Khôi phục',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final reloader = context.read<AppReloader>();
    final error = await context.read<BookingProvider>().resetToSeed();
    if (error == null) await reloader.reloadAll();
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã khôi phục dữ liệu mẫu', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final hotels = context.watch<HotelProvider>();
    final bookings = context.watch<BookingProvider>();
    final isManager = context.watch<AuthProvider>().isManager;
    final latest = bookings.latest();
    final today = Fmt.today;

    return AdminPage(
      title: 'Tổng quan',
      subtitle: 'Tình hình hoạt động của khách sạn hôm nay',
      actions: [
        if (isManager)
          OutlinedButton.icon(
            onPressed: () => _reset(context),
            icon: const Icon(Icons.restore),
            label: const Text('Khôi phục dữ liệu mẫu'),
          ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 210,
          maxColumns: 3,
          children: [
            StatCard(
                label: 'Phòng trống',
                value: '${hotels.countRooms(RoomStatus.available)} / ${hotels.rooms.length}',
                icon: Icons.meeting_room,
                color: AppColors.success),
            StatCard(
                label: 'Đang có khách ở',
                value: '${hotels.countRooms(RoomStatus.occupied)}',
                icon: Icons.hotel,
                color: AppColors.primaryDark),
            StatCard(
                label: 'Đang bảo trì',
                value: '${hotels.countRooms(RoomStatus.maintenance)}',
                icon: Icons.build_outlined,
                color: AppColors.textSecondary),
            StatCard(
                label: 'Khách đến hôm nay',
                value: '${bookings.arrivals(today).length}',
                icon: Icons.login,
                color: AppColors.cta),
            StatCard(
                label: 'Khách đi hôm nay',
                value: '${bookings.departures(today).length}',
                icon: Icons.logout,
                color: AppColors.warning),
            if (isManager)
              StatCard(
                  label: 'Doanh thu',
                  value: Fmt.vnd(bookings.revenue()),
                  icon: Icons.payments,
                  color: AppColors.success),
          ],
        ),
        const SizedBox(height: 28),
        SectionTitle(
          'Đơn đặt phòng mới nhất',
          trailing: TextButton(
            onPressed: () => context.go('/admin/bookings'),
            child: const Text('Xem tất cả →'),
          ),
        ),
        AdminTable(
          columns: const ['Mã đơn', 'Khách', 'Phòng', 'Nhận - Trả', 'Tiền phòng', 'Trạng thái'],
          rows: [
            for (final b in latest)
              DataRow(
                onSelectChanged: (_) => showBookingDetail(context, b),
                cells: [
                  DataCell(Text(Fmt.bookingCode(b.id),
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(b.guestName)),
                  DataCell(Text('${b.roomNumber} · ${b.roomTypeName}')),
                  DataCell(Text('${Fmt.dateShort(b.checkIn)} - ${Fmt.dateShort(b.checkOut)}')),
                  DataCell(Text(Fmt.vnd(b.totalPrice))),
                  DataCell(StatusChip(b.status)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
