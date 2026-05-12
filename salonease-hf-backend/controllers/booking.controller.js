const asyncHandler = require('express-async-handler');

const { getDB, makeId, now } = require('../config/db');
const { normalizeDate, toBooking } = require('../utils/db.util');

function makeBookingId() {
  const ts = Date.now().toString();
  return `#SALON${ts.substring(ts.length - 6)}`;
}

function getCoupon(code) {
  return getDB()
    .prepare('SELECT * FROM coupons WHERE code = ?')
    .get(String(code || '').trim().toUpperCase());
}

function validateCoupon(coupon, orderAmount, res) {
  if (!coupon || !coupon.is_active) {
    res.status(400);
    throw new Error('Coupon not valid');
  }
  if (coupon.expiry_date < new Date().toISOString().slice(0, 10)) {
    res.status(400);
    throw new Error('Coupon expired');
  }
  if (coupon.max_uses > 0 && coupon.used_count >= coupon.max_uses) {
    res.status(400);
    throw new Error('Coupon usage limit reached');
  }
  if (orderAmount < coupon.min_order_amount) {
    res.status(400);
    throw new Error(`Minimum order amount is ${coupon.min_order_amount}`);
  }
}

function calculateDiscount(coupon, orderAmount) {
  if (coupon.discount_type === 'percent') {
    return Math.round((orderAmount * coupon.discount_value) / 100);
  }
  return Number(coupon.discount_value);
}

const applyCoupon = asyncHandler(async (req, res) => {
  const { code, subtotal } = req.body || {};
  const orderAmount = Number(subtotal || 0);
  if (!code) {
    res.status(400);
    throw new Error('Code required');
  }

  const coupon = getCoupon(code);
  validateCoupon(coupon, orderAmount, res);
  const discountAmount = calculateDiscount(coupon, orderAmount);
  res.json({ ok: true, discount: discountAmount, discountAmount, code: coupon.code });
});

const createBooking = asyncHandler(async (req, res) => {
  const { serviceId, date, timeSlot, addOns = [], paymentMethod, coupon = null } = req.body || {};
  const bookingDate = normalizeDate(date);

  if (!serviceId || !bookingDate || !timeSlot || !paymentMethod) {
    res.status(400);
    throw new Error('Missing booking fields');
  }

  const service = getDB()
    .prepare('SELECT * FROM services WHERE id = ? AND is_active = 1')
    .get(serviceId);
  if (!service) {
    res.status(404);
    throw new Error('Service not found');
  }

  const existing = getDB()
    .prepare(`
      SELECT id FROM bookings
      WHERE service_id = ? AND date = ? AND time_slot = ? AND status <> 'cancelled'
      LIMIT 1
    `)
    .get(serviceId, bookingDate, timeSlot);
  if (existing) {
    res.status(409);
    throw new Error('Selected slot is already booked');
  }

  const selectedAddOns = Array.isArray(addOns) ? addOns : [];
  const addOnsTotal = selectedAddOns.reduce((acc, item) => acc + Number(item?.price || 0), 0);
  const subtotal = Number(service.price) + addOnsTotal;
  const gst = Math.round((subtotal * 18) / 100);
  let discount = 0;
  let couponCode = null;

  if (coupon) {
    const cp = getCoupon(coupon);
    validateCoupon(cp, subtotal, res);
    discount = calculateDiscount(cp, subtotal);
    couponCode = cp.code;
    getDB()
      .prepare('UPDATE coupons SET used_count = used_count + 1, updated_at = ? WHERE code = ?')
      .run(now(), cp.code);
  }

  const total = Math.max(0, subtotal + gst - discount);
  const createdAt = now();
  const bookingPk = makeId('book');
  const publicBookingId = makeBookingId();

  getDB()
    .prepare(`
      INSERT INTO bookings (
        id, user_id, service_id, date, time_slot, payment_method, coupon,
        subtotal, gst, discount, total, status, booking_id, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'upcoming', ?, ?, ?)
    `)
    .run(
      bookingPk,
      req.userId,
      serviceId,
      bookingDate,
      String(timeSlot),
      String(paymentMethod),
      couponCode,
      subtotal,
      gst,
      discount,
      total,
      publicBookingId,
      createdAt,
      createdAt
    );

  const insertAddOn = getDB().prepare(`
    INSERT INTO booking_addons (booking_id, name, price, duration)
    VALUES (?, ?, ?, ?)
  `);
  for (const addOn of selectedAddOns) {
    if (addOn?.name) {
      insertAddOn.run(bookingPk, String(addOn.name), Number(addOn.price || 0), Number(addOn.duration || 0));
    }
  }

  getDB()
    .prepare(`
      UPDATE users
      SET bookings_count = bookings_count + 1, points = points + 10, updated_at = ?
      WHERE id = ?
    `)
    .run(now(), req.userId);

  const row = getDB().prepare('SELECT * FROM bookings WHERE id = ?').get(bookingPk);
  res.json({ ok: true, booking: toBooking(row) });
});

