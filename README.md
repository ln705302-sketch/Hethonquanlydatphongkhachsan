# Sunrise Hotel – Website đặt phòng (Flutter Web)

Website đặt phòng cho **một khách sạn duy nhất: Sunrise Hotel**, khách sạn 3 sao với các hạng phòng Standard, Deluxe và Suite. Nghiệp vụ bám theo báo cáo đồ án và file `SUNRISE_HOTEL_ORACLE23AI.sql`.

Kiến trúc: **Flutter Web** → REST API **Node.js + Express** (`server/`) → **Oracle Database 23ai** (PDB `SCHOOLDB`, schema `SUNRISE_HOTEL`). Mọi nghiệp vụ (phòng trống, đặt phòng, nhận/trả phòng, hóa đơn, phân quyền) chạy ở server; mật khẩu băm bcrypt, đăng nhập bằng JWT. Trình duyệt chỉ lưu token đăng nhập.

## Cách chạy

Yêu cầu: Flutter 3.x stable, Node.js ≥ 20, Oracle 23ai đang chạy (VD container `oracle23ai`, cổng 1521, PDB `SCHOOLDB`).

**1. Database** (một lần): tạo user cho server, đăng nhập SYSDBA trong PDB `SCHOOLDB`:

```sql
ALTER USER SUNRISE_HOTEL IDENTIFIED BY "Sunrise_2026";
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE TRIGGER, CREATE SEQUENCE, CREATE PROCEDURE TO SUNRISE_HOTEL;
-- Schema riêng cho test tự động (bị xóa / nạp lại mỗi lần test)
CREATE USER SUNRISE_TEST IDENTIFIED BY "Sunrise_2026" DEFAULT TABLESPACE SCHOOLDATA QUOTA UNLIMITED ON SCHOOLDATA;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE TRIGGER, CREATE SEQUENCE, CREATE PROCEDURE TO SUNRISE_TEST;
```

Chưa có Oracle thì có thể dùng `server/docker-compose.yml` (image `gvenzl/oracle-free`, tự tạo `SCHOOLDB` và 2 user trên).

**2. Server** (tự tạo bảng + nạp dữ liệu mẫu ở lần chạy đầu):

```bash
cd server
cp .env.example .env      # sửa DB_*, JWT_SECRET nếu cần
npm install
npm start                 # API tại http://localhost:8080/api
npm run db:reset          # xóa và tạo lại toàn bộ bảng + dữ liệu mẫu
npm test                  # 34 test API trên schema SUNRISE_TEST
```

**3. Web**

```bash
flutter pub get
flutter run -d chrome                         # gọi API mặc định http://localhost:8080/api
flutter build web --dart-define=API_URL=https://ten-mien/api
```

Nếu đã `flutter build web`, `npm start` phục vụ luôn `build/web` tại http://localhost:8080 (đã chuyển mọi đường dẫn về `index.html`).

Kiểm tra:

```bash
flutter analyze
flutter test        # logic client + render mọi trang (backend giả trong bộ nhớ, không cần server)
# Test end-to-end app -> server -> Oracle (chạy server trên schema test):
#   cd server && DB_USER=SUNRISE_TEST PORT=8081 node src/server.js
flutter test test/integration_test.dart --dart-define=API_URL=http://localhost:8081/api
```

## Backend

| Thành phần | Nội dung |
|---|---|
| `server/db/01_schema.sql` | 8 bảng, index, trigger, view của file đồ án. **Sửa lỗi**: `TRG_DATPHONG_BIU` gốc là trigger `FOR EACH ROW` nhưng `SELECT` chính bảng `DatPhong` → mọi `UPDATE DatPhong` (nhận phòng) bị **ORA-04091 mutating table**. Đã viết lại thành `COMPOUND TRIGGER` (kiểm tra trùng lịch ở `AFTER STATEMENT`), giữ nguyên mã lỗi -20023/-20024/-20025. |
| `server/db/02_extensions.sql` | Cột/bảng website cần: mật khẩu + khóa tài khoản khách, ảnh/tiện nghi loại phòng, người ở + mã ưu đãi + giảm giá trên `DatPhong`, `SoDem` trên `HoaDon`; bảng `KhachSan`, `KhuyenMai`, `LuuKhuyenMai`, `DanhGia`. |
| `server/src/routes/` | `auth` (đăng nhập, đăng ký, hồ sơ, mã đã lưu), `users` (khách, nhân viên, khóa, đặt lại mật khẩu), `catalog` (khách sạn, loại phòng, phòng, dịch vụ, phòng trống), `bookings` (đặt, hủy, nhận phòng, dịch vụ, trả phòng, hóa đơn, hoàn tiền), `content` (đánh giá, mã ưu đãi), `reports` (doanh thu, khôi phục dữ liệu mẫu). |

