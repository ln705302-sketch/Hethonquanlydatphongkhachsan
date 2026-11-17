/**
 * Tạo schema (01_schema.sql + 02_extensions.sql) và nạp dữ liệu mẫu.
 *   node src/migrate.js          -> tạo bảng nếu chưa có, nạp mẫu nếu DB trống
 *   node src/migrate.js --reset  -> xóa toàn bộ bảng rồi tạo lại từ đầu
 */
const fs = require('fs');
const path = require('path');

const db = require('./db');
const config = require('./config');
const { seed } = require('./seed');

const DB_DIR = path.join(__dirname, '..', 'db');
const SCRIPTS = ['01_schema.sql', '02_extensions.sql'];

// Thứ tự xóa bảng (bảng con trước)
const TABLES = [
  'LuuKhuyenMai', 'DanhGia', 'KhuyenMai', 'KhachSan', 'HoaDon', 'SuDungDichVu',
  'DatPhong', 'Phong', 'LoaiPhong', 'DichVu', 'NhanVien', 'KhachHang',
];
const VIEWS = ['VW_Phong_ChiTiet', 'VW_DatPhong_ChiTiet', 'VW_HoaDon_ChiTiet',
  'VW_DoanhThu_TheoNgay', 'VW_DoanhThu_TheoLoaiPhong'];

/**
 * Tách file SQL thành từng câu lệnh: câu thường kết thúc bằng ";",
 * khối PL/SQL (trigger, BEGIN...) kết thúc bằng dòng chỉ có "/".
 */
function splitSql(text) {
  const clean = text.replace(/\/\*[\s\S]*?\*\//g, '');
  const statements = [];
  let buf = [];
  let plsql = false;
  for (const raw of clean.split(/\r?\n/)) {
    const line = raw.replace(/\s+$/, '');
    if (!plsql && /^\s*--/.test(line)) continue;
    if (!buf.length && !line.trim()) continue;
    if (!buf.length && /^\s*(CREATE\s+(OR\s+REPLACE\s+)?(TRIGGER|PROCEDURE|FUNCTION|PACKAGE)|BEGIN|DECLARE)\b/i.test(line)) {
      plsql = true;
    }
    if (plsql) {
      if (line.trim() === '/') {
        statements.push(buf.join('\n'));
        buf = [];
        plsql = false;
      } else {
        buf.push(raw);
      }
      continue;
    }
    buf.push(line);
    if (line.endsWith(';')) {
      statements.push(buf.join('\n').replace(/;$/, ''));
      buf = [];
    }
  }
  if (buf.join('').trim()) statements.push(buf.join('\n'));
  return statements;
}

async function tableExists(name) {
  const rows = await db.query('SELECT COUNT(*) AS N FROM user_tables WHERE table_name = :t',
    { t: name.toUpperCase() });
  return rows[0].N > 0;
}

async function dropAll() {
  for (const v of VIEWS) {
    await db.query(`DROP VIEW ${v}`).catch(() => {});
  }
  for (const t of TABLES) {
    if (await tableExists(t)) await db.query(`DROP TABLE ${t} CASCADE CONSTRAINTS PURGE`);
  }
}

async function createSchema() {
  for (const file of SCRIPTS) {
    const sql = fs.readFileSync(path.join(DB_DIR, file), 'utf8');
    for (const stmt of splitSql(sql)) {
      try {
        await db.query(stmt);
      } catch (e) {
        e.message = `${file}: ${e.message}\n--- SQL ---\n${stmt.slice(0, 300)}`;
        throw e;
      }
    }
  }
  // ALTER TABLE ở 02_extensions làm view/trigger phụ thuộc bị INVALID:
  // biên dịch lại rồi mới kiểm tra
  const invalid = await db.query(
    "SELECT object_name, object_type FROM user_objects WHERE status <> 'VALID' AND object_type IN ('VIEW','TRIGGER')");
  for (const o of invalid) {
    await db.query(`ALTER ${o.OBJECT_TYPE} ${o.OBJECT_NAME} COMPILE`).catch(() => {});
  }
  const bad = await db.query("SELECT object_name FROM user_objects WHERE status <> 'VALID'");
  if (bad.length) throw new Error(`Đối tượng lỗi biên dịch: ${bad.map((r) => r.OBJECT_NAME).join(', ')}`);
}

/** Đảm bảo schema tồn tại; [reset] = xóa và tạo lại. Trả về true nếu vừa tạo mới */
async function migrate({ reset = false } = {}) {
  if (reset) await dropAll();
  if (await tableExists('KhachHang')) return false;
  await createSchema();
  await seed();
  return true;
}

module.exports = { migrate, splitSql, dropAll };

if (require.main === module) {
  const reset = process.argv.includes('--reset');
  (async () => {
    await db.init(config.db);
    const created = await migrate({ reset });
    console.log(created ? 'Đã tạo schema và nạp dữ liệu mẫu.' : 'Schema đã tồn tại, không thay đổi.');
    await db.close();
  })().catch(async (e) => {
    console.error(e.message);
    await db.close().catch(() => {});
    process.exit(1);
  });
}
