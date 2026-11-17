import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feedback.dart';

/// Nhân viên đặt mật khẩu mới cho một tài khoản
Future<void> showResetPasswordDialog(BuildContext context, User user) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ResetPasswordDialog(user: user),
    );

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.user});

  final User user;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context
        .read<AuthProvider>()
        .resetPassword(widget.user.id, _password.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    Navigator.pop(context);
    showSnack(context, 'Đã đặt mật khẩu mới cho ${widget.user.fullName}');
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final noAccount = !u.hasAccount;
    return AlertDialog(
      title: Text(noAccount ? 'Cấp tài khoản online' : 'Đặt lại mật khẩu'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${u.fullName} · ${u.email.isEmpty ? 'chưa có email' : u.email}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                noAccount
                    ? 'Khách được tạo tại quầy chưa có mật khẩu. Sau khi đặt, '
                        'khách đăng nhập website bằng email trên.'
                    : 'Báo mật khẩu mới cho người dùng và nhắc họ đổi lại '
                        'trong trang Hồ sơ.',
                style: AppTheme.subtitleStyle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới *'),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Nhập lại mật khẩu *'),
                validator: Validators.confirm(() => _password.text),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: _save, child: const Text('Lưu mật khẩu')),
      ],
    );
  }
}