- **Đặt phòng**: khóa các phòng của loại đã chọn bằng `SELECT ... FOR UPDATE` rồi mới tìm phòng trống và chèn đơn trong cùng transaction → hai người đặt cùng lúc phòng cuối cùng chỉ một người thành công (có test).
- **Trả phòng**: lập hóa đơn + đơn "Đã trả phòng" + phòng "Trống" trong **một transaction**; lỗi ở bất kỳ bước nào thì rollback toàn bộ (có test).
- Ngày "hôm nay" lấy theo giờ của server Node (Asia/Ho_Chi_Minh), không dùng `SYSDATE` của container Oracle (giờ UTC).
- Id: khách hàng `KH<n>`, nhân viên `NV<n>` (hai bảng riêng); mã hiển thị đơn `SRH000012`, hóa đơn `HD000003`.

## Tài khoản demo

| Vai trò    | Email                       | Mật khẩu |
|------------|-----------------------------|----------|
| Quản lý    | admin@sunrisehotel.local    | admin123 |
| Lễ tân     | letan01@sunrisehotel.local  | letan123 |
| Khách hàng | an@example.com              | user123  |
| Khách hàng | binh@example.com            | binh123  |

Trang đăng nhập có nút điền nhanh. Dữ liệu mẫu có đủ các trạng thái đơn:
- Một đơn **nhận phòng hôm nay** (phòng 102) để thử chức năng nhận phòng.
- Một đơn **đang ở** (phòng 202, đã dùng giặt ủi) để thử ghi dịch vụ và trả phòng.
- Hai đơn đã trả phòng, có hóa đơn.

Muốn đưa dữ liệu về ban đầu: đăng nhập Quản lý → **Tổng quan → "Khôi phục dữ liệu mẫu"**.

## Chức năng

### Khách hàng
- **Trang chủ**: tìm phòng theo ngày nhận/trả và số khách; giới thiệu hạng phòng, dịch vụ, ưu đãi.
- **Chọn phòng** `/rooms?checkIn=&checkOut=&guests=`: mỗi loại phòng hiện số phòng còn trống theo khoảng ngày đã chọn. Mỗi đơn đặt một phòng.
- **Đặt phòng** `/booking` (cần đăng nhập): nhập thông tin, chọn mã ưu đãi, chọn phương thức thanh toán dự kiến. Hệ thống tự xếp một phòng cụ thể còn trống. Mã đơn có dạng `SRHxxxxxxxx`.
- **Dịch vụ** `/services` và **Giới thiệu** `/about` (ảnh, tiện nghi, đánh giá).
- **Đơn của tôi**: lọc theo trạng thái; xem chi tiết, dịch vụ đã dùng và hóa đơn; tự hủy đơn "Đã đặt" trước ngày nhận phòng.
- **Đánh giá**: chỉ khách đã trả phòng mới viết được, mỗi người một lần; sửa hoặc xóa được đánh giá của mình.
- **Mã ưu đãi**: lưu mã ở trang chủ, dùng ở bước đặt phòng. Mỗi mã dùng một lần, được dùng lại nếu đơn bị hủy.
- **Hồ sơ**: sửa họ tên, số điện thoại, CCCD, địa chỉ, giới tính, ngày sinh; đổi mật khẩu.
- **Quên mật khẩu**: hướng dẫn liên hệ lễ tân để được đặt lại mật khẩu (chưa có máy chủ gửi email).

### Lễ tân (`/admin`)
- **Tổng quan**: số phòng trống / đang ở / bảo trì, khách đến và đi hôm nay, đơn mới nhất.
- **Đặt phòng**:
  - Đặt tại quầy cho khách có sẵn hoặc khách mới.
  - **Nhận phòng**: có thể đổi sang phòng cùng loại nếu phòng được xếp chưa sẵn sàng.
  - **Ghi nhận dịch vụ** (chỉ với đơn đã nhận phòng).
  - **Trả phòng và lập hóa đơn**: nhập tiền khách trả, tự tính tiền thừa.
  - Hủy đơn trước ngày nhận phòng.
- **Phòng**: xem danh sách phòng và trạng thái.
- **Khách hàng**: thêm, sửa. Số điện thoại và CCCD không được trùng. Xem lịch sử đặt phòng và tổng chi tiêu; đặt lại mật khẩu hoặc cấp tài khoản online cho khách tạo tại quầy.
- **Hóa đơn**: tìm theo mã / khách / SĐT, lọc theo trạng thái và ngày lập; xem chi tiết.
- **Báo cáo**: khách nhận/trả phòng hôm nay và ngày mai; phòng trống theo khoảng ngày và loại phòng.

### Quản lý (có thêm)
- **Loại phòng & bảng giá**, **Dịch vụ**, **Thông tin khách sạn**.
- **Nhân viên**: thêm, sửa thông tin và vai trò, đặt lại mật khẩu lễ tân, tìm kiếm. Không tự hạ quyền của mình; luôn giữ ít nhất một Quản lý.
- **Mã ưu đãi** `/admin/promotions`: thêm, sửa (giảm % / số tiền, số đêm tối thiểu, chỉ đơn đầu tiên), tạm ngừng, xóa; xem số đơn đã dùng.
- **Đánh giá** `/admin/reviews`: ẩn / hiện, xóa đánh giá. Đánh giá bị ẩn không tính vào điểm trung bình.
- Thêm, sửa, xóa phòng và đổi trạng thái bảo trì.
- Khóa / mở khóa tài khoản.
- **Báo cáo doanh thu** theo ngày / tháng / năm và theo loại phòng.
- Phê duyệt **hủy đơn đặc biệt** (từ ngày nhận phòng trở đi) và **hoàn tiền** hóa đơn.

