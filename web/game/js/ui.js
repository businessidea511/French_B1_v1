// Everything drawn over the 3D scene: dialogues, word cards, the word book,
// the objective, the joystick.
import { t, setHelp, isRtl, fill } from './i18n.js';
import { say, listen, stopListening, micProblem, canListen, bestMatch, sfx, preload } from './speech.js';
import { music } from './music.js';

const $ = (id) => document.getElementById(id);
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

function shuffle(list) {
  const a = [...list];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/** "le chat" → <span class="art m">le</span> chat */
export function wordHtml(w) {
  const span = document.createElement('span');
  const art = document.createElement('span');
  art.className = `art ${w.g}`;
  art.textContent = w.art;
  span.append(art, document.createTextNode(w.art.endsWith("'") ? w.noun : ` ${w.noun}`));
  return span;
}

export class UI {
  constructor() {
    this.helpOn = localStorage.getItem('quest_help') === '1';
    this.busy = false;
    this.move = { x: 0, y: 0 };
    this.setupJoystick();
    $('dlgTranslate').classList.toggle('on', this.helpOn);
    $('dlgTranslate').onclick = () => {
      this.helpOn = !this.helpOn;
      localStorage.setItem('quest_help', this.helpOn ? '1' : '0');
      $('dlgTranslate').classList.toggle('on', this.helpOn);
      this.renderHelp();
    };
  }

  // ---------- objective, counters, toast ----------
  objective(english) {
    this.objectiveText = english;
    setHelp($('objective'), english);
  }

  counters(found, total) {
    $('wordCount').textContent = `${found}/${total}`;
  }

  toast(english, ms = 2600) {
    const el = $('toast');
    setHelp(el, english);
    el.hidden = false;
    clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => { el.hidden = true; }, ms);
  }

  // ---------- dialogue ----------
  renderHelp() {
    const help = $('dlgHelp');
    const node = this.node;
    if (!node) return;
    const showText = !node.listen || node.revealed;
    help.hidden = !(this.helpOn && node.en && showText);
    if (!help.hidden) setHelp(help, node.en);
    for (const btn of $('dlgChoices').children) {
      const small = btn.querySelector('small');
      if (small) small.hidden = !this.helpOn || node.listen && !node.revealed && !btn.dataset.always;
    }
  }

  showText(node) {
    const el = $('dlgText');
    if (node.listen && !node.revealed) {
      el.textContent = '🔊 …  ' + t('Listen and choose');
      el.classList.add('listen');
      el.dir = isRtl ? 'rtl' : 'ltr';
    } else {
      el.textContent = node.fr;
      el.classList.remove('listen');
      el.dir = 'ltr';
    }
  }

  /**
   * Plays a conversation. Each node: { fr, en, who?, listen?, hint?, choices?: [{ fr, en, ok }] }.
   * Resolves with the number of wrong answers.
   */
  async talk(speaker, nodes) {
    this.busy = true;
    let mistakes = 0;
    const panel = $('dialogue');
    panel.hidden = false;
    // Get the whole conversation's voices ready while the first line plays.
    preload(nodes.map((n) => ({ text: fill(n.fr), voice: (n.who || speaker).voice?.voice })));
    for (const raw of nodes) {
      const node = { ...raw, fr: fill(raw.fr) };
      if (raw.choices) node.choices = raw.choices.map((c) => ({ ...c, fr: fill(c.fr) }));
      this.node = node;
      const who = node.who || speaker;
      $('dlgAvatar').textContent = who.avatar;
      $('dlgName').textContent = who.name;
      this.showText(node);
      const tip = panel.querySelector('.coco-tip');
      if (tip) tip.remove();
      $('dlgHeard').textContent = '';
      const speak = () => say(node.fr, who.voice);
      $('dlgSpeak').onclick = speak;
      speak();

      const box = $('dlgChoices');
      box.innerHTML = '';
      $('dlgMic').hidden = true;
      if (!node.choices) {
        this.renderHelp();
        $('dlgNext').hidden = false;
        await new Promise((r) => { $('dlgNext').onclick = r; });
        continue;
      }

      $('dlgNext').hidden = true;
      mistakes += await new Promise((resolve) => {
        let wrong = 0;
        let done = false;
        const pick = async (choice, btn) => {
          if (done) return;
          if (choice.ok) {
            done = true;
            btn.classList.add('right');
            sfx.right();
            node.revealed = true;
            this.showText(node);
            this.renderHelp();
            await Promise.all([say(choice.fr, { voice: 'denise', rate: 0.95 }), wait(900)]);
            await wait(250);
            resolve(wrong);
          } else {
            wrong++;
            btn.classList.add('wrong');
            sfx.wrong();
            setTimeout(() => btn.classList.remove('wrong'), 600);
            if (node.hint && !panel.querySelector('.coco-tip')) {
              const tipEl = document.createElement('div');
              tipEl.className = 'coco-tip';
              tipEl.textContent = '🦜 ' + t(node.hint);
              tipEl.dir = isRtl ? 'rtl' : 'ltr';
              box.before(tipEl);
            }
          }
        };
        const shownAt = performance.now(); // taps in the first moment belong to the previous button
        const order = node.keepOrder ? node.choices : shuffle(node.choices);
        for (const choice of order) {
          const btn = document.createElement('button');
          btn.className = 'choice';
          btn.dir = 'ltr';
          const label = document.createElement('div');
          label.textContent = choice.fr;
          if (choice.en) {
            const small = document.createElement('small');
            small.textContent = t(choice.en);
            small.dir = isRtl ? 'rtl' : 'ltr';
            label.append(small);
          }
          btn.append(label);
          btn.onclick = () => { if (performance.now() - shownAt > 450) pick(choice, btn); };
          box.append(btn);
        }
        this.renderHelp();

        // Say the answer out loud instead of tapping it.
        if (canListen && !node.listen && node.choices.some((c) => c.fr.split(' ').length > 1)) {
          const mic = $('dlgMic');
          mic.hidden = false;
          // The choice that fits the whole sentence said (null if not sure).
          const match = (heard) => {
            const m = bestMatch(heard, order.map((c) => c.fr));
            return m.sure ? m.index : null;
          };
          let listening = false;
          mic.onclick = async () => {
            if (done) return;
            if (listening) return stopListening(); // tap again: done speaking
            listening = true;
            mic.classList.add('on');
            music.hold(true);
            $('dlgHeard').textContent = '🎤 ' + t('Speak now…');
            // The words appear while you speak; the answer is chosen only
            // when the whole sentence is finished (a short silence).
            const { text, error } = await listen((live) => {
              $('dlgHeard').textContent = `« ${live} »`;
            });
            listening = false;
            mic.classList.remove('on');
            music.hold(false);
            if (done) return;
            const chosen = text ? match(text) : null;
            if (chosen !== null) return pick(order[chosen], box.children[chosen]);
            if (!text) { $('dlgHeard').textContent = t(micProblem(error)); return; }
            $('dlgHeard').textContent = `« ${text.split('|')[0].trim()} » — ${t('Not quite. Try again!')}`;
          };
        }
      });
    }
    panel.hidden = true;
    this.node = null;
    this.busy = false;
    return mistakes;
  }

  // ---------- word found ----------
  async wordFound(w) {
    const card = $('wordCard');
    $('wordEmoji').textContent = w.emoji;
    const fr = $('wordFr');
    fr.innerHTML = '';
    fr.append(wordHtml(w));
    setHelp($('wordHelp'), w.en);
    // The note in French (tap to hear it), its translation below.
    const note = $('wordNote');
    note.hidden = !w.noteFr;
    note.textContent = w.noteFr ? `🔊 ${w.noteFr}` : '';
    note.dir = 'ltr';
    note.onclick = () => say(w.noteFr);
    const noteHelp = $('wordNoteHelp');
    noteHelp.hidden = !w.note;
    if (w.note) setHelp(noteHelp, w.note);
    const speak = () => say(`${w.art.endsWith("'") ? w.art + w.noun : w.art + ' ' + w.noun}`);
    $('wordSpeak').onclick = speak;
    card.hidden = false;
    sfx.crystal();
    setTimeout(speak, 350);
    // Stays as long as needed to read it: closed with the button, or by walking away.
    await new Promise((resolve) => {
      $('wordClose').onclick = resolve;
      // Still walking when the clue was picked up: wait until the stick is let go first.
      let armed = false;
      const walking = setInterval(() => {
        const d = this.direction();
        const m = Math.hypot(d.x, d.y);
        if (m < 0.1) armed = true;
        else if (armed && m > 0.3) { clearInterval(walking); resolve(); }
      }, 150);
      $('wordClose').addEventListener('click', () => clearInterval(walking), { once: true });
    });
    card.hidden = true;
  }

  // ---------- word book ----------
  openBook(words, found) {
    const list = $('bookList');
    list.innerHTML = '';
    for (const w of words) {
      const item = document.createElement('div');
      const has = found.includes(w.key);
      item.className = 'book-item' + (has ? '' : ' locked');
      if (has) {
        const b = document.createElement('b');
        b.textContent = w.emoji + ' ';
        b.append(wordHtml(w));
        const fr = document.createElement('span');
        fr.className = 'fr-note';
        fr.textContent = w.noteFr || '';
        fr.dir = 'ltr';
        const s = document.createElement('span');
        setHelp(s, w.note || w.en);
        item.append(b, fr, s);
        item.onclick = () => say(w.noteFr || (w.art.endsWith("'") ? w.art + w.noun : `${w.art} ${w.noun}`));
      } else {
        // Not found yet: where to look — only if the player asks (💡).
        item.innerHTML = '<b>❔ ???</b>';
        if (w.where) {
          const hintBtn = document.createElement('button');
          hintBtn.className = 'hint-btn';
          hintBtn.textContent = '💡 ' + t('Hint');
          hintBtn.onclick = (e) => {
            e.stopPropagation();
            const where = document.createElement('span');
            where.className = 'where';
            setHelp(where, w.where);
            where.textContent = '📍 ' + where.textContent;
            hintBtn.replaceWith(where);
          };
          item.append(hintBtn);
        }
      }
      list.append(item);
    }
    $('book').hidden = false;
    this.busy = true;
    $('bookClose').onclick = () => { $('book').hidden = true; this.busy = false; };
  }

  // ---------- joystick + keyboard ----------
  setupJoystick() {
    const pad = $('joystick');
    const stick = pad.querySelector('.stick');
    let id = null;
    const set = (e) => {
      const r = pad.getBoundingClientRect();
      let x = (e.clientX - r.left - r.width / 2) / (r.width / 2);
      let y = (e.clientY - r.top - r.height / 2) / (r.height / 2);
      const len = Math.hypot(x, y);
      if (len > 1) { x /= len; y /= len; }
      this.move.x = x;
      this.move.y = y;
      stick.style.transform = `translate(${x * 36}px, ${y * 36}px)`;
    };
    pad.addEventListener('pointerdown', (e) => { id = e.pointerId; pad.setPointerCapture(id); set(e); });
    pad.addEventListener('pointermove', (e) => { if (e.pointerId === id) set(e); });
    const end = (e) => {
      if (e.pointerId !== id) return;
      id = null;
      this.move.x = this.move.y = 0;
      stick.style.transform = '';
    };
    pad.addEventListener('pointerup', end);
    pad.addEventListener('pointercancel', end);

    this.keys = new Set();
    addEventListener('keydown', (e) => { this.keys.add(e.key.toLowerCase()); });
    addEventListener('keyup', (e) => { this.keys.delete(e.key.toLowerCase()); });
  }

  /** Movement wanted (x right, y down/south), from the joystick or the keyboard. */
  direction() {
    let { x, y } = this.move;
    const k = this.keys;
    if (k.has('arrowleft') || k.has('a') || k.has('q')) x -= 1;
    if (k.has('arrowright') || k.has('d')) x += 1;
    if (k.has('arrowup') || k.has('w') || k.has('z')) y -= 1;
    if (k.has('arrowdown') || k.has('s')) y += 1;
    const len = Math.hypot(x, y);
    return len > 1 ? { x: x / len, y: y / len } : { x, y };
  }
}

export { wait };
