// Background music made on the fly with the Web Audio API (no files):
// a calm adventure tune while exploring, a fast one during fights.

let ctx = null;
let master = null;
let timer = null;
let step = 0;
let mode = 'explore';
let on = localStorage.getItem('quest_music') !== '0';
let held = false; // quiet while the microphone listens

const NOTE = (n) => 440 * Math.pow(2, (n - 69) / 12);

// Chords as MIDI notes. Explore: C – Am – F – G. Fight: Am – F – G – E.
const SONGS = {
  // Night: Am – F – Dm – E, slow, a low drone. Danger: faster, with drums.
  explore: { bpm: 66, chords: [[57, 60, 64], [53, 57, 60], [50, 53, 57], [52, 56, 59]], bass: [33, 29, 26, 28], drums: false, sparse: true },
  fight: { bpm: 118, chords: [[57, 60, 64], [57, 60, 63], [53, 57, 60], [52, 56, 59]], bass: [33, 33, 29, 28], drums: true },
};

function voice(freq, start, dur, type, gain) {
  const o = ctx.createOscillator();
  const g = ctx.createGain();
  o.type = type;
  o.frequency.value = freq;
  g.gain.setValueAtTime(0, start);
  g.gain.linearRampToValueAtTime(gain, start + 0.02);
  g.gain.exponentialRampToValueAtTime(0.0008, start + dur);
  o.connect(g).connect(master);
  o.start(start);
  o.stop(start + dur + 0.05);
}

let noiseBuffer = null;
function hat(start, gain) {
  if (!noiseBuffer) {
    noiseBuffer = ctx.createBuffer(1, ctx.sampleRate * 0.1, ctx.sampleRate);
    const d = noiseBuffer.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  }
  const s = ctx.createBufferSource();
  s.buffer = noiseBuffer;
  const f = ctx.createBiquadFilter();
  f.type = 'highpass';
  f.frequency.value = 7000;
  const g = ctx.createGain();
  g.gain.setValueAtTime(gain, start);
  g.gain.exponentialRampToValueAtTime(0.001, start + 0.06);
  s.connect(f).connect(g).connect(master);
  s.start(start);
}

function kick(start) {
  const o = ctx.createOscillator();
  const g = ctx.createGain();
  o.frequency.setValueAtTime(140, start);
  o.frequency.exponentialRampToValueAtTime(45, start + 0.15);
  g.gain.setValueAtTime(0.5, start);
  g.gain.exponentialRampToValueAtTime(0.001, start + 0.2);
  o.connect(g).connect(master);
  o.start(start);
  o.stop(start + 0.25);
}

// Plays one eighth note of the song, a little ahead of time.
function tick() {
  const song = SONGS[mode];
  const eighth = 60 / song.bpm / 2;
  if (ctx.state !== 'running') { timer = setTimeout(tick, eighth * 1000); return; } // paused: no notes piling up
  const t = ctx.currentTime + 0.1;
  const bar = Math.floor(step / 8) % 4;
  const i = step % 8;
  const chord = song.chords[bar];
  if (i === 0) {
    for (const n of chord) voice(NOTE(n), t, eighth * 8, 'sine', mode === 'fight' ? 0.05 : 0.065);
    voice(NOTE(song.bass[bar]), t, eighth * 3, 'triangle', 0.16);
  }
  if (i === 4) voice(NOTE(song.bass[bar] + 7), t, eighth * 2, 'triangle', 0.1);
  // A few piano-like notes on top (sparse at night).
  const arp = [0, 1, 2, 1, 2, 0, 1, 2][i];
  if (!song.sparse || i === 0 || i === 3 || i === 6) voice(NOTE(chord[arp] + 12), t, eighth * 3, 'triangle', mode === 'fight' ? 0.05 : 0.045);
  if (song.drums) {
    if (i % 4 === 0) kick(t);
    hat(t, i % 2 ? 0.03 : 0.05);
  }
  step++;
  // Phones pause the music when a voice plays (iPhone: « interrupted »): start it again.
  if (ctx.state !== 'running' && on && !held && !document.hidden) ctx.resume().catch(() => {});
  timer = setTimeout(tick, eighth * 1000);
}

// One audio engine for the whole game: music, voices and little sounds.
// (On iPhone, a second player for the voices stopped the music.)
// « playback »: the game is like a music app (iPhone, Safari 16.4+).
try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch (_) {}
// After the microphone, iPhone stays in « phone call » mode: the sound comes
// from the small earpiece, very low. Go back to the loudspeaker and start a
// fresh audio engine (the music comes back on its own or on the next touch).
const IOS = /iP(hone|ad|od)/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
function afterMic() {
  if (held) return;
  try {
    if (navigator.audioSession) {
      navigator.audioSession.type = 'auto';
      navigator.audioSession.type = 'playback';
    }
  } catch (_) {}
  const old = ctx;
  clearTimeout(timer);
  timer = null;
  ctx = null;
  master = null;
  noiseBuffer = null;
  if (old) old.close().catch(() => {});
  if (on) begin();
}

export function audioContext() {
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = 0.5;
    master.connect(ctx.destination);
  }
  return ctx;
}

function begin() {
  if (!on) return;
  if (!audioContext()) return;
  if (ctx.state !== 'running' && !held) ctx.resume().catch(() => {});
  if (!timer) tick();
}

export const music = {
  get on() { return on; },
  start() { begin(); },
  explore() { mode = 'explore'; begin(); },
  fight() { mode = 'fight'; step = 0; begin(); },
  toggle() {
    on = !on;
    localStorage.setItem('quest_music', on ? '1' : '0');
    if (on) begin();
    else { clearTimeout(timer); timer = null; }
    return on;
  },
  // Silent while the player speaks into the microphone (iPhone shares one audio channel).
  hold(quiet) {
    held = quiet;
    if (!ctx) return;
    if (quiet) { ctx.suspend(); return; }
    if (IOS) return setTimeout(afterMic, 400);
    if (on && !document.hidden) ctx.resume();
  },
  // Quieter while someone speaks.
  duck(quiet) { if (master) master.gain.setTargetAtTime(quiet ? 0.18 : 0.5, ctx.currentTime, 0.2); },
};

// iPhone pauses the music each time a voice plays, and lets it start again
// only on a touch: every touch (the joystick too) brings it back.
function wake() {
  if (ctx && on && !held && !document.hidden && ctx.state !== 'running') ctx.resume().catch(() => {});
}
for (const ev of ['touchstart', 'touchend', 'pointerdown', 'pointerup', 'keydown']) {
  window.addEventListener(ev, wake, { capture: true, passive: true });
}

// The music stops when the phone screen goes off or the app is hidden.
document.addEventListener('visibilitychange', () => {
  if (!ctx) return;
  if (document.hidden) ctx.suspend();
  else if (on) ctx.resume();
});
