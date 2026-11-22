// Le Dossier Bruxelles — Chapitre 4 : « Le Laboratoire Lumen » (B1).
// COD / COI pronouns (le, la, lui, leur), y and en, the relative pronouns
// (qui, que, où, dont), and the imparfait against the passé composé.
// Sneaking: the guards see you inside the light of their torch.

export const CHAPTER = {
  id: 4,
  title: 'Chapitre 4 : Le Laboratoire Lumen',
  level: 'B1',
  world: 'office',
  layout: 'lumen',
  detect: 'cone',
  saveKey: 'dossier_save_ch4',
  spawn: [0, 21.5, Math.PI],
  respawn: [0, 21, Math.PI],
  lights: [[0, 2.6, 16, '#d6e4ff'], [-11, 2.6, 0, '#ffe2b8'], [12, 2.6, 0, '#9fd8ff'], [12, 2.6, -16, '#ff6b6b'], [-13, 2.6, -16, '#d6e4ff'], [0, 2.6, -8, '#d6e4ff']],
  places: [{ id: 'terminal', x: 17.2, z: -22.5, y: 2.2, symbol: '?' }],
  // Doors that open later: the corridor (after Marc), the server room (with the access card).
  locks: [
    { rect: [-3, 3, 6.6, 9.8], flag: 'marc', say: 'The night guard will not let you in yet. Talk to him at the reception.' },
    { rect: [2.2, 3.8, -17.6, -14.4], clue: 'carte', say: 'The server room is locked. You need an access card.' },
  ],
  agents: [
    { id: 'couloir', path: [[0, 5], [0, -21]] },
    { id: 'archives', path: [[-18.4, -14], [-5, -14]], guards: 'facture' },
    { id: 'labo', path: [[6, -5.6], [18.4, -5.6]], guards: 'echantillon' },
    { id: 'securite', path: [[12, -22.4]], chief: true },
  ],
  next: 'Chapitre 5 : La Vérité',
  doneIcon: '💾',
};

export const LINES = {
  agentName: 'Un garde de Lumen', chiefName: 'Le chef de la sécurité',
  agentVoice: { voice: 'henri', speed: 0.95 }, chiefVoice: { voice: 'remy', speed: 0.9 },
  agentIntro: 'Hé ! Vous, là ! Qu\'est-ce que vous faites ici ?', chiefIntro: 'Ne bougez plus. Vous allez répondre à mes questions.',
  release: 'Bon… Retournez travailler.', storyAsk: 'Alors ? Vous allez parler ?',
  caught: 'The guards take you outside… You come back in through the lobby.',
};

