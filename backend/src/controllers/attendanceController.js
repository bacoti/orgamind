const pool = require('../config/database');
const { sendSuccess, sendError } = require('../utils/responseHandler');
const { signPayload, verifyToken } = require('../utils/qrUtils');

// Peserta ambil token QR untuk event yang dia sudah "registered"
const getQrTokenForEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const { eventId } = req.params;

    const connection = await pool.getConnection();

    // pastikan peserta terdaftar (registered) di event
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
      // optional anti replay bisa ditambah expiresAt kalau mau
    });

    connection.release();
    return sendSuccess(res, { token }, 'QR token generated');
  } catch (error) {
    console.error('getQrTokenForEvent error:', error);
    return sendError(res, 'Gagal membuat QR token', [error.message], 500);
  }
};

// Scan QR => tandai hadir (dipakai admin/scanner device)
const scanQrCheckIn = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return sendError(res, 'token wajib diisi', [], 400);

    let payload;
    try {
      payload = verifyToken(token); // {eventId, userId}
    } catch (e) {
      return sendError(res, e.message || 'QR invalid', [], 400);
    }

    const connection = await pool.getConnection();

    // pastikan user yang di-QR memang registered di event tsb
    const [reg] = await connection.query(
      'SELECT status FROM event_participants WHERE event_id = ? AND user_id = ?',
      [payload.eventId, payload.userId]
    );

    if (reg.length === 0 || reg[0].status !== 'registered') {
      connection.release();
      return sendError(res, 'Peserta tidak terdaftar/registered untuk event ini', [], 400);
    }

    // UPSERT attendance (kalau sudah hadir -> update)
    await connection.query(
      `INSERT INTO event_attendance (event_id, user_id, method, checked_in_by)
       VALUES (?, ?, 'QR', NULL)
       ON DUPLICATE KEY UPDATE method='QR', checked_in_at=NOW(), checked_in_by=NULL`,
      [payload.eventId, payload.userId]
    );

    connection.release();
    return sendSuccess(res, { eventId: payload.eventId, userId: payload.userId }, 'Check-in berhasil');
  } catch (error) {
    console.error('scanQrCheckIn error:', error);
    return sendError(res, 'Gagal check-in QR', [error.message], 500);
  }
};

// Admin manual hadirkan peserta (kalau peserta kendala scan)
const manualCheckIn = async (req, res) => {
  try {
    const adminId = req.userId;
    const { eventId } = req.params;
    const { userId } = req.body;

    if (!userId) return sendError(res, 'userId wajib diisi', [], 400);

    // role check (minimal admin / organizer)
    if (req.userRole !== 'admin') {
      return sendError(res, 'Hanya admin yang boleh manual check-in', [], 403);
    }

    const connection = await pool.getConnection();

    const [reg] = await connection.query(
      'SELECT status FROM event_participants WHERE event_id = ? AND user_id = ?',
      [eventId, userId]
    );

    if (reg.length === 0) {
      connection.release();
      return sendError(res, 'User tidak diundang/terdaftar di event ini', [], 400);
    }

    if (reg[0].status !== 'registered') {
      connection.release();
      return sendError(res, 'User belum accept (status belum registered)', [], 400);
    }

    await connection.query(
      `INSERT INTO event_attendance (event_id, user_id, method, checked_in_by)
       VALUES (?, ?, 'MANUAL', ?)
       ON DUPLICATE KEY UPDATE method='MANUAL', checked_in_at=NOW(), checked_in_by=?`,
      [eventId, userId, adminId, adminId]
    );

    connection.release();
    return sendSuccess(res, { eventId: Number(eventId), userId: Number(userId) }, 'Manual check-in berhasil');
  } catch (error) {
    console.error('manualCheckIn error:', error);
    return sendError(res, 'Gagal manual check-in', [error.message], 500);
  }
};

// List attendance per event (admin/organizer)
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
  getQrTokenForEvent,
  scanQrCheckIn,
  manualCheckIn,
  listAttendanceByEvent,
};
