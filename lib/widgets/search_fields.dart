import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';

/// Mở DateRangePicker (không cho chọn ngày quá khứ)
Future<DateTimeRange?> pickStayDates(
    BuildContext context, DateTime checkIn, DateTime checkOut) async {
  final today = Fmt.today;
  final range = await showDateRangePicker(
    context: context,
    firstDate: today,
    lastDate: today.add(const Duration(days: 365)),
    initialDateRange: DateTimeRange(
      start: checkIn.isBefore(today) ? today : checkIn,
      end: checkOut.isAfter(checkIn) ? checkOut : checkIn.add(const Duration(days: 1)),
    ),
    helpText: 'Chọn ngày nhận - trả phòng',
    saveText: 'Xong',
  );
  if (range == null) return null;
  // Nhận và trả cùng ngày -> tự động +1 đêm
  if (!range.end.isAfter(range.start)) {
    return DateTimeRange(
        start: range.start, end: range.start.add(const Duration(days: 1)));
  }
  return range;
}

/// Ô hiển thị ngày nhận - trả phòng
class DateRangeField extends StatelessWidget {
  const DateRangeField({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onChanged,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final ValueChanged<DateTimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final nights = Fmt.nights(checkIn, checkOut);
    return InkWell(
      borderRadius: AppTheme.radius,
      onTap: () async {
        final r = await pickStayDates(context, checkIn, checkOut);
        if (r != null) onChanged(r);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Nhận phòng - Trả phòng',
          prefixIcon: Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          '${Fmt.dayLabel(checkIn)}  →  ${Fmt.dayLabel(checkOut)}  ·  $nights đêm',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Ô số khách, bấm mở popup tăng/giảm
class GuestField extends StatelessWidget {
  const GuestField({
    super.key,
    required this.guests,
    required this.onChanged,
  });

  final int guests;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.white),
        surfaceTintColor: WidgetStatePropertyAll(AppColors.transparent),
      ),
      menuChildren: [
        _GuestPopup(guests: guests, onChanged: onChanged),
      ],
      builder: (context, controller, _) => InkWell(
        borderRadius: AppTheme.radius,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Số khách',
            prefixIcon: Icon(Icons.people_outline),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          child: Text('$guests khách', maxLines: 1),
        ),
      ),
    );
  }
}

class _GuestPopup extends StatefulWidget {
  const _GuestPopup({required this.guests, required this.onChanged});

  final int guests;
  final ValueChanged<int> onChanged;

  @override
  State<_GuestPopup> createState() => _GuestPopupState();
}

class _GuestPopupState extends State<_GuestPopup> {
  late int _guests = widget.guests;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 280,
        child: CounterRow(
          label: 'Số khách',
          subtitle: 'Người lớn & trẻ em',
          value: _guests,
          min: 1,
          max: AppConstants.maxGuests,
          onChanged: (v) {
            setState(() => _guests = v);
            widget.onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Dòng có nút - / + để tăng giảm số
class CounterRow extends StatelessWidget {
  const CounterRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String? subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: 36,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        IconButton.outlined(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}
