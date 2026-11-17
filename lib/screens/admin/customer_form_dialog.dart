import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feedback.dart';

/// Dialog thêm / sửa khách hàng. Trả về User khi lưu thành công
class CustomerFormDialog extends StatefulWidget {
  const CustomerFormDialog({super.key, this.customer});

  final User? customer;

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  static const _genders = ['Nam', 'Nữ', 'Khác'];

  final _formKey = GlobalKey<FormState>();
  late final User? _c = widget.customer;
  late final _name = TextEditingController(text: _c?.fullName);
  late final _phone = TextEditingController(text: _c?.phone);
  late final _email = TextEditingController(text: _c?.email);
  late final _cccd = TextEditingController(text: _c?.cccd);
  late final _address = TextEditingController(text: _c?.address);
  late String? _gender = _genders.contains(_c?.gender) ? _c?.gender : null;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _cccd, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final (user, error) = await context.read<AuthProvider>().saveCustomer(
          id: _c?.id,
          fullName: _name.text,
          phone: _phone.text,
          email: _email.text,
          cccd: _cccd.text,
          address: _address.text,
          gender: _gender ?? '',
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    Navigator.pop(context, user);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_c == null ? 'Thêm khách hàng' : 'Sửa khách hàng'),
      content: SizedBox(
        width: 480,
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
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Số điện thoại *'),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cccd,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CCCD'),
                  validator: Validators.cccd,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? null
                      : Validators.email(v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                  items: [
                    for (final g in _genders)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: (v) => _gender = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
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
