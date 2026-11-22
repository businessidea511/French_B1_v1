// Magic fights: Morgane's shadows guard the island. French is the weapon:
// each wand casts one kind of French, and a shadow is only hurt by the wand
// of its colour. A right answer casts a spell; saying it out loud casts a
// double spell. A wrong answer, or no answer in time, and the shadow hits.
import * as THREE from 'three';
import { t, isRtl } from './i18n.js';
import { say, listen, canListen, closeness, sfx } from './speech.js';
import { music } from './music.js';

const $ = (id) => document.getElementById(id);
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const pick = (list) => list[Math.floor(Math.random() * list.length)];
const shuffle = (list) => [...list].sort(() => Math.random() - 0.5);

export const WANDS = {
  mots: { name: 'Baguette des Mots', icon: '🪄', color: '#4fc3ff', help: 'Wand of Words: name what you see.' },
  nombres: { name: 'Baguette des Nombres', icon: '🔢', color: '#ffc94d', help: 'Wand of Numbers: listen and find the number.' },
  etre: { name: "Baguette d'Être", icon: '⭐', color: '#c77dff', help: 'Wand of Être and Avoir: complete the sentence.' },
};

// Words for the Wand of Words: the island's words and a few more.
const VOCAB = [
  ['le bateau', '⛵'], ['la maison', '🏠'], ["l'arbre", '🌳'], ['la fontaine', '⛲'], ['le pain', '🥖'], ['le chat', '🐈'],
  ['la fleur', '🌸'], ['le pont', '🌉'], ['le soleil', '☀️'], ['la lune', '🌙'], ['le poisson', '🐟'], ['la pomme', '🍎'],
  ['le livre', '📖'], ['la voiture', '🚗'], ['le chien', '🐕'], ['la porte', '🚪'], ["l'eau", '💧'], ['le feu', '🔥'],
  ['la clé', '🔑'], ['le cœur', '❤️'], ["l'étoile", '⭐'], ['la mer', '🌊'],
];
const NUMBERS = ['zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf', 'vingt'];
// [sentence with ___, right, two wrong, English]
const ETRE = [
  ['Je ___ content.', 'suis', ['es', 'est'], 'I am happy.'],
  ['Tu ___ fatigué.', 'es', ['suis', 'sont'], 'You are tired.'],
  ['Il ___ grand.', 'est', ['es', 'sommes'], 'He is tall.'],
  ['Nous ___ amis.', 'sommes', ['êtes', 'sont'], 'We are friends.'],
  ['Vous ___ gentils.', 'êtes', ['sommes', 'est'], 'You are kind.'],
  ['Elles ___ ici.', 'sont', ['est', 'êtes'], 'They are here.'],
  ["J'___ un chat.", 'ai', ['as', 'a'], 'I have a cat.'],
  ['Tu ___ un livre.', 'as', ['ai', 'ont'], 'You have a book.'],
  ['Elle ___ dix ans.', 'a', ['as', 'ont'], 'She is ten years old.'],
  ['Nous ___ faim.', 'avons', ['avez', 'ont'], 'We are hungry.'],
  ['Vous ___ une clé.', 'avez', ['avons', 'a'], 'You have a key.'],
  ['Ils ___ un bateau.', 'ont', ['avons', 'a'], 'They have a boat.'],
];

/** A question for this wand: { show, audio?, en, choices: [{ fr, ok }], spoken? }. */
function challenge(type) {
  if (type === 'mots') {
    const [word, emoji] = pick(VOCAB);
    const wrong = shuffle(VOCAB.filter((v) => v[0] !== word)).slice(0, 2);
    return { show: emoji, big: true, en: 'What is it in French?', choices: shuffle([{ fr: word, ok: true }, ...wrong.map((w) => ({ fr: w[0] }))]), spoken: word };
  }
  if (type === 'nombres') {
    const n = 1 + Math.floor(Math.random() * 20);
    const wrong = shuffle([...Array(21).keys()].filter((k) => k && k !== n && Math.abs(k - n) < 8)).slice(0, 2);
    return { show: '🔊', big: true, audio: NUMBERS[n], en: 'Listen: which number?', choices: shuffle([{ fr: String(n), ok: true }, ...wrong.map((k) => ({ fr: String(k) }))]) };
  }
  const [sentence, right, wrong, en] = pick(ETRE);
  return {
    show: sentence, en, choices: shuffle([{ fr: right, ok: true }, ...wrong.map((w) => ({ fr: w }))]),
    spoken: sentence.replace("J'___", `J'${right}`).replace('___', right),
    hint: right === 'ai' || ['as', 'a', 'avons', 'avez', 'ont'].includes(right)
      ? 'avoir: j\'ai, tu as, il a, nous avons, vous avez, ils ont'
      : 'être: je suis, tu es, il est, nous sommes, vous êtes, ils sont',
  };
}

