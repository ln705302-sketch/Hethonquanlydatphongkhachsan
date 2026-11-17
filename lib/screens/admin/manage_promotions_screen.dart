import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/validators.dart';
import '../../models/promotion.dart';
import '../../providers/booking_provider.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'widgets/admin_widgets.dart';

/// Quản lý mã ưu đãi: chỉ Quản lý được vào
class ManagePromotionsScreen extends StatelessWidget {
  const ManagePromotionsScreen({super.key});

  Future<void> _openForm(BuildContext context, [Promotion? promo]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PromoFormDialog(promo: promo),
    );
    if (saved == true && context.mounted) {
      showSnack(context, promo == null ? 'Đã thêm mã ưu đãi' : 'Đã cập nhật mã ưu đãi');
    }
  }

  Future<void> _delete(BuildContext context, Promotion p) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa mã ${p.code}?',
      message: 'Khách sẽ không dùng được mã này nữa. Các đơn đã dùng mã '
          'vẫn giữ nguyên số tiền được giảm.',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<PromoProvider>().deletePromotion(p.code);
    if (!context.mounted) return;
    showSnack(context, error ?? "Đã xóa mã ${p.code}", error: error != null);
  }

  String _conditions(Promotion p) => [
        if (p.minNights > 1) 'Từ ${p.minNights} đêm',
        if (p.firstBookingOnly) 'Đơn đầu tiên',
      ].join(' · ');

  String _value(Promotion p) => [
        if (p.percent > 0) '${Fmt.quantity(p.percent)}%',
        if (p.fixedAmount > 0) Fmt.vnd(p.fixedAmount),
      ].join(' + ');

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PromoProvider>();
    final bookings = context.watch<BookingProvider>();
    final promos = prov.promotions;

    return AdminPage(
      title: 'Mã ưu đãi',
      subtitle: '${promos.length} mã · ${prov.activePromotions.length} đang áp dụng',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm mã ưu đãi'),
        ),
      ],
      children: [
        AdminTable(
          emptyText: 'Chưa có mã ưu đãi nào',
          columns: const ['Mã', 'Tên ưu đãi', 'Mức giảm', 'Điều kiện', 'Đã dùng', 'Trạng thái', 'Thao tác'],
          rows: [
            for (final p in promos)
              DataRow(cells: [
                DataCell(Text(p.code,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, overflow: TextOverflow.ellipsis),
                      Text(p.description,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )),
                DataCell(Text(_value(p))),
                DataCell(Text(_conditions(p).isEmpty ? '-' : _conditions(p))),
                DataCell(Text('${bookings.promoUsageCount(p.code)} đơn')),
                DataCell(p.isActive
                    ? const TagChip('Đang áp dụng', icon: Icons.check)
                    : const TagChip('Tạm ngừng',
                        color: AppColors.textSecondary, bg: AppColors.background)),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Sửa',
                    onPressed: () => _openForm(context, p),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  ),
                  IconButton(
                    tooltip: p.isActive ? 'Tạm ngừng' : 'Áp dụng lại',
                    onPressed: () async {
                      final error = await prov.toggleActive(p.code);
                      if (context.mounted && error != null) {
                        showSnack(context, error, error: true);
                      }
                    },
                    icon: Icon(
                        p.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        color: p.isActive ? AppColors.textSecondary : AppColors.success),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => _delete(context, p),
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

class _PromoFormDialog extends StatefulWidget {
  const _PromoFormDialog({this.promo});

  final Promotion? promo;

  @override
  State<_PromoFormDialog> createState() => _PromoFormDialogState();
}

class _PromoFormDialogState extends State<_PromoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Promotion? _p = widget.promo;
  late final _code = TextEditingController(text: _p?.code);
  late final _title = TextEditingController(text: _p?.title);
  late final _description = TextEditingController(text: _p?.description);
  late final _percent = TextEditingController(
      text: _p == null ? '0' : Fmt.quantity(_p.percent).replaceAll(',', '.'));
  late final _fixed =
      TextEditingController(text: (_p?.fixedAmount ?? 0).toStringAsFixed(0));
  late final _minNights = TextEditingController(text: '${_p?.minNights ?? 1}');
  late bool _firstOnly = _p?.firstBookingOnly ?? false;
  late bool _active = _p?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_code, _title, _description, _percent, _fixed, _minNights]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  bool _saving = false;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context.read<PromoProvider>().savePromotion(
          Promotion(
            code: _code.text,
            title: _title.text,
            description: _description.text,
            percent: _num(_percent),
            fixedAmount: _num(_fixed),
            minNights: int.parse(_minNights.text.trim()),
            firstBookingOnly: _firstOnly,
            isActive: _active,
          ),
          originalCode: _p?.code,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_p == null ? 'Thêm mã ưu đãi' : 'Sửa mã ${_p.code}'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      labelText: 'Mã *', hintText: 'VD: SUMMER20'),
                  validator: (v) => Validators.required(v, 'Mã'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Tên ưu đãi *'),
                  validator: (v) => Validators.required(v, 'Tên ưu đãi'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _percent,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Giảm theo %', suffixText: '%'),
                      validator: Validators.numRange(0, 100),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fixed,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Giảm số tiền', suffixText: '₫'),
                      validator: Validators.numRange(0, 100000000),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minNights,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Số đêm tối thiểu *'),
                  validator: Validators.intRange(1, 30),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Chỉ áp dụng cho đơn đầu tiên'),
                  value: _firstOnly,
                  onChanged: (v) => setState(() => _firstOnly = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang áp dụng'),
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
