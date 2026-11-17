/**
 * Ngày giờ nghiệp vụ tính theo giờ địa phương của server (Asia/Ho_Chi_Minh).
 * Không dùng SYSDATE của Oracle để server và client luôn cùng một "hôm nay".
 */
const pad = (n) => String(n).padStart(2, '0');

/** Ghi đè "bây giờ" khi test (null = dùng đồng hồ thật) */
let fixedNow = null;
const setNow = (d) => { fixedNow = d; };
const now = () => (fixedNow ? new Date(fixedNow) : new Date());

const dateOnly = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const today = () => dateOnly(now());
const addDays = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n,
  d.getHours(), d.getMinutes(), d.getSeconds());

/** Số đêm giữa hai ngày (chỉ tính phần ngày) */
const nights = (a, b) => Math.round((dateOnly(b) - dateOnly(a)) / 86400000);

/** Date -> 'YYYY-MM-DDTHH:MM:SS' (khớp db.DF) */
const toDb = (d) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}` +
  `T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;

/** Chuỗi từ Oracle 'YYYY-MM-DDTHH:MM:SS' -> Date giờ địa phương */
const fromDb = (s) => {
  if (!s) return null;
  const [date, time = '00:00:00'] = String(s).split('T');
  const [y, m, d] = date.split('-').map(Number);
  const [hh, mm, ss] = time.split(':').map(Number);
  return new Date(y, m - 1, d, hh, mm, ss);
};

/** Đọc ngày 'YYYY-MM-DD' (hoặc ISO có giờ) từ client, null nếu sai */
function parseDate(s) {
  if (typeof s !== 'string') return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(s);
  if (!m) return null;
  const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
  if (d.getMonth() !== Number(m[2]) - 1) return null; // VD 2026-02-31
  return d;
}

module.exports = { now, setNow, today, dateOnly, addDays, nights, toDb, fromDb, parseDate };
