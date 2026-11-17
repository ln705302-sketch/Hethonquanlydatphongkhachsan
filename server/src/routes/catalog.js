const express = require('express');

const db = require('../db');
const auth = require('../auth');
const v = require('../validate');
const map = require('../mappers');
const { bad, conflict, notFound } = require('../errors');
const { parseDate, toDb, nights } = require('../dates');
const { FREE_ROOM_CONDITION } = require('../logic');
const { wrap, idParam } = require('./helpers');

const router = express.Router();

// ---------- Thông tin khách sạn ----------

router.get('/hotel', wrap(async (_req, res) => {
  const rows = await db.query('SELECT * FROM KhachSan WHERE MaKhachSan = 1');
  if (!rows[0]) throw notFound('Chưa có thông tin khách sạn');
  res.json(map.hotel(rows[0]));
}));

router.put('/hotel', auth.requireManager, wrap(async (req, res) => {
  const b = req.body;
  const d = {
    name: v.required(b.name, 'Tên khách sạn', 120),
    city: v.required(b.city, 'Thành phố', 120),
    address: v.required(b.address, 'Địa chỉ', 300),
    phone: v.optional(b.phone, 'Hotline', 30) || null,
    email: v.email(b.email, { optional: true }) || null,
    description: v.optional(b.description, 'Mô tả', 2000) || null,
    stars: v.integer(b.stars, 'Số sao', 1, 5),
    images: JSON.stringify(v.stringList(b.images, 'Ảnh')),
    amenities: JSON.stringify(v.stringList(b.amenities, 'Tiện ích')),
  };
  await db.query(
    `UPDATE KhachSan SET TenKhachSan = :name, ThanhPho = :city, DiaChi = :address, SoDienThoai = :phone,
            Email = :email, MoTa = :description, SoSao = :stars, HinhAnh = :images, TienIch = :amenities
      WHERE MaKhachSan = 1`, d);
  const rows = await db.query('SELECT * FROM KhachSan WHERE MaKhachSan = 1');
  res.json(map.hotel(rows[0]));
}));

// ---------- Loại phòng ----------

router.get('/room-types', wrap(async (_req, res) => {
  const rows = await db.query('SELECT * FROM LoaiPhong ORDER BY GiaCoBan, MaLoaiPhong');
  res.json(rows.map(map.roomType));
}));

function roomTypeInput(b) {
  return {
    name: v.required(b.name, 'Tên loại phòng', 60),
    descr: v.optional(b.description, 'Mô tả', 1000) || null,
    price: v.number(b.pricePerNight, 'Giá phòng', 0, 1e9),
    max: v.integer(b.maxGuests, 'Số khách tối đa', 1, 20),
    area: v.number(b.area ?? 0, 'Diện tích', 0, 10000),
    bed: v.optional(b.bedType, 'Loại giường', 60) || null,
    amenities: JSON.stringify(v.stringList(b.amenities, 'Tiện nghi')),
    images: JSON.stringify(v.stringList(b.images, 'Ảnh')),
    status: b.isActive === false ? 'Ngung' : 'HoatDong',
  };
}

router.post('/room-types', auth.requireManager, wrap(async (req, res) => {
  const d = roomTypeInput(req.body);
  const id = await db.tx((t) => t.insert(
    `INSERT INTO LoaiPhong (TenLoaiPhong, MoTa, GiaCoBan, SoNguoiToiDa, DienTich, LoaiGiuong, TienNghi, HinhAnh, TrangThai)
     VALUES (:name, :descr, :price, :max, :area, :bed, :amenities, :images, :status)
     RETURNING MaLoaiPhong INTO :id`, d));
  const rows = await db.query('SELECT * FROM LoaiPhong WHERE MaLoaiPhong = :id', { id });
  res.status(201).json(map.roomType(rows[0]));
}));

