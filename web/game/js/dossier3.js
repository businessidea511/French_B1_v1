// Le Dossier Bruxelles — Chapitre 3 : « Liège — La Poursuite » (A2+ → B1).
// The imperative (tourne, prends, va), the futur proche and the futur simple,
// comparatives, and the COD pronouns (le, la, l', les). Every line is written
// here: no AI call to play.

const NODES = [];
for (const x of [-30, 0, 30]) for (const z of [-30, 0, 30]) NODES.push({ x, z });

export const CHAPTER = {
  id: 3,
  title: 'Chapitre 3 : Liège — La Poursuite',
  level: 'A2+',
  world: 'liege',
  saveKey: 'dossier_save_ch3',
  spawn: [0, 33, Math.PI],
  respawn: [0, 32, Math.PI],
  lights: [[-6, 3, 14, '#9fffc0'], [6, 3, 12, '#ffb36b'], [24, 3, -35, '#ffd9a0'], [0, 4, 0], [-30, 4, 0], [30, 4, 0]],
  places: [],
  agents: [
    { id: 'patrouille1', path: [[-14, 2.5], [-24, 2.5]], guards: 'briquet' },
    { id: 'patrouille2', path: [[10, -27.5], [20, -27.5]], guards: 'montre' },
  ],
  chase: {
    scooter: [2.5, 16, Math.PI],
    nodes: NODES,
  },
  next: 'Chapitre 4 : Le Laboratoire Lumen',
  doneIcon: '🏍️',
};

export const LINES = {
  agentName: 'Un homme en gris', chiefName: 'Le chef des hommes en gris',
  agentVoice: { voice: 'henri', speed: 0.95 }, chiefVoice: { voice: 'remy', speed: 0.92 },
  agentIntro: 'Vous, là ! Arrêtez-vous. Quelques questions.', chiefIntro: 'Nous nous revoyons.',
  release: 'Bon. Allez-y… pour le moment.', storyAsk: 'Expliquez-vous.',
  caught: 'They hold you for an hour, then let you go near the station.',
};

export const BANKS = [
  { kind: 'phrase', icon: '👉', help: 'The imperative: give the direction (allez, prenez, tournez…).', items: [
    ['Je cherche la gare. Je vais où ?', 'Prenez la deuxième rue à droite.', ['Prendre la deuxième rue à droite.', 'Prenez la deuxième rue à droit.'], "I'm looking for the station. Where do I go?"],
    ['Et pour la Place du Marché ?', 'Allez tout droit, puis tournez à gauche.', ['Allez tout droit, puis tourner à gauche.', 'Aller tout droit, puis tournez à gauche.'], 'And for the Place du Marché?'],
    ['Je peux voir vos papiers ?', 'Oui, regardez-les.', ['Oui, les regardez.', 'Oui, regardez-leur.'], 'Can I see your papers?'],
    ['Je dois attendre ici ?', 'Non, ne restez pas ici.', ['Non, ne restez ici pas.', 'Non, pas restez ici.'], 'Do I have to wait here?'],
    ['Je téléphone à la police ?', "Non, ne l'appelez pas.", ["Non, ne appelez la pas.", "Non, n'appelez pas la."], 'Shall I phone the police?'],
  ] },
  { kind: 'phrase', icon: '🔮', help: 'The future: aller + infinitive, or the futur simple.', items: [
    ["Qu'est-ce que vous allez faire ce soir ?", "Je vais dormir à l'hôtel.", ["Je vais dormi à l'hôtel.", "Je allez dormir à l'hôtel."], 'What are you going to do tonight?'],
    ['Vous partirez quand ?', 'Je partirai demain matin.', ['Je partira demain matin.', 'Je partir demain matin.'], 'When will you leave?'],
    ['Vous resterez combien de temps ?', 'Je resterai deux jours.', ['Je resterais deux jours hier.', 'Je resté deux jours.'], 'How long will you stay?'],
    ['Vous reviendrez à Liège ?', 'Oui, je reviendrai bientôt.', ['Oui, je revenirai bientôt.', 'Oui, je reviens hier.'], 'Will you come back to Liège?'],
    ['Il va pleuvoir demain ?', 'Oui, il va pleuvoir toute la journée.', ['Oui, il va plu toute la journée.', 'Oui, il pleuvoir toute la journée.'], 'Is it going to rain tomorrow?'],
  ] },
  { kind: 'phrase', icon: '🎯', help: 'COD pronouns: le, la, l\', les (before the verb).', items: [
    ['Vous connaissez Victor ?', 'Non, je ne le connais pas.', ['Non, je ne lui connais pas.', 'Non, je le ne connais pas.'], 'Do you know Victor?'],
    ['Vous avez votre billet ?', "Oui, je l'ai.", ['Oui, je lui ai.', "Oui, j'ai le."], 'Do you have your ticket?'],
    ['Vous avez vu ces photos ?', 'Non, je ne les ai pas vues.', ['Non, je ne leur ai pas vues.', 'Non, je les ne ai pas vues.'], 'Have you seen these photos?'],
    ['Vous cherchez la librairie ?', 'Non, je ne la cherche pas.', ['Non, je ne lui cherche pas.', 'Non, je la ne cherche pas.'], 'Are you looking for the bookshop?'],
    ['Vous regardez ce scooter ?', 'Oui, je le regarde.', ['Oui, je lui regarde.', 'Oui, je regarde le.'], 'Are you looking at this scooter?'],
  ] },
];

