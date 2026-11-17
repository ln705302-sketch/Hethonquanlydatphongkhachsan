import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../models/booking.dart';
import '../../../models/user.dart';

/// Gom các controller của form thông tin khách
class GuestFormControllers {
  GuestFormControllers.fromUser(User? user)
      : name = TextEditingController(text: user?.fullName ?? ''),
        phone = TextEditingController(text: user?.phone ?? ''),
        email = TextEditingController(text: user?.email ?? ''),
        note = TextEditingController();

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController note;

  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    note.dispose();
  }
}

/// Card nhập thông tin người nhận phòng
class GuestInfoCard extends StatelessWidget {
  const GuestInfoCard({super.key, required this.controllers});

  final GuestFormControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Thông tin khách',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Vui lòng nhập đúng thông tin để khách sạn liên hệ',
                style: AppTheme.subtitleStyle),
            const SizedBox(height: 16),
            TextFormField(
              controller: controllers.name,
              decoration: const InputDecoration(
                  labelText: 'Họ và tên *', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => Validators.required(v, 'Họ tên'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers.phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        prefixIcon: Icon(Icons.phone_outlined)),
                    validator: Validators.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controllers.email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined)),
                    validator: Validators.email,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.note,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Yêu cầu đặc biệt (không bắt buộc)',
                hintText: 'VD: phòng tầng cao, nhận phòng muộn...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card chọn phương thức dự kiến. Khách thanh toán khi trả phòng
class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard(
      {super.key, required this.value, required this.onChanged});

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  static const _info = {
    PaymentMethod.cash: (Icons.payments_outlined,
        'Trả bằng tiền mặt tại quầy lễ tân khi trả phòng.'),
    PaymentMethod.bankTransfer: (Icons.account_balance_outlined,
        'Chuyển khoản tại quầy khi trả phòng, lễ tân cung cấp số tài khoản.'),
    PaymentMethod.card: (Icons.credit_card,
        'Quẹt thẻ tại quầy lễ tân khi trả phòng.'),
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Dự kiến thanh toán khi trả phòng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final m in PaymentMethod.values) ...[
              _PaymentTile(
                icon: _info[m]!.$1,
                title: m.label,
                description: _info[m]!.$2,
                selected: m == value,
                onTap: () => onChanged(m),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.white,
          borderRadius: AppTheme.radius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ]),
      ),
    );
  }
}