export const BANKS = [
  { kind: 'phrase', icon: '🎯', help: 'Pronouns: le / la (things, people), lui / leur (à + person), y (a place), en (de + …).', items: [
    ['Vous avez parlé au directeur ?', 'Oui, je lui ai parlé.', ["Oui, je l'ai parlé.", 'Oui, je leur ai parlé.'], 'Did you speak to the director?'],
    ['Vous avez téléphoné aux gardes ?', 'Non, je ne leur ai pas téléphoné.', ['Non, je ne les ai pas téléphoné.', 'Non, je ne lui ai pas téléphonés.'], 'Did you phone the guards?'],
    ['Vous allez au laboratoire ?', "Oui, j'y vais.", ["Oui, j'en vais.", 'Oui, je vais y.'], 'Are you going to the laboratory?'],
    ['Vous avez des clés ?', "Oui, j'en ai deux.", ["Oui, j'y ai deux.", 'Oui, je les ai deux.'], 'Do you have keys?'],
    ['Vous venez du bureau ?', "Oui, j'en viens.", ["Oui, j'y viens.", 'Oui, je le viens.'], 'Are you coming from the office?'],
    ['Vous pensez à votre travail ?', "Oui, j'y pense.", ['Oui, je lui pense.', "Oui, j'en pense."], 'Are you thinking about your work?'],
    ['Vous connaissez la docteure Vasseur ?', 'Oui, je la connais.', ['Oui, je lui connais.', "Oui, j'en connais."], 'Do you know Doctor Vasseur?'],
  ] },
  { kind: 'phrase', icon: '🔗', help: 'Relative pronouns: qui (subject), que (object), où (place / time), dont (de + …).', items: [
    ['Quel badge ?', "Le badge que j'ai trouvé.", ["Le badge qui j'ai trouvé.", "Le badge dont j'ai trouvé."], 'Which badge?'],
    ['Quel bureau ?', 'Le bureau où je travaille.', ['Le bureau que je travaille.', 'Le bureau dont je travaille.'], 'Which office?'],
    ['Quel collègue ?', 'Le collègue dont je vous ai parlé.', ['Le collègue que je vous ai parlé.', 'Le collègue où je vous ai parlé.'], 'Which colleague?'],
    ['Quelle porte ?', 'La porte qui est fermée.', ['La porte que est fermée.', 'La porte dont est fermée.'], 'Which door?'],
    ['Quel document ?', "Le document dont j'ai besoin.", ["Le document que j'ai besoin.", "Le document qui j'ai besoin."], 'Which document?'],
    ['Quel jour ?', 'Le jour où je suis arrivé.', ['Le jour que je suis arrivé.', 'Le jour dont je suis arrivé.'], 'Which day?'],
  ] },
  { kind: 'phrase', icon: '⏳', help: 'Imparfait (a scene, a habit) or passé composé (an event).', items: [
    ["Qu'est-ce que vous faisiez quand l'alarme a sonné ?", 'Je travaillais dans mon bureau.', ['Je travaillé dans mon bureau.', "J'ai travaillais dans mon bureau."], 'What were you doing when the alarm rang?'],
    ['Vous étiez où hier soir ?', "J'étais chez moi.", ['Je étais chez moi.', "J'été chez moi."], 'Where were you last night?'],
    ['Quand êtes-vous arrivé ?', 'Je suis arrivé il y a dix minutes.', ["J'arrivais il y a dix minutes.", "J'ai arrivé il y a dix minutes."], 'When did you arrive?'],
    ['Il faisait quel temps quand vous êtes entré ?', 'Il pleuvait.', ['Il a plu toujours.', 'Il pleuvra.'], 'What was the weather like when you came in?'],
    ["Qu'est-ce qui s'est passé ?", "La lumière s'est éteinte.", ["La lumière s'éteignait souvent hier.", "La lumière s'est éteint."], 'What happened?'],
    ['Avant, vous travailliez où ?', 'Avant, je travaillais à Liège.', ["Avant, j'ai travaillé à Liège toujours.", 'Avant, je travaillerai à Liège.'], 'Before, where did you work?'],
  ] },
];

