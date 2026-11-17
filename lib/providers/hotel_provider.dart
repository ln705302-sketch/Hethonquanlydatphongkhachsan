import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/api_client.dart';
import '../models/hotel.dart';
import '../models/review.dart';
import '../models/room.dart';
import '../models/room_type.dart';
import '../models/service.dart';
import '../models/user.dart';

/// Danh mục: thông tin khách sạn, loại phòng, phòng, dịch vụ, đánh giá.
/// Dữ liệu tải từ server; các thao tác sửa gọi API rồi cập nhật bản sao.
class HotelProvider extends ChangeNotifier {
  HotelProvider(this._api);

  final ApiClient _api;

  /// Giá trị tạm trước khi tải xong
  Hotel _hotel = const Hotel(
    name: 'Sunrise Hotel',
    city: '',
    address: '',
    phone: '',
    email: '',
    description: '',
    stars: 3,
    images: [],
    amenities: [],
  );
  List<RoomType> _roomTypes = [];
  List<Room> _rooms = [];
  List<HotelService> _services = [];
  List<Review> _reviews = [];
  bool _loaded = false;
  String? _loadError;

  bool get isLoaded => _loaded;

  /// Lỗi lần tải gần nhất (VD không kết nối được server)
  String? get loadError => _loadError;

  Hotel get hotel => _hotel;
  List<RoomType> get roomTypes => [..._roomTypes]
    ..sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
  List<RoomType> get activeRoomTypes =>
      roomTypes.where((t) => t.isActive).toList();
  List<Room> get rooms =>
      [..._rooms]..sort((a, b) => a.number.compareTo(b.number));
  List<HotelService> get services => List.unmodifiable(_services);
  List<HotelService> get activeServices =>
      _services.where((s) => s.isActive).toList();

