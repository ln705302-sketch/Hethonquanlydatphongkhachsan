import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/hotel.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/booking_detail_dialog.dart';
import '../../widgets/feedback.dart';
import 'hotel_form_dialog.dart';
import 'widgets/admin_widgets.dart';

/// Thông tin khách sạn: chỉ Quản lý được sửa
class HotelInfoScreen extends StatelessWidget {
  const HotelInfoScreen({super.key});

  Future<void> _edit(BuildContext context, Hotel hotel) async {
    final prov = context.read<HotelProvider>();
    final result = await showDialog<Hotel>(
      context: context,
      builder: (_) => HotelFormDialog(hotel: hotel),
    );
    if (result == null || !context.mounted) return;
    final error = await prov.saveHotel(result);
    if (!context.mounted) return;
    showSnack(context, error ?? "Đã cập nhật thông tin khách sạn",
        error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final hotel = context.watch<HotelProvider>().hotel;
    return AdminPage(
      title: 'Thông tin khách sạn',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _edit(context, hotel),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Sửa thông tin'),
        ),
      ],
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              InfoRow('Tên khách sạn', hotel.name),
              InfoRow('Hạng sao', '${hotel.stars} sao'),
              InfoRow('Địa chỉ', '${hotel.address}, ${hotel.city}'),
              InfoRow('Hotline', hotel.phone),
              InfoRow('Email', hotel.email),
              InfoRow('Tiện nghi', [
                for (final key in hotel.amenities)
                  kHotelAmenities[key]?.label ?? key,
              ].join(', ')),
              InfoRow('Mô tả', hotel.description),
            ]),
          ),
        ),
      ],
    );
  }
}
