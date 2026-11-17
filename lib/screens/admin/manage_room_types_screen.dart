import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/room_type.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'room_type_form_dialog.dart';
import 'widgets/admin_widgets.dart';

/// Quản lý loại phòng và bảng giá: chỉ Quản lý được vào
class ManageRoomTypesScreen extends StatelessWidget {
  const ManageRoomTypesScreen({super.key});

  Future<void> _openForm(BuildContext context, [RoomType? type]) async {
    final prov = context.read<HotelProvider>();
    final result = await showDialog<RoomType>(
      context: context,
      builder: (_) => RoomTypeFormDialog(type: type),
    );
    if (result == null || !context.mounted) return;
    final error = await prov.saveRoomType(result);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã lưu loại phòng', error: error != null);
  }

  Future<void> _delete(BuildContext context, RoomType type) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa loại phòng?',
      message: 'Bạn chắc chắn muốn xóa "${type.name}"?',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<HotelProvider>().deleteRoomType(type.id);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã xóa loại phòng', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HotelProvider>();
    return AdminPage(
      title: 'Loại phòng & bảng giá',
      subtitle: '${prov.roomTypes.length} loại phòng',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm loại phòng'),
        ),
      ],
      children: [
        AdminTable(
          emptyText: 'Chưa có loại phòng nào',
          columns: const ['Loại phòng', 'Giường', 'Khách', 'Diện tích', 'Giá/đêm', 'Số phòng', 'Trạng thái', 'Thao tác'],
          rows: [
            for (final t in prov.roomTypes)
              DataRow(cells: [
                DataCell(Text(t.name,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(t.bedType)),
                DataCell(Text('${t.maxGuests}')),
                DataCell(Text('${t.area.toStringAsFixed(0)} m²')),
                DataCell(Text(Fmt.vnd(t.pricePerNight))),
                DataCell(Text('${prov.roomsOfType(t.id).length}')),
                DataCell(t.isActive
                    ? const TagChip('Hoạt động', icon: Icons.check)
                    : const TagChip('Ngừng',
                        color: AppColors.textSecondary, bg: AppColors.background)),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Sửa',
                    onPressed: () => _openForm(context, t),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => _delete(context, t),
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
