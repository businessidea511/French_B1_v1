// Le Dossier Bruxelles — an investigation game to learn French (chapter 1).
import * as THREE from 'three';
import { City } from './city.js';
import { makePerson, makeMarker } from './people.js';
import { UI, wait } from './ui.js';
import { t, translatePage, prefetch, setVars, setHelp, fill, lang, pickLanguage } from './i18n.js';
import { sfx, say, preload } from './speech.js';
import { music } from './music.js';
import { Confront, confrontTexts } from './confront.js';
import * as ch from './dossier1.js';

const $ = (id) => document.getElementById(id);

// ---------- device: older phones get a lighter picture ----------
const touch = navigator.maxTouchPoints > 0;
const memory = navigator.deviceMemory || 8;
const weak = memory <= 3 || (touch && (navigator.hardwareConcurrency || 8) <= 4);

// ---------- saved game ----------
const SAVE_KEY = 'dossier_save_v1';
const fresh = () => ({ name: '', found: [], flags: {}, mistakes: 0, introSeen: false, beaten: [] });
let state = fresh();
try { state = { ...fresh(), ...JSON.parse(localStorage.getItem(SAVE_KEY) || '{}') }; } catch (_) {}
const save = () => { try { localStorage.setItem(SAVE_KEY, JSON.stringify(state)); } catch (_) {} };

// ---------- renderer: night, wet, foggy ----------
const canvas = $('scene');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: !weak, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(devicePixelRatio, weak ? 1 : 1.6));
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.25;
renderer.shadowMap.enabled = !weak;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(55, 1, 0.3, 320);

scene.add(new THREE.HemisphereLight('#5a6c94', '#1a1714', 0.9));
const moon = new THREE.DirectionalLight('#9fb4ff', 0.55);
moon.position.set(-25, 40, 18);
moon.castShadow = !weak;
moon.shadow.mapSize.set(1024, 1024);
Object.assign(moon.shadow.camera, { left: -30, right: 30, top: 30, bottom: -30, near: 1, far: 120 });
moon.shadow.bias = -0.0008;
scene.add(moon);
scene.add(moon.target);
// A few real warm lights where the story happens.
const warm = [[-6, 3, 26.4], [6, 3, 21], [-12, 3, -17.5], [0, 3.5, -38], [-4.4, 4, 6], [4.4, 4, -9]];
for (const [x, y, z] of warm.slice(0, weak ? 3 : warm.length)) {
  const l = new THREE.PointLight('#ffb36b', 14, 13, 1.8);
  l.position.set(x, y, z);
  scene.add(l);
}

const city = new City(scene, { weak });
const clues = ch.CLUES.map((w) => ({ word: w, c: city.addClue(w, w.x, w.z) }));

// ---------- characters ----------
const player = makePerson({ skin: '#c99a76', hair: '#1d1612', coat: '#4a3a2c', coatLong: true, pants: '#22252c', scarf: '#8c2f2f', bag: '#3a2a1e' }, { weak });
player.position.set(-1.2, 0, 36);
player.rotation.y = Math.PI;
scene.add(player);

const people = {};
for (const [id, p] of Object.entries(ch.PEOPLE)) {
  const c = makePerson(p.look, { weak });
  c.position.set(p.pos[0], city.heightAt(p.pos[0], p.pos[1]), p.pos[1]);
  c.rotation.y = p.face;
  const marker = makeMarker('!', '#ffb84d');
  marker.position.y = 2.25 / (p.look.height || 1);
  c.add(marker);
  scene.add(c);
  city.colliders.push({ x: p.pos[0], z: p.pos[1], r: 0.55 });
  people[id] = { id, char: c, marker, face: p.face, x: p.pos[0], z: p.pos[1] };
}
const metroMarker = makeMarker('?', '#6fa8ff');
metroMarker.position.set(0, 2.4, -39.6);
scene.add(metroMarker);
const talkables = [...Object.values(people), { id: 'metro', x: 0, z: -39.6, marker: metroMarker }];

// ---------- interface ----------
const ui = new UI();
translatePage();

function refresh() {
  setVars({ name: state.name, n: state.found.length, total: ch.CLUES.length });
  ui.objective(ch.objective(state));
  ui.counters(state.found.length, ch.CLUES.length);
  for (const p of talkables) p.marker.visible = ch.hasNews(p.id, state);
}
prefetch([...ch.allTexts(), ...confrontTexts()], () => { translatePage(); refresh(); });

