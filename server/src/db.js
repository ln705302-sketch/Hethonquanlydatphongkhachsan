const oracledb = require('oracledb');

// Kết quả trả về dạng object { COT: giá trị }. Cột DATE được driver đọc theo
// giờ địa phương rồi chuyển thành chuỗi 'YYYY-MM-DDTHH:MM:SS' (không có múi
// giờ) để client hiểu đúng là giờ địa phương, không bị lệch khi ra JSON
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.fetchTypeHandler = (meta) => {
  if (meta.dbType === oracledb.DB_TYPE_DATE) {
    return { converter: (v) => (v == null ? v : require('./dates').toDb(v)) };
  }
  return undefined;
};

/** Định dạng ngày giờ dùng chung giữa Node và Oracle */
const DF = 'YYYY-MM-DD"T"HH24:MI:SS';

let pool = null;

async function initSession(conn, _tag, cb) {
  try {
    await conn.execute(
      `ALTER SESSION SET NLS_DATE_FORMAT = '${DF}' NLS_NUMERIC_CHARACTERS = '.,'`,
    );
    cb();
  } catch (e) {
    cb(e);
  }
}

async function init(dbConfig) {
  if (pool) return pool;
  pool = await oracledb.createPool({
    ...dbConfig,
    poolMin: 1,
    poolMax: 10,
    poolIncrement: 1,
    sessionCallback: initSession,
  });
  return pool;
}

async function close() {
  if (!pool) return;
  await pool.close(5);
  pool = null;
}

/** Chạy một câu lệnh đơn (tự commit nếu là DML) và trả về các dòng */
async function query(sql, binds = {}, opts = {}) {
  const conn = await pool.getConnection();
  try {
    const r = await conn.execute(sql, binds, { autoCommit: true, ...opts });
    return r.rows || [];
  } finally {
    await conn.close();
  }
}

/**
 * Chạy [fn] trong một transaction: commit nếu thành công, rollback toàn bộ
 * nếu có lỗi. [fn] nhận đối tượng `t` với các hàm rows/one/exec/insert.
 */
async function tx(fn) {
  const conn = await pool.getConnection();
  const t = {
    conn,
    async rows(sql, binds = {}) {
      return (await conn.execute(sql, binds)).rows || [];
    },
    async one(sql, binds = {}) {
      return (await conn.execute(sql, binds)).rows?.[0] ?? null;
    },
    async exec(sql, binds = {}) {
      return conn.execute(sql, binds);
    },
    /** INSERT ... RETURNING <idCol> INTO :id, trả về id mới */
    async insert(sql, binds = {}) {
      const r = await conn.execute(sql, {
        ...binds,
        id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      });
      return r.outBinds.id[0];
    },
  };
  try {
    const result = await fn(t);
    await conn.commit();
    return result;
  } catch (e) {
    await conn.rollback().catch(() => {});
    throw e;
  } finally {
    await conn.close();
  }
}

module.exports = { init, close, query, tx, DF, oracledb };
