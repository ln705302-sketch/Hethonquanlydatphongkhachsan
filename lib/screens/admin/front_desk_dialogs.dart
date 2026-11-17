import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/validators.dart';
import '../../models/booking.dart';
import '../../models/invoice.dart';
import '../../models/service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/booking_detail_dialog.dart';
import '../../widgets/feedback.dart';

/// Nhận phòng: đối chiếu thông tin khách, có thể đổi sang phòng cùng loại
class CheckInDialog extends StatefulWidget {
  const CheckInDialog({super.key, required this.booking});

  final Booking booking;

  @override
  State<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<CheckInDialog> {
  late final _options =
      context.read<BookingProvider>().checkInOptions(widget.booking);
  late String? _roomId = _options.any((r) => r.id == widget.booking.roomId)
      ? widget.booking.roomId
      : _options.firstOrNull?.id;

  bool _saving = false;

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final staff = context.read<AuthProvider>().currentUser!;
    final error = await context
        .read<BookingProvider>()
        .checkIn(widget.booking.id, staffId: staff.id, roomId: _roomId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    Navigator.pop(context);
    showSnack(context, 'Đã nhận phòng');
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return AlertDialog(
      title: Text('Nhận phòng ${Fmt.bookingCode(b.id)}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoRow('Khách', b.guestName),
            InfoRow('Điện thoại', b.guestPhone),
            InfoRow('Loại phòng', b.roomTypeName),
            InfoRow('Lưu trú', '${Fmt.date(b.checkIn)} - ${Fmt.date(b.checkOut)}'),
            const SizedBox(height: 12),
            if (_options.isEmpty)
              const Text('Không có phòng trống cùng loại để nhận.',
                  style: TextStyle(color: AppColors.danger))
            else
              DropdownButtonFormField<String>(
                initialValue: _roomId,
                decoration: const InputDecoration(labelText: 'Phòng nhận'),
                items: [
                  for (final r in _options)
                    DropdownMenuItem(
                        value: r.id, child: Text('${r.number} (tầng ${r.floor})')),
                ],
                onChanged: (v) => setState(() => _roomId = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ElevatedButton(
          onPressed: _roomId == null ? null : _submit,
          child: const Text('Xác nhận nhận phòng'),
        ),
      ],
    );
  }
}

/// Ghi nhận dịch vụ khách sử dụng trong thời gian lưu trú
class ServiceUsageDialog extends StatefulWidget {
  const ServiceUsageDialog({super.key, required this.booking});

  final Booking booking;

  @override
  State<ServiceUsageDialog> createState() => _ServiceUsageDialogState();
}

class _ServiceUsageDialogState extends State<ServiceUsageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  HotelService? _service;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _add(HotelService service) async {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.parse(_quantity.text.trim().replaceAll(',', '.'));
    final error = await context
        .read<BookingProvider>()
        .addService(widget.booking.id, service, quantity);
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    _quantity.text = '1';
  }

  Future<void> _remove(String usageId) async {
    final error = await context.read<BookingProvider>().removeUsage(usageId);
    if (mounted && error != null) showSnack(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<HotelProvider>().activeServices;
    final prov = context.watch<BookingProvider>();
    final usages = prov.usagesOf(widget.booking.id);
    final selected = _service ?? services.firstOrNull;

    return AlertDialog(
      title: Text('Dịch vụ phòng ${widget.booking.roomNumber}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<HotelService>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Dịch vụ'),
                  items: [
                    for (final s in services)
                      DropdownMenuItem(
                        value: s,
                        child: Text('${s.name} - ${Fmt.vnd(s.price)}/${s.unit}',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _service = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Số lượng', suffixText: selected?.unit),
                  validator: Validators.numRange(0.1, 1000),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: selected == null ? null : () => _add(selected),
                  icon: const Icon(Icons.add),
                  label: const Text('Ghi nhận'),
                ),
                const Divider(height: 28),
                if (usages.isEmpty)
                  const Text('Chưa có dịch vụ nào.',
                      style: AppTheme.subtitleStyle),
                for (final u in usages)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        '${u.serviceName} × ${Fmt.quantity(u.quantity)} ${u.unit}'),
                    subtitle: Text(Fmt.dateTime(u.date)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(Fmt.vnd(u.amount)),
                      IconButton(
                        tooltip: 'Xóa',
                        onPressed: () => _remove(u.id),
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
      ],
    );
  }
}

/// Trả phòng: xem bảng kê, thu tiền, lập hóa đơn
class CheckOutDialog extends StatefulWidget {
  const CheckOutDialog({super.key, required this.booking});

  final Booking booking;

  @override
  State<CheckOutDialog> createState() => _CheckOutDialogState();
}

class _CheckOutDialogState extends State<CheckOutDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Bill _bill = context.read<BookingProvider>().billFor(widget.booking);
  late final _paid =
      TextEditingController(text: _bill.total.toStringAsFixed(0));
  late PaymentMethod _method = widget.booking.paymentMethod;

  @override
  void dispose() {
    _paid.dispose();
    super.dispose();
  }

  double get _paidValue =>
      double.tryParse(_paid.text.trim().replaceAll(',', '.')) ?? 0;

  bool _saving = false;

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final staff = context.read<AuthProvider>().currentUser!;
    final (invoice, error) = await context.read<BookingProvider>().checkOut(
          widget.booking.id,
          staffId: staff.id,
          paidAmount: _paidValue,
          method: _method,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    final navigator = Navigator.of(context);
    navigator.pop();
    unawaited(showInvoiceDialog(navigator.context, invoice!));
  }

  @override
  Widget build(BuildContext context) {
    final b = _bill;
    return AlertDialog(
      title: Text('Trả phòng ${widget.booking.roomNumber}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoRow('Khách', widget.booking.guestName),
                InfoRow('Tiền phòng (${b.nights} đêm)', Fmt.vnd(b.roomCharge)),
                InfoRow('Tiền dịch vụ', Fmt.vnd(b.serviceCharge)),
                if (b.discount > 0)
                  InfoRow('Giảm giá', '-${Fmt.vnd(b.discount)}'),
                InfoRow('Tổng thanh toán', Fmt.vnd(b.total), bold: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: _method,
                  decoration:
                      const InputDecoration(labelText: 'Phương thức thanh toán'),
                  items: [
                    for (final m in PaymentMethod.values)
                      DropdownMenuItem(value: m, child: Text(m.label)),
                  ],
                  onChanged: (v) => _method = v ?? _method,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paid,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Tiền khách trả', suffixText: '₫'),
                  validator: Validators.numRange(b.total, 1000000000),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                InfoRow('Tiền thừa',
                    Fmt.vnd(_paidValue > b.total ? _paidValue - b.total : 0)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ElevatedButton(onPressed: _submit, child: const Text('Lập hóa đơn')),
      ],
    );
  }
}

/// Hiển thị một hóa đơn
Future<void> showInvoiceDialog(BuildContext context, Invoice invoice) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hóa đơn'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: invoiceRows(invoice),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
      ],
    ),
  );
}