// ---------- the men in grey ----------
let shake = 0;
let yaw = Math.PI;
const confront = new Confront({
  scene, player, city, ui, weak,
  get state() { return state; },
  save: () => { save(); refresh(); },
  hurt: () => {
    $('hurt').classList.add('on');
    shake = 0.25;
    setTimeout(() => $('hurt').classList.remove('on'), 350);
  },
  caught: async () => {
    $('fade').classList.add('on');
    await wait(900);
    player.position.set(4.6, 0.14, 2.6);
    yaw = -Math.PI / 2;
    await wait(500);
    $('fade').classList.remove('on');
    ui.toast('You wake up in front of the hotel… They let you go, for now.', 3800);
  },
});
confront.addAgent('ruelle', [[-12.4, 10]], { guards: 'carnet' });
confront.addAgent('place', [[-15, -15.6], [-15, -24], [-8, -24]], { guards: 'lettre' });
confront.addAgent('rue', [[-2.4, 3], [-2.4, -9]]);
const chief = state.flags.done ? null : confront.addAgent('chef', [[0, -37.8]], { chief: true });
confront.renderAlerts();

// Bring back a saved game.
for (const { word, c } of clues) if (state.found.includes(word.key)) city.takeClue(c);

// ---------- helpers given to the chapter ----------
const game = {
  ui,
  get state() { return state; },
  save: () => { save(); refresh(); },
  confrontChief: () => confront.confront(chief),
  story: (words) => confront.story(words),
  finish() {
    const m = state.mistakes;
    $('doneStars').textContent = m <= 3 ? '★★★' : m <= 7 ? '★★☆' : '★☆☆';
    $('doneStats').textContent = `${t('Clues found')}: ${state.found.length} · ${t('Mistakes')}: ${m}`;
    $('done').hidden = false;
    ui.busy = true;
  },
};
$('doneReplay').onclick = () => { $('done').hidden = true; ui.busy = false; };

// ---------- screens ----------
if (state.name) {
  $('playerName').value = state.name;
  $('resetBtn').hidden = false;
}
$('langPick').value = lang;
$('langPick').onchange = (e) => pickLanguage(e.target.value);
$('musicBtn').textContent = music.on ? '🎵' : '🔇';
$('musicBtn').onclick = () => { $('musicBtn').textContent = music.toggle() ? '🎵' : '🔇'; };
$('resetBtn').onclick = () => { localStorage.removeItem(SAVE_KEY); location.reload(); };
$('playBtn').onclick = async () => {
  sfx.unlock();
  music.start();
  state.name = ($('playerName').value.trim() || 'Alex').slice(0, 16);
  save();
  $('title').hidden = true;
  if (!state.introSeen) await playStory();
  start();
};

let cinema = null;
async function playStory() {
  setVars({ name: state.name });
  preload(ch.STORY.map((s, i) => ({ text: fill(s.fr), voice: i === 0 ? 'charline' : 'denise' })));
  $('story').hidden = false;
  cinema = { t: 0 };
  for (const [i, slide] of ch.STORY.entries()) {
    $('storyEmoji').textContent = slide.emoji;
    $('storyFr').textContent = fill(slide.fr);
    setHelp($('storyHelp'), slide.en);
    say(fill(slide.fr), { voice: i === 0 ? 'charline' : 'denise', speed: 0.95 });
    if (i === 3) cinema = null; // the camera comes down to the street
    await new Promise((r) => { $('storyNext').onclick = r; });
  }
  cinema = null;
  $('story').hidden = true;
  state.introSeen = true;
  save();
}

let playing = false;
function start() {
  playing = true;
  $('hud').hidden = false;
  refresh();
  if (!state.flags.lambert) ui.toast("Find number 12, rue des Ombres: Élise's building.", 3800);
}

// The case file: the clues, or Élise's letter when it can be read.
$('bookBtn').onclick = async () => {
  if (ui.busy) return;
  if (await ch.decode(game)) return refresh();
  ui.openBook(ch.CLUES, state.found);
};

// ---------- talking ----------
let nearby = null;
let talking = null;
async function talkTo(target) {
  if (!target || ui.busy) return;
  $('talkBtn').hidden = true;
  if (target.char) target.char.lookAt(player.position.x, target.char.position.y, player.position.z);
  player.lookAt(target.x, player.position.y, target.z);
  talking = target;
  await ch.interact(target.id, game);
  talking = null;
  if (target.char) target.char.rotation.y = target.face;
  refresh();
}
$('talkBtn').onclick = () => talkTo(nearby);
addEventListener('keydown', (e) => {
  if ([' ', 'e', 'enter'].includes(e.key.toLowerCase()) && playing && !ui.busy && nearby) {
    e.preventDefault();
    talkTo(nearby);
  }
});

// ---------- clues ----------
const lockTold = new Set();
async function collect(entry) {
  city.takeClue(entry.c);
  state.found.push(entry.word.key);
  save();
  refresh();
  await ui.wordFound(entry.word);
  if (state.found.length === ch.CLUES.length && state.flags.samir) await ch.decode(game);
  refresh();
}

// ---------- movement ----------
const SPEED = 4.6;
function blocked(x, z) {
  if (!city.walkable(x, z)) return true;
  for (const c of city.colliders) if ((x - c.x) ** 2 + (z - c.z) ** 2 < (c.r + 0.35) ** 2) return true;
  return false;
}

