require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');
const { getDatabasePath } = require('../config/db');

const dbPath = getDatabasePath();
const dbDir = path.dirname(dbPath);
const dbName = path.basename(dbPath);

function formatSize(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

function printFiles() {
  console.log('Database files:');
  if (!fs.existsSync(dbDir)) {
    console.log(`- No database directory found at ${dbDir}`);
    return;
  }

  const files = fs
    .readdirSync(dbDir)
    .filter((name) => name === dbName || name.startsWith(`${dbName}-`))
    .sort();

  if (files.length === 0) {
    console.log(`- No SQLite files found for ${dbPath}`);
    return;
  }

  for (const file of files) {
    const fullPath = path.join(dbDir, file);
    const stat = fs.statSync(fullPath);
    console.log(`- ${fullPath} (${formatSize(stat.size)})`);
  }
}

printFiles();

if (!fs.existsSync(dbPath)) {
  process.exit(0);
}

const db = new DatabaseSync(dbPath);
try {
  const tables = db
    .prepare(`
      SELECT name
      FROM sqlite_schema
      WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    `)
    .all();

  console.log('\nTable counts:');
  for (const table of tables) {
    const count = db.prepare(`SELECT COUNT(*) AS total FROM ${table.name}`).get().total;
    console.log(`- ${table.name}: ${count}`);
  }

  console.log('\nCustomers:');
  const customers = db
    .prepare(`
      SELECT id, name, email, phone, bookings_count, points, created_at
      FROM users
      WHERE role = 'user'
      ORDER BY created_at DESC
      LIMIT 20
    `)
    .all();
  if (customers.length === 0) {
    console.log('- No customers found');
  } else {
    for (const customer of customers) {
      console.log(
        `- ${customer.name} | ${customer.email} | ${customer.phone} | bookings: ${customer.bookings_count} | points: ${customer.points}`
      );
    }
  }

  console.log('\nRecent bookings:');
  const bookings = db
    .prepare(`
      SELECT b.booking_id, u.name, s.title, b.date, b.time_slot, b.total, b.status
      FROM bookings b
      JOIN users u ON u.id = b.user_id
      JOIN services s ON s.id = b.service_id
      ORDER BY b.created_at DESC
      LIMIT 10
    `)
    .all();
  if (bookings.length === 0) {
    console.log('- No bookings found');
  } else {
    for (const booking of bookings) {
      console.log(
        `- ${booking.booking_id} | ${booking.name} | ${booking.title} | ${booking.date} ${booking.time_slot} | Rs. ${booking.total} | ${booking.status}`
      );
    }
  }
} finally {
  db.close();
}
