const express = require('express');

const db = require('../db');
const auth = require('../auth');
const v = require('../validate');
const map = require('../mappers');
const { bad, conflict, forbidden, notFound } = require('../errors');
const { toDb, now } = require('../dates');
const { DATE } = require('../logic');
const { wrap, idParam } = require('./helpers');

const router = express.Router();

// ---------- Đánh giá ----------

/** Công khai: đánh giá đang hiển thị + đánh giá (bị ẩn) của chính mình; Quản lý thấy tất cả */
router.get('/reviews', wrap(async (req, res) => {
  const u = req.user;
  let rows;
  if (auth.isManager(u)) {
    rows = await db.query('SELECT * FROM DanhGia ORDER BY NgayTao DESC, MaDanhGia DESC');
  } else {
    rows = await db.query(
      'SELECT * FROM DanhGia WHERE An = 0 OR MaKhachHang = :kh ORDER BY NgayTao DESC, MaDanhGia DESC',
      { kh: auth.isCustomer(u) ? u._num : -1 });
  }
  res.json(rows.map(map.review));
}));

function reviewInput(b) {
  const score = v.number(b.score, 'Điểm', 1, 10);
  const comment = v.required(b.comment, 'Nhận xét', 2000);
  if (comment.length < 10) throw bad('Nhận xét tối thiểu 10 ký tự');
  return { score: Math.round(score * 10) / 10, cmt: comment };
}

/** Chỉ khách đã trả phòng mới viết được, mỗi người một đánh giá */
router.post('/reviews', auth.requireCustomer, wrap(async (req, res) => {
  const d = reviewInput(req.body);
  const stayed = await db.query(
    "SELECT COUNT(*) AS N FROM DatPhong WHERE MaKhachHang = :kh AND TrangThai = 'DaTraPhong'",
    { kh: req.user._num });
  if (stayed[0].N === 0) throw forbidden('Chỉ khách đã trả phòng mới có thể viết đánh giá');
  const id = await db.tx((t) => t.insert(
    `INSERT INTO DanhGia (MaKhachHang, TenHienThi, Diem, NhanXet, NgayTao)
     VALUES (:kh, :name, :score, :cmt, ${DATE('at')}) RETURNING MaDanhGia INTO :id`,
    { kh: req.user._num, name: req.user.fullName, ...d, at: toDb(now()) }));
  const rows = await db.query('SELECT * FROM DanhGia WHERE MaDanhGia = :id', { id });
  res.status(201).json(map.review(rows[0]));
}));

async function reviewRow(id) {
  const rows = await db.query('SELECT * FROM DanhGia WHERE MaDanhGia = :id', { id });
  if (!rows[0]) throw notFound('Không tìm thấy đánh giá');
  return rows[0];
}

router.put('/reviews/:id', auth.requireCustomer, wrap(async (req, res) => {
  const id = idParam(req);
  const row = await reviewRow(id);
  if (row.MAKHACHHANG !== req.user._num) throw forbidden('Bạn chỉ sửa được đánh giá của mình');
  const d = reviewInput(req.body);
  await db.query(
    `UPDATE DanhGia SET Diem = :score, NhanXet = :cmt, NgaySua = ${DATE('at')} WHERE MaDanhGia = :id`,
    { ...d, at: toDb(now()), id });
  res.json(map.review(await reviewRow(id)));
}));

router.delete('/reviews/:id', auth.requireAuth, wrap(async (req, res) => {
  const id = idParam(req);
  const row = await reviewRow(id);
  const own = auth.isCustomer(req.user) && row.MAKHACHHANG === req.user._num;
  if (!own && !auth.isManager(req.user)) throw forbidden('Bạn không có quyền xóa đánh giá này');
  await db.query('DELETE FROM DanhGia WHERE MaDanhGia = :id', { id });
  res.json({ ok: true });
}));

router.post('/reviews/:id/toggle-hidden', auth.requireManager, wrap(async (req, res) => {
  const id = idParam(req);
  await reviewRow(id);
  await db.query('UPDATE DanhGia SET An = 1 - An WHERE MaDanhGia = :id', { id });
  res.json(map.review(await reviewRow(id)));
}));

// ---------- Mã ưu đãi ----------

/** Khách / khách vãng lai: mã đang áp dụng. Quản lý: tất cả */
router.get('/promotions', wrap(async (req, res) => {
  const rows = await db.query(
    `SELECT * FROM KhuyenMai ${auth.isManager(req.user) ? '' : "WHERE TrangThai = 'HoatDong'"} ORDER BY MaKhuyenMai`);
  res.json(rows.map(map.promotion));
}));

