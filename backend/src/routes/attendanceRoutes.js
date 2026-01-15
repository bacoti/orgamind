const express = require('express');
const { authenticate } = require('../middleware/authMiddleware');
const {
  getQrTokenForEvent,
  scanQrCheckIn,
  manualCheckIn,
  listAttendanceByEvent,
} = require('../controllers/attendanceController');

const router = express.Router();


router.use(authenticate);


router.get('/qr-token/:eventId', getQrTokenForEvent);

router.post('/scan', scanQrCheckIn);


router.post('/manual/:eventId', manualCheckIn);

router.get('/event/:eventId', listAttendanceByEvent);

module.exports = router;
