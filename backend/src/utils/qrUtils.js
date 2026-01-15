const crypto = require('crypto');

const QR_SECRET = process.env.QR_SECRET || 'change-this-secret';

function signPayload(payload) {
  const data = JSON.stringify(payload);
  const sig = crypto.createHmac('sha256', QR_SECRET).update(data).digest('hex');
  // token = base64url({data, sig})
  const token = Buffer.from(JSON.stringify({ data, sig })).toString('base64url');
  return token;
}

function verifyToken(token) {
  const decoded = Buffer.from(token, 'base64url').toString('utf8');
  const parsed = JSON.parse(decoded); // {data, sig}

  const expected = crypto.createHmac('sha256', QR_SECRET).update(parsed.data).digest('hex');
  if (expected !== parsed.sig) {
    throw new Error('Invalid QR signature');
  }

  return JSON.parse(parsed.data); // payload
}

module.exports = { signPayload, verifyToken };
