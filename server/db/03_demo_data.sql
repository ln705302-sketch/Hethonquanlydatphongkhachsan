/* =====================================================================
   SUNRISE HOTEL - DỮ LIỆU MẪU (bản SQL của server/src/seed.js)
   - Mật khẩu đã băm bcrypt: admin123, letan123, user123, binh123
   - Ngày của các đơn tính tương đối theo TRUNC(SYSDATE) để luôn có:
     đơn nhận phòng hôm nay, đơn đang ở, đơn đã trả phòng.
   ===================================================================== */

-- Thông tin khách sạn
INSERT INTO KhachSan (MaKhachSan, TenKhachSan, ThanhPho, DiaChi, SoDienThoai, Email, MoTa, SoSao, HinhAnh, TienIch)
VALUES (1, 'Sunrise Hotel', 'TP. Hồ Chí Minh', '1 Đường Bình Minh, Quận 1', '1900 1234', 'support@sunrisehotel.local',
        'Sunrise Hotel là khách sạn 3 sao với các hạng phòng Standard, Deluxe và Suite, phục vụ khách du lịch, gia đình và khách công tác. Khách sạn có dịch vụ ăn sáng, giặt ủi và đưa đón sân bay.',
        3,
        '["https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1000&q=70","https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1000&q=70","https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1000&q=70","https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1000&q=70","https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1000&q=70"]',
        '["wifi","restaurant","parking","airport"]');

-- Loại phòng
INSERT INTO LoaiPhong (MaLoaiPhong, TenLoaiPhong, MoTa, GiaCoBan, SoNguoiToiDa, DienTich, LoaiGiuong, TienNghi, HinhAnh)
VALUES (1, 'Standard', 'Phòng tiêu chuẩn, tiện nghi cơ bản', 650000, 2, 22, '1 giường đôi',
        '["Điều hòa","TV","Vòi sen"]',
        '["https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=800&q=70"]');
INSERT INTO LoaiPhong (MaLoaiPhong, TenLoaiPhong, MoTa, GiaCoBan, SoNguoiToiDa, DienTich, LoaiGiuong, TienNghi, HinhAnh)
VALUES (2, 'Deluxe', 'Phòng cao cấp, không gian rộng', 950000, 3, 30, '1 giường King',
        '["Điều hòa","Smart TV","Minibar","Bồn tắm"]',
        '["https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=800&q=70"]');
INSERT INTO LoaiPhong (MaLoaiPhong, TenLoaiPhong, MoTa, GiaCoBan, SoNguoiToiDa, DienTich, LoaiGiuong, TienNghi, HinhAnh)
VALUES (3, 'Suite', 'Phòng Suite cao cấp với phòng khách riêng', 1600000, 4, 45, '2 giường Queen',
        '["Điều hòa","Smart TV","Minibar","Bồn tắm","Phòng khách riêng"]',
        '["https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=800&q=70"]');

-- Phòng (202 đang có khách ở)
INSERT INTO Phong (MaPhong, MaLoaiPhong, SoPhong, Tang, MoTa, TrangThai) VALUES (1, 1, '101', 1, 'Standard - tầng 1', 'Trong');
INSERT INTO Phong (MaPhong, MaLoaiPhong, SoPhong, Tang, MoTa, TrangThai) VALUES (2, 1, '102', 1, 'Standard - tầng 1', 'Trong');
INSERT INTO Phong (MaPhong, MaLoaiPhong, SoPhong, Tang, MoTa, TrangThai) VALUES (3, 2, '201', 2, 'Deluxe - tầng 2', 'Trong');
INSERT INTO Phong (MaPhong, MaLoaiPhong, SoPhong, Tang, MoTa, TrangThai) VALUES (4, 2, '202', 2, 'Deluxe - tầng 2', 'DangO');
INSERT INTO Phong (MaPhong, MaLoaiPhong, SoPhong, Tang, MoTa, TrangThai) VALUES (5, 3, '301', 3, 'Suite - tầng 3', 'Trong');

-- Dịch vụ
INSERT INTO DichVu (MaDichVu, TenDichVu, MoTa, DonGia, DonViTinh) VALUES (1, 'Ăn sáng', 'Suất ăn sáng', 100000, 'Suất');
INSERT INTO DichVu (MaDichVu, TenDichVu, MoTa, DonGia, DonViTinh) VALUES (2, 'Giặt ủi', 'Dịch vụ giặt và ủi quần áo', 80000, 'Kg');
INSERT INTO DichVu (MaDichVu, TenDichVu, MoTa, DonGia, DonViTinh) VALUES (3, 'Đưa đón sân bay', 'Đưa đón một chiều', 300000, 'Chuyến');

