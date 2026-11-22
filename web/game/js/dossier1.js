// Le Dossier Bruxelles — Chapitre 1 : « Rue des Ombres » (A1–A2).
// Polite French (vous), introducing yourself, ordering, prices and numbers,
// être/avoir, first questions. Every line is written here: playing costs no
// AI call; the English help is translated once for everyone.

export const CLUES = [
  { key: 'ticket', art: 'le', noun: 'ticket de métro', g: 'm', en: 'the metro ticket', emoji: '🎫', x: 3.2, z: 31,
    note: 'A metro ticket, used three days ago at Bourse station.' },
  { key: 'parapluie', art: 'le', noun: 'parapluie', g: 'm', en: 'the umbrella', emoji: '☂️', x: -5.3, z: 23,
    note: "Élise's red umbrella, left at her door. She left in a hurry." },
  { key: 'telephone', art: 'le', noun: 'téléphone', g: 'm', en: 'the phone', emoji: '📱', x: -3.6, z: 14,
    note: "Élise's phone, broken, in the gutter. Someone wanted her silent." },
  { key: 'carnet', art: 'le', noun: 'carnet', g: 'm', en: 'the notebook', emoji: '📓', x: -14.8, z: 10,
    note: "Élise's notebook. One word, underlined three times: LUMEN." },
  { key: 'cle', art: 'la', noun: 'clé', g: 'f', en: 'the key', emoji: '🔑', x: 6.2, z: 19.3,
    note: 'A small key under table seven, with a tag: « Casier 7 ».' },
  { key: 'lettre', art: 'la', noun: 'lettre', g: 'f', en: 'the letter', emoji: '✉️', x: -16.2, z: -16.4,
    note: "A letter for you, in Élise's handwriting. Part of it is in code." },
  { key: 'photo', art: 'la', noun: 'photo', g: 'f', en: 'the photo', emoji: '📷', x: 11, z: -24,
    note: 'A photo of Élise with a man in a grey coat, in front of the metro.' },
  { key: 'journal', art: 'le', noun: 'journal', g: 'm', en: 'the newspaper', emoji: '📰', x: 3.8, z: -30.6,
    note: 'La Gazette, three days ago: « Projet Lumen : qui a peur de la vérité ? » by Élise Moreau.' },
];

export const STORY = [
  { emoji: '📱', fr: "Il y a trois jours, un message d'Élise : « Viens à Bruxelles. J'ai trouvé quelque chose. Ne fais confiance à personne. »",
    en: "Three days ago, a message from Élise: « Come to Brussels. I found something. Trust no one. »" },
  { emoji: '📵', fr: 'Depuis, Élise ne répond plus. Son téléphone est éteint.', en: 'Since then, Élise has not answered. Her phone is off.' },
  { emoji: '🌧️', fr: 'Ce soir, il pleut sur Bruxelles. Tu as une seule adresse : 12, rue des Ombres.', en: 'Tonight, it is raining on Brussels. You have only one address: 12, rue des Ombres.' },
  { emoji: '🕵️', fr: 'Trouve Élise, {name}. Mais attention… quelqu\'un te surveille.', en: 'Find Élise, {name}. But careful… someone is watching you.' },
];

