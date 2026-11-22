// Chapter 1 (A1): « Le Port de Lumière ».
// Greetings, je m'appelle, ça va, numbers, un/une, être, first nouns.
// Every line is written here: playing costs no AI call. English help texts
// are translated once for everyone through the app's shared translations.

export const WORDS = [
  { key: 'bateau', art: 'le', noun: 'bateau', g: 'm', en: 'the boat', emoji: '⛵', x: -23, z: 35 },
  { key: 'maison', art: 'la', noun: 'maison', g: 'f', en: 'the house', emoji: '🏠', x: -15.8, z: -5 },
  { key: 'arbre', art: "l'", noun: 'arbre', g: 'm', en: 'the tree', emoji: '🌳', x: -25.6, z: -0.6 },
  { key: 'fontaine', art: 'la', noun: 'fontaine', g: 'f', en: 'the fountain', emoji: '⛲', x: -10, z: 4.6 },
  { key: 'pain', art: 'le', noun: 'pain', g: 'm', en: 'the bread', emoji: '🥖', x: -6.8, z: 13.2 },
  { key: 'chat', art: 'le', noun: 'chat', g: 'm', en: 'the cat', emoji: '🐈', x: -8, z: -8.8 },
  { key: 'fleur', art: 'la', noun: 'fleur', g: 'f', en: 'the flower', emoji: '🌸', x: -21, z: 16.4 },
  { key: 'pont', art: 'le', noun: 'pont', g: 'm', en: 'the bridge', emoji: '🌉', x: 2.6, z: -0.8 },
];

export const STORY = [
  { emoji: '🏝️', fr: "Il était une fois une île pleine de couleurs : l'Île de Lumière.", en: 'Once upon a time, there was an island full of colours: the Island of Light.' },
  { emoji: '🧙‍♀️', fr: "Un jour, la sorcière Morgane a volé tous les mots de l'île.", en: 'One day, the witch Morgane stole all the words of the island.' },
  { emoji: '🌫️', fr: "Sans les mots, l'île a perdu ses couleurs. Tout est gris !", en: 'Without words, the island lost its colours. Everything is grey!' },
  { emoji: '⛵', fr: 'Toi, {name}, tu arrives en bateau. Retrouve les mots… et le trésor de Morgane !', en: "You, {name}, arrive by boat. Find the words… and Morgane's treasure!" },
];

export const PEOPLE = {
  hugo: {
    name: 'Capitaine Hugo', avatar: '🧔', voice: { voice: 'gerard', speed: 0.95, pitch: 0.75, rate: 0.9 },
    pos: [-21, 29.2], face: 0,
    look: { skin: '#e8b48a', shirt: '#24376b', pants: '#e9e2d0', hat: 'captain', beard: '#f2f2f2', hair: '#d9d9d9' },
  },
  lea: {
    name: 'Léa', avatar: '👩‍🍳', voice: { voice: 'charline', pitch: 1.25, rate: 0.95 },
    pos: [-4.8, 8.4], face: -Math.PI / 2,
    look: { skin: '#f5cfae', shirt: '#ff8fab', pants: '#6b4a8c', hat: 'chef', apron: '#ffffff', hair: '#7a4a2a' },
  },
  bruno: {
    name: 'Bruno, le garde', avatar: '💂', voice: { voice: 'henri', speed: 0.92, pitch: 0.6, rate: 0.85 },
    pos: [3.2, -2.2], face: -Math.PI / 2,
    look: { skin: '#c98d62', shirt: '#3d5fc4', pants: '#2b3550', hat: 'helmet', beard: '#5a3a22', scale: 1.15 },
  },
};

export const COCO = { name: 'Coco', avatar: '🦜', voice: { voice: 'eloise', speed: 1.1, pitch: 1.7, rate: 1.05 } };
export const CHEST = { name: 'Le coffre magique', avatar: '🧰', voice: { voice: 'denise', speed: 0.95, pitch: 0.9, rate: 0.85 } };
export const MORGANE = { name: 'Morgane', avatar: '🧙‍♀️', voice: { voice: 'vivienne', speed: 0.88, pitch: 0.55, rate: 0.82 } };