function promoInput(b) {
  const code = v.str(b.code).toUpperCase();
  if (!/^[A-Z0-9]{3,20}$/.test(code)) throw bad('Mã gồm 3-20 ký tự chữ in hoa hoặc số, không dấu cách');
  const percent = v.number(b.percent ?? 0, 'Phần trăm giảm', 0, 100);
  const fixed = v.number(b.fixedAmount ?? 0, 'Số tiền giảm', 0, 1e9);
  if (percent <= 0 && fixed <= 0) throw bad('Cần nhập mức giảm theo % hoặc số tiền');
  return {
    code,
    title: v.required(b.title, 'Tên ưu đãi', 120),
    descr: v.optional(b.description, 'Mô tả', 500) || null,
    percent,
    fixed,
    minNights: v.integer(b.minNights ?? 1, 'Số đêm tối thiểu', 1, 30),
    first: v.bool(b.firstBookingOnly) ? 1 : 0,
    status: b.isActive === false ? 'Ngung' : 'HoatDong',
  };
}

router.post('/promotions', auth.requireManager, wrap(async (req, res) => {
  const d = promoInput(req.body);
  await db.tx((t) => t.insert(
    `INSERT INTO KhuyenMai (MaCode, TieuDe, MoTa, PhanTramGiam, SoTienGiam, SoDemToiThieu, ChiDonDauTien, TrangThai)
     VALUES (:code, :title, :descr, :percent, :fixed, :minNights, :first, :status) RETURNING MaKhuyenMai INTO :id`, d));
  const rows = await db.query('SELECT * FROM KhuyenMai WHERE MaCode = :c', { c: d.code });
  res.status(201).json(map.promotion(rows[0]));
}));

/** Sửa mã. Đổi mã thì cập nhật luôn mã đã ghi trên các đơn (cùng transaction) */
router.put('/promotions/:code', auth.requireManager, wrap(async (req, res) => {
  const oldCode = String(req.params.code).toUpperCase();
  const d = promoInput(req.body);
  await db.tx(async (t) => {
    const cur = await t.one('SELECT MaKhuyenMai FROM KhuyenMai WHERE MaCode = :c FOR UPDATE', { c: oldCode });
    if (!cur) throw notFound('Không tìm thấy mã ưu đãi');
    if (d.code !== oldCode) {
      const dup = await t.one('SELECT 1 AS X FROM KhuyenMai WHERE MaCode = :c', { c: d.code });
      if (dup) throw conflict('Mã ưu đãi đã tồn tại');
      await t.exec('UPDATE DatPhong SET MaCodeKM = :n WHERE MaCodeKM = :o', { n: d.code, o: oldCode });
    }
    await t.exec(
      `UPDATE KhuyenMai SET MaCode = :code, TieuDe = :title, MoTa = :descr, PhanTramGiam = :percent,
              SoTienGiam = :fixed, SoDemToiThieu = :minNights, ChiDonDauTien = :first, TrangThai = :status
        WHERE MaKhuyenMai = :id`, { ...d, id: cur.MAKHUYENMAI });
  });
  const rows = await db.query('SELECT * FROM KhuyenMai WHERE MaCode = :c', { c: d.code });
  res.json(map.promotion(rows[0]));
}));

router.post('/promotions/:code/toggle', auth.requireManager, wrap(async (req, res) => {
  const code = String(req.params.code).toUpperCase();
  const rows = await db.query('SELECT 1 FROM KhuyenMai WHERE MaCode = :c', { c: code });
  if (!rows.length) throw notFound('Không tìm thấy mã ưu đãi');
  await db.query(
    "UPDATE KhuyenMai SET TrangThai = CASE TrangThai WHEN 'HoatDong' THEN 'Ngung' ELSE 'HoatDong' END WHERE MaCode = :c",
    { c: code });
  const after = await db.query('SELECT * FROM KhuyenMai WHERE MaCode = :c', { c: code });
  res.json(map.promotion(after[0]));
}));

/** Xóa mã: lượt lưu bị xóa theo (ON DELETE CASCADE), đơn cũ giữ nguyên số tiền giảm */
router.delete('/promotions/:code', auth.requireManager, wrap(async (req, res) => {
  await db.query('DELETE FROM KhuyenMai WHERE MaCode = :c', { c: String(req.params.code).toUpperCase() });
  res.json({ ok: true });
}));

module.exports = router;
