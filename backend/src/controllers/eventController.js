// backend/src/controllers/eventController.js

const pool = require('../config/database');
const { sendSuccess, sendError } = require('../utils/responseHandler');

// 1. Get All Events (Public) - Tambah e.end_time
const getAllEvents = async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [events] = await connection.query(
      `SELECT e.id, e.title, e.description, e.location, e.date, e.time, e.end_time, 
              e.category, e.image_url, e.capacity, u.name as organizer_name,
              (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id AND status = 'registered') as participants_count
       FROM events e
       JOIN users u ON e.organizer_id = u.id
       ORDER BY e.date DESC`
    );
    connection.release();
    sendSuccess(res, events);
  } catch (error) {
    console.error('Get events error:', error);
    sendError(res, 'Failed to get events', [error.message], 500);
  }
};

// 2. Get Event Detail - Tambah e.end_time
const getEventDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [events] = await connection.query(
      `SELECT e.id, e.title, e.description, e.location, e.date, e.time, e.end_time,
              e.category, e.image_url, e.capacity, e.organizer_id, u.name as organizer_name,
              (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id AND status = 'registered') as participants_count,
              e.created_at
       FROM events e
       JOIN users u ON e.organizer_id = u.id
       WHERE e.id = ?`,
      [id]
    );
    connection.release();

    if (events.length === 0) {
      return sendError(res, 'Event not found', [], 404);
    }
    sendSuccess(res, events[0]);
  } catch (error) {
    console.error('Get event detail error:', error);
    sendError(res, 'Failed to get event detail', [error.message], 500);
  }
};

