const pool = require('../config/database');
const { sendSuccess, sendError } = require('../utils/responseHandler');

// Get All Events
const getAllEvents = async (req, res) => {
  try {
    const connection = await pool.getConnection();

    const [events] = await connection.query(
      `SELECT e.id, e.title, e.description, e.location, e.date, e.time, 
              e.category, e.image_url, e.capacity, u.name as organizer_name,
              (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id) as participants_count
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

// Get Event Detail
const getEventDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    const [events] = await connection.query(
      `SELECT e.id, e.title, e.description, e.location, e.date, e.time,
              e.category, e.image_url, e.capacity, e.organizer_id, u.name as organizer_name,
              (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id) as participants_count,
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

// Create Event
const createEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const { title, description, location, date, time, category, capacity, imageUrl } = req.body;

    const connection = await pool.getConnection();

    const [result] = await connection.query(
      `INSERT INTO events (title, description, location, date, time, category, 
                          capacity, image_url, organizer_id, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [title, description, location, date, time, category, capacity, imageUrl || null, userId]
    );

    connection.release();

    sendSuccess(res, {
      eventId: result.insertId,
      title,
      description,
      location,
      date,
      time,
      category,
      capacity,
    }, 'Event created successfully', 201);
  } catch (error) {
    console.error('Create event error:', error);
    sendError(res, 'Failed to create event', [error.message], 500);
  }
};

// Update Event
const updateEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const userRole = req.userRole;
    const { id } = req.params;
    const { title, description, location, date, time, category, capacity, imageUrl } = req.body;

    const connection = await pool.getConnection();

    // Check if event exists
    const [events] = await connection.query(
      'SELECT organizer_id FROM events WHERE id = ?',
      [id]
    );

    if (events.length === 0) {
      connection.release();
      return sendError(res, 'Event not found', [], 404);
    }

    // Admin can edit any event, organizer can only edit their own
    if (userRole !== 'admin' && events[0].organizer_id !== userId) {
      connection.release();
      return sendError(res, 'You are not authorized to update this event', [], 403);
    }

    await connection.query(
      `UPDATE events SET title = ?, description = ?, location = ?, date = ?, 
                        time = ?, category = ?, capacity = ?, image_url = ?, updated_at = NOW()
       WHERE id = ?`,
      [title, description, location, date, time, category, capacity, imageUrl || null, id]
    );

    connection.release();

    sendSuccess(res, { eventId: id }, 'Event updated successfully');
  } catch (error) {
    console.error('Update event error:', error);
    sendError(res, 'Failed to update event', [error.message], 500);
  }
};

// Delete Event
const deleteEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const userRole = req.userRole;
    const { id } = req.params;

    const connection = await pool.getConnection();

    const [events] = await connection.query(
      'SELECT organizer_id FROM events WHERE id = ?',
      [id]
    );

    if (events.length === 0) {
      connection.release();
      return sendError(res, 'Event not found', [], 404);
    }

    // Admin can delete any event, organizer can only delete their own
    if (userRole !== 'admin' && events[0].organizer_id !== userId) {
      connection.release();
      return sendError(res, 'You are not authorized to delete this event', [], 403);
    }

    // Delete participants first
    await connection.query('DELETE FROM event_participants WHERE event_id = ?', [id]);

    // Delete event
    await connection.query('DELETE FROM events WHERE id = ?', [id]);

    connection.release();

    sendSuccess(res, { eventId: id }, 'Event deleted successfully');
  } catch (error) {
    console.error('Delete event error:', error);
    sendError(res, 'Failed to delete event', [error.message], 500);
  }
};

// Join Event
const joinEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const connection = await pool.getConnection();

    // Check if event exists
    const [events] = await connection.query(
      'SELECT capacity FROM events WHERE id = ?',
      [id]
    );

    if (events.length === 0) {
      connection.release();
      return sendError(res, 'Event not found', [], 404);
    }

    // Check if already joined
    const [existing] = await connection.query(
      'SELECT id FROM event_participants WHERE event_id = ? AND user_id = ?',
      [id, userId]
    );

    if (existing.length > 0) {
      connection.release();
      return sendError(res, 'You have already joined this event', [], 400);
    }

    // Check capacity
    const [count] = await connection.query(
      'SELECT COUNT(*) as count FROM event_participants WHERE event_id = ?',
      [id]
    );

    if (count[0].count >= events[0].capacity) {
      connection.release();
      return sendError(res, 'Event is full', [], 400);
    }

    // Join event
    await connection.query(
      'INSERT INTO event_participants (event_id, user_id, joined_at) VALUES (?, ?, NOW())',
      [id, userId]
    );

    connection.release();

    sendSuccess(res, { eventId: id }, 'Successfully joined event', 201);
  } catch (error) {
    console.error('Join event error:', error);
    sendError(res, 'Failed to join event', [error.message], 500);
  }
};

// Leave Event
const leaveEvent = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const connection = await pool.getConnection();

    const [result] = await connection.query(
      'DELETE FROM event_participants WHERE event_id = ? AND user_id = ?',
      [id, userId]
    );

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

// Get User Events
const getUserEvents = async (req, res) => {
  try {
    const userId = req.userId;

    const connection = await pool.getConnection();

    const [events] = await connection.query(
      `SELECT e.id, e.title, e.description, e.location, e.date, e.time,
              e.category, e.image_url, e.capacity,
              (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id) as participants_count
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

module.exports = {
  getAllEvents,
  getEventDetail,
  createEvent,
  updateEvent,
  deleteEvent,
  joinEvent,
  leaveEvent,
  getUserEvents,
};
