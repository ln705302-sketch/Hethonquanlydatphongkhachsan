const config = require('./config');
const db = require('./db');
const { migrate } = require('./migrate');
const { createApp } = require('./app');

(async () => {
  await db.init(config.db);
  if (await migrate()) console.log('Đã tạo schema và nạp dữ liệu mẫu.');
  const server = createApp().listen(config.port, () => {
    console.log(`Sunrise Hotel API đang chạy tại http://localhost:${config.port}/api`);
  });
  const stop = async () => {
    server.close();
    await db.close();
    process.exit(0);
  };
  process.on('SIGINT', stop);
  process.on('SIGTERM', stop);
})().catch((e) => {
  console.error('Không khởi động được server:', e.message);
  process.exit(1);
});
