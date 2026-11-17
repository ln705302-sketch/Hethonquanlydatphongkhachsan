import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import 'common.dart';

/// Logo Sunrise Hotel, bấm để về trang chủ
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.color = AppColors.primary});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/'),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny, color: color, size: 30),
          const SizedBox(width: 6),
          Text(
            AppConstants.appName,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header cố định phía trên các trang khách hàng
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final compact = MediaQuery.sizeOf(context).width < 1000;
    final user = auth.currentUser;

    return Material(
      color: AppColors.white,
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: ContentWrap(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: AppLogo()),
              ),
              const SizedBox(width: 32),
              if (compact)
                const Spacer()
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                _NavLink(
                  label: 'Phòng',
                  icon: Icons.bed_outlined,
                  onTap: () => context
                      .go(context.read<SearchProvider>().roomsLocation),
                ),
                _NavLink(
                  label: 'Dịch vụ',
                  icon: Icons.room_service_outlined,
                  onTap: () => context.go('/services'),
                ),
                _NavLink(
                  label: 'Giới thiệu',
                  icon: Icons.apartment_outlined,
                  onTap: () => context.go('/about'),
                ),
                _NavLink(
                  label: 'Đơn của tôi',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.go('/my-bookings'),
                ),
                    ]),
                  ),
                ),
              if (user != null)
                _UserMenu(user: user, compact: compact)
              else if (compact)
                IconButton(
                  tooltip: 'Đăng nhập',
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.account_circle_outlined, size: 30),
                )
              else ...[
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Đăng nhập'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Đăng ký'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

/// Avatar + dropdown: Hồ sơ, Đơn của tôi, Quản trị, Đăng xuất
class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user, required this.compact});

  final User user;
  final bool compact;

  void _onSelected(BuildContext context, String value) {
    switch (value) {
      case 'rooms':
        context.go(context.read<SearchProvider>().roomsLocation);
      case 'logout':
        context.read<AuthProvider>().logout();
        context.go('/');
      default:
        context.go(value);
    }
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Tài khoản',
      offset: const Offset(0, 52),
      onSelected: (v) => _onSelected(context, v),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(user.email,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        const PopupMenuDivider(),
        if (compact) ...[
          _item('rooms', Icons.bed_outlined, 'Phòng'),
          _item('/services', Icons.room_service_outlined, 'Dịch vụ'),
          _item('/about', Icons.apartment_outlined, 'Giới thiệu'),
        ],
        _item('/profile', Icons.person_outline, 'Hồ sơ'),
        _item('/my-bookings', Icons.receipt_long_outlined, 'Đơn của tôi'),
        _item('/my-promos', Icons.local_offer_outlined, 'Mã ưu đãi của tôi'),
        if (user.isStaff)
          _item('/admin', Icons.admin_panel_settings_outlined, 'Quản trị'),
        const PopupMenuDivider(),
        _item('logout', Icons.logout, 'Đăng xuất'),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(user.initial,
                  style: const TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.w700)),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(user.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
