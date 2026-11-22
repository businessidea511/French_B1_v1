// Le Dossier Bruxelles — Chapitre 2 : « La Gare du Midi » (A2).
// The passé composé (avoir / être), asking for directions, buying a ticket,
// times and platforms. Every line is written here: no AI call to play.

export const CHAPTER = {
  id: 2,
  title: 'Chapitre 2 : La Gare du Midi',
  level: 'A2',
  world: 'station',
  saveKey: 'dossier_save_ch2',
  spawn: [0, 16.5, Math.PI],
  respawn: [0, 16, Math.PI],
  lights: [[-5, 8, 2, '#d6e4ff'], [5, 8, 12, '#d6e4ff'], [-13, 3, 17, '#ffb36b'], [15, 3, 5, '#d6e4ff'], [-15, 3, 6, '#ffd9a0'], [0, 4, -14, '#d6e4ff']],
  places: [
    { id: 'casier', x: 16.2, z: 4.5, y: 2.2, symbol: '7' },
    { id: 'quai', x: 0, z: -3.9, y: 2.4, symbol: '?' },
  ],
  agents: [
    { id: 'casiers', path: [[13.6, 12], [13.6, 0.6]], guards: 'badge' },
    { id: 'cafe', path: [[-6.8, 16.6], [-6.8, 11.5]], guards: 'gant' },
    { id: 'controleur', path: [[0, -5.4]], chief: true,
      look: { skin: '#e2b896', coat: '#1f3a6b', pants: '#1a2440', hat: 'cap', hatColor: '#1f3a6b', shirt: '#dfe6f0', height: 1.03 } },
  ],
  next: 'Chapitre 3 : Liège',
  doneIcon: '🚆',
};

export const LINES = {
  agentName: 'Un homme en gris', chiefName: 'Le contrôleur',
  agentVoice: { voice: 'henri', speed: 0.95 }, chiefVoice: { voice: 'gerard', speed: 0.92 },
  agentIntro: 'Pardon. Vous attendez un train ?', chiefIntro: 'Billets, s\'il vous plaît. Contrôle.',
  release: 'Bon… Ça va. Bonne soirée.', storyAsk: 'Expliquez-moi votre voyage.',
  caught: 'They take you to the station office… then let you go. You are back at the entrance.',
};

export const BANKS = [
  { kind: 'phrase', icon: '⏪', help: 'Answer in the passé composé (avoir or être + past participle).', items: [
    ["Qu'est-ce que vous avez fait ce soir ?", "J'ai mangé au café.", ['Je suis mangé au café.', "J'ai manger au café."], 'What did you do tonight?'],
    ['Vous êtes arrivé quand ?', 'Je suis arrivé à vingt-trois heures.', ["J'ai arrivé à vingt-trois heures.", 'Je suis arriver à vingt-trois heures.'], 'When did you arrive?'],
    ['Vous avez acheté un billet ?', "Oui, j'ai acheté un billet.", ['Oui, je suis acheté un billet.', "Oui, j'ai achète un billet."], 'Did you buy a ticket?'],
    ['Vous avez vu une femme en manteau rouge ?', "Non, je n'ai vu personne.", ["Non, je n'ai pas vu personne.", 'Non, je ne suis vu personne.'], 'Did you see a woman in a red coat?'],
    ['Où est-ce que vous êtes allé hier ?', 'Je suis allé au musée.', ["J'ai allé au musée.", 'Je suis aller au musée.'], 'Where did you go yesterday?'],
    ['Vous avez pris le métro ?', "Oui, j'ai pris le métro.", ["Oui, j'ai prendu le métro.", 'Oui, je suis pris le métro.'], 'Did you take the metro?'],
    ['Vous êtes venu seul ?', 'Oui, je suis venu seul.', ["Oui, j'ai venu seul.", 'Oui, je suis venir seul.'], 'Did you come alone?'],
    ["Qu'est-ce que vous avez bu ?", "J'ai bu un thé.", ["J'ai buvé un thé.", 'Je suis bu un thé.'], 'What did you drink?'],
  ] },
  { kind: 'ecoute', icon: '🚉', help: 'Listen: platform or time.', gens: ['quai', 'depart'] },
  { kind: 'phrase', icon: '🧳', help: 'Answer like a real traveller.', items: [
    ['Vous allez où ?', 'Je vais à Liège.', ['Je vais au Liège.', 'Je va à Liège.'], 'Where are you going?'],
    ["C'est un aller simple ou un aller-retour ?", "Un aller simple, s'il vous plaît.", ["Une aller simple, s'il vous plaît.", 'Un aller simple de vous plaît.'], 'Is it a one-way or a return ticket?'],
    ['Votre train part de quel quai ?', 'Il part du quai trois.', ['Il part de le quai trois.', 'Il part au quai trois.'], 'Which platform does your train leave from?'],
    ['Vous voyagez avec une valise ?', 'Non, je voyage avec un sac.', ['Non, je voyage avec une sac.', 'Non, je voyage avec un sacs.'], 'Are you travelling with a suitcase?'],
    ['Vous descendez à quelle gare ?', 'Je descends à Liège-Guillemins.', ['Je descend à Liège-Guillemins.', 'Je descends au Liège-Guillemins.'], 'At which station do you get off?'],
    ['Vous savez où est la sortie ?', 'Oui, tout droit, puis à droite.', ['Oui, tout droite, puis à droit.', 'Oui, tout droit, puis la droite de.'], 'Do you know where the exit is?'],
  ] },
];

