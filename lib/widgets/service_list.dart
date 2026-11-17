import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../providers/hotel_provider.dart';
import 'common.dart';

/// Lưới các dịch vụ đang cung cấp
class ServiceList extends StatelessWidget {
  const ServiceList({super.key});

  static const _icons = {
    'sv-breakfast': Icons.free_breakfast_outlined,
    'sv-laundry': Icons.local_laundry_service_outlined,
    'sv-airport': Icons.airport_shuttle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final services = context.watch<HotelProvider>().activeServices;
    if (services.isEmpty) {
      return const Card(
        child: EmptyState(
          icon: Icons.room_service_outlined,
          title: 'Chưa có dịch vụ nào',
        ),
      );
    }
    return ResponsiveGrid(
      minItemWidth: 280,
      maxColumns: 3,
      children: [
        for (final s in services)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(_icons[s.id] ?? Icons.room_service_outlined,
                    color: AppColors.primary),
              ),
              title: Text(s.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${s.description}\n${Fmt.vnd(s.price)} / ${s.unit}'),
            ),
          ),
      ],
    );
  }
}
