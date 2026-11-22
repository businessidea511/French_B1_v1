// The learner's language comes from the app (same site, same storage).
// Help texts are written in English and translated through the app's shared
// translation table (/api/translate): each sentence is translated by the AI
// once for everyone, then read from the database, and kept on the phone.

const LANGS = ['fr', 'ar', 'en', 'uk', 'it', 'ti', 'tr', 'id'];
const RTL = ['ar'];

export const API_BASE = /^(localhost|127\.0\.0\.1)$/.test(location.hostname) ? 'https://polylearnfrench.vercel.app' : '';

function readAppLanguage() {
  try {
    const raw = localStorage.getItem('flutter.selected_language');
    const code = raw ? JSON.parse(raw) : null;
    if (LANGS.includes(code)) return code;
  } catch (_) {}
  const nav = (navigator.language || 'en').slice(0, 2);
  return LANGS.includes(nav) ? nav : 'en';
}

// Each player picks their help language on the title screen (default: the
// app's language). A French-speaking learner gets help in English.
const appLang = readAppLanguage();
const picked = localStorage.getItem('quest_lang');
export const lang = LANGS.includes(picked) && picked !== 'fr' ? picked : appLang === 'fr' ? 'en' : appLang;

/** Changes the help language (the page reloads to use it everywhere). */
export function pickLanguage(code) {
  localStorage.setItem('quest_lang', code);
  location.reload();
}
export const isRtl = RTL.includes(lang);

// Interface words, written by hand in the two most used languages.
const UI = {
  ar: {
    'An investigation to learn French': 'تحقيق بوليسي لتعلّم الفرنسية',
    'Case file': 'ملف القضية',
    'Got it': 'فهمت',
    'Explore the street': 'استكشف الشارع',
    'Clues found': 'الأدلة',
    Mistakes: 'الأخطاء',
    'Your name': 'اسمك',
    Play: 'العب',
    Continue: 'تابع',
    'New game': 'لعبة جديدة',
    'Back to the app': 'العودة إلى التطبيق',
    'My words': 'كلماتي',
    Close: 'إغلاق',
    'Chapter 1 complete!': 'انتهى الفصل الأول!',
    'Coming soon': 'قريباً',
    'Explore the island': 'استكشف الجزيرة',
    'Help language': 'لغة المساعدة',
  },
};

const CACHE_KEY = `quest_tr_${lang}`;
let cache = {};
try { cache = JSON.parse(localStorage.getItem(CACHE_KEY) || '{}'); } catch (_) {}
const saveCache = () => { try { localStorage.setItem(CACHE_KEY, JSON.stringify(cache)); } catch (_) {} };

// Values put into texts after translation, so "{name}" or "{n}/{total}" are
// translated once for everyone, whatever the name or the number.
const vars = {};
export function setVars(values) { Object.assign(vars, values); }
export const fill = (s) => s.replace(/\{(\w+)\}/g, (m, k) => (k in vars ? String(vars[k]) : m));

/** The help text in the learner's language (English until its translation arrives). */
export function t(english) {
  if (lang === 'en') return fill(english);
  return fill(UI[lang]?.[english] ?? cache[english] ?? english);
}

/** Fetches the translations of all these English texts (30 at a time). */
export async function prefetch(texts, onUpdate) {
  if (lang === 'en') return;
  const missing = [...new Set(texts)].filter((s) => s && !UI[lang]?.[s] && !cache[s]);
  for (let i = 0; i < missing.length; i += 30) {
    const batch = missing.slice(i, i + 30);
    try {
      const res = await fetch(`${API_BASE}/api/translate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ lang, texts: batch }),
      });
      if (!res.ok) continue;
      const { items } = await res.json();
      batch.forEach((s, k) => { if (items && items[k]) cache[s] = items[k]; });
      saveCache();
      onUpdate && onUpdate();
    } catch (_) { /* offline: English stays */ }
  }
}

/** Fills elements marked data-t / data-ph with their text. */
export function translatePage(root = document) {
  root.querySelectorAll('[data-t]').forEach((el) => { el.textContent = t(el.dataset.t); });
  root.querySelectorAll('[data-ph]').forEach((el) => { el.placeholder = t(el.dataset.ph); });
}

/** Puts help text into an element, right to left for Arabic. */
export function setHelp(el, english) {
  el.textContent = t(english);
  el.dir = isRtl ? 'rtl' : 'ltr';
}
