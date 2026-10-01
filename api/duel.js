// POST /api/duel — scores of friendly duels (no login needed).
//   { action: 'submit', code, name, score, correct, seconds }  → saves a score, returns the board
//   { action: 'list', code }                                     → returns the board
// Everyone with the code (a friend or a whole class) answers the same 10 questions,
// generated in the app from the code. The board shows each player's best try.
const { handleCors, rateLimited, supabaseRest } = require('./_lib');

const CODE = /^[A-Z0-9]{6}$/;

function int(value, min, max) {
  const n = Number(value);
  return Number.isInteger(n) && n >= min && n <= max ? n : null;
}

module.exports = async (req, res) => {
  if (handleCors(req, res)) return;
  // A whole class (about 30 people) often shares one school Wi-Fi address.
  if (rateLimited(req, 'duel', 300, 60_000)) return res.status(429).json({ error: 'Too many requests, slow down.' });

  const body = req.body || {};
  const code = String(body.code || '').toUpperCase();
  if (!CODE.test(code)) return res.status(400).json({ error: 'invalid code' });

  try {
    if (body.action === 'submit') {
      const name = String(body.name || '').trim().slice(0, 24);
      const score = int(body.score, 0, 5000);
      const correct = int(body.correct, 0, 10);
      const seconds = int(body.seconds, 0, 3600);
      if (!name || score === null || correct === null || seconds === null) {
        return res.status(400).json({ error: 'invalid score' });
      }
      await supabaseRest('duel_scores', {
        method: 'POST',
        body: { code, name, score, correct, seconds },
        prefer: 'return=minimal',
      });
    } else if (body.action !== 'list') {
      return res.status(400).json({ error: 'unknown action' });
    }
    const all = await supabaseRest(
      `duel_scores?code=eq.${code}&select=name,score,correct,seconds,created_at&order=score.desc,seconds.asc&limit=500`,
    );
    // One line per player: their best try (a class can replay many times).
    const seen = new Set();
    const rows = all.filter((r) => {
      const key = r.name.trim().toLowerCase();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    }).slice(0, 100);
    return res.status(200).json({ rows });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};
