import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/booking.dart';

/// Hiển thị SnackBar thành công / lỗi
void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: error ? AppColors.danger : AppColors.success,
      content: Row(
        children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline,
              color: AppColors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ));
}

/// Dialog xác nhận, trả về true nếu người dùng đồng ý
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Xác nhận',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Không'),
        ),
        ElevatedButton(
          style: danger ? AppTheme.dangerButton : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Chip trạng thái đơn đặt phòng
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      BookingStatus.booked => (AppColors.warning, AppColors.warningLight),
      BookingStatus.checkedIn => (AppColors.primary, AppColors.primaryLight),
      BookingStatus.checkedOut => (AppColors.success, AppColors.successLight),
      BookingStatus.cancelled => (AppColors.danger, AppColors.dangerLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/// Nút có trạng thái loading
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.style,
    this.icon,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}
