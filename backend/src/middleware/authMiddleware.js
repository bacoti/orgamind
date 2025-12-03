const { verifyToken } = require('../utils/jwtUtils');
const { sendError } = require('../utils/responseHandler');

const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return sendError(res, 'No token provided', [], 401);
  }

  const decoded = verifyToken(token);
  if (!decoded) {
    return sendError(res, 'Invalid or expired token', [], 401);
  }

  req.userId = decoded.userId;
  next();
};

module.exports = { authenticate };