export const CLUES = [
  { key: 'valise', art: 'la', noun: 'valise', g: 'f', en: 'the suitcase', emoji: '🧳', x: 7.8, z: 7.2,
    note: 'A small suitcase with a tag: « É. M. ». Empty… someone searched it.' },
  { key: 'horaire', art: "l'", noun: 'horaire', g: 'm', en: 'the timetable', emoji: '📋', x: -6.5, z: -3.4,
    note: 'A timetable. The 23:50 train to Liège is circled in red.' },
  { key: 'badge', art: 'le', noun: 'badge', g: 'm', en: 'the badge', emoji: '🪪', x: 15.4, z: 11.6,
    note: 'A badge: « LUMEN — Accès niveau 3 ». A man in grey lost it.' },
  { key: 'gant', art: 'le', noun: 'gant', g: 'm', en: 'the glove', emoji: '🧤', x: -7.8, z: 14.2,
    note: 'A grey leather glove. The men in grey were here, close to the café.' },
  { key: 'plan', art: 'le', noun: 'plan de Liège', g: 'm', en: 'the map of Liège', emoji: '🗺️', x: -12.2, z: 13.2,
    note: 'A map of Liège. A cross near the Guillemins station.' },
  { key: 'enveloppe', art: "l'", noun: 'enveloppe', g: 'f', en: 'the envelope', emoji: '✉️', given: true,
    note: "Élise's envelope, from locker 7: a letter and photos of secret documents." },
  { key: 'usb', art: 'la', noun: 'clé USB', g: 'f', en: 'the USB key', emoji: '💾', given: true,
    note: 'A USB key from locker 7. On it, in Élise\'s writing: « PREUVES ».' },
  { key: 'billet', art: 'le', noun: 'billet', g: 'm', en: 'the ticket', emoji: '🎟️', given: true,
    note: 'A one-way ticket to Liège: 23:50, platform 3, car 8.' },
];

export const STORY = [
  { emoji: '🚉', fr: 'Gare du Midi, vingt-trois heures quarante. Le dernier grand train est parti. La gare est presque vide.', en: 'Midi station, 11:40 p.m. The last big train has left. The station is almost empty.' },
  { emoji: '🔑', fr: "Dans ta poche : la petite clé d'Élise. « Casier 7 ».", en: "In your pocket: Élise's little key. « Locker 7 »." },
  { emoji: '🕴️', fr: 'Mais les hommes en gris sont déjà là. Ils t\'attendent.', en: 'But the men in grey are already here. They are waiting for you.' },
  { emoji: '🎯', fr: "Trouve le casier sept, {name}. Et découvre ce qu'Élise a caché.", en: 'Find locker seven, {name}. And find out what Élise has hidden.' },
];

