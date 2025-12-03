const express = require('express');
const { body } = require('express-validator');
const { register, login, forgotPassword } = require('../controllers/authController');

const router = express.Router();

// Register
router.post(
  '/register',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('phone').optional().isMobilePhone().withMessage('Valid phone number is required'),
  ],
  register
);

// Login
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  login
);

// Forgot Password
router.post(
  '/forgot-password',
  [body('email').isEmail().withMessage('Valid email is required')],
  forgotPassword
);

module.exports = router;
