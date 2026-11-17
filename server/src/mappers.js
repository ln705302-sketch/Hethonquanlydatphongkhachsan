/**
 * Chuyển dòng Oracle -> JSON đúng định dạng các model Flutter (fromJson).
 * Ngày giờ giữ nguyên chuỗi 'YYYY-MM-DDTHH:MM:SS' (giờ địa phương).
 */

// Giá trị trong DB <-> giá trị enum phía app
const ROOM_STATUS = { Trong: 'available', DangO: 'occupied', BaoTri: 'maintenance', NgungSuDung: 'retired' };
const BOOKING_STATUS = { DaDat: 'booked', DaNhanPhong: 'checkedIn', DaTraPhong: 'checkedOut', DaHuy: 'cancelled' };
const PAYMENT = { TienMat: 'cash', ChuyenKhoan: 'bankTransfer', The: 'card' };
const INVOICE_STATUS = { DaThanhToan: 'paid', HoanTien: 'refunded', ChuaThanhToan: 'unpaid' };
const GENDER = { Nam: 'Nam', Nu: 'Nữ', Khac: 'Khác' };
const ROLE = { QuanLy: 'manager', LeTan: 'receptionist' };

const invert = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [v, k]));
const toDb = {
  roomStatus: invert(ROOM_STATUS),
  payment: invert(PAYMENT),
  gender: invert(GENDER),
  role: invert(ROLE),
};

const json = (s, fallback = []) => {
  try { return s ? JSON.parse(s) : fallback; } catch { return fallback; }
};
const num = (v) => (v == null ? 0 : Number(v));

// Mã người dùng: KH<id> cho khách hàng, NV<id> cho nhân viên
const customerId = (n) => `KH${n}`;
const staffId = (n) => (n == null ? null : `NV${n}`);
function parseUserId(id) {
  const m = /^(KH|NV)(\d+)$/.exec(String(id || ''));
  return m ? { kind: m[1], num: Number(m[2]) } : null;
}

/** Parse id số từ path param, null nếu không hợp lệ */
const parseId = (s) => (/^\d+$/.test(String(s)) ? Number(s) : null);

function customer(r) {
  return {
    id: customerId(r.MAKHACHHANG),
    fullName: r.HOTEN,
    email: r.EMAIL || '',
    phone: r.SODIENTHOAI || '',
    hasAccount: r.MATKHAUHASH != null,
    role: 'customer',
    cccd: r.CCCD || '',
    address: r.DIACHI || '',
    gender: GENDER[r.GIOITINH] || '',
    birthDate: r.NGAYSINH || null,
    isLocked: r.TRANGTHAI === 'Khoa',
    createdAt: r.NGAYTAO,
  };
}

function staff(r) {
  return {
    id: staffId(r.MANHANVIEN),
    fullName: r.HOTEN,
    email: r.EMAIL || '',
    phone: r.SODIENTHOAI || '',
    hasAccount: true,
    role: ROLE[r.VAITRO],
    username: r.TENDANGNHAP,
    cccd: '',
    address: '',
    gender: '',
    birthDate: null,
    isLocked: r.TRANGTHAI === 'Khoa',
    createdAt: r.NGAYTAO,
  };
}

function hotel(r) {
  return {
    name: r.TENKHACHSAN,
    city: r.THANHPHO,
    address: r.DIACHI,
    phone: r.SODIENTHOAI || '',
    email: r.EMAIL || '',
    description: r.MOTA || '',
    stars: num(r.SOSAO),
    images: json(r.HINHANH),
    amenities: json(r.TIENICH),
  };
}

function roomType(r) {
  return {
    id: String(r.MALOAIPHONG),
    name: r.TENLOAIPHONG,
    description: r.MOTA || '',
    bedType: r.LOAIGIUONG || '',
    maxGuests: num(r.SONGUOITOIDA),
    area: num(r.DIENTICH),
    pricePerNight: num(r.GIACOBAN),
    images: json(r.HINHANH),
    amenities: json(r.TIENNGHI),
    isActive: r.TRANGTHAI === 'HoatDong',
  };
}

