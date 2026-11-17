import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../models/room_type.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/search_fields.dart';
import 'customer_form_dialog.dart';

/// Lễ tân lập phiếu đặt phòng khi khách liên hệ trực tiếp
class DeskBookingDialog extends StatefulWidget {
  const DeskBookingDialog({super.key});

  @override
  State<DeskBookingDialog> createState() => _DeskBookingDialogState();
}

class _DeskBookingDialogState extends State<DeskBookingDialog> {
  final _note = TextEditingController();
  User? _customer;
  RoomType? _type;
  late DateTime _checkIn = Fmt.today;
  late DateTime _checkOut = Fmt.today.add(const Duration(days: 1));
  int _guests = 1;
  PaymentMethod _payment = PaymentMethod.cash;
  bool _loading = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _newCustomer() async {
    final user = await showDialog<User>(
        context: context, builder: (_) => const CustomerFormDialog());
    if (user != null) setState(() => _customer = user);
  }

  Future<void> _submit(User customer, RoomType type) async {
    setState(() => _loading = true);
    final staff = context.read<AuthProvider>().currentUser!;
    final (booking, error) = await context.read<BookingProvider>().createBooking(
          userId: customer.id,
          staffId: staff.id,
          type: type,
          checkIn: _checkIn,
          checkOut: _checkOut,
          guests: _guests,
          guestName: customer.fullName,
          guestPhone: customer.phone,
          guestEmail: customer.email,
          note: _note.text,
          paymentMethod: _payment,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    Navigator.pop(context);
    showSnack(context,
        'Đã đặt phòng ${booking!.roomNumber} · ${Fmt.bookingCode(booking.id)}');
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<AuthProvider>().customers;
    final types = context.watch<HotelProvider>().activeRoomTypes;
    final prov = context.watch<BookingProvider>();
    final type = _type ?? types.firstOrNull;
    final customer =
        customers.where((c) => c.id == _customer?.id).firstOrNull;
    final free = type == null ? 0 : prov.availableRooms(type, _checkIn, _checkOut);
    final fits = type != null && type.maxGuests >= _guests;

    return AlertDialog(
      title: const Text('Đặt phòng tại quầy'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<User>(
                    key: ValueKey(customer?.id),
                    initialValue: customer,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Khách hàng *'),
                    items: [
                      for (final c in customers)
                        DropdownMenuItem(
                          value: c,
                          child: Text('${c.fullName} - ${c.phone}',
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _customer = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Thêm khách mới',
                  onPressed: _newCustomer,
                  icon: const Icon(Icons.person_add_alt),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<RoomType>(
                initialValue: type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Loại phòng *'),
                items: [
                  for (final t in types)
                    DropdownMenuItem(
                      value: t,
                      child: Text('${t.name} - ${Fmt.vnd(t.pricePerNight)}/đêm'),
                    ),
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 12),
              DateRangeField(
                checkIn: _checkIn,
                checkOut: _checkOut,
                onChanged: (r) => setState(() {
                  _checkIn = r.start;
                  _checkOut = r.end;
                }),
              ),
              const SizedBox(height: 12),
              CounterRow(
                label: 'Số khách',
                value: _guests,
                min: 1,
                max: type?.maxGuests ?? 1,
                onChanged: (v) => setState(() => _guests = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _payment,
                decoration:
                    const InputDecoration(labelText: 'Dự kiến thanh toán'),
                items: [
                  for (final m in PaymentMethod.values)
                    DropdownMenuItem(value: m, child: Text(m.label)),
                ],
                onChanged: (v) => _payment = v ?? _payment,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
              const SizedBox(height: 12),
              if (free == null)
                const Text('Đang kiểm tra phòng trống...',
                    style: AppTheme.subtitleStyle)
              else
              Text(
                free == 0
                    ? 'Không còn phòng trống trong khoảng ngày này'
                    : 'Còn $free phòng trống',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: free == 0 ? AppColors.danger : AppColors.success,
                ),
              ),
              if (type != null && !fits)
                Text('Phòng này tối đa ${type.maxGuests} khách',
                    style: const TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        LoadingButton(
          label: 'Đặt phòng',
          loading: _loading,
          onPressed: customer != null && type != null && (free ?? 0) > 0 && fits
              ? () => _submit(customer, type)
              : null,
        ),
      ],
    );
  }
}