export const PEOPLE = {
  lambert: {
    name: 'Madame Lambert', avatar: '👵', voice: { voice: 'vivienne', speed: 0.9 },
    pos: [-5.6, 26.6], face: Math.PI / 2,
    look: { skin: '#e8c6a8', hair: '#d4d4d4', coat: '#5b3f4f', coatLong: true, pants: '#2a2228', glasses: true, scarf: '#8a6a3a', height: 0.93 },
  },
  theo: {
    name: 'Théo, le serveur', avatar: '🧑‍🍳', voice: { voice: 'gerard', speed: 0.95 },
    pos: [5.6, 24.6], face: -Math.PI / 2,
    look: { skin: '#e2b08c', hair: '#3b2a1e', beard: '#3b2a1e', coat: '#1c1c1f', shirt: '#f2f2f2', apron: '#f4f1ea', pants: '#1a1a1d' },
  },
  samir: {
    name: 'Samir, le kiosque', avatar: '🧔', voice: { voice: 'remy', speed: 0.95 },
    pos: [-12, -17.7], face: 0,
    look: { skin: '#b98a6a', hair: '#1a1410', beard: '#1a1410', coat: '#3f4a36', pants: '#26282c', hat: 'cap', hatColor: '#2b2f3a', scarf: '#7a2a2a' },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const LETTER = { name: "La lettre d'Élise", avatar: '✉️', voice: { voice: 'charline', speed: 0.92 } };
export const ELISE = { name: 'Élise (au téléphone)', avatar: '📞', voice: { voice: 'charline', speed: 0.95 } };
export const CHIEF = { name: 'Le chef des hommes en gris', avatar: '🕴️', voice: { voice: 'henri', speed: 0.85 } };

const LAMBERT = [
  { fr: "Oui ? Qu'est-ce que vous voulez, à cette heure-ci ?", en: 'Yes? What do you want, at this hour?' },
  {
    fr: '(Elle te regarde, méfiante.)', en: '(She looks at you, suspicious.)',
    hint: 'An older lady you do not know, at night: say « Bonsoir, madame » and use « vous ».',
    choices: [
      { fr: 'Bonsoir, madame. Excusez-moi de vous déranger.', en: 'Good evening, madam. Sorry to bother you.', ok: true },
      { fr: 'Salut ! Ça va ?', en: 'Hi! How is it going?' },
      { fr: 'Bonjour, mec !', en: 'Hello, dude!' },
    ],
  },
  {
    fr: 'Hmm. Bonsoir. Vous êtes qui ?', en: 'Hmm. Good evening. Who are you?',
    hint: 'Introduce yourself: « Je m\'appelle… Je suis un ami de… ».',
    choices: [
      { fr: "Je m'appelle {name}. Je suis un ami d'Élise.", en: 'My name is {name}. I am a friend of Élise.', ok: true },
      { fr: 'Je suis Élise.', en: 'I am Élise.' },
      { fr: "J'ai un ami d'Élise.", en: 'I have a friend of Élise.' },
    ],
  },
  { fr: 'Élise… Elle est partie il y a trois jours. Avec un homme en manteau gris.', en: 'Élise… She left three days ago. With a man in a grey coat.' },
  { fr: "Elle avait peur. Je l'ai entendue au téléphone : « Lumen… Ils savent. »", en: 'She was afraid. I heard her on the phone: « Lumen… They know. »' },
  {
    fr: '(Demande-lui où Élise est allée.)', en: '(Ask her where Élise went.)',
    hint: 'Ask: « Où est-elle allée ? » (Where did she go?).',
    choices: [
      { fr: 'Où est-elle allée, madame ?', en: 'Where did she go, madam?', ok: true },
      { fr: 'Où est-ce que tu vas ?', en: 'Where are you going?' },
      { fr: "Quelle heure est-il ?", en: 'What time is it?' },
    ],
  },
  { fr: 'Je ne sais pas. Mais elle allait tous les soirs au café Le Corbeau, en face.', en: 'I do not know. But she went to the café Le Corbeau every evening, across the street.' },
  { fr: 'Faites attention. Les hommes en gris… ils posent des questions à tout le monde.', en: 'Be careful. The men in grey… they ask everyone questions.' },
];

const THEO = [
  {
    fr: 'Bonsoir ! Une table pour une personne ?', en: 'Good evening! A table for one?',
    hint: 'Answer: « Oui, s\'il vous plaît ».',
    choices: [
      { fr: "Oui, s'il vous plaît.", en: 'Yes, please.', ok: true },
      { fr: 'Non, je suis une table.', en: 'No, I am a table.' },
      { fr: 'Oui, tu es une personne.', en: 'Yes, you are a person.' },
    ],
  },
  {
    fr: "Qu'est-ce que je vous sers ?", en: 'What can I get you?',
    hint: 'Be polite: « Je voudrais…, s\'il vous plaît ».',
    choices: [
      { fr: "Je voudrais un café, s'il vous plaît.", en: 'I would like a coffee, please.', ok: true },
      { fr: 'Je veux le café. Vite !', en: 'I want the coffee. Quick!' },
      { fr: 'Je voudrais une chambre.', en: 'I would like a room.' },
    ],
  },
  {
    fr: 'Voilà votre café. Ça fait deux euros cinquante.', en: 'Here is your coffee. That is two euros fifty.', listen: true,
    hint: 'Listen again (🔊). « deux euros cinquante » = 2,50 €.',
    choices: [{ fr: '2,50 €', ok: true }, { fr: '12,50 €' }, { fr: '2,15 €' }],
  },
  {
    fr: '(Demande-lui s\'il connaît Élise.)', en: '(Ask him if he knows Élise.)',
    hint: 'connaître with vous: « Vous connaissez… ? ».',
    choices: [
      { fr: 'Vous connaissez Élise Moreau ?', en: 'Do you know Élise Moreau?', ok: true },
      { fr: 'Vous connais Élise Moreau ?', en: '(wrong verb form)' },
      { fr: 'Vous connaissez le café ?', en: 'Do you know the café?' },
    ],
  },
  { fr: '(Il baisse la voix.) Chut… Oui. Elle venait ici tous les soirs.', en: '(He lowers his voice.) Shh… Yes. She came here every evening.' },
  {
    fr: "Elle s'asseyait toujours à la table sept.", en: 'She always sat at table seven.', listen: true,
    hint: 'Listen again (🔊). « sept » = 7.',
    choices: [{ fr: 'table 7', ok: true }, { fr: 'table 17' }, { fr: 'table 2' }],
  },
  { fr: "Il y a trois jours, elle a laissé quelque chose sous la table… et elle est partie en courant.", en: 'Three days ago, she left something under the table… and ran away.' },
  { fr: 'Regardez sous les tables de la terrasse. Et allez voir Samir, au kiosque, sur la place.', en: 'Look under the tables on the terrace. And go and see Samir, at the kiosk, on the square.' },
];

const SAMIR = [
  {
    fr: "Bonsoir, l'ami ! Un journal ? Un plan de Bruxelles ?", en: 'Good evening, my friend! A newspaper? A map of Brussels?',
    hint: 'Ask for the newspaper: « Je voudrais La Gazette, s\'il vous plaît ».',
    choices: [
      { fr: "Je voudrais La Gazette, s'il vous plaît.", en: 'I would like La Gazette, please.', ok: true },
      { fr: 'Je voudrais un croissant.', en: 'I would like a croissant.' },
      { fr: "J'ai La Gazette, s'il vous plaît.", en: 'I have La Gazette, please.' },
    ],
  },
  {
    fr: 'La Gazette ? Ça fait trois euros vingt.', en: 'La Gazette? That is three euros twenty.', listen: true,
    hint: 'Listen again (🔊). « trois euros vingt » = 3,20 €.',
    choices: [{ fr: '3,20 €', ok: true }, { fr: '13,20 €' }, { fr: '3,02 €' }],
  },
  { fr: 'Élise ? Bien sûr que je la connais. Elle écrivait un article sur le projet Lumen.', en: 'Élise? Of course I know her. She was writing an article about the Lumen project.' },
  { fr: 'Hier, un homme en gris a pris une lettre. Une lettre pour vous. Il tourne autour du kiosque…', en: 'Yesterday, a man in grey took a letter. A letter for you. He is walking around the kiosk…' },
  { fr: 'Si vous récupérez la lettre, lisez-la bien. Élise écrit toujours en code.', en: 'If you get the letter back, read it carefully. Élise always writes in code.' },
];

const DECODE = [
  { fr: '« Si tu lis cette lettre, c\'est que tu es à Bruxelles. »', en: '« If you are reading this letter, you are in Brussels. »' },
  {
    fr: '« Le rendez-vous ___ à la station Bourse. »', en: '« The meeting ___ at Bourse station. »',
    hint: '« le rendez-vous » = il → il est.',
    choices: [{ fr: 'est', ok: true }, { fr: 'es' }, { fr: 'sont' }], keepOrder: true,
  },
  {
    fr: '« Quai numéro deux. »', en: '« Platform number two. »', listen: true,
    hint: 'Listen again (🔊). « deux » = 2.',
    choices: [{ fr: 'quai 2', ok: true }, { fr: 'quai 12' }, { fr: 'quai 10' }],
  },
  {
    fr: '« À vingt-trois heures. Viens seul. »', en: '« At eleven p.m. Come alone. »', listen: true,
    hint: 'Listen again (🔊). « vingt-trois heures » = 23:00.',
    choices: [{ fr: '23:00', ok: true }, { fr: '13:00' }, { fr: '20:03' }],
  },
  { fr: '« Ne fais confiance à personne. Même pas à la police. — É. »', en: '« Trust no one. Not even the police. — É. »' },
];

const CHIEF_MEET = [
  { fr: 'Bonsoir. Vous allez quelque part ?', en: 'Good evening. Are you going somewhere?' },
  { fr: "Le métro est fermé… pour les gens qui posent trop de questions.", en: 'The metro is closed… for people who ask too many questions.' },
];

const ENDING = [
  { who: CHIEF, fr: "Hmm. Bon. Allez-y… Mais je vous ai à l'œil.", en: 'Hmm. Fine. Go on… But I have my eye on you.' },
  { who: YOU, fr: '(Quai numéro deux. Vingt-trois heures. Personne… Soudain, un téléphone sonne.)', en: '(Platform two. Eleven p.m. Nobody… Suddenly, a phone rings.)' },
  { who: ELISE, fr: "Allô ? C'est toi ? C'est Élise. Écoute-moi bien.", en: "Hello? Is that you? It's Élise. Listen to me carefully." },
  { who: ELISE, fr: 'Ne prends pas le train de vingt-trois heures. Ils savent que tu es là.', en: 'Do not take the eleven p.m. train. They know you are here.' },
  { who: ELISE, fr: 'Va à la gare du Midi. Casier numéro sept. Tu as la clé… Tout est dedans.', en: 'Go to the Midi station. Locker number seven. You have the key… Everything is inside.' },
  { who: ELISE, fr: 'Ils arrivent. Je dois raccrocher…', en: 'They are coming. I have to hang up…' },
];

/** The current goal (English, translated for the player). */
export function objective(s) {
  if (!s.flags.lambert) return "Find number 12, rue des Ombres: Élise's building.";
  if (!s.flags.theo) return 'Talk to the waiter at the café Le Corbeau. Look for clues ({n}/{total}).';
  if (!s.flags.samir) return 'Find Samir at the newspaper kiosk on the square. Clues: {n}/{total}.';
  if (s.found.length < CLUES.length) return 'Find all the clues ({n}/{total}). Careful with the men in grey.';
  if (!s.flags.decoded) return "Read Élise's letter: tap 📓.";
  if (!s.flags.done) return 'Go to the metro: platform 2, 11 p.m.';
  return 'Chapter complete! Explore the street.';
}

export function hasNews(id, s) {
  if (id === 'lambert') return !s.flags.lambert;
  if (id === 'theo') return s.flags.lambert && !s.flags.theo;
  if (id === 'samir') return s.flags.theo && !s.flags.samir;
  if (id === 'metro') return s.flags.decoded && !s.flags.done;
  return false;
}

/** Decoding Élise's letter, once everything is found. */
export async function decode(g) {
  const s = g.state;
  if (s.flags.decoded || s.found.length < CLUES.length || !s.flags.samir) return false;
  s.mistakes += await g.ui.talk(LETTER, DECODE);
  s.flags.decoded = true;
  g.save();
  g.ui.toast('🚇 Bourse station, platform 2, 11 p.m. Go to the metro.', 3500);
  return true;
}

/** Talking or acting at a place. g = { ui, state, save, confrontChief, story, finish, toast }. */
export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'lambert') {
    if (s.flags.lambert) return g.ui.talk(P.lambert, [{ fr: 'Allez au café Le Corbeau, en face. Et faites attention à vous.', en: 'Go to the café Le Corbeau, across the street. And take care of yourself.' }]);
    s.mistakes += await g.ui.talk(P.lambert, LAMBERT);
    s.flags.lambert = true;
  } else if (id === 'theo') {
    if (!s.flags.lambert) return g.ui.talk(P.theo, [{ fr: "Bonsoir ! Désolé, on ferme bientôt.", en: 'Good evening! Sorry, we are closing soon.' }]);
    if (s.flags.theo) return g.ui.talk(P.theo, [{ fr: 'Samir, au kiosque. Sur la place. Bonne chance.', en: 'Samir, at the kiosk. On the square. Good luck.' }]);
    s.mistakes += await g.ui.talk(P.theo, THEO);
    s.flags.theo = true;
  } else if (id === 'samir') {
    if (!s.flags.theo) return g.ui.talk(P.samir, [{ fr: 'Bonsoir ! Les journaux du soir sont arrivés.', en: 'Good evening! The evening papers have arrived.' }]);
    if (s.flags.samir) return g.ui.talk(P.samir, [{ fr: "La lettre, l'ami. L'homme en gris l'a toujours.", en: 'The letter, my friend. The man in grey still has it.' }]);
    s.mistakes += await g.ui.talk(P.samir, SAMIR);
    s.flags.samir = true;
  } else if (id === 'metro') {
    if (!s.flags.decoded) return g.ui.talk(YOU, [{ fr: "(Le métro… Mais où aller ? Il me faut plus d'indices.)", en: '(The metro… But where to go? I need more clues.)' }]);
    if (s.flags.done) return g.ui.talk(YOU, [{ fr: '(Prochaine étape : la gare du Midi, casier sept.)', en: '(Next stop: the Midi station, locker seven.)' }]);
    await g.ui.talk(CHIEF, CHIEF_MEET);
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(['Je', 'suis', 'touriste', 'et', 'je', 'cherche', 'mon', 'hôtel.']);
    await g.ui.talk(CHIEF, ENDING);
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
}

/** Every English text, translated in one go at the start. */
export function allTexts() {
  const out = [];
  for (const n of [LAMBERT, THEO, SAMIR, DECODE, CHIEF_MEET, ENDING, STORY].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note);
  out.push(
    "Find number 12, rue des Ombres: Élise's building.", 'Talk to the waiter at the café Le Corbeau. Look for clues ({n}/{total}).',
    'Find Samir at the newspaper kiosk on the square. Clues: {n}/{total}.', 'Find all the clues ({n}/{total}). Careful with the men in grey.',
    "Read Élise's letter: tap 📓.", 'Go to the metro: platform 2, 11 p.m.', 'Chapter complete! Explore the street.',
    '🚇 Bourse station, platform 2, 11 p.m. Go to the metro.', 'Go to the café Le Corbeau, across the street. And take care of yourself.',
    'Good evening! Sorry, we are closing soon.', 'Samir, at the kiosk. On the square. Good luck.',
    'Good evening! The evening papers have arrived.', 'The letter, my friend. The man in grey still has it.',
    '(The metro… But where to go? I need more clues.)', '(Next stop: the Midi station, locker seven.)',
    'A man in grey guards this clue. Get past him first.', 'You wake up in front of the hotel… They let you go, for now.',
    'Listen and choose', 'Speak now…', 'Got it',
    'The microphone is blocked. On iPhone: Settings › Safari › Microphone › Allow. Speech recognition also needs Siri to be on.',
    'The microphone is blocked. Allow it for this site in the browser settings.',
    'No microphone found, or another app is using it.', 'Speech recognition needs the internet.', 'I did not hear you. Try again.', 'Not quite. Try again!',
    'My clues', 'Case file', 'Words found', 'Mistakes', 'Clues found', 'Chapter 1 complete!', 'Coming soon', 'Explore the street',
    'An investigation to learn French', 'Your name', 'Play', 'Continue', 'New game', 'Back to the app', 'Close', 'Help language',
  );
  return out.filter(Boolean);
}
