// La Quête des Mots Perdus — a 3D adventure to learn French (chapter 1: A1).
import * as THREE from 'three';
import { World } from './world.js';
import { makeCharacter, makeParrot, makeWitch, makeMarker } from './characters.js';
import { UI, wait } from './ui.js';
import { t, translatePage, prefetch, setVars, setHelp, fill, lang, pickLanguage } from './i18n.js';
import { sfx, say, preload } from './speech.js';
import { music } from './music.js';
import { Combat, WANDS, combatTexts } from './combat.js';
import * as ch1 from './chapter1.js';

const $ = (id) => document.getElementById(id);

// ---------- device: older phones get a lighter picture ----------
const touch = navigator.maxTouchPoints > 0;
const memory = navigator.deviceMemory || 8;
const weak = memory <= 3 || (touch && (navigator.hardwareConcurrency || 8) <= 4);

// ---------- saved game ----------
const SAVE_KEY = 'quest_save_v1';
const fresh = () => ({ name: '', found: [], flags: {}, coins: 0, mistakes: 0, introSeen: false, wands: [], wand: null, beaten: [] });
let state = fresh();
try { state = { ...fresh(), ...JSON.parse(localStorage.getItem(SAVE_KEY) || '{}') }; } catch (_) {}
const save = () => { try { localStorage.setItem(SAVE_KEY, JSON.stringify(state)); } catch (_) {} };

// ---------- renderer, scene, camera ----------
const canvas = $('scene');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: !weak, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(devicePixelRatio, weak ? 1 : 1.75));
renderer.shadowMap.enabled = !weak;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(50, 1, 0.5, 500);

const hemi = new THREE.HemisphereLight('#d6ecff', '#7a9a52', 0.95);
scene.add(hemi);
const sun = new THREE.DirectionalLight('#fff1d6', 1.6);
sun.position.set(30, 50, 22);
sun.castShadow = !weak;
sun.shadow.mapSize.set(2048, 2048);
Object.assign(sun.shadow.camera, { left: -48, right: 48, top: 48, bottom: -48, near: 1, far: 140 });
sun.shadow.bias = -0.0006;
scene.add(sun);

// Keep crystals, people and paths free of trees.
const clear = [
  ...ch1.WORDS.map((w) => [w.x, w.z, 3]),
  ...Object.values(ch1.PEOPLE).map((p) => [p.pos[0], p.pos[1], 3]),
  [-22, 30, 5], [-10, 1, 6],
];
const world = new World(scene, { weak, clear });
const crystals = ch1.WORDS.map((w) => ({ word: w, c: world.addCrystal(w, w.x, w.z) }));

// ---------- characters ----------
const player = makeCharacter({ skin: '#d9a77a', shirt: '#2ec4b6', pants: '#2b3550', hair: '#2b1d14', scarf: '#e8443a', backpack: '#a8733f' }, { weak });
player.position.set(-22, 0.28, 41.5);
player.rotation.y = Math.PI;
scene.add(player);

const people = {};
for (const [id, p] of Object.entries(ch1.PEOPLE)) {
  const c = makeCharacter(p.look, { weak });
  c.position.set(p.pos[0], world.heightAt(p.pos[0], p.pos[1]), p.pos[1]);
  c.rotation.y = p.face;
  const marker = makeMarker('!', '#ff9f43');
  marker.position.y = 3.1 / (p.look.scale || 1);
  c.add(marker);
  scene.add(c);
  world.colliders.push({ x: p.pos[0], z: p.pos[1], r: 0.8 });
  people[id] = { id, char: c, marker, face: p.face, x: p.pos[0], z: p.pos[1] };
}
const chestMarker = makeMarker('?', '#c34dff');
chestMarker.position.set(22, 2.6, -6.5);
scene.add(chestMarker);
const talkables = [...Object.values(people), { id: 'chest', x: 22, z: -6.5, marker: chestMarker }];

const parrot = makeParrot({ weak });
parrot.visible = false;
scene.add(parrot);

// ---------- interface ----------
const ui = new UI();
translatePage();

function refresh() {
  setVars({ name: state.name, n: state.found.length, total: ch1.WORDS.length });
  ui.objective(ch1.objective(state));
  ui.counters(state.found.length, ch1.WORDS.length, state.coins);
  for (const p of talkables) p.marker.visible = ch1.hasNews(p.id, state);
}

prefetch([...ch1.allTexts(), ...combatTexts()], () => {
  translatePage();
  refresh();
});

