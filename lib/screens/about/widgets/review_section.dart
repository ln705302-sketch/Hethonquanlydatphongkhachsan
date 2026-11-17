import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/review.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/hotel_provider.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/rating_stars.dart';

/// Mục đánh giá: điểm trung bình, danh sách review, nút viết / sửa đánh giá
class ReviewSection extends StatelessWidget {
  const ReviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final hotelProv = context.watch<HotelProvider>();
    final reviews = hotelProv.reviews;
    final mine = user == null ? null : hotelProv.reviewOf(user.id);
    final canReview = user != null &&
        mine == null &&
        context.watch<BookingProvider>().hasCompletedStay(user.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Đánh giá của khách',
          trailing: canReview
              ? ElevatedButton.icon(
                  onPressed: () => showReviewDialog(context),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Viết đánh giá'),
                )
              : null,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingBadge(
                    rating: hotelProv.rating,
                    reviewCount: hotelProv.reviewCount,
                    large: true),
                if (!canReview && mine == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Chỉ khách đã trả phòng mới có thể viết đánh giá.',
                      style: AppTheme.subtitleStyle,
                    ),
                  ),
                if (mine != null && mine.isHidden)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Đánh giá của bạn đang bị ẩn do không phù hợp. '
                      'Bạn có thể sửa lại nội dung hoặc liên hệ khách sạn.',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                const Divider(height: 32),
                if (mine != null && mine.isHidden)
                  ReviewTile(review: mine, ownedByViewer: true),
                if (reviews.isEmpty)
                  const Text('Chưa có đánh giá nào.')
                else
                  for (final r in reviews)
                    ReviewTile(review: r, ownedByViewer: r.userId == user?.id),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Một đánh giá. Chủ đánh giá có nút sửa / xóa
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.ownedByViewer = false});

  final Review review;
  final bool ownedByViewer;

  Future<void> _delete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa đánh giá?',
      message: 'Bạn có thể viết lại đánh giá sau khi xóa.',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<HotelProvider>().deleteReview(review.id);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã xóa đánh giá', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final dateText = review.updatedAt == null
        ? Fmt.date(review.createdAt)
        : '${Fmt.date(review.createdAt)} · đã sửa ${Fmt.date(review.updatedAt!)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(review.userName.isEmpty ? '?' : review.userName[0],
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                        ownedByViewer
                            ? '${review.userName} (bạn)'
                            : review.userName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  TagChip(
                    '${review.score.toStringAsFixed(1)} · ${Fmt.ratingLabel(review.score)}',
                    color: AppColors.primary,
                    bg: AppColors.primaryLight,
                  ),
                ]),
                Text(dateText,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(review.comment, style: const TextStyle(height: 1.5)),
                if (ownedByViewer)
                  Wrap(spacing: 4, children: [
                    TextButton.icon(
                      onPressed: () => showReviewDialog(context, review: review),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Sửa'),
                    ),
                    TextButton.icon(
                      onPressed: () => _delete(context),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Xóa'),
                    ),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mở dialog viết mới hoặc sửa [review]
Future<void> showReviewDialog(BuildContext context, {Review? review}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ReviewDialog(review: review),
    );

/// Dialog viết / sửa đánh giá (điểm 1-10 + nhận xét)
class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({this.review});

  final Review? review;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _comment = TextEditingController(text: widget.review?.comment);
  late double _score = widget.review?.score.roundToDouble() ?? 9;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser!;
    final hotels = context.read<HotelProvider>();
    final existing = widget.review;
    setState(() => _saving = true);
    final error = existing == null
        ? await hotels.addReview(user: user, score: _score, comment: _comment.text)
        : await hotels.updateReview(existing.id, user.id,
            score: _score, comment: _comment.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    Navigator.pop(context);
    showSnack(context,
        existing == null ? 'Cảm ơn bạn đã đánh giá!' : 'Đã cập nhật đánh giá');
  }

  @override
  Widget build(BuildContext context) {
    final name = context.read<HotelProvider>().hotel.name;
    return AlertDialog(
      title: Text(widget.review == null ? 'Đánh giá $name' : 'Sửa đánh giá'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Điểm: ${_score.toStringAsFixed(0)}/10 · ${Fmt.ratingLabel(_score)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _score.clamp(1, 10),
                min: 1,
                max: 10,
                divisions: 9,
                label: _score.toStringAsFixed(0),
                onChanged: (v) => setState(() => _score = v),
              ),
              TextFormField(
                controller: _comment,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Nhận xét của bạn',
                    alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Nhận xét tối thiểu 10 ký tự'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
            onPressed: _submit,
            child: Text(widget.review == null ? 'Gửi đánh giá' : 'Lưu')),
      ],
    );
  }
}