export const CLUES = [
  { key: 'agenda', where: "In the director's office, near his desk.", art: "l'", noun: 'agenda de Lenoir', g: 'm', en: "Lenoir's diary", emoji: '📔', x: -11, z: 2.4,
    noteFr: "L'agenda de Lenoir. Ce soir : « Vingt-trois heures — Victor apporte la clé USB. »",
    note: "Lenoir's diary. Tonight: « 11 p.m. — Victor brings the USB key. »" },
  { key: 'postit', where: "Under the second desk, in the director's office.", art: 'le', noun: 'post-it', g: 'm', en: 'the sticky note', emoji: '🟨', x: -14.4, z: 6.8,
    noteFr: "Un post-it collé sous le bureau : « Serveur : l'année où tout a commencé. »",
    note: 'A sticky note under the desk: « Server: the year when everything began. »' },
  { key: 'photo', where: "Near the shelf, in the director's office.", art: 'la', noun: "photo d'une petite fille", g: 'f', en: "a little girl's photo", emoji: '🖼️', x: -17.4, z: -6,
    noteFr: '« Victor, ta fille va bien… pour le moment. » Lenoir fait chanter Victor !',
    note: '« Victor, your daughter is fine… for now. » Lenoir is blackmailing Victor!' },
  { key: 'facture', where: 'In the archives, between the shelves. A guard walks there.', art: 'la', noun: 'facture', g: 'f', en: 'the invoice', emoji: '🧾', x: -13.5, z: -18,
    noteFr: 'Une facture : Lumen a payé un commissaire de police. Cent mille euros.',
    note: 'An invoice: Lumen paid a police chief. One hundred thousand euros.' },
  { key: 'rapport', where: 'At the back of the archives.', art: 'le', noun: 'rapport secret', g: 'm', en: 'the secret report', emoji: '📑', x: -6.6, z: -22.2,
    noteFr: '« Projet Lumen, deux mille dix-neuf : une puce dans chaque téléphone pour surveiller la ville. »',
    note: '« Lumen project, 2019: a chip in every phone to watch the city. »' },
  { key: 'echantillon', where: 'In the laboratory, near the back wall. A guard walks there.', art: "l'", noun: 'échantillon', g: 'm', en: 'the sample', emoji: '🧪', x: 17.4, z: -4.2,
    noteFr: 'Un échantillon bleu, avec une étiquette : « Puce Lumen — version finale ».',
    note: 'A blue sample, with a label: « Lumen chip — final version ».' },
  { key: 'carte', where: 'In the corridor, near the archives door. A guard walks there.', art: 'la', noun: "carte d'accès", g: 'f', en: 'the access card', emoji: '💳', x: -1.6, z: -11,
    noteFr: "Une carte d'accès : « Salle des serveurs ». Un garde l'a perdue.",
    note: 'An access card: « Server room ». A guard lost it.' },
  { key: 'fichier', where: 'In the server room, at the computer.', art: 'le', noun: 'fichier principal', g: 'm', en: 'the main file', emoji: '💾', given: true,
    noteFr: 'Le fichier principal de Lumen : les noms, les puces, l\'argent. Toute la vérité.',
    note: "Lumen's main file: the names, the chips, the money. The whole truth." },
];

export const STORY = [
  { emoji: '🏢', fr: 'Le lendemain soir. Le siège de Lumen, à Bruxelles : une tour de verre au-dessus de la ville.', en: "The next evening. Lumen's headquarters, in Brussels: a glass tower above the city." },
  { emoji: '🎧', fr: "Élise te parle dans l'oreillette. Victor attend dehors… Mais tu n'as plus confiance en lui.", en: 'Élise talks to you in your earpiece. Victor waits outside… But you no longer trust him.' },
  { emoji: '🔦', fr: 'Des gardes font des rondes avec des lampes. Reste hors de leur lumière.', en: 'Guards make rounds with torches. Stay out of their light.' },
  { emoji: '💾', fr: 'Trouve le fichier principal, {name}. Et sors d\'ici vivant.', en: 'Find the main file, {name}. And get out of here alive.' },
];

