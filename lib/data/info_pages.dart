/// Nội dung trang thông tin mở từ footer
class InfoPage {
  const InfoPage(this.title, this.sections);
  final String title;
  final List<(String, String)> sections; // (tiêu đề, nội dung)
}

const kInfoPages = {
  'help': InfoPage('Trung tâm trợ giúp', [
    (
      'Làm thế nào để đặt phòng?',
      'Chọn ngày ở và số khách, chọn hạng phòng, nhập thông tin rồi bấm '
          '"Xác nhận đặt phòng". Bạn cần đăng nhập để đặt phòng. Mỗi đơn đặt một phòng.'
    ),
    (
      'Xem đơn đã đặt ở đâu?',
      'Vào mục "Đơn của tôi" trên header để xem trạng thái, dịch vụ đã dùng và hóa đơn.'
    ),
    (
      'Thanh toán khi nào?',
      'Bạn thanh toán tại quầy lễ tân khi trả phòng, gồm tiền phòng theo số đêm '
          'lưu trú và tiền các dịch vụ đã sử dụng.'
    ),
    (
      'Dùng mã ưu đãi như thế nào?',
      'Bấm vào thẻ ưu đãi ở trang chủ để lưu mã, sau đó chọn mã ở bước đặt '
          'phòng. Mỗi mã dùng được một lần; nếu đơn bị hủy, mã được dùng lại.'
    ),
  ]),
  'cancellation': InfoPage('Chính sách hủy phòng', [
    (
      'Điều kiện hủy',
      'Bạn có thể tự hủy đơn trong "Đơn của tôi" khi đơn ở trạng thái "Đã đặt" '
          'và chưa đến ngày nhận phòng.'
    ),
    (
      'Hủy từ ngày nhận phòng trở đi',
      'Đây là trường hợp đặc biệt, vui lòng liên hệ lễ tân để Quản lý phê duyệt.'
    ),
    (
      'Sau khi hủy',
      'Phòng được trả lại lịch trống. Mã ưu đãi đã dùng cho đơn được dùng lại.'
    ),
  ]),
  'terms': InfoPage('Điều khoản sử dụng', [
    (
      'Phạm vi',
      'Sunrise Hotel trên website này là sản phẩm đồ án môn học. Giá phòng và '
          'thanh toán đều là dữ liệu giả lập, không phát sinh giao dịch thật.'
    ),
    (
      'Tài khoản',
      'Bạn chịu trách nhiệm với thông tin đã đăng ký. Quản lý khách sạn có thể '
          'khóa tài khoản vi phạm.'
    ),
  ]),
  'privacy': InfoPage('Chính sách bảo mật', [
    (
      'Dữ liệu được lưu ở đâu?',
      'Tài khoản và đơn đặt phòng chỉ được lưu trong trình duyệt của bạn, '
          'không gửi lên máy chủ nào.'
    ),
    (
      'Lưu ý',
      'Đây là bản demo và mật khẩu chưa được mã hóa, vì vậy đừng dùng mật khẩu '
          'thật của bạn.'
    ),
  ]),
};
