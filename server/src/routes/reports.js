const express = require('express');

const db = require('../db');
const auth = require('../auth');
const config = require('../config');
const { bad, forbidden } = require('../errors');
const { parseDate, toDb, addDays } = require('../dates');
const { DATE } = require('../logic');
const { seed } = require('../seed');
const { wrap } = require('./helpers');

const router = express.Router();

/** Khoảng ngày lập hóa đơn [from, to] (tính cả ngày to) */
function range(q) {
  const from = q.from ? parseDate(q.from) : null;
  const to = q.to ? parseDate(q.to) : null;
  if ((q.from && !from) || (q.to && !to)) throw bad('Khoảng ngày không hợp lệ');
  return {
    sql: `AND (:f IS NULL OR hd.NgayLap >= ${DATE('f')}) AND (:t IS NULL OR hd.NgayLap < ${DATE('t')})`,
    binds: { f: from ? toDb(from) : null, t: to ? toDb(addDays(to, 1)) : null },
  };
}

const row = (r, label) => ({
  key: r.KHOA,
  label,
  invoices: r.SOHOADON,
  roomRevenue: Number(r.TIENPHONG),
  serviceRevenue: Number(r.TIENDICHVU),
  total: Number(r.TONG),
});

/** Doanh thu theo ngày / tháng / năm (chỉ hóa đơn "Đã thanh toán") */
router.get('/reports/revenue', auth.requireManager, wrap(async (req, res) => {
  const fmt = { day: 'YYYY-MM-DD', month: 'YYYY-MM', year: 'YYYY' }[req.query.period || 'day'];
  if (!fmt) throw bad('Kỳ báo cáo không hợp lệ');
  const r = range(req.query);
  const rows = await db.query(
    `SELECT TO_CHAR(hd.NgayLap, '${fmt}') AS Khoa, COUNT(*) AS SoHoaDon,
            SUM(hd.TienPhong) AS TienPhong, SUM(hd.TienDichVu) AS TienDichVu, SUM(hd.TongThanhToan) AS Tong
       FROM HoaDon hd
      WHERE hd.TrangThaiTT = 'DaThanhToan' ${r.sql}
      GROUP BY TO_CHAR(hd.NgayLap, '${fmt}')
      ORDER BY Khoa DESC`, r.binds);
  const label = (k) => k.split('-').reverse().join('/');
  res.json(rows.map((x) => row(x, label(x.KHOA))));
}));

/** Doanh thu theo loại phòng */
router.get('/reports/revenue-by-room-type', auth.requireManager, wrap(async (req, res) => {
  const r = range(req.query);
  const rows = await db.query(
    `SELECT lp.TenLoaiPhong AS Khoa, COUNT(*) AS SoHoaDon,
            SUM(hd.TienPhong) AS TienPhong, SUM(hd.TienDichVu) AS TienDichVu, SUM(hd.TongThanhToan) AS Tong
       FROM HoaDon hd
       JOIN DatPhong dp ON dp.MaDatPhong = hd.MaDatPhong
       JOIN Phong p ON p.MaPhong = dp.MaPhong
       JOIN LoaiPhong lp ON lp.MaLoaiPhong = p.MaLoaiPhong
      WHERE hd.TrangThaiTT = 'DaThanhToan' ${r.sql}
      GROUP BY lp.TenLoaiPhong
      ORDER BY Tong DESC`, r.binds);
  res.json(rows.map((x) => row(x, x.KHOA)));
}));

/** Khôi phục dữ liệu mẫu (chỉ Quản lý, tắt bằng ALLOW_RESET=false) */
router.post('/admin/reset', auth.requireManager, wrap(async (_req, res) => {
  if (!config.allowReset) throw forbidden('Chức năng khôi phục dữ liệu mẫu đang bị tắt');
  await seed();
  res.json({ ok: true });
}));

module.exports = router;
