import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../models/hotel.dart';

/// Dialog sửa thông tin khách sạn. Trả về Hotel khi bấm Lưu
class HotelFormDialog extends StatefulWidget {
  const HotelFormDialog({super.key, required this.hotel});

  final Hotel hotel;

  @override
  State<HotelFormDialog> createState() => _HotelFormDialogState();
}

class _HotelFormDialogState extends State<HotelFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Hotel _h = widget.hotel;
  late final _name = TextEditingController(text: _h.name);
  late final _city = TextEditingController(text: _h.city);
  late final _address = TextEditingController(text: _h.address);
  late final _phone = TextEditingController(text: _h.phone);
  late final _email = TextEditingController(text: _h.email);
  late final _description = TextEditingController(text: _h.description);
  late final _images = TextEditingController(text: _h.images.join('\n'));
  late int _stars = _h.stars;
  late final Set<String> _amenities = {..._h.amenities};

  @override
  void dispose() {
    for (final c in [_name, _city, _address, _phone, _email, _description, _images]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final images = _images.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    Navigator.pop(
      context,
      Hotel(
        name: _name.text.trim(),
        city: _city.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        description: _description.text.trim(),
        stars: _stars,
        images: images,
        amenities: _amenities.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sửa thông tin khách sạn'),
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
                      decoration: const InputDecoration(labelText: 'Tên khách sạn *'),
                      validator: (v) => Validators.required(v, 'Tên khách sạn'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<int>(
                      initialValue: _stars,
                      decoration: const InputDecoration(labelText: 'Hạng sao'),
                      items: [
                        for (var s = 1; s <= 5; s++)
                          DropdownMenuItem(value: s, child: Text('$s ★')),
                      ],
                      onChanged: (v) => _stars = v ?? _stars,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Địa chỉ *'),
                  validator: (v) => Validators.required(v, 'Địa chỉ'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'Thành phố *'),
                  validator: (v) => Validators.required(v, 'Thành phố'),
                ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Hotline *'),
                      validator: (v) => Validators.required(v, 'Hotline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email *'),
                      validator: Validators.email,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Mô tả *', alignLabelWithHint: true),
                  validator: (v) => Validators.required(v, 'Mô tả'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _images,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Link ảnh (mỗi dòng 1 link) *',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => Validators.required(v, 'Ảnh'),
                ),
                const SizedBox(height: 16),
                const Text('Tiện nghi',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final e in kHotelAmenities.entries)
                    FilterChip(
                      avatar: Icon(e.value.icon, size: 16),
                      label: Text(e.value.label),
                      selected: _amenities.contains(e.key),
                      onSelected: (sel) => setState(() =>
                          sel ? _amenities.add(e.key) : _amenities.remove(e.key)),
                    ),
                ]),
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
