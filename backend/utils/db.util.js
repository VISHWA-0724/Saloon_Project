const { getDB } = require('../config/db');

function safeJsonArray(raw) {
  try {
    const parsed = JSON.parse(raw || '[]');
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

function toUser(row, wishlist = []) {
  if (!row) return null;
  return {
    _id: row.id,
    id: row.id,
    name: row.name,
    email: row.email,
    phone: row.phone,
    profileImage: row.profile_image || '',
    role: row.role || 'user',
    points: Number(row.points || 0),
    bookingsCount: Number(row.bookings_count || 0),
    reviewsCount: Number(row.reviews_count || 0),
    wishlist,
  };
}

function getWishlistIds(userId) {
  return getDB()
    .prepare('SELECT service_id FROM wishlist WHERE user_id = ? ORDER BY created_at DESC')
    .all(userId)
    .map((row) => row.service_id);
}

function toService(row) {
  if (!row) return null;
  const db = getDB();
  const addOns = db
    .prepare('SELECT name, price, duration FROM service_addons WHERE service_id = ? ORDER BY id ASC')
    .all(row.id)
    .map((item) => ({
      name: item.name,
      price: Number(item.price),
      duration: Number(item.duration),
    }));
  const availableSlots = db
    .prepare('SELECT slot FROM service_slots WHERE service_id = ? ORDER BY id ASC')
    .all(row.id)
    .map((item) => item.slot);

  return {
    _id: row.id,
    id: row.id,
    title: row.title,
    category: row.category,
    description: row.description,
    price: Number(row.price),
    originalPrice: Number(row.original_price),
    duration: Number(row.duration),
    images: safeJsonArray(row.images_json),
    rating: Number(row.rating),
    reviewCount: Number(row.review_count),
    addOns,
    availableSlots,
    salonName: row.salon_name,
    salonLocation: row.salon_location,
  };
}

function toBooking(row) {
  if (!row) return null;
  const db = getDB();
  const serviceRow = db.prepare('SELECT * FROM services WHERE id = ?').get(row.service_id);
  const service = toService(serviceRow);
  const addOns = db
    .prepare('SELECT name, price, duration FROM booking_addons WHERE booking_id = ? ORDER BY id ASC')
    .all(row.id)
    .map((item) => ({
      name: item.name,
      price: Number(item.price),
      duration: Number(item.duration),
    }));

  return {
    _id: row.id,
    id: row.id,
    userId: row.user_id,
    serviceId: service || row.service_id,
    service,
    serviceTitle: service?.title || '',
    salonName: service?.salonName || 'SalonEase Studio',
    salonLocation: service?.salonLocation || 'Premium Street, City',
    imageUrl: service?.images?.[0] || '',
    date: row.date,
    timeSlot: row.time_slot,
    addOns,
    paymentMethod: row.payment_method,
    coupon: row.coupon,
    subtotal: Number(row.subtotal),
    gst: Number(row.gst),
    discount: Number(row.discount),
    total: Number(row.total),
    status: row.status,
    bookingId: row.booking_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function normalizeDate(value) {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString().slice(0, 10);
}

module.exports = {
  getWishlistIds,
  normalizeDate,
  safeJsonArray,
  toBooking,
  toService,
  toUser,
};
