const db = require('../db');
const map = require('../mappers');
const { notFound } = require('../errors');

/** Bọc handler async để lỗi được chuyển tới error handler của Express */
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

/** Email đã được dùng bởi khách hàng hoặc nhân viên khác chưa */
async function emailTaken(email, { exceptCustomer = -1, exceptStaff = -1 } = {}) {
  if (!email) return false;
  const rows = await db.query(
    `SELECT (SELECT COUNT(*) FROM KhachHang WHERE LOWER(Email) = :e AND MaKhachHang <> :kh)
          + (SELECT COUNT(*) FROM NhanVien WHERE LOWER(Email) = :e AND MaNhanVien <> :nv) AS N
       FROM dual`,
    { e: email.toLowerCase(), kh: exceptCustomer, nv: exceptStaff },
  );
  return rows[0].N > 0;
}

/** Lấy id số từ :id trong URL, 404 nếu không hợp lệ */
function idParam(req, name = 'id') {
  const n = map.parseId(req.params[name]);
  if (n == null) throw notFound();
  return n;
}

module.exports = { wrap, emailTaken, idParam };
