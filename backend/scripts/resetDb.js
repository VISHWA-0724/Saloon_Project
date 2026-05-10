require('dotenv').config();

const fs = require('fs');
const { connectDB, getDatabasePath } = require('../config/db');

const dbPath = getDatabasePath();

if (fs.existsSync(dbPath)) {
  fs.unlinkSync(dbPath);
}
if (fs.existsSync(`${dbPath}-shm`)) {
  fs.unlinkSync(`${dbPath}-shm`);
}
if (fs.existsSync(`${dbPath}-wal`)) {
  fs.unlinkSync(`${dbPath}-wal`);
}

connectDB();
// eslint-disable-next-line no-console
console.log(`SQLite database reset at ${dbPath}`);
