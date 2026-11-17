/** Lỗi nghiệp vụ trả về cho client: { error: message } */
class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const bad = (msg) => new ApiError(400, msg);
const forbidden = (msg = 'Bạn không có quyền thực hiện thao tác này') => new ApiError(403, msg);
const notFound = (msg = 'Không tìm thấy dữ liệu') => new ApiError(404, msg);
const conflict = (msg) => new ApiError(409, msg);

// Lỗi RAISE_APPLICATION_ERROR trong trigger
const TRIGGER_MESSAGES = {
  20021: 'Chỉ ghi nhận dịch vụ cho đơn đã nhận phòng',
  20022: 'Dịch vụ đang ngừng cung cấp',
  20023: 'Ngày trả phòng phải sau ngày nhận phòng',
  20024: 'Phòng đang bảo trì hoặc ngừng sử dụng',
  20025: 'Phòng đã được đặt trong khoảng thời gian này',
};

// Vi phạm UNIQUE theo tên constraint / index
const UNIQUE_MESSAGES = {
  UQ_KHACHHANG_SDT: 'Số điện thoại này đã được sử dụng',
  UQ_KHACHHANG_EMAIL: 'Email này đã được sử dụng',
  UQ_KHACHHANG_CCCD: 'Số CCCD này đã được sử dụng',
  UQ_NHANVIEN_EMAIL: 'Email này đã được sử dụng',
  UQ_NHANVIEN_USER: 'Tên đăng nhập đã tồn tại',
  UQ_LOAIPHONG_TEN: 'Tên loại phòng đã tồn tại',
  UQ_PHONG_SO: 'Số phòng đã tồn tại',
  UQ_DICHVU_TEN: 'Tên dịch vụ đã tồn tại',
  UQ_HOADON_DATPHONG: 'Đơn này đã có hóa đơn',
  UQ_KHUYENMAI_CODE: 'Mã ưu đãi đã tồn tại',
  UQ_DANHGIA_KHACH: 'Bạn đã đánh giá rồi',
  PK_LUUKHUYENMAI: 'Bạn đã lưu mã này',
};

/** Chuyển lỗi Oracle (ORA-xxxxx) sang ApiError với thông báo tiếng Việt */
function fromOracle(e) {
  const num = e.errorNum;
  if (!num) return null;
  if (TRIGGER_MESSAGES[num]) return conflict(TRIGGER_MESSAGES[num]);
  if (num === 1) {
    const m = /\(([^.]+)\.([^)]+)\)/.exec(e.message || '');
    const name = m ? m[2].toUpperCase() : '';
    return conflict(UNIQUE_MESSAGES[name] || 'Dữ liệu bị trùng');
  }
  if (num === 2292) return conflict('Dữ liệu đang được sử dụng ở nơi khác, không thể xóa');
  if (num === 2291) return bad('Dữ liệu liên quan không tồn tại');
  if (num === 2290) return bad('Dữ liệu không hợp lệ');
  if (num === 1400) return bad('Thiếu dữ liệu bắt buộc');
  if (num === 12899) return bad('Dữ liệu quá dài');
  return null;
}

module.exports = { ApiError, bad, forbidden, notFound, conflict, fromOracle };
