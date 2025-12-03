const pool = require('../config/database');
const { sendSuccess, sendError } = require('../utils/responseHandler');

// Get User Profile
const getProfile = async (req, res) => {
  try {
    const userId = req.userId;

    const connection = await pool.getConnection();

    const [users] = await connection.query(
      'SELECT id, name, email, phone, photo_url, bio, role, created_at FROM users WHERE id = ?',
      [userId]
    );

    connection.release();

    if (users.length === 0) {
      return sendError(res, 'User not found', [], 404);
    }

    const user = users[0];
    sendSuccess(res, {
      userId: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photo_url,
      bio: user.bio,
      role: user.role,
      createdAt: user.created_at,
    });
  } catch (error) {
    console.error('Get profile error:', error);
    sendError(res, 'Failed to get profile', [error.message], 500);
  }
};

// Update User Profile
const updateProfile = async (req, res) => {
  try {
    const userId = req.userId;
    const { name, phone, bio } = req.body;

    const connection = await pool.getConnection();

    await connection.query(
      'UPDATE users SET name = ?, phone = ?, bio = ?, updated_at = NOW() WHERE id = ?',
      [name, phone || null, bio || null, userId]
    );

    const [users] = await connection.query(
      'SELECT id, name, email, phone, photo_url, bio, role FROM users WHERE id = ?',
      [userId]
    );

    connection.release();

    const user = users[0];
    sendSuccess(res, {
      userId: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photo_url,
      bio: user.bio,
      role: user.role,
    }, 'Profile updated successfully');
  } catch (error) {
    console.error('Update profile error:', error);
    sendError(res, 'Failed to update profile', [error.message], 500);
  }
};

module.exports = { getProfile, updateProfile };
