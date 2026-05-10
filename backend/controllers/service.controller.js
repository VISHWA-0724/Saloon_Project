const asyncHandler = require('express-async-handler');

const { getDB, makeId, now } = require('../config/db');
const { toService } = require('../utils/db.util');

const getAllServices = asyncHandler(async (req, res) => {
  const { category, minPrice, maxPrice, minRating, search } = req.query || {};
  const rows = getDB()
    .prepare('SELECT * FROM services WHERE is_active = 1 ORDER BY rating DESC, title ASC')
    .all();

  const q = String(search || '').trim().toLowerCase();
  const filtered = rows.filter((row) => {
    const categoryOk = !category || String(row.category).toLowerCase() === String(category).toLowerCase();
    const minPriceOk = !minPrice || Number(row.price) >= Number(minPrice);
    const maxPriceOk = !maxPrice || Number(row.price) <= Number(maxPrice);
    const ratingOk = !minRating || Number(row.rating) >= Number(minRating);
    const searchOk =
      !q ||
      String(row.title).toLowerCase().includes(q) ||
      String(row.description).toLowerCase().includes(q) ||
      String(row.category).toLowerCase().includes(q);
    return categoryOk && minPriceOk && maxPriceOk && ratingOk && searchOk;
  });

  res.json(filtered.map(toService));
});

const getServiceById = asyncHandler(async (req, res) => {
  const row = getDB()
    .prepare('SELECT * FROM services WHERE id = ? AND is_active = 1')
    .get(req.params.id);
  if (!row) {
    res.status(404);
    throw new Error('Service not found');
  }

  const reviews = getDB()
    .prepare(`
      SELECT r.id, r.rating, r.comment, r.created_at, u.name, u.profile_image
      FROM reviews r
      JOIN users u ON u.id = r.user_id
      WHERE r.service_id = ?
      ORDER BY r.created_at DESC
      LIMIT 5
    `)
    .all(row.id)
    .map((review) => ({
      _id: review.id,
      rating: Number(review.rating),
      comment: review.comment,
      createdAt: review.created_at,
      userId: {
        name: review.name,
        profileImage: review.profile_image || '',
      },
    }));

  res.json({ ...toService(row), reviews });
});

const createService = asyncHandler(async (req, res) => {
  const {
    title,
    category,
    description,
    price,
    originalPrice,
    duration,
    images = [],
    addOns = [],
    availableSlots = [],
    salonName = 'SalonEase Studio',
    salonLocation = 'Premium Street, City',
  } = req.body || {};

  if (!title || !category || !description || !price || !duration) {
    res.status(400);
    throw new Error('title, category, description, price and duration are required');
  }

  const id = makeId('srv');
  const createdAt = now();
  getDB()
    .prepare(`
      INSERT INTO services (
        id, title, category, description, price, original_price, duration,
        images_json, rating, review_count, salon_name, salon_location,
        is_active, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 4.7, 0, ?, ?, 1, ?, ?)
    `)
    .run(
      id,
      String(title).trim(),
      String(category).trim(),
      String(description).trim(),
      Number(price),
      Number(originalPrice || price),
      Number(duration),
      JSON.stringify(Array.isArray(images) ? images : []),
      String(salonName).trim(),
      String(salonLocation).trim(),
      createdAt,
      createdAt
    );

  const addOnInsert = getDB().prepare(
    'INSERT INTO service_addons (service_id, name, price, duration) VALUES (?, ?, ?, ?)'
  );
  for (const addOn of Array.isArray(addOns) ? addOns : []) {
    if (addOn?.name) addOnInsert.run(id, addOn.name, Number(addOn.price || 0), Number(addOn.duration || 0));
  }

  const slotInsert = getDB().prepare('INSERT INTO service_slots (service_id, slot) VALUES (?, ?)');
  for (const slot of Array.isArray(availableSlots) ? availableSlots : []) {
    if (slot) slotInsert.run(id, String(slot));
  }

  const row = getDB().prepare('SELECT * FROM services WHERE id = ?').get(id);
  res.status(201).json(toService(row));
});

module.exports = { createService, getAllServices, getServiceById };
