const express = require('express');

const db = require('../db');
const auth = require('../auth');
const v = require('../validate');
const map = require('../mappers');
const { bad, conflict, forbidden, notFound } = require('../errors');
const { now, today, nights, parseDate, toDb, fromDb } = require('../dates');
const L = require('../logic');
const { wrap, idParam } = require('./helpers');

const router = express.Router();

const PAY = ['cash', 'bankTransfer', 'card'];

async function bookingJson(id) {
  const rows = await db.query(`${L.BOOKING_SELECT} WHERE dp.MaDatPhong = :id`, { id });
  return rows[0] ? map.booking(rows[0]) : null;
}

/** Khách chỉ được thao tác trên đơn của mình */
function assertOwnerOrStaff(user, row) {
  if (auth.isStaff(user)) return;
  if (row.MAKHACHHANG !== user._num) throw notFound('Không tìm thấy đơn');
}

// ---------- Danh sách ----------

router.get('/bookings', auth.requireAuth, wrap(async (req, res) => {
  const staff = auth.isStaff(req.user);
  const rows = await db.query(
    `${L.BOOKING_SELECT} ${staff ? '' : 'WHERE dp.MaKhachHang = :kh'} ORDER BY dp.NgayDat DESC, dp.MaDatPhong DESC`,
    staff ? {} : { kh: req.user._num },
  );
  res.json(rows.map(map.booking));
}));

router.get('/bookings/:id', auth.requireAuth, wrap(async (req, res) => {
  const id = idParam(req);
  const rows = await db.query(`${L.BOOKING_SELECT} WHERE dp.MaDatPhong = :id`, { id });
  if (!rows[0]) throw notFound('Không tìm thấy đơn');
  assertOwnerOrStaff(req.user, rows[0]);
  res.json(map.booking(rows[0]));
}));

// ---------- Đặt phòng ----------

/**
 * Tạo đơn: khóa các phòng của loại đã chọn (SELECT ... FOR UPDATE), tìm
 * phòng trống đầu tiên rồi chèn DatPhong trong cùng transaction. Hai người
 * đặt cùng lúc sẽ phải chờ nhau nên không thể trùng phòng.
 * Khách tự đặt cho mình; nhân viên đặt tại quầy truyền thêm userId của khách.
 */
router.post('/bookings', auth.requireAuth, wrap(async (req, res) => {
  const b = req.body;
  const staff = auth.isStaff(req.user);
  let customerNum = req.user._num;
  if (staff) {
    const p = map.parseUserId(b.userId);
    if (!p || p.kind !== 'KH') throw bad('Vui lòng chọn khách hàng');
    customerNum = p.num;
  }
  const typeId = map.parseId(b.roomTypeId);
  if (typeId == null) throw bad('Vui lòng chọn loại phòng');
  const checkIn = parseDate(b.checkIn);
  const checkOut = parseDate(b.checkOut);
  if (!checkIn || !checkOut) throw bad('Ngày nhận / trả phòng không hợp lệ');
  const stay = nights(checkIn, checkOut);
  if (stay <= 0) throw bad('Ngày trả phòng phải sau ngày nhận phòng');
  if (stay > 60) throw bad('Chỉ đặt tối đa 60 đêm');
  if (checkIn < today()) throw bad('Không thể đặt phòng cho ngày trong quá khứ');
  const guests = v.integer(b.guests, 'Số khách', 1, 20);
  const guestName = v.required(b.guestName, 'Họ tên người ở', 120);
  const guestPhone = v.phone(b.guestPhone);
  const guestEmail = v.email(b.guestEmail, { optional: true });
  const note = v.optional(b.note, 'Ghi chú', 1000);
  const pay = v.oneOf(b.paymentMethod || 'cash', PAY, 'Phương thức thanh toán');
  const code = v.str(b.promoCode).toUpperCase();

  const id = await db.tx(async (t) => {
    const kh = await t.one('SELECT TrangThai FROM KhachHang WHERE MaKhachHang = :id', { id: customerNum });
    if (!kh) throw bad('Không tìm thấy khách hàng');
    if (kh.TRANGTHAI === 'Khoa') throw forbidden('Tài khoản khách hàng đang bị khóa');
    const type = await t.one('SELECT * FROM LoaiPhong WHERE MaLoaiPhong = :id', { id: typeId });
    if (!type) throw bad('Không tìm thấy loại phòng');
    if (type.TRANGTHAI !== 'HoatDong') throw bad('Loại phòng này đã ngừng kinh doanh');
    if (guests > type.SONGUOITOIDA) throw bad('Số khách vượt quá sức chứa của phòng');

    // Khóa các phòng của loại này cho đến khi commit
    await t.rows('SELECT MaPhong FROM Phong WHERE MaLoaiPhong = :id FOR UPDATE', { id: typeId });
    const free = await L.freeRooms(t, typeId, checkIn, checkOut);
    if (!free.length) throw conflict('Rất tiếc, loại phòng này không còn phòng trống');

    let discount = 0;
    if (code) {
      const promo = await L.checkPromo(t, code, customerNum, stay);
      discount = L.discountFor(promo, Number(type.GIACOBAN) * stay);
    }
    return t.insert(
      `INSERT INTO DatPhong (MaKhachHang, MaPhong, MaNhanVien, NgayDat, NgayNhanDuKien, NgayTraDuKien, SoNguoi,
                             DonGiaPhong, GhiChu, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, MaCodeKM, GiamGia, PhuongThucDuKien)
       VALUES (:kh, :room, :nv, ${L.DATE('created')}, ${L.DATE('ci')}, ${L.DATE('co')}, :guests,
               :price, :note, 'DaDat', :gname, :gphone, :gemail, :code, :discount, :pay)
       RETURNING MaDatPhong INTO :id`,
      {
        kh: customerNum, room: free[0].MAPHONG, nv: staff ? req.user._num : null,
        created: toDb(now()), ci: toDb(checkIn), co: toDb(checkOut), guests,
        price: Number(type.GIACOBAN), note: note || null, gname: guestName, gphone: guestPhone,
        gemail: guestEmail || null, code: code || null, discount, pay: map.toDb.payment[pay],
      },
    );
  });
  res.status(201).json(await bookingJson(id));
}));

