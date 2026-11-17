/** Nghiệp vụ dùng chung: phòng trống, mã ưu đãi, bảng kê tiền */
const { dateOnly, nights, now, toDb, fromDb } = require('./dates');
const { bad, notFound } = require('./errors');

const DATE = (name) => `TO_DATE(:${name}, 'YYYY-MM-DD"T"HH24:MI:SS')`;

/** SELECT đơn đặt phòng kèm số phòng, loại phòng, thông tin khách */
const BOOKING_SELECT = `
  SELECT dp.*, p.SoPhong, p.MaLoaiPhong, lp.TenLoaiPhong, kh.HoTen, kh.SoDienThoai
    FROM DatPhong dp
    JOIN Phong p ON p.MaPhong = dp.MaPhong
    JOIN LoaiPhong lp ON lp.MaLoaiPhong = p.MaLoaiPhong
    JOIN KhachHang kh ON kh.MaKhachHang = dp.MaKhachHang`;

const USAGE_SELECT = `
  SELECT s.*, dv.TenDichVu, dv.DonViTinh
    FROM SuDungDichVu s JOIN DichVu dv ON dv.MaDichVu = s.MaDichVu`;

/**
 * Điều kiện phòng [alias] còn trống trong [ci, co): không bảo trì / ngừng
 * sử dụng và không có đơn "Đã đặt"/"Đã nhận phòng" chồng lịch
 */
const FREE_ROOM_CONDITION = (alias = 'p') => `
  ${alias}.TrangThai IN ('Trong','DangO')
  AND NOT EXISTS (
    SELECT 1 FROM DatPhong d
     WHERE d.MaPhong = ${alias}.MaPhong
       AND d.TrangThai IN ('DaDat','DaNhanPhong')
       AND d.MaDatPhong <> :exceptId
       AND d.NgayNhanDuKien < ${DATE('co')}
       AND d.NgayTraDuKien > ${DATE('ci')})`;

/** Các phòng trống của một loại trong khoảng ngày (chạy trong transaction) */
function freeRooms(t, typeId, checkIn, checkOut, exceptId = -1) {
  return t.rows(
    `SELECT p.MaPhong, p.SoPhong, p.TrangThai FROM Phong p
      WHERE p.MaLoaiPhong = :typeId AND ${FREE_ROOM_CONDITION('p')}
      ORDER BY p.SoPhong`,
    { typeId, exceptId, ci: toDb(checkIn), co: toDb(checkOut) },
  );
}

/** Số tiền giảm (không vượt tiền phòng), làm tròn đến đồng */
const discountFor = (promo, subtotal) =>
  Math.min(Math.round(subtotal * Number(promo.PHANTRAMGIAM) / 100 + Number(promo.SOTIENGIAM)), subtotal);

/**
 * Kiểm tra mã ưu đãi cho khách [customerNum]; trả về dòng KhuyenMai.
 * Mã đã dùng cho một đơn chưa hủy thì không dùng lại (đơn hủy -> dùng lại được)
 */
async function checkPromo(t, code, customerNum, stayNights) {
  const promo = await t.one('SELECT * FROM KhuyenMai WHERE MaCode = :code', { code });
  if (!promo) throw bad('Mã ưu đãi không tồn tại');
  if (promo.TRANGTHAI !== 'HoatDong') throw bad('Mã đã ngừng áp dụng');
  const used = await t.one(
    `SELECT COUNT(*) AS N FROM DatPhong WHERE MaKhachHang = :kh AND MaCodeKM = :code AND TrangThai <> 'DaHuy'`,
    { kh: customerNum, code },
  );
  if (used.N > 0) throw bad('Mã này đã được sử dụng');
  if (stayNights < Number(promo.SODEMTOITHIEU)) {
    throw bad(`Cần đặt từ ${promo.SODEMTOITHIEU} đêm trở lên`);
  }
  if (Number(promo.CHIDONDAUTIEN) === 1) {
    const active = await t.one(
      `SELECT COUNT(*) AS N FROM DatPhong WHERE MaKhachHang = :kh AND TrangThai <> 'DaHuy'`,
      { kh: customerNum },
    );
    if (active.N > 0) throw bad('Chỉ áp dụng cho đơn đặt phòng đầu tiên');
  }
  return promo;
}

/**
 * Bảng kê khi trả phòng: tiền phòng theo số đêm lưu trú thực tế (tối thiểu
 * 1 đêm) + tiền dịch vụ - giảm giá (không vượt tiền phòng)
 */
async function billFor(t, bookingRow) {
  const start = fromDb(bookingRow.NGAYNHANTHUCTE || bookingRow.NGAYNHANDUKIEN);
  const stay = Math.max(1, nights(dateOnly(start), now()));
  const roomCharge = Number(bookingRow.DONGIAPHONG) * stay;
  const svc = await t.one(
    'SELECT NVL(SUM(ThanhTien), 0) AS S FROM SuDungDichVu WHERE MaDatPhong = :id',
    { id: bookingRow.MADATPHONG },
  );
  const serviceCharge = Number(svc.S);
  const discount = Math.min(Number(bookingRow.GIAMGIA), roomCharge);
  return {
    nights: stay,
    roomCharge,
    serviceCharge,
    discount,
    total: roomCharge + serviceCharge - discount,
  };
}

/** Đọc một đơn và khóa dòng (SELECT ... FOR UPDATE) */
async function lockBooking(t, id) {
  const row = await t.one('SELECT * FROM DatPhong WHERE MaDatPhong = :id FOR UPDATE', { id });
  if (!row) throw notFound('Không tìm thấy đơn');
  return row;
}

module.exports = {
  DATE, BOOKING_SELECT, USAGE_SELECT, FREE_ROOM_CONDITION,
  freeRooms, discountFor, checkPromo, billFor, lockBooking,
};