-- Nhân viên (đăng nhập bằng email hoặc tên đăng nhập)
INSERT INTO NhanVien (MaNhanVien, HoTen, TenDangNhap, MatKhauHash, Email, SoDienThoai, VaiTro, NgayTao)
VALUES (1, 'Quản trị viên', 'admin', '$2a$10$MGihJRjN6g/cKKaMJOz.U.JfCO3odQfyto/gu0Nyybbcma9cAy476',
        'admin@sunrisehotel.local', '0909000111', 'QuanLy', DATE '2026-01-01');
INSERT INTO NhanVien (MaNhanVien, HoTen, TenDangNhap, MatKhauHash, Email, SoDienThoai, VaiTro, NgayTao)
VALUES (2, 'Lễ tân 01', 'letan01', '$2a$10$M0D1qnPHV973rkZWddbC4ePbL6CJTiVxmGz0YaQRjqJBKhnTUMQv6',
        'letan01@sunrisehotel.local', '0909000222', 'LeTan', DATE '2026-01-01');

-- Khách hàng (có tài khoản online)
INSERT INTO KhachHang (MaKhachHang, HoTen, NgaySinh, GioiTinh, SoDienThoai, Email, CCCD, DiaChi, MatKhauHash, NgayTao)
VALUES (1, 'Nguyễn Văn An', DATE '1998-05-12', 'Nam', '0900000001', 'an@example.com', '079098000001', 'TP. Hồ Chí Minh',
        '$2a$10$/QqHHXENbrAWmBph7oryF.hEFLU/1N/b2trmZf0Q6zomR8mSeS8uK', DATE '2026-03-15');
INSERT INTO KhachHang (MaKhachHang, HoTen, NgaySinh, GioiTinh, SoDienThoai, Email, CCCD, DiaChi, MatKhauHash, NgayTao)
VALUES (2, 'Trần Thị Bình', DATE '2000-09-20', 'Nu', '0900000002', 'binh@example.com', '079200000002', 'TP. Hồ Chí Minh',
        '$2a$10$4zkL5xsgWGZ9smQhCqwic.IPO/nJ584nXnN9mNnWRdflEo2R7J7xK', DATE '2026-05-20');

-- Đơn đặt phòng. Đơn đã trả phòng được chèn ở trạng thái "DaNhanPhong" để
-- trigger TRG_SDDV_BIU cho ghi dịch vụ, sau đó mới chuyển sang "DaTraPhong".
-- Đơn 1: KH1, phòng 201, -20 ngày, 2 đêm (sẽ trả phòng)
INSERT INTO DatPhong (MaDatPhong, MaKhachHang, MaPhong, MaNhanVien, NgayDat, NgayNhanDuKien, NgayTraDuKien, NgayNhanThucTe,
                      SoNguoi, DonGiaPhong, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, PhuongThucDuKien)
VALUES (1, 1, 3, 2, TRUNC(SYSDATE) - 27, TRUNC(SYSDATE) - 20, TRUNC(SYSDATE) - 18, TRUNC(SYSDATE) - 20,
        2, 950000, 'DaNhanPhong', 'Nguyễn Văn An', '0900000001', 'an@example.com', 'The');
-- Đơn 2: KH1, phòng 101, +10 ngày, 3 đêm, đã đặt
INSERT INTO DatPhong (MaDatPhong, MaKhachHang, MaPhong, NgayDat, NgayNhanDuKien, NgayTraDuKien,
                      SoNguoi, DonGiaPhong, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, PhuongThucDuKien)
VALUES (2, 1, 1, TRUNC(SYSDATE) + 3, TRUNC(SYSDATE) + 10, TRUNC(SYSDATE) + 13,
        2, 650000, 'DaDat', 'Nguyễn Văn An', '0900000001', 'an@example.com', 'ChuyenKhoan');
-- Đơn 3: KH1, phòng 301, +5 ngày, 2 đêm, đã đặt
INSERT INTO DatPhong (MaDatPhong, MaKhachHang, MaPhong, NgayDat, NgayNhanDuKien, NgayTraDuKien,
                      SoNguoi, DonGiaPhong, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, PhuongThucDuKien)
VALUES (3, 1, 5, TRUNC(SYSDATE) - 2, TRUNC(SYSDATE) + 5, TRUNC(SYSDATE) + 7,
        2, 1600000, 'DaDat', 'Nguyễn Văn An', '0900000001', 'an@example.com', 'TienMat');
-- Đơn 4: KH1, phòng 102, +25 ngày, 2 đêm, đã hủy
INSERT INTO DatPhong (MaDatPhong, MaKhachHang, MaPhong, NgayDat, NgayNhanDuKien, NgayTraDuKien,
                      SoNguoi, DonGiaPhong, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, PhuongThucDuKien)