function movePlayer(dt) {
  const d = playing && !ui.busy ? ui.direction() : { x: 0, y: 0 };
  const speed = Math.hypot(d.x, d.y);
  if (speed > 0.05) {
    const step = SPEED * dt * speed;
    const nx = player.position.x + (d.x / speed) * step;
    const nz = player.position.z + (d.y / speed) * step;
    if (!blocked(nx, player.position.z)) player.position.x = nx;
    if (!blocked(player.position.x, nz)) player.position.z = nz;
    const want = Math.atan2(d.x, d.y);
    const diff = Math.atan2(Math.sin(want - yaw), Math.cos(want - yaw));
    yaw += diff * Math.min(1, dt * 10);
    player.rotation.y = yaw;
  } else if (!talking) {
    player.rotation.y = yaw;
  }
  const h = city.heightAt(player.position.x, player.position.z);
  player.position.y += (h - player.position.y) * Math.min(1, dt * 12);
  player.userData.animate(dt, speed, false);
}

// ---------- camera: low and close, like a film ----------
const camTarget = new THREE.Vector3();
const lookAt = new THREE.Vector3();
const lookWant = new THREE.Vector3();
function updateCamera(dt) {
  const portrait = innerWidth < innerHeight;
  const k = portrait ? 1.25 : 1;
  const p = player.position;
  if (cinema) {
    cinema.t += dt;
    const a = 1.2 + cinema.t * 0.08;
    camTarget.set(Math.cos(a) * 30, 16, 6 + Math.sin(a) * 30);
    lookWant.set(0, 2, 4);
  } else if (talking || confront.active) {
    const o = talking || { x: confront.active.body.position.x, z: confront.active.body.position.z };
    const mx = (p.x + o.x) / 2;
    const mz = (p.z + o.z) / 2;
    let dx = o.x - p.x;
    let dz = o.z - p.z;
    const len = Math.hypot(dx, dz) || 1;
    dx /= len;
    dz /= len;
    let px = dz;
    let pz = -dx;
    if (pz < 0) { px = -px; pz = -pz; }
    camTarget.set(mx + px * 4.2 * k - dx * 1.2, p.y + 2.4 * k, mz + pz * 4.2 * k - dz * 1.2);
    lookWant.set(mx, p.y + (portrait ? 0.4 : 1.2), mz);
  } else {
    camTarget.set(p.x, p.y + 6.5 * k, p.z + 7.5 * k);
    lookWant.set(p.x, p.y + 1.2, p.z - 2);
  }
  camera.position.lerp(camTarget, Math.min(1, dt * (cinema ? 1.2 : 3.5)));
  lookAt.lerp(lookWant, Math.min(1, dt * 5));
  camera.lookAt(lookAt);
  if (shake > 0) {
    shake -= dt;
    camera.position.x += (Math.random() - 0.5) * shake;
    camera.position.y += (Math.random() - 0.5) * shake;
  }
}

function resize() {
  renderer.setSize(innerWidth, innerHeight, false);
  camera.aspect = innerWidth / innerHeight;
  camera.fov = innerWidth < innerHeight ? 64 : 55;
  camera.updateProjectionMatrix();
}
addEventListener('resize', resize);
resize();

// ---------- loop ----------
const clock = new THREE.Clock();
camera.position.set(20, 16, 30);
lookAt.set(0, 2, 4);
let firstFrame = true;
function frame() {
  requestAnimationFrame(frame);
  const dt = Math.min(clock.getDelta(), 0.05);
  city.update(dt, cinema ? camera.position : player.position);
  movePlayer(dt);
  confront.update(dt);
  for (const p of Object.values(people)) p.char.userData.animate(dt, 0, talking === p);
  for (const p of talkables) if (p.marker.visible) p.marker.position.y = (p.char ? 2.25 / p.char.scale.y : 2.4) + Math.sin(city.time * 3) * 0.08;

  if (playing && !ui.busy) {
    for (const entry of clues) {
      if (entry.c.taken) continue;
      if (Math.hypot(player.position.x - entry.word.x, player.position.z - entry.word.z) < 1.3) {
        if (entry.c.locked) {
          if (!lockTold.has(entry.word.key)) { lockTold.add(entry.word.key); ui.toast('A man in grey guards this clue. Get past him first.', 2800); }
        } else collect(entry);
      }
    }
    const man = confront.spotted();
    if (man) confront.confront(man);
    nearby = null;
    let best = 2.4;
    for (const p of talkables) {
      const d = Math.hypot(player.position.x - p.x, player.position.z - p.z);
      if (d < best) { best = d; nearby = p; }
    }
    $('talkBtn').hidden = !nearby;
  } else {
    $('talkBtn').hidden = true;
  }

  updateCamera(dt);
  renderer.render(scene, camera);
  if (firstFrame) {
    firstFrame = false;
    $('loading').classList.add('gone');
  }
}
frame();

// Testing only (…/game/?debug).
if (new URLSearchParams(location.search).has('debug')) {
  window.quest = { player, confront, city, get state() { return state; }, talkTo: (id) => talkTo(talkables.find((p) => p.id === id)) };
}
