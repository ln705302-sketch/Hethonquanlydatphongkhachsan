import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/hotel_provider.dart';
import '../providers/search_provider.dart';
import 'app_header.dart';
import 'common.dart';
import 'feedback.dart';

/// Footer cuối trang khách hàng
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const _linkStyle = TextStyle(color: AppColors.footerText, height: 2);

  static const _helpLinks = {
    'Trung tâm trợ giúp': '/info/help',
    'Chính sách hủy phòng': '/info/cancellation',
    'Điều khoản sử dụng': '/info/terms',
    'Chính sách bảo mật': '/info/privacy',
  };

  /// Mở ứng dụng ngoài (gọi điện, email, bản đồ)
  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      showSnack(context, 'Không mở được liên kết này', error: true);
    }
  }

  Widget _column(String title, List<Widget> links) => SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 8),
            ...links,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hotel = context.watch<HotelProvider>().hotel;
    final address = '${hotel.address}, ${hotel.city}';
    return Container(
      color: AppColors.footer,
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      child: ContentWrap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 32,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AppLogo(color: AppColors.white),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Khách sạn 3 sao với các hạng phòng Standard, Deluxe, '
                        'Suite. Đặt phòng trực tiếp tại website.',
                        style: _linkStyle,
                      ),
                    ],
                  ),
                ),
                _column('Hỗ trợ', [
                  for (final e in _helpLinks.entries)
                    _FooterLink(e.key, () => context.go(e.value)),
                ]),
                _column('Khách sạn', [
                  _FooterLink(
                      'Phòng',
                      () => context
                          .go(context.read<SearchProvider>().roomsLocation)),
                  _FooterLink('Dịch vụ', () => context.go('/services')),
                  _FooterLink('Giới thiệu', () => context.go('/about')),
                ]),
                _column('Liên hệ', [
                  _FooterLink(
                      'Hotline: ${hotel.phone}',
                      () => _open(context,
                          Uri.parse('tel:${hotel.phone.replaceAll(' ', '')}'))),
                  _FooterLink('Email: ${hotel.email}',
                      () => _open(context, Uri.parse('mailto:${hotel.email}'))),
                  _FooterLink(
                    address,
                    () => _open(
                      context,
                      Uri.https('www.google.com', '/maps/search/', {
                        'api': '1',
                        'query': address,
                      }),
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.footerDivider),
            const SizedBox(height: 16),
            const Text(
              '© 2026 ${AppConstants.appName}. Đồ án môn học - dữ liệu mang tính minh họa.',
              style: TextStyle(color: AppColors.footerMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link trong footer: đổi màu và gạch chân khi di chuột vào
class _FooterLink extends StatefulWidget {
  const _FooterLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: AppFooter._linkStyle.copyWith(
            color: _hover ? AppColors.white : AppColors.footerText,
            decoration: _hover ? TextDecoration.underline : null,
            decorationColor: AppColors.white,
          ),
        ),
      ),
    );
  }
}

/// Khung trang khách hàng: header cố định + nội dung cuộn + footer
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child, this.scrollController});

  final Widget child;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(child: child),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Align(alignment: Alignment.bottomCenter, child: AppFooter()),
          ),
        ],
      ),
    );
  }
}
