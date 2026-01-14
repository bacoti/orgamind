// backend/src/routes/eventRoutes.js

const express = require('express');
const { body } = require('express-validator');
const { 
  getAllEvents, 
  getEventDetail, 
  createEvent, 
  updateEvent, 
  deleteEvent,
  joinEvent,
  leaveEvent,
  getUserEvents,
  inviteParticipants,
  getUserInvitations,
  respondToInvitation,
  getEventParticipants,
  updateParticipantStatus, // ADDED
  removeParticipant        // ADDED
} = require('../controllers/eventController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', getAllEvents);
router.get('/:id', getEventDetail);

router.use(authenticate);

router.post(
  '/',
  [
    body('title').notEmpty().withMessage('Title is required'),
    body('date').notEmpty().withMessage('Date is required'),
    body('location').notEmpty().withMessage('Location is required'),
  ],
  createEvent
);

router.get('/user/organizer', getUserEvents);
router.get('/user/invitations', getUserInvitations);
router.get('/:id/participants', getEventParticipants);
router.post('/:id/invite', inviteParticipants);
router.post('/:id/respond', respondToInvitation);

// NEW ROUTES FOR ADMIN PARTICIPANT MANAGEMENT
router.put('/:id/participants/:userId', updateParticipantStatus);
router.delete('/:id/participants/:userId', removeParticipant);

router.put('/:id', updateEvent);
router.delete('/:id', deleteEvent);
router.post('/:id/join', joinEvent);
router.post('/:id/leave', leaveEvent);

module.exports = router;