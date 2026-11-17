import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/validators.dart';
import '../../models/service.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'widgets/admin_widgets.dart';

/// Quản lý dịch vụ và đơn giá: chỉ Quản lý được vào
class ManageServicesScreen extends StatelessWidget {
  const ManageServicesScreen({super.key});

  Future<void> _openForm(BuildContext context, [HotelService? service]) async {
    final prov = context.read<HotelProvider>();
    final result = await showDialog<HotelService>(
      context: context,
      builder: (_) => _ServiceFormDialog(service: service),
    );
    if (result == null || !context.mounted) return;
    final error = await prov.saveService(result);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã lưu dịch vụ', error: error != null);
  }

  Future<void> _delete(BuildContext context, HotelService service) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa dịch vụ?',
      message: 'Dịch vụ đã phát sinh trong đơn thì không xóa được.',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<BookingProvider>().deleteService(service.id);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Đã xóa dịch vụ', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<HotelProvider>().services;
    return AdminPage(
      title: 'Quản lý dịch vụ',
      subtitle: '${services.length} dịch vụ',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm dịch vụ'),
        ),
      ],
      children: [
        AdminTable(
          emptyText: 'Chưa có dịch vụ nào',
          columns: const ['Dịch vụ', 'Mô tả', 'Đơn giá', 'Đơn vị', 'Trạng thái', 'Thao tác'],
          rows: [
            for (final s in services)
              DataRow(cells: [
                DataCell(Text(s.name,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(s.description)),
                DataCell(Text(Fmt.vnd(s.price))),
                DataCell(Text(s.unit)),
                DataCell(s.isActive
                    ? const TagChip('Hoạt động', icon: Icons.check)
                    : const TagChip('Ngừng',
                        color: AppColors.textSecondary, bg: AppColors.background)),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Sửa',
                    onPressed: () => _openForm(context, s),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => _delete(context, s),
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

class _ServiceFormDialog extends StatefulWidget {
  const _ServiceFormDialog({this.service});

  final HotelService? service;

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final HotelService? _s = widget.service;
  late final _name = TextEditingController(text: _s?.name);
  late final _description = TextEditingController(text: _s?.description);
  late final _price = TextEditingController(text: _s?.price.toStringAsFixed(0));
  late final _unit = TextEditingController(text: _s?.unit ?? 'Lần');
  late bool _active = _s?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _unit]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      HotelService(
        id: _s?.id ?? context.read<HotelProvider>().newId(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: double.parse(_price.text.trim()),
        unit: _unit.text.trim(),
        isActive: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_s == null ? 'Thêm dịch vụ' : 'Sửa dịch vụ'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Tên dịch vụ *'),
                  validator: (v) => Validators.required(v, 'Tên dịch vụ'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Đơn giá *', suffixText: '₫'),
                      validator: Validators.numRange(0, 100000000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unit,
                      decoration: const InputDecoration(labelText: 'Đơn vị tính *'),
                      validator: (v) => Validators.required(v, 'Đơn vị'),
                    ),
                  ),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang cung cấp'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
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
