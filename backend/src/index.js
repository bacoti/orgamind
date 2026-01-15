const express = require('express');
const cors = require('cors');
require('dotenv').config();

const createAdmin = require('../createAdmin'); 

// Import routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const eventRoutes = require('./routes/eventRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/attendance', attendanceRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Backend is running' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// Start server
createAdmin().then(() => {
  app.listen(PORT, () => {
    console.log(`\n🚀 Server is running on http://localhost:${PORT}`);
    console.log(`📝 API Documentation:`);
    console.log(`   - Health Check: GET /api/health`);
    console.log(`   - Auth: POST /api/auth/register, /api/auth/login, /api/auth/forgot-password`);
    console.log(`   - Users: GET/PUT /api/users/profile`);
    console.log(`   - Events: GET /api/events, POST /api/events, etc.`);
    console.log(`   - Attendance: GET /api/attendance/qr-token/:eventId, POST /api/attendance/scan, POST /api/attendance/manual/:eventId`);
    console.log(`\n`);
  });
});

module.exports = app;
