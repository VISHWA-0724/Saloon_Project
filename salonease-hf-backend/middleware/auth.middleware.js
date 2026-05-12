const asyncHandler = require('express-async-handler');

const { getDB } = require('../config/db');
const { verifyToken } = require('../utils/jwt.util');

const protect = asyncHandler(async (req, res, next) => {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.substring(7) : null;
  if (!token) {
    res.status(401);
    throw new Error('Unauthorized');
  }

  try {
    const decoded = verifyToken(token);
    const user = getDB()
      .prepare('SELECT id, email, role FROM users WHERE id = ?')
      .get(decoded.userId);
    if (!user) {
      res.status(401);
      throw new Error('Unauthorized');
    }

    req.userId = user.id;
    req.userEmail = user.email;
    req.userRole = user.role;
    next();
  } catch (_) {
    res.status(401);
    throw new Error('Unauthorized');
  }
});

function adminOnly(req, res, next) {
  if (req.userRole !== 'admin') {
    res.status(403);
    next(new Error('Admin access required'));
    return;
  }
  next();
}

module.exports = { adminOnly, protect };