  /// Tất cả đánh giá server trả về (Quản lý: cả đánh giá bị ẩn;
  /// khách: thêm đánh giá bị ẩn của chính mình), mới nhất trước
  List<Review> get allReviews =>
      [..._reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Đánh giá hiển thị công khai
  List<Review> get reviews => allReviews.where((r) => !r.isHidden).toList();

  static List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) f) =>
      [for (final e in data as List) f(e as Map<String, dynamic>)];

  /// Tải toàn bộ danh mục
  Future<void> load() async {
    try {
      final results = await Future.wait([
        _api.get('/hotel'),
        _api.get('/room-types'),
        _api.get('/rooms'),
        _api.get('/services'),
        _api.get('/reviews'),
      ]);
      _hotel = Hotel.fromJson(results[0] as Map<String, dynamic>);
      _roomTypes = _list(results[1], RoomType.fromJson);
      _rooms = _list(results[2], Room.fromJson);
      _services = _list(results[3], HotelService.fromJson);
      _reviews = _list(results[4], Review.fromJson);
      _loaded = true;
      _loadError = null;
    } on ApiException catch (e) {
      _loadError = e.message;
    }
    notifyListeners();
  }

  /// Tải lại danh sách phòng (sau nhận / trả phòng)
  Future<void> loadRooms() async {
    try {
      _rooms = _list(await _api.get('/rooms'), Room.fromJson);
      notifyListeners();
    } on ApiException {
      // Bỏ qua, lần tải sau sẽ cập nhật
    }
  }

  /// Tải lại đánh giá (phụ thuộc người đang đăng nhập)
  Future<void> loadReviews() async {
    try {
      _reviews = _list(await _api.get('/reviews'), Review.fromJson);
      notifyListeners();
    } on ApiException {
      // Bỏ qua
    }
  }

  // ---------- Truy vấn ----------

  RoomType? roomTypeById(String id) =>
      _roomTypes.where((t) => t.id == id).firstOrNull;

  Room? roomById(String id) => _rooms.where((r) => r.id == id).firstOrNull;

  HotelService? serviceById(String id) =>
      _services.where((s) => s.id == id).firstOrNull;

  List<Room> roomsOfType(String typeId) =>
      rooms.where((r) => r.typeId == typeId).toList();

  int countRooms(RoomStatus status) =>
      _rooms.where((r) => r.status == status).length;

  /// Giá phòng thấp nhất đang kinh doanh
  double get minPrice {
    final list = activeRoomTypes;
    return list.isEmpty ? 0 : list.first.pricePerNight;
  }

  Iterable<Review> get _visible => _reviews.where((r) => !r.isHidden);

  int get reviewCount => _visible.length;

  /// Điểm trung bình từ các đánh giá đang hiển thị
  double get rating => reviewCount == 0
      ? 0
      : _visible.fold<double>(0, (sum, r) => sum + r.score) / reviewCount;

  bool hasReviewed(String userId) => _reviews.any((r) => r.userId == userId);

  Review? reviewOf(String userId) =>
      _reviews.where((r) => r.userId == userId).firstOrNull;

  /// Id tạm cho bản ghi mới (server sẽ cấp id thật)
  String newId() => 'new-${const Uuid().v4()}';

  bool _isNew(String id) => id.startsWith('new-');

  void _upsert<T>(List<T> list, T item, bool Function(T) same) {
    final i = list.indexWhere(same);
    i == -1 ? list.add(item) : list[i] = item;
  }

  // ---------- Thông tin khách sạn ----------

  Future<String?> saveHotel(Hotel hotel) => guard(() async {
        _hotel = Hotel.fromJson(
            await _api.put('/hotel', hotel.toJson()) as Map<String, dynamic>);
        notifyListeners();
      });

  // ---------- Loại phòng ----------

  Future<String?> saveRoomType(RoomType type) => guard(() async {
        final data = _isNew(type.id)
            ? await _api.post('/room-types', type.toJson())
            : await _api.put('/room-types/${type.id}', type.toJson());
        final saved = RoomType.fromJson(data as Map<String, dynamic>);
        _upsert(_roomTypes, saved, (t) => t.id == saved.id);
        notifyListeners();
      });

  /// Không được xóa loại phòng nếu vẫn còn phòng thuộc loại đó
  Future<String?> deleteRoomType(String id) => guard(() async {
        await _api.delete('/room-types/$id');
        _roomTypes.removeWhere((t) => t.id == id);
        notifyListeners();
      });

  // ---------- Phòng ----------

  Future<String?> saveRoom(Room room) => guard(() async {
        final data = _isNew(room.id)
            ? await _api.post('/rooms', room.toJson())
            : await _api.put('/rooms/${room.id}', room.toJson());
        final saved = Room.fromJson(data as Map<String, dynamic>);
        _upsert(_rooms, saved, (r) => r.id == saved.id);
        notifyListeners();
      });

  /// Phòng đã phát sinh trong đơn thì không xóa được (server kiểm tra)
  Future<String?> deleteRoom(String id) => guard(() async {
        await _api.delete('/rooms/$id');
        _rooms.removeWhere((r) => r.id == id);
        notifyListeners();
      });

  // ---------- Dịch vụ ----------

  Future<String?> saveService(HotelService service) => guard(() async {
        final data = _isNew(service.id)
            ? await _api.post('/services', service.toJson())
            : await _api.put('/services/${service.id}', service.toJson());
        final saved = HotelService.fromJson(data as Map<String, dynamic>);
        _upsert(_services, saved, (s) => s.id == saved.id);
        notifyListeners();
      });

  /// Dịch vụ đã phát sinh trong đơn thì không xóa được (server kiểm tra)
  Future<String?> deleteService(String id) => guard(() async {
        await _api.delete('/services/$id');
        _services.removeWhere((s) => s.id == id);
        notifyListeners();
      });

  // ---------- Đánh giá ----------

  Future<String?> addReview({
    required User user,
    required double score,
    required String comment,
  }) =>
      guard(() async {
        final data = await _api
            .post('/reviews', {'score': score, 'comment': comment.trim()});
        _reviews.add(Review.fromJson(data as Map<String, dynamic>));
        notifyListeners();
      });

  /// Khách sửa đánh giá của chính mình
  Future<String?> updateReview(String reviewId, String userId,
          {required double score, required String comment}) =>
      guard(() async {
        final data = await _api.put(
            '/reviews/$reviewId', {'score': score, 'comment': comment.trim()});
        final r = Review.fromJson(data as Map<String, dynamic>);
        _upsert(_reviews, r, (x) => x.id == r.id);
        notifyListeners();
      });

  /// Quản lý ẩn / hiện đánh giá
  Future<String?> toggleReviewHidden(String reviewId) => guard(() async {
        final data = await _api.post('/reviews/$reviewId/toggle-hidden');
        final r = Review.fromJson(data as Map<String, dynamic>);
        _upsert(_reviews, r, (x) => x.id == r.id);
        notifyListeners();
      });

  /// Xóa đánh giá (khách xóa của mình, hoặc Quản lý xóa)
  Future<String?> deleteReview(String reviewId) => guard(() async {
        await _api.delete('/reviews/$reviewId');
        _reviews.removeWhere((r) => r.id == reviewId);
        notifyListeners();
      });
}