// ---------- Hủy đơn ----------

/**
 * Chỉ đơn "Đã đặt" mới hủy được. Khách / lễ tân: trước ngày nhận phòng.
 * Từ ngày nhận phòng trở đi là trường hợp đặc biệt, chỉ Quản lý hủy được.
 */
router.post('/bookings/:id/cancel', auth.requireAuth, wrap(async (req, res) => {
  const id = idParam(req);
  await db.tx(async (t) => {
    const row = await L.lockBooking(t, id);
    assertOwnerOrStaff(req.user, row);
    if (row.TRANGTHAI !== 'DaDat') throw bad('Chỉ hủy được đơn ở trạng thái "Đã đặt"');
    const beforeCheckIn = today() < fromDb(row.NGAYNHANDUKIEN);
    if (!beforeCheckIn && !auth.isManager(req.user)) {
      throw auth.isStaff(req.user)
        ? forbidden('Hủy đơn từ ngày nhận phòng cần Quản lý phê duyệt')
        : bad('Đơn chỉ được hủy trước ngày nhận phòng. Vui lòng liên hệ lễ tân');
    }
    await t.exec("UPDATE DatPhong SET TrangThai = 'DaHuy' WHERE MaDatPhong = :id", { id });
  });
  res.json(await bookingJson(id));
}));

// ---------- Nhận phòng ----------

/**
 * Nhận phòng từ ngày nhận đến trước ngày trả. Có thể đổi sang phòng khác
 * cùng loại đang trống. Đơn -> "Đã nhận phòng", phòng -> "Đang ở".
 */
router.post('/bookings/:id/check-in', auth.requireStaff, wrap(async (req, res) => {
  const id = idParam(req);
  await db.tx(async (t) => {
    const row = await L.lockBooking(t, id);
    if (row.TRANGTHAI !== 'DaDat') throw bad('Đơn không ở trạng thái "Đã đặt"');
    const ci = fromDb(row.NGAYNHANDUKIEN);
    const co = fromDb(row.NGAYTRADUKIEN);
    if (today() < ci) throw bad('Chưa đến ngày nhận phòng');
    if (today() >= co) throw bad('Đơn đã quá ngày trả phòng');

    const targetId = req.body.roomId == null ? row.MAPHONG : map.parseId(req.body.roomId);
    const target = targetId == null ? null
      : await t.one('SELECT * FROM Phong WHERE MaPhong = :id FOR UPDATE', { id: targetId });
    if (!target) throw bad('Không tìm thấy phòng');
    const current = await t.one('SELECT MaLoaiPhong FROM Phong WHERE MaPhong = :id', { id: row.MAPHONG });
    if (target.MALOAIPHONG !== current.MALOAIPHONG) throw bad('Chỉ đổi sang phòng cùng loại');
    const free = await L.freeRooms(t, target.MALOAIPHONG, ci, co, id);
    const ok = target.TRANGTHAI === 'Trong' && free.some((r) => r.MAPHONG === target.MAPHONG);
    if (!ok) throw conflict(`Phòng ${target.SOPHONG} chưa sẵn sàng, hãy chọn phòng khác`);

    await t.exec(
      `UPDATE DatPhong SET TrangThai = 'DaNhanPhong', MaPhong = :room, MaNhanVien = :nv,
              NgayNhanThucTe = ${L.DATE('at')} WHERE MaDatPhong = :id`,
      { room: target.MAPHONG, nv: req.user._num, at: toDb(now()), id },
    );
    await t.exec("UPDATE Phong SET TrangThai = 'DangO' WHERE MaPhong = :id", { id: target.MAPHONG });
  });
  res.json(await bookingJson(id));
}));

