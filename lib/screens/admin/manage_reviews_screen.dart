import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/review.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'widgets/admin_widgets.dart';

enum _ReviewFilter {
  all('Tất cả'),
  visible('Đang hiển thị'),
  hidden('Đã ẩn');

  const _ReviewFilter(this.label);
  final String label;
}

/// Kiểm duyệt đánh giá: Quản lý ẩn / hiện / xóa đánh giá của khách
class ManageReviewsScreen extends StatefulWidget {
  const ManageReviewsScreen({super.key});

  @override
  State<ManageReviewsScreen> createState() => _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends State<ManageReviewsScreen> {
  String _query = '';
  _ReviewFilter _filter = _ReviewFilter.all;

  Future<void> _delete(Review r) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa đánh giá của ${r.userName}?',
      message: 'Đánh giá sẽ bị xóa vĩnh viễn và khách có thể viết lại.',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok || !mounted) return;
    final error = await context.read<HotelProvider>().deleteReview(r.id);
    if (!mounted) return;
    showSnack(context, error ?? "Đã xóa đánh giá", error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HotelProvider>();
    final all = prov.allReviews;
    final q = Fmt.normalize(_query);
    final list = all.where((r) {
      if (_filter == _ReviewFilter.visible && r.isHidden) return false;
      if (_filter == _ReviewFilter.hidden && !r.isHidden) return false;
      return q.isEmpty || Fmt.normalize('${r.userName} ${r.comment}').contains(q);
    }).toList();

    return AdminPage(
      title: 'Đánh giá của khách',
      subtitle: '${all.length} đánh giá · điểm trung bình '
          '${prov.rating.toStringAsFixed(1)} (${prov.reviewCount} đang hiển thị)',
      actions: [
        AdminSearchField(
            hint: 'Tên khách, nội dung...',
            onChanged: (v) => setState(() => _query = v)),
        SegmentedButton<_ReviewFilter>(
          showSelectedIcon: false,
          segments: [
            for (final f in _ReviewFilter.values)
              ButtonSegment(value: f, label: Text(f.label)),
          ],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first),
        ),
      ],
      children: [
        AdminTable(
          emptyText: 'Không có đánh giá phù hợp',
          columns: const ['Khách', 'Ngày', 'Điểm', 'Nhận xét', 'Trạng thái', 'Thao tác'],
          rows: [
            for (final r in list)
              DataRow(cells: [
                DataCell(Text(r.userName,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(Fmt.date(r.createdAt))),
                DataCell(Text(r.score.toStringAsFixed(1))),
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Text(r.comment,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                )),
                DataCell(r.isHidden
                    ? const TagChip('Đã ẩn',
                        icon: Icons.visibility_off,
                        color: AppColors.danger,
                        bg: AppColors.dangerLight)
                    : const TagChip('Hiển thị', icon: Icons.check)),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: r.isHidden ? 'Hiện lại' : 'Ẩn đánh giá',
                    onPressed: () async {
                      final error = await prov.toggleReviewHidden(r.id);
                      if (!context.mounted) return;
                      showSnack(
                          context,
                          error ??
                              (r.isHidden ? "Đã hiện lại đánh giá" : "Đã ẩn đánh giá"),
                          error: error != null);
                    },
                    icon: Icon(
                        r.isHidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.primary),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => _delete(r),
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                ])),
              ]),
          ],
        ),
      ],
    );
  }
}
