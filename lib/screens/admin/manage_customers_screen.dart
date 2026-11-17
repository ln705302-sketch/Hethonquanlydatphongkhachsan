import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/invoice.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/booking_detail_dialog.dart';
import 'customer_form_dialog.dart';
import 'reset_password_dialog.dart';
import 'widgets/admin_widgets.dart';

/// Quản lý khách hàng: lễ tân thêm / sửa, Quản lý khóa tài khoản
class ManageCustomersScreen extends StatefulWidget {
  const ManageCustomersScreen({super.key});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  String _query = '';

  Future<void> _openForm([User? customer]) async {
    final saved = await showDialog<User>(
      context: context,
      builder: (_) => CustomerFormDialog(customer: customer),
    );
    if (saved != null && mounted) {
      showSnack(context, customer == null ? 'Đã thêm khách hàng' : 'Đã cập nhật khách hàng');
    }
  }

  Future<void> _toggleLock(User u) async {
    final ok = await showConfirmDialog(
      context,
      title: u.isLocked ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?',
      message: u.isLocked
          ? '${u.fullName} sẽ có thể đăng nhập trở lại.'
          : '${u.fullName} sẽ không thể đăng nhập cho đến khi được mở khóa.',
      confirmText: u.isLocked ? 'Mở khóa' : 'Khóa',
      danger: !u.isLocked,
    );
    if (!ok || !mounted) return;
    final error = await context.read<AuthProvider>().toggleLock(u.id);
    if (!mounted) return;
    showSnack(context,
        error ?? (u.isLocked ? "Đã mở khóa tài khoản" : "Đã khóa tài khoản"),
        error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookings = context.watch<BookingProvider>();
    final q = Fmt.normalize(_query);
    final list = auth.customers
        .where((u) =>
            q.isEmpty ||
            Fmt.normalize('${u.fullName} ${u.email} ${u.phone} ${u.cccd}').contains(q))
        .toList();

    return AdminPage(
      title: 'Quản lý khách hàng',
      subtitle: '${auth.customers.length} khách hàng',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm khách hàng'),
        ),
        AdminSearchField(
            hint: 'Tên, email, số điện thoại, CCCD...',
            onChanged: (v) => setState(() => _query = v)),
      ],
      children: [
        AdminTable(
          emptyText: 'Không tìm thấy khách hàng',
          columns: const ['Họ tên', 'Số điện thoại', 'CCCD', 'Email', 'Số đơn', 'Trạng thái', 'Thao tác'],
          rows: [
            for (final u in list)
              DataRow(cells: [
                DataCell(Text(u.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(u.phone)),
                DataCell(Text(u.cccd.isEmpty ? '-' : u.cccd)),
                DataCell(Text(u.email.isEmpty ? '-' : u.email)),
                DataCell(Text('${bookings.countByUser(u.id)}')),
                DataCell(u.isLocked
                    ? const TagChip('Đã khóa',
                        icon: Icons.lock, color: AppColors.danger, bg: AppColors.dangerLight)
                    : const TagChip('Hoạt động', icon: Icons.check)),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Lịch sử đặt phòng',
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _CustomerHistoryDialog(customer: u)),
                    icon: const Icon(Icons.history),
                  ),
                  IconButton(
                    tooltip: 'Sửa',
                    onPressed: () => _openForm(u),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  ),
                  IconButton(
                    tooltip: !u.hasAccount
                        ? 'Cấp tài khoản online'
                        : 'Đặt lại mật khẩu',
                    onPressed: () => showResetPasswordDialog(context, u),
                    icon: Icon(
                        !u.hasAccount
                            ? Icons.person_add_alt_outlined
                            : Icons.key_outlined,
                        color: AppColors.textSecondary),
                  ),
                  if (auth.isManager)
                    IconButton(
                      tooltip: u.isLocked ? 'Mở khóa' : 'Khóa',
                      onPressed: () => _toggleLock(u),
                      icon: Icon(u.isLocked ? Icons.lock_open : Icons.lock_outline,
                          color: u.isLocked ? AppColors.success : AppColors.danger),
                    ),
                ])),
              ]),
          ],
        ),
      ],
    );
  }
}

/// Lịch sử đặt phòng và tổng chi tiêu của một khách hàng
class _CustomerHistoryDialog extends StatelessWidget {
  const _CustomerHistoryDialog({required this.customer});

  final User customer;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();
    final list = prov.bookingsOfUser(customer.id);
    final spent = list.fold<double>(0, (sum, b) {
      final inv = prov.invoiceOf(b.id);
      return inv != null && inv.status == InvoiceStatus.paid ? sum + inv.total : sum;
    });

    return AlertDialog(
      title: Text('Lịch sử của ${customer.fullName}'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              TagChip('${list.length} đơn', icon: Icons.receipt_long_outlined),
              TagChip('Đã chi ${Fmt.vnd(spent)}', icon: Icons.payments_outlined),
              if (!customer.hasAccount)
                const TagChip('Khách tại quầy',
                    color: AppColors.textSecondary, bg: AppColors.background),
            ]),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Khách chưa có đơn nào',
                    textAlign: TextAlign.center, style: AppTheme.subtitleStyle),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(children: [
                    for (final b in list) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                            '${Fmt.bookingCode(b.id)} · Phòng ${b.roomNumber} (${b.roomTypeName})',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${Fmt.date(b.checkIn)} - ${Fmt.date(b.checkOut)}\n'
                            '${Fmt.vnd(b.totalPrice)} · ${b.status.label}'),
                        onTap: () => showBookingDetail(context, b),
                      ),
                      const Divider(height: 1),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
      ],
    );
  }
}
