const express = require('express');

const db = require('../db');
const auth = require('../auth');
const v = require('../validate');
const map = require('../mappers');
const { ApiError, bad, conflict } = require('../errors');
const { today, toDb, parseDate } = require('../dates');
const { DATE } = require('../logic');
const { wrap, emailTaken } = require('./helpers');

const router = express.Router();

/** Đăng nhập bằng email (khách, nhân viên) hoặc tên đăng nhập (nhân viên) */
router.post('/auth/login', wrap(async (req, res) => {
  const login = v.str(req.body.email).toLowerCase();
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  if (!login || !password) throw bad('Vui lòng nhập email và mật khẩu');

  let user = null;
  let hashed = null;
  const nv = await db.query(
    'SELECT * FROM NhanVien WHERE LOWER(Email) = :l OR LOWER(TenDangNhap) = :l', { l: login });
  if (nv[0]) {
    user = map.staff(nv[0]);
    hashed = nv[0].MATKHAUHASH;
  } else {
    const kh = await db.query(
      'SELECT * FROM KhachHang WHERE LOWER(Email) = :l AND MatKhauHash IS NOT NULL', { l: login });
    if (kh[0]) {
      user = map.customer(kh[0]);
      hashed = kh[0].MATKHAUHASH;
    }
  }
  if (!user || !(await auth.verify(password, hashed))) {
    throw new ApiError(401, 'Email hoặc mật khẩu không đúng');
  }
  if (user.isLocked) throw new ApiError(403, 'Tài khoản đã bị khóa. Vui lòng liên hệ khách sạn');
  res.json({ token: auth.sign(user), user });
}));

/** Khách tự đăng ký tài khoản (đăng nhập luôn) */
router.post('/auth/register', wrap(async (req, res) => {
  const fullName = v.required(req.body.fullName, 'Họ tên', 120);
  const email = v.email(req.body.email);
  const phone = v.phone(req.body.phone);
  const password = v.password(req.body.password);
  if (await emailTaken(email)) throw conflict('Email này đã được sử dụng');
  const samePhone = await db.query('SELECT 1 FROM KhachHang WHERE SoDienThoai = :p', { p: phone });
  if (samePhone.length) throw conflict('Số điện thoại này đã được sử dụng');

  const hashed = await auth.hash(password);
  const id = await db.tx((t) => t.insert(
    `INSERT INTO KhachHang (HoTen, SoDienThoai, Email, MatKhauHash, NgayTao)
     VALUES (:name, :phone, :email, :h, ${DATE('created')}) RETURNING MaKhachHang INTO :id`,
    { name: fullName, phone, email, h: hashed, created: toDb(new Date()) },
  ));
  const user = auth.publicUser(await auth.loadUser(map.customerId(id)));
  res.status(201).json({ token: auth.sign(user), user });
}));

router.get('/auth/me', auth.requireAuth, (req, res) => {
  res.json(auth.publicUser(req.user));
});

/**
 * Cập nhật hồ sơ của chính mình. Nhân viên chỉ có họ tên và SĐT
 * (bảng NhanVien không có CCCD, địa chỉ, giới tính, ngày sinh)
 */
router.put('/me', auth.requireAuth, wrap(async (req, res) => {
  const u = req.user;
  const fullName = v.required(req.body.fullName, 'Họ tên', 120);
  const phone = v.phone(req.body.phone);
  if (auth.isStaff(u)) {
    await db.query('UPDATE NhanVien SET HoTen = :name, SoDienThoai = :phone WHERE MaNhanVien = :id',
      { name: fullName, phone, id: u._num });
  } else {
    const cccd = v.cccd(req.body.cccd);
    const address = v.optional(req.body.address, 'Địa chỉ', 300);
    const gender = v.str(req.body.gender);
    if (gender && !map.toDb.gender[gender]) throw bad('Giới tính không hợp lệ');
    let birth = null;
    if (req.body.birthDate) {
      birth = parseDate(req.body.birthDate);
      if (!birth || birth > today()) throw bad('Ngày sinh không hợp lệ');
    }
    await db.query(
      `UPDATE KhachHang SET HoTen = :name, SoDienThoai = :phone, CCCD = :cccd, DiaChi = :address,
              GioiTinh = :gender, NgaySinh = ${DATE('birth')}
        WHERE MaKhachHang = :id`,
      { name: fullName, phone, cccd: cccd || null, address: address || null,
        gender: gender ? map.toDb.gender[gender] : null, birth: birth ? toDb(birth) : null, id: u._num },
    );
  }
  res.json(auth.publicUser(await auth.loadUser(u.id)));
}));

router.put('/me/password', auth.requireAuth, wrap(async (req, res) => {
  const u = req.user;
  const oldPassword = typeof req.body.oldPassword === 'string' ? req.body.oldPassword : '';
  const newPassword = v.password(req.body.newPassword);
  const table = auth.isStaff(u) ? 'NhanVien' : 'KhachHang';
  const key = auth.isStaff(u) ? 'MaNhanVien' : 'MaKhachHang';
  const rows = await db.query(`SELECT MatKhauHash FROM ${table} WHERE ${key} = :id`, { id: u._num });
  if (!(await auth.verify(oldPassword, rows[0]?.MATKHAUHASH))) {
    throw bad('Mật khẩu hiện tại không đúng');
  }
  await db.query(`UPDATE ${table} SET MatKhauHash = :h WHERE ${key} = :id`,
    { h: await auth.hash(newPassword), id: u._num });
  res.json({ ok: true });
}));

// ---------- Mã ưu đãi khách đã lưu ----------

router.get('/me/saved-promos', auth.requireCustomer, wrap(async (req, res) => {
  const rows = await db.query(
    `SELECT km.MaCode FROM LuuKhuyenMai l JOIN KhuyenMai km ON km.MaKhuyenMai = l.MaKhuyenMai
      WHERE l.MaKhachHang = :kh ORDER BY l.NgayLuu`,
    { kh: req.user._num },
  );
  res.json(rows.map((r) => r.MACODE));
}));

router.post('/me/saved-promos', auth.requireCustomer, wrap(async (req, res) => {
  const code = v.str(req.body.code).toUpperCase();
  const promo = (await db.query('SELECT MaKhuyenMai, TrangThai FROM KhuyenMai WHERE MaCode = :c', { c: code }))[0];
  if (!promo || promo.TRANGTHAI !== 'HoatDong') throw bad('Mã ưu đãi không tồn tại hoặc đã ngừng áp dụng');
  await db.query(
    `MERGE INTO LuuKhuyenMai l USING (SELECT :kh AS kh, :km AS km FROM dual) s
        ON (l.MaKhachHang = s.kh AND l.MaKhuyenMai = s.km)
      WHEN NOT MATCHED THEN INSERT (MaKhachHang, MaKhuyenMai, NgayLuu)
           VALUES (s.kh, s.km, ${DATE('d')})`,
    { kh: req.user._num, km: promo.MAKHUYENMAI, d: toDb(new Date()) },
  );
  res.status(201).json({ ok: true });
}));

router.delete('/me/saved-promos/:code', auth.requireCustomer, wrap(async (req, res) => {
  await db.query(
    `DELETE FROM LuuKhuyenMai WHERE MaKhachHang = :kh
        AND MaKhuyenMai IN (SELECT MaKhuyenMai FROM KhuyenMai WHERE MaCode = :c)`,
    { kh: req.user._num, c: String(req.params.code).toUpperCase() },
  );
  res.json({ ok: true });
}));

module.exports = router;
