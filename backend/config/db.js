const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { DatabaseSync } = require('node:sqlite');

let db;

const defaultServices = [
  {
    id: 'srv_haircut',
    title: 'Signature Hair Cut',
    category: 'Hair',
    description: 'Precision cut, wash, blow dry, and styling by a senior stylist.',
    price: 799,
    originalPrice: 999,
    duration: 45,
    images: ['https://images.unsplash.com/photo-1560066984-138dadb4c035?w=900'],
    rating: 4.8,
    reviewCount: 124,
    addOns: [
      { name: 'Beard Trim', price: 199, duration: 15 },
      { name: 'Hair Spa', price: 499, duration: 30 },
    ],
    availableSlots: ['10:00', '11:30', '13:00', '15:00', '17:30', '19:00'],
    salonName: 'SalonEase Elite',
    salonLocation: 'MG Road, Bengaluru',
  },
  {
    id: 'srv_spa_glow',
    title: 'Facial & Spa Glow',
    category: 'Spa',
    description: 'Deep cleanse, hydration therapy, glow mask, and relaxing face massage.',
    price: 1299,
    originalPrice: 1699,
    duration: 60,
    images: ['https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=900'],
    rating: 4.7,
    reviewCount: 98,
    addOns: [
      { name: 'Under-eye Treatment', price: 249, duration: 10 },
      { name: 'Aroma Massage', price: 399, duration: 20 },
    ],
    availableSlots: ['10:30', '12:00', '14:00', '16:00', '18:00'],
    salonName: 'SalonEase Studio',
    salonLocation: 'Hitech City, Hyderabad',
  },
  {
    id: 'srv_manicure',
    title: 'Gel Manicure',
    category: 'Nails',
    description: 'Gel finish manicure with cuticle care, nail shaping, and hand massage.',
    price: 899,
    originalPrice: 1199,
    duration: 50,
    images: ['https://images.unsplash.com/photo-1607779097040-26e80aa78e66?w=900'],
    rating: 4.6,
    reviewCount: 76,
    addOns: [
      { name: 'Nail Art', price: 199, duration: 10 },
      { name: 'Paraffin Dip', price: 299, duration: 15 },
    ],
    availableSlots: ['11:00', '13:30', '15:30', '17:00', '19:30'],
    salonName: 'SalonEase Nails Bar',
    salonLocation: 'Bandra, Mumbai',
  },
  {
    id: 'srv_makeup',
    title: 'Glam Makeup',
    category: 'Makeup',
    description: 'Professional base, eye makeup, lip finish, setting spray, and touch-up kit.',
    price: 1999,
    originalPrice: 2499,
    duration: 70,
    images: ['https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=900'],
    rating: 4.9,
    reviewCount: 210,
    addOns: [
      { name: 'Lashes', price: 299, duration: 10 },
      { name: 'Hair Styling', price: 499, duration: 25 },
    ],
    availableSlots: ['10:00', '12:30', '15:00', '17:30'],
    salonName: 'SalonEase Glam',
    salonLocation: 'Connaught Place, Delhi',
  },
  {
    id: 'srv_keratin',
    title: 'Keratin Smoothening',
    category: 'Hair',
    description: 'Long-lasting frizz control and smoothening treatment for silky hair.',
    price: 3499,
    originalPrice: 4299,
    duration: 120,
    images: ['https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=900'],
    rating: 4.8,
    reviewCount: 88,
    addOns: [],
    availableSlots: ['11:00', '14:00', '17:00'],
    salonName: 'SalonEase Elite',
    salonLocation: 'Indiranagar, Bengaluru',
  },
  {
    id: 'srv_pedicure',
    title: 'Pedicure Deluxe',
    category: 'Nails',
    description: 'Foot soak, scrub, massage, polish, and heel care.',
    price: 999,
    originalPrice: 1299,
    duration: 55,
    images: ['https://images.unsplash.com/photo-1519014816548-bf5fe059798b?w=900'],
    rating: 4.5,
    reviewCount: 67,
    addOns: [],
    availableSlots: ['11:00', '13:00', '16:30'],
    salonName: 'SalonEase Nails Bar',
    salonLocation: 'Bandra, Mumbai',
  },
];

const defaultCoupons = [
  {
    code: 'FIRST20',
    discountType: 'percent',
    discountValue: 20,
    minOrderAmount: 500,
    maxUses: 1000,
    expiryDate: '2030-12-31',
  },
  {
    code: 'BEAUTY20',
    discountType: 'percent',
    discountValue: 20,
    minOrderAmount: 500,
    maxUses: 1000,
    expiryDate: '2030-12-31',
  },
  {
    code: 'NEWLOOK',
    discountType: 'flat',
    discountValue: 500,
    minOrderAmount: 2000,
    maxUses: 1000,
    expiryDate: '2030-12-31',
  },
];

function now() {
  return new Date().toISOString();
}

function makeId(prefix) {
  return `${prefix}_${crypto.randomUUID()}`;
}

function getDatabasePath() {
  const configured = process.env.SQLITE_PATH || 'data/salonease.sqlite';
  return path.isAbsolute(configured)
    ? configured
    : path.join(__dirname, '..', configured);
}

