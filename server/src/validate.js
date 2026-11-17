const { bad } = require('./errors');

const EMAIL = /^[\w.+-]+@[\w-]+(\.[\w-]+)+$/;
const PHONE = /^0\d{9}$/;
const CCCD = /^\d{12}$/;

const str = (v) => (typeof v === 'string' ? v.trim() : v == null ? '' : String(v).trim());

/** Chuỗi bắt buộc, không quá [max] ký tự */
function required(v, label, max = 200) {
  const s = str(v);
  if (!s) throw bad(`${label} không được để trống`);
  if (s.length > max) throw bad(`${label} tối đa ${max} ký tự`);
  return s;
}

function optional(v, label, max = 500) {
  const s = str(v);
  if (s.length > max) throw bad(`${label} tối đa ${max} ký tự`);
  return s;
}

function email(v, { optional: opt = false } = {}) {
  const s = str(v).toLowerCase();
  if (!s && opt) return '';
  if (!s) throw bad('Vui lòng nhập email');
  if (!EMAIL.test(s) || s.length > 150) throw bad('Email không hợp lệ');
  return s;
}

function phone(v) {
  const s = str(v);
  if (!s) throw bad('Vui lòng nhập số điện thoại');
  if (!PHONE.test(s)) throw bad('Số điện thoại gồm 10 số, bắt đầu bằng 0');
  return s;
}

function cccd(v) {
  const s = str(v);
  if (s && !CCCD.test(s)) throw bad('CCCD gồm 12 chữ số');
  return s;
}

function password(v) {
  if (typeof v !== 'string' || v.length < 6) throw bad('Mật khẩu phải có ít nhất 6 ký tự');
  if (v.length > 100) throw bad('Mật khẩu quá dài');
  return v;
}

function number(v, label, min, max) {
  const n = typeof v === 'number' ? v : Number(str(v).replace(',', '.'));
  if (!Number.isFinite(n)) throw bad(`${label} phải là số`);
  if (n < min || n > max) throw bad(`${label} phải từ ${min} đến ${max}`);
  return n;
}

function integer(v, label, min, max) {
  const n = number(v, label, min, max);
  if (!Number.isInteger(n)) throw bad(`${label} phải là số nguyên`);
  return n;
}

function oneOf(v, allowed, label) {
  if (!allowed.includes(v)) throw bad(`${label} không hợp lệ`);
  return v;
}

function stringList(v, label, maxItems = 30) {
  if (v == null) return [];
  if (!Array.isArray(v) || v.some((x) => typeof x !== 'string')) {
    throw bad(`${label} không hợp lệ`);
  }
  if (v.length > maxItems) throw bad(`${label} tối đa ${maxItems} mục`);
  return v.map((x) => x.trim()).filter(Boolean);
}

const bool = (v) => v === true || v === 'true' || v === 1;

module.exports = { required, optional, email, phone, cccd, password, number, integer, oneOf, stringList, bool, str };
