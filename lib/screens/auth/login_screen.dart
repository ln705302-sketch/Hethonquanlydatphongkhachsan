import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/feedback.dart';
import 'auth_card.dart';

/// Đăng nhập. Sau khi thành công router tự chuyển về trang [from]
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final error =
        await context.read<AuthProvider>().login(_email.text, _password.text);
    if (error == null) {
      // Router redirect sẽ chuyển trang, màn hình này bị hủy
      messenger.showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Đăng nhập thành công'),
      ));
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    showSnack(context, error, error: true);
  }

  /// Chưa có máy chủ gửi email nên hướng dẫn khách liên hệ lễ tân
  /// để được đặt lại mật khẩu (Quản trị → Khách hàng → Đặt lại mật khẩu)
  void _forgotPassword() {
    final hotel = context.read<HotelProvider>().hotel;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Vui lòng liên hệ lễ tân và cung cấp email đăng ký cùng số '
                  'điện thoại. Lễ tân sẽ xác minh và đặt mật khẩu mới cho bạn.'),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                title: Text('Hotline: ${hotel.phone}'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: Text('Email: ${hotel.email}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
        ],
      ),
    );
  }

  void _fillDemo(String email, String password) {
    _email.text = email;
    _password.text = password;
  }

  @override
  Widget build(BuildContext context) {
    final registerLink = Uri(
      path: '/register',
      queryParameters: widget.from == null ? null : {'from': widget.from},
    ).toString();

    return AuthCard(
      title: 'Đăng nhập',
      subtitle: widget.from == null
          ? 'Chào mừng bạn quay lại Sunrise Hotel'
          : 'Vui lòng đăng nhập để tiếp tục',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _password,
              label: 'Mật khẩu',
              validator: Validators.password,
              onSubmitted: _submit,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: LoadingButton(
                  label: 'Đăng nhập', loading: _loading, onPressed: _submit),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Chưa có tài khoản?'),
                TextButton(
                  onPressed: () => context.go(registerLink),
                  child: const Text('Đăng ký ngay'),
                ),
              ],
            ),
            const Divider(height: 28),
            const Text('Tài khoản demo (bấm để điền nhanh):',
                style: AppTheme.subtitleStyle),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(
                avatar: const Icon(Icons.person_outline, size: 18),
                label: const Text('Khách hàng'),
                onPressed: () => _fillDemo('an@example.com', 'user123'),
              ),
              ActionChip(
                avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Quản lý'),
                onPressed: () => _fillDemo('admin@sunrisehotel.local', 'admin123'),
              ),
              ActionChip(
                avatar: const Icon(Icons.support_agent, size: 18),
                label: const Text('Lễ tân'),
                onPressed: () => _fillDemo('letan01@sunrisehotel.local', 'letan123'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
