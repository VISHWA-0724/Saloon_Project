const asyncHandler = require('express-async-handler');

const { getDB, now } = require('../config/db');
const { getWishlistIds, toService, toUser } = require('../utils/db.util');

function getUserRow(userId) {
  return getDB().prepare('SELECT * FROM users WHERE id = ?').get(userId);
}

const getProfile = asyncHandler(async (req, res) => {
  const user = getUserRow(req.userId);
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  res.json(toUser(user, getWishlistIds(req.userId)));
});

const updateProfile = asyncHandler(async (req, res) => {
  const { name, phone, profileImage } = req.body || {};
  const user = getUserRow(req.userId);
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  if (name !== undefined && String(name).trim().length < 2) {
    res.status(400);
    throw new Error('Name must be at least 2 characters');
  }
  if (phone !== undefined && !/^[0-9]{10,}$/.test(String(phone).trim())) {
    res.status(400);
    throw new Error('Phone must be numeric and at least 10 digits');
  }

  getDB()
    .prepare(`
      UPDATE users
      SET name = COALESCE(?, name),
          phone = COALESCE(?, phone),
          profile_image = COALESCE(?, profile_image),
          updated_at = ?
      WHERE id = ?
    `)
    .run(
      name === undefined ? null : String(name).trim(),
      phone === undefined ? null : String(phone).trim(),
      profileImage === undefined ? null : String(profileImage),
      now(),
      req.userId
    );

  res.json(toUser(getUserRow(req.userId), getWishlistIds(req.userId)));
});

const uploadProfileImage = asyncHandler(async (req, res) => {
  const user = getUserRow(req.userId);
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }

  const imageUrl =
    req.body?.profileImage ||
    req.body?.url ||
    (req.file ? `${process.env.CLIENT_URL || 'http://localhost:5000'}/uploads/${req.file.filename}` : '');
  if (!imageUrl) {
    res.status(400);
    throw new Error('Image file or URL is required');
  }

  getDB()
    .prepare('UPDATE users SET profile_image = ?, updated_at = ? WHERE id = ?')
    .run(String(imageUrl), now(), req.userId);

  res.json({
    url: imageUrl,
    user: toUser(getUserRow(req.userId), getWishlistIds(req.userId)),
  });
});

const updateWishlist = asyncHandler(async (req, res) => {
  const { serviceId, wishlist } = req.body || {};
  const user = getUserRow(req.userId);
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }

  if (Array.isArray(wishlist)) {
    getDB().prepare('DELETE FROM wishlist WHERE user_id = ?').run(req.userId);
    const insert = getDB().prepare('INSERT OR IGNORE INTO wishlist (user_id, service_id, created_at) VALUES (?, ?, ?)');
    for (const id of wishlist) {
      insert.run(req.userId, String(id), now());
    }
  } else if (serviceId) {
    const id = String(serviceId);
    const exists = getDB()
      .prepare('SELECT service_id FROM wishlist WHERE user_id = ? AND service_id = ?')
      .get(req.userId, id);
    if (exists) {
      getDB().prepare('DELETE FROM wishlist WHERE user_id = ? AND service_id = ?').run(req.userId, id);
    } else {
      getDB()
        .prepare('INSERT OR IGNORE INTO wishlist (user_id, service_id, created_at) VALUES (?, ?, ?)')
        .run(req.userId, id, now());
    }
  } else {
    res.status(400);
    throw new Error('serviceId or wishlist array is required');
  }

  res.json({ wishlist: getWishlistIds(req.userId) });
});

const getWishlist = asyncHandler(async (req, res) => {
  const rows = getDB()
    .prepare(`
      SELECT s.*
      FROM wishlist w
      JOIN services s ON s.id = w.service_id
      WHERE w.user_id = ? AND s.is_active = 1
      ORDER BY w.created_at DESC
    `)
    .all(req.userId);
  res.json(rows.map(toService));
});

module.exports = { getProfile, getWishlist, updateProfile, updateWishlist, uploadProfileImage };
