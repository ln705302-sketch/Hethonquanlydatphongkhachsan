import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../models/promotion.dart';
import '../../models/room_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'widgets/booking_summary.dart';
import 'widgets/guest_form.dart';
import 'widgets/promo_select_card.dart';

/// Trang đặt phòng: /booking?roomTypeId=&checkIn=&checkOut=&guests=
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key, required this.query});

  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final type =
        context.read<HotelProvider>().roomTypeById(query['roomTypeId'] ?? '');
    final checkIn = Fmt.parseIsoDate(query['checkIn']);
    final checkOut = Fmt.parseIsoDate(query['checkOut']);
    final guests = int.tryParse(query['guests'] ?? '') ?? 0;

    final valid = type != null &&
        type.isActive &&
        checkIn != null &&
        checkOut != null &&
        checkOut.isAfter(checkIn) &&
        guests > 0;

    if (!valid) {
      return AppScaffold(
        child: ContentWrap(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Thông tin đặt phòng không hợp lệ',
            message: 'Vui lòng chọn lại loại phòng.',
            action: ElevatedButton(
              onPressed: () => context.go('/rooms'),
              child: const Text('Chọn phòng'),
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      child: _BookingForm(
        type: type,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
      ),
    );
  }
}

class _BookingForm extends StatefulWidget {
  const _BookingForm({
    required this.type,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });

  final RoomType type;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  @override
  State<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<_BookingForm> {
  final _formKey = GlobalKey<FormState>();
  late final GuestFormControllers _controllers;
  PaymentMethod _payment = PaymentMethod.cash;
  Promotion? _promo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controllers = GuestFormControllers.fromUser(
        context.read<AuthProvider>().currentUser);
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  /// Xác nhận đặt phòng: validate -> kiểm tra phòng trống -> tạo đơn
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      showSnack(context, 'Vui lòng kiểm tra lại thông tin', error: true);
      return;
    }
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().currentUser!;
    final (booking, error) = await context.read<BookingProvider>().createBooking(
          userId: user.id,
          type: widget.type,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          guests: widget.guests,
          guestName: _controllers.name.text,
          guestPhone: _controllers.phone.text,
          guestEmail: _controllers.email.text,
          note: _controllers.note.text,
          paymentMethod: _payment,
          promo: _promo,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    showSnack(context, 'Đặt phòng thành công!');
    context.go('/booking/success/${booking!.id}');
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    final hotel = context.watch<HotelProvider>().hotel;
    final available = context
        .watch<BookingProvider>()
        .availableRooms(widget.type, widget.checkIn, widget.checkOut);
    final canBook = (available ?? 0) > 0 && widget.type.maxGuests >= widget.guests;

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuestInfoCard(controllers: _controllers),
          const SizedBox(height: 16),
          PromoSelectCard(
            userId: context.read<AuthProvider>().currentUser?.id ?? '',
            nights: Fmt.nights(widget.checkIn, widget.checkOut),
            selected: _promo,
            onChanged: (p) => setState(() => _promo = p),
          ),
          const SizedBox(height: 16),
          PaymentMethodCard(
            value: _payment,
            onChanged: (v) => setState(() => _payment = v),
          ),
        ],
      ),
    );
    final summary = BookingSummary(
      hotel: hotel,
      type: widget.type,
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      guests: widget.guests,
      available: available,
      promo: _promo,
      submit: LoadingButton(
        label: 'Xác nhận đặt phòng',
        icon: Icons.lock_outline,
        loading: _loading,
        style: AppTheme.ctaButton,
        onPressed: canBook ? _submit : null,
      ),
    );

    return ContentWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              IconButton(
                onPressed: () =>
                    context.go(context.read<SearchProvider>().roomsLocation),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text('Hoàn tất đặt phòng', style: AppTheme.titleStyle),
              ),
            ]),
            const SizedBox(height: 16),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: 24),
                  SizedBox(width: 380, child: summary),
                ],
              )
            else ...[
              summary,
              const SizedBox(height: 16),
              form,
            ],
          ],
        ),
      ),
    );
  }
}
