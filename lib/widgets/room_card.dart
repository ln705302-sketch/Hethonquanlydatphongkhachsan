import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../models/room_type.dart';
import 'common.dart';

/// Card loại phòng trên trang chọn phòng
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.type,
    required this.available,
    required this.nights,
    required this.guests,
    required this.onBook,
  });

  final RoomType type;
  final int? available; // Số phòng trống theo khoảng ngày (null = đang kiểm tra)
  final int nights;
  final int guests;
  final VoidCallback onBook;

  /// Lý do không đặt được (null = đặt được)
  String? get _blockReason {
    if (available == null) return "Đang kiểm tra phòng trống";
    if (available == 0) return "Hết phòng";
    if (type.maxGuests < guests) return 'Tối đa ${type.maxGuests} khách/phòng';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final image = NetImage(type.coverImage,
            width: wide ? 220 : double.infinity, height: wide ? 190 : 170);
        final info = _RoomInfo(type: type);
        final action = _RoomAction(
          type: type,
          available: available,
          nights: nights,
          blockReason: _blockReason,
          onBook: onBook,
          alignEnd: wide,
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              Expanded(
                  child:
                      Padding(padding: const EdgeInsets.all(16), child: info)),
              SizedBox(
                  width: 220,
                  child:
                      Padding(padding: const EdgeInsets.all(16), child: action)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            image,
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [info, const Divider(height: 24), action],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RoomInfo extends StatelessWidget {
  const _RoomInfo({required this.type});

  final RoomType type;

  Widget _spec(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(text),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(type.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (type.description.isNotEmpty)
          Text(type.description, style: AppTheme.subtitleStyle),
        const SizedBox(height: 10),
        _spec(Icons.bed_outlined, type.bedType),
        _spec(Icons.square_foot, '${type.area.toStringAsFixed(0)} m²'),
        _spec(Icons.person_outline, 'Tối đa ${type.maxGuests} khách'),
        const SizedBox(height: 4),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final a in type.amenities)
            TagChip(a,
                color: AppColors.textSecondary, bg: AppColors.background),
        ]),
      ],
    );
  }
}

class _RoomAction extends StatelessWidget {
  const _RoomAction({
    required this.type,
    required this.available,
    required this.nights,
    required this.blockReason,
    required this.onBook,
    required this.alignEnd,
  });

  final RoomType type;
  final int? available;
  final int nights;
  final String? blockReason;
  final VoidCallback onBook;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final total = type.pricePerNight * nights;
    final count = available ?? 0;
    final lowStock = count == 1;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(Fmt.vnd(type.pricePerNight),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.cta)),
        const Text('/ phòng / đêm', style: AppTheme.subtitleStyle),
        const SizedBox(height: 6),
        Text('Tổng $nights đêm: ${Fmt.vnd(total)}',
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text(
          available == null
              ? "Đang kiểm tra phòng trống..."
              : count == 0
                  ? "Hết phòng"
                  : "Còn $count phòng trống",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: available == null
                ? AppColors.textSecondary
                : count == 0 || lowStock
                    ? AppColors.danger
                    : AppColors.success,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: alignEnd ? null : double.infinity,
          child: ElevatedButton(
            style: AppTheme.ctaButton,
            onPressed: blockReason == null ? onBook : null,
            child: Text(blockReason ?? 'Đặt ngay'),
          ),
        ),
      ],
    );
  }
}
