// Confrontations: the men in grey stop you and question you in French.
// Answer well and fast, and their doubt falls until they let you go.
// Saying the answer out loud is more convincing (counts double).
// Three alerts, and they take you away (you wake up at the hotel).
import * as THREE from 'three';
import { t, isRtl } from './i18n.js';
import { say, listen, stopListening, micProblem, canListen, bestMatch, sfx } from './speech.js';
import { music } from './music.js';
import { makeAgent, makePerson } from './people.js';
import { HOURS, NUMBERS, DEPART_MINUTES, departLine, quaiLine } from './voicedata.js';
export { bankLines } from './voicedata.js';

const $ = (id) => document.getElementById(id);
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const pick = (list) => list[Math.floor(Math.random() * list.length)];
const shuffle = (list) => [...list].sort(() => Math.random() - 0.5);

// Listening questions: a sentence with a number, find the number.
const LISTEN = {
  heure: () => {
    const h = 1 + Math.floor(Math.random() * 11);
    const wrong = shuffle([...Array(12).keys()].filter((k) => k && k !== h)).slice(0, 2);
    return { ask: `Il est ${HOURS[h]}. Vous êtes en retard !`, show: '🕰️', en: 'What time did he say?', right: `${h}:00`, wrong: wrong.map((k) => `${k}:00`) };
  },
  chambre: () => {
    const n = 10 + Math.floor(Math.random() * 21);
    const wrong = shuffle([...Array(31).keys()].filter((k) => k >= 10 && k !== n && Math.abs(k - n) < 9)).slice(0, 2);
    return { ask: `Votre chambre d'hôtel, c'est la ${NUMBERS[n]} ?`, show: '🏨', en: 'Which room number did he say?', right: String(n), wrong: wrong.map(String) };
  },
  quai: () => {
    const n = 1 + Math.floor(Math.random() * 12);
    const wrong = shuffle([...Array(13).keys()].filter((k) => k && k !== n)).slice(0, 2);
    return { ask: quaiLine(n), show: '🚉', en: 'Which platform does the Namur train leave from?', right: `quai ${n}`, wrong: wrong.map((k) => `quai ${k}`) };
  },
  depart: () => {
    const h = 18 + Math.floor(Math.random() * 6);
    const m = pick(DEPART_MINUTES);
    const wrongM = pick(DEPART_MINUTES.filter((x) => x !== m));
    const hhmm = (H, M) => `${H}:${String(M).padStart(2, '0')}`;
    return {
      ask: departLine(h, m), show: '🕰️', en: 'At what time does the Charleroi train leave?',
      right: hhmm(h, m), wrong: [hhmm(h, wrongM), hhmm(h === 23 ? 21 : h + 1, m)],
    };
  },
};

/**
 * A question from a bank. Banks come from the chapter:
 *  { kind: 'phrase', icon, help, items: [[question, right, [wrong, wrong], English]] }
 *  { kind: 'objets', icon, help, ask, askEn, items: [[word, emoji]] }
 *  { kind: 'ecoute', icon, help, gens: ['heure', 'chambre', 'quai', 'depart'] }
 */
const asked = new Map(); // bank → items already asked (in this game session)
function fresh(bank) {
  const done = asked.get(bank) || new Set();
  asked.set(bank, done);
  let left = bank.items.filter((it) => !done.has(it));
  if (!left.length) { done.clear(); left = bank.items; }
  const item = pick(left);
  done.add(item);
  return item;
}

function question(bank) {
  if (bank.kind === 'phrase') {
    const [ask, right, wrong, en] = fresh(bank);
    return { ask, show: ask, en, choices: shuffle([{ fr: right, ok: true }, ...wrong.map((w) => ({ fr: w }))]), spoken: right };
  }
  if (bank.kind === 'objets') {
    const [word, emoji] = fresh(bank);
    const wrong = shuffle(bank.items.filter((o) => o[0] !== word)).slice(0, 2);
    return {
      ask: bank.ask, show: emoji, big: true, en: bank.askEn,
      choices: shuffle([{ fr: word, ok: true }, ...wrong.map((w) => ({ fr: w[0] }))]), spoken: word, accept: word,
    };
  }
  const q = LISTEN[pick(bank.gens)]();
  return { ask: q.ask, show: q.show, big: true, en: q.en, listen: true, choices: shuffle([{ fr: q.right, ok: true }, ...q.wrong.map((w) => ({ fr: w }))]) };
}

