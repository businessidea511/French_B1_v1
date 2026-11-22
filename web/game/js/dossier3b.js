// Le Dossier Bruxelles — A2, stage 4 : « La librairie Le Phénix ».
// Three in the morning, in Victor's bookshop: who is Victor really?
// A2 grammar: negations (ne… plus, ne… jamais, ne… rien, ne… personne),
// the imparfait for the past (habits, descriptions), venir de + infinitive,
// être en train de, depuis.

export const CHAPTER = {
  id: '3b',
  title: 'La librairie Le Phénix',
  level: 'A2',
  world: 'office',
  layout: 'librairie',
  saveKey: 'dossier_save_3b',
  spawn: [0, 16.2, Math.PI],
  respawn: [0, 15.6, Math.PI],
  lights: [[0, 2.6, 12, '#ffd59a'], [-7, 2.6, -1, '#ffe2b8'], [7, 2.6, -1, '#ffcf9a'], [0, 2.6, -12, '#9fb4ff'], [-10, 2.6, 7, '#ffd59a']],
  places: [{ id: 'presse', x: 0, z: -9.6, y: 2.4, symbol: '?' }],
  locks: [
    { rect: [-8.5, -5.5, 3.1, 4.9], flag: 'elise', say: 'Élise wants to talk to you first. She is near the cash desk.' },
    { rect: [5.5, 8.5, 3.1, 4.9], flag: 'elise', say: 'This is private. Talk to Élise first.' },
    { rect: [-9.5, -6.5, -6.9, -5.1], clue: 'cle', say: 'The printing room is locked. The key must be in the office.' },
  ],
  agents: [
    { id: 'bureau', path: [[-12.4, -3], [-4.2, -3]], guards: 'enveloppe' },
    { id: 'imprimerie', path: [[-11, -9], [-3.4, -9]], guards: 'photo' },
    { id: 'chef', path: [[3.6, -10.2]], chief: true },
  ],
  next: 'Niveau B1 : Le Laboratoire Lumen',
  doneIcon: '🎧',
};

export const LINES = {
  agentName: 'Un homme en gris', chiefName: 'Le chef des hommes en gris',
  agentVoice: { voice: 'henri', speed: 0.95 }, chiefVoice: { voice: 'remy', speed: 0.9 },
  agentIntro: "Qu'est-ce que vous faites ici, à trois heures du matin ?", chiefIntro: 'Victor m\'a dit que vous étiez ici.',
  release: 'Bon. Allez vous coucher.', storyAsk: "Qu'est-ce que vous cherchez dans cette librairie ?",
  caught: 'They lock you in the shop… Élise opens the door for you.',
};

