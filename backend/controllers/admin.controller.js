const asyncHandler = require('express-async-handler');

const { getDB, now } = require('../config/db');
const { toBooking, toUser } = require('../utils/db.util');

const getDashboard = asyncHandler(async (_req, res) => {
  const db = getDB();
  const users = db.prepare("SELECT COUNT(*) AS total FROM users WHERE role = 'user'").get().total;
  const admins = db.prepare("SELECT COUNT(*) AS total FROM users WHERE role = 'admin'").get().total;
  const services = db.prepare('SELECT COUNT(*) AS total FROM services WHERE is_active = 1').get().total;
  const bookings = db.prepare('SELECT COUNT(*) AS total FROM bookings').get().total;
  const upcoming = db.prepare("SELECT COUNT(*) AS total FROM bookings WHERE status = 'upcoming'").get().total;
  const revenue = db
    .prepare("SELECT COALESCE(SUM(total), 0) AS total FROM bookings WHERE status <> 'cancelled'")
    .get().total;

  const recentBookings = db
    .prepare('SELECT * FROM bookings ORDER BY created_at DESC LIMIT 8')
    .all()
    .map(toBooking);
  const recentUsers = db
    .prepare("SELECT * FROM users WHERE role = 'user' ORDER BY created_at DESC LIMIT 5")
    .all()
    .map((row) => toUser(row));

  res.json({
    stats: {
      users: Number(users),
      admins: Number(admins),
      services: Number(services),
      bookings: Number(bookings),
      upcoming: Number(upcoming),
      revenue: Number(revenue),
    },
    recentBookings,
    recentUsers,
  });
});

const getAllBookings = asyncHandler(async (_req, res) => {
  const items = getDB()
    .prepare('SELECT * FROM bookings ORDER BY date DESC, created_at DESC LIMIT 200')
    .all()
    .map(toBooking);
  res.json({ items });
});

const updateBookingStatus = asyncHandler(async (req, res) => {
  const allowed = ['upcoming', 'confirmed', 'past', 'cancelled'];
  const status = String(req.body?.status || '').trim();
  if (!allowed.includes(status)) {
    res.status(400);
    throw new Error('Invalid booking status');
  }

  const booking = getDB().prepare('SELECT * FROM bookings WHERE id = ?').get(req.params.id);
  if (!booking) {
    res.status(404);
    throw new Error('Booking not found');
  }

  getDB()
    .prepare('UPDATE bookings SET status = ?, updated_at = ? WHERE id = ?')
    .run(status, now(), req.params.id);

  res.json({ ok: true, booking: toBooking(getDB().prepare('SELECT * FROM bookings WHERE id = ?').get(req.params.id)) });
});

module.exports = { getAllBookings, getDashboard, updateBookingStatus };