const HUGO_FIRST = [
  { fr: "Bonjour ! Bienvenue sur l'Île de Lumière !", en: 'Hello! Welcome to the Island of Light!' },
  {
    fr: "Je m'appelle Hugo. Je suis le capitaine. Et toi, comment tu t'appelles ?",
    en: 'My name is Hugo. I am the captain. And you, what is your name?',
    hint: 'He asks your name. Answer with « Je m\'appelle… ».',
    choices: [
      { fr: "Je m'appelle {name}.", en: 'My name is {name}.', ok: true },
      { fr: "J'ai faim.", en: 'I am hungry.' },
      { fr: 'Il fait beau.', en: 'The weather is nice.' },
    ],
  },
  {
    fr: 'Enchanté, {name} ! Ça va ?',
    en: 'Nice to meet you, {name}! How are you?',
    hint: '« Ça va ? » means "How are you?". Answer « Ça va bien, merci ! ».',
    choices: [
      { fr: 'Ça va bien, merci !', en: 'I am fine, thank you!', ok: true },
      { fr: 'Bonne nuit !', en: 'Good night!' },
      { fr: 'Je suis un bateau.', en: 'I am a boat.' },
    ],
  },
  { fr: "Écoute… La sorcière Morgane a volé les mots de l'île.", en: 'Listen… The witch Morgane stole the words of the island.' },
  { fr: 'Regarde : sans les mots, tout est gris !', en: 'Look: without the words, everything is grey!' },
  { fr: "Trouve les cristaux bleus. Chaque cristal te donne un mot, et l'île retrouve ses couleurs !", en: 'Find the blue crystals. Each crystal gives you a word, and the island gets its colours back!' },
  { fr: "Voici dix pièces d'or pour ton voyage.", en: 'Here are ten gold coins for your journey.' },
  { who: COCO, fr: 'Coco ! Coco ! Je suis Coco, le perroquet ! Je vais t\'aider !', en: 'Coco! Coco! I am Coco the parrot! I will help you!' },
  { fr: 'Attention ! Les ombres de Morgane gardent les cristaux.', en: "Careful! Morgane's shadows guard the crystals." },
  { fr: 'Prends cette baguette magique : la Baguette des Mots !', en: 'Take this magic wand: the Wand of Words!' },
  { fr: 'Les ombres bleues ont peur des mots. Dis le bon mot en français, et pouf !', en: 'Blue shadows are afraid of words. Say the right word in French, and poof!' },
  { who: COCO, fr: 'Coco ! Si tu dis le mot à voix haute, le sort est deux fois plus fort !', en: 'Coco! If you say the word out loud, the spell is twice as strong!' },
  { fr: 'Va voir Léa à la boulangerie. Bonne chance, {name} !', en: 'Go and see Léa at the bakery. Good luck, {name}!' },
];

