const express = require('express');

const db = require('../db');
const auth = require('../auth');
const v = require('../validate');
const map = require('../mappers');
const { bad, conflict, forbidden, notFound } = require('../errors');
const { toDb } = require('../dates');
const { DATE } = require('../logic');
const { wrap, emailTaken } = require('./helpers');

const router = express.Router();

// ---------- Khách hàng (nhân viên quản lý) ----------

router.get('/customers', auth.requireStaff, wrap(async (_req, res) => {
  const rows = await db.query('SELECT * FROM KhachHang ORDER BY NgayTao DESC, MaKhachHang DESC');
  res.json(rows.map(map.customer));
}));

/** Đọc và kiểm tra dữ liệu khách hàng từ form */
async function customerInput(body, exceptId = -1) {
  const data = {
    name: v.required(body.fullName, 'Họ tên', 120),
    phone: v.phone(body.phone),
    email: v.email(body.email, { optional: true }),
    cccd: v.cccd(body.cccd),
    address: v.optional(body.address, 'Địa chỉ', 300),
    gender: v.str(body.gender),
  };
  if (data.gender && !map.toDb.gender[data.gender]) throw bad('Giới tính không hợp lệ');
  const dup = await db.query(
    `SELECT SoDienThoai, CCCD FROM KhachHang
      WHERE MaKhachHang <> :id AND (SoDienThoai = :phone OR (CCCD IS NOT NULL AND CCCD = :cccd))`,
    { id: exceptId, phone: data.phone, cccd: data.cccd || null },
  );
  if (dup.some((r) => r.SODIENTHOAI === data.phone)) throw conflict('Số điện thoại này đã được sử dụng');
  if (dup.length) throw conflict('Số CCCD này đã được sử dụng');
  if (await emailTaken(data.email, { exceptCustomer: exceptId })) {
    throw conflict('Email này đã được sử dụng');
  }
  return {
    ...data,
    email: data.email || null,
    cccd: data.cccd || null,
    address: data.address || null,
    gender: data.gender ? map.toDb.gender[data.gender] : null,
  };
}

/** Lễ tân thêm khách tại quầy (chưa có tài khoản online) */
router.post('/customers', auth.requireStaff, wrap(async (req, res) => {
  const d = await customerInput(req.body);
  const id = await db.tx((t) => t.insert(
    `INSERT INTO KhachHang (HoTen, SoDienThoai, Email, CCCD, DiaChi, GioiTinh, NgayTao)
     VALUES (:name, :phone, :email, :cccd, :address, :gender, ${DATE('created')})
     RETURNING MaKhachHang INTO :id`,
    { ...d, created: toDb(new Date()) },
  ));
  const rows = await db.query('SELECT * FROM KhachHang WHERE MaKhachHang = :id', { id });
  res.status(201).json(map.customer(rows[0]));
}));

function customerNum(req) {
  const p = map.parseUserId(req.params.id);
  if (!p || p.kind !== 'KH') throw notFound('Không tìm thấy khách hàng');
  return p.num;
}

router.put('/customers/:id', auth.requireStaff, wrap(async (req, res) => {
  const id = customerNum(req);
  const d = await customerInput(req.body, id);
  // Khách đã có tài khoản online thì không được xóa email đăng nhập
  const cur = (await db.query('SELECT MatKhauHash FROM KhachHang WHERE MaKhachHang = :id', { id }))[0];
  if (!cur) throw notFound('Không tìm thấy khách hàng');
  if (cur.MATKHAUHASH && !d.email) throw bad('Khách có tài khoản online, không được để trống email');
  await db.query(
    `UPDATE KhachHang SET HoTen = :name, SoDienThoai = :phone, Email = :email, CCCD = :cccd,
            DiaChi = :address, GioiTinh = :gender WHERE MaKhachHang = :id`,
    { ...d, id },
  );
  const rows = await db.query('SELECT * FROM KhachHang WHERE MaKhachHang = :id', { id });
  res.json(map.customer(rows[0]));
}));

// ---------- Nhân viên (chỉ Quản lý) ----------

router.get('/staff', auth.requireManager, wrap(async (_req, res) => {
  const rows = await db.query('SELECT * FROM NhanVien ORDER BY MaNhanVien');
  res.json(rows.map(map.staff));
}));

/** Tạo tên đăng nhập không trùng từ phần trước @ của email */
async function uniqueUsername(email) {
  const base = email.split('@')[0].replace(/[^a-z0-9._-]/gi, '').slice(0, 50) || 'nhanvien';
  for (let i = 0; ; i++) {
    const name = i === 0 ? base : `${base}${i + 1}`;
    const rows = await db.query('SELECT 1 FROM NhanVien WHERE LOWER(TenDangNhap) = :n', { n: name.toLowerCase() });
    if (!rows.length) return name;
  }
}

const roleOf = (r) => {
  const role = map.toDb.role[r];
  if (!role) throw bad('Vai trò không hợp lệ');
  return role;
};