// ---------- shadows ----------
const SHADOW_COLORS = { mots: '#2bb3ff', nombres: '#ffb300', etre: '#b14dff' };

function makeShadow(type, scale = 1) {
  const g = new THREE.Group();
  const color = SHADOW_COLORS[type] || '#ff3df2';
  const body = new THREE.Mesh(
    new THREE.IcosahedronGeometry(0.9, 1),
    new THREE.MeshLambertMaterial({ color: '#1a1030', emissive: color, emissiveIntensity: 0.35, flatShading: true }),
  );
  body.scale.set(1, 1.25, 1);
  g.add(body);
  for (const s of [-1, 1]) {
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.13, 6, 4), new THREE.MeshBasicMaterial({ color }));
    eye.position.set(s * 0.3, 0.3, 0.78);
    g.add(eye);
  }
  const wisps = [];
  for (let i = 0; i < 5; i++) {
    const w = new THREE.Mesh(new THREE.ConeGeometry(0.22, 0.8, 5), new THREE.MeshLambertMaterial({ color: '#1a1030', flatShading: true }));
    w.rotation.x = Math.PI;
    g.add(w);
    wisps.push({ m: w, a: (i / 5) * Math.PI * 2 });
  }
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(1.1, 1.35, 24),
    new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.5, side: THREE.DoubleSide, depthWrite: false }),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = -1.3;
  g.add(ring);
  g.scale.setScalar(scale);
  return { group: g, body, wisps, ring };
}

function makeCage(color) {
  const g = new THREE.Group();
  for (let i = 0; i < 6; i++) {
    const bar = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.05, 2.2, 4), new THREE.MeshBasicMaterial({ color }));
    const a = (i / 6) * Math.PI * 2;
    bar.position.set(Math.cos(a) * 0.9, 0, Math.sin(a) * 0.9);
    g.add(bar);
  }
  for (const y of [-1.1, 1.1]) {
    const ring = new THREE.Mesh(new THREE.TorusGeometry(0.9, 0.06, 4, 16), new THREE.MeshBasicMaterial({ color }));
    ring.rotation.x = Math.PI / 2;
    ring.position.y = y;
    g.add(ring);
  }
  return g;
}

export class Combat {
  /** g: { scene, player, world, ui, state, save, refresh, respawn } */
  constructor(g) {
    this.g = g;
    this.shadows = [];
    this.active = null;
    this.hearts = 3;
    this.bolts = [];
    this.setupWandBar();
  }

  /** A shadow at x,z. guards: a word key whose crystal it locks. boss: the guardian of the chest. */
  addShadow(id, type, x, z, { guards, boss } = {}) {
    if (this.g.state.beaten?.includes(id)) return;
    const look = makeShadow(boss ? 'boss' : type, boss ? 2.2 : 1);
    look.group.position.set(x, 1.6 * (boss ? 1.8 : 1), z);
    this.g.scene.add(look.group);
    const s = { id, type, x, z, home: new THREE.Vector3(x, look.group.position.y, z), hp: boss ? 6 : 2, maxHp: boss ? 6 : 2, guards, boss, ...look, t: Math.random() * 5 };
    if (boss) s.shields = ['mots', 'nombres', 'etre'];
    if (guards) {
      const crystal = this.g.world.crystals.find((c) => c.word.key === guards);
      if (crystal) {
        s.cage = makeCage(SHADOW_COLORS[type]);
        crystal.group.add(s.cage);
        crystal.locked = true;
        s.crystal = crystal;
      }
    }
    this.shadows.push(s);
  }

  hasWand(type) { return this.g.state.wands?.includes(type); }

  // ---------- HUD: hearts and wands ----------
  setupWandBar() {
    const bar = $('wandBar');
    bar.innerHTML = '';
    for (const [type, w] of Object.entries(WANDS)) {
      const b = document.createElement('button');
      b.className = 'wand';
      b.dataset.type = type;
      b.style.setProperty('--c', w.color);
      b.textContent = w.icon;
      b.title = w.name;
      b.onclick = () => this.selectWand(type);
      bar.append(b);
    }
    this.renderHud();
  }

