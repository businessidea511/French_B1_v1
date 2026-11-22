// Le Dossier Bruxelles — A1, stage 2 : « L'immeuble d'Élise ».
// Inside number 12, rue des Ombres: the hall, Élise's flat, the attic, the cellar.
// A1 grammar: possessives (mon / ma / mes, son / sa / ses), « il y a »,
// places (sur, sous, dans, à côté de), rooms and objects, days of the week,
// ordinal numbers (le troisième étage).

export const CHAPTER = {
  id: '1b',
  title: "L'immeuble d'Élise",
  level: 'A1',
  world: 'office',
  layout: 'immeuble',
  saveKey: 'dossier_save_1b',
  spawn: [0, 18.6, Math.PI],
  respawn: [0, 17, Math.PI],
  lights: [[0, 2.6, 15, '#ffd59a'], [-9, 2.6, 3, '#ffe2b8'], [8, 2.6, 6, '#fff3d6'], [11, 2.6, -2, '#ffcf9a'], [-8, 2.6, -13, '#c9b48a'], [9, 2.6, -13, '#9fb4ff']],
  places: [{ id: 'boite', x: 11, z: -16.4, y: 1.8, symbol: '?' }],
  // Doors that open later: the flat (Madame Lambert's key), the attic (the little key), the cellar (the neighbour).
  locks: [
    { rect: [-1.6, 1.6, 8.6, 11.4], flag: 'lambert', say: "Élise's door is locked. Madame Lambert, in the hall, has a key." },
    { rect: [-9.6, -6.4, -7.4, -4.6], clue: 'cle', say: 'The attic door is locked. Its key is somewhere in the flat.' },
    { rect: [6.4, 9.6, -7.4, -4.6], flag: 'petit', say: 'The cellar is locked. A neighbour may have the key.' },
  ],
  agents: [
    { id: 'salon', path: [[-13, -1.6], [-4.5, -1.6]], guards: 'agenda' },
    { id: 'grenier', path: [[-13, -15.6], [-4.2, -15.6]], guards: 'plan' },
    { id: 'chef', path: [[7.4, -14.2]], chief: true },
  ],
  next: 'La station Bourse',
  doneIcon: '📦',
};

export const LINES = {
  agentName: 'Un homme en gris', chiefName: "L'homme au manteau gris",
  agentVoice: { voice: 'henri', speed: 0.95 }, chiefVoice: { voice: 'remy', speed: 0.9 },
  agentIntro: "Qu'est-ce que vous faites dans cet appartement ?", chiefIntro: 'Vous cherchez quelque chose ? Moi aussi.',
  release: 'Bon. Partez. Et ne revenez pas.', storyAsk: 'Pourquoi êtes-vous ici ? Expliquez-moi.',
  caught: 'They push you down to the hall… You come back up, quietly.',
};

export const BANKS = [
  { kind: 'phrase', icon: '🏠', help: 'mon / ma / mes, son / sa / ses, il y a, and where things are.', items: [
    ['Où est votre sac ?', 'Mon sac est sur la table.', ['Ma sac est sur la table.', 'Mes sac est sur la table.'], 'Where is your bag?'],
    ['Où sont vos clés ?', 'Mes clés sont dans ma poche.', ['Mon clés sont dans ma poche.', 'Mes clés est dans ma poche.'], 'Where are your keys?'],
    ["C'est l'appartement de qui ?", "C'est l'appartement de mon amie.", ["C'est l'appartement de ma amie.", "C'est l'appartement de mes amie."], 'Whose flat is it?'],
    ["Il y a quelqu'un dans la cuisine ?", "Non, il n'y a personne.", ["Non, il n'est personne.", 'Non, il y a personne pas.'], 'Is there someone in the kitchen?'],
    ["Qu'est-ce qu'il y a dans votre poche ?", 'Il y a un téléphone.', ['Il est un téléphone.', 'Il y sont un téléphone.'], 'What is there in your pocket?'],
    ['Votre amie a un chat ?', 'Oui, elle a un chat noir.', ['Oui, elle est un chat noir.', 'Oui, elle a un noir chat.'], 'Does your friend have a cat?'],
    ['Où est la cuisine ?', 'La cuisine est à côté du salon.', ['La cuisine est à côté de le salon.', 'La cuisine est à côté le salon.'], 'Where is the kitchen?'],
    ['Où est le chat ?', 'Le chat est sous le lit.', ['Le chat est sous la lit.', 'Le chat sont sous le lit.'], 'Where is the cat?'],
    ['Élise habite ici ?', 'Oui, elle habite au troisième étage.', ['Oui, elle habite au trois étage.', 'Oui, elle habites au troisième étage.'], 'Does Élise live here?'],
  ] },
  { kind: 'objets', icon: '🔍', help: 'Name the object, with le / la / les.', ask: "Qu'est-ce que c'est ?", askEn: 'What is this?', items: [
    ['la lampe', '💡'], ['le lit', '🛏️'], ['la chaise', '🪑'], ['la porte', '🚪'], ['le canapé', '🛋️'], ['la fenêtre', '🪟'],
    ['le miroir', '🪞'], ['la tasse', '☕'], ['le livre', '📕'], ['la bougie', '🕯️'], ['la valise', '🧳'], ['le réveil', '⏰'],
    ['la boîte', '📦'], ['le cadre', '🖼️'], ['le balai', '🧹'], ['les clés', '🗝️'],
  ] },
  { kind: 'ecoute', icon: '🔢', help: 'Listen carefully to the number.', gens: ['etage', 'heure'] },
];

