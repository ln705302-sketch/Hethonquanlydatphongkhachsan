import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import '../../widgets/room_card.dart';
import '../../widgets/search_fields.dart';

/// Trang chọn phòng: /rooms?checkIn=&checkOut=&guests=
class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key, required this.query});

  final Map<String, String> query;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    // Đồng bộ điều kiện từ URL (hỗ trợ tải lại trang / chia sẻ link)
    context.read<SearchProvider>().applyQuery(widget.query);
  }

  @override
  void didUpdateWidget(covariant RoomsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.query, widget.query)) {
      context.read<SearchProvider>().applyQuery(widget.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final bookings = context.watch<BookingProvider>();
    final types = context.watch<HotelProvider>().activeRoomTypes;
    final wide = Breakpoints.isWide(context);

    final dateField = DateRangeField(
      checkIn: search.checkIn,
      checkOut: search.checkOut,
      onChanged: (r) => search.updateCriteria(checkIn: r.start, checkOut: r.end),
    );
    final guestField = GuestField(
      guests: search.guests,
      onChanged: (g) => search.updateCriteria(guests: g),
    );

    return AppScaffold(
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Chọn phòng',
                  subtitle:
                      'Giá và số phòng trống theo ngày bạn chọn. Mỗi đơn đặt một phòng.'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: wide
                      ? Row(children: [
                          Expanded(flex: 3, child: dateField),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: guestField),
                        ])
                      : Column(children: [
                          dateField,
                          const SizedBox(height: 10),
                          guestField,
                        ]),
                ),
              ),
              const SizedBox(height: 16),
              if (types.isEmpty)
                const Card(
                  child: EmptyState(
                    icon: Icons.meeting_room_outlined,
                    title: 'Khách sạn chưa mở bán loại phòng nào',
                  ),
                ),
              for (final type in types) ...[
                RoomCard(
                  type: type,
                  available: bookings.availableRooms(
                      type, search.checkIn, search.checkOut),
                  nights: search.nights,
                  guests: search.guests,
                  onBook: () => context.go(Uri(path: '/booking', queryParameters: {
                    'roomTypeId': type.id,
                    ...search.stayQuery,
                  }).toString()),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
