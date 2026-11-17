/**
 * Test API trên Oracle thật (schema SUNRISE_TEST, tách khỏi dữ liệu SUNRISE_HOTEL).
 * Mỗi test chạy trên bộ dữ liệu mẫu mới (seed lại trước mỗi test).
 * Ngày của dữ liệu mẫu tính tương đối so với hôm nay:
 *   Đơn 1: KH1, phòng 201 (Deluxe), -20 ngày, 2 đêm, đã trả phòng, có hóa đơn
 *   Đơn 2: KH1, phòng 101 (Standard), +10 ngày, 3 đêm, đã đặt
 *   Đơn 3: KH1, phòng 301 (Suite),    +5 ngày, 2 đêm, đã đặt
 *   Đơn 4: KH1, phòng 102, +25 ngày, đã hủy
 *   Đơn 5: KH2, phòng 202 (Deluxe), -1 ngày, 3 đêm, đang ở (giặt ủi 1,5kg)
 *   Đơn 6: KH2, phòng 102 (Standard), hôm nay, 2 đêm, đã đặt
 *   Đơn 7: KH2, phòng 301, -40 ngày, 1 đêm, đã trả phòng, có hóa đơn
 */
const { describe, it, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

const config = require('../src/config');
const db = require('../src/db');
const { migrate } = require('../src/migrate');
const { seed } = require('../src/seed');
const { createApp } = require('../src/app');
const { today, addDays, toDb } = require('../src/dates');

const app = createApp();
const day = (offset) => toDb(addDays(today(), offset)).slice(0, 10);

const tokens = {};
async function login(email, password) {
  const res = await request(app).post('/api/auth/login').send({ email, password });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  return res.body.token;
}
const api = (method, path, token, body) => {
  let r = request(app)[method](`/api${path}`);
  if (token) r = r.set('Authorization', `Bearer ${token}`);
  return body === undefined ? r : r.send(body);
};

const bookingBody = (over = {}) => ({
  roomTypeId: '1', checkIn: day(50), checkOut: day(53), guests: 2,
  guestName: 'Khách Test', guestPhone: '0912345678', guestEmail: 'test@example.com',
  note: '', paymentMethod: 'cash', ...over,
});

before(async () => {
  await db.init(config.testDb);
  await migrate({ reset: true });
});
after(async () => { await db.close(); });
beforeEach(async () => {
  await seed();
  tokens.admin = await login('admin', 'admin123');
  tokens.letan = await login('letan01@sunrisehotel.local', 'letan123');
  tokens.an = await login('an@example.com', 'user123');
  tokens.binh = await login('binh@example.com', 'binh123');
});

describe('Danh mục công khai', () => {
  it('trả về khách sạn, loại phòng, phòng, dịch vụ, mã ưu đãi, đánh giá', async () => {
    assert.equal((await api('get', '/hotel')).body.name, 'Sunrise Hotel');
    const types = (await api('get', '/room-types')).body;
    assert.deepEqual(types.map((t) => t.name), ['Standard', 'Deluxe', 'Suite']);
    assert.equal(types[0].pricePerNight, 650000);
    assert.equal((await api('get', '/rooms')).body.length, 5);
    assert.equal((await api('get', '/services')).body.length, 3);
    assert.equal((await api('get', '/promotions')).body.length, 3);
    assert.equal((await api('get', '/reviews')).body.length, 4);
  });

  it('ngày tháng trả về dạng YYYY-MM-DDTHH:MM:SS (giờ địa phương)', async () => {
    const b = (await api('get', '/bookings/6', tokens.binh)).body;
    assert.equal(b.checkIn, `${day(0)}T00:00:00`);
    assert.equal(b.checkOut, `${day(2)}T00:00:00`);
  });

  it('API không tồn tại trả 404, JSON lỗi trả 400', async () => {
    assert.equal((await api('get', '/khong-co')).status, 404);
    const res = await request(app).post('/api/auth/login')
      .set('Content-Type', 'application/json').send('{sai');
    assert.equal(res.status, 400);
  });
});

describe('Đăng nhập, đăng ký, phân quyền', () => {
  it('đăng nhập bằng email hoặc tên đăng nhập, sai mật khẩu bị từ chối', async () => {
    assert.ok(await login('ADMIN@sunrisehotel.local', 'admin123'));
    const bad = await api('post', '/auth/login', null, { email: 'admin', password: 'sai' });
    assert.equal(bad.status, 401);
    assert.equal(bad.body.error, 'Email hoặc mật khẩu không đúng');
  });

  it('mật khẩu được băm bcrypt, không lưu dạng thô', async () => {
    const rows = await db.query('SELECT MatKhauHash FROM NhanVien WHERE TenDangNhap = :u', { u: 'admin' });
    assert.match(rows[0].MATKHAUHASH, /^\$2[aby]\$10\$/);
    const me = (await api('get', '/auth/me', tokens.admin)).body;
    assert.equal(me.role, 'manager');
    assert.equal(me.password, undefined);
    assert.equal(me.hasAccount, true);
  });

  it('đăng ký: tạo tài khoản, chặn trùng email (kể cả email nhân viên) và SĐT', async () => {
    const ok = await api('post', '/auth/register', null,
      { fullName: 'Lê Mới', email: 'Moi@Example.com', phone: '0911111111', password: 'abc123' });
    assert.equal(ok.status, 201);
    assert.equal(ok.body.user.email, 'moi@example.com');
    assert.ok(ok.body.token);
    const dupMail = await api('post', '/auth/register', null,
      { fullName: 'X', email: 'letan01@sunrisehotel.local', phone: '0911111112', password: 'abc123' });
    assert.equal(dupMail.status, 409);
    const dupPhone = await api('post', '/auth/register', null,
      { fullName: 'X', email: 'x@example.com', phone: '0900000001', password: 'abc123' });
    assert.equal(dupPhone.body.error, 'Số điện thoại này đã được sử dụng');
    const weak = await api('post', '/auth/register', null,
      { fullName: 'X', email: 'y@example.com', phone: '0911111113', password: '123' });
    assert.equal(weak.status, 400);
  });

  it('không có token / token sai -> 401; khách không vào được API nhân viên', async () => {
    assert.equal((await api('get', '/auth/me')).status, 401);
    assert.equal((await api('get', '/auth/me', 'abc.def.ghi')).status, 401);
    assert.equal((await api('get', '/customers', tokens.an)).status, 403);
    assert.equal((await api('get', '/staff', tokens.letan)).status, 403);
    assert.equal((await api('get', '/reports/revenue', tokens.letan)).status, 403);
  });

  it('khóa tài khoản: không đăng nhập được và token cũ mất hiệu lực', async () => {
    assert.equal((await api('post', '/users/KH1/toggle-lock', tokens.letan)).status, 403);
    const locked = await api('post', '/users/KH1/toggle-lock', tokens.admin);
    assert.equal(locked.body.isLocked, true);
    const res = await api('post', '/auth/login', null, { email: 'an@example.com', password: 'user123' });
    assert.equal(res.status, 403);
    assert.equal((await api('get', '/bookings', tokens.an)).status, 401);
    assert.equal((await api('post', '/users/NV1/toggle-lock', tokens.admin)).status, 403);
    await api('post', '/users/KH1/toggle-lock', tokens.admin);
    assert.ok(await login('an@example.com', 'user123'));
  });
});

describe('Hồ sơ', () => {
  it('khách sửa hồ sơ (giới tính, ngày sinh), chặn trùng SĐT', async () => {
    const res = await api('put', '/me', tokens.an, {
      fullName: 'Nguyễn Văn An', phone: '0900000001', cccd: '079098000001',
      address: 'Hà Nội', gender: 'Khác', birthDate: '1999-01-02',
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.gender, 'Khác');
    assert.equal(res.body.birthDate, '1999-01-02T00:00:00');
    const dup = await api('put', '/me', tokens.an, { fullName: 'An', phone: '0900000002' });
    assert.equal(dup.status, 409);
    const future = await api('put', '/me', tokens.an,
      { fullName: 'An', phone: '0900000001', birthDate: day(5) });
    assert.equal(future.status, 400);
  });

  it('đổi mật khẩu cần mật khẩu cũ đúng', async () => {
    assert.equal((await api('put', '/me/password', tokens.an,
      { oldPassword: 'sai', newPassword: 'moi123' })).status, 400);
    assert.equal((await api('put', '/me/password', tokens.an,
      { oldPassword: 'user123', newPassword: 'moi123' })).status, 200);
    assert.ok(await login('an@example.com', 'moi123'));
  });
});

describe('Phòng trống và đặt phòng', () => {
  it('đếm phòng trống theo khoảng ngày', async () => {
    const res = await api('get', `/availability?checkIn=${day(0)}&checkOut=${day(2)}`);
    // Standard: 102 có đơn hôm nay; Deluxe: 202 đang ở; Suite: 301 trống
    assert.deepEqual(res.body.map((r) => r.available), [1, 1, 1]);
    const later = await api('get', `/availability?checkIn=${day(5)}&checkOut=${day(6)}`);
    assert.deepEqual(later.body.map((r) => r.available), [2, 2, 0]);
    assert.equal((await api('get', `/availability?checkIn=${day(3)}&checkOut=${day(3)}`)).status, 400);
  });

  it('đặt phòng có mã ưu đãi; mã chỉ dùng một lần, hủy đơn thì dùng lại được', async () => {
    const res = await api('post', '/bookings', tokens.an, bookingBody({ promoCode: 'sunrise15' }));
    assert.equal(res.status, 201, JSON.stringify(res.body));
    assert.equal(res.body.status, 'booked');
    assert.equal(res.body.userId, 'KH1');
    assert.equal(res.body.discount, 292500); // 15% của 3 x 650.000
    assert.equal(res.body.promoCode, 'SUNRISE15');
    const again = await api('post', '/bookings', tokens.an, bookingBody({ promoCode: 'SUNRISE15', checkIn: day(60), checkOut: day(63) }));
    assert.equal(again.body.error, 'Mã này đã được sử dụng');
    assert.equal((await api('post', `/bookings/${res.body.id}/cancel`, tokens.an)).status, 200);
    const reuse = await api('post', '/bookings', tokens.an, bookingBody({ promoCode: 'SUNRISE15', checkIn: day(60), checkOut: day(63) }));
    assert.equal(reuse.status, 201);
  });

  it('điều kiện mã: số đêm tối thiểu, chỉ đơn đầu tiên, mã tạm ngừng', async () => {
    const short = await api('post', '/bookings', tokens.an, bookingBody({ promoCode: 'SUNRISE15', checkOut: day(51) }));
    assert.equal(short.body.error, 'Cần đặt từ 3 đêm trở lên');
    const first = await api('post', '/bookings', tokens.an, bookingBody({ promoCode: 'XINCHAO10' }));
    assert.equal(first.body.error, 'Chỉ áp dụng cho đơn đặt phòng đầu tiên');
    const reg = await api('post', '/auth/register', null,
      { fullName: 'Khách Mới', email: 'new@example.com', phone: '0922222222', password: 'abc123' });
    const ok = await api('post', '/bookings', reg.body.token, bookingBody({ promoCode: 'XINCHAO10', checkOut: day(51) }));
    assert.equal(ok.body.discount, 65000);
    await api('post', '/promotions/WEEKEND300/toggle', tokens.admin);
    const paused = await api('post', '/bookings', tokens.an, bookingBody({ promoCode: 'WEEKEND300' }));
    assert.equal(paused.body.error, 'Mã đã ngừng áp dụng');
  });

  it('chặn đặt quá sức chứa, ngày quá khứ, hết phòng, loại phòng ngừng kinh doanh', async () => {
    assert.equal((await api('post', '/bookings', tokens.an, bookingBody({ guests: 3 }))).body.error,
      'Số khách vượt quá sức chứa của phòng');
    assert.equal((await api('post', '/bookings', tokens.an, bookingBody({ checkIn: day(-1), checkOut: day(1) }))).body.error,
      'Không thể đặt phòng cho ngày trong quá khứ');
    const full = await api('post', '/bookings', tokens.an, bookingBody({ roomTypeId: '3', checkIn: day(5), checkOut: day(7) }));
    assert.equal(full.status, 409);
    const types = (await api('get', '/room-types')).body;
    await api('put', '/room-types/1', tokens.admin, { ...types[0], isActive: false });
    assert.equal((await api('post', '/bookings', tokens.an, bookingBody())).body.error,
      'Loại phòng này đã ngừng kinh doanh');
  });

  it('hai người đặt cùng lúc phòng cuối cùng: chỉ một người thành công', async () => {
    const body = bookingBody({ roomTypeId: '3', checkIn: day(100), checkOut: day(102) });
    const [a, b] = await Promise.all([
      api('post', '/bookings', tokens.an, body),
      api('post', '/bookings', tokens.binh, body),
    ]);
    assert.deepEqual([a.status, b.status].sort(), [201, 409]);
  });

  it('trigger Oracle vẫn chặn trùng lịch nếu chèn thẳng vào DB', async () => {
    await assert.rejects(
      db.query(`INSERT INTO DatPhong (MaKhachHang, MaPhong, NgayNhanDuKien, NgayTraDuKien, DonGiaPhong)
                VALUES (1, 5, TO_DATE(:a,'YYYY-MM-DD'), TO_DATE(:b,'YYYY-MM-DD'), 1)`, { a: day(5), b: day(6) }),
      (e) => e.errorNum === 20025);
  });

  it('nhân viên đặt tại quầy cho khách; khách chỉ thấy đơn của mình', async () => {
    const res = await api('post', '/bookings', tokens.letan, bookingBody({ userId: 'KH2' }));
    assert.equal(res.status, 201);
    assert.equal(res.body.userId, 'KH2');
    assert.equal(res.body.staffId, 'NV2');
    const mine = (await api('get', '/bookings', tokens.an)).body;
    assert.ok(mine.every((b) => b.userId === 'KH1'));
    assert.equal(mine.length, 4);
    assert.equal((await api('get', '/bookings/5', tokens.an)).status, 404);
    assert.equal((await api('get', '/bookings', tokens.letan)).body.length, 8);
  });
});

describe('Hủy đơn', () => {
  it('khách hủy trước ngày nhận; từ ngày nhận chỉ Quản lý hủy được', async () => {
    assert.equal((await api('post', '/bookings/2/cancel', tokens.an)).body.status, 'cancelled');
    assert.equal((await api('post', '/bookings/6/cancel', tokens.binh)).status, 400);
    assert.equal((await api('post', '/bookings/6/cancel', tokens.letan)).status, 403);
    assert.equal((await api('post', '/bookings/6/cancel', tokens.admin)).body.status, 'cancelled');
    assert.equal((await api('post', '/bookings/3/cancel', tokens.binh)).status, 404); // đơn người khác
    assert.equal((await api('post', '/bookings/5/cancel', tokens.admin)).status, 400); // đang ở
  });
});

describe('Nhận phòng, dịch vụ, trả phòng, hóa đơn', () => {
  it('nhận phòng đúng ngày; phòng chuyển sang Đang ở', async () => {
    assert.equal((await api('post', '/bookings/6/check-in', tokens.binh)).status, 403);
    assert.equal((await api('post', '/bookings/2/check-in', tokens.letan)).body.error, 'Chưa đến ngày nhận phòng');
    const res = await api('post', '/bookings/6/check-in', tokens.letan, {});
    assert.equal(res.status, 200, JSON.stringify(res.body));
    assert.equal(res.body.status, 'checkedIn');
    assert.ok(res.body.actualCheckIn);
    const room = (await api('get', '/rooms')).body.find((r) => r.number === '102');
    assert.equal(room.status, 'occupied');
    assert.equal((await api('post', '/bookings/6/check-in', tokens.letan, {})).status, 400);
  });

  it('nhận phòng đổi sang phòng khác cùng loại; chặn phòng khác loại / đang bảo trì', async () => {
    assert.equal((await api('post', '/bookings/6/check-in', tokens.letan, { roomId: '3' })).body.error,
      'Chỉ đổi sang phòng cùng loại');
    await api('put', '/rooms/1', tokens.admin, { typeId: '1', number: '101', floor: 1, note: '', status: 'maintenance' });
    assert.equal((await api('post', '/bookings/6/check-in', tokens.letan, { roomId: '1' })).status, 409);
    await api('put', '/rooms/1', tokens.admin, { typeId: '1', number: '101', floor: 1, note: '', status: 'available' });
    const res = await api('post', '/bookings/6/check-in', tokens.letan, { roomId: '1' });
    assert.equal(res.body.roomNumber, '101');
  });

  it('ghi dịch vụ: trigger chốt đơn giá; chỉ cho đơn đang ở và dịch vụ đang hoạt động', async () => {
    const res = await api('post', '/bookings/5/usages', tokens.letan, { serviceId: '1', quantity: 2 });
    assert.equal(res.status, 201);
    assert.equal(res.body.unitPrice, 100000);
    assert.equal(res.body.amount, 200000);
    assert.equal((await api('post', '/bookings/2/usages', tokens.letan, { serviceId: '1', quantity: 1 })).status, 400);
    const svc = (await api('get', '/services')).body[0];
    await api('put', '/services/1', tokens.admin, { ...svc, isActive: false });
    assert.equal((await api('post', '/bookings/5/usages', tokens.letan, { serviceId: '1', quantity: 1 })).body.error,
      'Dịch vụ đang ngừng cung cấp');
    assert.equal((await api('delete', `/usages/${res.body.id}`, tokens.letan)).status, 200);
    const usages = (await api('get', '/usages', tokens.binh)).body;
    assert.ok(usages.every((u) => ['5', '6', '7'].includes(u.bookingId)));
  });

  it('trả phòng: hóa đơn đúng tiền, đơn + phòng cập nhật cùng lúc, không trả hai lần', async () => {
    const bill = (await api('get', '/bookings/5/bill', tokens.letan)).body;
    // Nhận phòng hôm qua -> 1 đêm Deluxe 950.000 + giặt ủi 1,5 x 80.000
    assert.deepEqual(bill, { nights: 1, roomCharge: 950000, serviceCharge: 120000, discount: 0, total: 1070000 });
    const short = await api('post', '/bookings/5/check-out', tokens.letan, { paidAmount: 1000000, method: 'cash' });
    assert.equal(short.body.error, 'Số tiền khách trả chưa đủ');
    const res = await api('post', '/bookings/5/check-out', tokens.letan, { paidAmount: 1100000, method: 'card' });
    assert.equal(res.status, 201, JSON.stringify(res.body));
    assert.equal(res.body.invoice.total, 1070000);
    assert.equal(res.body.invoice.change, 30000);
    assert.equal(res.body.invoice.method, 'card');
    assert.equal(res.body.booking.status, 'checkedOut');
    const room = (await api('get', '/rooms')).body.find((r) => r.number === '202');
    assert.equal(room.status, 'available');
    assert.equal((await api('post', '/bookings/5/check-out', tokens.letan, { paidAmount: 2000000 })).status, 400);
    assert.equal((await api('get', '/invoices', tokens.binh)).body.length, 2);
    assert.equal((await api('get', '/invoices', tokens.an)).body.length, 1);
  });

  it('trả phòng lỗi giữa chừng thì rollback toàn bộ (không có hóa đơn mồ côi)', async () => {
    // Gây lỗi ở bước cuối: xóa phòng 202 khỏi danh mục là không thể (FK),
    // nên mô phỏng bằng cách khóa CHECK của Phong để UPDATE Phong thất bại
    await db.query("ALTER TABLE Phong ADD CONSTRAINT CK_TEST_KHONG_TRONG CHECK (TrangThai <> 'Trong') ENABLE NOVALIDATE");
    try {
      const res = await api('post', '/bookings/5/check-out', tokens.letan, { paidAmount: 2000000 });
      assert.equal(res.status, 400);
      assert.equal((await db.query('SELECT COUNT(*) AS N FROM HoaDon WHERE MaDatPhong = 5'))[0].N, 0);
      assert.equal((await db.query('SELECT TrangThai FROM DatPhong WHERE MaDatPhong = 5'))[0].TRANGTHAI, 'DaNhanPhong');
    } finally {
      await db.query('ALTER TABLE Phong DROP CONSTRAINT CK_TEST_KHONG_TRONG');
    }
  });

  it('hoàn tiền: chỉ Quản lý, doanh thu loại hóa đơn đã hoàn', async () => {
    const before = (await api('get', '/reports/revenue?period=year', tokens.admin)).body;
    assert.equal(before[0].total, 3700000);
    assert.equal((await api('post', '/invoices/2/refund', tokens.letan)).status, 403);
    assert.equal((await api('post', '/invoices/2/refund', tokens.admin)).body.status, 'refunded');
    assert.equal((await api('post', '/invoices/2/refund', tokens.admin)).status, 400);
    const afterRows = (await api('get', '/reports/revenue?period=year', tokens.admin)).body;
    assert.equal(afterRows[0].total, 2100000);
    const byType = (await api('get', '/reports/revenue-by-room-type', tokens.admin)).body;
    assert.deepEqual(byType.map((r) => [r.label, r.total]), [['Deluxe', 2100000]]);
  });
});

describe('Quản trị danh mục', () => {
  it('loại phòng: thêm, trùng tên, không xóa khi còn phòng', async () => {
    const body = { name: 'Family', description: 'Phòng gia đình', bedType: '2 giường', maxGuests: 5,
      area: 50, pricePerNight: 2000000, images: [], amenities: ['TV'], isActive: true };
    const res = await api('post', '/room-types', tokens.admin, body);
    assert.equal(res.status, 201);
    assert.equal((await api('post', '/room-types', tokens.admin, body)).body.error, 'Tên loại phòng đã tồn tại');
    assert.equal((await api('delete', '/room-types/1', tokens.admin)).status, 409);
    assert.equal((await api('delete', `/room-types/${res.body.id}`, tokens.admin)).status, 200);
    assert.equal((await api('post', '/room-types', tokens.letan, body)).status, 403);
  });

  it('phòng: trùng số phòng, không xóa phòng đã có đơn, không đổi trạng thái phòng đang ở', async () => {
    const res = await api('post', '/rooms', tokens.admin, { typeId: '1', number: '103', floor: 1, status: 'available' });
    assert.equal(res.status, 201);
    assert.equal((await api('post', '/rooms', tokens.admin, { typeId: '1', number: '103', floor: 1 })).body.error, 'Số phòng đã tồn tại');
    assert.equal((await api('post', '/rooms', tokens.admin, { typeId: '1', number: '104', status: 'occupied' })).status, 400);
    assert.equal((await api('delete', '/rooms/1', tokens.admin)).status, 409);
    assert.equal((await api('delete', `/rooms/${res.body.id}`, tokens.admin)).status, 200);
    const busy = await api('put', '/rooms/4', tokens.admin, { typeId: '2', number: '202', floor: 2, status: 'maintenance' });
    assert.equal(busy.body.error, 'Phòng đang có khách ở, không thể đổi trạng thái');
  });

  it('dịch vụ: không xóa dịch vụ đã dùng; thông tin khách sạn sửa được', async () => {
    assert.equal((await api('delete', '/services/1', tokens.admin)).status, 409);
    assert.equal((await api('delete', '/services/3', tokens.admin)).status, 200);
    const hotel = (await api('get', '/hotel')).body;
    const res = await api('put', '/hotel', tokens.admin, { ...hotel, phone: '028 1234 5678', stars: 4 });
    assert.equal(res.body.stars, 4);
    assert.equal((await api('put', '/hotel', tokens.admin, { ...hotel, stars: 9 })).status, 400);
  });
});

describe('Khách hàng và nhân viên', () => {
  it('lễ tân thêm khách tại quầy, chặn trùng SĐT/CCCD/email, cấp tài khoản online', async () => {
    const body = { fullName: 'Khách Quầy', phone: '0933333333', email: '', cccd: '', address: '', gender: 'Nữ' };
    const res = await api('post', '/customers', tokens.letan, body);
    assert.equal(res.status, 201);
    assert.equal(res.body.hasAccount, false);
    assert.equal((await api('post', '/customers', tokens.letan, body)).status, 409);
    assert.equal((await api('post', '/customers', tokens.letan, { ...body, phone: '0933333334', cccd: '079098000001' })).body.error,
      'Số CCCD này đã được sử dụng');
    assert.equal((await api('post', `/users/${res.body.id}/reset-password`, tokens.letan, { password: 'abc123' })).body.error,
      'Khách chưa có email, hãy cập nhật email trước');
    await api('put', `/customers/${res.body.id}`, tokens.letan, { ...body, email: 'quay@example.com' });
    const granted = await api('post', `/users/${res.body.id}/reset-password`, tokens.letan, { password: 'abc123' });
    assert.equal(granted.body.hasAccount, true);
    assert.ok(await login('quay@example.com', 'abc123'));
  });

  it('nhân viên: thêm, sửa, không tự hạ quyền, lễ tân không đặt lại mật khẩu nhân viên', async () => {
    const res = await api('post', '/staff', tokens.admin,
      { fullName: 'Lễ tân 02', email: 'letan02@sunrisehotel.local', phone: '0909000333', password: 'abc123', role: 'receptionist' });
    assert.equal(res.status, 201);
    assert.equal(res.body.username, 'letan02');
    assert.ok(await login('letan02', 'abc123'));
    const upd = await api('put', `/staff/${res.body.id}`, tokens.admin,
      { fullName: 'Lễ tân Hai', email: 'letan02@sunrisehotel.local', phone: '0909000333', role: 'manager' });
    assert.equal(upd.body.role, 'manager');
    const self = await api('put', '/staff/NV1', tokens.admin,
      { fullName: 'QTV', email: 'admin@sunrisehotel.local', phone: '0909000111', role: 'receptionist' });
    assert.equal(self.body.error, 'Bạn không thể tự đổi vai trò của mình');
    assert.equal((await api('post', '/users/NV1/reset-password', tokens.letan, { password: 'abc123' })).status, 403);
    assert.equal((await api('post', '/users/NV2/reset-password', tokens.letan, { password: 'abc123' })).status, 400); // tự đặt cho mình
    assert.equal((await api('post', '/users/NV2/reset-password', tokens.admin, { password: 'xyz789' })).status, 200);
    assert.ok(await login('letan01', 'xyz789'));
    assert.equal((await api('post', `/users/${res.body.id}/reset-password`, tokens.admin, { password: 'xyz789' })).status, 403);
  });
});

describe('Đánh giá', () => {
  it('chỉ khách đã trả phòng mới viết, mỗi người một lần; sửa / xóa của mình', async () => {
    const reg = await api('post', '/auth/register', null,
      { fullName: 'Chưa Ở', email: 'chuao@example.com', phone: '0944444444', password: 'abc123' });
    assert.equal((await api('post', '/reviews', reg.body.token, { score: 9, comment: 'Rất tuyệt vời luôn' })).status, 403);
    const res = await api('post', '/reviews', tokens.an, { score: 9, comment: 'Phòng sạch và đẹp' });
    assert.equal(res.status, 201);
    assert.equal(res.body.userId, 'KH1');
    assert.equal((await api('post', '/reviews', tokens.an, { score: 8, comment: 'Đánh giá lần hai' })).body.error, 'Bạn đã đánh giá rồi');
    assert.equal((await api('post', '/reviews', tokens.binh, { score: 8, comment: 'ngắn' })).status, 400);
    const upd = await api('put', `/reviews/${res.body.id}`, tokens.an, { score: 7, comment: 'Đã sửa lại nhận xét' });
    assert.equal(upd.body.score, 7);
    assert.ok(upd.body.updatedAt);
    assert.equal((await api('put', `/reviews/${res.body.id}`, tokens.binh, { score: 1, comment: 'Sửa của người khác' })).status, 403);
    assert.equal((await api('delete', `/reviews/${res.body.id}`, tokens.binh)).status, 403);
    assert.equal((await api('delete', `/reviews/${res.body.id}`, tokens.an)).status, 200);
  });

  it('Quản lý ẩn đánh giá: công khai không thấy, chủ vẫn thấy', async () => {
    const res = await api('post', '/reviews', tokens.an, { score: 2, comment: 'Nội dung không phù hợp' });
    assert.equal((await api('post', `/reviews/${res.body.id}/toggle-hidden`, tokens.letan)).status, 403);
    assert.equal((await api('post', `/reviews/${res.body.id}/toggle-hidden`, tokens.admin)).body.isHidden, true);
    assert.equal((await api('get', '/reviews')).body.length, 4);
    assert.equal((await api('get', '/reviews', tokens.an)).body.length, 5);
    assert.equal((await api('get', '/reviews', tokens.admin)).body.length, 5);
  });
});

describe('Mã ưu đãi', () => {
  it('Quản lý thêm, sửa, đổi mã (đơn và mã đã lưu đổi theo), xóa', async () => {
    const body = { code: 'he2026', title: 'Hè', description: '', percent: 20, fixedAmount: 0,
      minNights: 1, firstBookingOnly: false, isActive: true };
    assert.equal((await api('post', '/promotions', tokens.admin, body)).body.code, 'HE2026');
    assert.equal((await api('post', '/promotions', tokens.admin, body)).status, 409);
    assert.equal((await api('post', '/promotions', tokens.admin, { ...body, code: 'ZERO', percent: 0 })).status, 400);
    assert.equal((await api('post', '/me/saved-promos', tokens.an, { code: 'HE2026' })).status, 201);
    assert.equal((await api('post', '/me/saved-promos', tokens.an, { code: 'HE2026' })).status, 201); // lưu lại không lỗi
    const b = await api('post', '/bookings', tokens.an, bookingBody({ promoCode: 'HE2026' }));
    assert.equal(b.body.discount, 390000);
    const renamed = await api('put', '/promotions/HE2026', tokens.admin, { ...body, code: 'SUMMER20' });
    assert.equal(renamed.body.code, 'SUMMER20');
    assert.deepEqual((await api('get', '/me/saved-promos', tokens.an)).body, ['SUMMER20']);
    assert.equal((await api('get', `/bookings/${b.body.id}`, tokens.an)).body.promoCode, 'SUMMER20');
    await api('delete', '/promotions/SUMMER20', tokens.admin);
    assert.deepEqual((await api('get', '/me/saved-promos', tokens.an)).body, []);
    assert.equal((await api('get', `/bookings/${b.body.id}`, tokens.an)).body.discount, 390000);
    assert.equal((await api('post', '/me/saved-promos', tokens.admin, { code: 'SUNRISE15' })).status, 403);
  });

  it('khách chỉ thấy mã đang áp dụng, Quản lý thấy tất cả', async () => {
    await api('post', '/promotions/XINCHAO10/toggle', tokens.admin);
    assert.equal((await api('get', '/promotions', tokens.an)).body.length, 2);
    assert.equal((await api('get', '/promotions', tokens.admin)).body.length, 3);
  });
});

describe('Khôi phục dữ liệu mẫu', () => {
  it('chỉ Quản lý được khôi phục', async () => {
    await api('post', '/bookings/2/cancel', tokens.an);
    assert.equal((await api('post', '/admin/reset', tokens.letan)).status, 403);
    assert.equal((await api('post', '/admin/reset', tokens.admin)).status, 200);
    const b = (await api('get', '/bookings/2', await login('an@example.com', 'user123'))).body;
    assert.equal(b.status, 'booked');
  });
});