export const BANKS = [
  { kind: 'phrase', icon: '🚫', help: 'Negations: ne… plus, ne… jamais, ne… rien, ne… personne.', items: [
    ['Vous travaillez encore ici ?', 'Non, je ne travaille plus ici.', ['Non, je ne travaille pas plus ici.', 'Non, je travaille ne plus ici.'], 'Do you still work here?'],
    ["Vous avez vu quelqu'un ?", "Non, je n'ai vu personne.", ["Non, je n'ai personne vu.", "Non, je n'ai pas vu personne."], 'Did you see anyone?'],
    ['Vous avez entendu quelque chose ?', "Non, je n'ai rien entendu.", ["Non, je n'ai entendu rien.", "Non, je n'ai pas rien entendu."], 'Did you hear anything?'],
    ['Vous venez souvent à Liège ?', 'Non, je ne viens jamais à Liège.', ['Non, je viens jamais ne à Liège.', 'Non, je ne viens pas jamais à Liège.'], 'Do you often come to Liège?'],
    ['Vous fumez ?', 'Non, je ne fume plus.', ['Non, je fume ne plus.', 'Non, je ne plus fume.'], 'Do you smoke?'],
    ["Il y a quelqu'un dans la cave ?", "Non, il n'y a personne.", ['Non, il y a ne personne.', "Non, il n'y a pas personne."], 'Is there anyone in the cellar?'],
  ] },
  { kind: 'phrase', icon: '🕰️', help: 'The imparfait (was doing, used to), venir de (just did), être en train de (busy doing).', items: [
    ["Qu'est-ce que vous faisiez à minuit ?", 'Je dormais.', ["J'ai dormais.", 'Je dormi.'], 'What were you doing at midnight?'],
    ['Vous étiez où ?', "J'étais dans la librairie.", ['Je étais dans la librairie.', "J'été dans la librairie."], 'Where were you?'],
    ["Qu'est-ce que vous faites là ?", 'Je suis en train de lire.', ['Je suis en train lire.', 'Je suis en train de lis.'], 'What are you doing there?'],
    ["Vous venez d'arriver ?", "Oui, je viens d'arriver.", ['Oui, je viens arriver.', 'Oui, je viens de arrivé.'], 'Have you just arrived?'],
    ['Avant, vous lisiez beaucoup ?', 'Oui, je lisais tous les soirs.', ["Oui, j'ai lisais tous les soirs.", 'Oui, je lis tous les soirs hier.'], 'Before, did you read a lot?'],
    ['Il faisait quel temps ?', 'Il pleuvait.', ['Il pleuvoir.', 'Il a pleuvait.'], 'What was the weather like?'],
  ] },
  { kind: 'ecoute', icon: '🔢', help: 'Listen carefully to the time or the price.', gens: ['heure', 'prix'] },
];

export const CLUES = [
  { key: 'carte', where: 'In the shop, next to the cash desk.', art: 'la', noun: 'carte de visite', g: 'f', en: 'the business card', emoji: '📇', x: 1.8, z: 8.6,
    noteFr: 'Une carte de visite dans la caisse : « Lenoir — Directeur, Lumen ». Au dos : « Appelez-moi. »',
    note: 'A business card in the till: « Lenoir — Director, Lumen ». On the back: « Call me. »' },
  { key: 'releve', where: "In Victor's office, near the door.", art: 'le', noun: 'relevé de téléphone', g: 'm', en: 'the phone bill', emoji: '🧾', x: -10.5, z: 2.4,
    noteFr: 'Le relevé de téléphone de Victor : le même numéro, tous les soirs à minuit. Le numéro de Lumen.',
    note: "Victor's phone bill: the same number, every night at midnight. Lumen's number." },
  { key: 'cle', where: "In Victor's office, next to his desk.", art: 'la', noun: "clé de l'imprimerie", g: 'f', en: 'the key to the printing room', emoji: '🗝️', x: -5.2, z: 1.6,
    noteFr: "La clé de l'imprimerie, cachée sous un livre, à côté du bureau.",
    note: 'The key to the printing room, hidden under a book, next to the desk.' },
  { key: 'enveloppe', where: "At the back of Victor's office, near the safe. A man in grey is searching there.", art: "l'", noun: 'enveloppe de Lumen', g: 'f', en: 'the Lumen envelope', emoji: '✉️', x: -9.6, z: -4.6,
    noteFr: "Une enveloppe de Lumen, vide. Dessus : « Pour V. — Lina va bien. »",
    note: 'An empty Lumen envelope. On it: « For V. — Lina is fine. »' },
  { key: 'dessin', given: true, where: "Victor's mother gives it to you, upstairs.", art: 'le', noun: 'dessin de Lina', g: 'm', en: "Lina's drawing", emoji: '🖍️',
    noteFr: 'Un dessin de Lina, huit ans : un papa et une petite fille. « Pour papa. Je t\'aime. »',
    note: 'A drawing by Lina, eight years old: a dad and a little girl. « For daddy. I love you. »' },
  { key: 'cartable', where: "In the flat (PRIVÉ), near Lina's bed.", art: 'le', noun: 'cartable de Lina', g: 'm', en: "Lina's school bag", emoji: '🎒', x: 9, z: -0.6,
    noteFr: "Le cartable de Lina, prêt pour l'école… depuis trois jours.",
    note: "Lina's school bag, ready for school… for three days now." },
  { key: 'photo', where: 'In the printing room, on the left. A man in grey walks there.', art: 'les', noun: 'photos', g: 'f', en: 'the photos', emoji: '📷', x: -10, z: -11.6,
    noteFr: "Des photos de toi et d'Élise, prises cette nuit. Quelqu'un vous espionne.",
    note: 'Photos of you and Élise, taken tonight. Someone is spying on you.' },
  { key: 'plan', where: 'In the printing room, behind the old press.', art: 'le', noun: 'plan de Lumen', g: 'm', en: 'the plan of Lumen', emoji: '🗺️', x: 4.5, z: -15.6,
    noteFr: 'Un plan du siège de Lumen, imprimé ici. Une croix rouge : « Salle des serveurs ».',
    note: "A plan of Lumen's headquarters, printed here. A red cross: « Server room »." },
];