const LEA = [
  { fr: "Bonjour ! Bienvenue à la boulangerie ! Je m'appelle Léa.", en: 'Hello! Welcome to the bakery! My name is Léa.' },
  {
    fr: 'Et toi ? Tu dis quoi ?',
    en: 'And you? What do you say?',
    hint: 'It is daytime and you are arriving: say « Bonjour ».',
    choices: [
      { fr: 'Bonjour, madame !', en: 'Hello, madam!', ok: true },
      { fr: 'Bonne nuit, madame !', en: 'Good night, madam!' },
      { fr: 'Au revoir, madame !', en: 'Goodbye, madam!' },
    ],
  },
  { fr: 'Tu cherches le trésor ? Le garde Bruno bloque le pont… mais il adore les croissants !', en: 'Are you looking for the treasure? Bruno the guard is blocking the bridge… but he loves croissants!' },
  {
    fr: 'Bruno veut quatre croissants.',
    en: 'Bruno wants four croissants.',
    listen: true,
    hint: 'Listen again (🔊). « quatre » = 4.',
    choices: [
      { fr: '4 🥐', ok: true },
      { fr: '2 🥐' },
      { fr: '7 🥐' },
    ],
  },
  {
    fr: 'Voilà quatre croissants ! Ça fait six euros.',
    en: 'Here are four croissants! That is six euros.',
    listen: true,
    hint: 'Listen again (🔊). « six » = 6.',
    choices: [
      { fr: '6 €', ok: true },
      { fr: '10 €' },
      { fr: '3 €' },
    ],
  },
  {
    fr: 'Tu as six euros ?',
    en: 'Do you have six euros?',
    hint: 'To pay, say « Oui, voilà… » (Yes, here is…).',
    choices: [
      { fr: 'Oui, voilà six euros.', en: 'Yes, here are six euros.', ok: true },
      { fr: 'Non, je suis un chat.', en: 'No, I am a cat.' },
      { fr: "Oui, j'ai dix ans.", en: 'Yes, I am ten years old.' },
    ],
  },
  {
    fr: 'Merci ! Bonne journée !',
    en: 'Thank you! Have a nice day!',
    hint: 'You are leaving: say « au revoir ».',
    choices: [
      { fr: 'Merci, au revoir !', en: 'Thank you, goodbye!', ok: true },
      { fr: 'Bonjour !', en: 'Hello!' },
      { fr: 'Bonne nuit !', en: 'Good night!' },
    ],
  },
  { fr: 'Attends ! Un cadeau pour toi : la Baguette des Nombres !', en: 'Wait! A present for you: the Wand of Numbers!' },
  { fr: 'Les ombres dorées ont peur des nombres. Écoute bien, et choisis le bon nombre !', en: 'Golden shadows are afraid of numbers. Listen carefully and choose the right number!' },
];

const BRUNO_HUNGRY = [
  { fr: 'Halte ! Le pont est fermé !', en: 'Stop! The bridge is closed!' },
  { fr: "J'ai faim… Sans croissants, je ne travaille pas !", en: 'I am hungry… Without croissants, I do not work!' },
  { who: COCO, fr: 'Coco ! La boulangerie ! La boulangerie !', en: 'Coco! The bakery! The bakery!' },
];

const BRUNO_RIDDLE = [
  { fr: 'Halte ! … Oh ! Ce sont des croissants ?', en: 'Stop! … Oh! Are those croissants?',
    hint: 'Give him the croissants: « Oui, c\'est pour toi ! ».',
    choices: [
      { fr: "Oui, c'est pour toi !", en: 'Yes, it is for you!', ok: true },
      { fr: "Non, c'est un bateau.", en: 'No, it is a boat.' },
      { fr: 'Je ne sais pas.', en: 'I do not know.' },
    ] },
  { fr: 'Merci ! Miam ! Maintenant, écoute ma devinette.', en: 'Thank you! Yum! Now, listen to my riddle.' },
  {
    fr: 'Je suis grand et vert. Les oiseaux habitent dans mes branches. Qui suis-je ?',
    en: 'I am big and green. Birds live in my branches. Who am I?',
    hint: 'Big, green, branches, birds… Look for the big tree in the west of the village!',
    choices: [
      { fr: "l'arbre", en: 'the tree', ok: true },
      { fr: 'la fontaine', en: 'the fountain' },
      { fr: 'le chat', en: 'the cat' },
    ],
  },
  { fr: 'Bravo ! Le pont est ouvert. Le coffre est sous le vieil arbre, de l\'autre côté.', en: 'Well done! The bridge is open. The chest is under the old tree, on the other side.' },
  { fr: "Mais attention : les ombres violettes sont là-bas. Prends ma Baguette d'Être !", en: 'But careful: the purple shadows are over there. Take my Wand of Être!' },
  { fr: 'Je suis, tu es, il est… Avec les bons verbes, tu es le plus fort !', en: 'I am, you are, he is… With the right verbs, you are the strongest!' },
];

