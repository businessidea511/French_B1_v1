// Le Dossier Bruxelles — an investigation game to learn French, chapter by chapter.
import * as THREE from 'three';
import { makePerson, makeMarker } from './people.js';
import { UI, wait } from './ui.js';
import { t, translatePage, prefetch, setVars, setHelp, fill, lang, pickLanguage } from './i18n.js';
import { sfx, say, preload } from './speech.js';
import { music } from './music.js';
import { Confront, confrontTexts } from './confront.js';

const $ = (id) => document.getElementById(id);

// ---------- which chapter ----------
export const CHAPTERS = [1, 2];
const asked = Number(new URLSearchParams(location.search).get('ch') || localStorage.getItem('dossier_chapter') || 1);
const chId = CHAPTERS.includes(asked) ? asked : 1;
const ch = await import(`./dossier${chId}.js`);
const C = ch.CHAPTER;
const World = C.world === 'station' ? (await import('./station.js')).Station : (await import('./city.js')).City;

// ---------- device: older phones get a lighter picture ----------
const touch = navigator.maxTouchPoints > 0;
const memory = navigator.deviceMemory || 8;
const weak = memory <= 3 || (touch && (navigator.hardwareConcurrency || 8) <= 4);

// ---------- saved game ----------
const SAVE_KEY = C.saveKey;
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
// A few real lights where the story happens.
for (const [x, y, z, color] of C.lights.slice(0, weak ? 3 : C.lights.length)) {
  const l = new THREE.PointLight(color || '#ffb36b', 14, 13, 1.8);
  l.position.set(x, y, z);
  scene.add(l);
}

const city = new World(scene, { weak });
// Clues on the ground (others are given by the characters).
const clues = ch.CLUES.filter((w) => !w.given).map((w) => ({ word: w, c: city.addClue(w, w.x, w.z) }));

// ---------- characters ----------
const player = makePerson({ skin: '#c99a76', hair: '#1d1612', coat: '#4a3a2c', coatLong: true, pants: '#22252c', scarf: '#8c2f2f', bag: '#3a2a1e' }, { weak });
player.position.set(C.spawn[0], 0, C.spawn[1]);
player.rotation.y = C.spawn[2];
scene.add(player);
// The player always stands in a little light, even in the darkest corner,
// with a soft ring on the ground pointing where they walk.
const playerLight = new THREE.PointLight('#ffe2b8', 7, 7, 1.5);
playerLight.position.set(0, 2.8, 0.8);
player.add(playerLight);
const ringTex = (() => {
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const x = c.getContext('2d');
  const g = x.createRadialGradient(64, 64, 20, 64, 64, 62);
  g.addColorStop(0, 'rgba(255,226,170,0.0)');
  g.addColorStop(0.7, 'rgba(255,226,170,0.55)');
  g.addColorStop(1, 'rgba(255,226,170,0)');
  x.fillStyle = g;
  x.fillRect(0, 0, 128, 128);
  // A small arrow at the front: where the player is facing.
  x.fillStyle = 'rgba(255,226,170,0.9)';
  x.beginPath();
  x.moveTo(64, 124);
  x.lineTo(54, 106);
  x.lineTo(74, 106);
  x.fill();
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
})();
const feetRing = new THREE.Mesh(
  new THREE.PlaneGeometry(1.6, 1.6),
  new THREE.MeshBasicMaterial({ map: ringTex, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }),
);
feetRing.rotation.x = -Math.PI / 2;
feetRing.position.y = 0.03;
player.add(feetRing);

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
const places = C.places.map((pl) => {
  const marker = makeMarker(pl.symbol || '?', '#6fa8ff');
  marker.position.set(pl.x, pl.y || 2.4, pl.z);
  scene.add(marker);
  return { id: pl.id, x: pl.x, z: pl.z, marker, markerY: pl.y || 2.4 };
});
const talkables = [...Object.values(people), ...places];

// ---------- interface ----------
const ui = new UI();
translatePage();

function refresh() {
  setVars({ name: state.name, n: state.found.length, total: ch.CLUES.length });
  ui.objective(ch.objective(state));
  ui.counters(state.found.length, ch.CLUES.length);
  for (const p of talkables) p.marker.visible = !!ch.hasNews(p.id, state);
}
prefetch([...ch.allTexts(), ...confrontTexts(ch.BANKS), ch.LINES.caught, 'Continue', 'Chapter', 'Finished'], () => { translatePage(); refresh(); renderChapters(); });

// ---------- the men in grey ----------
let shake = 0;
let yaw = C.spawn[2];
const confront = new Confront({
  scene, player, city, ui, weak, banks: ch.BANKS, lines: ch.LINES,
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
    player.position.set(C.respawn[0], 0, C.respawn[1]);
    yaw = C.respawn[2];
    await wait(500);
    $('fade').classList.remove('on');
    ui.toast(ch.LINES.caught, 3800);
  },
});
let chief = null;
for (const a of C.agents) {
  if (a.chief && state.flags.done) continue;
  const agent = confront.addAgent(a.id, a.path, { guards: a.guards, chief: a.chief, look: a.look });
  if (a.chief) chief = agent;
}
confront.renderAlerts();

