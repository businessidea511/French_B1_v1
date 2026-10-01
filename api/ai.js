// POST /api/ai  — DeepSeek chat completions proxy. The API key never leaves the server.
// Body: { messages, response_format?, temperature?, max_tokens? }
// A message's content is a string, or an array of
//   { type: 'text', text } and { type: 'image_url', image_url: { url: 'data:image/...;base64,...' } }
// Returns DeepSeek's response body and status code unchanged.
const { handleCors, rateLimited } = require('./_lib');

const MODEL = 'deepseek-flash';
const MAX_INPUT_CHARS = 300000;
const MAX_IMAGES = 10;
const MAX_OUTPUT_TOKENS = 16384;

// Returns an error string, or null when the content is acceptable.
function checkContent(content, counts) {
  if (typeof content === 'string') {
    counts.chars += content.length;
    return null;
  }
  if (!Array.isArray(content)) return 'content must be a string or an array';
  for (const part of content) {
    if (part && part.type === 'text' && typeof part.text === 'string') {
      counts.chars += part.text.length;
    } else if (part && part.type === 'image_url' && part.image_url && typeof part.image_url.url === 'string') {
      if (!/^data:image\/(png|jpe?g|gif|webp);base64,/.test(part.image_url.url)) {
        return 'images must be base64 data URLs';
      }
      counts.images += 1;
    } else {
      return 'unsupported content part';
    }
  }
  return null;
}

module.exports = async (req, res) => {
  if (handleCors(req, res)) return;

  // Lesson pages translate many strings at once, so this limit is generous.
  if (rateLimited(req, 'ai', 150, 60 * 1000)) {
    return res.status(429).json({ error: 'Too many AI requests. Slow down a little.' });
  }

  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'DEEPSEEK_API_KEY is not configured' });

  const body = req.body || {};
  const messages = body.messages;
  if (!Array.isArray(messages) || messages.length === 0 || messages.length > 20) {
    return res.status(400).json({ error: 'messages must be a non-empty array' });
  }
  const counts = { chars: 0, images: 0 };
  for (const m of messages) {
    if (!m || !['system', 'user', 'assistant'].includes(m.role)) {
      return res.status(400).json({ error: 'invalid message role' });
    }
    const error = checkContent(m.content, counts);
    if (error) return res.status(400).json({ error });
  }
  if (counts.chars > MAX_INPUT_CHARS) return res.status(413).json({ error: 'Input too long' });
  if (counts.images > MAX_IMAGES) return res.status(413).json({ error: `At most ${MAX_IMAGES} images per request` });

  // Thinking mode is DeepSeek's default; it is off here because the app needs fast
  // answers and thinking mode ignores temperature.
  const payload = { model: MODEL, messages, thinking: { type: 'disabled' } };
  if (body.response_format && body.response_format.type === 'json_object') {
    payload.response_format = { type: 'json_object' };
  }
  if (typeof body.temperature === 'number') {
    payload.temperature = Math.min(Math.max(body.temperature, 0), 1.5);
  }
  payload.max_tokens = typeof body.max_tokens === 'number'
    ? Math.min(Math.max(1, Math.floor(body.max_tokens)), MAX_OUTPUT_TOKENS)
    : MAX_OUTPUT_TOKENS;

  try {
    const upstream = await fetch('https://api.deepseek.com/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify(payload),
    });
    const text = await upstream.text();
    res.status(upstream.status).setHeader('Content-Type', 'application/json; charset=utf-8');
    return res.send(text);
  } catch (e) {
    return res.status(502).json({ error: `DeepSeek request failed: ${e.message}` });
  }
};

