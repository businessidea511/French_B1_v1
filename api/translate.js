// Shared translations for every user (table public.translations, see supabase/translations.sql).
//   GET  /api/translate?lang=ar                 → { items: { <hash>: <translation>, ... } } (cached by the CDN)
//   POST /api/translate { lang, texts: [...] }   → { items: [translation | null, ...] }
//        Texts already in the table come from it; the others are translated by
//        DeepSeek once, saved, and returned. Clients can only send source texts,
//        never translations, so nobody can put a wrong translation in the table.
// <hash> = first 16 hex characters of sha1(text), computed the same way in the app.
const crypto = require('crypto');
const { handleCors, isAllowedOrigin, rateLimited, isAdmin, supabaseRest } = require('./_lib');

const LANGUAGES = {
  fr: 'French',
  ar: 'Arabic',
  uk: 'Ukrainian',
  it: 'Italian',
  ti: 'Tigrinya',
  tr: 'Turkish',
  id: 'Indonesian',
};
const MAX_TEXTS = 30;
const MAX_TEXT_CHARS = 6000;
const MAX_TOTAL_CHARS = 20000;
const MAX_ROWS_PER_LANGUAGE = 60000; // stops anyone from filling the table with junk
const PAGE = 1000;

const hash = (text) => crypto.createHash('sha1').update(text, 'utf8').digest('hex').slice(0, 16);

// Supabase answers 404 / PGRST205 when the table does not exist yet.
function notSetUp(e) {
  return /\(404\)|PGRST205|relation .* does not exist/.test(String(e && e.message));
}

async function listAll(lang) {
  const items = {};
  for (let offset = 0; ; offset += PAGE) {
    const rows = await supabaseRest(
      `translations?lang=eq.${lang}&select=hash,translated&order=hash.asc&limit=${PAGE}&offset=${offset}`,
    );
    for (const r of rows) items[r.hash] = r.translated;
    if (rows.length < PAGE) break;
  }
  return items;
}

// DeepSeek's JSON mode sometimes answers with only spaces; then ask again in normal mode.
async function deepseek(texts, language) {
  try {
    return await deepseekOnce(texts, language, true);
  } catch (e) {
    if (!/JSON|items/.test(e.message)) throw e;
    return deepseekOnce(texts, language, false);
  }
}

async function deepseekOnce(texts, language, jsonMode) {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) throw new Error('DEEPSEEK_API_KEY is not configured');
  const response = await fetch('https://api.deepseek.com/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({
      model: 'deepseek-flash',
      thinking: { type: 'disabled' },
      temperature: 0.2,
      max_tokens: 16384,
      ...(jsonMode ? { response_format: { type: 'json_object' } } : {}),
      messages: [
        {
          role: 'system',
          content:
            `You translate the interface and explanations of a French course for learners into ${language}. ` +
            'Translate every item of "items" (labels, glosses, notes, grammar explanations). ' +
            'Keep every French word, example, conjugation or quotation (often between « » or in quotes) exactly as it is. ' +
            'Keep line breaks, numbering, markdown (**bold**) and symbols (✅ ❌ → ♂ ♀ emoji) as they are. ' +
            'Natural and clear. Keep the same number and order of items. Return JSON: {"items": ["...", "..."]}',
        },
        { role: 'user', content: JSON.stringify({ items: texts }) },
        ...(jsonMode ? [] : [{ role: 'system', content: 'Answer with ONLY the JSON object, nothing else.' }]),
      ],
    }),
  });
  if (!response.ok) throw new Error(`DeepSeek failed (${response.status})`);
  const data = await response.json();
  const content = String(data.choices?.[0]?.message?.content || '').replace(/```json|```/g, '').trim();
  const start = content.indexOf('{');
  const end = content.lastIndexOf('}');
  if (start < 0 || end <= start) throw new Error('DeepSeek returned no JSON');
  const items = JSON.parse(content.slice(start, end + 1)).items;
  if (!Array.isArray(items) || items.length !== texts.length) throw new Error('DeepSeek returned a wrong number of items');
  return items.map((t) => (typeof t === 'string' && t.trim() ? t.trim() : null));
}

