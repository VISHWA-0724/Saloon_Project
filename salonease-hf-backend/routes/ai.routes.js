const express = require('express');

const { getStyleAdvice } = require('../controllers/ai.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/style-advisor', protect, getStyleAdvice);

module.exports = router;
