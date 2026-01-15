const pool = require('../config/database');
const { sendSuccess, sendError } = require('../utils/responseHandler');
const { signPayload, verifyToken } = require('../utils/qrUtils');

// ============ ADMIN: Generate QR Code untuk Event ============
// QR Code ini akan ditampilkan oleh admin, dan peserta yang scan
const getEventQrCode = async (req, res) => {
  try {
    const { eventId } = req.params;
    const userRole = req.userRole;

    // Hanya admin yang boleh generate QR event
    if (userRole !== 'admin') {
      return sendError(res, 'Hanya admin yang dapat generate QR event', [], 403);
    }

    const connection = await pool.getConnection();

    // Cek apakah event ada
    const [events] = await connection.query(
      'SELECT id, title FROM events WHERE id = ?',
      [eventId]
    );

    if (events.length === 0) {
      connection.release();
      return sendError(res, 'Event tidak ditemukan', [], 404);
    }

    connection.release();

    // Generate token yang berisi eventId saja (tanpa userId)
    // Peserta akan menambahkan userId mereka saat scan
    const token = signPayload({
      eventId: Number(eventId),
      type: 'event_checkin',
      generatedAt: Date.now(),
    });

    return sendSuccess(res, { 
      token,
      eventId: Number(eventId),
      eventTitle: events[0].title 
    }, 'QR Code event berhasil dibuat');
  } catch (error) {
    console.error('getEventQrCode error:', error);
    return sendError(res, 'Gagal membuat QR event', [error.message], 500);
  }
};

// ============ PESERTA: Scan QR Event untuk Check-in ============
// Peserta scan QR yang ditampilkan admin
const participantScanCheckIn = async (req, res) => {
  try {
    const userId = req.userId; // Dari token auth peserta
    const { token } = req.body;

    if (!token) return sendError(res, 'QR token wajib diisi', [], 400);

    let payload;
    try {
      payload = verifyToken(token);
    } catch (e) {
      return sendError(res, e.message || 'QR Code tidak valid', [], 400);
    }

    // Pastikan ini QR event (bukan QR tipe lain)
    if (payload.type !== 'event_checkin') {
      return sendError(res, 'QR Code tidak valid untuk presensi', [], 400);
    }

    const eventId = payload.eventId;

    const connection = await pool.getConnection();

    // Cek apakah peserta terdaftar di event ini
    const [reg] = await connection.query(
      'SELECT status FROM event_participants WHERE event_id = ? AND user_id = ?',
      [eventId, userId]
    );

    if (reg.length === 0) {
      connection.release();
      return sendError(res, 'Anda tidak terdaftar di event ini', [], 400);
    }

    if (reg[0].status !== 'registered') {
      connection.release();
      return sendError(res, 'Anda belum menerima undangan event ini', [], 400);
    }

    // Cek apakah sudah check-in sebelumnya
    const [existing] = await connection.query(
      'SELECT id FROM event_attendance WHERE event_id = ? AND user_id = ?',
      [eventId, userId]
    );

    if (existing.length > 0) {
      connection.release();
      return sendError(res, 'Anda sudah melakukan presensi sebelumnya', [], 400);
    }

    // Insert attendance
    await connection.query(
      `INSERT INTO event_attendance (event_id, user_id, method, checked_in_by)
       VALUES (?, ?, 'QR', NULL)`,
      [eventId, userId]
    );

    connection.release();
    return sendSuccess(
      res,
      { eventId: Number(eventId), userId: Number(userId) },
      'Presensi berhasil! Anda telah hadir di event ini.'
    );
  } catch (error) {
    console.error('participantScanCheckIn error:', error);
    return sendError(res, 'Gagal melakukan presensi', [error.message], 500);
  }
};

// ============ LEGACY: QR Token untuk Peserta (tetap dipertahankan) ============
const getQrTokenForEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const { eventId } = req.params;

    const connection = await pool.getConnection();

    const [rows] = await connection.query(
      'SELECT id, status FROM event_participants WHERE event_id = ? AND user_id = ?',
      [eventId, userId]
    );

    if (rows.length === 0) {
      connection.release();
      return sendError(res, 'Anda tidak terdaftar di event ini', [], 403);
    }

    if (rows[0].status !== 'registered') {
      connection.release();
      return sendError(res, 'Undangan belum diterima / belum terdaftar', [], 400);
    }

    const token = signPayload({
      eventId: Number(eventId),
      userId: Number(userId),
    });

    connection.release();
    return sendSuccess(res, { token }, 'QR token generated');
  } catch (error) {
    console.error('getQrTokenForEvent error:', error);
    return sendError(res, 'Gagal membuat QR token', [error.message], 500);
  }
};

