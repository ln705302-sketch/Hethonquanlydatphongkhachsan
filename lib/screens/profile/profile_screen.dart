import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../auth/auth_card.dart';

/// Hồ sơ: sửa họ tên, SĐT và đổi mật khẩu
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const AppScaffold(child: SizedBox());
    final bookingCount = context.watch<BookingProvider>().countByUser(user.id);
    final wide = Breakpoints.isWide(context);

    final header = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: Text(
                user.initial,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: AppTheme.titleStyle),
                  Text(
                    '${user.email} · ${user.role.label}',
                    style: AppTheme.subtitleStyle,
                  ),
                  Text(
                    'Thành viên từ ${Fmt.date(user.createdAt)} · $bookingCount đơn đặt phòng',
                    style: AppTheme.subtitleStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return AppScaffold(
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 16),
              if (wide)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ProfileForm()),
                    SizedBox(width: 16),
                    Expanded(child: _PasswordForm()),
                  ],
                )
              else ...const [
                _ProfileForm(),
                SizedBox(height: 16),
                _PasswordForm(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm();

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: context.read<AuthProvider>().currentUser?.fullName,
  );
  late final _phone = TextEditingController(
    text: context.read<AuthProvider>().currentUser?.phone,
  );
  late final _cccd = TextEditingController(
    text: context.read<AuthProvider>().currentUser?.cccd,
  );
  late final _address = TextEditingController(
    text: context.read<AuthProvider>().currentUser?.address,
  );
  static const _genders = ['Nam', 'Nữ', 'Khác'];
  late String? _gender =
      _genders.contains(context.read<AuthProvider>().currentUser?.gender)
      ? context.read<AuthProvider>().currentUser?.gender
      : null;
  late DateTime? _birthDate = context
      .read<AuthProvider>()
      .currentUser
      ?.birthDate;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1920),
      lastDate: now,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Chọn ngày sinh',
    );
    if (d != null) setState(() => _birthDate = d);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _cccd.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<AuthProvider>().updateProfile(
      fullName: _name.text,
      phone: _phone.text,
      cccd: _cccd.text,
      address: _address.text,
      gender: _gender ?? '',
      birthDate: _birthDate,
    );
    if (!mounted) return;
    showSnack(
      context,
      error ?? 'Đã cập nhật thông tin cá nhân',
      error: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final email = me?.email ?? "";
    final isStaff = me?.isStaff ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Thông tin cá nhân'),
              TextFormField(
                initialValue: email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email (không thể thay đổi)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, 'Họ tên'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: Validators.phone,
              ),
              // Bảng NhanVien chỉ có họ tên và số điện thoại
              if (!isStaff) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cccd,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CCCD',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: Validators.cccd,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Giới tính',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: [
                    for (final g in _genders)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: AppTheme.radius,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      suffixIcon: _birthDate == null
                          ? null
                          : IconButton(
                              tooltip: 'Xóa ngày sinh',
                              onPressed: () =>
                                  setState(() => _birthDate = null),
                              icon: const Icon(Icons.clear, size: 18),
                            ),
                    ),
                    child: Text(
                      _birthDate == null ? 'Chưa chọn' : Fmt.date(_birthDate!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm();

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await context.read<AuthProvider>().changePassword(
      _old.text,
      _new.text,
    );
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    _formKey.currentState!.reset();
    for (final c in [_old, _new, _confirm]) {
      c.clear();
    }
    showSnack(context, 'Đổi mật khẩu thành công');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Đổi mật khẩu'),
              PasswordField(
                controller: _old,
                label: 'Mật khẩu hiện tại',
                validator: (v) => Validators.required(v, 'Mật khẩu hiện tại'),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _new,
                label: 'Mật khẩu mới',
                validator: Validators.password,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirm,
                label: 'Nhập lại mật khẩu mới',
                validator: Validators.confirm(() => _new.text),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Đổi mật khẩu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
