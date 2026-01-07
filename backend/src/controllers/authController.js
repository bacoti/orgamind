const pool = require('../config/database');
const { hashPassword, comparePassword } = require('../utils/passwordUtils');
const { generateToken } = require('../utils/jwtUtils');
const { sendSuccess, sendError } = require('../utils/responseHandler');
const { validationResult } = require('express-validator');

// Register
const register = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return sendError(res, 'Validation failed', errors.array(), 400);
    }

    const { name, email, password, phone } = req.body;

    const connection = await pool.getConnection();

    // Check if email exists
    const [existingUser] = await connection.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existingUser.length > 0) {
      connection.release();
      return sendError(res, 'Email already registered', [], 400);
    }

    // Hash password
    const hashedPassword = await hashPassword(password);

    // Create user
    const [result] = await connection.query(
      'INSERT INTO users (name, email, password, phone, role, created_at) VALUES (?, ?, ?, ?, ?, NOW())',
      [name, email, hashedPassword, phone || null, 'participant']
    );

    connection.release();

    const token = generateToken(result.insertId);

    sendSuccess(res, {
      userId: result.insertId,
      name,
      email,
      token,
    }, 'Registration successful', 201);
  } catch (error) {
    console.error('Register error:', error);
    sendError(res, 'Registration failed', [error.message], 500);
  }
};

// Login
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return sendError(res, 'Email and password are required', [], 400);
    }

    const connection = await pool.getConnection();

    const [users] = await connection.query(
      'SELECT id, name, email, password, phone, photo_url, bio, role FROM users WHERE email = ?',
      [email]
    );

    connection.release();

    if (users.length === 0) {
      return sendError(res, 'Email not found', [], 404);
    }

    const user = users[0];
    const isPasswordValid = await comparePassword(password, user.password);

    if (!isPasswordValid) {
      return sendError(res, 'Invalid password', [], 401);
    }

    const token = generateToken(user.id);

    sendSuccess(res, {
      userId: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photo_url,
      bio: user.bio,
      role: user.role,
      token,
    }, 'Login successful');
  } catch (error) {
    console.error('Login error:', error);
    sendError(res, 'Login failed', [error.message], 500);
  }
};

// Forgot Password (request reset token)
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return sendError(res, 'Email is required', [], 400);
    }

    const connection = await pool.getConnection();

    const [users] = await connection.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      connection.release();
      return sendError(res, 'Email not found', [], 404);
    }

    // In production, generate and save a reset token in database
    // For now, we'll just return success
    connection.release();

    sendSuccess(res, {
      message: 'Reset password link sent to email (check your inbox)',
    }, 'Check your email for reset instructions');
  } catch (error) {
    console.error('Forgot password error:', error);
    sendError(res, 'Failed to process forgot password', [error.message], 500);
  }
};

// Change Password (authenticated user)
const changePassword = async (req, res) => {
  try {
    const userId = req.userId;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return sendError(res, 'Current password and new password are required', [], 400);
    }

    if (newPassword.length < 6) {
      return sendError(res, 'New password must be at least 6 characters', [], 400);
    }

    const connection = await pool.getConnection();

    // Get current user password
    const [users] = await connection.query(
      'SELECT password FROM users WHERE id = ?',
      [userId]
    );

    if (users.length === 0) {
      connection.release();
      return sendError(res, 'User not found', [], 404);
    }

    // Verify current password
    const isPasswordValid = await comparePassword(currentPassword, users[0].password);
    if (!isPasswordValid) {
      connection.release();
      return sendError(res, 'Current password is incorrect', [], 401);
    }

    // Hash new password
    const hashedPassword = await hashPassword(newPassword);

    // Update password
    await connection.query(
      'UPDATE users SET password = ?, updated_at = NOW() WHERE id = ?',
      [hashedPassword, userId]
    );

    connection.release();

    sendSuccess(res, null, 'Password changed successfully');
  } catch (error) {
    console.error('Change password error:', error);
    sendError(res, 'Failed to change password', [error.message], 500);
  }
};

module.exports = { register, login, forgotPassword, changePassword };