export class Confront {
  /** g: { scene, player, city, ui, state, save, hurt, caught, weak } */
  constructor(g) {
    this.g = g;
    this.agents = [];
    this.active = null;
    this.alerts = 0;
  }

  /** A man in grey walking along a path of points. guards: a clue he stands next to. */
  addAgent(id, path, { guards, chief, look } = {}) {
    if (this.g.state.beaten?.includes(id)) return null;
    // A man in grey, or someone else (look: the ticket inspector…).
    const body = look ? makePerson(look, { weak: this.g.weak }) : makeAgent({ weak: this.g.weak, chief });
    body.position.set(path[0][0], 0, path[0][1]);
    this.g.scene.add(body);
    // Sneaking chapters: the torch light shows how far the guard can see.
    if (this.g.detect === 'cone' && body.userData.cone) body.userData.cone.scale.setScalar(2.5);
    const a = { id, body, path, leg: 0, guards, chief, hp: chief ? 6 : 2, maxHp: chief ? 6 : 2, wait: 0, done: false };
    if (guards) {
      const clue = this.g.city.clues.find((c) => c.word.key === guards);
      if (clue) { clue.locked = true; a.clue = clue; }
    }
    this.agents.push(a);
    return a;
  }

  renderAlerts() {
    $('hearts').textContent = '🔴'.repeat(this.alerts) + '⚪'.repeat(Math.max(0, 3 - this.alerts));
    $('hearts').title = 'Alertes';
  }

  update(dt) {
    const p = this.g.player.position;
    for (const a of this.agents) {
      if (a.done) continue;
      const b = a.body;
      if (this.active === a) {
        b.lookAt(p.x, 0, p.z);
        b.userData.animate(dt, 0, true);
        continue;
      }
      if (a.leaving) {
        b.position.z += dt * 2.2;
        b.userData.animate(dt, 1, false);
        a.leaving -= dt;
        if (a.leaving <= 0) { a.done = true; this.g.scene.remove(b); }
        continue;
      }
      // Patrol: walk to the next point, wait a moment, turn back.
      if (a.path.length > 1) {
        if (a.wait > 0) {
          a.wait -= dt;
          // Waiting: the guard looks around.
          if (this.g.detect === 'cone') b.rotation.y = a.yaw + Math.sin(a.wait * 1.6) * 0.9;
          b.userData.animate(dt, 0, false);
          continue;
        }
        const [tx, tz] = a.path[(a.leg + 1) % a.path.length];
        const dx = tx - b.position.x;
        const dz = tz - b.position.z;
        const d = Math.hypot(dx, dz);
        if (d < 0.2) { a.leg = (a.leg + 1) % a.path.length; a.wait = 1.5 + Math.random() * 2; continue; }
        b.position.x += (dx / d) * dt * 1.3;
        b.position.z += (dz / d) * dt * 1.3;
        b.rotation.y = a.yaw = Math.atan2(dx, dz);
        b.userData.animate(dt, 1, false);
      } else {
        b.userData.animate(dt, 0, false);
        const want = Math.atan2(p.x - b.position.x, p.z - b.position.z);
        if (Math.hypot(p.x - b.position.x, p.z - b.position.z) < 9) b.rotation.y += (want - b.rotation.y) * Math.min(1, dt * 2);
      }
      if (b.userData.cone) b.userData.cone.material.opacity = 0.12 + Math.sin(performance.now() / 300) * 0.03;
    }
  }

  /** The man who spots the player, if any (the chief waits at the metro). */
  spotted() {
    const p = this.g.player.position;
    if (this.g.detect !== 'cone') {
      return this.agents.find((a) => !a.done && !a.leaving && !a.chief && Math.hypot(p.x - a.body.position.x, p.z - a.body.position.z) < 4.2);
    }
    // Sneaking: seen inside the torch light (and not behind a wall), or when very close.
    return this.agents.find((a) => {
      if (a.done || a.leaving || a.chief) return false;
      const b = a.body.position;
      const dx = p.x - b.x;
      const dz = p.z - b.z;
      const d = Math.hypot(dx, dz);
      if (d < 1.4) return true;
      if (d > 6.3) return false;
      let diff = Math.atan2(dx, dz) - a.body.rotation.y;
      diff = Math.atan2(Math.sin(diff), Math.cos(diff));
      if (Math.abs(diff) > 0.55) return false;
      for (let k = 1; k < 8; k++) {
        const x = b.x + (dx * k) / 8;
        const z = b.z + (dz * k) / 8;
        if (!this.g.city.walkable(x, z)) return false; // a wall in between
      }
      return true;
    });
  }

