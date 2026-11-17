/**
 * Dữ liệu mẫu (khớp phần DEMO DATA của SUNRISE_HOTEL_ORACLE23AI.sql và
 * dữ liệu demo của website). Ngày của các đơn tính tương đối so với hôm nay
 * để luôn có: đơn nhận phòng hôm nay, đơn đang ở, đơn đã trả phòng.
 */
const db = require('./db');
const auth = require('./auth');
const { today, addDays, toDb } = require('./dates');

const unsplash = (id, w = 1000) =>
  `https://images.unsplash.com/photo-${id}?auto=format&fit=crop&w=${w}&q=70`;

const DELETE_ORDER = [
  'LuuKhuyenMai', 'DanhGia', 'KhuyenMai', 'KhachSan', 'HoaDon', 'SuDungDichVu',
  'DatPhong', 'Phong', 'LoaiPhong', 'DichVu', 'NhanVien', 'KhachHang',
];
const IDENTITY_COLUMNS = {
  KhachHang: 'MaKhachHang', LoaiPhong: 'MaLoaiPhong', Phong: 'MaPhong', DichVu: 'MaDichVu',
  NhanVien: 'MaNhanVien', DatPhong: 'MaDatPhong', SuDungDichVu: 'MaSuDung', HoaDon: 'MaHoaDon',
  KhuyenMai: 'MaKhuyenMai', DanhGia: 'MaDanhGia',
};

const D = (d) => toDb(d);
const DATE = `TO_DATE(:%s, 'YYYY-MM-DD"T"HH24:MI:SS')`;
const dt = (name) => DATE.replace('%s', name);

