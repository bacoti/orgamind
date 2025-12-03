const express = require('express');
const {
  getAllEvents,
  getEventDetail,
  createEvent,
  updateEvent,
  deleteEvent,
  joinEvent,
  leaveEvent,
  getUserEvents,
} = require('../controllers/eventController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

// Public routes
router.get('/', getAllEvents);
router.get('/:id', getEventDetail);

// Protected routes
router.post('/', authenticate, createEvent);
router.put('/:id', authenticate, updateEvent);
router.delete('/:id', authenticate, deleteEvent);
router.post('/:id/join', authenticate, joinEvent);
router.delete('/:id/leave', authenticate, leaveEvent);
router.get('/user/events', authenticate, getUserEvents);

module.exports = router;