VALUES (4, 1, 2, TRUNC(SYSDATE) + 18, TRUNC(SYSDATE) + 25, TRUNC(SYSDATE) + 27,
        2, 650000, 'DaHuy', 'Nguyễn Văn An', '0900000001', 'an@example.com', 'TienMat');
-- Đơn 5: KH2, phòng 202, -1 ngày, 3 đêm, đang ở
INSERT INTO DatPhong (MaDatPhong, MaKhachHang, MaPhong, MaNhanVien, NgayDat, NgayNhanDuKien, NgayTraDuKien, NgayNhanThucTe,
                      SoNguoi, DonGiaPhong, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, PhuongThucDuKien)
VALUES (5, 2, 4, 2, TRUNC(SYSDATE) - 8, TRUNC(SYSDATE) - 1, TRUNC(SYSDATE) + 2, TRUNC(SYSDATE) - 1,
        2, 950000, 'DaNhanPhong', 'Trần Thị Bình', '0900000002', 'binh@example.com', 'TienMat');
-- Đơn 6: KH2, phòng 102, nhận phòng hôm nay, 2 đêm
INSERT INTO DatPhong (MaDatPhong, MaKhachHang, MaPhong, NgayDat, NgayNhanDuKien, NgayTraDuKien,
                      SoNguoi, DonGiaPhong, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, PhuongThucDuKien)
VALUES (6, 2, 2, TRUNC(SYSDATE) - 7, TRUNC(SYSDATE), TRUNC(SYSDATE) + 2,
        2, 650000, 'DaDat', 'Trần Thị Bình', '0900000002', 'binh@example.com', 'TienMat');
-- Đơn 7: KH2, phòng 301, -40 ngày, 1 đêm (sẽ trả phòng)
INSERT INTO DatPhong (MaDatPhong, MaKhachHang, MaPhong, MaNhanVien, NgayDat, NgayNhanDuKien, NgayTraDuKien, NgayNhanThucTe,
                      SoNguoi, DonGiaPhong, TrangThai, TenKhachO, SDTKhachO, EmailKhachO, PhuongThucDuKien)
VALUES (7, 2, 5, 2, TRUNC(SYSDATE) - 47, TRUNC(SYSDATE) - 40, TRUNC(SYSDATE) - 39, TRUNC(SYSDATE) - 40,
        2, 1600000, 'DaNhanPhong', 'Trần Thị Bình', '0900000002', 'binh@example.com', 'TienMat');

-- Dịch vụ đã dùng (trigger tự chốt đơn giá và tính thành tiền)
INSERT INTO SuDungDichVu (MaSuDung, MaDatPhong, MaDichVu, NgaySuDung, SoLuong) VALUES (1, 1, 1, TRUNC(SYSDATE) - 19, 2);
INSERT INTO SuDungDichVu (MaSuDung, MaDatPhong, MaDichVu, NgaySuDung, SoLuong) VALUES (2, 5, 2, TRUNC(SYSDATE), 1.5);

-- Trả phòng hai đơn cũ + lập hóa đơn
UPDATE DatPhong SET TrangThai = 'DaTraPhong', NgayTraThucTe = NgayTraDuKien WHERE MaDatPhong IN (1, 7);
INSERT INTO HoaDon (MaHoaDon, MaDatPhong, MaNhanVien, NgayLap, SoDem, TienPhong, TienDichVu, GiamGia,
                    TongThanhToan, TienKhachTra, TienThua, PhuongThucTT, TrangThaiTT)
VALUES (1, 1, 2, TRUNC(SYSDATE) - 18, 2, 1900000, 200000, 0, 2100000, 2100000, 0, 'The', 'DaThanhToan');
INSERT INTO HoaDon (MaHoaDon, MaDatPhong, MaNhanVien, NgayLap, SoDem, TienPhong, TienDichVu, GiamGia,
                    TongThanhToan, TienKhachTra, TienThua, PhuongThucTT, TrangThaiTT)
VALUES (2, 7, 2, TRUNC(SYSDATE) - 39, 1, 1600000, 0, 0, 1600000, 2000000, 400000, 'TienMat', 'DaThanhToan');