function migrate(database) {
  database.exec(`
    PRAGMA foreign_keys = ON;
    PRAGMA journal_mode = WAL;

    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      phone TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      profile_image TEXT NOT NULL DEFAULT '',
      role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
      points INTEGER NOT NULL DEFAULT 0,
      bookings_count INTEGER NOT NULL DEFAULT 0,
      reviews_count INTEGER NOT NULL DEFAULT 0,
      refresh_token TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS services (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT NOT NULL,
      price INTEGER NOT NULL,
      original_price INTEGER NOT NULL,
      duration INTEGER NOT NULL,
      images_json TEXT NOT NULL DEFAULT '[]',
      rating REAL NOT NULL DEFAULT 4.7,
      review_count INTEGER NOT NULL DEFAULT 0,
      salon_name TEXT NOT NULL,
      salon_location TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS service_addons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      service_id TEXT NOT NULL,
      name TEXT NOT NULL,
      price INTEGER NOT NULL,
      duration INTEGER NOT NULL,
      FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS service_slots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      service_id TEXT NOT NULL,
      slot TEXT NOT NULL,
      FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS coupons (
      code TEXT PRIMARY KEY,
      discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'flat')),
      discount_value INTEGER NOT NULL,
      min_order_amount INTEGER NOT NULL DEFAULT 0,
      max_uses INTEGER NOT NULL DEFAULT 0,
      used_count INTEGER NOT NULL DEFAULT 0,
      expiry_date TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS bookings (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      service_id TEXT NOT NULL,
      date TEXT NOT NULL,
      time_slot TEXT NOT NULL,
      payment_method TEXT NOT NULL,
      coupon TEXT,
      subtotal INTEGER NOT NULL,
      gst INTEGER NOT NULL,
      discount INTEGER NOT NULL,
      total INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'confirmed', 'cancelled')),
      booking_id TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (service_id) REFERENCES services(id)
    );

    CREATE TABLE IF NOT EXISTS booking_addons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      booking_id TEXT NOT NULL,
      name TEXT NOT NULL,
      price INTEGER NOT NULL,
      duration INTEGER NOT NULL,
      FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS wishlist (
      user_id TEXT NOT NULL,
      service_id TEXT NOT NULL,
      created_at TEXT NOT NULL,
      PRIMARY KEY (user_id, service_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS reviews (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      service_id TEXT NOT NULL,
      rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
      comment TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
    );
  `);
}

function seedUsers(database) {
  const count = database.prepare('SELECT COUNT(*) AS total FROM users').get().total;
  if (count > 0) return;

  const insert = database.prepare(`
    INSERT INTO users (
      id, name, email, phone, password_hash, profile_image, role,
      points, bookings_count, reviews_count, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const createdAt = now();

  insert.run(
    'usr_admin',
    'Salon Admin',
    'admin@salonease.com',
    '9999999999',
    bcrypt.hashSync('admin123', 10),
    '',
    'admin',
    0,
    0,
    0,
    createdAt,
    createdAt
  );

  insert.run(
    'usr_demo',
    'Demo User',
    'user@salonease.com',
    '9876543210',
    bcrypt.hashSync('user123', 10),
    '',
    'user',
    120,
    0,
    0,
    createdAt,
    createdAt
  );
}

function seedServices(database) {
  const count = database.prepare('SELECT COUNT(*) AS total FROM services').get().total;
  if (count > 0) return;

  const insertService = database.prepare(`
    INSERT INTO services (
      id, title, category, description, price, original_price, duration,
      images_json, rating, review_count, salon_name, salon_location,
      is_active, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
  `);
  const insertAddOn = database.prepare(`
    INSERT INTO service_addons (service_id, name, price, duration)
    VALUES (?, ?, ?, ?)
  `);
  const insertSlot = database.prepare(`
    INSERT INTO service_slots (service_id, slot)
    VALUES (?, ?)
  `);
  const createdAt = now();

  for (const service of defaultServices) {
    insertService.run(
      service.id,
      service.title,
      service.category,
      service.description,
      service.price,
      service.originalPrice,
      service.duration,
      JSON.stringify(service.images),
      service.rating,
      service.reviewCount,
      service.salonName,
      service.salonLocation,
      createdAt,
      createdAt
    );
    for (const addOn of service.addOns) {
      insertAddOn.run(service.id, addOn.name, addOn.price, addOn.duration);
    }
    for (const slot of service.availableSlots) {
      insertSlot.run(service.id, slot);
    }
  }
}

function seedCoupons(database) {
  const count = database.prepare('SELECT COUNT(*) AS total FROM coupons').get().total;
  if (count > 0) return;

  const insert = database.prepare(`
    INSERT INTO coupons (
      code, discount_type, discount_value, min_order_amount, max_uses,
      used_count, expiry_date, is_active, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, 0, ?, 1, ?, ?)
  `);
  const createdAt = now();

  for (const coupon of defaultCoupons) {
    insert.run(
      coupon.code,
      coupon.discountType,
      coupon.discountValue,
      coupon.minOrderAmount,
      coupon.maxUses,
      coupon.expiryDate,
      createdAt,
      createdAt
    );
  }
}

function seed(database) {
  seedUsers(database);
  seedServices(database);
  seedCoupons(database);
}

function connectDB() {
  if (db) return db;

  const filePath = getDatabasePath();
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  db = new DatabaseSync(filePath);
  migrate(db);
  seed(db);
  return db;
}

function getDB() {
  return db || connectDB();
}

module.exports = {
  connectDB,
  getDB,
  getDatabasePath,
  makeId,
  now,
};