router.post('/staff', auth.requireManager, wrap(async (req, res) => {
  const name = v.required(req.body.fullName, 'Họ tên', 120);
  const email = v.email(req.body.email);
  const phone = v.phone(req.body.phone);
  const password = v.password(req.body.password);
  const role = roleOf(req.body.role);
  if (await emailTaken(email)) throw conflict('Email này đã được sử dụng');
  const username = await uniqueUsername(email);
  const h = await auth.hash(password);
  const id = await db.tx((t) => t.insert(
    `INSERT INTO NhanVien (HoTen, TenDangNhap, MatKhauHash, Email, SoDienThoai, VaiTro, NgayTao)
     VALUES (:name, :username, :h, :email, :phone, :role, ${DATE('created')})
     RETURNING MaNhanVien INTO :id`,
    { name, username, h, email, phone, role, created: toDb(new Date()) },
  ));
  const rows = await db.query('SELECT * FROM NhanVien WHERE MaNhanVien = :id', { id });
  res.status(201).json(map.staff(rows[0]));
}));

function staffNum(req) {
  const p = map.parseUserId(req.params.id);
  if (!p || p.kind !== 'NV') throw notFound('Không tìm thấy nhân viên');
  return p.num;
}

/** Sửa nhân viên: không tự đổi vai trò của mình, luôn còn ít nhất một Quản lý */
router.put('/staff/:id', auth.requireManager, wrap(async (req, res) => {
  const id = staffNum(req);
  const name = v.required(req.body.fullName, 'Họ tên', 120);
  const email = v.email(req.body.email);
  const phone = v.phone(req.body.phone);
  const role = roleOf(req.body.role);
  await db.tx(async (t) => {
    const cur = await t.one('SELECT * FROM NhanVien WHERE MaNhanVien = :id FOR UPDATE', { id });
    if (!cur) throw notFound('Không tìm thấy nhân viên');
    if (id === req.user._num && role !== cur.VAITRO) throw bad('Bạn không thể tự đổi vai trò của mình');
    if (cur.VAITRO === 'QuanLy' && role !== 'QuanLy') {
      const m = await t.one(
        "SELECT COUNT(*) AS N FROM NhanVien WHERE VaiTro = 'QuanLy' AND TrangThai = 'HoatDong' AND MaNhanVien <> :id",
        { id });
      if (m.N === 0) throw bad('Hệ thống cần ít nhất một Quản lý');
    }
    if (await emailTaken(email, { exceptStaff: id })) throw conflict('Email này đã được sử dụng');
    await t.exec(
      'UPDATE NhanVien SET HoTen = :name, Email = :email, SoDienThoai = :phone, VaiTro = :role WHERE MaNhanVien = :id',
      { name, email, phone, role, id },
    );
  });
  const rows = await db.query('SELECT * FROM NhanVien WHERE MaNhanVien = :id', { id });
  res.json(map.staff(rows[0]));
}));

// ---------- Khóa tài khoản, đặt lại mật khẩu ----------

/** Quản lý khóa / mở khóa khách hàng hoặc lễ tân (không khóa Quản lý) */
router.post('/users/:id/toggle-lock', auth.requireManager, wrap(async (req, res) => {
  const p = map.parseUserId(req.params.id);
  if (!p) throw notFound('Không tìm thấy tài khoản');
  if (p.kind === 'NV') {
    const cur = (await db.query('SELECT VaiTro FROM NhanVien WHERE MaNhanVien = :id', { id: p.num }))[0];
    if (!cur) throw notFound('Không tìm thấy tài khoản');
    if (cur.VAITRO === 'QuanLy') throw forbidden('Không thể khóa tài khoản Quản lý');
    await db.query(
      `UPDATE NhanVien SET TrangThai = CASE TrangThai WHEN 'Khoa' THEN 'HoatDong' ELSE 'Khoa' END
        WHERE MaNhanVien = :id`, { id: p.num });
  } else {
    const cur = await db.query('SELECT 1 FROM KhachHang WHERE MaKhachHang = :id', { id: p.num });
    if (!cur.length) throw notFound('Không tìm thấy tài khoản');
    await db.query(
      `UPDATE KhachHang SET TrangThai = CASE TrangThai WHEN 'Khoa' THEN 'HoatDong' ELSE 'Khoa' END
        WHERE MaKhachHang = :id`, { id: p.num });
  }
  res.json(auth.publicUser(await auth.loadUser(req.params.id)));
}));

/**
 * Đặt mật khẩu mới cho tài khoản khác (khách quên mật khẩu, hoặc cấp tài
 * khoản online cho khách tạo tại quầy). Lễ tân chỉ đặt cho khách hàng.
 */
router.post('/users/:id/reset-password', auth.requireStaff, wrap(async (req, res) => {
  const actor = req.user;
  const target = await auth.loadUser(req.params.id);
  if (!target) throw notFound('Không tìm thấy tài khoản');
  if (target.id === actor.id) throw bad('Hãy đổi mật khẩu của bạn trong trang Hồ sơ');
  if (target._kind === 'NV' && !auth.isManager(actor)) {
    throw forbidden('Chỉ Quản lý được đặt lại mật khẩu nhân viên');
  }
  if (target.role === 'manager') throw forbidden('Không thể đặt lại mật khẩu của Quản lý khác');
  if (!target.email) throw bad('Khách chưa có email, hãy cập nhật email trước');
  const password = v.password(req.body.password);
  const table = target._kind === 'NV' ? 'NhanVien' : 'KhachHang';
  const key = target._kind === 'NV' ? 'MaNhanVien' : 'MaKhachHang';
  await db.query(`UPDATE ${table} SET MatKhauHash = :h WHERE ${key} = :id`,
    { h: await auth.hash(password), id: target._num });
  res.json(auth.publicUser(await auth.loadUser(target.id)));
}));

module.exports = router;
