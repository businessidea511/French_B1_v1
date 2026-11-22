// Le Dossier Bruxelles — A2, stage 2 : « Le train de nuit ».
// On the night train to Liège: the conductor, the bar, the sleeping car, the luggage car.
// A2 grammar: the passé composé with avoir and être (passé, allé, venue, resté),
// comparatives (plus… que, moins… que, meilleur), depuis / il y a,
// reflexive verbs (se lever, se reposer), « quelque chose de » + adjective.

export const CHAPTER = {
  id: '2b',
  title: 'Le train de nuit',
  level: 'A2',
  world: 'office',
  layout: 'train',
  saveKey: 'dossier_save_2b',
  spawn: [0.1, 39, Math.PI],
  respawn: [0.1, 38.4, Math.PI],
  lights: [[0, 2.5, 31, '#ffe2b8'], [0, 2.5, 13, '#ffcf8a'], [1.2, 2.5, -5, '#d6e4ff'], [0, 2.5, -23, '#9fb4ff'], [0, 2.5, -36, '#ff9a6a']],
  places: [{ id: 'porte', x: 0.8, z: -38.4, y: 2.2, symbol: '?' }],
  // Doors that open later: the bar (after the ticket check), the luggage car (after the passenger).
  locks: [
    { rect: [0, 2, 21.1, 22.9], flag: 'controleur', say: 'The conductor is checking tickets. Show him yours first.' },
    { rect: [0, 2, -14.9, -13.1], flag: 'vandenberg', say: 'The luggage car is locked. Maybe a passenger knows something.' },
  ],
  agents: [
    { id: 'couchettes', path: [[1.2, -8], [1.2, -13]], guards: 'telephone' },
    { id: 'fourgon', path: [[0.8, -17], [0.8, -29]], guards: 'caisse' },
    { id: 'chef', path: [[0.6, -35]], chief: true },
  ],
  next: 'Liège — La Poursuite',
  doneIcon: '🚆',
};

export const LINES = {
  agentName: 'Un homme en gris', chiefName: 'Le chef des hommes en gris',
  agentVoice: { voice: 'henri', speed: 0.95 }, chiefVoice: { voice: 'remy', speed: 0.9 },
  agentIntro: 'Vous, là. Vous allez où, comme ça ?', chiefIntro: "Nous nous retrouvons enfin. Le train ne s'arrête pas avant Liège.",
  release: 'Bon… Retournez à votre place.', storyAsk: 'Pourquoi êtes-vous dans ce train ? Dites-moi la vérité.',
  caught: 'They take you back to your seat in car 8… and walk away.',
};

export const BANKS = [
  { kind: 'phrase', icon: '⚖️', help: 'Compare: plus… que, moins… que, meilleur (better).', items: [
    ['Le train est rapide ?', 'Oui, il est plus rapide que le bus.', ['Oui, il est plus rapide de le bus.', 'Oui, il est plus vite que le bus.'], 'Is the train fast?'],
    ['Votre valise est lourde ?', 'Non, elle est moins lourde que la vôtre.', ['Non, elle est moins lourd que la vôtre.', 'Non, elle est moins lourde comme la vôtre.'], 'Is your suitcase heavy?'],
    ['Le café est bon ici ?', "Il est meilleur qu'à la gare.", ["Il est plus bon qu'à la gare.", "Il est le meilleur qu'à la gare."], 'Is the coffee good here?'],
    ['Liège est grande ?', "C'est une ville plus grande que Namur.", ["C'est une ville plus grand que Namur.", "C'est une plus ville grande que Namur."], 'Is Liège big?'],
    ['Vous voyagez souvent ?', 'Oui, je voyage plus souvent que mes amis.', ['Oui, je voyage plus souvent comme mes amis.', 'Oui, je voyage plus souvent de mes amis.'], 'Do you travel often?'],
    ['Il fait froid dehors ?', "Oui, il fait plus froid qu'à Bruxelles.", ["Oui, il est plus froid qu'à Bruxelles.", "Oui, il fait plus froid comme à Bruxelles."], 'Is it cold outside?'],
  ] },
  { kind: 'phrase', icon: '⏳', help: 'depuis (since / for), il y a (ago), and verbs with « se ».', items: [
    ['Vous êtes dans le train depuis quand ?', 'Je suis dans le train depuis une heure.', ['Je suis dans le train il y a une heure.', 'Je suis dans le train pour une heure.'], 'How long have you been on the train?'],
    ['Vous avez pris le train quand ?', "J'ai pris le train il y a une heure.", ["J'ai pris le train depuis une heure.", 'Je suis pris le train il y a une heure.'], 'When did you take the train?'],
    ['Vous dormez dans le train ?', 'Non, je ne dors jamais dans le train.', ['Non, je dors jamais pas dans le train.', 'Non, je ne dors pas jamais dans le train.'], 'Do you sleep on the train?'],
    ['Vous vous levez tôt demain ?', 'Oui, je me lève à six heures.', ['Oui, je lève à six heures.', 'Oui, me je lève à six heures.'], 'Are you getting up early tomorrow?'],
    ['Vous vous reposez ?', 'Oui, je me repose un peu.', ['Oui, je repose me un peu.', 'Oui, je te repose un peu.'], 'Are you resting?'],
    ["Qu'est-ce que vous allez faire à Liège ?", 'Je vais visiter la ville.', ['Je vais visite la ville.', 'Je va visiter la ville.'], 'What are you going to do in Liège?'],
  ] },
  { kind: 'ecoute', icon: '💶', help: 'Listen carefully to the price or the time.', gens: ['prix', 'heure'] },
];