export const PEOPLE = {
  marc: {
    name: 'Marc, le gardien de nuit', avatar: '💂', voice: { voice: 'gerard', speed: 0.95 },
    pos: [0, 16.6], face: 0,
    look: { skin: '#d8a47f', hair: '#3a2a1e', coat: '#1d2a44', pants: '#151a26', hat: 'cap', hatColor: '#1d2a44', height: 1.02, build: 1.1 },
  },
  claire: {
    name: 'Claire Vasseur, la scientifique', avatar: '👩‍🔬', voice: { voice: 'denise', speed: 0.95 },
    pos: [14, 4.4], face: -Math.PI / 2,
    look: { skin: '#f2cdb0', hair: '#b88a4a', longHair: true, coat: '#f0f0f0', coatLong: true, pants: '#2a2f3a', glasses: true, height: 0.96 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const EAR = { name: "Élise (dans l'oreillette)", avatar: '🎧', voice: { voice: 'charline', speed: 1 } };
export const LENOIR = { name: 'Monsieur Lenoir', avatar: '🎩', voice: { voice: 'henri', speed: 0.85 } };
export const VICTOR = { name: 'Victor', avatar: '📚', voice: { voice: 'remy', speed: 0.92 } };

const MARC = [
  { fr: 'Bonsoir. Le bâtiment est fermé. Vous êtes qui ?', en: 'Good evening. The building is closed. Who are you?' },
  {
    fr: '(Fais semblant d\'être le technicien.)', en: '(Pretend to be the technician.)',
    hint: '« On m\'a appelé » = someone called me (on + passé composé).',
    choices: [
      { fr: "Bonsoir. Je suis le technicien. On m'a appelé pour le serveur.", en: 'Good evening. I am the technician. Someone called me for the server.', ok: true },
      { fr: "Bonsoir. Je suis le technicien. On m'ai appelé pour le serveur.", en: '(wrong verb form)' },
      { fr: "Bonsoir. J'ai le technicien.", en: 'Good evening. I have the technician.' },
    ],
  },
  {
    fr: 'Le technicien ? À cette heure-ci ? Vous avez votre badge ?', en: 'The technician? At this time? Do you have your badge?',
    hint: '« le badge » → « je l\'ai » (COD before the verb).',
    choices: [
      { fr: "Oui, je l'ai. Le voilà.", en: 'Yes, I have it. Here it is.', ok: true },
      { fr: 'Oui, je lui ai. Le voilà.', en: '(lui is for people)' },
      { fr: "Oui, j'en ai le. Le voilà.", en: '(not a correct sentence)' },
    ],
  },
  {
    fr: 'Hmm… Vous allez au laboratoire ?', en: 'Hmm… Are you going to the laboratory?',
    hint: '« y » replaces a place: au laboratoire → « j\'y vais ».',
    choices: [
      { fr: "Oui, j'y vais tout de suite.", en: 'Yes, I am going there right away.', ok: true },
      { fr: "Oui, j'en vais tout de suite.", en: '(en is for « de + … »)' },
      { fr: 'Oui, je vais y tout de suite.', en: '(y goes before the verb)' },
    ],
  },
  {
    fr: 'Vous avez parlé au directeur, monsieur Lenoir ?', en: 'Did you speak to the director, Mr Lenoir?',
    hint: 'parler à quelqu\'un → « lui » (one person).',
    choices: [
      { fr: 'Oui, je lui ai parlé ce matin.', en: 'Yes, I spoke to him this morning.', ok: true },
      { fr: "Oui, je l'ai parlé ce matin.", en: '(parler à → lui, not le)' },
      { fr: 'Oui, je leur ai parlé ce matin.', en: '(leur = to them)' },
    ],
  },
  { fr: "D'accord. L'ascenseur est en panne. Le couloir est derrière moi. Ne traînez pas.", en: 'OK. The lift is out of order. The corridor is behind me. Do not hang around.' },
  { who: EAR, fr: 'Bravo ! Fais attention aux gardes : ne reste jamais dans la lumière de leur lampe.', en: 'Well done! Watch out for the guards: never stay in the light of their torch.' },
];

const CLAIRE = [
  { fr: 'Qui êtes-vous ? … Attendez. Vous êtes l\'ami d\'Élise ? Je la connais.', en: "Who are you? … Wait. Are you Élise's friend? I know her." },
  { fr: "Quand j'ai commencé ici, Lumen était une petite entreprise. Nous voulions aider les hôpitaux.", en: 'When I started here, Lumen was a small company. We wanted to help hospitals.' },
  {
    fr: '(Comment était Lumen au début ?)', en: '(What was Lumen like at the beginning?)',
    hint: 'The imparfait describes how things were: « Lumen était… nous voulions… ».',
    choices: [
      { fr: "C'était une petite entreprise qui voulait aider les hôpitaux.", en: 'It was a small company that wanted to help hospitals.', ok: true },
      { fr: "C'est une grande entreprise qui a volé les hôpitaux.", en: 'It is a big company that robbed the hospitals.' },
      { fr: "C'était un hôpital qui voulait aider Lumen.", en: 'It was a hospital that wanted to help Lumen.' },
    ],
  },
  { fr: 'Mais un jour, monsieur Lenoir est arrivé. Il a tout changé.', en: 'But one day, Mr Lenoir arrived. He changed everything.' },
  {
    fr: '« Un jour, Lenoir ___ arrivé. »', en: '« One day, Lenoir ___ arrived. »',
    hint: 'One event on one day → passé composé (arriver uses être).',
    choices: [{ fr: 'est', ok: true }, { fr: 'était' }, { fr: 'a' }], keepOrder: true,
  },
  {
    fr: '« Avant, nous ___ des médicaments. »', en: '« Before, we ___ medicines. »',
    hint: 'A habit in the past → imparfait: nous fabriquions.',
    choices: [{ fr: 'fabriquions', ok: true }, { fr: 'avons fabriqué' }, { fr: 'fabriquerons' }], keepOrder: true,
  },
  { fr: "Le fichier dont vous avez besoin est dans la salle des serveurs. Le code, c'est l'année où Lumen est née.", en: 'The file you need is in the server room. The code is the year Lumen was born.' },
  {
    fr: '(Le code, c\'est quoi ?)', en: '(What is the code?)',
    hint: '« où » is used for a time or a place: « l\'année où… ».',
    choices: [
      { fr: "C'est l'année où Lumen est née.", en: 'It is the year when Lumen was born.', ok: true },
      { fr: "C'est l'année que Lumen est née.", en: '(que does not fit a time here)' },
      { fr: "C'est l'année dont Lumen est née.", en: '(dont = de + …)' },
    ],
  },
  { fr: 'Le rapport secret dit l\'année. Il est dans les archives. Allez-y… et pardonnez-moi.', en: 'The secret report gives the year. It is in the archives. Go… and forgive me.' },
];

const TERMINAL = [
  { who: YOU, fr: "(L'ordinateur de la salle des serveurs. Il demande un code : l'année où Lumen est née.)", en: '(The server room computer. It asks for a code: the year Lumen was born.)' },
  {
    who: YOU, fr: '(Le rapport secret disait : « Projet Lumen, deux mille dix-neuf ». Tape le code.)', en: '(The secret report said: « Lumen project, two thousand and nineteen ». Type the code.)',
    hint: '« deux mille dix-neuf » = 2019.',
    choices: [{ fr: '2019', ok: true }, { fr: '2009' }, { fr: '1990' }],
  },
  { who: EAR, fr: 'Ça marche ! Le fichier se télécharge… Vite, vite !', en: 'It works! The file is downloading… Quick, quick!' },
];

const ENDING = [
  { who: LENOIR, fr: 'Bravo. Vous êtes très doué.', en: 'Well done. You are very talented.' },
  { who: LENOIR, fr: "Mais vous avez oublié une chose : ici, c'est moi qui contrôle tout.", en: 'But you forgot one thing: here, I am the one who controls everything.' },
  { who: VICTOR, fr: "Je suis désolé… Ils avaient ma fille. Je n'avais pas le choix.", en: 'I am sorry… They had my daughter. I had no choice.' },
  { who: LENOIR, fr: 'Donnez-moi la clé USB. Merci. Et votre amie Élise… nous l\'avons trouvée, elle aussi.', en: 'Give me the USB key. Thank you. And your friend Élise… we have found her too.' },
  { who: EAR, fr: 'Ils sont là ! Ils m\'ont trouv…', en: 'They are here! They found m…' },
  { who: LENOIR, fr: 'Demain matin, je passerai à la télévision. Et tout le monde oubliera cette histoire.', en: 'Tomorrow morning, I will be on television. And everyone will forget this story.' },
  { who: YOU, fr: '(Les gardes te jettent dehors, sous la pluie. Mais dans ta poche, ton téléphone… Tu as photographié tous les documents.)', en: '(The guards throw you outside, into the rain. But in your pocket, your phone… You photographed every document.)' },
  { who: YOU, fr: "(Demain matin, à la télévision… Lenoir ne sait pas ce qui l'attend.)", en: '(Tomorrow morning, on television… Lenoir does not know what is waiting for him.)' },
];

const SHORT = {
  marcAgain: { fr: 'Le couloir est derrière moi. Ne traînez pas.', en: 'The corridor is behind me. Do not hang around.' },
  claireAgain: { fr: 'Le rapport secret est dans les archives. Il dit l\'année.', en: 'The secret report is in the archives. It gives the year.' },
  claireEarly: { fr: '(Une femme en blouse blanche travaille. Elle ne te voit pas.)', en: '(A woman in a white coat is working. She does not see you.)' },
  terminalEarly: { fr: "(L'ordinateur demande un code. Il me faut tous les documents… et l'aide de quelqu'un.)", en: '(The computer asks for a code. I need all the documents… and someone\'s help.)' },
  terminalDone: { fr: '(Le fichier est téléchargé. Il faut sortir.)', en: '(The file is downloaded. Time to get out.)' },
};
const STORY_WORDS = ['Je', 'ne', 'dirai', 'rien', 'à', 'personne.'];

export function objective(s) {
  if (!s.flags.marc) return 'Get past the night guard at the reception.';
  if (!s.flags.claire) return 'Search the offices (clues {n}/{total}). Find the scientist in the laboratory.';
  if (s.found.length < CLUES.length - 1) return 'Find the documents ({n}/{total}). Stay out of the guards\' torch light.';
  if (!s.flags.done) return 'Go to the server room and use the computer.';
  return 'Chapter complete!';
}

export function hasNews(id, s) {
  if (id === 'marc') return !s.flags.marc;
  if (id === 'claire') return s.flags.marc && !s.flags.claire;
  if (id === 'terminal') return s.flags.claire && s.found.length >= CLUES.length - 1 && !s.flags.done;
  return false;
}

export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'marc') {
    if (s.flags.marc) return g.ui.talk(P.marc, [SHORT.marcAgain]);
    s.mistakes += await g.ui.talk(P.marc, MARC);
    s.flags.marc = true;
  } else if (id === 'claire') {
    if (!s.flags.marc) return g.ui.talk(YOU, [SHORT.claireEarly]);
    if (s.flags.claire) return g.ui.talk(P.claire, [SHORT.claireAgain]);
    s.mistakes += await g.ui.talk(P.claire, CLAIRE);
    s.flags.claire = true;
  } else if (id === 'terminal') {
    if (s.flags.done) return g.ui.talk(YOU, [SHORT.terminalDone]);
    if (!s.flags.claire || s.found.length < CLUES.length - 1) return g.ui.talk(YOU, [SHORT.terminalEarly]);
    s.mistakes += await g.ui.talk(YOU, TERMINAL);
    await g.give('fichier');
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(STORY_WORDS);
    await g.ui.talk(LENOIR, ENDING);
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
}

export function allTexts() {
  const out = [];
  for (const n of [MARC, CLAIRE, TERMINAL, ENDING, STORY, Object.values(SHORT)].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note, c.where);
  for (const l of CHAPTER.locks) out.push(l.say);
  out.push(
    'Get past the night guard at the reception.', 'Search the offices (clues {n}/{total}). Find the scientist in the laboratory.',
    "Find the documents ({n}/{total}). Stay out of the guards' torch light.", 'Go to the server room and use the computer.',
    'Chapter complete!', 'Chapter 4 complete!', 'A man in grey guards this clue. Get past him first.', 'Hint',
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
  talk(P.marc, [...MARC, SHORT.marcAgain]);
  talk(P.claire, [...CLAIRE, SHORT.claireAgain]);
  talk(YOU, [...TERMINAL, SHORT.claireEarly, SHORT.terminalEarly, SHORT.terminalDone]);
  talk(LENOIR, ENDING);
  STORY.forEach((st) => out.push([st.fr, { voice: 'denise' }]));
  for (const c of CLUES) {
    out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
    out.push([c.noteFr, { voice: 'denise' }]);
  }
  out.push([STORY_WORDS.join(' '), { voice: 'denise' }]);
  return out;
}
