// Confrontations: the men in grey stop you and question you in French.
// Answer well and fast, and their doubt falls until they let you go.
// Saying the answer out loud is more convincing (counts double).
// Three alerts, and they take you away (you wake up at the hotel).
import * as THREE from 'three';
import { t, isRtl } from './i18n.js';
import { say, listen, stopListening, micProblem, canListen, closeness, sfx } from './speech.js';
import { music } from './music.js';
import { makeAgent } from './people.js';

const $ = (id) => document.getElementById(id);
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const pick = (list) => list[Math.floor(Math.random() * list.length)];
const shuffle = (list) => [...list].sort(() => Math.random() - 0.5);

// [question, right answer, two wrong answers, English]
const IDENTITY = [
  ['Vous êtes qui ?', 'Je suis touriste.', ['Je es touriste.', "J'ai touriste."], 'Who are you?'],
  ['Vous avez des papiers ?', "Oui, j'ai mon passeport.", ['Oui, je suis mon passeport.', "Oui, j'as mon passeport."], 'Do you have papers?'],
  ['Vous avez quel âge ?', "J'ai vingt-cinq ans.", ['Je suis vingt-cinq ans.', "J'ai vingt-cinq."], 'How old are you?'],
  ["Qu'est-ce que vous faites ici ?", 'Je cherche mon hôtel.', ['Je cherche mon hôpital.', 'Je suis mon hôtel.'], 'What are you doing here?'],
  ['Vous habitez où ?', "J'habite à l'hôtel du Lion.", ["Je habite à l'hôtel du Lion.", "J'habites à l'hôtel du Lion."], 'Where are you staying?'],
  ['Vous parlez français ?', 'Oui, un peu.', ['Oui, je suis un peu.', 'Non, merci beaucoup.'], 'Do you speak French?'],
  ['Vous connaissez Élise Moreau ?', 'Non, je ne la connais pas.', ['Non, je ne connais pas la.', 'Oui, je suis Élise.'], 'Do you know Élise Moreau?'],
  ['Vous êtes seul ce soir ?', 'Oui, je suis seul.', ["Oui, j'ai seul.", 'Oui, tu es seul.'], 'Are you alone tonight?'],
  ['Vous allez où ?', 'Je vais à mon hôtel.', ['Je vas à mon hôtel.', 'Je suis à mon hôtel hier.'], 'Where are you going?'],
];
const OBJECTS = [
  ['le téléphone', '📱'], ['la clé', '🔑'], ['le parapluie', '☂️'], ['le ticket', '🎫'], ['la lettre', '✉️'],
  ['le passeport', '🛂'], ['le portefeuille', '👛'], ['la carte', '🗺️'], ['le stylo', '🖊️'], ['le journal', '📰'],
  ['la montre', '⌚'], ['les lunettes', '👓'], ['le sac', '👜'], ['la photo', '📷'], ['le carnet', '📓'], ["l'argent", '💶'],
];
const HOURS = ['', 'une heure', 'deux heures', 'trois heures', 'quatre heures', 'cinq heures', 'six heures', 'sept heures', 'huit heures', 'neuf heures', 'dix heures', 'onze heures', 'midi'];
const NUMBERS = ['zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf', 'vingt', 'vingt et un', 'vingt-deux', 'vingt-trois', 'vingt-quatre', 'vingt-cinq', 'vingt-six', 'vingt-sept', 'vingt-huit', 'vingt-neuf', 'trente'];

export const KINDS = {
  identite: { icon: '🪪', help: 'Answer like a real visitor.' },
  nombres: { icon: '🔢', help: 'Listen carefully to the number.' },
  objets: { icon: '🔍', help: 'Say what you are holding.' },
};