// Bring back a saved game: the clues found, and where the player was standing.
for (const { word, c } of clues) if (state.found.includes(word.key)) city.takeClue(c);
if (state.flags.done) city.gateOpen = true; // the platform stays open after the chapter
if (state.pos && city.walkable(state.pos[0], state.pos[1])) {
  player.position.set(state.pos[0], 0, state.pos[1]);
  yaw = state.pos[2];
  player.rotation.y = yaw;
}

// ---------- helpers given to the chapter ----------
const game = {
  ui,
  world: city,
  get state() { return state; },
  /** A clue given by a character (or found in a locker). */
  async give(key) {
    const word = ch.CLUES.find((c) => c.key === key);
    if (!word || state.found.includes(key)) return;
    state.found.push(key);
    save();
    refresh();
    await ui.wordFound(word);
  },
  save: () => { save(); refresh(); },
  confrontChief: () => confront.confront(chief),
  story: (words) => confront.story(words),
  finish() {
    const m = state.mistakes;
    $('doneStars').textContent = m <= 3 ? '★★★' : m <= 7 ? '★★☆' : '★☆☆';
    $('doneStats').textContent = `${t('Clues found')}: ${state.found.length} · ${t('Mistakes')}: ${m}`;
    renderChapters();
    $('done').querySelector('h2').textContent = t(`Chapter ${C.id} complete!`);
    $('done').hidden = false;
    ui.busy = true;
  },
};
$('doneReplay').onclick = () => { $('done').hidden = true; ui.busy = false; };

// ---------- screens ----------
// The chapters on the title screen (each has its own saved game).
function chapterSave(id) {
  try { return JSON.parse(localStorage.getItem(id === 1 ? 'dossier_save_v1' : `dossier_save_ch${id}`) || 'null'); } catch (_) { return null; }
}
const CHAPTER_NAMES = { 1: ['Chapitre 1 : Rue des Ombres', 'A1–A2'], 2: ['Chapitre 2 : La Gare du Midi', 'A2'] };
function renderChapters() {
  const list = $('chapterList');
  list.innerHTML = '';
  for (const id of CHAPTERS) {
    const b = document.createElement('button');
    const saved = chapterSave(id);
    b.className = 'chapter' + (id === chId ? ' on' : '');
    const [name, level] = CHAPTER_NAMES[id];
    b.innerHTML = `<span class="ch-name"></span><span class="ch-tag"></span>`;
    b.querySelector('.ch-name').textContent = name;
    b.querySelector('.ch-tag').textContent = saved?.flags?.done ? `✓ ${t('Finished')}` : level;
    b.onclick = () => {
      if (id === chId) return;
      localStorage.setItem('dossier_chapter', String(id));
      location.href = location.pathname + (location.search.includes('debug') ? '?debug' : '');
    };
    list.append(b);
  }
  $('doneNext').textContent = C.next;
  $('doneIcon').textContent = C.doneIcon;
}
renderChapters();
if (state.name || chapterSave(1)?.name) $('playerName').value = state.name || chapterSave(1).name;
if (state.introSeen) {
  $('playBtn').textContent = t('Continue');
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
  localStorage.setItem('dossier_chapter', String(chId));
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
  if (!state.flags.started) {
    state.flags.started = true;
    save();
    ui.toast(ch.objective(state), 3800);
  }
}

