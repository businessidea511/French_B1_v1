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

// The sentences recorded once with the game (tools/game_voices.mjs): played
// from the game's own files, with no call to the voice server at all.
const recorded = fetch('voices.json')
  .then((r) => (r.ok ? r.json() : {}))
  .catch(() => ({}));

function natural(text, voice) {
  const id = `${voice}|${text}`;
  if (made.has(id)) return made.get(id);
  const job = (async () => {
    const file = (await recorded)[id];
    if (file) return `audio/${file}`;
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
let finishCurrent = null; // ends the promise of the line being said

export function stopSpeaking() {
  token++;
  if (current) { current.pause(); current = null; }
  if ('speechSynthesis' in window) speechSynthesis.cancel();
  if (finishCurrent) { finishCurrent(); finishCurrent = null; }
}

function deviceVoice(text, { pitch = 1, rate = 0.92 } = {}, done) {
  if (!('speechSynthesis' in window)) return done();
  const u = new SpeechSynthesisUtterance(text);
  u.lang = 'fr-FR';
  if (frVoice) u.voice = frVoice;
  u.pitch = pitch;
  u.rate = rate;
  u.onend = done;
  u.onerror = done;
  speechSynthesis.speak(u);
}

/**
 * Says a French sentence with the character's voice: { voice, speed, pitch, rate }.
 * Resolves when the sentence has been said (or was stopped), so the next one
 * never talks over it.
 */
export function say(text, opts = {}) {
  if (!text || !clean(text)) return Promise.resolve();
  stopSpeaking();
  const mine = token;
  const line = clean(text);
  return new Promise((resolve) => {
    let ended = false;
    const done = () => {
      if (ended) return;
      ended = true;
      if (finishCurrent === done) finishCurrent = null;
      resolve();
    };
    finishCurrent = done;
    // Never wait forever (a voice that never says « finished »).
    setTimeout(done, 3500 + line.length * 110);
    Promise.race([
      natural(line, opts.voice || 'denise'),
      new Promise((r) => setTimeout(() => r(null), 3500)),
    ]).then((url) => {
      if (mine !== token) return done(); // something else is being said now
      if (!url) return deviceVoice(line, opts, done);
      const audio = new Audio(url);
      audio.playbackRate = opts.speed || 1;
      audio.onended = done;
      audio.onerror = done;
      current = audio;
      audio.play().catch(() => deviceVoice(line, opts, done));
    });
  });
}

export const canListen = !!(window.SpeechRecognition || window.webkitSpeechRecognition);

let activeRec = null;

/** Stops listening now (the words heard so far are kept). */
export function stopListening() {
  try { activeRec?.stop(); } catch (_) {}
}

/**
 * Listens to French. onText(text) gets the words live, while the player
 * speaks (iPhone Safari only gives results this way). Stops after a short
 * silence, after 10 seconds, or with stopListening().
 * Resolves { text, error }: text may hold alternatives separated by « | ».
 */
export function listen(onText) {
  return new Promise((resolve) => {
    const Rec = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!Rec) return resolve({ text: '', error: 'unsupported' });
    // Sounds playing at the same time can block the microphone on iPhone.
    stopSpeaking();
    const rec = new Rec();
    rec.lang = 'fr-FR';
    rec.interimResults = true;
    rec.continuous = !/Android/i.test(navigator.userAgent); // Android repeats words in continuous mode
    rec.maxAlternatives = 3;
    activeRec = rec;
    let text = '';
    let alternatives = '';
    let error = '';
    let silence = null;
    const hardStop = setTimeout(() => stopListening(), 10000);
    rec.onresult = (e) => {
      const parts = [];
      const alts = [];
      for (const r of e.results) {
        parts.push(r[0].transcript.trim());
        for (let k = 1; k < r.length; k++) alts.push(r[k].transcript.trim());
      }
      text = parts.join(' ').trim();
      alternatives = alts.join(' | ');
      if (text && onText) onText(text);
      // Finished speaking: stop after a short pause.
      clearTimeout(silence);
      silence = setTimeout(() => stopListening(), 1400);
    };
    rec.onerror = (e) => { if (e.error !== 'no-speech' && e.error !== 'aborted') error = e.error; };
    rec.onend = () => {
      clearTimeout(silence);
      clearTimeout(hardStop);
      if (activeRec === rec) activeRec = null;
      resolve({ text: alternatives ? `${text} | ${alternatives}` : text, error });
    };
    try { rec.start(); } catch (_) { resolve({ text: '', error: 'start' }); }
  });
}

/** What to tell the player when the microphone could not be used. */
export function micProblem(error) {
  if (error === 'not-allowed' || error === 'service-not-allowed') {
    return /iPhone|iPad/i.test(navigator.userAgent)
      ? 'The microphone is blocked. On iPhone: Settings › Safari › Microphone › Allow. Speech recognition also needs Siri to be on.'
      : 'The microphone is blocked. Allow it for this site in the browser settings.';
  }
  if (error === 'audio-capture') return 'No microphone found, or another app is using it.';
  if (error === 'network') return 'Speech recognition needs the internet.';
  return 'I did not hear you. Try again.';
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

/** How well one heard sentence fits one answer: both the words said and the words missing count. */
function fit(heard, expected) {
  const want = norm(expected).split(' ').filter(Boolean);
  const got = norm(heard).split(' ').filter(Boolean);
  if (!want.length || !got.length) return 0;
  const pool = [...got];
  let common = 0;
  for (const w of want) {
    const i = pool.indexOf(w);
    if (i >= 0) { common++; pool.splice(i, 1); }
  }
  const recall = common / want.length;
  const precision = common / got.length;
  return recall + precision ? (2 * recall * precision) / (recall + precision) : 0;
}

/**
 * The answer that fits the WHOLE sentence said best. Answers that share
 * words (« je voudrais un café » / « je voudrais un champagne ») are told
 * apart by the words that differ. Returns { index, score, sure }: sure is
 * false when nothing fits well, or two answers fit almost as well.
 */
export function bestMatch(heard, answers) {
  const versions = heard.split('|').map((h) => h.trim()).filter(Boolean);
  const scores = answers.map((a) => Math.max(0, ...versions.map((v) => fit(v, a))));
  let index = 0;
  scores.forEach((s, i) => { if (s > scores[index]) index = i; });
  const second = Math.max(0, ...scores.filter((_, i) => i !== index));
  // A word said that the answer does not have, while the answer has a word
  // not said (« café » for « thé »): that is another sentence, not this one.
  const want = new Set(norm(answers[index]).split(' ').filter((w) => w.length > 2));
  const swapped = versions.every((v) => {
    const got = new Set(norm(v).split(' ').filter((w) => w.length > 2));
    return [...got].some((w) => !want.has(w)) && [...want].some((w) => !got.has(w) && !['sil', 'vous', 'plait', 'merci'].includes(w));
  });
  return { index, score: scores[index], sure: !swapped && scores[index] >= 0.6 && scores[index] - second >= 0.12 };
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
  ring() { for (let k = 0; k < 3; k++) { tone(880, k * 0.6, 0.18, 'sine', 0.1); tone(660, k * 0.6 + 0.2, 0.18, 'sine', 0.1); } },
  unlock() { audio(); },
};
