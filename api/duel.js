// POST /api/duel — friendly duels for a friend or a whole class (no login needed).
//   { action: 'create', code, topics: [...], questions: [...] } → saves a new duel's questions
//   { action: 'get', code }                                       → { duel: { topics, questions } | null }
//   { action: 'submit', code, name, score, correct, seconds }     → saves a score, returns the board
//   { action: 'list', code }                                      → returns the board
//   { action: 'join', code, name }                                → waiting room: adds the player, returns the status
//   { action: 'start', code, host_key }                           → creator starts the duel for everyone (in 5 s)
//   GET /api/duel?code=…                                          → status { live, started_at, host_name, players, now }
//                                                                   (cached 1 s by the CDN: a class polls it every 2 s)
// Everyone with the code answers the same questions (5 to 20, easy to hard). Duels
// created before topics could be chosen have no row in "duels": the app then makes
// their 10 questions from the code. The board shows each player's best try.
const { handleCors, isAllowedOrigin, rateLimited, supabaseRest } = require('./_lib');

const CODE = /^[A-Z0-9]{6}$/;
const MIN_QUESTIONS = 5;
const MAX_QUESTIONS = 20;
const HOST_KEY = /^[A-Za-z0-9]{16,64}$/;
const START_DELAY_MS = 5000; // time for every phone to see the start and count down 3-2-1

// Supabase answers 400 with PGRST204 / 42703 when duel_live.sql has not been run yet.
const missingColumns = (e) => /PGRST204|42703|column/.test(String(e && e.message));

// Waiting-room status of a duel, or null if the duel does not exist.
async function status(code) {
  let duel;
  try {
    [duel] = await supabaseRest(`duels?code=eq.${code}&select=host_key,host_name,started_at&limit=1`);
  } catch (e) {
    if (!missingColumns(e)) throw e;
    return { live: false, started_at: null, host_name: null, players: [], now: new Date().toISOString() };
  }
  if (!duel) return null;
  const players = duel.host_key
    ? await supabaseRest(`duel_players?code=eq.${code}&select=name&order=joined_at.asc&limit=200`)
    : [];
  return {
    live: Boolean(duel.host_key),
    started_at: duel.started_at,
    host_name: duel.host_name,
    players: players.map((p) => p.name),
    now: new Date().toISOString(),
  };
}

async function handleGet(req, res) {
  if (isAllowedOrigin(req.headers.origin)) {
    res.setHeader('Access-Control-Allow-Origin', req.headers.origin);
    res.setHeader('Vary', 'Origin');
  }
  const code = String(req.query.code || '').toUpperCase();
  if (!CODE.test(code)) return res.status(400).json({ error: 'invalid code' });
  try {
    const result = await status(code);
    res.setHeader('Cache-Control', 'public, s-maxage=1, stale-while-revalidate=1');
    return res.status(200).json({ status: result });
  } catch (e) {
    if (/\(404\)|PGRST205|42P01/.test(e.message)) return res.status(503).json({ error: 'duels table not set up' });
    return res.status(500).json({ error: e.message });
  }
}

function int(value, min, max) {
  const n = Number(value);
  return Number.isInteger(n) && n >= min && n <= max ? n : null;
}

const str = (v, max) => (typeof v === 'string' && v.trim() && v.length <= max ? v.trim() : null);

// Keeps only well-formed questions; returns null if the set is not usable.
function cleanQuestions(raw) {
  if (!Array.isArray(raw) || raw.length < MIN_QUESTIONS || raw.length > MAX_QUESTIONS) return null;
  const out = [];
  for (const q of raw) {
    if (!q || typeof q !== 'object') return null;
    const prompt = str(q.prompt, 300);
    const hint = typeof q.hint === 'string' ? q.hint.slice(0, 120) : '';
    const options = Array.isArray(q.options) ? q.options.map((o) => str(o, 120)) : [];
    const correct = int(q.correct, 0, options.length - 1);
    if (!prompt || options.length < 2 || options.length > 4 || options.includes(null) || correct === null) return null;
    if (new Set(options).size !== options.length) return null;
    out.push({ prompt, english: q.english === true, hint, options, correct, level: int(q.level, 1, 3) || 2 });
  }
  return out;
}