async function handleGet(req, res) {
  if (isAllowedOrigin(req.headers.origin)) {
    res.setHeader('Access-Control-Allow-Origin', req.headers.origin);
    res.setHeader('Vary', 'Origin');
  }
  const lang = String(req.query.lang || '');
  if (!LANGUAGES[lang]) return res.status(400).json({ error: 'unknown language' });
  if (rateLimited(req, 'translate-get', 30, 60_000)) return res.status(429).json({ error: 'Too many requests' });
  try {
    const items = await listAll(lang);
    // The CDN keeps the answer 5 minutes and may serve an older copy while refreshing.
    res.setHeader('Cache-Control', 'public, s-maxage=300, stale-while-revalidate=86400');
    return res.status(200).json({ items });
  } catch (e) {
    if (notSetUp(e)) return res.status(503).json({ error: 'translations table not set up' });
    return res.status(500).json({ error: e.message });
  }
}

module.exports = async (req, res) => {
  if (req.method === 'GET') return handleGet(req, res);
  if (handleCors(req, res)) return;

  const admin = isAdmin(req);
  // The admin pre-translates whole lessons into 7 languages, so gets more room.
  if (rateLimited(req, 'translate', admin ? 400 : 60, 60_000)) {
    return res.status(429).json({ error: 'Too many translation requests. Slow down a little.' });
  }

  const body = req.body || {};
  const lang = String(body.lang || '');
  const language = LANGUAGES[lang];
  if (!language) return res.status(400).json({ error: 'unknown language' });
  const texts = body.texts;
  if (!Array.isArray(texts) || texts.length === 0 || texts.length > MAX_TEXTS) {
    return res.status(400).json({ error: `texts must be 1 to ${MAX_TEXTS} strings` });
  }
  let total = 0;
  for (const t of texts) {
    if (typeof t !== 'string' || !t.trim() || t.length > MAX_TEXT_CHARS) {
      return res.status(400).json({ error: 'invalid text' });
    }
    total += t.length;
  }
  if (total > MAX_TOTAL_CHARS) return res.status(413).json({ error: 'texts too long' });

  try {
    const hashes = texts.map(hash);
    const unique = [...new Set(hashes)];
    const found = await supabaseRest(
      `translations?lang=eq.${lang}&hash=in.(${unique.join(',')})&select=hash,translated`,
    );
    const known = Object.fromEntries(found.map((r) => [r.hash, r.translated]));

    const missing = [];
    texts.forEach((t, i) => {
      if (!(hashes[i] in known) && !missing.some((j) => hashes[j] === hashes[i])) missing.push(i);
    });

    if (missing.length) {
      const translated = await deepseek(missing.map((i) => texts[i]), language);
      const rows = [];
      missing.forEach((i, k) => {
        if (translated[k] === null) return;
        known[hashes[i]] = translated[k];
        rows.push({ lang, hash: hashes[i], source: texts[i], translated: translated[k] });
      });
      if (rows.length) {
        // Saved for everyone, unless the table for this language is already very full.
        const head = await fetch(
          `${process.env.SUPABASE_URL.replace(/\/$/, '')}/rest/v1/translations?lang=eq.${lang}&select=hash&limit=1`,
          { method: 'HEAD', headers: countHeaders() },
        );
        const count = Number((head.headers.get('content-range') || '').split('/')[1] || 0);
        if (admin || count < MAX_ROWS_PER_LANGUAGE) {
          await supabaseRest('translations?on_conflict=lang,hash', {
            method: 'POST',
            body: rows,
            prefer: 'resolution=ignore-duplicates,return=minimal',
          });
        }
      }
    }
    return res.status(200).json({ items: hashes.map((h) => (h in known ? known[h] : null)) });
  } catch (e) {
    if (notSetUp(e)) return res.status(503).json({ error: 'translations table not set up' });
    return res.status(500).json({ error: e.message });
  }
};

function countHeaders() {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const headers = { apikey: key, Prefer: 'count=estimated' };
  if (key && key.startsWith('eyJ')) headers.Authorization = `Bearer ${key}`;
  return headers;
}
