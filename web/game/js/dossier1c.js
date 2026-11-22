// Le Dossier Bruxelles — A1, stage 3 : « La station Bourse ».
// The metro at night: buying a ticket, prices and times, describing someone
// (adjectives and colours after the noun), asking the way (à gauche, tout droit),
// aller / prendre / venir. At 11 p.m., on platform 2, the phone rings.

export const CHAPTER = {
  id: '1c',
  title: 'La station Bourse',
  level: 'A1',
  world: 'office',
  layout: 'metro',
  saveKey: 'dossier_save_1c',
  spawn: [0, 20.4, Math.PI],
  respawn: [0, 19, Math.PI],
  lights: [[0, 2.6, 16, '#fff3d6'], [-7, 2.6, 4, '#d6e4ff'], [6, 2.6, -5, '#fff3d6'], [6, 2.6, -21, '#fff3d6'], [-16, 2.6, -8, '#d6e4ff'], [15, 2.6, -22, '#ffcf6b']],
  places: [{ id: 'cabine', x: 15.4, z: -23.4, y: 2.6, symbol: '?' }],
  // The gates open with a ticket.
  locks: [
    { rect: [-9, -5, 6.8, 9.2], clue: 'ticket', say: 'You need a ticket to go through the gates. Buy one at the ticket office (GUICHET).' },
  ],
  agents: [
    { id: 'couloir', path: [[-16.4, 5.4], [-13.2, 5.4]], guards: 'cartevisite' },
    { id: 'quai1', path: [[8.4, -8.4], [16.4, -8.4]], guards: 'journal' },
    { id: 'chef', path: [[11.6, -22.6]], chief: true },
  ],
  next: 'Niveau A2 : La Gare du Midi',
  doneIcon: '📞',
};

export const LINES = {
  agentName: 'Un homme en gris', chiefName: 'Le chef des hommes en gris',
  agentVoice: { voice: 'henri', speed: 0.95 }, chiefVoice: { voice: 'remy', speed: 0.9 },
  agentIntro: "Contrôle ! Votre ticket, s'il vous plaît.", chiefIntro: 'Vous voilà. Je vous attendais.',
  release: "C'est bon. Bon voyage.", storyAsk: 'Alors, racontez-moi. Vous allez où ?',
  caught: 'They walk you out of the station… You come back down the stairs.',
};

export const BANKS = [
  { kind: 'phrase', icon: '🚇', help: 'aller, prendre, venir, attendre — and polite answers.', items: [
    ['Vous allez où ?', 'Je vais à la gare du Midi.', ['Je vais au la gare du Midi.', 'Je vas à la gare du Midi.'], 'Where are you going?'],
    ['Vous prenez quelle ligne ?', 'Je prends la ligne deux.', ['Je prend la ligne deux.', 'Je prends le ligne deux.'], 'Which line are you taking?'],
    ['Vous avez votre ticket ?', 'Oui, il est dans mon sac.', ['Oui, elle est dans mon sac.', 'Oui, il est dans ma sac.'], 'Do you have your ticket?'],
    ['Vous attendez qui ?', "J'attends une amie.", ['Je attends une amie.', "J'attends un amie."], 'Who are you waiting for?'],
    ['Il est quelle heure ?', 'Il est vingt-deux heures cinquante.', ['Il a vingt-deux heures cinquante.', 'Il est vingt-deux cinquante heures.'], 'What time is it?'],
    ["Vous venez d'où ?", "Je viens de l'hôtel.", ['Je viens du hôtel.', "Je venir de l'hôtel."], 'Where are you coming from?'],
    ['Vous descendez ici ?', 'Non, je descends à la prochaine station.', ['Non, je descend à la prochaine station.', 'Non, je descends au prochaine station.'], 'Are you getting off here?'],
    ['Vous habitez à Bruxelles ?', 'Non, je suis en vacances.', ["Non, j'ai en vacances.", 'Non, je suis à vacances.'], 'Do you live in Brussels?'],
  ] },
  { kind: 'objets', icon: '🔍', help: 'Name the object, with le / la / les.', ask: "Qu'est-ce que c'est ?", askEn: 'What is this?', items: [
    ['le ticket', '🎫'], ['le métro', '🚇'], ['le train', '🚆'], ['le bus', '🚌'], ['le taxi', '🚕'], ['le vélo', '🚲'],
    ['la valise', '🧳'], ['le plan', '🗺️'], ['la montre', '⌚'], ['le téléphone', '📱'], ['le sac à dos', '🎒'], ['les écouteurs', '🎧'],
    ['le billet', '💶'], ['la pièce', '🪙'], ['le parapluie', '☂️'], ['la carte bancaire', '💳'],
  ] },
  { kind: 'ecoute', icon: '💶', help: 'Listen carefully to the price or the time.', gens: ['prix', 'heure'] },
];

