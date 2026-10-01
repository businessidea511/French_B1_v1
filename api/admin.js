// POST /api/admin  { "password": "..." }  →  { "token": "...", "expiresAt": 1234 }
const { handleCors, rateLimited, issueAdminToken, passwordMatches } = require('./_lib');

module.exports = async (req, res) => {
  if (handleCors(req, res)) return;

  if (rateLimited(req, 'admin-login', 8, 10 * 60 * 1000)) {
    return res.status(429).json({ error: 'Too many attempts. Try again in a few minutes.' });
  }

  if (!process.env.ADMIN_PASSWORD) {
    return res.status(500).json({ error: 'ADMIN_PASSWORD is not configured on the server' });
  }

  if (!passwordMatches(req.body && req.body.password)) {
    return res.status(401).json({ error: 'Incorrect password' });
  }

  return res.status(200).json(issueAdminToken());
};