// ---------- Dịch vụ sử dụng ----------

router.get('/usages', auth.requireAuth, wrap(async (req, res) => {
  const staff = auth.isStaff(req.user);
  const rows = await db.query(
    `${L.USAGE_SELECT} ${staff ? '' : 'WHERE s.MaDatPhong IN (SELECT MaDatPhong FROM DatPhong WHERE MaKhachHang = :kh)'}
      ORDER BY s.NgaySuDung, s.MaSuDung`,
    staff ? {} : { kh: req.user._num },
  );
  res.json(rows.map(map.usage));
}));

/** Ghi nhận dịch vụ: trigger TRG_SDDV_BIU chốt đơn giá và tính thành tiền */
router.post('/bookings/:id/usages', auth.requireStaff, wrap(async (req, res) => {
  const id = idParam(req);
  const serviceId = map.parseId(req.body.serviceId);
  if (serviceId == null) throw bad('Vui lòng chọn dịch vụ');
  const quantity = v.number(req.body.quantity, 'Số lượng', 0.01, 1000);
  const note = v.optional(req.body.note, 'Ghi chú', 500);
  const usageId = await db.tx(async (t) => {
    const row = await L.lockBooking(t, id);
    if (row.TRANGTHAI !== 'DaNhanPhong') throw bad('Chỉ ghi nhận dịch vụ cho đơn đã nhận phòng');
    const svc = await t.one('SELECT TrangThai FROM DichVu WHERE MaDichVu = :id', { id: serviceId });
    if (!svc) throw bad('Không tìm thấy dịch vụ');
    if (svc.TRANGTHAI !== 'HoatDong') throw bad('Dịch vụ đang ngừng cung cấp');
    return t.insert(
      `INSERT INTO SuDungDichVu (MaDatPhong, MaDichVu, NgaySuDung, SoLuong, DonGiaTaiThoiDiem, ThanhTien, GhiChu)
       VALUES (:bid, :sid, ${L.DATE('at')}, :q, 0, 0, :note) RETURNING MaSuDung INTO :id`,
      { bid: id, sid: serviceId, at: toDb(now()), q: quantity, note: note || null },
    );
  });
  const rows = await db.query(`${L.USAGE_SELECT} WHERE s.MaSuDung = :id`, { id: usageId });
  res.status(201).json(map.usage(rows[0]));
}));

router.delete('/usages/:id', auth.requireStaff, wrap(async (req, res) => {
  const id = idParam(req);
  await db.tx(async (t) => {
    const u = await t.one('SELECT MaDatPhong FROM SuDungDichVu WHERE MaSuDung = :id', { id });
    if (!u) throw notFound('Không tìm thấy dịch vụ đã ghi');
    const row = await L.lockBooking(t, u.MADATPHONG);
    if (row.TRANGTHAI !== 'DaNhanPhong') throw bad('Chỉ xóa dịch vụ của đơn đang ở');
    await t.exec('DELETE FROM SuDungDichVu WHERE MaSuDung = :id', { id });
  });
  res.json({ ok: true });
}));

// ---------- Trả phòng và hóa đơn ----------

/** Bảng kê dự kiến nếu trả phòng ngay bây giờ */
router.get('/bookings/:id/bill', auth.requireStaff, wrap(async (req, res) => {
  const id = idParam(req);
  const bill = await db.tx(async (t) => {
    const row = await t.one('SELECT * FROM DatPhong WHERE MaDatPhong = :id', { id });
    if (!row) throw notFound('Không tìm thấy đơn');
    return L.billFor(t, row);
  });
  res.json(bill);
}));

