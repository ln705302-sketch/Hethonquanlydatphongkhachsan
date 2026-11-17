import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_header.dart';

/// Mục menu sidebar quản trị
class _NavItem {
  const _NavItem(this.label, this.icon, this.path, {this.managerOnly = false});
  final String label;
  final IconData icon;
  final String path;
  final bool managerOnly;
}

const _items = [
  _NavItem('Tổng quan', Icons.dashboard_outlined, '/admin'),
  _NavItem('Đặt phòng', Icons.receipt_long_outlined, '/admin/bookings'),
  _NavItem('Phòng', Icons.meeting_room_outlined, '/admin/rooms'),
  _NavItem('Khách hàng', Icons.people_outline, '/admin/customers'),
  _NavItem('Hóa đơn', Icons.request_quote_outlined, '/admin/invoices'),
  _NavItem('Báo cáo', Icons.bar_chart_outlined, '/admin/reports'),
  _NavItem('Loại phòng', Icons.category_outlined, '/admin/room-types',
      managerOnly: true),
  _NavItem('Dịch vụ', Icons.room_service_outlined, '/admin/services',
      managerOnly: true),
  _NavItem('Mã ưu đãi', Icons.local_offer_outlined, '/admin/promotions',
      managerOnly: true),
  _NavItem('Đánh giá', Icons.reviews_outlined, '/admin/reviews',
      managerOnly: true),
  _NavItem('Nhân viên', Icons.badge_outlined, '/admin/staff', managerOnly: true),
  _NavItem('Khách sạn', Icons.apartment_outlined, '/admin/hotel',
      managerOnly: true),
];

/// Layout riêng cho nhân viên: sidebar + nội dung (drawer trên màn hình nhỏ)
class AdminLayout extends StatelessWidget {
  const AdminLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    final user = context.watch<AuthProvider>().currentUser;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            const SizedBox(width: 240, child: _Sidebar()),
            Expanded(
              child: Column(children: [
                _TopBar(
                    userName:
                        '${user?.fullName ?? ''} · ${user?.role.label ?? ''}'),
                Expanded(child: child),
              ]),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('${AppConstants.appName} Admin'),
        elevation: 1,
      ),
      drawer: const Drawer(child: _Sidebar(inDrawer: true)),
      body: child,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        const Text('Trang quản trị',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        const Icon(Icons.admin_panel_settings, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({this.inDrawer = false});

  final bool inDrawer;

  void _go(BuildContext context, String path) {
    if (inDrawer) Navigator.pop(context);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final isManager = context.watch<AuthProvider>().isManager;
    // Dùng Material (không phải Container) để highlight của ListTile hiển thị
    return Material(
      color: AppColors.footer,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppLogo(color: AppColors.white),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 16),
              child: Text('Quản trị khách sạn',
                  style: TextStyle(color: AppColors.footerMuted)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in _items)
                    if (!item.managerOnly || isManager)
                      _SidebarTile(
                        item: item,
                        selected: path == item.path,
                        onTap: () => _go(context, item.path),
                      ),
                ],
              ),
            ),
            const Divider(color: AppColors.footerDivider),
            _SidebarTile(
              item: const _NavItem('Về trang khách hàng', Icons.storefront_outlined, '/'),
              selected: false,
              onTap: () => _go(context, '/'),
            ),
            _SidebarTile(
              item: const _NavItem('Đăng xuất', Icons.logout, '/'),
              selected: false,
              onTap: () {
                final router = GoRouter.of(context);
                final auth = context.read<AuthProvider>();
                if (inDrawer) Navigator.pop(context);
                auth.logout();
                router.go('/');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile(
      {required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: AppColors.primary,
        selectedColor: AppColors.white,
        iconColor: AppColors.footerText,
        textColor: AppColors.footerText,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius),
        leading: Icon(item.icon),
        title: Text(item.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: onTap,
      ),
    );
  }
}
