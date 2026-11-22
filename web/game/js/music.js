// Background music made on the fly with the Web Audio API (no files):
// a calm adventure tune while exploring, a fast one during fights.

let ctx = null;
let master = null;
let timer = null;
let step = 0;
let mode = 'explore';
let on = localStorage.getItem('quest_music') !== '0';

const NOTE = (n) => 440 * Math.pow(2, (n - 69) / 12);

// Chords as MIDI notes. Explore: C – Am – F – G. Fight: Am – F – G – E.
const SONGS = {
  explore: { bpm: 92, chords: [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]], bass: [36, 33, 29, 31], drums: false },
  fight: { bpm: 132, chords: [[57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 56, 59]], bass: [33, 29, 31, 28], drums: true },
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
  const t = ctx.currentTime + 0.1;
  const bar = Math.floor(step / 8) % 4;
  const i = step % 8;
  const chord = song.chords[bar];
  if (i === 0) {
    for (const n of chord) voice(NOTE(n), t, eighth * 8, 'sine', 0.05);
    voice(NOTE(song.bass[bar]), t, eighth * 3, 'triangle', 0.16);
  }
  if (i === 4) voice(NOTE(song.bass[bar] + 7), t, eighth * 2, 'triangle', 0.1);
  // Arpeggio on top.
  const arp = [0, 1, 2, 1, 2, 0, 1, 2][i];
  voice(NOTE(chord[arp] + 12), t, eighth * 1.6, 'triangle', mode === 'fight' ? 0.05 : 0.035);
  if (song.drums) {
    if (i % 4 === 0) kick(t);
    hat(t, i % 2 ? 0.03 : 0.05);
  }
  step++;
  timer = setTimeout(tick, eighth * 1000);
}

function begin() {
  if (!on) return;
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = 0.5;
    master.connect(ctx.destination);
  }
  if (ctx.state === 'suspended') ctx.resume();
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
  // Quieter while someone speaks.
  duck(quiet) { if (master) master.gain.setTargetAtTime(quiet ? 0.18 : 0.5, ctx.currentTime, 0.2); },
};

// The music stops when the phone screen goes off or the app is hidden.
document.addEventListener('visibilitychange', () => {
  if (!ctx) return;
  if (document.hidden) ctx.suspend();
  else if (on) ctx.resume();
});