// Bring back a saved game.
function restoreSaved() {
  for (const key of state.found) world.target[key] = 1;
  world.restore(null, state.found.length, ch1.WORDS.length);
  world.restoreInstantly();
  for (const { word, c } of crystals) {
    if (state.found.includes(word.key)) { c.taken = true; c.group.visible = false; }
  }
  if (state.flags.bridge) world.openBridge();
  if (state.flags.hugo) parrot.visible = true;
  if (state.flags.chest) { world.chestOpening = 0.999; }
}
restoreSaved();

// ---------- Morgane's shadows ----------
const combat = new Combat({
  scene, player, world, ui,
  get state() { return state; },
  save: () => { save(); refresh(); },
  hurt: () => {
    $('hurt').classList.add('on');
    shake = 0.35;
    setTimeout(() => $('hurt').classList.remove('on'), 350);
  },
  respawn: async () => {
    $('hurt').classList.add('on');
    await wait(500);
    player.position.set(-10, 0, 5.2);
    $('hurt').classList.remove('on');
    ui.toast('You fell… The fountain gives you your strength back.', 3200);
  },
});
let shake = 0;
combat.addShadow('tuto', 'mots', -18.5, 22);
combat.addShadow('arbre', 'mots', -23.2, -3, { guards: 'arbre' });
combat.addShadow('maison', 'mots', -13.5, -7.5, { guards: 'maison' });
combat.addShadow('chat', 'nombres', -5.5, -8, { guards: 'chat' });
combat.addShadow('fleur', 'nombres', -23.5, 15.5, { guards: 'fleur' });
combat.addShadow('est1', 'etre', 15, -6.5);
combat.addShadow('est2', 'etre', 18.5, -1.5);
if (!state.flags.chest) combat.addShadow('boss', 'etre', 22, -10.5, { boss: true });
const sleeperTold = new Set();
const lockTold = new Set();

// ---------- game helpers given to the chapter ----------
const game = {
  ui,
  world,
  get state() { return state; },
  save: () => { save(); refresh(); },
  coinSound: () => sfx.coin(),
  giveWand(type) {
    if (!state.wands.includes(type)) state.wands.push(type);
    state.wand = type;
    save();
    combat.renderHud();
    sfx.open();
    ui.toast(`${WANDS[type].icon} ${t('New wand!')} ${WANDS[type].name}`, 3000);
  },
  fightBoss: () => combat.fight(combat.shadows.find((s) => s.boss)),
  finalSpell: (words) => combat.sentence(words),
  showParrot: () => { parrot.visible = true; parrot.position.copy(player.position).add(new THREE.Vector3(0, 4, 0)); },
  async openChest() {
    world.openChest();
    sfx.open();
    await wait(1600);
    ui.toast('A piece of the treasure map!', 3000);
    await wait(1200);
  },
  async showWitch(talk) {
    const witch = makeWitch({ weak });
    witch.position.set(22, 0, -10.5);
    witch.lookAt(player.position.x, 0, player.position.z);
    witch.scale.setScalar(0.01);
    scene.add(witch);
    sfx.dark();
    witches.push(witch);
    for (let i = 0; i <= 20; i++) { witch.scale.setScalar(i / 20); await wait(25); }
    await talk();
    for (let i = 20; i >= 0; i--) { witch.scale.setScalar(Math.max(0.01, i / 20)); await wait(25); }
    scene.remove(witch);
    witches.splice(witches.indexOf(witch), 1);
  },
  finish() {
    const m = state.mistakes;
    $('doneStars').textContent = m <= 2 ? '⭐⭐⭐' : m <= 5 ? '⭐⭐☆' : '⭐☆☆';
    $('doneStats').textContent = `${t('Words found')}: ${state.found.length} · ${t('Mistakes')}: ${m}`;
    $('done').hidden = false;
    ui.busy = true;
  },
};
const witches = [];
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
$('resetBtn').onclick = () => {
  localStorage.removeItem(SAVE_KEY);
  location.reload();
};
$('playBtn').onclick = async () => {
  sfx.unlock();
  music.start();
  state.name = ($('playerName').value.trim() || 'Explorateur').slice(0, 16);
  save();
  $('title').hidden = true;
  if (!state.introSeen) await playStory();
  start();
};

