import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../widgets/common.dart';

/// Gallery: 1 ảnh lớn + lưới ảnh nhỏ, bấm để xem phóng to
class HotelGallery extends StatelessWidget {
  const HotelGallery({super.key, required this.images});

  final List<String> images;

  void _open(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (_) => _GalleryViewer(images: images, initialIndex: index),
    );
  }

  Widget _tile(BuildContext context, int i, {double? height}) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _open(context, i),
          child: NetImage(images[i],
              height: height, radius: BorderRadius.circular(8)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const NetImage('', height: 300);
    }
    final mobile = Breakpoints.isMobile(context);
    final thumbs = images.length > 1 ? images.sublist(1).take(4).toList() : <String>[];

    if (mobile || thumbs.isEmpty) {
      return Column(children: [
        SizedBox(height: 240, width: double.infinity, child: _tile(context, 0)),
        if (thumbs.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: thumbs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) =>
                  SizedBox(width: 100, child: _tile(context, i + 1)),
            ),
          ),
        ],
      ]);
    }

    return SizedBox(
      height: 400,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _tile(context, 0)),
          const SizedBox(width: 8),
          // Lưới 2x2 ảnh nhỏ
          Expanded(
            child: Column(children: [
              for (var row = 0; row < 2; row++) ...[
                if (row == 1) const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < 2; col++) ...[
                        if (col == 1) const SizedBox(width: 8),
                        Expanded(
                          child: row * 2 + col < thumbs.length
                              ? _tile(context, row * 2 + col + 1)
                              : const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

/// Xem ảnh phóng to, chuyển ảnh bằng mũi tên
class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.images.length - 1);
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Widget _arrow(IconData icon, VoidCallback? onPressed) => IconButton.filled(
        style: IconButton.styleFrom(
            backgroundColor: AppColors.white, foregroundColor: AppColors.textPrimary),
        onPressed: onPressed,
        icon: Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 680),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                child: NetImage(widget.images[i],
                    fit: BoxFit.contain, radius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Positioned(
            left: 8,
            child: _arrow(Icons.chevron_left, _index > 0 ? () => _go(-1) : null),
          ),
          Positioned(
            right: 8,
            child: _arrow(Icons.chevron_right,
                _index < widget.images.length - 1 ? () => _go(1) : null),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _arrow(Icons.close, () => Navigator.pop(context)),
          ),
          Positioned(
            bottom: 12,
            child: Text('${_index + 1} / ${widget.images.length}',
                style: const TextStyle(
                    color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