module.exports = async (req, res) => {
  if (req.method === 'GET') return handleGet(req, res);
  if (handleCors(req, res)) return;
  // A whole class (about 30 people) often shares one school Wi-Fi address.
  if (rateLimited(req, 'duel', 300, 60_000)) return res.status(429).json({ error: 'Too many requests, slow down.' });

  const body = req.body || {};
  const code = String(body.code || '').toUpperCase();
  if (!CODE.test(code)) return res.status(400).json({ error: 'invalid code' });

  try {
    if (body.action === 'create') {
      const questions = cleanQuestions(body.questions);
      if (!questions) return res.status(400).json({ error: 'invalid questions' });
      const topics = (Array.isArray(body.topics) ? body.topics : [])
        .map((t) => str(t, 80))
        .filter(Boolean)
        .slice(0, 40);
      const hostKey = HOST_KEY.test(String(body.host_key || '')) ? String(body.host_key) : null;
      const hostName = hostKey ? String(body.host_name || '').trim().slice(0, 24) || null : null;
      const row = { code, topics, questions, ...(hostKey ? { host_key: hostKey, host_name: hostName } : {}) };
      try {
        await supabaseRest('duels', { method: 'POST', body: row, prefer: 'return=minimal' });
      } catch (e) {
        if (!hostKey || !missingColumns(e)) throw e;
        // duel_live.sql not run yet: a duel without waiting room.
        await supabaseRest('duels', { method: 'POST', body: { code, topics, questions }, prefer: 'return=minimal' });
        return res.status(200).json({ ok: true, live: false });
      }
      if (hostKey && hostName) {
        await supabaseRest('duel_players?on_conflict=code,name_key', {
          method: 'POST',
          body: { code, name_key: hostName.toLowerCase(), name: hostName },
          prefer: 'resolution=ignore-duplicates,return=minimal',
        });
      }
      return res.status(200).json({ ok: true, live: Boolean(hostKey) });
    }

    if (body.action === 'get') {
      const rows = await supabaseRest(`duels?code=eq.${code}&select=topics,questions&limit=1`);
      if (!rows[0]) return res.status(200).json({ duel: null });
      return res.status(200).json({ duel: rows[0], status: await status(code) });
    }

    if (body.action === 'join') {
      const name = String(body.name || '').trim().slice(0, 24);
      if (!name) return res.status(400).json({ error: 'invalid name' });
      const current = await status(code);
      if (!current) return res.status(404).json({ error: 'unknown duel' });
      if (current.live) {
        await supabaseRest('duel_players?on_conflict=code,name_key', {
          method: 'POST',
          body: { code, name_key: name.toLowerCase(), name },
          prefer: 'resolution=ignore-duplicates,return=minimal',
        });
      }
      return res.status(200).json({ status: await status(code) });
    }

    if (body.action === 'start') {
      const hostKey = String(body.host_key || '');
      if (!HOST_KEY.test(hostKey)) return res.status(403).json({ error: 'only the creator can start' });
      const startAt = new Date(Date.now() + START_DELAY_MS).toISOString();
      const updated = await supabaseRest(
        `duels?code=eq.${code}&host_key=eq.${hostKey}&started_at=is.null&select=code`,
        { method: 'PATCH', body: { started_at: startAt }, prefer: 'return=representation' },
      );
      if (!updated.length) {
        const [owned] = await supabaseRest(`duels?code=eq.${code}&host_key=eq.${hostKey}&select=code&limit=1`);
        if (!owned) return res.status(403).json({ error: 'only the creator can start' });
      }
      return res.status(200).json({ status: await status(code) });
    }

    if (body.action === 'submit') {
      const name = String(body.name || '').trim().slice(0, 24);
      const correct = int(body.correct, 0, MAX_QUESTIONS);
      const score = int(body.score, 0, 5000);
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
    // Duplicate code (very rare): the app makes a new code and tries again.
    if (/\(409\)|23505/.test(e.message)) return res.status(409).json({ error: 'code already used' });
    // The duels table is not created yet: the app falls back to questions made from the code.
    if (/\(404\)|PGRST205|42P01/.test(e.message)) return res.status(503).json({ error: 'duels table not set up' });
    return res.status(500).json({ error: e.message });
  }
};