export const CLUES = [
  { key: 'foulard', where: 'Near the station Liège-Palais, where you arrived.', art: 'le', noun: 'foulard rouge', g: 'm', en: 'the red scarf', emoji: '🧣', x: -4.4, z: 31,
    noteFr: "Un foulard rouge, comme le manteau de la femme du train. Élise est passée par ici.",
    note: 'A red scarf, like the coat of the woman on the train. Élise came this way.' },
  { key: 'bus', where: 'On the east street, near the Place du Marché.', art: 'le', noun: 'ticket de bus', g: 'm', en: 'the bus ticket', emoji: '🚌', x: 15, z: 3.5,
    noteFr: "Un ticket de bus de Liège, d'aujourd'hui, vingt-deux heures.",
    note: "A Liège bus ticket, from today, 10 p.m." },
  { key: 'briquet', where: 'On the west street, near the Place du Marché. A man in grey guards it.', art: 'le', noun: 'briquet', g: 'm', en: 'the lighter', emoji: '🔥', x: -19, z: -3.5,
    noteFr: 'Un briquet avec un dessin : un oiseau de feu. Le Phénix ?',
    note: 'A lighter with a drawing: a bird of fire. The Phoenix?' },
  { key: 'carte', where: 'On the west street, near the café du Pont.', art: 'la', noun: 'carte postale', g: 'f', en: 'the postcard', emoji: '💌', x: -27, z: 14,
    noteFr: '« Librairie Le Phénix — livres anciens. » Au dos : « Au coin nord-est. »',
    note: '« Le Phénix bookshop — old books. » On the back: « At the north-east corner. »' },
  { key: 'montre', where: 'On the north street. A man in grey guards it.', art: 'la', noun: 'montre', g: 'f', en: 'the watch', emoji: '⌚', x: 15, z: -32.5,
    noteFr: 'Une montre cassée, arrêtée à vingt-trois heures cinquante-deux. Quelqu\'un s\'est battu ici.',
    note: 'A broken watch, stopped at 11:52 p.m. Someone fought here.' },
  { key: 'plan', where: 'Madame Renard (the night shop) will give it to you.', art: 'le', noun: 'plan de la ville', g: 'm', en: 'the town map', emoji: '🗺️', given: true,
    noteFr: 'Un plan de Liège : les rues font un grand carré autour de la Place du Marché.',
    note: 'A map of Liège: the streets make a big square around the Place du Marché.' },
];

