import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../models/booking.dart';
import '../models/invoice.dart';
import '../providers/booking_provider.dart';
import 'feedback.dart';

/// Một dòng nhãn - giá trị
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTheme.subtitleStyle),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                fontSize: bold ? 17 : 14,
                color: bold ? AppColors.cta : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hiển thị chi tiết một đơn đặt phòng, dịch vụ đã dùng và tiền
Future<void> showBookingDetail(BuildContext context, Booking b) {
  final prov = context.read<BookingProvider>();
  final usages = prov.usagesOf(b.id);
  final invoice = prov.invoiceOf(b.id);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(children: [
        Expanded(child: Text('Đơn ${Fmt.bookingCode(b.id)}')),
        StatusChip(b.status),
      ]),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoRow('Phòng', '${b.roomNumber} (${b.roomTypeName})'),
              InfoRow('Nhận phòng', Fmt.date(b.checkIn)),
              InfoRow('Trả phòng', Fmt.date(b.checkOut)),
              if (b.actualCheckIn != null)
                InfoRow('Nhận thực tế', Fmt.dateTime(b.actualCheckIn!)),
              if (b.actualCheckOut != null)
                InfoRow('Trả thực tế', Fmt.dateTime(b.actualCheckOut!)),
              InfoRow('Số đêm / khách', '${b.nights} đêm · ${b.guests} khách'),
              const Divider(height: 20),
              InfoRow('Người đặt', b.guestName),
              InfoRow('Điện thoại', b.guestPhone),
              if (b.guestEmail.isNotEmpty) InfoRow('Email', b.guestEmail),
              if (b.note.isNotEmpty) InfoRow('Ghi chú', b.note),
              InfoRow('Ngày đặt', Fmt.dateTime(b.createdAt)),
              if (usages.isNotEmpty) ...[
                const Divider(height: 20),
                for (final u in usages)
                  InfoRow('${u.serviceName} × ${Fmt.quantity(u.quantity)}',
                      Fmt.vnd(u.amount)),
              ],
              const Divider(height: 20),
              if (b.promoCode != null)
                InfoRow('Mã ưu đãi', '${b.promoCode} (-${Fmt.vnd(b.discount)})'),
              if (invoice != null)
                ...invoiceRows(invoice)
              else ...[
                InfoRow('Dự kiến thanh toán', b.paymentMethod.label),
                InfoRow('Tiền phòng dự kiến', Fmt.vnd(b.totalPrice), bold: true),
              ],
            ],
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

/// Các dòng tiền của một hóa đơn
List<Widget> invoiceRows(Invoice i) => [
      InfoRow('Mã hóa đơn', Fmt.invoiceCode(i.id)),
      InfoRow('Ngày lập', Fmt.dateTime(i.createdAt)),
      InfoRow('Tiền phòng (${i.nights} đêm)', Fmt.vnd(i.roomCharge)),
      InfoRow('Tiền dịch vụ', Fmt.vnd(i.serviceCharge)),
      if (i.discount > 0) InfoRow('Giảm giá', '-${Fmt.vnd(i.discount)}'),
      InfoRow('Khách trả', '${Fmt.vnd(i.paidAmount)} (${i.method.label})'),
      if (i.change > 0) InfoRow('Tiền thừa', Fmt.vnd(i.change)),
      InfoRow('Trạng thái', i.status.label),
      InfoRow('Tổng thanh toán', Fmt.vnd(i.total), bold: true),
    ];
