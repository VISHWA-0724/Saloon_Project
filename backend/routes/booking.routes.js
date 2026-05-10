const express = require('express');
const { protect } = require('../middleware/auth.middleware');
const {
  applyCoupon,
  createBooking,
  getMyBookings,
  cancelBooking,
  rescheduleBooking,
} = require('../controllers/booking.controller');

const router = express.Router();

router.post('/apply-coupon', protect, applyCoupon);
router.post('/', protect, createBooking);
router.get('/my', protect, getMyBookings);
router.patch('/:id/cancel', protect, cancelBooking);
router.patch('/:id/reschedule', protect, rescheduleBooking);

module.exports = router;