async function playStory() {
  setVars({ name: state.name });
  preload(ch1.STORY.map((s) => ({ text: fill(s.fr) })));
  $('story').hidden = false;
  cinema = { t: 0 };
  world.setAllColors(1); // the island as it was: full of colours
  let witch = null;
  for (const [i, slide] of ch1.STORY.entries()) {
    $('storyEmoji').textContent = slide.emoji;
    $('storyFr').textContent = fill(slide.fr);
    setHelp($('storyHelp'), slide.en);
    say(fill(slide.fr), { rate: 0.9 });
    if (i === 1) {
      witch = makeWitch({ weak });
      witch.scale.setScalar(2.4);
      witch.position.set(-8, 0, 2);
      scene.add(witch);
      witches.push(witch);
      sfx.dark();
    }
    if (i === 2) {
      // Morgane takes the words: the colours drain away.
      world.drainColors();
      sfx.dark();
    }
    if (i === 3 && witch) {
      scene.remove(witch);
      witches.splice(witches.indexOf(witch), 1);
      cinema = null; // the camera flies down to the boat
    }
    await new Promise((r) => { $('storyNext').onclick = r; });
  }
  cinema = null;
  $('story').hidden = true;
  state.introSeen = true;
  save();
}
let cinema = null;

let playing = false;
function start() {
  playing = true;
  $('hud').hidden = false;
  refresh();
  if (!state.flags.hugo) ui.toast('Talk to Captain Hugo on the dock.', 3500);
  combat.renderHud();
}

$('bookBtn').onclick = () => ui.openBook(ch1.WORDS, state.found);

// ---------- talking ----------
let nearby = null;
async function talkTo(target) {
  if (!target || ui.busy) return;
  $('talkBtn').hidden = true;
  if (target.char) target.char.lookAt(player.position.x, target.char.position.y, player.position.z);
  player.lookAt(target.x, player.position.y, target.z);
  talking = target;
  await ch1.interact(target.id, game);
  talking = null;
  if (target.char) target.char.rotation.y = target.face;
  refresh();
}
let talking = null;
$('talkBtn').onclick = () => talkTo(nearby);
addEventListener('keydown', (e) => {
  if ([' ', 'e', 'enter'].includes(e.key.toLowerCase()) && playing && !ui.busy && nearby) {
    e.preventDefault();
    talkTo(nearby);
  }
});

// ---------- crystals ----------
async function collect(entry) {
  const { word, c } = entry;
  world.takeCrystal(c);
  state.found.push(word.key);
  world.restore(word.key, state.found.length, ch1.WORDS.length);
  save();
  refresh();
  await ui.wordFound(word);
  if (state.found.length === ch1.WORDS.length) {
    ui.toast(state.flags.bridge
      ? 'All the words are found! Open the chest across the bridge.'
      : 'All the words are found! Now cross the bridge to the chest.', 3500);
  }
}

// ---------- movement ----------
const SPEED = 6.2;
const camOffset = new THREE.Vector3(0, 11, 12.5);
const camTarget = new THREE.Vector3();
let yaw = Math.PI;

function blocked(x, z) {
  if (!world.walkable(x, z)) return true;
  for (const c of world.colliders) {
    if ((x - c.x) ** 2 + (z - c.z) ** 2 < (c.r + 0.45) ** 2) return true;
  }
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
    let diff = want - yaw;
    diff = Math.atan2(Math.sin(diff), Math.cos(diff));
    yaw += diff * Math.min(1, dt * 12);
    player.rotation.y = yaw;
  } else if (!talking) {
    player.rotation.y = yaw;
  }
  const h = world.heightAt(player.position.x, player.position.z);
  player.position.y += (h - player.position.y) * Math.min(1, dt * 12);
  player.userData.animate(dt, speed, false);
  return speed;
}

