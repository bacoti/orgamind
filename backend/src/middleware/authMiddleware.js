const { verifyToken } = require('../utils/jwtUtils');
const { sendError } = require('../utils/responseHandler');
const pool = require('../config/database');

const authenticate = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return sendError(res, 'No token provided', [], 401);
  }

  const decoded = verifyToken(token);
  if (!decoded) {
    return sendError(res, 'Invalid or expired token', [], 401);
  }

  req.userId = decoded.userId;
  
  // Get user role from database
  try {
    const connection = await pool.getConnection();
    const [users] = await connection.query(
      'SELECT role FROM users WHERE id = ?',
      [decoded.userId]
    );
    connection.release();
    
    if (users.length > 0) {
      req.userRole = users[0].role;
    }
  } catch (error) {
    console.error('Error fetching user role:', error);
  }
  
  next();
};

module.exports = { authenticate };