function room(r) {
  return {
    id: String(r.MAPHONG),
    typeId: String(r.MALOAIPHONG),
    number: r.SOPHONG,
    floor: num(r.TANG),
    note: r.MOTA || '',
    status: ROOM_STATUS[r.TRANGTHAI],
  };
}

function service(r) {
  return {
    id: String(r.MADICHVU),
    name: r.TENDICHVU,
    description: r.MOTA || '',
    price: num(r.DONGIA),
    unit: r.DONVITINH,
    isActive: r.TRANGTHAI === 'HoatDong',
  };
}

/** Dòng từ BOOKING_SELECT (DatPhong JOIN Phong, LoaiPhong, KhachHang) */
function booking(r) {
  return {
    id: String(r.MADATPHONG),
    userId: customerId(r.MAKHACHHANG),
    staffId: staffId(r.MANHANVIEN),
    roomId: String(r.MAPHONG),
    roomNumber: r.SOPHONG,
    roomTypeName: r.TENLOAIPHONG,
    unitPrice: num(r.DONGIAPHONG),
    checkIn: r.NGAYNHANDUKIEN,
    checkOut: r.NGAYTRADUKIEN,
    actualCheckIn: r.NGAYNHANTHUCTE || null,
    actualCheckOut: r.NGAYTRATHUCTE || null,
    guests: num(r.SONGUOI),
    guestName: r.TENKHACHO || r.HOTEN || '',
    guestPhone: r.SDTKHACHO || r.SODIENTHOAI || '',
    guestEmail: r.EMAILKHACHO || '',
    note: r.GHICHU || '',
    promoCode: r.MACODEKM || null,
    discount: num(r.GIAMGIA),
    paymentMethod: PAYMENT[r.PHUONGTHUCDUKIEN],
    status: BOOKING_STATUS[r.TRANGTHAI],
    createdAt: r.NGAYDAT,
  };
}

/** Dòng từ USAGE_SELECT (SuDungDichVu JOIN DichVu) */
function usage(r) {
  return {
    id: String(r.MASUDUNG),
    bookingId: String(r.MADATPHONG),
    serviceId: String(r.MADICHVU),
    serviceName: r.TENDICHVU,
    unit: r.DONVITINH,
    date: r.NGAYSUDUNG,
    quantity: num(r.SOLUONG),
    unitPrice: num(r.DONGIATAITHOIDIEM),
    amount: num(r.THANHTIEN),
    note: r.GHICHU || '',
  };
}

function invoice(r) {
  return {
    id: String(r.MAHOADON),
    bookingId: String(r.MADATPHONG),
    staffId: staffId(r.MANHANVIEN),
    createdAt: r.NGAYLAP,
    nights: num(r.SODEM),
    roomCharge: num(r.TIENPHONG),
    serviceCharge: num(r.TIENDICHVU),
    discount: num(r.GIAMGIA),
    total: num(r.TONGTHANHTOAN),
    paidAmount: num(r.TIENKHACHTRA),
    change: num(r.TIENTHUA),
    method: PAYMENT[r.PHUONGTHUCTT],
    status: INVOICE_STATUS[r.TRANGTHAITT],
    note: r.GHICHU || '',
  };
}

function review(r) {
  return {
    id: String(r.MADANHGIA),
    userId: r.MAKHACHHANG == null ? `guest-${r.MADANHGIA}` : customerId(r.MAKHACHHANG),
    userName: r.TENHIENTHI,
    score: num(r.DIEM),
    comment: r.NHANXET,
    createdAt: r.NGAYTAO,
    updatedAt: r.NGAYSUA || null,
    isHidden: num(r.AN) === 1,
  };
}

function promotion(r) {
  return {
    code: r.MACODE,
    title: r.TIEUDE,
    description: r.MOTA || '',
    percent: num(r.PHANTRAMGIAM),
    fixedAmount: num(r.SOTIENGIAM),
    minNights: num(r.SODEMTOITHIEU),
    firstBookingOnly: num(r.CHIDONDAUTIEN) === 1,
    isActive: r.TRANGTHAI === 'HoatDong',
  };
}

module.exports = {
  customer, staff, hotel, roomType, room, service, booking, usage, invoice, review, promotion,
  customerId, staffId, parseUserId, parseId, toDb, json,
};
