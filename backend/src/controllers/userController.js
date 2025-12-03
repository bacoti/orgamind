const pool = require('../config/database');
const { hashPassword } = require('../utils/passwordUtils');
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

// Update user role (admin only)
const updateUserRole = async (req, res) => {
  try {
    const { userId, role } = req.body;
    
    if (!userId || !role) {
      return sendError(res, 'Missing required fields', [], 400);
    }
    
    if (!['admin', 'participant'].includes(role)) {
      return sendError(res, 'Invalid role', [], 400);
    }

    const connection = await pool.getConnection();

    const [result] = await connection.query(
      'UPDATE users SET role = ? WHERE id = ?',
      [role, userId]
    );

    connection.release();

    if (result.affectedRows === 0) {
      return sendError(res, 'User not found', [], 404);
    }

    sendSuccess(res, { userId, role }, 'Role updated successfully', 200);
  } catch (error) {
    console.error('Update role error:', error);
    sendError(res, 'Failed to update role', [error.message], 500);
  }
};

// Get All Users (Admin only)
const getAllUsers = async (req, res) => {
  try {
    const { role, search } = req.query;

    const connection = await pool.getConnection();

    let query = 'SELECT id, name, email, phone, photo_url, bio, role, created_at FROM users WHERE 1=1';
    const params = [];

    // Filter by role
    if (role && ['admin', 'participant'].includes(role)) {
      query += ' AND role = ?';
      params.push(role);
    }

    // Search by name or email
    if (search) {
      query += ' AND (name LIKE ? OR email LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    query += ' ORDER BY created_at DESC';

    const [users] = await connection.query(query, params);
    connection.release();

    const formattedUsers = users.map(user => ({
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photo_url,
      bio: user.bio,
      role: user.role,
      createdAt: user.created_at,
    }));

    sendSuccess(res, formattedUsers, 'Users retrieved successfully');
  } catch (error) {
    console.error('Get all users error:', error);
    sendError(res, 'Failed to get users', [error.message], 500);
  }
};

// Get User by ID (Admin only)
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const connection = await pool.getConnection();

    const [users] = await connection.query(
      'SELECT id, name, email, phone, photo_url, bio, role, created_at FROM users WHERE id = ?',
      [id]
    );

    connection.release();

    if (users.length === 0) {
      return sendError(res, 'User not found', [], 404);
    }

    const user = users[0];
    sendSuccess(res, {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photo_url,
      bio: user.bio,
      role: user.role,
      createdAt: user.created_at,
    });
  } catch (error) {
    console.error('Get user by ID error:', error);
    sendError(res, 'Failed to get user', [error.message], 500);
  }
};

// Update User (Admin only)
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, phone, bio, role } = req.body;

    if (!name || !email) {
      return sendError(res, 'Name and email are required', [], 400);
    }

    if (role && !['admin', 'participant'].includes(role)) {
      return sendError(res, 'Invalid role', [], 400);
    }

    const connection = await pool.getConnection();

    // Check if email already exists for another user
    const [existingUser] = await connection.query(
      'SELECT id FROM users WHERE email = ? AND id != ?',
      [email, id]
    );

    if (existingUser.length > 0) {
      connection.release();
      return sendError(res, 'Email already exists', [], 400);
    }

    const [result] = await connection.query(
      'UPDATE users SET name = ?, email = ?, phone = ?, bio = ?, role = ?, updated_at = NOW() WHERE id = ?',
      [name, email, phone || null, bio || null, role || 'participant', id]
    );

    if (result.affectedRows === 0) {
      connection.release();
      return sendError(res, 'User not found', [], 404);
    }

    const [users] = await connection.query(
      'SELECT id, name, email, phone, photo_url, bio, role FROM users WHERE id = ?',
      [id]
    );

    connection.release();

    const user = users[0];
    sendSuccess(res, {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photo_url,
      bio: user.bio,
      role: user.role,
    }, 'User updated successfully');
  } catch (error) {
    console.error('Update user error:', error);
    sendError(res, 'Failed to update user', [error.message], 500);
  }
};

// Delete User (Admin only)
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    const connection = await pool.getConnection();

    // Check if user exists
    const [users] = await connection.query('SELECT id FROM users WHERE id = ?', [id]);
    
    if (users.length === 0) {
      connection.release();
      return sendError(res, 'User not found', [], 404);
    }

    // Delete user (cascade will delete related records)
    await connection.query('DELETE FROM users WHERE id = ?', [id]);

    connection.release();

    sendSuccess(res, { id }, 'User deleted successfully');
  } catch (error) {
    console.error('Delete user error:', error);
    sendError(res, 'Failed to delete user', [error.message], 500);
  }
};

// Create User (Admin only)
const createUser = async (req, res) => {
  try {
    const { name, email, password, phone, role } = req.body;

    if (!name || !email || !password) {
      return sendError(res, 'Name, email, and password are required', [], 400);
    }

    if (role && !['admin', 'participant'].includes(role)) {
      return sendError(res, 'Invalid role', [], 400);
    }

    const connection = await pool.getConnection();

    // Check if email already exists
    const [existingUser] = await connection.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existingUser.length > 0) {
      connection.release();
      return sendError(res, 'Email already exists', [], 400);
    }

    // Hash password
    const hashedPassword = await hashPassword(password);

    // Create user
    const [result] = await connection.query(
      'INSERT INTO users (name, email, password, phone, role, created_at) VALUES (?, ?, ?, ?, ?, NOW())',
      [name, email, hashedPassword, phone || null, role || 'participant']
    );

    const [users] = await connection.query(
      'SELECT id, name, email, phone, photo_url, bio, role, created_at FROM users WHERE id = ?',
      [result.insertId]
    );

    connection.release();

    const user = users[0];
    sendSuccess(res, {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      photoUrl: user.photo_url,
      bio: user.bio,
      role: user.role,
      createdAt: user.created_at,
    }, 'User created successfully', 201);
  } catch (error) {
    console.error('Create user error:', error);
    sendError(res, 'Failed to create user', [error.message], 500);
  }
};

module.exports = { 
  getProfile, 
  updateProfile, 
  updateUserRole,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
  createUser,
};