export const CLUES = [
  { key: 'photo', where: 'In car 8, in the aisle between the seats.', art: 'la', noun: 'photo', g: 'f', en: 'the photo', emoji: '📸', x: 0.2, z: 30.6,
    noteFr: 'Une photo de toi, prise à la gare du Midi ce soir. Ils te suivent depuis Bruxelles.',
    note: 'A photo of you, taken at the Midi station tonight. They have been following you since Brussels.' },
  { key: 'billet', where: 'In car 8, near the door to the bar.', art: 'le', noun: 'billet déchiré', g: 'm', en: 'the torn ticket', emoji: '🎟️', x: 0.5, z: 25.6,
    noteFr: "Un billet déchiré : « Voiture six, couchette trois ». Le billet d'Élise ?",
    note: "A torn ticket: « Car six, berth three ». Élise's ticket?" },
  { key: 'livre', where: 'In the bar car (car 7), near the tables.', art: 'le', noun: 'livre oublié', g: 'm', en: 'the forgotten book', emoji: '📕', x: 1.0, z: 14.6,
    noteFr: 'Un livre oublié au bar. Le marque-page : « Librairie Le Phénix, Liège ».',
    note: 'A book left at the bar. The bookmark: « Librairie Le Phénix, Liège ».' },
  { key: 'perruque', where: 'In the sleeping car (car 6), inside compartment 3.', art: 'la', noun: 'boîte de perruque', g: 'f', en: 'the wig box', emoji: '💇', x: -1.4, z: -7.2,
    noteFr: 'Une boîte de perruque vide, dans la couchette trois. Élise se cache… en blonde !',
    note: 'An empty wig box, in berth three. Élise is hiding… as a blonde!' },
  { key: 'telephone', where: 'At the end of the sleeping-car corridor. A man in grey walks there.', art: 'le', noun: 'téléphone gris', g: 'm', en: 'the grey phone', emoji: '📱', x: 1.6, z: -12.4,
    noteFr: "Le téléphone d'un homme en gris : « La journaliste est dans le train. On la prend à Liège-Guillemins. »",
    note: 'The phone of a man in grey: « The journalist is on the train. We take her at Liège-Guillemins. »' },
  { key: 'caisse', where: 'In the luggage car (car 5), on the left. A man in grey walks there.', art: 'la', noun: 'caisse', g: 'f', en: 'the crate', emoji: '📦', x: -1.4, z: -23.5,
    noteFr: 'Une caisse « LUMEN — Fragile ». Dedans : des petites caméras de surveillance.',
    note: 'A crate « LUMEN — Fragile ». Inside: small surveillance cameras.' },
  { key: 'talkie', where: 'At the back of the luggage car, on the right.', art: 'le', noun: 'talkie-walkie', g: 'm', en: 'the walkie-talkie', emoji: '📻', x: 1.6, z: -30.6,
    noteFr: '« Ici Liège. Tout est prêt à Guillemins. » Ils attendent Élise là-bas.',
    note: '« Liège here. Everything is ready at Guillemins. » They are waiting for Élise there.' },
  { key: 'mouchoir', given: true, where: 'The passenger in the sleeping car gives it to you.', art: 'le', noun: 'mouchoir', g: 'm', en: 'the handkerchief', emoji: '🤍',
    noteFr: 'Un mouchoir. Dessus, au rouge à lèvres : « Palais » — la gare avant Guillemins.',
    note: 'A handkerchief. On it, in lipstick: « Palais » — the station before Guillemins.' },
];