-- Mã ưu đãi
INSERT INTO KhuyenMai (MaKhuyenMai, MaCode, TieuDe, MoTa, PhanTramGiam, SoTienGiam, SoDemToiThieu, ChiDonDauTien)
VALUES (1, 'SUNRISE15', 'Giảm 15% kỳ nghỉ dài', 'Giảm 15% tiền phòng cho đơn từ 3 đêm', 15, 0, 3, 0);
INSERT INTO KhuyenMai (MaKhuyenMai, MaCode, TieuDe, MoTa, PhanTramGiam, SoTienGiam, SoDemToiThieu, ChiDonDauTien)
VALUES (2, 'WEEKEND300', 'Ưu đãi cuối tuần', 'Giảm 300.000 ₫ cho đơn từ 2 đêm', 0, 300000, 2, 0);
INSERT INTO KhuyenMai (MaKhuyenMai, MaCode, TieuDe, MoTa, PhanTramGiam, SoTienGiam, SoDemToiThieu, ChiDonDauTien)
VALUES (3, 'XINCHAO10', 'Thành viên mới', 'Giảm 10% cho lần đặt phòng đầu tiên', 10, 0, 1, 1);

-- Đánh giá mẫu của khách cũ (không gắn tài khoản)
INSERT INTO DanhGia (MaDanhGia, TenHienThi, Diem, NhanXet, NgayTao)
VALUES (1, 'Minh Anh', 8.8, 'Phòng sạch sẽ, nhân viên rất nhiệt tình. Vị trí thuận tiện đi lại.', DATE '2026-09-10');
INSERT INTO DanhGia (MaDanhGia, TenHienThi, Diem, NhanXet, NgayTao)
VALUES (2, 'Quốc Bảo', 8.5, 'Bữa sáng ngon, nhiều món. Sẽ quay lại lần sau!', DATE '2026-08-11');
INSERT INTO DanhGia (MaDanhGia, TenHienThi, Diem, NhanXet, NgayTao)
VALUES (3, 'Thu Hà', 7.9, 'Giá hợp lý so với chất lượng, view đẹp. Wifi hơi chậm vào buổi tối.', DATE '2026-07-12');
INSERT INTO DanhGia (MaDanhGia, TenHienThi, Diem, NhanXet, NgayTao)
VALUES (4, 'Hoàng Nam', 9.2, 'Check-in nhanh, phòng thơm tho, giường êm. Rất hài lòng.', DATE '2026-06-13');

COMMIT;

-- Bộ đếm IDENTITY tiếp tục sau các id đã chèn
ALTER TABLE KhachHang    MODIFY MaKhachHang GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE LoaiPhong    MODIFY MaLoaiPhong GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE Phong        MODIFY MaPhong     GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE DichVu       MODIFY MaDichVu    GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE NhanVien     MODIFY MaNhanVien  GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE DatPhong     MODIFY MaDatPhong  GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE SuDungDichVu MODIFY MaSuDung    GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE HoaDon       MODIFY MaHoaDon    GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE KhuyenMai    MODIFY MaKhuyenMai GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);
ALTER TABLE DanhGia      MODIFY MaDanhGia   GENERATED BY DEFAULT AS IDENTITY (START WITH LIMIT VALUE);

-- Biên dịch lại trigger / view bị INVALID sau các lệnh ALTER TABLE ở trên
ALTER TRIGGER TRG_SDDV_BIU COMPILE;
ALTER TRIGGER TRG_DATPHONG_BIU COMPILE;
ALTER VIEW VW_Phong_ChiTiet COMPILE;
ALTER VIEW VW_DatPhong_ChiTiet COMPILE;
ALTER VIEW VW_HoaDon_ChiTiet COMPILE;
ALTER VIEW VW_DoanhThu_TheoNgay COMPILE;
ALTER VIEW VW_DoanhThu_TheoLoaiPhong COMPILE;

-- KIỂM TRA NHANH
SELECT object_name, object_type, status FROM user_objects
 WHERE object_type IN ('TRIGGER','VIEW') ORDER BY object_type, object_name;
SELECT 'KhachHang' AS TenBang, COUNT(*) AS SoDong FROM KhachHang
UNION ALL SELECT 'LoaiPhong', COUNT(*) FROM LoaiPhong
UNION ALL SELECT 'Phong', COUNT(*) FROM Phong
UNION ALL SELECT 'DichVu', COUNT(*) FROM DichVu
UNION ALL SELECT 'NhanVien', COUNT(*) FROM NhanVien
UNION ALL SELECT 'DatPhong', COUNT(*) FROM DatPhong
UNION ALL SELECT 'SuDungDichVu', COUNT(*) FROM SuDungDichVu
UNION ALL SELECT 'HoaDon', COUNT(*) FROM HoaDon
UNION ALL SELECT 'KhuyenMai', COUNT(*) FROM KhuyenMai
UNION ALL SELECT 'DanhGia', COUNT(*) FROM DanhGia;
SELECT * FROM VW_DatPhong_ChiTiet ORDER BY MaDatPhong;
