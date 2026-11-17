/// Cho các màn hình yêu cầu tải lại toàn bộ dữ liệu từ server
/// (VD sau khi Quản lý khôi phục dữ liệu mẫu)
class AppReloader {
  const AppReloader(this.reloadAll);
  final Future<void> Function() reloadAll;
}