export const CLUES = [
  { key: 'ticket', given: true, where: 'Buy it at the ticket office (GUICHET), on the right of the hall.', art: 'le', noun: 'ticket', g: 'm', en: 'the ticket', emoji: '🎫',
    noteFr: 'Ton ticket de métro : un voyage, deux euros dix.',
    note: 'Your metro ticket: one trip, two euros ten.' },
  { key: 'gant', where: 'In the ticket hall, on the left of the stairs.', art: 'le', noun: 'gant rouge', g: 'm', en: 'the red glove', emoji: '🧤', x: -6, z: 18.4,
    noteFr: "Un gant rouge, comme le parapluie d'Élise. Elle est passée par ici.",
    note: "A red glove, like Élise's umbrella. She came this way." },
  { key: 'recu', where: 'Next to the ticket machines, on the left of the hall.', art: 'le', noun: 'reçu', g: 'm', en: 'the receipt', emoji: '🧾', x: -14.6, z: 14.2,
    noteFr: 'Un reçu du distributeur : mercredi, vingt-deux heures cinquante. Un ticket.',
    note: 'A receipt from the machine: Wednesday, 10:50 p.m. One ticket.' },
  { key: 'cartevisite', where: 'Behind the gates, in the room on the left (west). A man in grey walks there.', art: 'la', noun: 'carte de visite', g: 'f', en: 'the business card', emoji: '📇', x: -16.2, z: 5.6,
    noteFr: "Une carte de visite : « Lumen — Service de sécurité ». Au dos, une photo d'Élise.",
    note: "A business card: « Lumen — Security department ». On the back, a photo of Élise." },
  { key: 'dictaphone', given: true, where: 'The musician gives it to you, behind the gates.', art: 'le', noun: 'dictaphone', g: 'm', en: 'the voice recorder', emoji: '🎙️',
    noteFr: "La voix d'Élise : « Si je disparais, cherchez à la gare du Midi. »",
    note: "Élise's voice: « If I disappear, look at the Midi station. »" },
  { key: 'journal', where: 'On platform 1, near the drinks machine. A man in grey walks there.', art: 'le', noun: 'journal du soir', g: 'm', en: 'the evening paper', emoji: '📰', x: 13, z: -8.6,
    noteFr: '« Une journaliste disparue ? La police ne dit rien. » Élise est dans le journal.',
    note: '« A journalist missing? The police say nothing. » Élise is in the paper.' },
  { key: 'lunettes', where: 'In the passage to platform 2, on the far left.', art: 'les', noun: "lunettes d'Élise", g: 'f', en: "Élise's glasses", emoji: '👓', x: -16, z: -12,
    noteFr: "Les lunettes d'Élise, par terre, dans le passage. Elle courait.",
    note: "Élise's glasses, on the ground, in the passage. She was running." },
  { key: 'telecarte', where: 'On platform 2, near the bench on the left.', art: 'la', noun: 'carte de téléphone', g: 'f', en: 'the phone card', emoji: '💳', x: 4.6, z: -23,
    noteFr: 'Une carte de téléphone. Au dos : « Cabine du quai deux, vingt-trois heures. »',
    note: 'A phone card. On the back: « Platform two phone box, 11 p.m. »' },
];