/**
 * Trả phòng: lập hóa đơn, đơn -> "Đã trả phòng", phòng -> "Trống".
 * Cả ba thay đổi nằm trong MỘT transaction, lỗi ở bước nào cũng rollback hết.
 */
router.post('/bookings/:id/check-out', auth.requireStaff, wrap(async (req, res) => {
  const id = idParam(req);
  const method = v.oneOf(req.body.method || 'cash', PAY, 'Phương thức thanh toán');
  const paid = v.number(req.body.paidAmount, 'Số tiền khách trả', 0, 1e11);
  const note = v.optional(req.body.note, 'Ghi chú', 500);
  const invoiceId = await db.tx(async (t) => {
    const row = await L.lockBooking(t, id);
    if (row.TRANGTHAI !== 'DaNhanPhong') throw bad('Đơn chưa nhận phòng');
    const existing = await t.one('SELECT 1 AS X FROM HoaDon WHERE MaDatPhong = :id', { id });
    if (existing) throw conflict('Đơn này đã có hóa đơn');
    const bill = await L.billFor(t, row);
    if (paid < bill.total) throw bad('Số tiền khách trả chưa đủ');
    const at = toDb(now());
    const newId = await t.insert(
      `INSERT INTO HoaDon (MaDatPhong, MaNhanVien, NgayLap, SoDem, TienPhong, TienDichVu, GiamGia, TongThanhToan,
                           TienKhachTra, TienThua, PhuongThucTT, TrangThaiTT, GhiChu)
       VALUES (:bid, :nv, ${L.DATE('at')}, :n, :room, :svc, :disc, :total, :paid, :change, :method, 'DaThanhToan', :note)
       RETURNING MaHoaDon INTO :id`,
      {
        bid: id, nv: req.user._num, at, n: bill.nights, room: bill.roomCharge, svc: bill.serviceCharge,
        disc: bill.discount, total: bill.total, paid, change: paid - bill.total,
        method: map.toDb.payment[method], note: note || null,
      },
    );
    await t.exec(
      `UPDATE DatPhong SET TrangThai = 'DaTraPhong', MaNhanVien = :nv, NgayTraThucTe = ${L.DATE('at')}
        WHERE MaDatPhong = :id`, { nv: req.user._num, at, id });
    await t.exec("UPDATE Phong SET TrangThai = 'Trong' WHERE MaPhong = :id", { id: row.MAPHONG });
    return newId;
  });
  const rows = await db.query('SELECT * FROM HoaDon WHERE MaHoaDon = :id', { id: invoiceId });
  res.status(201).json({ invoice: map.invoice(rows[0]), booking: await bookingJson(id) });
}));

router.get('/invoices', auth.requireAuth, wrap(async (req, res) => {
  const staff = auth.isStaff(req.user);
  const rows = await db.query(
    `SELECT hd.* FROM HoaDon hd ${staff ? ''
      : 'JOIN DatPhong dp ON dp.MaDatPhong = hd.MaDatPhong WHERE dp.MaKhachHang = :kh'}
      ORDER BY hd.NgayLap DESC, hd.MaHoaDon DESC`,
    staff ? {} : { kh: req.user._num },
  );
  res.json(rows.map(map.invoice));
}));

/** Hoàn tiền đặc biệt: chỉ Quản lý, hóa đơn bị loại khỏi doanh thu */
router.post('/invoices/:id/refund', auth.requireManager, wrap(async (req, res) => {
  const id = idParam(req);
  await db.tx(async (t) => {
    const inv = await t.one('SELECT TrangThaiTT FROM HoaDon WHERE MaHoaDon = :id FOR UPDATE', { id });
    if (!inv) throw notFound('Không tìm thấy hóa đơn');
    if (inv.TRANGTHAITT === 'HoanTien') throw bad('Hóa đơn đã được hoàn tiền');
    if (inv.TRANGTHAITT !== 'DaThanhToan') throw bad('Hóa đơn chưa thanh toán');
    await t.exec("UPDATE HoaDon SET TrangThaiTT = 'HoanTien' WHERE MaHoaDon = :id", { id });
  });
  const rows = await db.query('SELECT * FROM HoaDon WHERE MaHoaDon = :id', { id });
  res.json(map.invoice(rows[0]));
}));

module.exports = router;
