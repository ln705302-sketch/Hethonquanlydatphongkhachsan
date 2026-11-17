import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/search_provider.dart';
import 'search_fields.dart';

/// Hộp tìm phòng trống: ngày nhận - trả, số khách, nút Tìm phòng.
/// Giá trị được giữ cục bộ, chỉ ghi vào SearchProvider khi bấm tìm.
class SearchBox extends StatefulWidget {
  const SearchBox({super.key});

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _guests;

  @override
  void initState() {
    super.initState();
    final s = context.read<SearchProvider>();
    _checkIn = s.checkIn;
    _checkOut = s.checkOut;
    _guests = s.guests;
  }

  void _search() {
    final search = context.read<SearchProvider>()
      ..updateCriteria(checkIn: _checkIn, checkOut: _checkOut, guests: _guests);
    context.go(search.roomsLocation);
  }

  @override
  Widget build(BuildContext context) {
    final dates = DateRangeField(
      checkIn: _checkIn,
      checkOut: _checkOut,
      onChanged: (r) => setState(() {
        _checkIn = r.start;
        _checkOut = r.end;
      }),
    );
    final guests = GuestField(
      guests: _guests,
      onChanged: (g) => setState(() => _guests = g),
    );
    final button = SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        style: AppTheme.ctaButton,
        onPressed: _search,
        icon: const Icon(Icons.search),
        label: const Text('Tìm phòng'),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        // Màn hình rộng: 1 hàng ngang; hẹp: xếp dọc
        if (constraints.maxWidth >= Breakpoints.mobile) {
          return Row(
            children: [
              Expanded(flex: 4, child: dates),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: guests),
              const SizedBox(width: 10),
              button,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            dates,
            const SizedBox(height: 10),
            guests,
            const SizedBox(height: 12),
            button,
          ],
        );
      }),
    );
  }
}
