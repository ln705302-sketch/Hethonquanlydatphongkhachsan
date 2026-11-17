import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/validators.dart';
import '../../models/room_type.dart';

/// Dialog thêm / sửa loại phòng. Trả về RoomType khi bấm Lưu
class RoomTypeFormDialog extends StatefulWidget {
  const RoomTypeFormDialog({super.key, this.type});

  final RoomType? type;

  @override
  State<RoomTypeFormDialog> createState() => _RoomTypeFormDialogState();
}

class _RoomTypeFormDialogState extends State<RoomTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final RoomType? _t = widget.type;
  late final _name = TextEditingController(text: _t?.name);
  late final _description = TextEditingController(text: _t?.description);
  late final _bed = TextEditingController(text: _t?.bedType ?? '1 giường đôi');
  late final _guests = TextEditingController(text: '${_t?.maxGuests ?? 2}');
  late final _area = TextEditingController(text: _t?.area.toStringAsFixed(0) ?? '25');
  late final _price =
      TextEditingController(text: _t?.pricePerNight.toStringAsFixed(0));
  late final _images = TextEditingController(text: _t?.images.join('\n'));
  late final _amenities = TextEditingController(text: _t?.amenities.join(', '));
  late bool _active = _t?.isActive ?? true;

  List<TextEditingController> get _all =>
      [_name, _description, _bed, _guests, _area, _price, _images, _amenities];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _split(String text, Pattern sep) =>
      text.split(sep).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      RoomType(
        id: _t?.id ?? const Uuid().v4(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        bedType: _bed.text.trim(),
        maxGuests: int.parse(_guests.text.trim()),
        area: double.parse(_area.text.trim()),
        pricePerNight: double.parse(_price.text.trim()),
        images: _split(_images.text, '\n'),
        amenities: _split(_amenities.text, ','),
        isActive: _active,
      ),
    );
  }

  Widget _num(TextEditingController c, String label, String? Function(String?) v) =>
      Expanded(
        child: TextFormField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          validator: v,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t == null ? 'Thêm loại phòng' : 'Sửa loại phòng'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                          labelText: 'Tên loại phòng *',
                          hintText: 'Standard, Deluxe, Suite...'),
                      validator: (v) => Validators.required(v, 'Tên phòng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bed,
                      decoration: const InputDecoration(labelText: 'Loại giường *'),
                      validator: (v) => Validators.required(v, 'Loại giường'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _num(_guests, 'Số khách tối đa', Validators.intRange(1, 10)),
                  const SizedBox(width: 12),
                  _num(_area, 'Diện tích (m²)', Validators.numRange(5, 500)),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Giá mỗi đêm (VNĐ) *', suffixText: '₫'),
                  validator: Validators.numRange(50000, 100000000),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amenities,
                  decoration: const InputDecoration(
                      labelText: 'Tiện nghi phòng (cách nhau bởi dấu phẩy)',
                      hintText: 'Điều hòa, TV, Minibar'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _images,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Link ảnh (mỗi dòng 1 link)',
                      alignLabelWithHint: true),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang kinh doanh'),
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
