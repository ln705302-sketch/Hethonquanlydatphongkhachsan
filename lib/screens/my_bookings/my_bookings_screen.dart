import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import 'booking_tile.dart';

/// Đơn của tôi: tab theo trạng thái
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  /// null = Tất cả
  static const List<BookingStatus?> _tabs = [
    null,
    BookingStatus.booked,
    BookingStatus.checkedIn,
    BookingStatus.checkedOut,
    BookingStatus.cancelled,
  ];

  late final TabController _tabController =
      TabController(length: _tabs.length, vsync: this)
        ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final all = user == null
        ? <Booking>[]
        : context.watch<BookingProvider>().bookingsOfUser(user.id);
    final status = _tabs[_tabController.index];
    final list =
        status == null ? all : all.where((b) => b.status == status).toList();

    return AppScaffold(
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Đơn của tôi',
                  subtitle: 'Quản lý các đơn đặt phòng của bạn'),
              Card(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: AppColors.transparent,
                  tabs: [
                    for (final s in _tabs)
                      Tab(
                        text:
                            '${s?.label ?? 'Tất cả'} (${s == null ? all.length : all.where((b) => b.status == s).length})',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Card(
                  child: EmptyState(
                    icon: Icons.luggage_outlined,
                    title: 'Chưa có đơn đặt phòng nào',
                    message: 'Hãy chọn phòng cho kỳ nghỉ sắp tới tại Sunrise Hotel!',
                    action: ElevatedButton(
                      style: AppTheme.ctaButton,
                      onPressed: () => context.go('/rooms'),
                      child: const Text('Chọn phòng'),
                    ),
                  ),
                )
              else
                for (final b in list) ...[
                  BookingTile(booking: b),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