export const STORY = [
  { emoji: '🚆', fr: "Tu descends à Liège-Palais, une gare avant Guillemins, comme Élise l'a demandé.", en: 'You get off at Liège-Palais, one station before Guillemins, as Élise asked.' },
  { emoji: '📱', fr: '« Va à la Place du Marché. Je t\'appellerai. Ne parle à personne. »', en: '« Go to the Place du Marché. I will call you. Do not talk to anyone. »' },
  { emoji: '🌧️', fr: 'Liège dort sous la pluie. Mais les hommes en gris sont déjà en ville…', en: 'Liège sleeps in the rain. But the men in grey are already in town…' },
  { emoji: '🏍️', fr: 'Ce soir, {name}, il faudra être rapide. Très rapide.', en: 'Tonight, {name}, you will have to be fast. Very fast.' },
];

export const PEOPLE = {
  renard: {
    name: "Madame Renard, l'épicerie", avatar: '👩‍🦳', voice: { voice: 'vivienne', speed: 0.92 },
    pos: [-5.6, 14], face: Math.PI / 2,
    look: { skin: '#e8c3a2', hair: '#c9c9c9', coat: '#2f5a3a', coatLong: true, pants: '#22252c', glasses: true, height: 0.93 },
  },
  malik: {
    name: 'Malik, le livreur', avatar: '🛵', voice: { voice: 'gerard', speed: 1 },
    pos: [5.6, 12.6], face: -Math.PI / 2,
    look: { skin: '#a9774f', hair: '#140e0a', beard: '#140e0a', coat: '#b03a2e', pants: '#1d2028', hat: 'cap', hatColor: '#e8c33a' },
  },
  victor: {
    name: 'Victor, le libraire', avatar: '📚', voice: { voice: 'remy', speed: 0.92 },
    pos: [26, -34.8], face: 0,
    look: { skin: '#e2b896', hair: '#6a5a4a', beard: '#8a7a6a', coat: '#4a3a2c', scarf: '#2a4a6a', glasses: true, pants: '#2a2a2e', height: 1.02 },
  },
  elise: {
    name: 'Élise', avatar: '👩', voice: { voice: 'charline', speed: 0.98 },
    pos: [22, -34.6], face: 0,
    look: { skin: '#f0caa8', hair: '#3a2416', longHair: true, coat: '#a8231f', coatLong: true, pants: '#1a1a1d', height: 0.97 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const ELISE_PHONE = { name: 'Élise (au téléphone)', avatar: '📞', voice: { voice: 'charline', speed: 1 } };

const RENARD = [
  { fr: 'Bonsoir ! Vous cherchez quelque chose ? On ferme dans une heure.', en: 'Good evening! Are you looking for something? We close in an hour.' },
  {
    fr: '(Demande-lui le chemin de la Place du Marché.)', en: '(Ask her the way to the Place du Marché.)',
    hint: 'A stranger: use « vous ». « Excusez-moi… c\'est loin ? »',
    choices: [
      { fr: "Excusez-moi, la Place du Marché, c'est loin ?", en: 'Excuse me, is the Place du Marché far?', ok: true },
      { fr: 'Excuse-moi, tu connais la Place du Marché ?', en: 'Excuse me (informal), do you know the Place du Marché?' },
      { fr: 'La Place du Marché est plus loin que moi ?', en: 'Is the Place du Marché further than me?' },
    ],
  },
  { fr: "Non, c'est tout près ! Allez tout droit : c'est le premier carrefour.", en: "No, it's very close! Go straight on: it's the first crossroads." },
  { fr: 'Mais attention… Des hommes en gris sont passés tout à l\'heure. Ils reviendront, j\'en suis sûre.', en: 'But careful… Men in grey came by a while ago. They will come back, I am sure.' },
  {
    fr: '(Qu\'est-ce que les hommes en gris feront ?)', en: '(What will the men in grey do?)',
    hint: '« Ils reviendront » is the futur simple of « revenir ».',
    choices: [
      { fr: 'Ils reviendront.', en: 'They will come back.', ok: true },
      { fr: 'Ils sont revenus hier.', en: 'They came back yesterday.' },
      { fr: 'Ils ne viennent jamais.', en: 'They never come.' },
    ],
  },
  { fr: 'Tenez, prenez ce plan de la ville. Il est plus utile qu\'un téléphone, croyez-moi !', en: 'Here, take this town map. It is more useful than a phone, believe me!' },
  {
    fr: '(Le plan est comment, selon elle ?)', en: '(What is the map like, according to her?)',
    hint: '« plus utile que » = more useful than.',
    choices: [
      { fr: "Il est plus utile qu'un téléphone.", en: 'It is more useful than a phone.', ok: true },
      { fr: "Il est moins utile qu'un téléphone.", en: 'It is less useful than a phone.' },
      { fr: 'Il est aussi cher qu\'un téléphone.', en: 'It is as expensive as a phone.' },
    ],
  },
];

const MALIK_FIRST = [
  { fr: 'Salut ! Tu veux une pizza ? Moi, je vais finir dans dix minutes.', en: 'Hi! Do you want a pizza? Me, I am going to finish in ten minutes.' },
  {
    fr: '(Réponds-lui.)', en: '(Answer him.)',
    hint: 'Futur proche: aller + infinitive: « je vais attendre ».',
    choices: [
      { fr: 'Non merci. Je vais attendre un appel.', en: 'No thanks. I am going to wait for a call.', ok: true },
      { fr: 'Non merci. Je vais attendu un appel.', en: '(wrong verb form)' },
      { fr: 'Non merci. Je vais attendre un appel hier.', en: '(hier = yesterday: not the future!)' },
    ],
  },
  { fr: 'Un appel ? À cette heure-ci ? Bon… Si tu as besoin d\'aide, je serai là.', en: 'A call? At this time? OK… If you need help, I will be here.' },
];

const CALL = [
  { fr: "C'est moi, Élise. Écoute-moi bien : ils t'ont repéré !", en: "It's me, Élise. Listen to me carefully: they have spotted you!" },
  { fr: "Trouve un scooter. Je vais te guider jusqu'à moi. Fais exactement ce que je dis !", en: 'Find a scooter. I am going to guide you to me. Do exactly what I say!' },
  { who: YOU, fr: '(Un scooter… Malik, le livreur de pizzas !)', en: '(A scooter… Malik, the pizza delivery guy!)' },
];

const MALIK_SCOOTER = [
  {
    fr: '(Demande-lui son scooter.)', en: '(Ask him for his scooter.)',
    hint: 'The pronoun goes before the verb: « me prêter ».',
    choices: [
      { fr: "Malik, tu peux me prêter ton scooter ? C'est urgent !", en: "Malik, can you lend me your scooter? It's urgent!", ok: true },
      { fr: 'Malik, tu peux prêter moi ton scooter ?', en: '(wrong word order)' },
      { fr: "Malik, tu as prêté ton scooter hier ?", en: 'Malik, did you lend your scooter yesterday?' },
    ],
  },
  { fr: "Mon scooter ? Bon… Prends-le ! Mais ramène-le, d'accord ?", en: 'My scooter? OK… Take it! But bring it back, OK?' },
  {
    fr: '(Malik dit : « Prends-le ». « le », c\'est quoi ?)', en: '(Malik says: « Take it ». What is « it »?)',
    hint: '« le » replaces a masculine noun: le scooter.',
    choices: [
      { fr: 'le scooter', ok: true },
      { fr: 'la pizza' },
      { fr: 'les clés' },
    ],
  },
  { fr: 'Les clés sont dessus. Vas-y, vite ! Ils arrivent !', en: 'The keys are on it. Go, quick! They are coming!' },
];

// Élise's directions, from the scooter to the bookshop (the right street each time).
export const ROUTE = [
  { x: 2.5, z: 16 }, { x: 0, z: 0 }, { x: -30, z: 0 }, { x: -30, z: -30 }, { x: 0, z: -30 },
  { x: 0, z: 0 }, { x: 0, z: 30 }, { x: 30, z: 30 }, { x: 30, z: 0 }, { x: 30, z: -30 },
];
export const LEGS = [
  { fr: "Démarre ! Va tout droit jusqu'à la place !", en: 'Start! Go straight on to the square!' },
  { fr: 'Tourne à gauche !', en: 'Turn left!' },
  { fr: 'Prends la rue à droite !', en: 'Take the street on the right!' },
  { fr: 'À droite, encore !', en: 'Right, again!' },
  { fr: 'Tourne encore à droite, vite ! Ils sont derrière toi !', en: 'Turn right again, quick! They are behind you!' },
  { fr: "Continue tout droit ! Ne t'arrête pas !", en: "Keep going straight on! Don't stop!" },
  { fr: 'Tourne à gauche !', en: 'Turn left!' },
  { fr: 'Prends à gauche, maintenant !', en: 'Turn left, now!' },
  { fr: "Tout droit jusqu'au bout ! La librairie est là !", en: 'Straight on to the end! The bookshop is there!' },
];

const ENDING = [
  { who: PEOPLE.elise, fr: 'Tu es là ! Enfin ! Entre, vite !', en: 'You are here! At last! Come in, quick!' },
  { who: PEOPLE.victor, fr: 'Bienvenue au Phénix. Ici, personne ne vous trouvera.', en: 'Welcome to the Phoenix. Here, nobody will find you.' },
  { who: PEOPLE.elise, fr: 'Écoute. Lumen surveille toute la ville : les caméras, les téléphones… tout.', en: 'Listen. Lumen watches the whole city: the cameras, the phones… everything.' },
  {
    who: PEOPLE.elise, fr: 'Les preuves sont sur la clé USB. Tu l\'as toujours ?', en: 'The proof is on the USB key. Do you still have it?',
    hint: '« la clé USB » is feminine: « je l\'ai » (la + ai).',
    choices: [
      { fr: "Oui, je l'ai !", en: 'Yes, I have it!', ok: true },
      { fr: 'Oui, je lui ai !', en: '(lui is for people: wrong here)' },
      { fr: "Oui, j'ai la !", en: '(the pronoun goes before the verb)' },
    ],
  },
  { who: PEOPLE.victor, fr: 'Parfait. Demain, nous irons au laboratoire Lumen. Il nous faut le fichier principal.', en: 'Perfect. Tomorrow, we will go to the Lumen laboratory. We need the main file.' },
  {
    who: PEOPLE.elise, fr: 'Tu viendras avec nous ?', en: 'Will you come with us?',
    hint: 'venir in the futur simple: « je viendrai ».',
    choices: [
      { fr: 'Oui, je viendrai.', en: 'Yes, I will come.', ok: true },
      { fr: 'Oui, je venirai.', en: '(wrong future form)' },
      { fr: 'Oui, je suis venu hier.', en: 'Yes, I came yesterday.' },
    ],
  },
  { who: YOU, fr: '(Plus tard, dans la nuit… Victor parle au téléphone, à voix basse.)', en: '(Later, in the night… Victor is speaking on the phone, quietly.)' },
  { who: PEOPLE.victor, fr: 'Oui, monsieur Lenoir. Ils sont ici. Demain, au laboratoire… comme prévu.', en: 'Yes, Mr Lenoir. They are here. Tomorrow, at the laboratory… as planned.' },
  { who: YOU, fr: '(Victor… travaille pour Lumen ?)', en: '(Victor… works for Lumen?)' },
];

const SHORT = {
  renardAgain: { fr: 'La place, c\'est tout droit. Et faites attention à vous.', en: 'The square is straight on. And take care.' },
  malikAgain: { fr: 'Je finis bientôt. Bonne soirée !', en: 'I finish soon. Have a good evening!' },
  malikWait: { fr: "Hé ! Tu cherches quelque chose ? Regarde partout, alors. Moi, j'attends.", en: 'Hey! Looking for something? Look everywhere, then. I am waiting.' },
  malikDone: { fr: 'Mon scooter ! Merci de me l\'avoir ramené.', en: 'My scooter! Thanks for bringing it back to me.' },
  victorAgain: { fr: 'Reposez-vous. Demain sera une longue journée.', en: 'Rest. Tomorrow will be a long day.' },
};

export function objective(s) {
  if (!s.flags.renard) return 'Find the Place du Marché. Ask at the night shop (Épicerie de nuit).';
  if (!s.flags.called) return "Look for Élise's traces ({n}/{total}) and talk to Malik at Pizza Meuse.";
  if (!s.flags.chased) return 'Ask Malik for his scooter — fast!';
  if (!s.flags.done) return 'Talk to Élise and Victor in the bookshop.';
  return 'Chapter complete! Explore Liège.';
}

/** Élise and Victor are only in the bookshop after the chase. */
export function present(id, s) {
  if (id === 'elise' || id === 'victor') return !!s.flags.chased;
  return true;
}

export function hasNews(id, s) {
  if (id === 'renard') return !s.flags.renard;
  if (id === 'malik') return (s.flags.renard && !s.flags.malik) || (s.flags.called && !s.flags.chased);
  if (id === 'elise') return s.flags.chased && !s.flags.done;
  return false;
}

/** Élise calls once you have talked to everyone and found her traces. */
export async function afterClue(g) {
  const s = g.state;
  if (s.flags.called || !s.flags.renard || !s.flags.malik || s.found.length < CLUES.length) return false;
  g.ring();
  s.mistakes += await g.ui.talk(ELISE_PHONE, CALL);
  s.flags.called = true;
  g.save();
  return true;
}

export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'renard') {
    if (s.flags.renard) return g.ui.talk(P.renard, [SHORT.renardAgain]);
    s.mistakes += await g.ui.talk(P.renard, RENARD);
    s.flags.renard = true;
    g.save();
    await g.give('plan');
  } else if (id === 'malik') {
    if (s.flags.chased) return g.ui.talk(P.malik, [SHORT.malikDone]);
    if (s.flags.called) {
      s.mistakes += await g.ui.talk(P.malik, MALIK_SCOOTER);
      s.mistakes += await g.runChase(ROUTE, LEGS, Math.PI);
      s.flags.chased = true;
      g.save();
      await g.ui.talk(P.elise, ENDING.slice(0, 1));
      return interact('elise', g);
    }
    if (s.flags.malik) return g.ui.talk(P.malik, [SHORT.malikWait]);
    s.mistakes += await g.ui.talk(P.malik, MALIK_FIRST);
    s.flags.malik = true;
  } else if (id === 'elise' || id === 'victor') {
    if (!s.flags.chased) return;
    if (s.flags.done) return g.ui.talk(P.victor, [SHORT.victorAgain]);
    s.mistakes += await g.ui.talk(P.elise, ENDING.slice(1));
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
  await afterClue(g);
}

export function allTexts() {
  const out = [];
  for (const n of [RENARD, MALIK_FIRST, CALL, MALIK_SCOOTER, ENDING, STORY, LEGS, Object.values(SHORT)].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note, c.where);
  out.push(
    'Find the Place du Marché. Ask at the night shop (Épicerie de nuit).', "Look for Élise's traces ({n}/{total}) and talk to Malik at Pizza Meuse.",
    'Ask Malik for his scooter — fast!', 'Talk to Élise and Victor in the bookshop.', 'Chapter complete! Explore Liège.',
    'Chapter 3 complete!', 'A man in grey guards this clue. Get past him first.', 'Hint', 'Your phone is ringing…',
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
  talk(P.renard, [...RENARD, SHORT.renardAgain]);
  talk(P.malik, [...MALIK_FIRST, ...MALIK_SCOOTER, SHORT.malikAgain, SHORT.malikWait, SHORT.malikDone]);
  talk(ELISE_PHONE, [...CALL, ...LEGS]);
  talk(P.elise, ENDING);
  talk(P.victor, [SHORT.victorAgain]);
  STORY.forEach((st, i) => out.push([st.fr, { voice: i === 1 ? 'charline' : 'denise' }]));
  for (const c of CLUES) {
    out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
    out.push([c.noteFr, { voice: 'denise' }]);
  }
  out.push(["Ils t'ont rattrapé ! Recommence, vite !", ELISE_PHONE.voice], ['Non ! Pas par là ! Écoute bien.', ELISE_PHONE.voice]);
  return out;
}
