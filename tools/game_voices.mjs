// Records the game's voices once, as audio files the game plays directly.
//
//   node tools/game_voices.mjs
//
// Every fixed French sentence of the chapters (dialogues, clues, the men in
// grey's questions…) is spoken by the natural voice of its character through
// the same Edge-TTS Hugging Face Space as /api/tts, saved to
// web/game/audio/, and listed in web/game/voices.json.
// Sentences already recorded are skipped, so running it again only records
// what is new. Sentences with the player's name stay live (/api/tts).
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, unlinkSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const GAME = join(ROOT, 'web', 'game');
const OUT = join(GAME, 'audio');
const SPACE = 'https://innoai-edge-tts-text-to-speech.hf.space/gradio_api/call/tts_interface';
const VOICES = {
  denise: 'fr-FR-DeniseNeural - fr-FR (Female)',
  henri: 'fr-FR-HenriNeural - fr-FR (Male)',
  eloise: 'fr-FR-EloiseNeural - fr-FR (Female)',
  vivienne: 'fr-FR-VivienneMultilingualNeural - fr-FR (Female)',
  remy: 'fr-FR-RemyMultilingualNeural - fr-FR (Male)',
  gerard: 'fr-BE-GerardNeural - fr-BE (Male)',
  charline: 'fr-BE-CharlineNeural - fr-BE (Female)',
};

// Exactly like clean() in web/game/js/speech.js: the key must match.
const clean = (text) =>
  text.replace(/[«»_]/g, ' ').replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu, '').replace(/\s+/g, ' ').trim();

const load = (file) => import(pathToFileURL(join(GAME, 'js', file)).href);
const { bankLines } = await load('voicedata.js');
const lines = new Map(); // key → { text, voice }
function add(text, voice) {
  if (!text || text.includes('{')) return; // the player's name: said live
  const line = clean(text);
  if (!line) return;
  const v = voice || 'denise';
  lines.set(`${v}|${line}`, { text: line, voice: v });
}

for (const file of ['dossier1.js', 'dossier1b.js', 'dossier1c.js', 'dossier2.js', 'dossier2b.js', 'dossier3.js', 'dossier3b.js', 'dossier4.js', 'dossier4b.js', 'dossier5.js']) {
  const ch = await load(file);
  for (const [text, v] of ch.voiceLines()) add(text, v?.voice);
  const L = ch.LINES;
  for (const t of [L.agentIntro, L.release]) add(t, L.agentVoice.voice);
  for (const t of [L.chiefIntro, L.storyAsk]) add(t, L.chiefVoice.voice);
  for (const [text, who] of bankLines(ch.BANKS)) {
    if (who === 'agent') {
      add(text, L.agentVoice.voice);
      add(text, L.chiefVoice.voice);
    } else add(text, who);
  }
}

mkdirSync(OUT, { recursive: true });
const manifestPath = join(GAME, 'voices.json'); // not in audio/: that folder is cached for a year
const manifest = existsSync(manifestPath) ? JSON.parse(readFileSync(manifestPath, 'utf8')) : {};

const fileFor = (key) => `${createHash('sha1').update(key).digest('hex').slice(0, 14)}.mp3`;

async function record({ text, voice }) {
  const r = await fetch(SPACE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ data: [text, VOICES[voice], 0, 0] }),
  });
  if (!r.ok) throw new Error(`trigger ${r.status}`);
  const { event_id: id } = await r.json();
  const body = await (await fetch(`${SPACE}/${id}`)).text();
  const rows = body.split('\n');
  for (let i = 0; i < rows.length - 1; i++) {
    if (rows[i].trim() === 'event: complete' && rows[i + 1].startsWith('data: ')) {
      const data = JSON.parse(rows[i + 1].slice(6));
      const url = data?.[0]?.url;
      if (!url) break;
      const audio = await fetch(url);
      if (!audio.ok) throw new Error(`download ${audio.status}`);
      return Buffer.from(await audio.arrayBuffer());
    }
  }
  throw new Error('no audio');
}

const todo = [...lines.entries()].filter(([key]) => !manifest[key] || !existsSync(join(OUT, manifest[key])));
console.log(`${lines.size} sentences, ${todo.length} to record.`);
let done = 0;
let failed = 0;
async function worker() {
  while (todo.length) {
    const [key, line] = todo.shift();
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const bytes = await record(line);
        const file = fileFor(key);
        writeFileSync(join(OUT, file), bytes);
        manifest[key] = file;
        done++;
        if (done % 10 === 0) {
          writeFileSync(manifestPath, JSON.stringify(manifest, null, 0));
          console.log(`  ${done} recorded…`);
        }
        break;
      } catch (e) {
        if (attempt === 3) { failed++; console.log(`  ✗ ${line.voice}: ${line.text.slice(0, 60)} (${e.message})`); }
        else await new Promise((r) => setTimeout(r, 2000 * attempt));
      }
    }
  }
}
await Promise.all([worker(), worker(), worker()]);
// Keep only the sentences the game still uses.
for (const key of Object.keys(manifest)) if (!lines.has(key)) delete manifest[key];
writeFileSync(manifestPath, JSON.stringify(manifest, null, 0));
// Delete audio files nothing uses any more (sentences changed or removed).
const used = new Set(Object.values(manifest));
let removed = 0;
for (const f of readdirSync(OUT)) if (f.endsWith('.mp3') && !used.has(f)) { unlinkSync(join(OUT, f)); removed++; }
if (removed) console.log(`${removed} unused audio file(s) deleted.`);
console.log(`Done: ${done} recorded, ${failed} failed, ${Object.keys(manifest).length} in the manifest.`);