const getMyBookings = asyncHandler(async (req, res) => {
  const rows = getDB()
    .prepare('SELECT * FROM bookings WHERE user_id = ? ORDER BY date DESC, created_at DESC LIMIT 100')
    .all(req.userId);
  const items = rows.map(toBooking);
  const grouped = items.reduce(
    (acc, booking) => {
      const key = booking.status || 'upcoming';
      if (!acc[key]) acc[key] = [];
      acc[key].push(booking);
      return acc;
    },
    { upcoming: [], cancelled: [], confirmed: [] }
  );

  res.json({ grouped, items });
});

const cancelBooking = asyncHandler(async (req, res) => {
  const booking = getDB()
    .prepare('SELECT * FROM bookings WHERE id = ? AND user_id = ?')
    .get(req.params.id, req.userId);
  if (!booking) {
    res.status(404);
    throw new Error('Booking not found');
  }
  if (booking.status !== 'upcoming') {
    res.status(400);
    throw new Error('This booking is already locked by the salon');
  }
  if (booking.date <= new Date().toISOString().slice(0, 10)) {
    res.status(400);
    throw new Error('Only future bookings can be cancelled');
  }

  getDB()
    .prepare("UPDATE bookings SET status = 'cancelled', updated_at = ? WHERE id = ?")
    .run(now(), booking.id);
  const row = getDB().prepare('SELECT * FROM bookings WHERE id = ?').get(booking.id);
  res.json({ ok: true, booking: toBooking(row) });
});

const rescheduleBooking = asyncHandler(async (req, res) => {
  const { date, timeSlot } = req.body || {};
  const bookingDate = normalizeDate(date);
  if (!bookingDate || !timeSlot) {
    res.status(400);
    throw new Error('date and timeSlot are required');
  }

  const booking = getDB()
    .prepare('SELECT * FROM bookings WHERE id = ? AND user_id = ?')
    .get(req.params.id, req.userId);
  if (!booking) {
    res.status(404);
    throw new Error('Booking not found');
  }
  if (booking.status !== 'upcoming') {
    res.status(400);
    throw new Error('This booking is already locked by the salon');
  }

  const conflict = getDB()
    .prepare(`
      SELECT id FROM bookings
      WHERE id <> ? AND service_id = ? AND date = ? AND time_slot = ? AND status <> 'cancelled'
      LIMIT 1
    `)
    .get(booking.id, booking.service_id, bookingDate, timeSlot);
  if (conflict) {
    res.status(409);
    throw new Error('Selected slot is already booked');
  }

  getDB()
    .prepare("UPDATE bookings SET date = ?, time_slot = ?, status = 'upcoming', updated_at = ? WHERE id = ?")
    .run(bookingDate, String(timeSlot), now(), booking.id);
  const row = getDB().prepare('SELECT * FROM bookings WHERE id = ?').get(booking.id);
  res.json({ ok: true, booking: toBooking(row) });
});

module.exports = { applyCoupon, createBooking, getMyBookings, cancelBooking, rescheduleBooking };
