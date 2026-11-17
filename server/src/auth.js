const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const config = require('./config');
const db = require('./db');
const map = require('./mappers');
const { ApiError, forbidden } = require('./errors');

const hash = (password) => bcrypt.hash(password, 10);
const verify = (password, hashed) => bcrypt.compare(password, hashed || '');

const sign = (user) =>
  jwt.sign({ sub: user.id }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });

/** Đọc user mới nhất từ DB theo id dạng KH<n> / NV<n> */
async function loadUser(id) {
  const parsed = map.parseUserId(id);
  if (!parsed) return null;
  if (parsed.kind === 'NV') {
    const rows = await db.query('SELECT * FROM NhanVien WHERE MaNhanVien = :n', { n: parsed.num });
    return rows[0] ? { ...map.staff(rows[0]), _num: parsed.num, _kind: 'NV' } : null;
  }
  const rows = await db.query('SELECT * FROM KhachHang WHERE MaKhachHang = :n', { n: parsed.num });
  return rows[0] ? { ...map.customer(rows[0]), _num: parsed.num, _kind: 'KH' } : null;
}

/**
 * Middleware: nếu có header "Authorization: Bearer <token>" thì gắn req.user.
 * Token sai / hết hạn / tài khoản bị khóa -> req.authError (chỉ báo lỗi
 * ở các route bắt buộc đăng nhập).
 */
async function attachUser(req, _res, next) {
  req.user = null;
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return next();
  try {
    const payload = jwt.verify(header.slice(7), config.jwtSecret);
    const user = await loadUser(payload.sub);
    if (!user) req.authError = 'Tài khoản không còn tồn tại';
    else if (user.isLocked) req.authError = 'Tài khoản đã bị khóa. Vui lòng liên hệ khách sạn';
    else req.user = user;
  } catch {
    req.authError = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
  }
  next();
}

const isStaff = (u) => u && u._kind === 'NV';
const isManager = (u) => isStaff(u) && u.role === 'manager';
const isCustomer = (u) => u && u._kind === 'KH';

function requireAuth(req, _res, next) {
  if (!req.user) return next(new ApiError(401, req.authError || 'Vui lòng đăng nhập'));
  next();
}
function requireStaff(req, res, next) {
  requireAuth(req, res, (err) => {
    if (err) return next(err);
    if (!isStaff(req.user)) return next(forbidden('Chỉ nhân viên khách sạn được thực hiện'));
    next();
  });
}
function requireManager(req, res, next) {
  requireAuth(req, res, (err) => {
    if (err) return next(err);
    if (!isManager(req.user)) return next(forbidden('Chỉ Quản lý được thực hiện'));
    next();
  });
}
function requireCustomer(req, res, next) {
  requireAuth(req, res, (err) => {
    if (err) return next(err);
    if (!isCustomer(req.user)) return next(forbidden('Chức năng dành cho tài khoản khách hàng'));
    next();
  });
}

/** Bỏ các trường nội bộ trước khi trả về client */
const publicUser = (u) => {
  if (!u) return null;
  const { _num, _kind, ...rest } = u;
  return rest;
};

module.exports = {
  hash, verify, sign, loadUser, attachUser,
  requireAuth, requireStaff, requireManager, requireCustomer,
  isStaff, isManager, isCustomer, publicUser,
};
