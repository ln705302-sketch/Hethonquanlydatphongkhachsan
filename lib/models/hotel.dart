/// Thông tin của khách sạn duy nhất trong hệ thống: Sunrise Hotel
class Hotel {
  const Hotel({
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.email,
    required this.description,
    required this.stars,
    required this.images,
    required this.amenities,
  });

  final String name;
  final String city;
  final String address;
  final String phone;
  final String email;
  final String description;
  final int stars; // 1-5
  final List<String> images;
  final List<String> amenities; // key trong kHotelAmenities

  String get coverImage => images.isNotEmpty ? images.first : '';

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
        name: json['name'] as String,
        city: json['city'] as String,
        address: json['address'] as String,
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        description: json['description'] as String? ?? '',
        stars: json['stars'] as int,
        images: List<String>.from(json['images'] as List? ?? const []),
        amenities: List<String>.from(json['amenities'] as List? ?? const []),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'city': city,
        'address': address,
        'phone': phone,
        'email': email,
        'description': description,
        'stars': stars,
        'images': images,
        'amenities': amenities,
      };
}