  /** A confrontation. Resolves true if the man lets you go. */
  async confront(a) {
    if (this.active) return false;
    this.active = a;
    const ui = this.g.ui;
    ui.busy = true;
    music.fight();
    document.body.classList.add('fighting');
    const panel = $('combat');
    panel.hidden = false;
    const L = this.g.lines;
    $('foeName').textContent = a.chief ? L.chiefName : L.agentName;
    const voice = a.chief ? L.chiefVoice : L.agentVoice;
    say(a.chief ? L.chiefIntro : L.agentIntro, voice);
    await wait(1400);
    let spokenTip = false;
    let caught = false;
    while (a.hp > 0) {
      const banks = this.g.banks;
      const bank = a.chief ? banks[Math.floor((a.maxHp - a.hp) / 2) % banks.length] : pick(banks);
      if (!spokenTip && canListen) {
        spokenTip = true;
        ui.toast('🎤 Answer out loud: it is twice as convincing!', 2600);
      }
      const q = question(bank);
      $('foeIcon').textContent = bank.icon;
      this.renderDoubt(a);
      const outcome = await this.ask(q, a, voice);
      if (outcome === 'right' || outcome === 'spoken') {
        const dmg = outcome === 'spoken' ? 2 : 1;
        const floor = a.chief ? Math.floor((a.hp - 1) / 2) * 2 : 0;
        a.hp = Math.max(a.hp - dmg, floor);
        sfx.right();
        if (outcome === 'spoken') ui.toast('🎤 Très convaincant ! ×2', 1200);
      } else {
        this.alerts++;
        this.renderAlerts();
        sfx.wrong();
        this.g.hurt();
        if (this.alerts >= 3) { caught = true; break; }
      }
      this.renderDoubt(a);
      await wait(400);
    }
    panel.hidden = true;
    document.body.classList.remove('fighting');
    music.explore();
    this.active = null;
    ui.busy = false;
    if (caught) {
      a.hp = a.maxHp;
      this.alerts = 0;
      this.renderAlerts();
      await this.g.caught();
      return false;
    }
    if (!a.chief) {
      say(L.release, voice);
      a.leaving = 3;
      this.g.state.beaten = [...(this.g.state.beaten || []), a.id];
      if (a.clue) a.clue.locked = false;
      ui.toast('🕴️ He lets you go… and walks away.', 2400);
      this.g.save();
    }
    return true;
  }

  renderDoubt(a) {
    $('foeHp').style.width = `${(a.hp / a.maxHp) * 100}%`;
    $('foeHp').style.background = 'linear-gradient(90deg, #c0392b, #e67e22)';
  }

  setPrompt(q) {
    const el = $('foePrompt');
    el.textContent = q.listen ? `${q.show}  🔊` : q.show;
    el.className = 'foe-prompt' + (q.big ? ' big' : '');
    el.dir = 'ltr';
    const help = $('foeHelp');
    help.textContent = t(q.en);
    help.dir = isRtl ? 'rtl' : 'ltr';
  }

