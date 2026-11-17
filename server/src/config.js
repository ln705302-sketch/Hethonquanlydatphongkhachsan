require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

/** Cấu hình đọc từ biến môi trường (file server/.env), có giá trị mặc định cho dev */
const config = {
  port: Number(process.env.PORT || 8080),
  jwtSecret: process.env.JWT_SECRET || 'dev-only-secret-change-me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  // Cho phép Quản lý khôi phục dữ liệu mẫu (tắt khi chạy thật)
  allowReset: (process.env.ALLOW_RESET || 'true') === 'true',
  db: {
    user: process.env.DB_USER || 'SUNRISE_HOTEL',
    password: process.env.DB_PASSWORD || 'Sunrise_2026',
    connectString: process.env.DB_CONNECT || 'localhost:1521/SCHOOLDB',
  },
  testDb: {
    user: process.env.TEST_DB_USER || 'SUNRISE_TEST',
    password: process.env.TEST_DB_PASSWORD || 'Sunrise_2026',
    connectString: process.env.DB_CONNECT || 'localhost:1521/SCHOOLDB',
  },
};

module.exports = config;