async function seed() {
  const t0 = today();
  const [adminHash, letanHash, anHash, binhHash] = await Promise.all(
    ['admin123', 'letan123', 'user123', 'binh123'].map(auth.hash),
  );

  await db.tx(async (t) => {
    for (const table of DELETE_ORDER) await t.exec(`DELETE FROM ${table}`);

    // Khách sạn
    await t.exec(
      `INSERT INTO KhachSan (MaKhachSan, TenKhachSan, ThanhPho, DiaChi, SoDienThoai, Email, MoTa, SoSao, HinhAnh, TienIch)
       VALUES (1, :name, :city, :address, :phone, :email, :description, 3, :images, :amenities)`,
      {
        name: 'Sunrise Hotel',
        city: 'TP. Hồ Chí Minh',
        address: '1 Đường Bình Minh, Quận 1',
        phone: '1900 1234',
        email: 'support@sunrisehotel.local',
        description:
          'Sunrise Hotel là khách sạn 3 sao với các hạng phòng Standard, Deluxe '
          + 'và Suite, phục vụ khách du lịch, gia đình và khách công tác. Khách sạn '
          + 'có dịch vụ ăn sáng, giặt ủi và đưa đón sân bay.',
        images: JSON.stringify([
          '1566073771259-6a8506099945', '1551882547-ff40c63fe5fa', '1542314831-068cd1dbfeeb',
          '1582719478250-c89cae4dc85b', '1590490360182-c33d57733427',
        ].map((id) => unsplash(id))),
        amenities: JSON.stringify(['wifi', 'restaurant', 'parking', 'airport']),
      },
    );

    // Loại phòng
    const types = [
      [1, 'Standard', 'Phòng tiêu chuẩn, tiện nghi cơ bản', 650000, 2, 22, '1 giường đôi',
        ['Điều hòa', 'TV', 'Vòi sen'], '1611892440504-42a792e24d32'],
      [2, 'Deluxe', 'Phòng cao cấp, không gian rộng', 950000, 3, 30, '1 giường King',
        ['Điều hòa', 'Smart TV', 'Minibar', 'Bồn tắm'], '1618773928121-c32242e63f39'],
      [3, 'Suite', 'Phòng Suite cao cấp với phòng khách riêng', 1600000, 4, 45, '2 giường Queen',
        ['Điều hòa', 'Smart TV', 'Minibar', 'Bồn tắm', 'Phòng khách riêng'], '1631049307264-da0ec9d70304'],
    ];
    for (const [id, name, desc, price, max, area, bed, amenities, img] of types) {
      await t.exec(
        `INSERT INTO LoaiPhong (MaLoaiPhong, TenLoaiPhong, MoTa, GiaCoBan, SoNguoiToiDa, DienTich, LoaiGiuong, TienNghi, HinhAnh)
         VALUES (:id, :name, :descr, :price, :max, :area, :bed, :amenities, :images)`,
        { id, name, descr: desc, price, max, area, bed,
          amenities: JSON.stringify(amenities), images: JSON.stringify([unsplash(img, 800)]) },
      );
    }

    // Phòng (202 đang có khách ở)
    const rooms = [[1, 1, '101', 1, 'Trong'], [2, 1, '102', 1, 'Trong'], [3, 2, '201', 2, 'Trong'],
      [4, 2, '202', 2, 'DangO'], [5, 3, '301', 3, 'Trong']];
    const roomType = Object.fromEntries(rooms.map((r) => [r[0], r[1]]));
    for (const [id, type, number, floor, status] of rooms) {
      const typeName = types[type - 1][1];
      await t.exec(
        `INSERT INTO Phong (MaPhong, MaLoaiPhong, SoPhong, Tang, MoTa, TrangThai)
         VALUES (:id, :type, :num, :floor, :note, :status)`,
        { id, type, num: number, floor, note: `${typeName} - tầng ${floor}`, status },
      );
    }

    // Dịch vụ
    const services = [[1, 'Ăn sáng', 'Suất ăn sáng', 100000, 'Suất'],
      [2, 'Giặt ủi', 'Dịch vụ giặt và ủi quần áo', 80000, 'Kg'],
      [3, 'Đưa đón sân bay', 'Đưa đón một chiều', 300000, 'Chuyến']];
    for (const [id, name, desc, price, unit] of services) {
      await t.exec(
        `INSERT INTO DichVu (MaDichVu, TenDichVu, MoTa, DonGia, DonViTinh) VALUES (:id, :name, :descr, :price, :unit)`,
        { id, name, descr: desc, price, unit },
      );
    }

    // Nhân viên (đăng nhập bằng email hoặc tên đăng nhập)
    const jan1 = D(new Date(2026, 0, 1));
    await t.exec(
      `INSERT INTO NhanVien (MaNhanVien, HoTen, TenDangNhap, MatKhauHash, Email, SoDienThoai, VaiTro, NgayTao)
       VALUES (1, 'Quản trị viên', 'admin', :h, 'admin@sunrisehotel.local', '0909000111', 'QuanLy', ${dt('d')})`,
      { h: adminHash, d: jan1 },
    );
    await t.exec(
      `INSERT INTO NhanVien (MaNhanVien, HoTen, TenDangNhap, MatKhauHash, Email, SoDienThoai, VaiTro, NgayTao)
       VALUES (2, 'Lễ tân 01', 'letan01', :h, 'letan01@sunrisehotel.local', '0909000222', 'LeTan', ${dt('d')})`,
      { h: letanHash, d: jan1 },
    );

    // Khách hàng
    const customers = [
      [1, 'Nguyễn Văn An', new Date(1998, 4, 12), 'Nam', '0900000001', 'an@example.com', '079098000001', anHash, new Date(2026, 2, 15)],
      [2, 'Trần Thị Bình', new Date(2000, 8, 20), 'Nu', '0900000002', 'binh@example.com', '079200000002', binhHash, new Date(2026, 4, 20)],
    ];
    for (const [id, name, birth, gender, phone, email, cccd, h, created] of customers) {
      await t.exec(
        `INSERT INTO KhachHang (MaKhachHang, HoTen, NgaySinh, GioiTinh, SoDienThoai, Email, CCCD, DiaChi, MatKhauHash, NgayTao)
         VALUES (:id, :name, ${dt('birth')}, :gender, :phone, :email, :cccd, 'TP. Hồ Chí Minh', :h, ${dt('created')})`,
        { id, name, birth: D(birth), gender, phone, email, cccd, h, created: D(created) },
      );
    }

    // Đơn đặt phòng: [id, khách, phòng, lệch ngày, số đêm, trạng thái, phương thức]
    const price = Object.fromEntries(types.map((x) => [x[0], x[3]]));
    const bookings = [
      [1, 1, 3, -20, 2, 'DaTraPhong', 'The'],
      [2, 1, 1, 10, 3, 'DaDat', 'ChuyenKhoan'],
      [3, 1, 5, 5, 2, 'DaDat', 'TienMat'],
      [4, 1, 2, 25, 2, 'DaHuy', 'TienMat'],
      [5, 2, 4, -1, 3, 'DaNhanPhong', 'TienMat'],
      [6, 2, 2, 0, 2, 'DaDat', 'TienMat'],
      [7, 2, 5, -40, 1, 'DaTraPhong', 'TienMat'],
    ];
    const guest = {
      1: ['Nguyễn Văn An', '0900000001', 'an@example.com'],
      2: ['Trần Thị Bình', '0900000002', 'binh@example.com'],
    };
    for (const [id, kh, roomId, offset, n, status, pay] of bookings) {
      const checkIn = addDays(t0, offset);
      const checkOut = addDays(checkIn, n);
      const stayed = status === 'DaNhanPhong' || status === 'DaTraPhong';
      // Đơn đã trả phòng: chèn ở trạng thái "đã nhận phòng" để trigger cho ghi
      // dịch vụ, sau đó mới chuyển sang "đã trả phòng"
      await t.exec(
        `INSERT INTO DatPhong (MaDatPhong, MaKhachHang, MaPhong, MaNhanVien, NgayDat, NgayNhanDuKien, NgayTraDuKien,
                               NgayNhanThucTe, SoNguoi, DonGiaPhong, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, PhuongThucDuKien)
         VALUES (:id, :kh, :room, :nv, ${dt('created')}, ${dt('ci')}, ${dt('co')},
                 ${dt('aci')}, 2, :price, :status, :gname, :gphone, :gemail, :pay)`,
        {
          id, kh, room: roomId, nv: stayed ? 2 : null,
          created: D(addDays(checkIn, -7)), ci: D(checkIn), co: D(checkOut),
          aci: stayed ? D(checkIn) : null,
          price: price[roomType[roomId]],
          status: status === 'DaTraPhong' ? 'DaNhanPhong' : status,
          gname: guest[kh][0], gphone: guest[kh][1], gemail: guest[kh][2], pay,
        },
      );
    }

    // Dịch vụ đã dùng (trigger tự chốt đơn giá và tính thành tiền)
    await t.exec(
      `INSERT INTO SuDungDichVu (MaSuDung, MaDatPhong, MaDichVu, NgaySuDung, SoLuong) VALUES (1, 1, 1, ${dt('d')}, 2)`,
      { d: D(addDays(t0, -19)) },
    );
    await t.exec(
      `INSERT INTO SuDungDichVu (MaSuDung, MaDatPhong, MaDichVu, NgaySuDung, SoLuong) VALUES (2, 5, 2, ${dt('d')}, 1.5)`,
      { d: D(t0) },
    );

    // Trả phòng hai đơn cũ + hóa đơn
    for (const [bid, invId, created, n, room, service, paid, change, method] of [
      [1, 1, addDays(t0, -18), 2, 1900000, 200000, 2100000, 0, 'The'],
      [7, 2, addDays(t0, -39), 1, 1600000, 0, 2000000, 400000, 'TienMat'],
    ]) {
      await t.exec(
        `UPDATE DatPhong SET TrangThai = 'DaTraPhong', NgayTraThucTe = NgayTraDuKien WHERE MaDatPhong = :bid`,
        { bid },
      );
      await t.exec(
        `INSERT INTO HoaDon (MaHoaDon, MaDatPhong, MaNhanVien, NgayLap, SoDem, TienPhong, TienDichVu, GiamGia,
                             TongThanhToan, TienKhachTra, TienThua, PhuongThucTT, TrangThaiTT)
         VALUES (:id, :bid, 2, ${dt('created')}, :n, :room, :service, 0, :total, :paid, :change, :method, 'DaThanhToan')`,
        { id: invId, bid, created: D(created), n, room, service, total: room + service, paid, change, method },
      );
    }

    // Mã ưu đãi
    const promos = [
      [1, 'SUNRISE15', 'Giảm 15% kỳ nghỉ dài', 'Giảm 15% tiền phòng cho đơn từ 3 đêm', 15, 0, 3, 0],
      [2, 'WEEKEND300', 'Ưu đãi cuối tuần', 'Giảm 300.000 ₫ cho đơn từ 2 đêm', 0, 300000, 2, 0],
      [3, 'XINCHAO10', 'Thành viên mới', 'Giảm 10% cho lần đặt phòng đầu tiên', 10, 0, 1, 1],
    ];
    for (const [id, code, title, desc, pct, fixed, minN, first] of promos) {
      await t.exec(
        `INSERT INTO KhuyenMai (MaKhuyenMai, MaCode, TieuDe, MoTa, PhanTramGiam, SoTienGiam, SoDemToiThieu, ChiDonDauTien)
         VALUES (:id, :code, :title, :descr, :pct, :fixed, :minN, :first)`,
        { id, code, title, descr: desc, pct, fixed, minN, first },
      );
    }

    // Đánh giá mẫu của khách cũ
    const reviews = [
      ['Minh Anh', 8.8, 'Phòng sạch sẽ, nhân viên rất nhiệt tình. Vị trí thuận tiện đi lại.'],
      ['Quốc Bảo', 8.5, 'Bữa sáng ngon, nhiều món. Sẽ quay lại lần sau!'],
      ['Thu Hà', 7.9, 'Giá hợp lý so với chất lượng, view đẹp. Wifi hơi chậm vào buổi tối.'],
      ['Hoàng Nam', 9.2, 'Check-in nhanh, phòng thơm tho, giường êm. Rất hài lòng.'],
    ];
    for (let i = 0; i < reviews.length; i++) {
      await t.exec(
        `INSERT INTO DanhGia (MaDanhGia, TenHienThi, Diem, NhanXet, NgayTao) VALUES (:id, :name, :score, :cmt, ${dt('d')})`,
        { id: i + 1, name: reviews[i][0], score: reviews[i][1], cmt: reviews[i][2], d: D(new Date(2026, 8 - i, 10 + i)) },
      );
    }
  });

  // Đặt lại bộ đếm IDENTITY sau các id đã chèn (DDL, chạy sau commit)
  for (const [table, col] of Object.entries(IDENTITY_COLUMNS)) {
    await db.query(`ALTER TABLE ${table} MODIFY ${col} GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE)`);
  }
  // ALTER TABLE ở trên làm trigger / view phụ thuộc bị đánh dấu INVALID:
  // biên dịch lại để DBeaver / SQL Developer hiển thị VALID
  const invalid = await db.query(
    "SELECT object_name, object_type FROM user_objects WHERE status <> 'VALID' AND object_type IN ('TRIGGER','VIEW')");
  for (const o of invalid) {
    await db.query(`ALTER ${o.OBJECT_TYPE} ${o.OBJECT_NAME} COMPILE`);
  }
}

module.exports = { seed };
