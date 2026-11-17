const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');

const auth = require('./auth');
const { ApiError, fromOracle } = require('./errors');

/** Tạo ứng dụng Express (tách khỏi server.js để test bằng supertest) */
function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));
  app.use(auth.attachUser);

  app.get('/api/health', (_req, res) => res.json({ ok: true }));
  for (const name of ['auth', 'users', 'catalog', 'bookings', 'content', 'reports']) {
    app.use('/api', require(`./routes/${name}`));
  }

  app.use('/api', (_req, res) => res.status(404).json({ error: 'Không tìm thấy API' }));

  // Phục vụ bản build Flutter web (../build/web) nếu có; mọi đường dẫn khác
  // /api trả về index.html để URL dạng /rooms, /admin/... hoạt động khi F5
  const webDir = path.join(__dirname, '..', '..', 'build', 'web');
  if (fs.existsSync(path.join(webDir, 'index.html'))) {
    app.use(express.static(webDir));
    app.get(/^\/(?!api\/).*/, (_req, res) => res.sendFile(path.join(webDir, 'index.html')));
  }

  // Xử lý lỗi tập trung: lỗi nghiệp vụ, lỗi Oracle, JSON sai, lỗi không lường trước
  // eslint-disable-next-line no-unused-vars
  app.use((err, _req, res, _next) => {
    if (err instanceof ApiError) return res.status(err.status).json({ error: err.message });
    if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'Dữ liệu gửi lên không hợp lệ' });
    const mapped = fromOracle(err);
    if (mapped) return res.status(mapped.status).json({ error: mapped.message });
    console.error(err);
    res.status(500).json({ error: 'Lỗi máy chủ, vui lòng thử lại' });
  });
  return app;
}

module.exports = { createApp };
