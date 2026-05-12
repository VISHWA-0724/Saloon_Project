const express = require('express');
const { protect } = require('../middleware/auth.middleware');
const multer = require('multer');
const {
  getProfile,
  updateProfile,
  uploadProfileImage,
  updateWishlist,
  getWishlist,
} = require('../controllers/user.controller');

const router = express.Router();
const upload = multer({ dest: 'uploads/' });

router.get('/profile', protect, getProfile);
router.patch('/profile', protect, updateProfile);
router.post('/profile-image', protect, upload.single('image'), uploadProfileImage);
router.patch('/wishlist', protect, updateWishlist);
router.get('/wishlist', protect, getWishlist);

module.exports = router;