router.put('/room-types/:id', auth.requireManager, wrap(async (req, res) => {
  const id = idParam(req);
  const d = roomTypeInput(req.body);
  const r = await db.tx((t) => t.exec(
    `UPDATE LoaiPhong SET TenLoaiPhong = :name, MoTa = :descr, GiaCoBan = :price, SoNguoiToiDa = :max,
            DienTich = :area, LoaiGiuong = :bed, TienNghi = :amenities, HinhAnh = :images, TrangThai = :status
      WHERE MaLoaiPhong = :id`, { ...d, id }));
  if (!r.rowsAffected) throw notFound('Không tìm thấy loại phòng');
  const rows = await db.query('SELECT * FROM LoaiPhong WHERE MaLoaiPhong = :id', { id });
  res.json(map.roomType(rows[0]));
}));

router.delete('/room-types/:id', auth.requireManager, wrap(async (req, res) => {
  const id = idParam(req);
  const rooms = await db.query('SELECT COUNT(*) AS N FROM Phong WHERE MaLoaiPhong = :id', { id });
  if (rooms[0].N > 0) throw conflict('Vẫn còn phòng thuộc loại này, không thể xóa');
  await db.query('DELETE FROM LoaiPhong WHERE MaLoaiPhong = :id', { id });
  res.json({ ok: true });
}));

// ---------- Phòng ----------

router.get('/rooms', wrap(async (_req, res) => {
  const rows = await db.query('SELECT * FROM Phong ORDER BY SoPhong');
  res.json(rows.map(map.room));
}));

// Trạng thái "Đang ở" chỉ do nhận phòng / trả phòng thay đổi
const MANUAL_STATUS = ['available', 'maintenance', 'retired'];

function roomInput(b) {
  const typeId = map.parseId(b.typeId);
  if (typeId == null) throw bad('Vui lòng chọn loại phòng');
  return {
    typeId,
    num: v.required(b.number, 'Số phòng', 15),
    floor: v.integer(b.floor ?? 1, 'Tầng', 0, 200),
    note: v.optional(b.note, 'Ghi chú', 500) || null,
    status: v.str(b.status) || 'available',
  };
}

router.post('/rooms', auth.requireManager, wrap(async (req, res) => {
  const d = roomInput(req.body);
  v.oneOf(d.status, MANUAL_STATUS, 'Trạng thái phòng');
  const id = await db.tx((t) => t.insert(
    `INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, MoTa, TrangThai)
     VALUES (:typeId, :num, :floor, :note, :status) RETURNING MaPhong INTO :id`,
    { ...d, status: map.toDb.roomStatus[d.status] }));
  const rows = await db.query('SELECT * FROM Phong WHERE MaPhong = :id', { id });
  res.status(201).json(map.room(rows[0]));
}));

router.put('/rooms/:id', auth.requireManager, wrap(async (req, res) => {
  const id = idParam(req);
  const d = roomInput(req.body);
  await db.tx(async (t) => {
    const cur = await t.one('SELECT * FROM Phong WHERE MaPhong = :id FOR UPDATE', { id });
    if (!cur) throw notFound('Không tìm thấy phòng');
    const curStatus = map.room(cur).status;
    if (d.status !== curStatus) {
      if (curStatus === 'occupied') throw bad('Phòng đang có khách ở, không thể đổi trạng thái');
      v.oneOf(d.status, MANUAL_STATUS, 'Trạng thái phòng');
    }
    if (d.typeId !== cur.MALOAIPHONG) {
      const active = await t.one(
        "SELECT COUNT(*) AS N FROM DatPhong WHERE MaPhong = :id AND TrangThai IN ('DaDat','DaNhanPhong')", { id });
      if (active.N > 0) throw bad('Phòng đang có đơn đặt, không thể đổi loại phòng');
    }
    await t.exec(
      `UPDATE Phong SET MaLoaiPhong = :typeId, SoPhong = :num, Tang = :floor, MoTa = :note, TrangThai = :status
        WHERE MaPhong = :id`,
      { ...d, status: map.toDb.roomStatus[d.status], id });
  });
  const rows = await db.query('SELECT * FROM Phong WHERE MaPhong = :id', { id });
  res.json(map.room(rows[0]));
}));