// The case file: the clues, or Élise's letter when it can be read.
$('bookBtn').onclick = async () => {
  if (ui.busy) return;
  if (ch.onBook && (await ch.onBook(game))) return refresh();
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
  if (ch.afterClue) await ch.afterClue(game);
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
const ray = new THREE.Raycaster();
const head = new THREE.Vector3();
const toCam = new THREE.Vector3();

/** True when a building stands between this point (the player's head by default) and the camera spot. */
function hidden(spot, from = player.position) {
  if (!city.occluders?.length) return false;
  head.set(from.x, from.y + 1.5, from.z);
  toCam.subVectors(spot, head);
  const dist = toCam.length();
  ray.set(head, toCam.normalize());
  ray.far = dist;
  return ray.intersectObjects(city.occluders, false).length > 0;
}

/**
 * The camera behind the player; if a building is in the way, higher and
 * more from above, so the player and the road always stay in sight.
 */
// The last view, straight from above, can never be inside a building.
const VIEWS = [[6.5, 7.5], [9.5, 4.6], [12.5, 2], [13, 0.05]];
let viewIndex = 0;
let viewCheck = 0;
function followSpot(p, k, dt, focus = p) {
  viewCheck -= dt;
  if (viewCheck <= 0) {
    viewCheck = 0.15;
    let chosen = VIEWS.length - 1;
    for (let i = 0; i < VIEWS.length - 1; i++) {
      camTarget.set(focus.x, p.y + VIEWS[i][0] * k, focus.z + VIEWS[i][1] * k);
      if (!hidden(camTarget, focus)) { chosen = i; break; }
    }
    viewIndex = chosen;
  }
  const [h, back] = VIEWS[viewIndex];
  camTarget.set(focus.x, p.y + h * k, focus.z + back * k);
  lookWant.set(focus.x, p.y + 1.2, focus.z - (viewIndex ? (viewIndex === VIEWS.length - 1 ? 0.3 : 0.8) : 2));
}
const mid = new THREE.Vector3();

// The guide: a gold arrow at the player's feet, pointing to the next goal
// (someone with something to say, or the nearest clue).
const guide = (() => {
  const shape = new THREE.Shape();
  shape.moveTo(0, 0.55);
  shape.lineTo(0.32, 0);
  shape.lineTo(0.12, 0.06);
  shape.lineTo(0.12, -0.35);
  shape.lineTo(-0.12, -0.35);
  shape.lineTo(-0.12, 0.06);
  shape.lineTo(-0.32, 0);
  shape.closePath();
  const m = new THREE.Mesh(
    new THREE.ShapeGeometry(shape),
    new THREE.MeshBasicMaterial({ color: '#ffcf6b', transparent: true, opacity: 0.85, depthWrite: false, blending: THREE.AdditiveBlending }),
  );
  m.rotation.x = -Math.PI / 2;
  const holder = new THREE.Group();
  holder.add(m);
  scene.add(holder);
  return holder;
})();
function goal() {
  const p = player.position;
  let best = null;
  let bestD = Infinity;
  const consider = (x, z) => {
    const d = Math.hypot(x - p.x, z - p.z);
    if (d < bestD) { bestD = d; best = { x, z, d }; }
  };
  for (const t of talkables) if (t.marker.visible) consider(t.x, t.z);
  if (!best) for (const { word, c } of clues) if (!c.taken) consider(word.x, word.z);
  return best;
}
function updateGuide(dt) {
  const g = playing && !ui.busy && !cinema ? goal() : null;
  guide.visible = !!g && g.d > 2.6;
  if (!guide.visible) return;
  const p = player.position;
  const a = Math.atan2(g.x - p.x, g.z - p.z);
  guide.position.set(p.x + Math.sin(a) * 1.25, p.y + 0.06, p.z + Math.cos(a) * 1.25);
  guide.rotation.y = a;
  guide.children[0].material.opacity = 0.55 + Math.sin(city.time * 4) * 0.3;
}
function updateCamera(dt) {
  const portrait = innerWidth < innerHeight;
  const k = portrait ? 1.25 : 1;
  const p = player.position;
  if (cinema) {
    // A slow crane shot down the middle of the street, under the rain.
    cinema.t += dt;
    const k2 = Math.min(cinema.t, 24);
    const [cx, cy, cz, dz, lx, ly, lz] = city.cinema || [0, 13, 46, -0.9, 0, 3, 4];
    camTarget.set(cx + Math.sin(cinema.t * 0.15) * 1.5, cy - k2 * 0.25, cz + k2 * dz);
    lookWant.set(lx, ly, lz + k2 * dz * 0.55);
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
    // A wall in the way of the side view: the usual views, around both of them.
    mid.set(mx, p.y, mz);
    if (hidden(camTarget, mid)) followSpot(p, k, 1, mid);
  } else {
    followSpot(p, k, dt);
  }
  if (city.clampCamera) city.clampCamera(camTarget);
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
camera.position.set(...(city.cinema ? city.cinema.slice(0, 3) : [0, 13, 46]));
lookAt.set(...(city.cinema ? city.cinema.slice(4, 7) : [0, 3, 4]));
let firstFrame = true;
let savePosIn = 2;
function frame() {
  requestAnimationFrame(frame);
  step(Math.min(clock.getDelta(), 0.05));
}

function step(dt) {
  city.update(dt, cinema ? camera.position : player.position);
  movePlayer(dt);
  confront.update(dt);
  for (const p of Object.values(people)) p.char.userData.animate(dt, 0, talking === p);
  for (const p of talkables) if (p.marker.visible) p.marker.position.y = (p.char ? 2.25 / p.char.scale.y : p.markerY) + Math.sin(city.time * 3) * 0.08;
  // Remember where the player stands (every 2 seconds), to continue from there.
  savePosIn -= dt;
  if (playing && savePosIn <= 0) {
    savePosIn = 2;
    const pos = [+player.position.x.toFixed(2), +player.position.z.toFixed(2), +yaw.toFixed(2)];
    if (!state.pos || pos.some((v, i) => Math.abs(v - state.pos[i]) > 0.05)) { state.pos = pos; save(); }
  }

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

  updateGuide(dt);
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
  window.quest = { player, confront, city, camera, ch, step: (n = 20) => { for (let i = 0; i < n; i++) step(0.05); }, get state() { return state; }, talkTo: (id) => talkTo(talkables.find((p) => p.id === id)) };
}
