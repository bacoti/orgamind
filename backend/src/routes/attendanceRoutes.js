const express = require('express');
const { authenticate } = require('../middleware/authMiddleware');
const {
  getEventQrCode,
  participantScanCheckIn,
  getQrTokenForEvent,
  scanQrCheckIn,
  manualCheckIn,
  listAttendanceByEvent,
} = require('../controllers/attendanceController');

const router = express.Router();

router.use(authenticate);

// ======== NEW FLOW: Admin tampilkan QR, Peserta scan ========
// Admin: Generate QR Code untuk event
router.get('/event-qr/:eventId', getEventQrCode);

// Peserta: Scan QR event untuk check-in
router.post('/participant-scan', participantScanCheckIn);

// ======== LEGACY FLOW (tetap tersedia) ========
// Peserta: Generate QR token personal
router.get('/qr-token/:eventId', getQrTokenForEvent);

// Admin: Scan QR peserta
router.post('/scan', scanQrCheckIn);

// Admin: Manual check-in
router.post('/manual/:eventId', manualCheckIn);

// List attendance by event
router.get('/event/:eventId', listAttendanceByEvent);

module.exports = router;
