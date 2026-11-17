import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../models/promotion.dart';

/// Mã ưu đãi (Quản lý thêm / sửa / xóa) và các mã khách đã lưu
class PromoProvider extends ChangeNotifier {
  PromoProvider(this._api);

  final ApiClient _api;
  List<Promotion> _promos = [];
  List<String> _saved = []; // mã người đang đăng nhập đã lưu

  /// Server trả về: khách thấy mã đang áp dụng, Quản lý thấy tất cả
  List<Promotion> get promotions => List.unmodifiable(_promos);

  /// Mã đang áp dụng, hiển thị cho khách
  List<Promotion> get activePromotions =>
      _promos.where((p) => p.isActive).toList();

  Promotion? byCode(String code) =>
      _promos.where((p) => p.code == code).firstOrNull;

  /// Tải danh sách mã; [customer] = true thì tải thêm mã đã lưu
  Future<void> load({bool customer = false}) async {
    try {
      _promos = [
        for (final j in await _api.get('/promotions') as List)
          Promotion.fromJson(j as Map<String, dynamic>)
      ];
      _saved = customer
          ? List<String>.from(await _api.get('/me/saved-promos') as List)
          : [];
    } on ApiException {
      // Giữ dữ liệu cũ
    }
    notifyListeners();
  }

  // ---------- Danh mục mã (Quản lý) ----------

  /// Thêm mã mới ([originalCode] == null) hoặc sửa mã đã có
  Future<String?> savePromotion(Promotion promo, {String? originalCode}) =>
      guard(() async {
        final data = originalCode == null
            ? await _api.post('/promotions', promo.toJson())
            : await _api.put('/promotions/$originalCode', promo.toJson());
        final saved = Promotion.fromJson(data as Map<String, dynamic>);
        final i = _promos.indexWhere((p) => p.code == (originalCode ?? saved.code));
        i == -1 ? _promos.add(saved) : _promos[i] = saved;
        if (originalCode != null && originalCode != saved.code) {
          _saved = [for (final c in _saved) c == originalCode ? saved.code : c];
        }
        notifyListeners();
      });

  Future<String?> toggleActive(String code) => guard(() async {
        final saved = Promotion.fromJson(
            await _api.post('/promotions/$code/toggle') as Map<String, dynamic>);
        final i = _promos.indexWhere((p) => p.code == code);
        if (i != -1) _promos[i] = saved;
        notifyListeners();
      });

  /// Xóa mã. Đơn đã dùng mã vẫn giữ nguyên số tiền đã giảm
  Future<String?> deletePromotion(String code) => guard(() async {
        await _api.delete('/promotions/$code');
        _promos.removeWhere((p) => p.code == code);
        _saved.remove(code);
        notifyListeners();
      });

  // ---------- Mã khách đã lưu ----------

  bool isSaved(String userId, String code) => _saved.contains(code);

  /// Các mã người dùng đã lưu và còn đang áp dụng
  List<Promotion> savedOf(String userId) =>
      activePromotions.where((p) => _saved.contains(p.code)).toList();

  Future<String?> save(String userId, String code) => guard(() async {
        await _api.post('/me/saved-promos', {'code': code});
        if (!_saved.contains(code)) _saved.add(code);
        notifyListeners();
      });

  Future<String?> remove(String userId, String code) => guard(() async {
        await _api.delete('/me/saved-promos/$code');
        _saved.remove(code);
        notifyListeners();
      });
}