export const CLUES = [
  { key: 'carte', given: true, where: 'Madame Lambert gives it to you, in the hall.', art: 'la', noun: 'carte postale', g: 'f', en: 'the postcard', emoji: '📮',
    noteFr: 'Une carte postale de Liège. Au dos : « Merci pour tout. — V. »',
    note: 'A postcard from Liège. On the back: « Thank you for everything. — V. »' },
  { key: 'agenda', where: 'In the living room, near the desk. A man in grey is searching the flat.', art: "l'", noun: "agenda d'Élise", g: 'm', en: "Élise's diary", emoji: '📔', x: -6.6, z: -2.2,
    noteFr: "L'agenda d'Élise. Mercredi : « Métro Bourse, vingt-trois heures. »",
    note: "Élise's diary. Wednesday: « Bourse metro, 11 p.m. »" },
  { key: 'tasses', where: 'In the kitchen, next to the table.', art: 'les', noun: 'deux tasses', g: 'f', en: 'the two cups', emoji: '☕', x: 9.6, z: 3.8,
    noteFr: "Deux tasses de café sur la table. Élise n'était pas seule.",
    note: 'Two cups of coffee on the table. Élise was not alone.' },
  { key: 'photo', where: 'In the bedroom, next to the wardrobe.', art: 'la', noun: 'photo de Liège', g: 'f', en: 'the photo from Liège', emoji: '🖼️', x: 3, z: -3.4,
    noteFr: 'Élise et un homme devant une librairie, à Liège. Derrière : « Victor, 2019 ».',
    note: 'Élise and a man in front of a bookshop, in Liège. On the back: « Victor, 2019 ».' },
  { key: 'cle', where: 'In the bedroom, under the bed.', art: 'la', noun: 'petite clé', g: 'f', en: 'the little key', emoji: '🗝️', x: 10.2, z: -4.4,
    noteFr: 'Une petite clé sous le lit, avec une étiquette : « Grenier ».',
    note: 'A little key under the bed, with a tag: « Attic ».' },
  { key: 'appareil', where: 'In the attic, near the old trunk.', art: "l'", noun: 'appareil photo', g: 'm', en: 'the camera', emoji: '📷', x: -11, z: -11.6,
    noteFr: "Le vieil appareil photo d'Élise. La dernière photo : un homme en gris devant le métro Bourse.",
    note: "Élise's old camera. The last picture: a man in grey in front of the Bourse metro." },
  { key: 'plan', where: 'At the back of the attic. A man in grey walks there.', art: 'le', noun: 'plan du métro', g: 'm', en: 'the metro map', emoji: '🗺️', x: -3, z: -15.4,
    noteFr: 'Un plan du métro. La station Bourse est entourée en rouge : « Quai 2 ».',
    note: 'A metro map. Bourse station is circled in red: « Platform 2 ».' },
  { key: 'abonnement', given: true, where: 'In the metal box, in the cellar.', art: "l'", noun: 'abonnement de métro', g: 'm', en: 'the metro pass', emoji: '🎫',
    noteFr: "L'abonnement de métro d'Élise, et un mot : « Bourse, quai deux. Je t'attends. »",
    note: "Élise's metro pass, and a note: « Bourse, platform two. I am waiting for you. »" },
];

