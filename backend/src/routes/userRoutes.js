const express = require('express');
const { getProfile, updateProfile } = require('../controllers/userController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

// All user routes require authentication
router.use(authenticate);

// Get Profile
router.get('/profile', getProfile);

// Update Profile
router.put('/profile', updateProfile);

module.exports = router;
