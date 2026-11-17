/* =====================================================================
   SUNRISE HOTEL - XÓA TOÀN BỘ BẢNG VÀ VIEW (CẢNH BÁO: MẤT HẾT DỮ LIỆU)
   Chỉ chạy khi muốn tạo lại schema từ đầu, sau đó chạy SUNRISE_HOTEL_FULL.sql
   ===================================================================== */
BEGIN
  FOR v IN (SELECT view_name FROM user_views
             WHERE view_name IN ('VW_PHONG_CHITIET','VW_DATPHONG_CHITIET','VW_HOADON_CHITIET',
                                 'VW_DOANHTHU_THEONGAY','VW_DOANHTHU_THEOLOAIPHONG')) LOOP
    EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
  END LOOP;
  FOR t IN (SELECT table_name FROM user_tables
             WHERE table_name IN ('LUUKHUYENMAI','DANHGIA','KHUYENMAI','KHACHSAN','HOADON',
                                  'SUDUNGDICHVU','DATPHONG','PHONG','LOAIPHONG','DICHVU',
                                  'NHANVIEN','KHACHHANG')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/