export const STORY = [
  { emoji: '🚪', fr: 'Vingt-deux heures. Tu retournes au numéro douze, rue des Ombres.', en: 'Ten p.m. You go back to number 12, rue des Ombres.' },
  { emoji: '🔑', fr: "Madame Lambert a une clé de l'appartement d'Élise. Elle t'attend dans le hall.", en: "Madame Lambert has a key to Élise's flat. She is waiting for you in the hall." },
  { emoji: '👣', fr: "Mais quelqu'un est déjà chez Élise… Tu entends des pas au troisième étage.", en: 'But someone is already in Élise\'s flat… You hear footsteps on the third floor.' },
  { emoji: '🕵️', fr: 'Cherche bien, {name}. Le rendez-vous au métro est à vingt-trois heures.', en: 'Search well, {name}. The meeting at the metro is at 11 p.m.' },
];

export const PEOPLE = {
  lambert: {
    name: 'Madame Lambert', avatar: '👵', voice: { voice: 'vivienne', speed: 0.9 },
    pos: [-12.4, 14.2], face: Math.PI / 2,
    look: { skin: '#e8c6a8', hair: '#d4d4d4', coat: '#5b3f4f', coatLong: true, pants: '#2a2228', glasses: true, scarf: '#8a6a3a', height: 0.93 },
  },
  petit: {
    name: 'Monsieur Petit, le voisin', avatar: '👴', voice: { voice: 'gerard', speed: 0.92 },
    pos: [9.4, 16.4], face: -Math.PI / 2,
    look: { skin: '#e2b08c', hair: '#9a9a9a', coat: '#4a4a3a', pants: '#2a2a2a', glasses: true, hat: 'beret', hatColor: '#2a2a33', height: 0.95, build: 1.1 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const DIARY = { name: "L'agenda d'Élise", avatar: '📔', voice: { voice: 'charline', speed: 0.92 } };
export const CHIEF = { name: "L'homme au manteau gris", avatar: '🕴️', voice: { voice: 'remy', speed: 0.88 } };

const LAMBERT = [
  { fr: "Ah, c'est vous ! L'ami d'Élise. Entrez, entrez. Il fait froid.", en: "Ah, it's you! Élise's friend. Come in, come in. It's cold." },
  {
    fr: "Vous voulez voir l'appartement d'Élise, c'est ça ?", en: "You want to see Élise's flat, is that it?",
    hint: 'Answer politely: « Oui, madame, s\'il vous plaît ».',
    choices: [
      { fr: "Oui, madame, s'il vous plaît.", en: 'Yes, madam, please.', ok: true },
      { fr: 'Oui, tu veux.', en: 'Yes, you want.' },
      { fr: 'Non, je veux la cuisine.', en: 'No, I want the kitchen.' },
    ],
  },
  {
    fr: 'Élise habite au troisième étage. Appartement 3B.', en: 'Élise lives on the third floor. Flat 3B.', listen: true,
    hint: 'Listen again (🔊). « troisième » = 3rd.',
    choices: [{ fr: '3e étage', ok: true }, { fr: '13e étage' }, { fr: '2e étage' }],
  },
  { fr: 'Voici sa clé. Elle me donne toujours une clé… pour son chat.', en: 'Here is her key. She always gives me a key… for her cat.' },
  {
    fr: '(Demande-lui où est le chat.)', en: '(Ask her where the cat is.)',
    hint: '« son chat » = her cat (le chat → son). « Où est… ? » = Where is…?',
    choices: [
      { fr: 'Où est son chat ?', en: 'Where is her cat?', ok: true },
      { fr: 'Où sont son chat ?', en: '(wrong verb form)' },
      { fr: 'Où est sa chat ?', en: '(wrong possessive)' },
    ],
  },
  { fr: 'Le chat ? Il est chez moi. Le pauvre… Il est seul depuis trois jours.', en: 'The cat? He is at my place. Poor thing… He has been alone for three days.' },
  { fr: 'Ah, et il y a du courrier pour Élise. Une carte postale. Tenez.', en: 'Ah, and there is some mail for Élise. A postcard. Here.' },
  { fr: "Attention : hier soir, j'ai entendu des pas là-haut. Quelqu'un est entré chez elle.", en: 'Be careful: last night, I heard footsteps up there. Someone went into her flat.' },
];

const DIARY_READ = [
  { fr: '« Lundi : finir mon article sur Lumen. »', en: '« Monday: finish my article about Lumen. »' },
  {
    fr: '« ___ : café avec V., à la maison. »', en: '« ___: coffee with V., at home. »',
    hint: 'The day after Monday (lundi) is…',
    choices: [{ fr: 'Mardi', ok: true }, { fr: 'Dimanche' }, { fr: 'Samedi' }], keepOrder: true,
  },
  {
    fr: '« Mercredi : métro Bourse, à vingt-trois heures. »', en: '« Wednesday: Bourse metro, at 11 p.m. »', listen: true,
    hint: 'Listen again (🔊). « vingt-trois heures » = 23:00.',
    choices: [{ fr: '23:00', ok: true }, { fr: '13:00' }, { fr: '22:00' }],
  },
  { fr: '« Jeudi : … » (La page est arrachée.)', en: '« Thursday: … » (The page is torn out.)' },
];

const PETIT = [
  {
    fr: 'Chut ! Pas si fort… Vous êtes qui, vous ?', en: 'Shh! Not so loud… Who are you?',
    hint: 'Introduce yourself: « Je suis… Je m\'appelle… ».',
    choices: [
      { fr: "Je suis un ami d'Élise. Je m'appelle {name}.", en: "I am a friend of Élise. My name is {name}.", ok: true },
      { fr: "Je suis le chat d'Élise.", en: "I am Élise's cat." },
      { fr: "Tu es un ami d'Élise.", en: 'You are a friend of Élise.' },
    ],
  },
  {
    fr: "Un ami d'Élise… Bon. Moi, c'est Monsieur Petit. J'habite au quatrième étage.", en: "A friend of Élise… All right. I'm Monsieur Petit. I live on the fourth floor.", listen: true,
    hint: 'Listen again (🔊). « quatrième » = 4th.',
    choices: [{ fr: '4e étage', ok: true }, { fr: '14e étage' }, { fr: '1er étage' }],
  },
  { fr: "Hier soir, il y avait du bruit chez Élise. Et après… dans la cave.", en: "Last night, there was noise in Élise's flat. And then… in the cellar." },
  {
    fr: "(Demande-lui s'il a la clé de la cave.)", en: '(Ask him if he has the key to the cellar.)',
    hint: 'avoir: vous avez. « la clé » is feminine.',
    choices: [
      { fr: 'Vous avez la clé de la cave ?', en: 'Do you have the key to the cellar?', ok: true },
      { fr: 'Vous êtes la clé de la cave ?', en: 'Are you the key to the cellar?' },
      { fr: 'Vous avez le clé de la cave ?', en: '(wrong article)' },
    ],
  },
  { fr: 'Oui, bien sûr. Tous les voisins ont une clé. Voilà, la cave est ouverte.', en: 'Yes, of course. All the neighbours have a key. There, the cellar is open.' },
  { fr: "Mais d'abord, montez au grenier. Élise cache toujours ses affaires là-haut.", en: 'But first, go up to the attic. Élise always hides her things up there.' },
  { fr: "Et faites attention. Un homme en manteau gris est descendu à la cave. Il n'est pas remonté.", en: 'And be careful. A man in a grey coat went down to the cellar. He has not come back up.' },
];

const CHIEF_MEET = [
  { fr: 'Encore vous ? Vous cherchez Élise, vous aussi ?', en: 'You again? You are looking for Élise too?' },
  { fr: "Cette boîte est à moi. Répondez d'abord à mes questions.", en: 'This box is mine. First, answer my questions.' },
];

const ENDING = [
  { who: CHIEF, fr: 'Hmm. Gardez votre petite boîte. On se reverra… au métro.', en: 'Hmm. Keep your little box. We will meet again… at the metro.' },
  { who: YOU, fr: "(Dans la boîte, il y a un abonnement de métro… et un mot d'Élise.)", en: "(In the box, there is a metro pass… and a note from Élise.)" },
];
const ENDING_AFTER = [
  { who: YOU, fr: '(Vingt-deux heures quarante. Le rendez-vous est dans vingt minutes. Vite, au métro Bourse !)', en: '(10:40 p.m. The meeting is in twenty minutes. Quick, to the Bourse metro!)' },
];

export function objective(s) {
  if (!s.flags.lambert) return 'Talk to Madame Lambert in the hall.';
  if (!s.found.includes('cle')) return "Search Élise's flat (clues {n}/{total}). Someone is inside…";
  if (!s.flags.petit) return 'The neighbour, Monsieur Petit, is in the hall. Talk to him.';
  if (!s.found.includes('appareil') || !s.found.includes('plan')) return 'Search the attic (clues {n}/{total}).';
  if (!s.flags.done) return 'Go down to the cellar and open the metal box.';
  return 'Stage complete! Next: the Bourse metro.';
}

export function hasNews(id, s) {
  if (id === 'lambert') return !s.flags.lambert;
  if (id === 'petit') return s.flags.lambert && s.found.includes('cle') && !s.flags.petit;
  if (id === 'boite') return s.flags.petit && s.found.includes('appareil') && s.found.includes('plan') && !s.flags.done;
  return false;
}

export async function afterClue(g) {
  const s = g.state;
  if (s.found.includes('agenda') && !s.flags.diary) {
    s.flags.diary = true;
    g.save();
    s.mistakes += await g.ui.talk(DIARY, DIARY_READ);
    g.save();
    return true;
  }
  if (s.found.includes('cle') && !s.flags.keyTold) {
    s.flags.keyTold = true;
    g.save();
    g.ui.toast('The attic key! Monsieur Petit, in the hall, wants to talk to you.', 3500);
  }
  return false;
}

const SHORT = {
  lambertAgain: { fr: 'Le troisième étage, appartement 3B. Et faites attention à vous.', en: 'Third floor, flat 3B. And take care of yourself.' },
  petitEarly: { fr: 'Bonsoir… Il est tard. Bonne nuit.', en: 'Good evening… It is late. Good night.' },
  petitAgain: { fr: "Le grenier, puis la cave. Et pas de bruit, s'il vous plaît !", en: 'The attic, then the cellar. And no noise, please!' },
  boiteEarly: { fr: "(Une vieille boîte en métal… Mais d'abord, je dois fouiller le grenier.)", en: '(An old metal box… But first, I must search the attic.)' },
  boiteDone: { fr: '(Vite, au métro Bourse ! Quai deux, vingt-trois heures.)', en: '(Quick, to the Bourse metro! Platform two, 11 p.m.)' },
};
const STORY_WORDS = ['Je', 'cherche', 'mon', 'amie', 'Élise.'];

export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'lambert') {
    if (s.flags.lambert) return g.ui.talk(P.lambert, [SHORT.lambertAgain]);
    s.mistakes += await g.ui.talk(P.lambert, LAMBERT);
    s.flags.lambert = true;
    g.save();
    await g.give('carte');
    g.ui.toast("Élise's door is open: flat 3B, behind the hall.", 3200);
  } else if (id === 'petit') {
    if (!s.found.includes('cle')) return g.ui.talk(P.petit, [SHORT.petitEarly]);
    if (s.flags.petit) return g.ui.talk(P.petit, [SHORT.petitAgain]);
    s.mistakes += await g.ui.talk(P.petit, PETIT);
    s.flags.petit = true;
  } else if (id === 'boite') {
    if (s.flags.done) return g.ui.talk(YOU, [SHORT.boiteDone]);
    if (!hasNews('boite', s)) return g.ui.talk(YOU, [SHORT.boiteEarly]);
    await g.ui.talk(CHIEF, CHIEF_MEET);
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(STORY_WORDS);
    await g.ui.talk(CHIEF, ENDING);
    await g.give('abonnement');
    await g.ui.talk(YOU, ENDING_AFTER);
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
}

export function allTexts() {
  const out = [];
  for (const n of [LAMBERT, DIARY_READ, PETIT, CHIEF_MEET, ENDING, ENDING_AFTER, STORY, Object.values(SHORT)].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note, c.where);
  for (const l of CHAPTER.locks) out.push(l.say);
  out.push(
    'Talk to Madame Lambert in the hall.', "Search Élise's flat (clues {n}/{total}). Someone is inside…",
    'The neighbour, Monsieur Petit, is in the hall. Talk to him.', 'Search the attic (clues {n}/{total}).',
    'Go down to the cellar and open the metal box.', 'Stage complete! Next: the Bourse metro.',
    "Élise's door is open: flat 3B, behind the hall.", 'The attic key! Monsieur Petit, in the hall, wants to talk to you.',
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
  talk(P.lambert, [...LAMBERT, SHORT.lambertAgain]);
  talk(P.petit, [...PETIT, SHORT.petitEarly, SHORT.petitAgain]);
  talk(DIARY, DIARY_READ);
  talk(CHIEF, [...CHIEF_MEET, ...ENDING, ...ENDING_AFTER]);
  talk(YOU, [SHORT.boiteEarly, SHORT.boiteDone]);
  STORY.forEach((st, i) => out.push([st.fr, { voice: i === 0 ? 'charline' : 'denise' }]));
  for (const c of CLUES) {
    out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
    out.push([c.noteFr, { voice: 'denise' }]);
  }
  out.push([STORY_WORDS.join(' '), { voice: 'denise' }]);
  return out;
}