  selectWand(type) {
    if (!this.hasWand(type)) return;
    this.g.state.wand = type;
    sfx.coin();
    this.renderHud();
    this.g.ui.toast(`${WANDS[type].icon} ${WANDS[type].name}`, 1400);
    if (this.onWand) this.onWand(type);
  }

  renderHud() {
    const s = this.g.state;
    $('hearts').textContent = '❤️'.repeat(Math.max(0, this.hearts)) + '🖤'.repeat(Math.max(0, 3 - this.hearts));
    $('wandBar').hidden = !s.wands?.length;
    for (const b of $('wandBar').children) {
      b.hidden = !this.hasWand(b.dataset.type);
      b.classList.toggle('on', s.wand === b.dataset.type);
    }
  }

  heal() {
    if (this.hearts >= 3) return false;
    this.hearts = 3;
    this.renderHud();
    return true;
  }

  // ---------- every frame ----------
  update(dt) {
    const p = this.g.player.position;
    for (const s of this.shadows) {
      if (s.dead) continue;
      s.t += dt;
      const sleeping = !this.hasWand(s.boss ? 'etre' : s.type);
      const bob = Math.sin(s.t * 2) * 0.2;
      if (this.active === s) {
        // Moves toward the player while the timer runs.
        const want = new THREE.Vector3(p.x, s.home.y, p.z);
        const d = s.group.position.distanceTo(want);
        const keep = s.boss ? 4.5 : 2.6;
        if (d > keep) s.group.position.lerp(want, Math.min(1, dt * 0.25 * (s.rush || 1)));
      } else {
        s.group.position.lerp(s.home, Math.min(1, dt * 2));
      }
      s.group.position.y = s.home.y + bob + (sleeping ? -0.5 : 0);
      s.group.lookAt(p.x, s.group.position.y, p.z);
      s.body.rotation.y += dt * (sleeping ? 0.3 : 1.2);
      s.body.material.emissiveIntensity = sleeping ? 0.08 : 0.35 + Math.sin(s.t * 4) * 0.15;
      for (const w of s.wisps) {
        w.a += dt * 1.5;
        w.m.position.set(Math.cos(w.a) * 0.55, -1 + Math.sin(s.t * 5 + w.a) * 0.1, Math.sin(w.a) * 0.55);
      }
      if (s.cage) s.cage.rotation.y += dt * 0.8;
      if (s.hitFlash > 0) {
        s.hitFlash -= dt;
        s.body.material.emissiveIntensity = 1.5;
      }
    }
    for (const b of this.bolts) {
      b.t += dt * 2.6;
      b.mesh.position.lerpVectors(b.from, b.to, Math.min(1, b.t));
      b.mesh.position.y += Math.sin(Math.min(1, b.t) * Math.PI) * 1.2;
      b.mesh.scale.setScalar(1 + b.t * 0.6);
      if (b.t >= 1 && !b.done) { b.done = true; this.g.scene.remove(b.mesh); }
    }
    this.bolts = this.bolts.filter((b) => !b.done);
  }

  /** The shadow close enough to attack the player, if any. */
  nearbyThreat() {
    const p = this.g.player.position;
    for (const s of this.shadows) {
      if (s.dead || s.boss) continue;
      if (!this.hasWand(s.type)) continue; // asleep until the player has its wand
      if (Math.hypot(p.x - s.x, p.z - s.z) < 5.5) return s;
    }
    return null;
  }

  sleeperNear() {
    const p = this.g.player.position;
    return this.shadows.find((s) => !s.dead && !s.boss && !this.hasWand(s.type) && Math.hypot(p.x - s.x, p.z - s.z) < 5);
  }

  bolt(from, to, color, big) {
    const mesh = new THREE.Mesh(
      new THREE.IcosahedronGeometry(big ? 0.45 : 0.3, 0),
      new THREE.MeshBasicMaterial({ color }),
    );
    this.g.scene.add(mesh);
    this.bolts.push({ mesh, from: from.clone().setY(from.y + 1.4), to: to.clone(), t: 0 });
  }

