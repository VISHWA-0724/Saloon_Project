const asyncHandler = require('express-async-handler');
const bcrypt = require('bcryptjs');

const { getDB, makeId, now } = require('../config/db');
const { getWishlistIds, toUser } = require('../utils/db.util');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../utils/jwt.util');

function findUserByEmail(email) {
  return getDB()
    .prepare('SELECT * FROM users WHERE lower(email) = lower(?)')
    .get(String(email || '').trim());
}

function findUserById(id) {
  return getDB().prepare('SELECT * FROM users WHERE id = ?').get(id);
}

function authResponse(userRow) {
  const user = toUser(userRow, getWishlistIds(userRow.id));
  const payload = { userId: user.id, email: user.email, role: user.role };
  const token = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);

  getDB()
    .prepare('UPDATE users SET refresh_token = ?, updated_at = ? WHERE id = ?')
    .run(refreshToken, now(), user.id);

  return { token, refreshToken, user };
}

const register = asyncHandler(async (req, res) => {
  const { name, email, phone, password } = req.body || {};
  if (!name || !email || !phone || !password) {
    res.status(400);
    throw new Error('Missing required fields');
  }
  if (String(password).length < 6) {
    res.status(400);
    throw new Error('Password must be at least 6 characters');
  }
  if (findUserByEmail(email)) {
    res.status(409);
    throw new Error('Email already in use');
  }

  const createdAt = now();
  const userId = makeId('usr');
  const passwordHash = await bcrypt.hash(password, 10);
  getDB()
    .prepare(`
      INSERT INTO users (
        id, name, email, phone, password_hash, role, points,
        bookings_count, reviews_count, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, 'user', 0, 0, 0, ?, ?)
    `)
    .run(
      userId,
      String(name).trim(),
      String(email).trim().toLowerCase(),
      String(phone).trim(),
      passwordHash,
      createdAt,
      createdAt
    );

  res.json(authResponse(findUserById(userId)));
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    res.status(400);
    throw new Error('Missing credentials');
  }

  const user = findUserByEmail(email);
  if (!user) {
    res.status(401);
    throw new Error('Invalid credentials');
  }

  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) {
    res.status(401);
    throw new Error('Invalid credentials');
  }

  res.json(authResponse(user));
});

const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body || {};
  if (!refreshToken) {
    res.status(401);
    throw new Error('Refresh token required');
  }

  const decoded = verifyRefreshToken(refreshToken);
  const user = findUserById(decoded.userId);
  if (!user || user.refresh_token !== refreshToken) {
    res.status(401);
    throw new Error('Invalid refresh token');
  }

  const token = signAccessToken({ userId: user.id, email: user.email, role: user.role });
  res.json({ accessToken: token });
});

module.exports = { register, login, refresh };
