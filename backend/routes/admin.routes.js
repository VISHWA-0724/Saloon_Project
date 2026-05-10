const express = require('express');

const { getAllBookings, getDashboard, updateBookingStatus } = require('../controllers/admin.controller');
const { adminOnly, protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect, adminOnly);
router.get('/dashboard', getDashboard);
router.get('/bookings', getAllBookings);
router.patch('/bookings/:id/status', updateBookingStatus);

module.exports = router;
