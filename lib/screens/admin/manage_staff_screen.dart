import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'reset_password_dialog.dart';
import 'widgets/admin_widgets.dart';

enum _StaffAction { edit, resetPassword, toggleLock }

/// Quản lý nhân viên: chỉ Quản lý được vào
class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  String _query = '';

  Future<void> _toggleLock(User u) async {
    final ok = await showConfirmDialog(
      context,
      title: u.isLocked ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?',
      message: '${u.fullName} (${u.role.label})',
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

  void _openForm([User? staff]) => showDialog<void>(
      context: context, builder: (_) => _StaffFormDialog(staff: staff));

  void _run(User u, _StaffAction a) {
    switch (a) {
      case _StaffAction.edit:
        _openForm(u);
      case _StaffAction.resetPassword:
        showResetPasswordDialog(context, u);
      case _StaffAction.toggleLock:
        _toggleLock(u);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final me = auth.currentUser;
    final q = Fmt.normalize(_query);
    final staff = auth.staff
        .where((u) =>
            q.isEmpty ||
            Fmt.normalize('${u.fullName} ${u.email} ${u.phone}').contains(q))
        .toList();

    return AdminPage(
      title: 'Quản lý nhân viên',
      subtitle: '${auth.staff.length} nhân viên',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm nhân viên'),
        ),
        AdminSearchField(
            hint: 'Tên, email, số điện thoại...',
            onChanged: (v) => setState(() => _query = v)),
      ],
      children: [
        AdminTable(
          emptyText: 'Không tìm thấy nhân viên',
          columns: const ['Họ tên', 'Email', 'Số điện thoại', 'Vai trò', 'Trạng thái', 'Thao tác'],
          rows: [
            for (final u in staff)
              DataRow(cells: [
                DataCell(Text(u.id == me?.id ? '${u.fullName} (bạn)' : u.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(u.email)),
                DataCell(Text(u.phone)),
                DataCell(Text(u.role.label)),
                DataCell(u.isLocked
                    ? const TagChip('Đã khóa',
                        icon: Icons.lock, color: AppColors.danger, bg: AppColors.dangerLight)
                    : const TagChip('Hoạt động', icon: Icons.check)),
                DataCell(PopupMenuButton<_StaffAction>(
                  tooltip: 'Thao tác',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (a) => _run(u, a),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _StaffAction.edit,
                      child: ListTile(
                          dense: true,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Sửa thông tin')),
                    ),
                    if (!u.isManager) ...[
                      const PopupMenuItem(
                        value: _StaffAction.resetPassword,
                        child: ListTile(
                            dense: true,
                            leading: Icon(Icons.key_outlined),
                            title: Text('Đặt lại mật khẩu')),
                      ),
                      PopupMenuItem(
                        value: _StaffAction.toggleLock,
                        child: ListTile(
                            dense: true,
                            leading: Icon(u.isLocked
                                ? Icons.lock_open
                                : Icons.lock_outline),
                            title: Text(u.isLocked ? 'Mở khóa' : 'Khóa')),
                      ),
                    ],
                  ],
                )),
              ]),
          ],
        ),
      ],
    );
  }
}

/// Thêm nhân viên mới hoặc sửa thông tin [staff]
class _StaffFormDialog extends StatefulWidget {
  const _StaffFormDialog({this.staff});

  final User? staff;

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final User? _s = widget.staff;
  late final _name = TextEditingController(text: _s?.fullName);
  late final _email = TextEditingController(text: _s?.email);
  late final _phone = TextEditingController(text: _s?.phone);
  final _password = TextEditingController();
  late UserRole _role = _s?.role ?? UserRole.receptionist;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final error = _s == null
        ? await auth.addStaff(
            fullName: _name.text,
            email: _email.text,
            phone: _phone.text,
            password: _password.text,
            role: _role,
          )
        : await auth.updateStaff(
            id: _s.id,
            fullName: _name.text,
            email: _email.text,
            phone: _phone.text,
            role: _role,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    Navigator.pop(context);
    showSnack(context, _s == null ? 'Đã thêm nhân viên' : 'Đã cập nhật nhân viên');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_s == null ? 'Thêm nhân viên' : 'Sửa thông tin nhân viên'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Họ và tên *'),
                  validator: (v) => Validators.required(v, 'Họ tên'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email đăng nhập *'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại *'),
                  validator: Validators.phone,
                ),
                if (_s == null) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu *'),
                    validator: Validators.password,
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                  items: const [
                    DropdownMenuItem(
                        value: UserRole.receptionist, child: Text('Lễ tân')),
                    DropdownMenuItem(
                        value: UserRole.manager, child: Text('Quản lý')),
                  ],
                  onChanged: (v) => _role = v ?? _role,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
}
