const jwt = require('jsonwebtoken');

function signAccessToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET || 'salonease_dev_secret', { expiresIn: '7d' });
}

function signRefreshToken(payload) {
  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET || 'salonease_dev_secret', {
    expiresIn: '30d',
  });
}

function verifyToken(token) {
  return jwt.verify(token, process.env.JWT_SECRET || 'salonease_dev_secret');
}

function verifyRefreshToken(token) {
  return jwt.verify(token, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET || 'salonease_dev_secret');
}

module.exports = { signAccessToken, signRefreshToken, verifyToken, verifyRefreshToken };