router.delete('/rooms/:id', auth.requireManager, wrap(async (req, res) => {
  const id = idParam(req);
  const used = await db.query('SELECT COUNT(*) AS N FROM DatPhong WHERE MaPhong = :id', { id });
  if (used[0].N > 0) throw conflict('Phòng đã phát sinh trong đơn, chỉ có thể ngừng sử dụng');
  await db.query('DELETE FROM Phong WHERE MaPhong = :id', { id });
  res.json({ ok: true });
}));

// ---------- Dịch vụ ----------

router.get('/services', wrap(async (_req, res) => {
  const rows = await db.query('SELECT * FROM DichVu ORDER BY MaDichVu');
  res.json(rows.map(map.service));
}));

function serviceInput(b) {
  return {
    name: v.required(b.name, 'Tên dịch vụ', 120),
    descr: v.optional(b.description, 'Mô tả', 500) || null,
    price: v.number(b.price, 'Đơn giá', 0, 1e9),
    unit: v.required(b.unit, 'Đơn vị tính', 30),
    status: b.isActive === false ? 'Ngung' : 'HoatDong',
  };
}

router.post('/services', auth.requireManager, wrap(async (req, res) => {
  const d = serviceInput(req.body);
  const id = await db.tx((t) => t.insert(
    `INSERT INTO DichVu (TenDichVu, MoTa, DonGia, DonViTinh, TrangThai)
     VALUES (:name, :descr, :price, :unit, :status) RETURNING MaDichVu INTO :id`, d));
  const rows = await db.query('SELECT * FROM DichVu WHERE MaDichVu = :id', { id });
  res.status(201).json(map.service(rows[0]));
}));

router.put('/services/:id', auth.requireManager, wrap(async (req, res) => {
  const id = idParam(req);
  const d = serviceInput(req.body);
  const r = await db.tx((t) => t.exec(
    `UPDATE DichVu SET TenDichVu = :name, MoTa = :descr, DonGia = :price, DonViTinh = :unit, TrangThai = :status
      WHERE MaDichVu = :id`, { ...d, id }));
  if (!r.rowsAffected) throw notFound('Không tìm thấy dịch vụ');
  const rows = await db.query('SELECT * FROM DichVu WHERE MaDichVu = :id', { id });
  res.json(map.service(rows[0]));
}));

router.delete('/services/:id', auth.requireManager, wrap(async (req, res) => {
  const id = idParam(req);
  const used = await db.query('SELECT COUNT(*) AS N FROM SuDungDichVu WHERE MaDichVu = :id', { id });
  if (used[0].N > 0) throw conflict('Dịch vụ đã phát sinh trong đơn, chỉ có thể ngừng cung cấp');
  await db.query('DELETE FROM DichVu WHERE MaDichVu = :id', { id });
  res.json({ ok: true });
}));

// ---------- Phòng trống ----------

/** Số phòng còn trống của từng loại trong [checkIn, checkOut) */
router.get('/availability', wrap(async (req, res) => {
  const checkIn = parseDate(req.query.checkIn);
  const checkOut = parseDate(req.query.checkOut);
  if (!checkIn || !checkOut) throw bad('Ngày nhận / trả phòng không hợp lệ');
  if (nights(checkIn, checkOut) <= 0) throw bad('Ngày trả phòng phải sau ngày nhận phòng');
  if (nights(checkIn, checkOut) > 60) throw bad('Chỉ đặt tối đa 60 đêm');
  const rows = await db.query(
    `SELECT lp.MaLoaiPhong,
            (SELECT COUNT(*) FROM Phong p WHERE p.MaLoaiPhong = lp.MaLoaiPhong AND ${FREE_ROOM_CONDITION('p')}) AS SoPhongTrong
       FROM LoaiPhong lp ORDER BY lp.GiaCoBan`,
    { exceptId: -1, ci: toDb(checkIn), co: toDb(checkOut) },
  );
  res.json(rows.map((r) => ({ typeId: String(r.MALOAIPHONG), available: r.SOPHONGTRONG })));
}));

module.exports = router;