export const STORY = [
  { emoji: '🚆', fr: 'Minuit. Le train de nuit roule vers Liège. Dehors, la pluie et le noir.', en: 'Midnight. The night train is heading for Liège. Outside, rain and darkness.' },
  { emoji: '🧣', fr: 'Élise est quelque part dans ce train. Mais où ?', en: 'Élise is somewhere on this train. But where?' },
  { emoji: '🕴️', fr: 'Deux hommes en gris sont montés à Bruxelles. Ils fouillent toutes les voitures.', en: 'Two men in grey got on in Brussels. They are searching every car.' },
  { emoji: '🕵️', fr: 'Trouve Élise, {name}, avant Liège. Le train arrive dans une heure.', en: 'Find Élise, {name}, before Liège. The train arrives in one hour.' },
];

export const PEOPLE = {
  controleur: {
    name: 'Monsieur Dubois, le contrôleur', avatar: '🎫', voice: { voice: 'gerard', speed: 0.92 },
    pos: [1.9, 23.2], face: -Math.PI / 2,
    look: { skin: '#e2b08c', hair: '#6a5a4a', coat: '#1f2a44', shirt: '#e8e2d4', pants: '#1a1d26', hat: 'cap', hatColor: '#1f2a44', build: 1.1 },
  },
  hugo: {
    name: 'Hugo, le barman', avatar: '🍫', voice: { voice: 'remy', speed: 1 },
    pos: [-1.6, 17.4], face: Math.PI / 2,
    look: { skin: '#c99a76', hair: '#2a1d14', coat: '#f2f2f2', shirt: '#f2f2f2', apron: '#2a2a2e', pants: '#1a1a1d' },
  },
  vandenberg: {
    name: 'Madame Van den Berg', avatar: '👵', voice: { voice: 'vivienne', speed: 0.9 },
    pos: [-1.3, -2.6], face: Math.PI / 2,
    look: { skin: '#f0d0b8', hair: '#e8e2d4', coat: '#3a5a4a', coatLong: true, pants: '#2a2a2a', glasses: true, scarf: '#c9a24a', height: 0.92 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const CHIEF = { name: 'Le chef des hommes en gris', avatar: '🕴️', voice: { voice: 'remy', speed: 0.88 } };

const CONTROLEUR = [
  {
    fr: "Bonsoir. Contrôle des billets, s'il vous plaît.", en: 'Good evening. Ticket check, please.',
    hint: '« le billet » is masculine: mon billet.',
    choices: [
      { fr: 'Bonsoir. Voilà mon billet.', en: 'Good evening. Here is my ticket.', ok: true },
      { fr: 'Bonsoir. Voilà ma billet.', en: '(wrong possessive)' },
      { fr: 'Bonsoir. Voici moi billet.', en: '(wrong word)' },
    ],
  },
  {
    fr: 'Merci. Vous avez pris le train à Bruxelles-Midi ?', en: 'Thank you. Did you take the train at Brussels-Midi?',
    hint: 'prendre → avoir + pris.',
    choices: [
      { fr: "Oui, j'ai pris le train à Bruxelles-Midi.", en: 'Yes, I took the train at Brussels-Midi.', ok: true },
      { fr: 'Oui, je suis pris le train à Bruxelles-Midi.', en: '(wrong helper verb)' },
      { fr: "Oui, j'ai prendu le train à Bruxelles-Midi.", en: '(wrong past participle)' },
    ],
  },
  {
    fr: 'Très bien. Nous arriverons à Liège dans une heure et quart.', en: 'Very good. We will arrive in Liège in an hour and a quarter.', listen: true,
    hint: 'Listen again (🔊). « une heure et quart » = 1 h 15.',
    choices: [{ fr: '1 h 15', ok: true }, { fr: '1 h 45' }, { fr: '4 h 15' }],
  },
  {
    fr: "(Demande-lui s'il a vu une femme en manteau rouge.)", en: '(Ask him if he has seen a woman in a red coat.)',
    hint: 'voir → avoir + vu.',
    choices: [
      { fr: 'Vous avez vu une femme en manteau rouge ?', en: 'Have you seen a woman in a red coat?', ok: true },
      { fr: 'Vous êtes vu une femme en manteau rouge ?', en: '(wrong helper verb)' },
      { fr: 'Vous avez voyé une femme en manteau rouge ?', en: '(wrong past participle)' },
    ],
  },
  { fr: 'Une femme en rouge ? Oui… Elle est passée il y a dix minutes. Elle est allée vers le bar.', en: 'A woman in red? Yes… She went by ten minutes ago. She went towards the bar.' },
  { fr: "Mais attention : deux messieurs en gris m'ont posé la même question. Ils n'avaient pas de billet… mais ils avaient une carte de police.", en: 'But be careful: two gentlemen in grey asked me the same question. They had no ticket… but they had a police card.' },
];

const HUGO = [
  {
    fr: "Bonsoir ! Le bar ferme dans un quart d'heure. Qu'est-ce que je vous sers ?", en: 'Good evening! The bar closes in a quarter of an hour. What can I get you?',
    hint: '« le chocolat » is masculine: un chocolat chaud.',
    choices: [
      { fr: "Un chocolat chaud, s'il vous plaît.", en: 'A hot chocolate, please.', ok: true },
      { fr: "Une chocolat chaud, s'il vous plaît.", en: '(wrong article)' },
      { fr: 'Je suis un chocolat chaud.', en: 'I am a hot chocolate.' },
    ],
  },
  {
    fr: 'Voilà. Ça fait trois euros cinquante.', en: 'Here you are. That is three euros fifty.', listen: true,
    hint: 'Listen again (🔊). « trois euros cinquante » = 3,50 €.',
    choices: [{ fr: '3,50 €', ok: true }, { fr: '3,15 €' }, { fr: '13,50 €' }],
  },
  {
    fr: '(Demande-lui si la femme en rouge est venue ici.)', en: '(Ask him if the woman in red came here.)',
    hint: 'venir → être + venu. With « une femme »: venue (+e).',
    choices: [
      { fr: "Est-ce qu'une femme en rouge est venue ici ?", en: 'Did a woman in red come here?', ok: true },
      { fr: "Est-ce qu'une femme en rouge a venu ici ?", en: '(wrong helper verb)' },
      { fr: "Est-ce qu'une femme en rouge est venu ici ?", en: '(the past participle needs an -e)' },
    ],
  },
  { fr: 'Oui ! Elle a bu un chocolat, comme vous. Mais elle était plus nerveuse que vous.', en: 'Yes! She drank a hot chocolate, like you. But she was more nervous than you.' },
  { fr: 'Elle est restée cinq minutes. Puis elle est partie vers les couchettes, la voiture six.', en: 'She stayed five minutes. Then she left towards the sleeping car, car six.' },
  {
    fr: '(Demande-lui si elle a laissé quelque chose.)', en: '(Ask him if she left something.)',
    hint: 'laisser → avoir + laissé.',
    choices: [
      { fr: 'Elle a laissé quelque chose ?', en: 'Did she leave something?', ok: true },
      { fr: 'Elle est laissée quelque chose ?', en: '(wrong helper verb)' },
      { fr: 'Elle a laisser quelque chose ?', en: '(infinitive instead of past participle)' },
    ],
  },
  { fr: 'Un livre, je crois. Près des tables, là-bas. Regardez bien.', en: 'A book, I think. Near the tables, over there. Look carefully.' },
];

const VANDENBERG = [
  { fr: 'Goedenavond… Oh, pardon ! Bonsoir. Je suis flamande, je parle un peu français.', en: 'Goedenavond… Oh, sorry! Good evening. I am Flemish, I speak a little French.' },
  {
    fr: '(Réponds poliment : elle parle bien français.)', en: '(Answer politely: she speaks French well.)',
    hint: 'parler is a verb: « bien » (well), not « bon » (good).',
    choices: [
      { fr: 'Mais vous parlez très bien français, madame !', en: 'But you speak French very well, madam!', ok: true },
      { fr: 'Mais vous parlez très bon français, madame !', en: '(« bon » is an adjective)' },
      { fr: 'Mais tu parles très bien français, toi !', en: '(too familiar)' },
    ],
  },
  { fr: "Merci, c'est gentil. Je vais à Liège chez ma fille. Je prends ce train depuis vingt ans.", en: 'Thank you, that is kind. I am going to Liège to my daughter. I have been taking this train for twenty years.' },
  {
    fr: '(Demande-lui si elle a vu quelque chose de bizarre.)', en: '(Ask her if she has seen something strange.)',
    hint: '« quelque chose de » + adjective.',
    choices: [
      { fr: 'Vous avez vu quelque chose de bizarre ?', en: 'Have you seen something strange?', ok: true },
      { fr: 'Vous avez vu quelque chose bizarre de ?', en: '(wrong word order)' },
      { fr: 'Vous avez vu quelque bizarre chose ?', en: '(wrong word order)' },
    ],
  },
  { fr: 'Oui ! Une jeune femme est entrée dans le compartiment trois. Elle est ressortie avec des cheveux blonds !', en: 'Yes! A young woman went into compartment three. She came out with blond hair!' },
  { fr: 'Et avant de partir, elle m\'a donné ce mouchoir. Elle a dit : « Pour la personne qui me cherche. »', en: 'And before leaving, she gave me this handkerchief. She said: « For the person who is looking for me. »' },
  { fr: 'Ah, et le fourgon à bagages est ouvert. Le contrôleur l\'a ouvert pour ma valise. Mais les hommes en gris sont là-bas aussi…', en: 'Ah, and the luggage car is open. The conductor opened it for my suitcase. But the men in grey are there too…' },
];

const CHIEF_MEET = [
  { fr: 'Vous voilà. Où est la journaliste ?', en: 'There you are. Where is the journalist?' },
  { fr: 'Vous ne voulez pas parler ? Nous avons une heure… et beaucoup de questions.', en: 'You do not want to talk? We have an hour… and a lot of questions.' },
];

const ENDING = [
  { who: CHIEF, fr: 'Bon… Vous êtes un simple touriste. Mais à Guillemins, nous vous attendrons.', en: 'Fine… You are just a tourist. But at Guillemins, we will be waiting for you.' },
  { who: YOU, fr: '(Le train freine. « Liège-Palais. » Une gare avant Guillemins.)', en: '(The train brakes. « Liège-Palais. » One station before Guillemins.)' },
  { who: YOU, fr: '(Sur le quai, une femme blonde en manteau rouge descend… et disparaît dans la nuit.)', en: '(On the platform, a blonde woman in a red coat gets off… and disappears into the night.)' },
  { who: YOU, fr: '(Tu sautes du train juste avant la fermeture des portes.)', en: '(You jump off the train just before the doors close.)' },
];

export function objective(s) {
  if (!s.flags.controleur) return 'Show your ticket to the conductor, at the end of car 8.';
  if (!s.flags.hugo) return 'Go to the bar car (car 7). Clues: {n}/{total}.';
  if (!s.flags.vandenberg) return 'Go to the sleeping car (car 6). A passenger is still awake.';
  if (s.found.length < CLUES.length) return 'Find all the clues ({n}/{total}). The luggage car (car 5) is open.';
  if (!s.flags.done) return 'Go to the front of the train, past the luggage car.';
  return 'Stage complete! Next: Liège.';
}

export function hasNews(id, s) {
  if (id === 'controleur') return !s.flags.controleur;
  if (id === 'hugo') return s.flags.controleur && !s.flags.hugo;
  if (id === 'vandenberg') return s.flags.hugo && !s.flags.vandenberg;
  if (id === 'porte') return s.flags.vandenberg && s.found.length >= CLUES.length && !s.flags.done;
  return false;
}

export async function afterClue(g) {
  const s = g.state;
  if (s.found.length >= CLUES.length && s.flags.vandenberg && !s.flags.allTold) {
    s.flags.allTold = true;
    g.save();
    g.ui.toast('The train is slowing down… Go to the front of the train.', 3500);
  }
  return false;
}

const SHORT = {
  controleurAgain: { fr: 'Le bar est dans la voiture sept. Bon voyage !', en: 'The bar is in car seven. Have a good trip!' },
  hugoEarly: { fr: "Un instant, s'il vous plaît, je range.", en: 'Just a moment, please, I am tidying up.' },
  hugoAgain: { fr: 'Les couchettes, voiture six. Bonne chance !', en: 'The sleeping car, car six. Good luck!' },
  vandenbergEarly: { fr: '(Une vieille dame lit un livre. Elle ne te regarde pas.)', en: '(An old lady is reading a book. She does not look at you.)' },
  vandenbergAgain: { fr: 'Le fourgon est ouvert. Faites attention à vous !', en: 'The luggage car is open. Take care of yourself!' },
  porteEarly: { fr: "(La porte de la plateforme. Mais je n'ai pas encore tous les indices.)", en: '(The door of the platform. But I do not have all the clues yet.)' },
  porteDone: { fr: '(Liège-Palais. Élise est passée par ici.)', en: '(Liège-Palais. Élise went this way.)' },
};
const STORY_WORDS = ['Hier,', "j'ai", 'pris', 'le', 'train', 'pour', 'visiter', 'Liège.'];

export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'controleur') {
    if (s.flags.controleur) return g.ui.talk(P.controleur, [SHORT.controleurAgain]);
    s.mistakes += await g.ui.talk(P.controleur, CONTROLEUR);
    s.flags.controleur = true;
    g.save();
    g.ui.toast('The door to the bar car is open.', 2800);
  } else if (id === 'hugo') {
    if (!s.flags.controleur) return g.ui.talk(P.hugo, [SHORT.hugoEarly]);
    if (s.flags.hugo) return g.ui.talk(P.hugo, [SHORT.hugoAgain]);
    s.mistakes += await g.ui.talk(P.hugo, HUGO);
    s.flags.hugo = true;
  } else if (id === 'vandenberg') {
    if (!s.flags.hugo) return g.ui.talk(YOU, [SHORT.vandenbergEarly]);
    if (s.flags.vandenberg) return g.ui.talk(P.vandenberg, [SHORT.vandenbergAgain]);
    s.mistakes += await g.ui.talk(P.vandenberg, VANDENBERG.slice(0, 6));
    await g.give('mouchoir');
    s.mistakes += await g.ui.talk(P.vandenberg, VANDENBERG.slice(6));
    s.flags.vandenberg = true;
    g.save();
    await afterClue(g);
  } else if (id === 'porte') {
    if (s.flags.done) return g.ui.talk(YOU, [SHORT.porteDone]);
    if (!hasNews('porte', s)) return g.ui.talk(YOU, [SHORT.porteEarly]);
    await g.ui.talk(CHIEF, CHIEF_MEET);
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(STORY_WORDS);
    await g.ui.talk(CHIEF, ENDING);
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
}

export function allTexts() {
  const out = [];
  for (const n of [CONTROLEUR, HUGO, VANDENBERG, CHIEF_MEET, ENDING, STORY, Object.values(SHORT)].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note, c.where);
  for (const l of CHAPTER.locks) out.push(l.say);
  out.push(
    'Show your ticket to the conductor, at the end of car 8.', 'Go to the bar car (car 7). Clues: {n}/{total}.',
    'Go to the sleeping car (car 6). A passenger is still awake.', 'Find all the clues ({n}/{total}). The luggage car (car 5) is open.',
    'Go to the front of the train, past the luggage car.', 'Stage complete! Next: Liège.',
    'The door to the bar car is open.', 'The train is slowing down… Go to the front of the train.',
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
  talk(P.controleur, [...CONTROLEUR, SHORT.controleurAgain]);
  talk(P.hugo, [...HUGO, SHORT.hugoEarly, SHORT.hugoAgain]);
  talk(P.vandenberg, [...VANDENBERG, SHORT.vandenbergAgain]);
  talk(CHIEF, [...CHIEF_MEET, ...ENDING]);
  talk(YOU, [SHORT.vandenbergEarly, SHORT.porteEarly, SHORT.porteDone]);
  STORY.forEach((st, i) => out.push([st.fr, { voice: i === 0 ? 'charline' : 'denise' }]));
  for (const c of CLUES) {
    out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
    out.push([c.noteFr, { voice: 'denise' }]);
  }
  out.push([STORY_WORDS.join(' '), { voice: 'denise' }]);
  return out;
}