export const STORY = [
  { emoji: '📚', fr: 'Trois heures du matin. La librairie Le Phénix est silencieuse.', en: 'Three in the morning. The Phénix bookshop is silent.' },
  { emoji: '📞', fr: 'Tu as entendu Victor au téléphone avec Lenoir. Maintenant, il est sorti.', en: 'You heard Victor on the phone with Lenoir. Now, he has gone out.' },
  { emoji: '👩', fr: "Élise ne dort pas. Elle t'attend en bas, dans la librairie.", en: 'Élise is not sleeping. She is waiting for you downstairs, in the bookshop.' },
  { emoji: '🕵️', fr: 'Fouille la librairie, {name}. Qui est vraiment Victor ?', en: 'Search the bookshop, {name}. Who is Victor really?' },
];

export const PEOPLE = {
  elise: {
    name: 'Élise', avatar: '👩', voice: { voice: 'charline', speed: 0.98 },
    pos: [-2.4, 8.8], face: 0,
    look: { skin: '#f0caa8', hair: '#3a2416', longHair: true, coat: '#a8231f', coatLong: true, pants: '#1a1a1d', height: 0.97 },
  },
  odile: {
    name: 'Odile, la mère de Victor', avatar: '👵', voice: { voice: 'vivienne', speed: 0.88 },
    pos: [5.4, 2], face: 0,
    look: { skin: '#e8c6a8', hair: '#bdbdbd', coat: '#4a3a5a', coatLong: true, pants: '#2a2228', glasses: true, height: 0.92 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const VICTOR = { name: 'Victor', avatar: '📚', voice: { voice: 'remy', speed: 0.92 } };
export const CHIEF = { name: 'Le chef des hommes en gris', avatar: '🕴️', voice: { voice: 'remy', speed: 0.88 } };

const ELISE = [
  { fr: "Tu ne dors pas non plus ? Moi, je n'arrive plus à dormir.", en: 'You are not sleeping either? I cannot sleep any more.' },
  {
    fr: '(Dis-lui que tu as entendu Victor au téléphone.)', en: '(Tell her you heard Victor on the phone.)',
    hint: 'entendre → avoir + entendu.',
    choices: [
      { fr: "J'ai entendu Victor au téléphone avec Lenoir.", en: 'I heard Victor on the phone with Lenoir.', ok: true },
      { fr: 'Je suis entendu Victor au téléphone avec Lenoir.', en: '(wrong helper verb)' },
      { fr: "J'ai entendre Victor au téléphone avec Lenoir.", en: '(infinitive instead of past participle)' },
    ],
  },
  { fr: "Quoi ? Victor ? C'est impossible… Je le connais depuis dix ans !", en: 'What? Victor? Impossible… I have known him for ten years!' },
  { fr: 'Avant, il était journaliste, comme moi. Il écrivait des articles contre les grandes entreprises.', en: 'Before, he was a journalist, like me. He used to write articles against big companies.' },
  {
    fr: '(Demande-lui où est Victor maintenant.)', en: '(Ask her where Victor is now.)',
    hint: '« Où est… ? » with one person: est.',
    choices: [
      { fr: 'Où est Victor maintenant ?', en: 'Where is Victor now?', ok: true },
      { fr: 'Où sont Victor maintenant ?', en: '(wrong verb form)' },
      { fr: 'Où Victor maintenant est ?', en: '(wrong word order)' },
    ],
  },
  { fr: 'Il vient de sortir. Il a dit : « Je vais chercher du pain. » À trois heures du matin…', en: 'He has just gone out. He said: « I am going to get some bread. » At three in the morning…' },
  { fr: "Bon. On fouille son bureau. Mais doucement : il y a peut-être quelqu'un dans la maison.", en: 'All right. We search his office. But quietly: there may be someone in the house.' },
];

const ODILE = [
  {
    fr: "Qui est là ? Victor, c'est toi ?", en: 'Who is there? Victor, is that you?',
    hint: 'Answer politely and say who you are.',
    choices: [
      { fr: "Non, madame. Je travaille avec Élise.", en: 'No, madam. I work with Élise.', ok: true },
      { fr: 'Non, madame. Je suis Victor.', en: 'No, madam. I am Victor.' },
      { fr: 'Non, tu es Élise.', en: 'No, you are Élise.' },
    ],
  },
  { fr: 'Ah… La journaliste. Moi, je suis Odile, la mère de Victor.', en: 'Ah… The journalist. I am Odile, Victor\'s mother.' },
  { fr: "Excusez-moi, je ne dors plus. Ma petite-fille, Lina, n'est pas à la maison.", en: 'Excuse me, I do not sleep any more. My granddaughter, Lina, is not at home.' },
  {
    fr: '(Demande-lui depuis quand.)', en: '(Ask her since when.)',
    hint: '« depuis quand » = since when / for how long.',
    choices: [
      { fr: "Depuis quand elle n'est pas là ?", en: 'Since when has she not been here?', ok: true },
      { fr: "Il y a quand elle n'est pas là ?", en: '(« il y a » needs a time: il y a trois jours)' },
      { fr: "Pendant quand elle n'est pas là ?", en: '(this means nothing)' },
    ],
  },
  { fr: "Depuis mardi. Avant, elle venait me voir tous les jours après l'école. Elle dessinait ici, sur cette table.", en: 'Since Tuesday. Before, she came to see me every day after school. She used to draw here, on this table.' },
  { fr: 'Victor dit qu\'elle est chez sa tante. Mais il ment. Je le vois dans ses yeux.', en: 'Victor says she is at her aunt\'s. But he is lying. I can see it in his eyes.' },
  { fr: "Tenez, c'est son dernier dessin. Pour son papa.", en: 'Here, this is her last drawing. For her dad.' },
  { fr: "Si vous trouvez quelque chose… dites-le-moi. S'il vous plaît.", en: 'If you find something… tell me. Please.' },
];

const CHIEF_MEET = [
  { fr: 'Vous cherchez la vérité, vous aussi ?', en: 'You are looking for the truth, too?' },
  { fr: "Ici, il n'y a rien pour vous. Mais je vais quand même vous poser quelques questions.", en: 'There is nothing for you here. But I am going to ask you a few questions anyway.' },
];

const ENDING = [
  { who: CHIEF, fr: "Bon. La clé USB n'est pas ici. Dites à votre ami Victor… qu'on attend toujours.", en: 'Fine. The USB key is not here. Tell your friend Victor… that we are still waiting.' },
  { who: YOU, fr: "(Il part par la porte de la cour. Victor travaille avec eux… mais pourquoi ?)", en: '(He leaves through the courtyard door. Victor works with them… but why?)' },
  { who: PEOPLE.elise, fr: "J'ai entendu du bruit ! Ça va ? Tu as trouvé quelque chose ?", en: 'I heard a noise! Are you all right? Did you find something?' },
  {
    who: YOU, fr: '(Dis-lui que Victor parle à Lumen depuis des semaines.)', en: '(Tell her that Victor has been talking to Lumen for weeks.)',
    hint: 'depuis + present tense: « il parle… depuis… ».',
    choices: [
      { fr: 'Victor parle à Lumen depuis des semaines.', en: 'Victor has been talking to Lumen for weeks.', ok: true },
      { fr: 'Victor parle à Lumen il y a des semaines.', en: '(« il y a » is for a finished action)' },
      { fr: 'Victor a parlé à Lumen depuis des semaines.', en: '(with « depuis », use the present)' },
    ],
  },
  { who: PEOPLE.elise, fr: 'Et sa fille a disparu… Je ne comprends plus rien.', en: 'And his daughter has disappeared… I do not understand anything any more.' },
  { who: PEOPLE.elise, fr: "Demain soir, on va chez Lumen quand même. Mais on ne lui dit plus tout.", en: 'Tomorrow evening, we go to Lumen anyway. But we do not tell him everything any more.' },
  { who: PEOPLE.elise, fr: 'Prends cette oreillette. Je te parlerai pendant toute la mission.', en: 'Take this earpiece. I will talk to you during the whole mission.' },
  { who: YOU, fr: '(La porte de la librairie s\'ouvre. Victor rentre, avec du pain. Il sourit.)', en: '(The bookshop door opens. Victor comes back, with bread. He smiles.)' },
  { who: VICTOR, fr: 'Vous ne dormez pas ? Allez vous reposer. Demain sera une longue journée…', en: 'You are not sleeping? Go and rest. Tomorrow will be a long day…' },
];

export function objective(s) {
  if (!s.flags.elise) return 'Talk to Élise, near the cash desk.';
  if (!['releve', 'enveloppe', 'cle'].every((k) => s.found.includes(k))) return "Search Victor's office (BUREAU). Clues: {n}/{total}. Someone is inside…";
  if (!s.flags.odile) return 'Someone is awake behind the door PRIVÉ. Go and see.';
  if (s.found.length < CLUES.length) return 'Find all the clues ({n}/{total}). The key opens the printing room (IMPRIMERIE).';
  if (!s.flags.done) return 'Go down to the printing room, to the old press.';
  return 'Stage complete! Next: level B1, the Lumen laboratory.';
}

export function hasNews(id, s) {
  if (id === 'elise') return !s.flags.elise;
  if (id === 'odile') return s.flags.elise && ['releve', 'enveloppe', 'cle'].every((k) => s.found.includes(k)) && !s.flags.odile;
  if (id === 'presse') return s.flags.odile && s.found.length >= CLUES.length && !s.flags.done;
  return false;
}

export async function afterClue(g) {
  const s = g.state;
  if (s.flags.elise && ['releve', 'enveloppe', 'cle'].every((k) => s.found.includes(k)) && !s.flags.officeTold) {
    s.flags.officeTold = true;
    g.save();
    g.ui.toast('A light is on behind the door PRIVÉ. Someone is awake.', 3200);
  }
  if (s.found.length >= CLUES.length && s.flags.odile && !s.flags.allTold) {
    s.flags.allTold = true;
    g.save();
    g.ui.toast('A noise in the printing room… Go to the old press.', 3200);
  }
  return false;
}

const SHORT = {
  eliseAgain: { fr: 'Le bureau de Victor, à gauche. Doucement…', en: "Victor's office, on the left. Quietly…" },
  eliseDone: { fr: 'Repose-toi un peu. Demain, on va chez Lumen.', en: 'Rest a little. Tomorrow, we go to Lumen.' },
  odileEarly: { fr: "(Quelqu'un pleure doucement derrière la porte.)", en: '(Someone is crying quietly behind the door.)' },
  odileAgain: { fr: 'Trouvez Lina. Je vous en prie.', en: 'Find Lina. I beg you.' },
  presseEarly: { fr: "(Une vieille presse. Je n'ai pas encore tous les indices.)", en: '(An old press. I do not have all the clues yet.)' },
  presseDone: { fr: '(Demain soir : Lumen. Et Victor sera avec nous…)', en: '(Tomorrow evening: Lumen. And Victor will be with us…)' },
};
const STORY_WORDS = ['Je', 'ne', 'cherche', 'rien.', 'Je', 'lisais', 'un', 'livre.'];

export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'elise') {
    if (s.flags.done) return g.ui.talk(P.elise, [SHORT.eliseDone]);
    if (s.flags.elise) return g.ui.talk(P.elise, [SHORT.eliseAgain]);
    s.mistakes += await g.ui.talk(P.elise, ELISE);
    s.flags.elise = true;
    g.save();
    g.ui.toast("Victor's office (BUREAU) is open.", 2800);
  } else if (id === 'odile') {
    if (!hasNews('odile', s) && !s.flags.odile) return g.ui.talk(YOU, [SHORT.odileEarly]);
    if (s.flags.odile) return g.ui.talk(P.odile, [SHORT.odileAgain]);
    s.mistakes += await g.ui.talk(P.odile, ODILE.slice(0, 7));
    await g.give('dessin');
    s.mistakes += await g.ui.talk(P.odile, ODILE.slice(7));
    s.flags.odile = true;
    g.save();
    await afterClue(g);
  } else if (id === 'presse') {
    if (s.flags.done) return g.ui.talk(YOU, [SHORT.presseDone]);
    if (!hasNews('presse', s)) return g.ui.talk(YOU, [SHORT.presseEarly]);
    await g.ui.talk(CHIEF, CHIEF_MEET);
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(STORY_WORDS);
    s.mistakes += await g.ui.talk(CHIEF, ENDING);
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
}

export function allTexts() {
  const out = [];
  for (const n of [ELISE, ODILE, CHIEF_MEET, ENDING, STORY, Object.values(SHORT)].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note, c.where);
  for (const l of CHAPTER.locks) out.push(l.say);
  out.push(
    'Talk to Élise, near the cash desk.', "Search Victor's office (BUREAU). Clues: {n}/{total}. Someone is inside…",
    'Someone is awake behind the door PRIVÉ. Go and see.', 'Find all the clues ({n}/{total}). The key opens the printing room (IMPRIMERIE).',
    'Go down to the printing room, to the old press.', 'Stage complete! Next: level B1, the Lumen laboratory.',
    "Victor's office (BUREAU) is open.", 'A light is on behind the door PRIVÉ. Someone is awake.', 'A noise in the printing room… Go to the old press.',
    'A man in grey guards this clue. Get past him first.', 'Hint', 'Stage complete!', 'Next stage',
  );
  return out.filter(Boolean);
}

export function voiceLines() {
  const P = PEOPLE;
  const out = [];
  const talk = (speaker, nodes) => {
    for (const n of nodes) {
      out.push([n.fr, (n.who || speaker).voice]);
      for (const c of n.choices || []) if (c.ok) out.push([c.fr, { voice: 'denise' }]);
    }
  };
  talk(P.elise, [...ELISE, SHORT.eliseAgain, SHORT.eliseDone]);
  talk(P.odile, [...ODILE, SHORT.odileAgain]);
  talk(CHIEF, [...CHIEF_MEET, ...ENDING]);
  talk(YOU, [SHORT.odileEarly, SHORT.presseEarly, SHORT.presseDone]);
  STORY.forEach((st, i) => out.push([st.fr, { voice: i === 0 ? 'charline' : 'denise' }]));
  for (const c of CLUES) {
    out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
    out.push([c.noteFr, { voice: 'denise' }]);
  }
  out.push([STORY_WORDS.join(' '), { voice: 'denise' }]);
  return out;
}
