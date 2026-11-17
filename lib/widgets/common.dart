import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

/// Giới hạn chiều rộng nội dung (1200px) và căn giữa
class ContentWrap extends StatelessWidget {
  const ContentWrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gutter = Breakpoints.isMobile(context) ? 16.0 : 24.0;
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: child,
        ),
      ),
    );
  }
}

/// Ảnh mạng có placeholder khi đang tải / lỗi
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  Widget _placeholder(bool loading) => Container(
        width: width,
        height: height,
        color: AppColors.primaryLight,
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.hotel, color: AppColors.primary, size: 36),
      );

  @override
  Widget build(BuildContext context) {
    final image = url.isEmpty
        ? _placeholder(false)
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _placeholder(true),
            errorBuilder: (context, error, stack) => _placeholder(false),
          );
    return radius == null ? image : ClipRRect(borderRadius: radius!, child: image);
  }
}

/// Card có hiệu ứng hover (nổi lên + đổ bóng) trên web
class HoverCard extends StatefulWidget {
  const HoverCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: radius,
          border: Border.all(
            color: _hover ? AppColors.primary : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: _hover ? 18 : 4,
              offset: Offset(0, _hover ? 8 : 2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            child: ClipRRect(borderRadius: radius, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Lưới responsive: tự tính số cột theo chiều rộng
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 260,
    this.maxColumns = 4,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols =
          ((w + spacing) / (minItemWidth + spacing)).floor().clamp(1, maxColumns);
      final itemWidth = (w - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final c in children) SizedBox(width: itemWidth, child: c),
        ],
      );
    });
  }
}

/// Trạng thái rỗng (không có kết quả, không có đơn...)
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryLight,
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!,
                textAlign: TextAlign.center, style: AppTheme.subtitleStyle),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Tiêu đề section có phụ đề
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: AppTheme.subtitleStyle),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Nhãn nhỏ có màu (vd: "Miễn phí hủy", "Bao bữa sáng")
class TagChip extends StatelessWidget {
  const TagChip(this.label,
      {super.key, this.icon, this.color = AppColors.success, this.bg = AppColors.successLight});

  final String label;
  final IconData? icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