  // ---------- a fight ----------
  async fight(s) {
    if (this.active) return;
    this.active = s;
    const ui = this.g.ui;
    ui.busy = true;
    music.fight();
    document.body.classList.add('fighting');
    const panel = $('combat');
    panel.hidden = false;
    $('foeName').textContent = s.boss ? 'Le Gardien de Morgane' : 'Ombre de Morgane';
    let result = 'win';
    let spokenHint = false;

    while (s.hp > 0) {
      const need = s.boss ? s.shields[Math.floor((s.maxHp - s.hp) / 2)] : s.type;
      this.renderFoe(s, need);
      // The right wand first.
      if (this.g.state.wand !== need) {
        this.setPrompt({ show: WANDS[need].icon, big: true, en: `This shadow only fears the ${WANDS[need].name}. Tap it below!` });
        $('foeChoices').innerHTML = '';
        $('foeTimer').style.width = '0%';
        document.querySelector(`.wand[data-type="${need}"]`)?.classList.add('hint');
        await new Promise((r) => { this.onWand = (type) => { if (type === need) r(); }; });
        this.onWand = null;
        document.querySelectorAll('.wand.hint').forEach((b) => b.classList.remove('hint'));
      }
      const q = challenge(need);
      if (!spokenHint && canListen && q.spoken) {
        spokenHint = true;
        ui.toast('🎤 Say the answer out loud for a double spell!', 2600);
      }
      const outcome = await this.ask(q, s);
      if (outcome === 'right' || outcome === 'spoken') {
        const dmg = outcome === 'spoken' ? 2 : 1;
        this.bolt(this.g.player.position, s.group.position, WANDS[need].color, dmg > 1);
        sfx.right();
        await wait(380);
        // The guardian has three shields of 2: a double spell never breaks two at once.
        const floor = s.boss ? Math.floor((s.hp - 1) / 2) * 2 : 0;
        s.hp = Math.max(s.hp - dmg, floor);
        s.hitFlash = 0.3;
        sfx.coin();
        if (outcome === 'spoken') ui.toast('✨ Sort parlé ! ×2', 1200);
      } else {
        this.hearts--;
        this.renderHud();
        sfx.wrong();
        this.g.hurt();
        if (this.hearts <= 0) { result = 'lose'; break; }
      }
      this.renderFoe(s, need);
      await wait(500);
    }

    panel.hidden = true;
    document.body.classList.remove('fighting');
    music.explore();
    this.active = null;
    if (result === 'win') {
      s.dead = true;
      this.defeat(s);
      if (!s.boss) {
        this.g.state.beaten = [...(this.g.state.beaten || []), s.id];
        this.g.state.coins += 3;
        ui.toast('💥 The shadow is gone! +3 🪙', 2200);
      }
      this.g.save();
      ui.busy = false;
      return true;
    }
    s.hp = s.maxHp;
    s.group.position.copy(s.home);
    ui.busy = false;
    await this.g.respawn();
    this.hearts = 3;
    this.renderHud();
    return false;
  }

  defeat(s) {
    const g = s.group;
    let k = 0;
    const fade = setInterval(() => {
      k += 0.08;
      g.scale.setScalar(Math.max(0.01, (s.boss ? 2.2 : 1) * (1 - k)));
      g.rotation.y += 0.4;
      if (k >= 1) { clearInterval(fade); this.g.scene.remove(g); }
    }, 30);
    if (s.cage && s.crystal) {
      s.crystal.group.remove(s.cage);
      s.crystal.locked = false;
    }
    sfx.open();
  }

  renderFoe(s, need) {
    $('foeHp').style.width = `${(s.hp / s.maxHp) * 100}%`;
    $('foeHp').style.background = SHADOW_COLORS[need] || '#ff3df2';
    $('foeIcon').textContent = WANDS[need].icon;
  }

  setPrompt(q) {
    const el = $('foePrompt');
    el.textContent = q.show;
    el.className = 'foe-prompt' + (q.big ? ' big' : '');
    el.dir = 'ltr';
    const help = $('foeHelp');
    help.textContent = t(q.en);
    help.dir = isRtl ? 'rtl' : 'ltr';
  }

