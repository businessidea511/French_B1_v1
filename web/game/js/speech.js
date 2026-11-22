// Voices and sounds. French is spoken with natural voices from the server
// (/api/tts, a different voice per character). Each sentence is made once,
// kept on the phone, and played at once after that. When the server is slow
// or there is no internet, the phone's own voice speaks instead.
// Listening uses the browser's speech recognition.
import { API_BASE } from './i18n.js';

let frVoice = null;
function pickVoice() {
  const voices = speechSynthesis.getVoices();
  frVoice =
    voices.find((v) => v.lang === 'fr-FR' && /google|natural|neural/i.test(v.name)) ||
    voices.find((v) => v.lang === 'fr-FR') ||
    voices.find((v) => v.lang && v.lang.startsWith('fr')) ||
    null;
}
if ('speechSynthesis' in window) {
  pickVoice();
  speechSynthesis.onvoiceschanged = pickVoice;
}

const clean = (text) =>
  text.replace(/[«»_]/g, ' ').replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu, '').replace(/\s+/g, ' ').trim();

// ---- natural voices ----
const VOICE_CACHE = 'quest-voice-v1';
const made = new Map(); // "voice|text" → Promise<url | null>

function natural(text, voice) {
  const id = `${voice}|${text}`;
  if (made.has(id)) return made.get(id);
  const job = (async () => {
    const key = `/quest-voice/${voice}/${encodeURIComponent(text)}`;
    let cache = null;
    try { cache = 'caches' in window ? await caches.open(VOICE_CACHE) : null; } catch (_) {}
    try {
      const saved = cache && (await cache.match(key));
      if (saved) return URL.createObjectURL(await saved.blob());
      const res = await fetch(`${API_BASE}/api/tts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, voice }),
      });
      if (!res.ok) throw new Error(`tts ${res.status}`);
      const { url } = await res.json();
      // Play it from the server now (it streams), and keep a copy for next time.
      if (cache) {
        fetch(url)
          .then((r) => r.blob())
          .then((blob) => cache.put(key, new Response(blob, { headers: { 'Content-Type': blob.type || 'audio/mpeg' } })))
          .catch(() => {});
      }
      return url;
    } catch (_) {
      made.delete(id); // try again next time
      return null;
    }
  })();
  made.set(id, job);
  return job;
}

/** Makes these lines ready in the background, one after another. */
export async function preload(lines) {
  for (const { text, voice } of lines) {
    if (text && clean(text)) await natural(clean(text), voice || 'denise');
  }
}

let current = null;
let token = 0;

export function stopSpeaking() {
  token++;
  if (current) { current.pause(); current = null; }
  if ('speechSynthesis' in window) speechSynthesis.cancel();
}

function deviceVoice(text, { pitch = 1, rate = 0.92 } = {}) {
  if (!('speechSynthesis' in window)) return;
  const u = new SpeechSynthesisUtterance(text);
  u.lang = 'fr-FR';
  if (frVoice) u.voice = frVoice;
  u.pitch = pitch;
  u.rate = rate;
  speechSynthesis.speak(u);
}

/** Says a French sentence with the character's voice: { voice, speed, pitch, rate }. */
export async function say(text, opts = {}) {
  if (!text || !clean(text)) return;
  stopSpeaking();
  const mine = token;
  const line = clean(text);
  const url = await Promise.race([
    natural(line, opts.voice || 'denise'),
    new Promise((r) => setTimeout(() => r(null), 3500)),
  ]);
  if (mine !== token) return; // something else is being said now
  if (!url) return deviceVoice(line, opts);
  const audio = new Audio(url);
  audio.playbackRate = opts.speed || 1;
  current = audio;
  audio.play().catch(() => deviceVoice(line, opts));
}

export const canListen = !!(window.SpeechRecognition || window.webkitSpeechRecognition);

/** Listens for one French sentence. Resolves the words heard ('' if none). */
export function listen() {
  return new Promise((resolve) => {
    const Rec = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!Rec) return resolve('');
    const rec = new Rec();
    rec.lang = 'fr-FR';
    rec.interimResults = false;
    rec.maxAlternatives = 3;
    let heard = '';
    rec.onresult = (e) => {
      heard = [...e.results[0]].map((a) => a.transcript).join(' | ');
    };
    rec.onerror = () => resolve('');
    rec.onend = () => resolve(heard);
    try { rec.start(); } catch (_) { resolve(''); }
  });
}

/** Letters only, no accents: "Je m'appelle Léa !" → "je mappelle lea". */
export function norm(s) {
  return s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9 ]/g, '').replace(/\s+/g, ' ').trim();
}

/** How close what was heard is to the expected sentence (0…1). */
export function closeness(heard, expected) {
  const want = norm(expected).split(' ').filter((w) => w.length > 1);
  if (!want.length) return 0;
  const got = new Set(heard.split('|').flatMap((h) => norm(h).split(' ')));
  return want.filter((w) => got.has(w)).length / want.length;
}

// ---- Little sounds, made on the fly (no files to download) ----
let ctx = null;
function audio() {
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
  }
  if (ctx.state === 'suspended') ctx.resume();
  return ctx;
}

function tone(freq, start, dur, type = 'sine', gain = 0.18) {
  const a = audio();
  if (!a) return;
  const o = a.createOscillator();
  const g = a.createGain();
  o.type = type;
  o.frequency.setValueAtTime(freq, a.currentTime + start);
  g.gain.setValueAtTime(0, a.currentTime + start);
  g.gain.linearRampToValueAtTime(gain, a.currentTime + start + 0.02);
  g.gain.exponentialRampToValueAtTime(0.001, a.currentTime + start + dur);
  o.connect(g).connect(a.destination);
  o.start(a.currentTime + start);
  o.stop(a.currentTime + start + dur + 0.05);
}

export const sfx = {
  crystal() { [784, 988, 1175, 1568].forEach((f, i) => tone(f, i * 0.07, 0.5, 'triangle', 0.14)); },
  right() { tone(660, 0, 0.15, 'triangle'); tone(990, 0.1, 0.3, 'triangle'); },
  wrong() { tone(220, 0, 0.25, 'square', 0.06); tone(180, 0.12, 0.3, 'square', 0.06); },
  coin() { tone(1320, 0, 0.08, 'square', 0.07); tone(1760, 0.07, 0.2, 'square', 0.07); },
  open() { [392, 523, 659, 784, 1046].forEach((f, i) => tone(f, i * 0.11, 0.6, 'triangle', 0.13)); },
  dark() { tone(110, 0, 1.2, 'sawtooth', 0.05); tone(98, 0.3, 1.2, 'sawtooth', 0.05); },
  step() { tone(140 + Math.random() * 40, 0, 0.05, 'sine', 0.03); },
  unlock() { audio(); },
};
