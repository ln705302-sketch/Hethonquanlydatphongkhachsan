/// Loại phòng (bảng LoaiPhong): Standard, Deluxe, Suite...
class RoomType {
  const RoomType({
    required this.id,
    required this.name,
    this.description = '',
    required this.bedType,
    required this.maxGuests,
    required this.area,
    required this.pricePerNight,
    required this.images,
    required this.amenities,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final String bedType;
  final int maxGuests; // Số khách tối đa / phòng
  final double area; // m²
  final double pricePerNight;
  final List<String> images;
  final List<String> amenities;
  final bool isActive; // false = ngừng kinh doanh

  String get coverImage => images.isNotEmpty ? images.first : '';

  factory RoomType.fromJson(Map<String, dynamic> json) => RoomType(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        bedType: json['bedType'] as String,
        maxGuests: json['maxGuests'] as int,
        area: (json['area'] as num).toDouble(),
        pricePerNight: (json['pricePerNight'] as num).toDouble(),
        images: List<String>.from(json['images'] as List? ?? const []),
        amenities: List<String>.from(json['amenities'] as List? ?? const []),
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'bedType': bedType,
        'maxGuests': maxGuests,
        'area': area,
        'pricePerNight': pricePerNight,
        'images': images,
        'amenities': amenities,
        'isActive': isActive,
      };
}