## Quy tắc nghiệp vụ

- **Phòng trống**: phòng không ở trạng thái Bảo trì / Ngừng sử dụng, và không có đơn "Đã đặt" hoặc "Đã nhận phòng" có khoảng ngày giao với `[nhận, trả)`.
- **Trạng thái đơn**: Đã đặt → Đã nhận phòng → Đã trả phòng. Chỉ đơn "Đã đặt" mới hủy được.
- **Nhận phòng**: chỉ từ ngày nhận phòng; đơn chuyển sang "Đã nhận phòng", phòng chuyển sang "Đang ở".
- **Trả phòng**: lập hóa đơn, chuyển đơn sang "Đã trả phòng" và đưa phòng về "Trống". Ba việc này cùng xảy ra hoặc cùng không xảy ra. Mỗi đơn chỉ có một hóa đơn.
- **Tổng thanh toán** = đơn giá × số đêm lưu trú thực tế (tối thiểu 1) + tiền dịch vụ − giảm giá. Không cộng thuế riêng.
- **Doanh thu** chỉ tính hóa đơn "Đã thanh toán"; hóa đơn đã hoàn tiền bị loại.
- **Ràng buộc xóa**:
  - Không xóa loại phòng còn phòng.
  - Không xóa phòng hoặc dịch vụ đã phát sinh trong đơn. Thay vào đó, chuyển sang Ngừng sử dụng / Ngừng cung cấp.

## Đối chiếu với database (SQL)

| Website (model)          | Bảng SQL       |
|--------------------------|----------------|
| `RoomType`               | LoaiPhong      |
| `Room`                   | Phong          |
| `HotelService`           | DichVu         |
| `User` (vai trò khách)   | KhachHang      |
| `User` (lễ tân, quản lý) | NhanVien       |
| `Booking`                | DatPhong       |
| `ServiceUsage`           | SuDungDichVu   |
| `Invoice`                | HoaDon         |

Một số dữ liệu chỉ có trên website, cần thêm cột hoặc bảng nếu muốn lưu vào database:
- Ảnh, loại giường, tiện nghi của loại phòng.
- Mật khẩu đăng nhập của khách hàng (bảng KhachHang chưa có).
- Thông tin khách sạn.
- Mã ưu đãi (danh mục + mã khách đã lưu) và đánh giá (kèm cờ ẩn).

## Cấu trúc thư mục

```
lib/
  main.dart                 # khởi tạo storage, providers, MaterialApp.router
  app_router.dart           # go_router + phân quyền (đăng nhập, nhân viên, quản lý)
  core/                     # theme, constants, validators, formatters
  models/                   # hotel, room_type, room, service, booking, invoice, user, review, promotion
  data/                     # api_client (gọi REST API), local_storage (token), info_pages
  providers/                # gọi API + giữ bản sao dữ liệu: auth, hotel, booking, promo, search
  screens/
    home/ rooms/ services/ about/ booking/ my_bookings/ my_promos/ auth/ profile/ info/
    admin/                  # tổng quan, đặt phòng, nhận/trả phòng, phòng, khách hàng,
                            # hóa đơn, báo cáo, loại phòng, dịch vụ, nhân viên, khách sạn
  widgets/                  # header, footer, ô tìm phòng, card phòng, dịch vụ, dialog chi tiết...
test/
  client_logic_test.dart    # ApiClient, phiên đăng nhập, mã ưu đãi, bảng kê, báo cáo (backend giả)
  smoke_test.dart           # mở mọi route và dialog ở 3 kích thước màn hình (backend giả)
  integration_test.dart     # app -> server -> Oracle, toàn bộ quy trình (cần server test)
  support/                 # mock_data, fake_backend
server/
  db/                       # 01_schema.sql (đồ án, đã sửa trigger), 02_extensions.sql, init/
  src/                      # app, auth (JWT, bcrypt), migrate, seed, logic, routes/
  test/api.test.js          # 34 test API trên Oracle thật (schema SUNRISE_TEST)
```

**Công nghệ:** Flutter Web, Material 3, `provider`, `go_router`, `http`, `shared_preferences` (lưu token), `intl`, `flutter_localizations`; Node.js, Express, `oracledb` (thin mode), `bcryptjs`, `jsonwebtoken`; Oracle Database 23ai.

## Ghi chú
- Dữ liệu và thanh toán là **giả lập** phục vụ đồ án.
- Khi deploy thật: đổi `JWT_SECRET`, đặt `ALLOW_RESET=false` để tắt nút khôi phục dữ liệu mẫu, và chạy server sau HTTPS.
- Địa chỉ, hotline và email của khách sạn là dữ liệu mẫu, sửa được tại Quản trị → Khách sạn.
- Ảnh lấy từ Unsplash qua mạng; khi không tải được sẽ hiện ảnh thay thế.