const MORGANE_TALK = [
  { fr: 'Ha ha ha ! Bravo, petit explorateur…', en: 'Ha ha ha! Well done, little explorer…' },
  { fr: "Mais ce n'est qu'un morceau de la carte !", en: 'But it is only one piece of the map!' },
  { fr: 'Le trésor est caché très loin… dans la Forêt des Verbes !', en: 'The treasure is hidden very far away… in the Forest of Verbs!' },
  { fr: 'On se reverra, {name} !', en: 'We will meet again, {name}!' },
];

/** The current goal, in English (translated for the learner). */
export function objective(s) {
  const n = s.found.length;
  if (!s.flags.hugo) return 'Talk to Captain Hugo on the dock.';
  if (!s.flags.croissants) return 'Beat the blue shadows, find the word crystals ({n}/{total}) and visit Léa at the bakery.';
  if (!s.flags.bridge) return 'Bring the croissants to Bruno, the guard of the bridge.';
  if (n < WORDS.length) return 'Find all the word crystals ({n}/{total}), then open the chest across the bridge.';
  if (!s.flags.chest) return "Defeat Morgane's Guardian at the treasure chest, across the bridge.";
  return 'Chapter complete! Explore the island.';
}

/** Who has something new to say (gets a "!" above their head). */
export function hasNews(id, s) {
  if (id === 'hugo') return !s.flags.hugo;
  if (id === 'lea') return !s.flags.croissants;
  if (id === 'bruno') return s.flags.croissants && !s.flags.bridge;
  if (id === 'chest') return s.flags.bridge && !s.flags.chest;
  return false;
}

/** Talking to someone. g = { ui, world, state, save, finish, showWitch }. */
export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'hugo') {
    if (s.flags.hugo) return g.ui.talk(P.hugo, [{ fr: 'Bonne chance, {name} ! Les cristaux brillent partout sur l\'île.', en: 'Good luck, {name}! The crystals shine all over the island.' }]);
    s.mistakes += await g.ui.talk(P.hugo, HUGO_FIRST);
    s.flags.hugo = true;
    g.giveWand('mots');
    s.coins += 10;
    g.coinSound();
    g.showParrot();
  } else if (id === 'lea') {
    if (s.flags.croissants) return g.ui.talk(P.lea, [{ fr: 'Bonne chance avec Bruno !', en: 'Good luck with Bruno!' }]);
    s.mistakes += await g.ui.talk(P.lea, LEA);
    s.flags.croissants = true;
    g.giveWand('nombres');
    s.coins = Math.max(0, s.coins - 6);
    g.ui.toast('🥐 You got four croissants for Bruno!');
  } else if (id === 'bruno') {
    if (s.flags.bridge) return g.ui.talk(P.bruno, [{ fr: 'Le coffre est sous le vieil arbre. Allez, vas-y !', en: 'The chest is under the old tree. Go on!' }]);
    if (!s.flags.croissants) return g.ui.talk(P.bruno, BRUNO_HUNGRY);
    s.mistakes += await g.ui.talk(P.bruno, BRUNO_RIDDLE);
    s.flags.bridge = true;
    g.world.openBridge();
    g.giveWand('etre');
    s.coins += 5;
    g.coinSound();
  } else if (id === 'chest') {
    if (s.flags.chest) return g.ui.talk(CHEST, [{ fr: 'Le coffre est vide… La suite est dans la Forêt des Verbes !', en: 'The chest is empty… The story continues in the Forest of Verbs!' }]);
    if (s.found.length < WORDS.length) {
      return g.ui.talk(CHEST, [
        { fr: 'Le coffre est fermé. Il veut tous les mots de l\'île !', en: 'The chest is locked. It wants all the words of the island! ({n}/{total})' },
        { who: COCO, fr: 'Coco ! Les cristaux bleus ! Cherche partout !', en: 'Coco! The blue crystals! Look everywhere!' },
      ]);
    }
    await g.ui.talk(CHEST, [
      { fr: 'Le coffre tremble… Une ombre géante sort de la terre !', en: 'The chest is shaking… A giant shadow rises from the ground!' },
      { who: MORGANE, fr: 'Mon Gardien va te manger, petit explorateur ! Ha ha ha !', en: 'My Guardian will eat you, little explorer! Ha ha ha!' },
      { who: COCO, fr: 'Coco ! Trois boucliers : bleu, doré, violet ! Change de baguette !', en: 'Coco! Three shields: blue, gold, purple! Switch wands!' },
    ]);
    if (!(await g.fightBoss())) return;
    s.mistakes += await g.finalSpell(['Je', 'suis', 'un', 'explorateur', 'courageux', '!']);
    s.flags.chest = true;
    s.coins += 20;
    g.save();
    await g.openChest();
    await g.showWitch(async () => { await g.ui.talk(MORGANE, MORGANE_TALK); });
    g.finish();
  }
  g.save();
}

