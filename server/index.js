const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

// Middleware
app.use(cors());
app.use(express.json());

// Database configuration
const rawDbPath = process.env.DB_PATH || path.join(__dirname, 'users.db');
const dbPath = path.isAbsolute(rawDbPath) ? rawDbPath : path.resolve(process.cwd(), rawDbPath);

// Ensure directory for db exists
const dbDir = path.dirname(dbPath);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

console.log(`Connecting to SQLite database at: ${dbPath}`);
const db = new Database(dbPath);

// Enable WAL mode for performance
db.pragma('journal_mode = WAL');

// Re-create users table on startup
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    pwd_hash TEXT NOT NULL
  )
`);

// Utility to calculate SHA-512 hex
function sha512Hex(password) {
  return crypto.createHash('sha512').update(password).digest('hex');
}

// Seed initial users on startup
const seedUsers = [
  { id: 'alex_dev', password: 'password123' },
  { id: 'navaneet', password: 'test1234' },
];

const insertUserStmt = db.prepare(`
  INSERT OR REPLACE INTO users (id, pwd_hash)
  VALUES (?, ?)
`);

console.log('Seeding initial users into SQLite database...');
const seedTransaction = db.transaction((users) => {
  for (const user of users) {
    const hash = sha512Hex(user.password);
    insertUserStmt.run(user.id, hash);
    console.log(` - Seeded user: ${user.id}`);
  }
});
seedTransaction(seedUsers);

// Prepared queries
const findUserByIdStmt = db.prepare('SELECT id, pwd_hash FROM users WHERE id = ?');

// Validation regex for 128 hex characters (SHA-512)
const SHA512_REGEX = /^[a-fA-F0-9]{128}$/;

/**
 * Health check endpoints
 */
app.get('/health', (req, res) => {
  res.status(200).json({ ok: true });
});

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    ok: true,
    timestamp: new Date().toISOString(),
  });
});

/**
 * POST /api/login
 * Body: { id: string, pwdHash: string }
 */
app.post('/api/login', (req, res) => {
  try {
    const { id, pwdHash } = req.body || {};

    if (!id || typeof id !== 'string' || !pwdHash || typeof pwdHash !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Invalid request: "id" and "pwdHash" are required strings.',
      });
    }

    const trimmedId = id.trim();
    const cleanPwdHash = pwdHash.trim().toLowerCase();

    // Validate that pwdHash is exactly 128 hex characters
    if (!SHA512_REGEX.test(cleanPwdHash)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid hash format: pwdHash must be a 128-character hex string.',
      });
    }

    const user = findUserByIdStmt.get(trimmedId);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid id or password',
      });
    }

    const storedHash = user.pwd_hash.toLowerCase();
    const storedBuffer = Buffer.from(storedHash, 'hex');
    const receivedBuffer = Buffer.from(cleanPwdHash, 'hex');

    // Constant-time comparison using crypto.timingSafeEqual
    if (
      storedBuffer.length === receivedBuffer.length &&
      crypto.timingSafeEqual(storedBuffer, receivedBuffer)
    ) {
      return res.status(200).json({
        success: true,
        id: user.id,
        hash: storedHash,
      });
    } else {
      return res.status(401).json({
        success: false,
        message: 'Invalid id or password',
      });
    }
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
});

/**
 * POST /api/register (Optional)
 * Body: { id: string, pwdHash: string }
 */
app.post('/api/register', (req, res) => {
  try {
    const { id, pwdHash } = req.body || {};

    if (!id || typeof id !== 'string' || !pwdHash || typeof pwdHash !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Invalid request: "id" and "pwdHash" are required strings.',
      });
    }

    const trimmedId = id.trim();
    const cleanPwdHash = pwdHash.trim().toLowerCase();

    if (trimmedId.length < 3) {
      return res.status(400).json({
        success: false,
        message: 'Username/ID must be at least 3 characters long.',
      });
    }

    if (!SHA512_REGEX.test(cleanPwdHash)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid hash format: pwdHash must be a 128-character hex string.',
      });
    }

    const existingUser = findUserByIdStmt.get(trimmedId);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User ID already exists.',
      });
    }

    insertUserStmt.run(trimmedId, cleanPwdHash);
    return res.status(201).json({
      success: true,
      message: 'User registered successfully.',
      id: trimmedId,
      hash: cleanPwdHash,
    });
  } catch (error) {
    console.error('Registration error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
});

// Start listening on 0.0.0.0:PORT
app.listen(PORT, HOST, () => {
  console.log(`🚀 Authentication server listening on http://${HOST}:${PORT}`);
  console.log(`   - Health check: http://${HOST}:${PORT}/health`);
  console.log(`   - Local access: http://localhost:${PORT}`);
});