  /** One question with a timer: 'right', 'spoken', 'wrong' or 'late'. */
  ask(q, a, voice) {
    this.setPrompt(q);
    say(q.ask, voice);
    const box = $('foeChoices');
    box.innerHTML = '';
    const shownAt = performance.now();
    const seconds = a.chief ? 11 : 13;
    return new Promise((resolve) => {
      let done = false;
      const finish = async (outcome, btn) => {
        if (done) return;
        done = true;
        clearInterval(timer);
        const right = [...box.children].find((b) => b.dataset.ok);
        right?.classList.add('right');
        if (outcome === 'wrong' || outcome === 'late') {
          btn?.classList.add('wrong');
          // Learn from it: the right answer, shown and said.
          $('foeHelp').textContent = `✔ ${right?.textContent}${q.listen ? `  ·  « ${q.ask} »` : ''}`;
          await Promise.all([say(q.listen ? q.ask : right?.textContent, q.listen ? voice : { voice: 'denise' }), wait(2000)]);
          await wait(300);
        } else {
          if (q.spoken && !q.listen) await say(right?.textContent, { voice: 'denise' });
          await wait(500);
        }
        resolve(outcome);
      };
      for (const c of q.choices) {
        const b = document.createElement('button');
        b.className = 'foe-choice';
        b.textContent = c.fr;
        b.dir = 'ltr';
        if (c.ok) b.dataset.ok = '1';
        b.onclick = () => { if (performance.now() - shownAt > 550) finish(c.ok ? 'right' : 'wrong', b); };
        box.append(b);
      }
      $('foeReplay').hidden = false;
      $('foeReplay').onclick = () => say(q.ask, voice);
      const mic = $('foeMic');
      mic.hidden = !(canListen && !q.listen);
      const expected = q.accept || q.choices.find((c) => c.ok).fr;
      let listening = false;
      mic.onclick = async () => {
        if (done) return;
        if (listening) return stopListening(); // tap again: done speaking
        listening = true;
        mic.classList.add('on');
        music.hold(true);
        $('foeHelp').textContent = '🎤 ' + t('Speak now…');
        const { text, error } = await listen((live) => {
          $('foeHelp').textContent = `« ${live} »`;
        });
        listening = false;
        mic.classList.remove('on');
        music.hold(false);
        if (done) return;
        if (text) {
          const answers = q.choices.map((c) => (c.ok ? expected : c.fr));
          const m = bestMatch(text, answers);
          const buttons = [...box.children];
          if (m.sure && q.choices[m.index].ok) return finish('spoken');
          if (m.sure) return finish('wrong', buttons[m.index]); // you said a wrong answer
        }
        $('foeHelp').textContent = text ? `« ${text.split('|')[0].trim()} » — ${t('Not quite. Try again!')}` : t(micProblem(error));
      };
      // The clock stops while you speak: speaking takes time.
      let start = performance.now();
      let last = start;
      const bar = $('foeTimer');
      const timer = setInterval(() => {
        const now = performance.now();
        if (listening) start += now - last;
        last = now;
        const left = 1 - (now - start) / (seconds * 1000);
        bar.style.width = `${Math.max(0, left) * 100}%`;
        if (left <= 0) finish('late');
      }, 100);
    });
  }

  /** The chief's last test: put the words of your story in order. */
  async story(words) {
    const ui = this.g.ui;
    ui.busy = true;
    music.fight();
    document.body.classList.add('fighting');
    const panel = $('combat');
    panel.hidden = false;
    const L = this.g.lines;
    $('foeName').textContent = L.chiefName;
    $('foeIcon').textContent = '🧩';
    $('foeHp').style.width = '8%';
    $('foeTimer').style.width = '0%';
    $('foeMic').hidden = true;
    $('foeReplay').hidden = true;
    const el = $('foePrompt');
    el.className = 'foe-prompt';
    $('foeHelp').textContent = t('Tell your story: put the words in order!');
    $('foeHelp').dir = isRtl ? 'rtl' : 'ltr';
    say(L.storyAsk, L.chiefVoice);
    const built = [];
    let mistakes = 0;
    const shownAt = performance.now();
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
            if (performance.now() - shownAt < 600) return; // a tap meant for the previous screen
            if (w === words[built.length]) {
              built.push(w);
              sfx.coin();
              if (built.length === words.length) say(words.join(' '), { voice: 'denise' }).then(() => setTimeout(resolve, 300));
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

/** English texts used here (translated once at the start). */
export function confrontTexts(banks) {
  const out = ['🎤 Answer out loud: it is twice as convincing!', '🎤 Très convaincant ! ×2', '🕴️ He lets you go… and walks away.',
    'Tell your story: put the words in order!', 'What time did he say?', 'Which room number did he say?', 'Which platform did he say?',
    'At what time does the Charleroi train leave?', 'Which platform does the Namur train leave from?', 'Not quite. Try again!', 'I did not hear you. Try again.'];
  for (const b of banks) {
    out.push(b.help, b.askEn);
    if (b.kind === 'phrase') for (const q of b.items) out.push(q[3]);
  }
  return out.filter(Boolean);
}