const scanQrCheckIn = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return sendError(res, 'token wajib diisi', [], 400);

    let payload;
    try {
      payload = verifyToken(token);
    } catch (e) {
      return sendError(res, e.message || 'QR invalid', [], 400);
    }

    const connection = await pool.getConnection();

    const [reg] = await connection.query(
      'SELECT status FROM event_participants WHERE event_id = ? AND user_id = ?',
      [payload.eventId, payload.userId]
    );

    if (reg.length === 0 || reg[0].status !== 'registered') {
      connection.release();
      return sendError(
        res,
        'Peserta tidak terdaftar/registered untuk event ini',
        [],
        400
      );
    }

    await connection.query(
      `INSERT INTO event_attendance (event_id, user_id, method, checked_in_by)
       VALUES (?, ?, 'QR', NULL)
       ON DUPLICATE KEY UPDATE method='QR', checked_in_at=NOW(), checked_in_by=NULL`,
      [payload.eventId, payload.userId]
    );

    connection.release();
    return sendSuccess(
      res,
      { eventId: payload.eventId, userId: payload.userId },
      'Check-in berhasil'
    );
  } catch (error) {
    console.error('scanQrCheckIn error:', error);
    return sendError(res, 'Gagal check-in QR', [error.message], 500);
  }
};

const manualCheckIn = async (req, res) => {
  try {
    const adminId = req.userId;
    const { eventId } = req.params;
    const { userId } = req.body;

    if (!userId) return sendError(res, 'userId wajib diisi', [], 400);

    if (req.userRole !== 'admin') {
      return sendError(
        res,
        'Hanya admin yang boleh manual check-in',
        [],
        403
      );
    }

    const connection = await pool.getConnection();

    const [reg] = await connection.query(
      'SELECT status FROM event_participants WHERE event_id = ? AND user_id = ?',
      [eventId, userId]
    );

    if (reg.length === 0) {
      connection.release();
      return sendError(
        res,
        'User tidak diundang/terdaftar di event ini',
        [],
        400
      );
    }

    if (reg[0].status !== 'registered') {
      connection.release();
      return sendError(
        res,
        'User belum accept (status belum registered)',
        [],
        400
      );
    }

    await connection.query(
      `INSERT INTO event_attendance (event_id, user_id, method, checked_in_by)
       VALUES (?, ?, 'MANUAL', ?)
       ON DUPLICATE KEY UPDATE method='MANUAL', checked_in_at=NOW(), checked_in_by=?`,
      [eventId, userId, adminId, adminId]
    );

    connection.release();
    return sendSuccess(
      res,
      { eventId: Number(eventId), userId: Number(userId) },
      'Manual check-in berhasil'
    );
  } catch (error) {
    console.error('manualCheckIn error:', error);
    return sendError(res, 'Gagal manual check-in', [error.message], 500);
  }
};

const listAttendanceByEvent = async (req, res) => {
  try {
    const { eventId } = req.params;

    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT ea.user_id, u.name, u.email, ea.method, ea.checked_in_at, ea.checked_in_by
       FROM event_attendance ea
       JOIN users u ON u.id = ea.user_id
       WHERE ea.event_id = ?
       ORDER BY ea.checked_in_at DESC`,
      [eventId]
    );
    connection.release();

    return sendSuccess(res, rows, 'Attendance loaded');
  } catch (error) {
    console.error('listAttendanceByEvent error:', error);
    return sendError(res, 'Gagal ambil attendance', [error.message], 500);
  }
};

module.exports = {
  getEventQrCode,         // Admin: Generate QR untuk event
  participantScanCheckIn, // Peserta: Scan QR event untuk check-in
  getQrTokenForEvent,     // Legacy: QR token peserta
  scanQrCheckIn,          // Legacy: Admin scan QR peserta
  manualCheckIn,
  listAttendanceByEvent,
};