  /** One question with a timer. Resolves 'right', 'spoken', 'wrong' or 'late'. */
  ask(q, s) {
    this.setPrompt(q);
    if (q.audio) say(q.audio, { voice: 'denise' });
    const box = $('foeChoices');
    box.innerHTML = '';
    const seconds = s.boss ? 10 : 12;
    return new Promise((resolve) => {
      let done = false;
      const finish = async (outcome, btn) => {
        if (done) return;
        done = true;
        clearInterval(timer);
        s.rush = 1;
        const right = [...box.children].find((b) => b.dataset.ok);
        right?.classList.add('right');
        if (outcome === 'wrong' || outcome === 'late') {
          btn?.classList.add('wrong');
          // Learn from it: show and say the right answer.
          const answer = q.spoken || q.audio || right?.textContent;
          $('foeHelp').textContent = '✔ ' + (q.audio ? `${right?.textContent} = ${q.audio}` : answer) + (q.hint ? `  ·  ${t(q.hint)}` : '');
          if (answer) say(answer, { voice: 'denise' });
          await wait(1800);
        } else if (q.spoken) {
          say(q.spoken, { voice: 'denise' });
          await wait(600);
        }
        resolve(outcome);
      };
      for (const c of q.choices) {
        const b = document.createElement('button');
        b.className = 'foe-choice';
        b.textContent = c.fr;
        b.dir = 'ltr';
        if (c.ok) b.dataset.ok = '1';
        b.onclick = () => finish(c.ok ? 'right' : 'wrong', b);
        box.append(b);
      }
      $('foeReplay').hidden = !q.audio;
      $('foeReplay').onclick = () => say(q.audio, { voice: 'denise' });
      const mic = $('foeMic');
      mic.hidden = !(canListen && q.spoken);
      mic.onclick = async () => {
        if (done) return;
        mic.classList.add('on');
        const heard = await listen();
        mic.classList.remove('on');
        if (done) return;
        if (heard && closeness(heard, q.spoken) >= 0.6) finish('spoken');
        else this.g.ui.toast(heard ? `« ${heard.split('|')[0].trim()} » — ${t('Not quite. Try again!')}` : t('I did not hear you. Try again.'), 1800);
      };
      const start = performance.now();
      const bar = $('foeTimer');
      const timer = setInterval(() => {
        const left = 1 - (performance.now() - start) / (seconds * 1000);
        bar.style.width = `${Math.max(0, left) * 100}%`;
        s.rush = left < 0.35 ? 3 : 1;
        if (left <= 0) finish('late');
      }, 100);
    });
  }

  /** The boss's last attack: put the words in order. */
  async sentence(words) {
    const ui = this.g.ui;
    ui.busy = true;
    music.fight();
    document.body.classList.add('fighting');
    const panel = $('combat');
    panel.hidden = false;
    $('foeName').textContent = 'Le Gardien de Morgane';
    $('foeIcon').textContent = '🧩';
    $('foeHp').style.width = '8%';
    $('foeTimer').style.width = '0%';
    $('foeMic').hidden = true;
    $('foeReplay').hidden = true;
    const target = words.join(' ');
    let built = [];
    const el = $('foePrompt');
    el.className = 'foe-prompt';
    $('foeHelp').textContent = t('Last spell: put the words in order!');
    $('foeHelp').dir = isRtl ? 'rtl' : 'ltr';
    let mistakes = 0;
    await new Promise((resolve) => {
      const render = () => {
        el.textContent = built.length ? built.join(' ') : '…';
        const box = $('foeChoices');
        box.innerHTML = '';
        const left = [...words];
        for (const w of built) left.splice(left.indexOf(w), 1);
        for (const w of shuffle(left)) {
          const b = document.createElement('button');
          b.className = 'foe-choice';
          b.textContent = w;
          b.onclick = () => {
            const next = words[built.length];
            if (w === next) {
              built.push(w);
              sfx.coin();
              if (built.length === words.length) { say(target, { voice: 'denise' }); setTimeout(resolve, 900); }
              render();
            } else {
              mistakes++;
              b.classList.add('wrong');
              sfx.wrong();
              setTimeout(() => b.classList.remove('wrong'), 500);
            }
          };
          box.append(b);
        }
      };
      render();
    });
    panel.hidden = true;
    document.body.classList.remove('fighting');
    music.explore();
    ui.busy = false;
    return mistakes;
  }
}

/** Every English text used here, translated once at the start. */
export function combatTexts() {
  const out = ['What is it in French?', 'Listen: which number?', 'Last spell: put the words in order!',
    '🎤 Say the answer out loud for a double spell!', '💥 The shadow is gone! +3 🪙', 'Not quite. Try again!',
    'avoir: j\'ai, tu as, il a, nous avons, vous avez, ils ont', 'être: je suis, tu es, il est, nous sommes, vous êtes, ils sont'];
  for (const w of Object.values(WANDS)) out.push(w.help, `This shadow only fears the ${w.name}. Tap it below!`);
  for (const e of ETRE) out.push(e[3]);
  return out;
}