// 3. Create Event - Simpan endTime
const createEvent = async (req, res) => {
  try {
    const userId = req.userId;
    // Tambah endTime di destructuring
    const { title, description, location, date, time, endTime, category, capacity, imageUrl } = req.body;

    const connection = await pool.getConnection();

    const [result] = await connection.query(
      `INSERT INTO events (title, description, location, date, time, end_time, category, 
                          capacity, image_url, organizer_id, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      // Masukkan endTime ke values (gunakan null jika tidak ada)
      [title, description, location, date, time, endTime || null, category, capacity, imageUrl || null, userId]
    );

    connection.release();

    sendSuccess(res, {
      eventId: result.insertId,
      title, description, location, date, time, endTime, category, capacity,
    }, 'Event created successfully', 201);
  } catch (error) {
    console.error('Create event error:', error);
    sendError(res, 'Failed to create event', [error.message], 500);
  }
};

// 4. Update Event - Update end_time
const updateEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const userRole = req.userRole;
    const { id } = req.params;
    const { title, description, location, date, time, endTime, category, capacity, imageUrl } = req.body;

    const connection = await pool.getConnection();

    const [events] = await connection.query('SELECT organizer_id FROM events WHERE id = ?', [id]);

    if (events.length === 0) {
      connection.release();
      return sendError(res, 'Event not found', [], 404);
    }

    if (userRole !== 'admin' && events[0].organizer_id !== userId) {
      connection.release();
      return sendError(res, 'You are not authorized to update this event', [], 403);
    }

    // Tambahkan end_time = ? di query update
    await connection.query(
      `UPDATE events SET title = ?, description = ?, location = ?, date = ?, 
                        time = ?, end_time = ?, category = ?, capacity = ?, image_url = ?, updated_at = NOW()
       WHERE id = ?`,
      [title, description, location, date, time, endTime || null, category, capacity, imageUrl || null, id]
    );

    connection.release();
    sendSuccess(res, { eventId: id }, 'Event updated successfully');
  } catch (error) {
    console.error('Update event error:', error);
    sendError(res, 'Failed to update event', [error.message], 500);
  }
};

// 5. Delete Event (Tidak berubah)
const deleteEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const userRole = req.userRole;
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [events] = await connection.query('SELECT organizer_id FROM events WHERE id = ?', [id]);

    if (events.length === 0) {
      connection.release();
      return sendError(res, 'Event not found', [], 404);
    }
    if (userRole !== 'admin' && events[0].organizer_id !== userId) {
      connection.release();
      return sendError(res, 'You are not authorized to delete this event', [], 403);
    }

    await connection.query('DELETE FROM event_participants WHERE event_id = ?', [id]);
    await connection.query('DELETE FROM events WHERE id = ?', [id]);
    connection.release();
    sendSuccess(res, { eventId: id }, 'Event deleted successfully');
  } catch (error) {
    console.error('Delete event error:', error);
    sendError(res, 'Failed to delete event', [error.message], 500);
  }
};

// 6. Join Event (Tidak berubah)
const joinEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [events] = await connection.query('SELECT capacity FROM events WHERE id = ?', [id]);
    if (events.length === 0) {
      connection.release();
      return sendError(res, 'Event not found', [], 404);
    }
    const [existing] = await connection.query('SELECT id FROM event_participants WHERE event_id = ? AND user_id = ?', [id, userId]);
    if (existing.length > 0) {
      connection.release();
      return sendError(res, 'You have already joined this event', [], 400);
    }
    const [count] = await connection.query('SELECT COUNT(*) as count FROM event_participants WHERE event_id = ? AND status = "registered"', [id]);
    if (count[0].count >= events[0].capacity) {
      connection.release();
      return sendError(res, 'Event is full', [], 400);
    }
    await connection.query('INSERT INTO event_participants (event_id, user_id, status, joined_at) VALUES (?, ?, "registered", NOW())', [id, userId]);
    connection.release();
    sendSuccess(res, { eventId: id }, 'Successfully joined event', 201);
  } catch (error) {
    console.error('Join event error:', error);
    sendError(res, 'Failed to join event', [error.message], 500);
  }
};

// 7. Leave Event (Tidak berubah)
const leaveEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [result] = await connection.query('DELETE FROM event_participants WHERE event_id = ? AND user_id = ?', [id, userId]);
    connection.release();
    if (result.affectedRows === 0) {
      return sendError(res, 'You are not a participant in this event', [], 404);
    }
    sendSuccess(res, { eventId: id }, 'Successfully left event');
  } catch (error) {
    console.error('Leave event error:', error);
    sendError(res, 'Failed to leave event', [error.message], 500);
  }
};

// 8. Get User Events (Dashboard Organizer) - Tambah e.end_time
const getUserEvents = async (req, res) => {
  try {
    const userId = req.userId;
    const connection = await pool.getConnection();
    const [events] = await connection.query(
      `SELECT e.id, e.title, e.description, e.location, e.date, e.time, e.end_time,
              e.category, e.image_url, e.capacity,
              (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id AND status = 'registered') as participants_count
       FROM events e
       WHERE e.organizer_id = ?
       ORDER BY e.date DESC`,
      [userId]
    );
    connection.release();
    sendSuccess(res, events);
  } catch (error) {
    console.error('Get user events error:', error);
    sendError(res, 'Failed to get user events', [error.message], 500);
  }
};

// 8b. Get User Participating Events (Dashboard Peserta / Riwayat)
const getUserParticipatingEvents = async (req, res) => {
  try {
    const userId = req.userId;
    const connection = await pool.getConnection();
    const [events] = await connection.query(
      `SELECT e.id, e.title, e.description, e.location, e.date, e.time, e.end_time,
              e.category, e.image_url, e.capacity,
              u.name as organizer_name,
              ep.status, ep.joined_at,
              (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id AND status = 'registered') as participants_count
       FROM event_participants ep
       JOIN events e ON e.id = ep.event_id
       JOIN users u ON e.organizer_id = u.id
       WHERE ep.user_id = ?
         AND ep.status IN ('registered', 'rejected')
         AND STR_TO_DATE(
               CONCAT(e.date, ' ', COALESCE(e.end_time, e.time)),
               '%Y-%m-%d %H:%i:%s'
             ) <= NOW()
       ORDER BY e.date DESC, ep.joined_at DESC`,
      [userId]
    );
    connection.release();
    sendSuccess(res, events);
  } catch (error) {
    console.error('Get participating events error:', error);
    sendError(res, 'Failed to get participating events', [error.message], 500);
  }
};

// 9. Invite Participants (Tidak berubah)
const inviteParticipants = async (req, res) => {
  try {
    const { id } = req.params;
    const { userIds } = req.body;
    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      return sendError(res, 'Pilih minimal satu peserta', [], 400);
    }
    const connection = await pool.getConnection();
    try {
      const promises = userIds.map(async (userId) => {
        const [existing] = await connection.query('SELECT id FROM event_participants WHERE event_id = ? AND user_id = ?', [id, userId]);
        if (existing.length === 0) {
          await connection.query('INSERT INTO event_participants (event_id, user_id, status, joined_at) VALUES (?, ?, "invited", NOW())', [id, userId]);
        }
      });
      await Promise.all(promises);
      sendSuccess(res, null, 'Undangan berhasil dikirim');
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Invite participants error:', error);
    sendError(res, 'Gagal mengundang peserta', [error.message], 500);
  }
};

// 10. Get User Invitations (Dashboard Peserta) - Tambah e.end_time (Opsional, jika mau ditampilkan di list)
const getUserInvitations = async (req, res) => {
  try {
    const userId = req.userId;
    const connection = await pool.getConnection();
    const [events] = await connection.query(
      `SELECT e.id, e.title, e.description, e.location, e.date, e.time, e.end_time,
              e.image_url, ep.status, u.name as organizer_name
       FROM events e
       JOIN event_participants ep ON e.id = ep.event_id
       JOIN users u ON e.organizer_id = u.id
       WHERE ep.user_id = ? AND (ep.status = 'invited' OR ep.status = 'registered')
       ORDER BY e.date ASC`,
      [userId]
    );
    connection.release();
    sendSuccess(res, events);
  } catch (error) {
    console.error('Get invitations error:', error);
    sendError(res, 'Gagal mengambil undangan', [error.message], 500);
  }
};

// 11. Respond Invitation (Tidak berubah)
const respondToInvitation = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;
    const { action } = req.body;
    if (!['accept', 'reject'].includes(action)) return sendError(res, 'Action harus accept atau reject', [], 400);
    const connection = await pool.getConnection();
    if (action === 'accept') {
      await connection.query('UPDATE event_participants SET status = "registered" WHERE event_id = ? AND user_id = ?', [id, userId]);
      sendSuccess(res, null, 'Anda berhasil bergabung ke event');
    } else {
      await connection.query('DELETE FROM event_participants WHERE event_id = ? AND user_id = ?', [id, userId]);
      sendSuccess(res, null, 'Anda menolak undangan event');
    }
    connection.release();
  } catch (error) {
    console.error('Respond invitation error:', error);
    sendError(res, 'Gagal memproses respon', [error.message], 500);
  }
};

// 12. Get Event Participants (Tidak berubah)
const getEventParticipants = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [participants] = await connection.query(
      `SELECT u.id, u.name, u.email, ep.status, ep.joined_at FROM event_participants ep JOIN users u ON ep.user_id = u.id WHERE ep.event_id = ? ORDER BY ep.joined_at DESC`,
      [id]
    );
    connection.release();
    sendSuccess(res, participants || []);
  } catch (error) {
    console.error('Get event participants error:', error);
    sendError(res, 'Gagal mengambil data peserta', [error.message], 500);
  }
};

// 13. Update Participant Status (Tidak berubah)
const updateParticipantStatus = async (req, res) => {
  try {
    const { id, userId } = req.params;
    const { status } = req.body;
    const connection = await pool.getConnection();
    await connection.query('UPDATE event_participants SET status = ? WHERE event_id = ? AND user_id = ?', [status, id, userId]);
    connection.release();
    sendSuccess(res, null, 'Status peserta berhasil diperbarui');
  } catch (error) {
    console.error('Update participant error:', error);
    sendError(res, 'Gagal memperbarui status', [error.message], 500);
  }
};

// 14. Remove Participant (Tidak berubah)
const removeParticipant = async (req, res) => {
  try {
    const { id, userId } = req.params;
    const connection = await pool.getConnection();
    await connection.query('DELETE FROM event_participants WHERE event_id = ? AND user_id = ?', [id, userId]);
    connection.release();
    sendSuccess(res, null, 'Peserta berhasil dihapus dari event');
  } catch (error) {
    console.error('Remove participant error:', error);
    sendError(res, 'Gagal menghapus peserta', [error.message], 500);
  }
};

module.exports = {
  getAllEvents, getEventDetail, createEvent, updateEvent, deleteEvent, joinEvent, leaveEvent,
  getUserEvents, getUserParticipatingEvents, inviteParticipants, getUserInvitations, respondToInvitation,
  getEventParticipants, updateParticipantStatus, removeParticipant
};