const lookAt = new THREE.Vector3();
const lookWant = new THREE.Vector3();
function updateCamera(dt) {
  const portrait = innerWidth < innerHeight;
  const k = portrait ? 1.3 : 1;
  if (talking) {
    // In a conversation: from the side, both faces visible above the dialogue box.
    const mx = (player.position.x + talking.x) / 2;
    const mz = (player.position.z + talking.z) / 2;
    let dx = talking.x - player.position.x;
    let dz = talking.z - player.position.z;
    const len = Math.hypot(dx, dz) || 1;
    dx /= len;
    dz /= len;
    let px = dz;
    let pz = -dx;
    if (pz < 0) { px = -px; pz = -pz; } // stay on the south side, like the usual view
    camTarget.set(mx + px * 7 * k - dx * 1.5, player.position.y + 4.5 * k, mz + pz * 7 * k - dz * 1.5);
    lookWant.set(mx, player.position.y + (portrait ? -0.6 : 0.3), mz);
  } else {
    camTarget.set(player.position.x + camOffset.x, player.position.y + camOffset.y * k, player.position.z + camOffset.z * k);
    lookWant.set(player.position.x, player.position.y + 1.2, player.position.z - 1);
  }
  if (cinema) {
    cinema.t += dt;
    const a = 0.6 + cinema.t * 0.12;
    camTarget.set(-6 + Math.cos(a) * 46, 26, 2 + Math.sin(a) * 46);
    lookWant.set(-6, 0, 2);
  } else if (combat.active) {
    // In a fight: see both the player and the shadow.
    const f = combat.active.group.position;
    const mx = (player.position.x + f.x) / 2;
    const mz = (player.position.z + f.z) / 2;
    camTarget.set(mx, player.position.y + 9 * k, mz + 10 * k);
    lookWant.set(mx, player.position.y + (portrait ? -1.5 : 0.5), mz);
  }
  camera.position.lerp(camTarget, Math.min(1, dt * (cinema ? 1.5 : 4)));
  lookAt.lerp(lookWant, Math.min(1, dt * 5));
  camera.lookAt(lookAt);
  if (shake > 0) {
    shake -= dt;
    camera.position.x += (Math.random() - 0.5) * shake;
    camera.position.y += (Math.random() - 0.5) * shake;
  }
}

const parrotWant = new THREE.Vector3();
function updateParrot(dt) {
  if (!parrot.visible) return;
  const side = new THREE.Vector3(Math.cos(yaw) * 0.9, 0, -Math.sin(yaw) * 0.9);
  parrotWant.copy(player.position).add(side);
  parrotWant.y = player.position.y + 2.6 + Math.sin(world.time * 3) * 0.25;
  parrot.position.lerp(parrotWant, Math.min(1, dt * 3));
  parrot.rotation.y = yaw;
  parrot.userData.animate(dt);
}

function resize() {
  const w = innerWidth;
  const h = innerHeight;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.fov = w < h ? 62 : 50;
  camera.updateProjectionMatrix();
}
addEventListener('resize', resize);
resize();

// ---------- loop ----------
const clock = new THREE.Clock();
camera.position.set(player.position.x, 14, player.position.z + 16);
lookAt.set(player.position.x, 1.2, player.position.z - 1);
let firstFrame = true;
function frame() {
  requestAnimationFrame(frame);
  const dt = Math.min(clock.getDelta(), 0.05);
  world.update(dt);
  movePlayer(dt);
  updateParrot(dt);
  for (const p of Object.values(people)) p.char.userData.animate(dt, 0, talking === p);
  for (const w of witches) w.userData.animate(dt);
  combat.update(dt);
  for (const p of talkables) if (p.marker.visible) p.marker.position.y = (p.char ? 3.1 / p.char.scale.y : 2.6) + Math.sin(world.time * 3) * 0.12;

  if (playing && !ui.busy) {
    for (const entry of crystals) {
      if (entry.c.taken) continue;
      if (Math.hypot(player.position.x - entry.word.x, player.position.z - entry.word.z) < 1.5) {
        if (entry.c.locked) {
          if (!lockTold.has(entry.word.key)) { lockTold.add(entry.word.key); ui.toast('A shadow guards this crystal! Beat it first.', 2600); }
        } else collect(entry);
      }
    }
    // Shadows attack when you come close (if you have their wand).
    const threat = combat.nearbyThreat();
    if (threat) combat.fight(threat);
    const sleeper = combat.sleeperNear();
    if (sleeper && !sleeperTold.has(sleeper.id)) {
      sleeperTold.add(sleeper.id);
      ui.toast({
        mots: 'This shadow is asleep. Captain Hugo has a wand for you.',
        nombres: 'This golden shadow is asleep. Léa at the bakery has the Wand of Numbers.',
        etre: 'This purple shadow is asleep. Bruno has the Wand of Être.',
      }[sleeper.type], 3500);
    }
    // The fountain heals.
    if (Math.hypot(player.position.x + 10, player.position.z - 1) < 3.8 && combat.heal()) ui.toast('⛲ The fountain heals you!', 2000);
    nearby = null;
    let best = 2.9;
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

// Testing only (…/game/?debug): move the player and read the state from the console.
if (new URLSearchParams(location.search).has('debug')) {
  window.quest = { player, combat, get state() { return state; }, world, talkTo: (id) => talkTo(talkables.find((p) => p.id === id)) };
}