/** A question: { ask (French, spoken by the man), show, big?, en, choices, spoken? }. */
function question(kind) {
  if (kind === 'identite') {
    const [ask, right, wrong, en] = pick(IDENTITY);
    return { ask, show: ask, en, choices: shuffle([{ fr: right, ok: true }, ...wrong.map((w) => ({ fr: w }))]), spoken: right };
  }
  if (kind === 'objets') {
    const [word, emoji] = pick(OBJECTS);
    const wrong = shuffle(OBJECTS.filter((o) => o[0] !== word)).slice(0, 2);
    return {
      ask: "Qu'est-ce que vous avez dans la main ?", show: emoji, big: true, en: 'What do you have in your hand?',
      choices: shuffle([{ fr: word, ok: true }, ...wrong.map((w) => ({ fr: w[0] }))]), spoken: `C'est ${word.startsWith('les') ? 'des lunettes' : word}`.replace("C'est l'argent", "C'est de l'argent"),
      accept: word,
    };
  }
  if (Math.random() < 0.5) {
    const h = 1 + Math.floor(Math.random() * 11);
    const wrong = shuffle([...Array(12).keys()].filter((k) => k && k !== h)).slice(0, 2);
    return {
      ask: `Il est ${HOURS[h]}. Vous êtes en retard !`, show: '🕰️', big: true, en: 'What time did he say?', listen: true,
      choices: shuffle([{ fr: `${h}:00`, ok: true }, ...wrong.map((k) => ({ fr: `${k}:00` }))]),
    };
  }
  const n = 10 + Math.floor(Math.random() * 21);
  const wrong = shuffle([...Array(31).keys()].filter((k) => k >= 10 && k !== n && Math.abs(k - n) < 9)).slice(0, 2);
  return {
    ask: `Votre chambre d'hôtel, c'est la ${NUMBERS[n]} ?`, show: '🏨', big: true, en: 'Which room number did he say?', listen: true,
    choices: shuffle([{ fr: String(n), ok: true }, ...wrong.map((k) => ({ fr: String(k) }))]),
  };
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
  addAgent(id, path, { guards, chief } = {}) {
    if (this.g.state.beaten?.includes(id)) return null;
    const body = makeAgent({ weak: this.g.weak, chief });
    body.position.set(path[0][0], 0, path[0][1]);
    this.g.scene.add(body);
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
        if (a.wait > 0) { a.wait -= dt; b.userData.animate(dt, 0, false); continue; }
        const [tx, tz] = a.path[(a.leg + 1) % a.path.length];
        const dx = tx - b.position.x;
        const dz = tz - b.position.z;
        const d = Math.hypot(dx, dz);
        if (d < 0.2) { a.leg = (a.leg + 1) % a.path.length; a.wait = 1.5 + Math.random() * 2; continue; }
        b.position.x += (dx / d) * dt * 1.3;
        b.position.z += (dz / d) * dt * 1.3;
        b.rotation.y = Math.atan2(dx, dz);
        b.userData.animate(dt, 1, false);
      } else {
        b.userData.animate(dt, 0, false);
        const want = Math.atan2(p.x - b.position.x, p.z - b.position.z);
        if (Math.hypot(p.x - b.position.x, p.z - b.position.z) < 9) b.rotation.y += (want - b.rotation.y) * Math.min(1, dt * 2);
      }
      b.userData.cone.material.opacity = 0.12 + Math.sin(performance.now() / 300) * 0.03;
    }
  }

  /** The man who spots the player, if any (the chief waits at the metro). */
  spotted() {
    const p = this.g.player.position;
    return this.agents.find((a) => !a.done && !a.leaving && !a.chief && Math.hypot(p.x - a.body.position.x, p.z - a.body.position.z) < 4.2);
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
    $('foeName').textContent = a.chief ? "Le chef des hommes en gris" : 'Un homme en gris';
    const voice = a.chief ? { voice: 'remy', speed: 0.92 } : { voice: 'henri', speed: 0.95 };
    say(a.chief ? 'Enfin. Je vous attendais.' : 'Excusez-moi. Contrôle. Une minute.', voice);
    await wait(1400);
    let spokenTip = false;
    let caught = false;
    while (a.hp > 0) {
      const kind = a.chief ? ['identite', 'nombres', 'objets'][Math.floor((a.maxHp - a.hp) / 2)] : pick(['identite', 'nombres', 'objets']);
      if (!spokenTip && canListen) {
        spokenTip = true;
        ui.toast('🎤 Answer out loud: it is twice as convincing!', 2600);
      }
      const q = question(kind);
      $('foeIcon').textContent = KINDS[kind].icon;
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
      say('Bon… Ça va. Circulez.', voice);
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
        b.onclick = () => finish(c.ok ? 'right' : 'wrong', b);
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
        let convinced = false;
        const { text, error } = await listen((live) => {
          $('foeHelp').textContent = `« ${live} »`;
          if (!convinced && closeness(live, expected) >= 0.6) { convinced = true; stopListening(); }
        });
        listening = false;
        mic.classList.remove('on');
        music.hold(false);
        if (done) return;
        if (convinced || (text && closeness(text, expected) >= 0.6)) return finish('spoken');
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
    $('foeName').textContent = 'Le chef des hommes en gris';
    $('foeIcon').textContent = '🧩';
    $('foeHp').style.width = '8%';
    $('foeTimer').style.width = '0%';
    $('foeMic').hidden = true;
    $('foeReplay').hidden = true;
    const el = $('foePrompt');
    el.className = 'foe-prompt';
    $('foeHelp').textContent = t('Tell your story: put the words in order!');
    $('foeHelp').dir = isRtl ? 'rtl' : 'ltr';
    say('Racontez-moi votre histoire. Lentement.', { voice: 'remy', speed: 0.92 });
    const built = [];
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
export function confrontTexts() {
  const out = ['🎤 Answer out loud: it is twice as convincing!', '🎤 Très convaincant ! ×2', '🕴️ He lets you go… and walks away.',
    'Tell your story: put the words in order!', 'What do you have in your hand?', 'What time did he say?', 'Which room number did he say?',
    'Not quite. Try again!', 'I did not hear you. Try again.'];
  for (const k of Object.values(KINDS)) out.push(k.help);
  for (const q of IDENTITY) out.push(q[3]);
  return out;
}
