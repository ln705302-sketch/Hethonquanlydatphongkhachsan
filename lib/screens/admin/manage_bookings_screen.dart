import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_detail_dialog.dart';
import '../../widgets/feedback.dart';
import 'desk_booking_dialog.dart';
import 'front_desk_dialogs.dart';
import 'widgets/admin_widgets.dart';

enum _Action { checkIn, services, checkOut, cancel }

/// Đặt phòng: tìm, lọc, đặt tại quầy, nhận phòng, dịch vụ, trả phòng, hủy
class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  String _query = '';
  BookingStatus? _status;
  DateTimeRange? _range; // Lọc theo ngày nhận phòng

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
      initialDateRange: _range,
      helpText: 'Lọc theo ngày nhận phòng',
      saveText: 'Áp dụng',
    );
    if (r != null) setState(() => _range = r);
  }

  Future<void> _cancel(Booking b) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hủy đơn ${Fmt.bookingCode(b.id)}?',
      message: 'Đơn sẽ chuyển sang trạng thái "Đã hủy" và trả lại lịch phòng.',
      confirmText: 'Hủy đơn',
      danger: true,
    );
    if (!ok || !mounted) return;
    final staff = context.read<AuthProvider>().currentUser!;
    final error = await context.read<BookingProvider>().cancelByStaff(b.id, staff);
    if (!mounted) return;
    showSnack(context, error ?? 'Đã hủy đơn', error: error != null);
  }

  void _run(Booking b, _Action action) {
    switch (action) {
      case _Action.checkIn:
        showDialog<void>(context: context, builder: (_) => CheckInDialog(booking: b));
      case _Action.services:
        showDialog<void>(context: context, builder: (_) => ServiceUsageDialog(booking: b));
      case _Action.checkOut:
        showDialog<void>(context: context, builder: (_) => CheckOutDialog(booking: b));
      case _Action.cancel:
        _cancel(b);
    }
  }

  /// Các thao tác hợp lệ với trạng thái hiện tại của đơn
  List<_Action> _actions(BookingProvider prov, Booking b) {
    final staff = context.read<AuthProvider>().currentUser!;
    return [
      if (prov.canCheckIn(b)) _Action.checkIn,
      if (b.status == BookingStatus.checkedIn) ...[
        _Action.services,
        _Action.checkOut,
      ],
      if (prov.canStaffCancel(b, staff)) _Action.cancel,
    ];
  }

  /// Áp dụng bộ lọc lên danh sách đơn
  List<Booking> _filter(List<Booking> all) {
    final q = Fmt.normalize(_query);
    return all.where((b) {
      if (_status != null && b.status != _status) return false;
      if (_range != null &&
          (b.checkIn.isBefore(_range!.start) || b.checkIn.isAfter(_range!.end))) {
        return false;
      }
      if (q.isEmpty) return true;
      return Fmt.normalize('${Fmt.bookingCode(b.id)} ${b.guestName} ${b.guestPhone} ${b.roomNumber}')
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();
    final list = _filter(prov.bookings);

    return AdminPage(
      title: 'Quản lý đặt phòng',
      subtitle: '${list.length} / ${prov.bookings.length} đơn',
      actions: [
        ElevatedButton.icon(
          onPressed: () => showDialog<void>(
              context: context, builder: (_) => const DeskBookingDialog()),
          icon: const Icon(Icons.add),
          label: const Text('Đặt tại quầy'),
        ),
        AdminSearchField(
            hint: 'Mã đơn, tên khách, SĐT, số phòng...',
            onChanged: (v) => setState(() => _query = v)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: AppTheme.radius,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BookingStatus?>(
              value: _status,
              dropdownColor: AppColors.white,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                for (final s in BookingStatus.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _pickRange,
          icon: const Icon(Icons.date_range),
          label: Text(_range == null
              ? 'Ngày nhận phòng'
              : '${Fmt.dateShort(_range!.start)} - ${Fmt.dateShort(_range!.end)}'),
        ),
        if (_range != null)
          IconButton(
            tooltip: 'Bỏ lọc ngày',
            onPressed: () => setState(() => _range = null),
            icon: const Icon(Icons.clear),
          ),
      ],
      children: [
        AdminTable(
          emptyText: 'Không có đơn phù hợp',
          columns: const ['Mã đơn', 'Khách', 'Phòng', 'Nhận - Trả', 'Tiền phòng', 'Trạng thái', 'Thao tác'],
          rows: [
            for (final b in list)
              DataRow(cells: [
                DataCell(Text(Fmt.bookingCode(b.id),
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.guestName),
                    Text(b.guestPhone,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                )),
                DataCell(Text('${b.roomNumber} · ${b.roomTypeName}')),
                DataCell(Text('${Fmt.date(b.checkIn)}\n${Fmt.date(b.checkOut)}')),
                DataCell(Text(Fmt.vnd(b.totalPrice))),
                DataCell(StatusChip(b.status)),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Xem chi tiết',
                    onPressed: () => showBookingDetail(context, b),
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  _ActionMenu(
                    actions: _actions(prov, b),
                    onSelected: (a) => _run(b, a),
                  ),
                ])),
              ]),
          ],
        ),
      ],
    );
  }
}

/// Menu thao tác: Nhận phòng / Dịch vụ / Trả phòng / Hủy đơn
class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.actions, required this.onSelected});

  final List<_Action> actions;
  final ValueChanged<_Action> onSelected;

  static const _labels = {
    _Action.checkIn: ('Nhận phòng', Icons.login),
    _Action.services: ('Ghi nhận dịch vụ', Icons.room_service_outlined),
    _Action.checkOut: ('Trả phòng & lập hóa đơn', Icons.logout),
    _Action.cancel: ('Hủy đơn', Icons.cancel_outlined),
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Action>(
      tooltip: actions.isEmpty ? 'Không có thao tác' : 'Thao tác',
      enabled: actions.isNotEmpty,
      icon: const Icon(Icons.more_vert),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final a in actions)
          PopupMenuItem(
            value: a,
            child: Row(children: [
              Icon(_labels[a]!.$2,
                  size: 20,
                  color: a == _Action.cancel
                      ? AppColors.danger
                      : AppColors.primary),
              const SizedBox(width: 10),
              Text(_labels[a]!.$1),
            ]),
          ),
      ],
    );
  }
}