export const PEOPLE = {
  nadia: {
    name: 'Nadia, au guichet', avatar: '👩‍💼', voice: { voice: 'charline', speed: 0.95 },
    pos: [-17.2, 6], face: Math.PI / 2,
    look: { skin: '#c99a76', hair: '#2a1a12', longHair: true, coat: '#1f4f9c', pants: '#1a1d24', scarf: '#e8c33a', height: 0.96 },
  },
  lucien: {
    name: "Lucien, l'agent de nettoyage", avatar: '🧹', voice: { voice: 'henri', speed: 0.9 },
    pos: [-2.4, 1.2], face: 0,
    look: { skin: '#e0b48e', hair: '#9a9a9a', beard: '#9a9a9a', coat: '#3b5a3a', pants: '#2a3528', hat: 'cap', hatColor: '#2a3528', height: 0.97 },
  },
  ines: {
    name: 'Inès, café Le Quai', avatar: '☕', voice: { voice: 'vivienne', speed: 0.98 },
    pos: [-13, 19.1], face: Math.PI,
    look: { skin: '#f0c9a8', hair: '#8a3a1e', longHair: true, coat: '#2a2a2e', shirt: '#ffffff', apron: '#7a3a2a', pants: '#1a1a1d', height: 0.95 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const LETTER = { name: "La lettre d'Élise", avatar: '✉️', voice: { voice: 'charline', speed: 0.92 } };
export const INSPECTOR = { name: 'Le contrôleur', avatar: '🎫', voice: { voice: 'gerard', speed: 0.92 } };

const NADIA_FIRST = [
  { fr: 'Bonsoir. Les guichets ferment dans dix minutes.', en: 'Good evening. The ticket office closes in ten minutes.' },
  {
    fr: '(Demande-lui où sont les casiers.)', en: '(Ask her where the lockers are.)',
    hint: 'Ask politely: « Excusez-moi, où sont les casiers, s\'il vous plaît ? ».',
    choices: [
      { fr: "Excusez-moi, où sont les casiers, s'il vous plaît ?", en: 'Excuse me, where are the lockers, please?', ok: true },
      { fr: 'Où est la casier ?', en: '(wrong article and verb)' },
      { fr: 'Je voudrais manger un casier.', en: 'I would like to eat a locker.' },
    ],
  },
  { fr: "Les casiers ? Allez tout droit, puis tournez à droite. C'est au fond de la gare, à droite.", en: 'The lockers? Go straight on, then turn right. They are at the back of the station, on the right.' },
  {
    fr: '(Les casiers sont où ?)', en: '(Where are the lockers?)',
    hint: '« à droite » = on the right; « au fond » = at the back.',
    choices: [
      { fr: 'À droite, au fond de la gare.', en: 'On the right, at the back of the station.', ok: true },
      { fr: "À gauche, près de l'entrée.", en: 'On the left, near the entrance.' },
      { fr: 'Sur le quai numéro trois.', en: 'On platform number three.' },
    ],
  },
  { fr: 'Et faites attention à vos affaires. Il y a des gens bizarres, ce soir…', en: 'And watch your things. There are strange people here tonight…' },
];

const NADIA_TICKET = [
  { fr: 'Encore vous ? Vous voulez un billet ?', en: 'You again? Do you want a ticket?' },
  {
    fr: '(Achète un billet pour Liège.)', en: '(Buy a ticket to Liège.)',
    hint: 'A one-way ticket = « un aller simple »; to a city = « pour Liège ».',
    choices: [
      { fr: "Oui, je voudrais un aller simple pour Liège, s'il vous plaît.", en: 'Yes, I would like a one-way ticket to Liège, please.', ok: true },
      { fr: 'Oui, je veux aller simple Liège.', en: '(not a correct sentence)' },
      { fr: "Oui, je voudrais un aller-retour pour Paris, s'il vous plaît.", en: 'Yes, I would like a return ticket to Paris, please.' },
    ],
  },
  {
    fr: 'Le train pour Liège part à vingt-trois heures cinquante, quai trois.', en: 'The train to Liège leaves at 11:50 p.m., platform three.', listen: true,
    hint: 'Listen again (🔊). « vingt-trois heures cinquante » = 23:50, « quai trois » = platform 3.',
    choices: [{ fr: '23:50 · quai 3', ok: true }, { fr: '23:15 · quai 3' }, { fr: '23:50 · quai 13' }],
  },
  {
    fr: "Ça fait vingt-quatre euros, s'il vous plaît.", en: 'That is twenty-four euros, please.', listen: true,
    hint: 'Listen again (🔊). « vingt-quatre » = 24.',
    choices: [{ fr: '24 €', ok: true }, { fr: '14 €' }, { fr: '20,04 €' }],
  },
  { fr: 'Voilà votre billet. Voiture huit. Bon voyage !', en: 'Here is your ticket. Car eight. Have a good trip!' },
];

const LUCIEN = [
  { fr: '(Il passe la serpillière.) Hmm ? Vous cherchez quelqu\'un ?', en: '(He is mopping the floor.) Hmm? Are you looking for someone?' },
  {
    fr: '(Montre-lui la photo d\'Élise.)', en: "(Show him Élise's photo.)",
    hint: 'Passé composé with avoir: « vous avez vu » (you saw).',
    choices: [
      { fr: 'Oui. Vous avez vu cette femme ?', en: 'Yes. Did you see this woman?', ok: true },
      { fr: 'Oui. Vous avez voir cette femme ?', en: '(wrong verb form)' },
      { fr: 'Oui. Vous êtes vu cette femme ?', en: '(wrong helping verb)' },
    ],
  },
  { fr: 'Elle ? Oui… Elle est venue ici il y a trois jours. Elle a ouvert un casier.', en: 'Her? Yes… She came here three days ago. She opened a locker.' },
  { fr: "Et après, elle est partie vers les quais. Un homme en gris l'a suivie.", en: 'And then she went towards the platforms. A man in grey followed her.' },
  {
    fr: "(Qu'est-ce qu'Élise a fait ?)", en: '(What did Élise do?)',
    hint: 'Listen to Lucien again: « elle a ouvert un casier… elle est partie vers les quais ».',
    choices: [
      { fr: 'Elle a ouvert un casier et elle est partie vers les quais.', en: 'She opened a locker and went towards the platforms.', ok: true },
      { fr: 'Elle a pris un café et elle est rentrée chez elle.', en: 'She had a coffee and went home.' },
      { fr: 'Elle a acheté un journal et elle a dormi ici.', en: 'She bought a newspaper and slept here.' },
    ],
  },
  { fr: "Moi, je n'ai rien vu, d'accord ? Rien du tout.", en: 'Me, I saw nothing, OK? Nothing at all.' },
];

const INES = [
  { fr: 'Bonsoir ! On ferme bientôt, mais il reste du thé.', en: 'Good evening! We are closing soon, but there is still some tea.' },
  {
    fr: "Qu'est-ce que je vous sers ?", en: 'What can I get you?',
    hint: '« le thé » is masculine: « un thé ».',
    choices: [
      { fr: "Je voudrais un thé, s'il vous plaît.", en: 'I would like a tea, please.', ok: true },
      { fr: "Je voudrais une thé, s'il vous plaît.", en: '(wrong article)' },
      { fr: "J'ai voulu un thé hier.", en: 'I wanted a tea yesterday.' },
    ],
  },
  {
    fr: 'Un thé, ça fait trois euros.', en: 'A tea, that is three euros.', listen: true,
    hint: 'Listen again (🔊). « trois » = 3.',
    choices: [{ fr: '3 €', ok: true }, { fr: '13 €' }, { fr: '30 €' }],
  },
  { fr: "Vous êtes l'ami d'Élise ? Elle m'a laissé un message pour vous.", en: "Are you Élise's friend? She left me a message for you." },
  {
    fr: 'Elle a dit : « Le train de Liège. Voiture numéro huit. »', en: 'She said: « The Liège train. Car number eight. »', listen: true,
    hint: 'Listen again (🔊). « huit » = 8.',
    choices: [{ fr: 'voiture 8', ok: true }, { fr: 'voiture 18' }, { fr: 'voiture 6' }],
  },
  { fr: 'Bonne chance. Et attention au contrôleur… je crois qu\'il travaille pour eux.', en: 'Good luck. And watch out for the ticket inspector… I think he works for them.' },
];

const LOCKER = [
  { fr: "(Casier numéro sept. La clé d'Élise… Elle tourne !)", en: "(Locker number seven. Élise's key… It turns!)" },
  { who: YOU, fr: '(Dedans : une enveloppe, une clé USB… et une lettre.)', en: '(Inside: an envelope, a USB key… and a letter.)' },
];

const LETTER_TEXT = [
  { fr: "« J'ai trouvé les preuves. Le projet Lumen a volé les données de toute la ville. »", en: '« I found the proof. The Lumen project stole the data of the whole city. »' },
  { fr: "« Je suis partie à Liège pour voir un ami. Il s'appelle Victor. »", en: '« I left for Liège to see a friend. His name is Victor. »' },
  {
    fr: "(Où est-ce qu'Élise est allée ?)", en: '(Where did Élise go?)',
    hint: 'Read again: « Je suis partie à Liège ».',
    choices: [
      { fr: 'Elle est allée à Liège.', en: 'She went to Liège.', ok: true },
      { fr: 'Elle est allée à Paris.', en: 'She went to Paris.' },
      { fr: 'Elle est restée à Bruxelles.', en: 'She stayed in Brussels.' },
    ],
  },
  {
    fr: '« Je ___ partie à Liège. »', en: '« I ___ left for Liège. »',
    hint: 'partir uses être in the passé composé: « je suis partie ».',
    choices: [{ fr: 'suis', ok: true }, { fr: 'ai' }, { fr: 'es' }], keepOrder: true,
  },
  { fr: '« Prends le train de vingt-trois heures cinquante. Voiture huit. Je t\'attends. — É. »', en: '« Take the 11:50 p.m. train. Car eight. I am waiting for you. — É. »' },
];

const GATE_MEET = [
  { fr: 'Halte. Le quai trois, c\'est par ici. Votre billet ?', en: 'Stop. Platform three is this way. Your ticket?' },
  { fr: 'Hmm… Avant de monter, quelques questions.', en: 'Hmm… Before you get on, a few questions.' },
];

const ENDING = [
  { who: INSPECTOR, fr: 'Bon. Montez. Voiture huit… Bon voyage.', en: 'Fine. Get on. Car eight… Have a good trip.' },
  { who: YOU, fr: '(Voiture huit. Le train part. Bruxelles disparaît dans la nuit.)', en: '(Car eight. The train leaves. Brussels disappears into the night.)' },
  { who: YOU, fr: '(Une femme en manteau rouge passe dans le couloir… Elle laisse un papier sur ton siège.)', en: '(A woman in a red coat walks down the corridor… She leaves a piece of paper on your seat.)' },
  { who: LETTER, fr: '« Tu es suivi. Ne descends pas à Liège-Guillemins. Descends une gare avant. — É. »', en: '« You are being followed. Do not get off at Liège-Guillemins. Get off one station before. — É. »' },
  { who: YOU, fr: '(Élise est dans ce train…)', en: '(Élise is on this train…)' },
];

const SHORT = {
  nadiaClosed: { fr: 'Le casier ? Tout droit, puis à droite, au fond.', en: 'The locker? Straight on, then right, at the back.' },
  nadiaAgain: { fr: 'Quai trois, vingt-trois heures cinquante. Ne le ratez pas !', en: 'Platform three, 11:50 p.m. Do not miss it!' },
  lucienAgain: { fr: "Je n'ai rien vu, je vous dis.", en: 'I saw nothing, I tell you.' },
  inesAgain: { fr: 'Voiture huit. Et faites attention.', en: 'Car eight. And be careful.' },
  lockerEarly: { fr: '(Les casiers… Mais lequel ? Il faut demander au guichet.)', en: '(The lockers… But which one? Ask at the ticket office.)' },
  lockerEmpty: { fr: '(Le casier sept est vide maintenant.)', en: '(Locker seven is empty now.)' },
  gateNoTicket: { fr: "(Le contrôleur vérifie les billets. Il me faut un billet… et tous les indices.)", en: '(The inspector checks tickets. I need a ticket… and all the clues.)' },
  gateDone: { fr: '(Prochaine étape : Liège.)', en: '(Next stop: Liège.)' },
};
const STORY_WORDS = ["J'ai", 'acheté', 'mon', 'billet', 'et', 'je', 'vais', 'à', 'Liège.'];

/** The current goal (English, translated for the player). */
export function objective(s) {
  if (!s.flags.nadia) return 'Ask at the ticket office (GUICHETS) where the lockers are.';
  if (!s.flags.casier) return "Open locker number 7 with Élise's key. Clues: {n}/{total}.";
  if (!s.flags.lucien || !s.flags.ines) return 'Talk to Lucien (the cleaner) and Inès (café Le Quai). Clues: {n}/{total}.';
  if (!s.flags.ticket) return 'Buy a ticket to Liège at the ticket office.';
  if (s.found.length < CLUES.length) return 'Find the last clues ({n}/{total}). Careful with the men in grey.';
  if (!s.flags.done) return 'Go to platform 3: the inspector checks the tickets.';
  return 'Chapter complete! Explore the station.';
}

export function hasNews(id, s) {
  if (id === 'nadia') return !s.flags.nadia || (s.flags.casier && s.flags.lucien && s.flags.ines && !s.flags.ticket);
  if (id === 'casier') return s.flags.nadia && !s.flags.casier;
  if (id === 'lucien') return s.flags.casier && !s.flags.lucien;
  if (id === 'ines') return s.flags.casier && !s.flags.ines;
  if (id === 'quai') return s.flags.ticket && s.found.length === CLUES.length && !s.flags.done;
  return false;
}

/** Talking or acting at a place. g = { ui, state, save, give, world, confrontChief, story, finish }. */
export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'nadia') {
    if (!s.flags.nadia) {
      s.mistakes += await g.ui.talk(P.nadia, NADIA_FIRST);
      s.flags.nadia = true;
    } else if (!s.flags.casier) {
      return g.ui.talk(P.nadia, [SHORT.nadiaClosed]);
    } else if (!s.flags.ticket && s.flags.lucien && s.flags.ines) {
      s.mistakes += await g.ui.talk(P.nadia, NADIA_TICKET);
      s.flags.ticket = true;
      await g.give('billet');
    } else {
      return g.ui.talk(P.nadia, [s.flags.ticket ? SHORT.nadiaAgain : SHORT.nadiaClosed]);
    }
  } else if (id === 'lucien') {
    if (s.flags.lucien || !s.flags.casier) return g.ui.talk(P.lucien, [SHORT.lucienAgain]);
    s.mistakes += await g.ui.talk(P.lucien, LUCIEN);
    s.flags.lucien = true;
  } else if (id === 'ines') {
    if (s.flags.ines) return g.ui.talk(P.ines, [SHORT.inesAgain]);
    s.mistakes += await g.ui.talk(P.ines, INES);
    s.flags.ines = true;
  } else if (id === 'casier') {
    if (!s.flags.nadia) return g.ui.talk(YOU, [SHORT.lockerEarly]);
    if (s.flags.casier) return g.ui.talk(YOU, [SHORT.lockerEmpty]);
    await g.ui.talk(YOU, LOCKER);
    s.flags.casier = true;
    g.save();
    await g.give('enveloppe');
    await g.give('usb');
    s.mistakes += await g.ui.talk(LETTER, LETTER_TEXT);
  } else if (id === 'quai') {
    if (s.flags.done) return g.ui.talk(YOU, [SHORT.gateDone]);
    if (!s.flags.ticket || s.found.length < CLUES.length) return g.ui.talk(YOU, [SHORT.gateNoTicket]);
    await g.ui.talk(INSPECTOR, GATE_MEET);
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(STORY_WORDS);
    g.world.gateOpen = true;
    await g.ui.talk(INSPECTOR, ENDING);
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
}

/** Every English text, translated in one go at the start. */
export function allTexts() {
  const out = [];
  const all = [NADIA_FIRST, NADIA_TICKET, LUCIEN, INES, LOCKER, LETTER_TEXT, GATE_MEET, ENDING, STORY, Object.values(SHORT)].flat();
  for (const n of all) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note);
  out.push(
    'Ask at the ticket office (GUICHETS) where the lockers are.', "Open locker number 7 with Élise's key. Clues: {n}/{total}.",
    'Talk to Lucien (the cleaner) and Inès (café Le Quai). Clues: {n}/{total}.', 'Buy a ticket to Liège at the ticket office.',
    'Find the last clues ({n}/{total}). Careful with the men in grey.', 'Go to platform 3: the inspector checks the tickets.',
    'Chapter complete! Explore the station.', 'A man in grey guards this clue. Get past him first.',
    'Listen and choose', 'Speak now…', 'Got it', 'I did not hear you. Try again.', 'Not quite. Try again!',
    'Case file', 'Clues found', 'Mistakes', 'Chapter 1 complete!', 'Chapter 2 complete!', 'Coming soon', 'Explore the street',
    'An investigation to learn French', 'Your name', 'Play', 'Continue', 'New game', 'Back to the app', 'Close', 'Help language',
    'The microphone is blocked. On iPhone: Settings › Safari › Microphone › Allow. Speech recognition also needs Siri to be on.',
    'The microphone is blocked. Allow it for this site in the browser settings.',
    'No microphone found, or another app is using it.', 'Speech recognition needs the internet.',
  );
  return out.filter(Boolean);
}

/** Every sentence said aloud, with its voice, to record the voices once. */
export function voiceLines() {
  const P = PEOPLE;
  const out = [];
  const talk = (speaker, nodes) => {
    for (const n of nodes) {
      out.push([n.fr, (n.who || speaker).voice]);
      for (const c of n.choices || []) if (c.ok) out.push([c.fr, { voice: 'denise' }]);
    }
  };
  talk(P.nadia, [...NADIA_FIRST, ...NADIA_TICKET, SHORT.nadiaClosed, SHORT.nadiaAgain]);
  talk(P.lucien, [...LUCIEN, SHORT.lucienAgain]);
  talk(P.ines, [...INES, SHORT.inesAgain]);
  talk(YOU, [...LOCKER, SHORT.lockerEarly, SHORT.lockerEmpty, SHORT.gateNoTicket, SHORT.gateDone]);
  talk(LETTER, LETTER_TEXT);
  talk(INSPECTOR, [...GATE_MEET, ...ENDING]);
  STORY.forEach((st) => out.push([st.fr, { voice: 'denise' }]));
  for (const c of CLUES) out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
  out.push([STORY_WORDS.join(' '), { voice: 'denise' }]);
  return out;
}
