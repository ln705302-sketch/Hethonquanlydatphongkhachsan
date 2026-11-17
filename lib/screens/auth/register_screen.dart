import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feedback.dart';
import 'auth_card.dart';

/// Đăng ký tài khoản khách hàng
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.from});

  final String? from;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AuthProvider>().register(
          fullName: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        );
    if (error == null) {
      messenger.showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Đăng ký thành công! Chào mừng bạn đến với Sunrise Hotel'),
      ));
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    showSnack(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final loginLink = Uri(
      path: '/login',
      queryParameters: widget.from == null ? null : {'from': widget.from},
    ).toString();

    return AuthCard(
      title: 'Tạo tài khoản',
      subtitle: 'Đăng ký để đặt phòng và quản lý đơn dễ dàng',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Họ và tên', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => Validators.required(v, 'Họ tên'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined)),
              validator: Validators.phone,
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _password,
              label: 'Mật khẩu (tối thiểu 6 ký tự)',
              validator: Validators.password,
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _confirm,
              label: 'Nhập lại mật khẩu',
              validator: Validators.confirm(() => _password.text),
              onSubmitted: _submit,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: LoadingButton(
                  label: 'Đăng ký', loading: _loading, onPressed: _submit),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Đã có tài khoản?'),
                TextButton(
                  onPressed: () => context.go(loginLink),
                  child: const Text('Đăng nhập'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
