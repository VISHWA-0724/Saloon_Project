const express = require('express');
const { adminOnly, protect } = require('../middleware/auth.middleware');
const { createService, getAllServices, getServiceById } = require('../controllers/service.controller');

const router = express.Router();

router.get('/', getAllServices);
router.post('/', protect, adminOnly, createService);
router.get('/:id', getServiceById);

module.exports = router;