export const STORY = [
  { emoji: '🚇', fr: 'Vingt-deux heures quarante-cinq. Tu descends dans le métro Bourse.', en: '10:45 p.m. You go down into the Bourse metro.' },
  { emoji: '🕰️', fr: "Le rendez-vous d'Élise : quai deux, vingt-trois heures.", en: "Élise's meeting: platform two, 11 p.m." },
  { emoji: '🕴️', fr: 'Mais les hommes en gris sont déjà là. Ils contrôlent tout le monde.', en: 'But the men in grey are already here. They check everyone.' },
  { emoji: '🕵️', fr: "Achète un ticket, {name}, et trouve le quai deux. Vite !", en: 'Buy a ticket, {name}, and find platform two. Quick!' },
];

export const PEOPLE = {
  lea: {
    name: 'Léa, au guichet', avatar: '👩‍💼', voice: { voice: 'eloise', speed: 0.95 },
    pos: [14.9, 14], face: -Math.PI / 2,
    look: { skin: '#c99a76', hair: '#1d1612', coat: '#2a3f6a', shirt: '#f2f2f2', pants: '#22252c', height: 0.95 },
  },
  bruno: {
    name: "Bruno, l'accordéoniste", avatar: '🪗', voice: { voice: 'gerard', speed: 0.95 },
    pos: [-8.2, 3], face: 0,
    look: { skin: '#e2b08c', hair: '#5a4632', beard: '#5a4632', coat: '#5a3a2a', pants: '#2a2a2a', hat: 'beret', hatColor: '#7a2a2a', scarf: '#c9a24a', build: 1.05 },
  },
  diallo: {
    name: 'Madame Diallo', avatar: '🧹', voice: { voice: 'vivienne', speed: 0.92 },
    pos: [-1.4, -6.2], face: Math.PI / 2,
    look: { skin: '#6b4430', hair: '#141010', coat: '#3a6a7a', apron: '#e8c33a', pants: '#22252c', height: 0.96 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const ELISE = { name: 'Élise (au téléphone)', avatar: '📞', voice: { voice: 'charline', speed: 0.95 } };
export const CHIEF = { name: 'Le chef des hommes en gris', avatar: '🕴️', voice: { voice: 'remy', speed: 0.88 } };

const LEA = [
  {
    fr: "Bonsoir. C'est pour un ticket ?", en: 'Good evening. Is it for a ticket?',
    hint: 'Ask politely: « un ticket, s\'il vous plaît ».',
    choices: [
      { fr: "Oui, un ticket, s'il vous plaît.", en: 'Yes, a ticket, please.', ok: true },
      { fr: 'Oui, je suis un ticket.', en: 'Yes, I am a ticket.' },
      { fr: 'Non, je voudrais un café.', en: 'No, I would like a coffee.' },
    ],
  },
  {
    fr: 'Un voyage ou dix voyages ?', en: 'One trip or ten trips?',
    hint: '« le voyage » is masculine: un voyage.',
    choices: [
      { fr: "Un voyage, s'il vous plaît.", en: 'One trip, please.', ok: true },
      { fr: "Une voyage, s'il vous plaît.", en: '(wrong article)' },
      { fr: 'Dix voyages, hier.', en: 'Ten trips, yesterday.' },
    ],
  },
  {
    fr: 'Ça fait deux euros dix.', en: 'That is two euros ten.', listen: true,
    hint: 'Listen again (🔊). « deux euros dix » = 2,10 €.',
    choices: [{ fr: '2,10 €', ok: true }, { fr: '2,20 €' }, { fr: '12,10 €' }],
  },
  {
    fr: '(Paie, et demande à quelle heure part le dernier métro.)', en: '(Pay, and ask at what time the last metro leaves.)',
    hint: '« À quelle heure… ? » = At what time…?',
    choices: [
      { fr: 'À quelle heure part le dernier métro ?', en: 'At what time does the last metro leave?', ok: true },
      { fr: 'Quelle heure part le dernier métro ?', en: '(« à » is missing)' },
      { fr: 'À quelle heure est-ce que tu pars ?', en: 'At what time are you leaving?' },
    ],
  },
  {
    fr: 'Le dernier métro part à minuit dix.', en: 'The last metro leaves at ten past midnight.', listen: true,
    hint: 'Listen again (🔊). « minuit dix » = 00:10.',
    choices: [{ fr: '00:10', ok: true }, { fr: '12:10' }, { fr: '22:10' }],
  },
  { fr: 'Voilà votre ticket. Bonne soirée… et faites attention. Il y a des drôles de types ce soir.', en: 'Here is your ticket. Have a good evening… and be careful. There are strange people around tonight.' },
];

const BRUNO = [
  {
    fr: "(Il joue de l'accordéon. Il s'arrête.) Bonsoir ! Une chanson pour vous ?", en: '(He is playing the accordion. He stops.) Good evening! A song for you?',
    hint: 'Say no politely, and say why: « Je cherche… ».',
    choices: [
      { fr: 'Non merci. Je cherche une amie.', en: 'No thank you. I am looking for a friend.', ok: true },
      { fr: 'Oui, je suis une chanson.', en: 'Yes, I am a song.' },
      { fr: 'Non, je cherche un accordéon.', en: 'No, I am looking for an accordion.' },
    ],
  },
  {
    fr: 'Une amie ? Elle est comment ?', en: 'A friend? What does she look like?',
    hint: 'Élise: « elle » → the adjectives take an -e or -s: jeune, longs, bruns.',
    choices: [
      { fr: 'Elle est jeune. Elle a les cheveux longs et bruns.', en: 'She is young. She has long brown hair.', ok: true },
      { fr: 'Il est jeune. Il a les cheveux long et brun.', en: '(wrong pronoun and agreement)' },
      { fr: 'Elle est jeune. Elle a les longs cheveux brune.', en: '(wrong agreement)' },
    ],
  },
  {
    fr: 'Et elle porte quoi ?', en: 'And what is she wearing?',
    hint: 'The colour comes after the noun: un manteau rouge.',
    choices: [
      { fr: 'Elle porte un manteau rouge.', en: 'She is wearing a red coat.', ok: true },
      { fr: 'Elle porte un rouge manteau.', en: '(wrong word order)' },
      { fr: 'Elle porte une manteau rouge.', en: '(wrong article)' },
    ],
  },
  { fr: 'Un manteau rouge… Oui ! Élise ! Elle passe ici tous les soirs. Elle me donne toujours une pièce.', en: 'A red coat… Yes! Élise! She comes by every evening. She always gives me a coin.' },
  { fr: "Hier, elle m'a donné ça. Elle a dit : « Gardez ça. Quelqu'un va venir le chercher. »", en: 'Yesterday, she gave me this. She said: « Keep this. Someone is going to come and get it. »' },
  {
    fr: '(Demande-lui où est le quai deux.)', en: '(Ask him where platform two is.)',
    hint: '« Où est… ? » = Where is…?',
    choices: [
      { fr: "Où est le quai deux, s'il vous plaît ?", en: 'Where is platform two, please?', ok: true },
      { fr: 'Où sont le quai deux ?', en: '(wrong verb form)' },
      { fr: 'Qui est le quai deux ?', en: 'Who is platform two?' },
    ],
  },
  { fr: 'Le quai deux ? Prenez le passage à gauche, au bout du quai un. Puis tout droit.', en: 'Platform two? Take the passage on the left, at the end of platform one. Then straight on.' },
  { fr: "Mais attention : un homme en gris attend là-bas depuis une heure.", en: 'But be careful: a man in grey has been waiting there for an hour.' },
];

const DIALLO = [
  { fr: 'Oh ! Vous m\'avez fait peur ! Bonsoir.', en: 'Oh! You scared me! Good evening.' },
  {
    fr: '(Demande-lui si elle travaille ici tous les soirs.)', en: '(Ask her if she works here every evening.)',
    hint: 'With « vous »: vous travaillez.',
    choices: [
      { fr: 'Vous travaillez ici tous les soirs ?', en: 'Do you work here every evening?', ok: true },
      { fr: 'Vous travaille ici tous les soirs ?', en: '(wrong verb form)' },
      { fr: 'Tu travailles ici tous les soirs, toi ?', en: '(too familiar with a lady you do not know)' },
    ],
  },
  {
    fr: 'Oui. Je commence à vingt heures et je finis à six heures du matin.', en: 'Yes. I start at 8 p.m. and I finish at 6 a.m.', listen: true,
    hint: 'Listen again (🔊). « vingt heures » = 20:00, « six heures du matin » = 6:00.',
    choices: [{ fr: '20:00 → 6:00', ok: true }, { fr: '22:00 → 6:00' }, { fr: '20:00 → 16:00' }],
  },
  { fr: 'La jeune femme au manteau rouge ? Oui… Mercredi, elle attendait sur le quai deux.', en: 'The young woman in the red coat? Yes… On Wednesday, she was waiting on platform two.' },
  { fr: 'Elle téléphonait dans la cabine, au bout du quai. Elle avait peur.', en: 'She was phoning from the phone box, at the end of the platform. She was afraid.' },
  {
    fr: '(Demande-lui à quelle heure.)', en: '(Ask her at what time.)',
    hint: '« heure » is feminine: à quelle heure.',
    choices: [
      { fr: 'À quelle heure, madame ?', en: 'At what time, madam?', ok: true },
      { fr: 'À quel heure, madame ?', en: '(wrong spelling: heure is feminine)' },
      { fr: 'Quelle heure tu es ?', en: '(this means nothing)' },
    ],
  },
  { fr: 'À vingt-trois heures. Exactement comme maintenant…', en: 'At 11 p.m. Exactly like now…' },
];

const CHIEF_MEET = [
  { fr: 'Vous voilà. Vous attendez un appel ?', en: 'There you are. Are you waiting for a call?' },
  { fr: "Moi aussi. Mais d'abord, quelques questions.", en: 'So am I. But first, a few questions.' },
];

const ENDING = [
  { who: CHIEF, fr: 'Bon. Le métro arrive. Je monte… Mais je vous retrouverai.', en: 'Fine. The metro is coming. I am getting on… But I will find you again.' },
  { who: YOU, fr: '(Les portes se ferment. Le métro part. Vingt-trois heures. Soudain, le téléphone de la cabine sonne.)', en: '(The doors close. The metro leaves. 11 p.m. Suddenly, the phone in the box rings.)' },
  { who: ELISE, fr: "Allô ? C'est toi ? C'est Élise. Écoute-moi bien.", en: "Hello? Is that you? It's Élise. Listen to me carefully." },
  { who: ELISE, fr: 'Ne reste pas ici. Ils savent que tu es là.', en: 'Do not stay here. They know you are here.' },
  { who: ELISE, fr: 'Va à la gare du Midi. Casier numéro sept. Tu as la clé… Tout est dedans.', en: 'Go to the Midi station. Locker number seven. You have the key… Everything is inside.' },
  { who: ELISE, fr: 'Ils arrivent. Je dois raccrocher…', en: 'They are coming. I have to hang up…' },
];

export function objective(s) {
  if (!s.flags.lea) return 'Buy a ticket at the ticket office (GUICHET), on the right.';
  if (!s.flags.bruno) return 'Go through the gates. Someone is playing music behind them.';
  if (!s.flags.diallo) return 'Find the cleaning lady on platform 1. Clues: {n}/{total}.';
  if (s.found.length < CLUES.length) return 'Find all the clues ({n}/{total}). Platform 2: the passage on the far left.';
  if (!s.flags.done) return 'Platform 2, 11 p.m.: go to the phone box.';
  return 'Stage complete! Next: level A2, the Midi station.';
}

export function hasNews(id, s) {
  if (id === 'lea') return !s.flags.lea;
  if (id === 'bruno') return s.flags.lea && !s.flags.bruno;
  if (id === 'diallo') return s.flags.bruno && !s.flags.diallo;
  if (id === 'cabine') return s.flags.diallo && s.found.length >= CLUES.length && !s.flags.done;
  return false;
}

export async function afterClue(g) {
  const s = g.state;
  if (s.found.length >= CLUES.length && s.flags.diallo && !s.flags.allTold) {
    s.flags.allTold = true;
    g.save();
    g.ui.toast('📞 Eleven p.m. Go to the phone box on platform 2.', 3500);
  }
  return false;
}

const SHORT = {
  leaAgain: { fr: 'Les portiques sont à gauche. Bonne soirée !', en: 'The gates are on the left. Have a good evening!' },
  brunoEarly: { fr: '(Une musique triste, derrière les portiques…)', en: '(Sad music, behind the gates…)' },
  brunoAgain: { fr: 'Le passage à gauche, au bout du quai un. Bonne chance !', en: 'The passage on the left, at the end of platform one. Good luck!' },
  dialloEarly: { fr: "Pardon, je travaille. Le quai est mouillé, attention !", en: 'Sorry, I am working. The platform is wet, careful!' },
  dialloAgain: { fr: 'La cabine, au bout du quai deux. À vingt-trois heures.', en: 'The phone box, at the end of platform two. At 11 p.m.' },
  cabineEarly: { fr: "(Une vieille cabine téléphonique. Il n'est pas encore l'heure. Il me faut tous les indices.)", en: '(An old phone box. It is not time yet. I need all the clues.)' },
  cabineDone: { fr: '(La gare du Midi. Casier sept. Je dois y aller.)', en: '(The Midi station. Locker seven. I must go there.)' },
};
const STORY_WORDS = ['Je', 'prends', 'le', 'métro', 'pour', 'rentrer', 'à', "l'hôtel."];

export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'lea') {
    if (s.flags.lea) return g.ui.talk(P.lea, [SHORT.leaAgain]);
    s.mistakes += await g.ui.talk(P.lea, LEA);
    s.flags.lea = true;
    g.save();
    await g.give('ticket');
    g.ui.toast('The gates are open: on the left of the hall.', 3000);
  } else if (id === 'bruno') {
    if (!s.flags.lea) return g.ui.talk(YOU, [SHORT.brunoEarly]);
    if (s.flags.bruno) return g.ui.talk(P.bruno, [SHORT.brunoAgain]);
    s.mistakes += await g.ui.talk(P.bruno, BRUNO.slice(0, 5));
    await g.give('dictaphone');
    s.mistakes += await g.ui.talk(P.bruno, BRUNO.slice(5));
    s.flags.bruno = true;
  } else if (id === 'diallo') {
    if (!s.flags.bruno) return g.ui.talk(P.diallo, [SHORT.dialloEarly]);
    if (s.flags.diallo) return g.ui.talk(P.diallo, [SHORT.dialloAgain]);
    s.mistakes += await g.ui.talk(P.diallo, DIALLO);
    s.flags.diallo = true;
    g.save();
    await afterClue(g);
  } else if (id === 'cabine') {
    if (s.flags.done) return g.ui.talk(YOU, [SHORT.cabineDone]);
    if (!hasNews('cabine', s)) return g.ui.talk(YOU, [SHORT.cabineEarly]);
    await g.ui.talk(CHIEF, CHIEF_MEET);
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(STORY_WORDS);
    g.ring();
    await g.ui.talk(CHIEF, ENDING);
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
}

export function allTexts() {
  const out = [];
  for (const n of [LEA, BRUNO, DIALLO, CHIEF_MEET, ENDING, STORY, Object.values(SHORT)].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note, c.where);
  for (const l of CHAPTER.locks) out.push(l.say);
  out.push(
    'Buy a ticket at the ticket office (GUICHET), on the right.', 'Go through the gates. Someone is playing music behind them.',
    'Find the cleaning lady on platform 1. Clues: {n}/{total}.', 'Find all the clues ({n}/{total}). Platform 2: the passage on the far left.',
    'Platform 2, 11 p.m.: go to the phone box.', 'Stage complete! Next: level A2, the Midi station.',
    'The gates are open: on the left of the hall.', '📞 Eleven p.m. Go to the phone box on platform 2.', 'Your phone is ringing…',
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
  talk(P.lea, [...LEA, SHORT.leaAgain]);
  talk(P.bruno, [...BRUNO, SHORT.brunoAgain]);
  talk(P.diallo, [...DIALLO, SHORT.dialloEarly, SHORT.dialloAgain]);
  talk(CHIEF, [...CHIEF_MEET, ...ENDING]);
  talk(YOU, [SHORT.brunoEarly, SHORT.cabineEarly, SHORT.cabineDone]);
  STORY.forEach((st, i) => out.push([st.fr, { voice: i === 0 ? 'charline' : 'denise' }]));
  for (const c of CLUES) {
    out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
    out.push([c.noteFr, { voice: 'denise' }]);
  }
  out.push([STORY_WORDS.join(' '), { voice: 'denise' }]);
  return out;
}
