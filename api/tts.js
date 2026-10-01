// POST /api/tts  { "text": "..." }  →  { "url": "https://...mp3" }
// Proxies the Edge-TTS Hugging Face Space so HF_TOKEN stays on the server.
const { handleCors, rateLimited } = require('./_lib');

const SPACE_URL = 'https://innoai-edge-tts-text-to-speech.hf.space/gradio_api/call/tts_interface';
const VOICE = 'fr-FR-DeniseNeural - fr-FR (Female)';
const MAX_TEXT_CHARS = 3000;

module.exports = async (req, res) => {
  if (handleCors(req, res)) return;

  if (rateLimited(req, 'tts', 60, 60 * 1000)) {
    return res.status(429).json({ error: 'Too many voice requests' });
  }

  const text = req.body && req.body.text;
  if (typeof text !== 'string' || !text.trim()) return res.status(400).json({ error: 'text is required' });
  if (text.length > MAX_TEXT_CHARS) return res.status(413).json({ error: 'text too long' });

  const headers = { 'Content-Type': 'application/json' };
  if (process.env.HF_TOKEN) headers.Authorization = `Bearer ${process.env.HF_TOKEN}`;

  try {
    // Step 1: start generation, get an event id.
    const trigger = await fetch(SPACE_URL, {
      method: 'POST',
      headers,
      body: JSON.stringify({ data: [text, VOICE, 0, 0] }),
    });
    if (!trigger.ok) {
      return res.status(502).json({ error: `TTS trigger failed (${trigger.status})` });
    }
    const { event_id: eventId } = await trigger.json();

    // Step 2: read the result stream and pick the "complete" event.
    const result = await fetch(`${SPACE_URL}/${eventId}`, { headers });
    if (!result.ok) {
      return res.status(502).json({ error: `TTS poll failed (${result.status})` });
    }
    const lines = (await result.text()).split('\n');
    for (let i = 0; i < lines.length - 1; i++) {
      if (lines[i].trim() === 'event: complete' && lines[i + 1].startsWith('data: ')) {
        const data = JSON.parse(lines[i + 1].slice(6));
        const url = Array.isArray(data) && data[0] && data[0].url;
        if (url) return res.status(200).json({ url });
      }
    }
    return res.status(502).json({ error: 'TTS returned no audio' });
  } catch (e) {
    return res.status(502).json({ error: `TTS request failed: ${e.message}` });
  }
};
