// Shared helpers for the Vercel serverless functions in /api.
// Files starting with "_" are not exposed as endpoints by Vercel.
const crypto = require('crypto');

// Origins allowed to call the API from a browser. Same-origin calls from the
// deployed app need no CORS; these cover `flutter run -d chrome` on localhost.
function isAllowedOrigin(origin) {
  if (!origin) return false;
  try {
    const { hostname } = new URL(origin);
    if (hostname === 'localhost' || hostname === '127.0.0.1') return true;
    const extra = (process.env.ALLOWED_ORIGINS || '').split(',').map((s) => s.trim()).filter(Boolean);
    return extra.includes(origin);
  } catch (_) {
    return false;
  }
}

// Applies CORS headers and answers preflight. Returns true when the request is done.
function handleCors(req, res) {
  const origin = req.headers.origin;
  if (isAllowedOrigin(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  }
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return true;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return true;
  }
  return false;
}

// Best-effort per-IP rate limit. State lives in one warm function instance, so it
// slows down casual abuse but is not a hard global limit.
const buckets = new Map();
function rateLimited(req, name, limit, windowMs) {
  const ip = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || 'unknown';
  const key = `${name}:${ip}`;
  const now = Date.now();
  const hits = (buckets.get(key) || []).filter((t) => now - t < windowMs);
  hits.push(now);
  buckets.set(key, hits);
  if (buckets.size > 5000) buckets.clear();
  return hits.length > limit;
}

// ── Admin session tokens ─────────────────────────────────────────────────────
// Stateless HMAC token: "<expiryMs>.<signature>". Changing ADMIN_PASSWORD or
// ADMIN_TOKEN_SECRET invalidates every issued token.
const TOKEN_TTL_MS = 12 * 60 * 60 * 1000;

function tokenSecret() {
  const secret = process.env.ADMIN_TOKEN_SECRET || process.env.ADMIN_PASSWORD;
  if (!secret) throw new Error('ADMIN_PASSWORD is not configured');
  return crypto.createHash('sha256').update(`polylearn-admin:${secret}`).digest();
}

function sign(payload) {
  return crypto.createHmac('sha256', tokenSecret()).update(payload).digest('base64url');
}

function issueAdminToken() {
  const exp = String(Date.now() + TOKEN_TTL_MS);
  return { token: `${exp}.${sign(exp)}`, expiresAt: Number(exp) };
}

function safeEqual(a, b) {
  const ab = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  return ab.length === bb.length && crypto.timingSafeEqual(ab, bb);
}

function isAdmin(req) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const [exp, sig] = token.split('.');
  if (!exp || !sig || !/^\d+$/.test(exp) || Number(exp) < Date.now()) return false;
  try {
    return safeEqual(sig, sign(exp));
  } catch (_) {
    return false;
  }
}

function passwordMatches(input) {
  const expected = process.env.ADMIN_PASSWORD;
  if (!expected || typeof input !== 'string') return false;
  return safeEqual(input, expected);
}

// ── Supabase (service role, server only) ─────────────────────────────────────
function supabaseHeaders(extra = {}) {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!process.env.SUPABASE_URL || !key) throw new Error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not configured');
  const headers = { apikey: key, 'Content-Type': 'application/json', ...extra };
  // Legacy JWT keys go in Authorization too; new sb_secret_ keys must not.
  if (key.startsWith('eyJ')) headers.Authorization = `Bearer ${key}`;
  return headers;
}

async function supabaseRest(path, { method = 'GET', body, prefer } = {}) {
  const url = `${process.env.SUPABASE_URL.replace(/\/$/, '')}/rest/v1/${path}`;
  const response = await fetch(url, {
    method,
    headers: supabaseHeaders(prefer ? { Prefer: prefer } : {}),
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`Supabase ${method} ${path.split('?')[0]} failed (${response.status}): ${text.slice(0, 300)}`);
  }
  return text ? JSON.parse(text) : null;
}

module.exports = {
  isAllowedOrigin,
  handleCors,
  rateLimited,
  issueAdminToken,
  isAdmin,
  passwordMatches,
  supabaseRest,
};
