import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/room.dart';
import '../../models/room_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'widgets/admin_widgets.dart';

/// Danh sách phòng và trạng thái. Lễ tân chỉ xem, Quản lý thêm / sửa / xóa
class ManageRoomsScreen extends StatelessWidget {
  const ManageRoomsScreen({super.key});

  Future<void> _openForm(BuildContext context, [Room? room]) async {
    final prov = context.read<HotelProvider>();
    if (prov.roomTypes.isEmpty) {
      showSnack(context, 'Hãy thêm loại phòng trước', error: true);
      return;
    }
    final result = await showDialog<Room>(
      context: context,
      builder: (_) => _RoomFormDialog(room: room, types: prov.roomTypes),
    );
    if (result == null || !context.mounted) return;
    final error = await prov.saveRoom(result);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã lưu phòng ${result.number}',
        error: error != null);
  }

  Future<void> _delete(BuildContext context, Room room) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa phòng ${room.number}?',
      message: 'Phòng đã phát sinh đơn đặt phòng thì không xóa được.',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<BookingProvider>().deleteRoom(room.id);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã xóa phòng', error: error != null);
  }

  Widget _status(RoomStatus s) {
    final (fg, bg) = switch (s) {
      RoomStatus.available => (AppColors.success, AppColors.successLight),
      RoomStatus.occupied => (AppColors.primary, AppColors.primaryLight),
      RoomStatus.maintenance => (AppColors.warning, AppColors.warningLight),
      RoomStatus.retired => (AppColors.textSecondary, AppColors.background),
    };
    return TagChip(s.label, color: fg, bg: bg);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HotelProvider>();
    final isManager = context.watch<AuthProvider>().isManager;

    return AdminPage(
      title: 'Quản lý phòng',
      subtitle: '${prov.rooms.length} phòng',
      actions: [
        if (isManager)
          ElevatedButton.icon(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Thêm phòng'),
          ),
      ],
      children: [
        AdminTable(
          emptyText: 'Chưa có phòng nào',
          columns: [
            'Số phòng', 'Tầng', 'Loại phòng', 'Ghi chú', 'Trạng thái',
            if (isManager) 'Thao tác',
          ],
          rows: [
            for (final r in prov.rooms)
              DataRow(cells: [
                DataCell(Text(r.number,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text('${r.floor}')),
                DataCell(Text(prov.roomTypeById(r.typeId)?.name ?? '-')),
                DataCell(Text(r.note.isEmpty ? '-' : r.note)),
                DataCell(_status(r.status)),
                if (isManager)
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: 'Sửa',
                      onPressed: () => _openForm(context, r),
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    ),
                    IconButton(
                      tooltip: 'Xóa',
                      onPressed: () => _delete(context, r),
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

class _RoomFormDialog extends StatefulWidget {
  const _RoomFormDialog({this.room, required this.types});

  final Room? room;
  final List<RoomType> types;

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Room? _r = widget.room;
  late final _number = TextEditingController(text: _r?.number);
  late final _floor = TextEditingController(text: '${_r?.floor ?? 1}');
  late final _note = TextEditingController(text: _r?.note);
  late String _typeId = _r?.typeId ?? widget.types.first.id;
  late RoomStatus _status = _r?.status ?? RoomStatus.available;

  @override
  void dispose() {
    for (final c in [_number, _floor, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Room(
        id: _r?.id ?? context.read<HotelProvider>().newId(),
        typeId: _typeId,
        number: _number.text.trim(),
        floor: int.parse(_floor.text.trim()),
        note: _note.text.trim(),
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phòng đang có khách thì trạng thái do nhận / trả phòng quyết định
    final occupied = _status == RoomStatus.occupied;
    return AlertDialog(
      title: Text(_r == null ? 'Thêm phòng' : 'Sửa phòng ${_r.number}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _number,
                    decoration: const InputDecoration(labelText: 'Số phòng *'),
                    validator: (v) => Validators.required(v, 'Số phòng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _floor,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tầng *'),
                    validator: Validators.intRange(0, 200),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _typeId,
                decoration: const InputDecoration(labelText: 'Loại phòng *'),
                items: [
                  for (final t in widget.types)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: (v) => _typeId = v ?? _typeId,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RoomStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: [
                  for (final s in RoomStatus.values)
                    if (s != RoomStatus.occupied || occupied)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged:
                    occupied ? null : (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
}
