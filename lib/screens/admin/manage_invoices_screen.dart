import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/invoice.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'front_desk_dialogs.dart';
import 'widgets/admin_widgets.dart';

/// Danh sách hóa đơn: tìm kiếm, lọc theo trạng thái / ngày lập.
/// Hoàn tiền đặc biệt do Quản lý phê duyệt
class ManageInvoicesScreen extends StatefulWidget {
  const ManageInvoicesScreen({super.key});

  @override
  State<ManageInvoicesScreen> createState() => _ManageInvoicesScreenState();
}

class _ManageInvoicesScreenState extends State<ManageInvoicesScreen> {
  String _query = '';
  InvoiceStatus? _status;
  DateTimeRange? _range; // Lọc theo ngày lập

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
      initialDateRange: _range,
      helpText: 'Lọc theo ngày lập hóa đơn',
      saveText: 'Áp dụng',
    );
    if (r != null) setState(() => _range = r);
  }

  Future<void> _refund(Invoice i) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hoàn tiền hóa đơn ${Fmt.invoiceCode(i.id)}?',
      message: 'Hóa đơn sẽ không còn được tính vào doanh thu.',
      confirmText: 'Hoàn tiền',
      danger: true,
    );
    if (!ok || !mounted) return;
    final staff = context.read<AuthProvider>().currentUser!;
    final error = await context.read<BookingProvider>().refund(i.id, staff);
    if (!mounted) return;
    showSnack(context, error ?? 'Đã hoàn tiền', error: error != null);
  }

  List<Invoice> _filter(BookingProvider prov) {
    final q = Fmt.normalize(_query);
    return prov.invoices.where((i) {
      if (_status != null && i.status != _status) return false;
      final day = Fmt.dateOnly(i.createdAt);
      if (_range != null &&
          (day.isBefore(_range!.start) || day.isAfter(_range!.end))) {
        return false;
      }
      if (q.isEmpty) return true;
      final b = prov.bookingById(i.bookingId);
      return Fmt.normalize(
              '${Fmt.invoiceCode(i.id)} ${Fmt.bookingCode(i.bookingId)} '
              '${b?.guestName ?? ''} ${b?.guestPhone ?? ''} ${b?.roomNumber ?? ''}')
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();
    final isManager = context.watch<AuthProvider>().isManager;
    final list = _filter(prov);
    final paidTotal = list
        .where((i) => i.status == InvoiceStatus.paid)
        .fold<double>(0, (sum, i) => sum + i.total);

    return AdminPage(
      title: 'Hóa đơn',
      subtitle: '${list.length} / ${prov.invoices.length} hóa đơn',
      actions: [
        AdminSearchField(
            hint: 'Mã hóa đơn, mã đơn, tên khách, SĐT...',
            onChanged: (v) => setState(() => _query = v)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: AppTheme.radius,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<InvoiceStatus?>(
              value: _status,
              dropdownColor: AppColors.white,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                for (final s in InvoiceStatus.values)
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
              ? 'Ngày lập'
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
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Tổng đã thanh toán (theo bộ lọc): '),
            TextSpan(
                text: Fmt.vnd(paidTotal),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 12),
        AdminTable(
          emptyText: 'Không có hóa đơn phù hợp',
          columns: const ['Mã hóa đơn', 'Ngày lập', 'Khách', 'Phòng', 'Tiền phòng', 'Dịch vụ', 'Tổng', 'Phương thức', 'Trạng thái', 'Thao tác'],
          rows: [
            for (final i in list)
              DataRow(cells: [
                DataCell(Text(Fmt.invoiceCode(i.id),
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(Fmt.date(i.createdAt))),
                DataCell(Text(prov.bookingById(i.bookingId)?.guestName ?? '-')),
                DataCell(Text(prov.bookingById(i.bookingId)?.roomNumber ?? '-')),
                DataCell(Text(Fmt.vnd(i.roomCharge))),
                DataCell(Text(Fmt.vnd(i.serviceCharge))),
                DataCell(Text(Fmt.vnd(i.total))),
                DataCell(Text(i.method.label)),
                DataCell(i.status == InvoiceStatus.paid
                    ? TagChip(i.status.label, icon: Icons.check)
                    : TagChip(i.status.label,
                        color: AppColors.danger, bg: AppColors.dangerLight)),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Xem hóa đơn',
                    onPressed: () => showInvoiceDialog(context, i),
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  if (isManager && i.status == InvoiceStatus.paid)
                    IconButton(
                      tooltip: 'Hoàn tiền',
                      onPressed: () => _refund(i),
                      icon: const Icon(Icons.undo, color: AppColors.danger),
                    ),
                ])),
              ]),
          ],
        ),
      ],
    );
  }
}