/** Every English text, to translate in one go at the start. */
export function allTexts() {
  const out = [];
  const nodes = [HUGO_FIRST, LEA, BRUNO_HUNGRY, BRUNO_RIDDLE, MORGANE_TALK, STORY].flat();
  for (const n of nodes) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const w of WORDS) out.push(w.en);
  out.push(
    'Find the blue word crystals ({n}/{total}) and visit Léa at the bakery.',
    'Find all the word crystals ({n}/{total}), then open the chest across the bridge.',
    'The chest is locked. It wants all the words of the island! ({n}/{total})',
    'Talk to Captain Hugo on the dock.', 'Bring the croissants to Bruno, the guard of the bridge.',
    'Open the treasure chest under the old tree, across the bridge.', 'Chapter complete! Explore the island.',
    '🥐 You got four croissants for Bruno!', 'Listen and choose', 'Speak now…', 'I did not hear you. Try again.',
    'Not quite. Try again!', 'Listen again (🔊) and choose the word you hear.', '« le chat » is masculine, so: un chat.',
    'être: je suis, tu es, il est.', 'Three locks are shining on the chest…', 'Second lock: on the crate, there is ___ cat.',
    'Third lock: I ___ an explorer.', 'Good luck, {name}! The crystals shine all over the island.', 'Good luck with Bruno!',
    'The chest is under the old tree. Go on!', 'A piece of the treasure map!', 'Words found', 'Mistakes',
    'An adventure to learn French', 'Your name', 'Play', 'Continue', 'New game', 'Back to the app', 'My words', 'Close',
    'All the words are found! Open the chest across the bridge.',
    'All the words are found! Now cross the bridge to the chest.',
    'Beat the blue shadows, find the word crystals ({n}/{total}) and visit Léa at the bakery.',
    "Defeat Morgane's Guardian at the treasure chest, across the bridge.",
    'The chest is shaking… A giant shadow rises from the ground!', 'My Guardian will eat you, little explorer! Ha ha ha!',
    'Coco! Three shields: blue, gold, purple! Switch wands!', 'A shadow guards this crystal! Beat it first.',
    'This shadow is asleep. Captain Hugo has a wand for you.', 'This golden shadow is asleep. Léa at the bakery has the Wand of Numbers.',
    'This purple shadow is asleep. Bruno has the Wand of Être.', '⛲ The fountain heals you!',
    'You fell… The fountain gives you your strength back.', 'New wand!', 'Help language',
    'Chapter 1 complete!', 'Coming soon', 'Explore the island', 'Coco! The blue crystals! Look everywhere!',
  );
  return out.filter(Boolean);
}
