const express = require('express');
const { 
  getProfile, 
  updateProfile, 
  updateUserRole,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
  createUser,
} = require('../controllers/userController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

// All user routes require authentication
router.use(authenticate);

// Get Profile (current user)
router.get('/profile', getProfile);

// Update Profile (current user)
router.put('/profile', updateProfile);

// Admin Only Routes
// Get All Users
router.get('/', getAllUsers);

// Create New User
router.post('/', createUser);

// Get User by ID
router.get('/:id', getUserById);

// Update User
router.put('/:id', updateUser);

// Delete User
router.delete('/:id', deleteUser);

// Update User Role (legacy - kept for compatibility)
router.put('/role', updateUserRole);

module.exports = router;
