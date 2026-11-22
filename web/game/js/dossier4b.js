// Le Dossier Bruxelles — B1, stage 2 : « La Gazette, la nuit ».
// One in the morning, at Élise's newspaper: convince the editor, find more proof,
// and face a police commissioner paid by Lumen.
// B1 grammar: the plus-que-parfait, the passive voice (être + participle),
// the gérondif (en + -ant), giving an opinion and linking ideas (pourtant, parce que).
// Sneaking: Lumen's men search the newsroom with torches.

export const CHAPTER = {
  id: '4b',
  title: 'La Gazette, la nuit',
  level: 'B1',
  world: 'office',
  layout: 'gazette',
  detect: 'cone',
  saveKey: 'dossier_save_4b',
  spawn: [0, 18.4, Math.PI],
  respawn: [0, 18, Math.PI],
  lights: [[0, 2.6, 16, '#d6e4ff'], [-9, 2.6, 3, '#ffe2b8'], [9, 2.6, 3, '#ffe2b8'], [-12, 2.6, -12, '#c9b48a'], [0, 2.6, -12, '#ff6b6b'], [12, 2.6, -10, '#ffe2b8']],
  places: [{ id: 'accueil', x: 0, z: 14.6, y: 2.4, symbol: '?' }],
  locks: [
    { rect: [-2.1, 2.1, 11.1, 12.9], flag: 'bernard', say: 'The night guard is watching the door. Talk to him first.' },
    { rect: [-1.5, 1.5, -4.9, -3.1], flag: 'paul', say: 'The photo lab is closed. The editor must agree first.' },
    { rect: [-13.5, -10.5, -4.9, -3.1], flag: 'paul', say: 'The archives are closed. The editor must agree first.' },
  ],
  agents: [
    { id: 'redac1', path: [[-15, -1.8], [-3, -1.8]], guards: 'micro' },
    { id: 'redac2', path: [[3, 3.4], [15, 3.4]], guards: 'mail' },
    {
      id: 'roche', path: [[2.6, 15.8]], chief: true, after: 'paul2',
      look: { skin: '#e2b08c', hair: '#3a3a3a', coat: '#2a2d33', coatLong: true, pants: '#1a1d23', shirt: '#e8e2d4', hat: 'fedora', hatColor: '#1a1a1d', build: 1.15 },
    },
  ],
  next: 'La Vérité',
  doneIcon: '📰',
};

export const LINES = {
  agentName: 'Un homme de Lumen', chiefName: 'Le commissaire Roche',
  agentVoice: { voice: 'henri', speed: 0.95 }, chiefVoice: { voice: 'remy', speed: 0.9 },
  agentIntro: 'Qui êtes-vous ? Personne ne doit être ici cette nuit.', chiefIntro: 'Police. Vous êtes en possession de documents volés.',
  release: 'Bon… Je ne vous ai pas vu.', storyAsk: 'Expliquez-moi ce que vous faites ici. En détail.',
  caught: 'They throw you out into the street… Bernard lets you back in.',
};

export const BANKS = [
  { kind: 'phrase', icon: '⏮️', help: 'The plus-que-parfait: avoir / être in the imparfait + past participle (what had happened before).', items: [
    ["Quand la police est arrivée, qu'est-ce qui s'était passé ?", 'Les voleurs étaient déjà partis.', ['Les voleurs avaient déjà partis.', 'Les voleurs sont déjà partaient.'], 'When the police arrived, what had happened?'],
    ['Vous aviez déjà vu cet homme ?', "Oui, je l'avais déjà vu à Liège.", ["Oui, je l'étais déjà vu à Liège.", "Oui, je l'avais déjà voir à Liège."], 'Had you already seen this man?'],
    ['Pourquoi Élise avait peur ?', "Parce qu'elle avait découvert un secret.", ["Parce qu'elle était découvert un secret.", "Parce qu'elle avait découvrir un secret."], 'Why was Élise afraid?'],
    ["Le directeur avait lu l'article ?", "Non, il ne l'avait pas lu.", ["Non, il ne l'avait lu pas.", "Non, il n'avait pas le lu."], 'Had the director read the article?'],
    ["Qu'est-ce que vous aviez fait avant minuit ?", "J'avais dîné avec une amie.", ["J'étais dîné avec une amie.", "J'avais dîner avec une amie."], 'What had you done before midnight?'],
  ] },
  { kind: 'phrase', icon: '🔁', help: 'The passive (être + participle, which agrees) and the gérondif (en + -ant).', items: [
    ['Qui a écrit cet article ?', 'Il a été écrit par Élise.', ['Il a écrit par Élise.', 'Il a été écrite par Élise.'], 'Who wrote this article?'],
    ['Les documents ont été volés ?', 'Oui, ils ont été volés hier.', ['Oui, ils ont volés hier.', 'Oui, ils sont été volés hier.'], 'Were the documents stolen?'],
    ['Comment avez-vous trouvé le micro ?', 'En cherchant sous le bureau.', ['En chercher sous le bureau.', 'En cherché sous le bureau.'], 'How did you find the microphone?'],
    ['Comment avez-vous appris la nouvelle ?', 'En lisant le journal.', ['En lire le journal.', 'En lisé le journal.'], 'How did you hear the news?'],
    ['La porte est fermée ?', 'Oui, elle est fermée à clé par le gardien.', ['Oui, elle est fermé à clé par le gardien.', 'Oui, elle a fermée à clé par le gardien.'], 'Is the door closed?'],
  ] },
  { kind: 'phrase', icon: '💬', help: 'Give your opinion and link your ideas: je crois que, à mon avis, pourtant, parce que.', items: [
    ['Vous croyez Élise ?', "Oui, je crois qu'elle dit la vérité.", ["Oui, je crois qu'elle dise la vérité.", 'Oui, je crois que elle dit la vérité.'], 'Do you believe Élise?'],
    ['Lumen est dangereux ?', "À mon avis, oui. Pourtant, personne n'en parle.", ['À mon avis, oui. Pourtant, personne en parle.', 'À mon avis, oui. Donc pourtant, personne parle.'], 'Is Lumen dangerous?'],
    ['Pourquoi êtes-vous ici ?', 'Je suis ici parce que je veux aider Élise.', ['Je suis ici car de je veux aider Élise.', 'Je suis ici à cause je veux aider Élise.'], 'Why are you here?'],
    ['Vous avez des preuves ?', "Oui, j'en ai plusieurs.", ["Oui, j'y ai plusieurs.", 'Oui, je les ai plusieurs.'], 'Do you have proof?'],
    ['Vous pensez que Lenoir est coupable ?', "Oui, je pense qu'il ment depuis le début.", ["Oui, je pense qu'il mente depuis le début.", 'Oui, je pense de il ment depuis le début.'], 'Do you think Lenoir is guilty?'],
  ] },
];

export const CLUES = [
  { key: 'article', where: "On Élise's desk, in the newsroom (west side).", art: "l'", noun: "article d'Élise", g: 'm', en: "Élise's article", emoji: '📝', x: -9, z: 2.3,
    noteFr: "L'article d'Élise, pas terminé : « Lumen écoute toute la ville. » La dernière phrase s'arrête au milieu.",
    note: "Élise's unfinished article: « Lumen listens to the whole city. » The last sentence stops halfway." },
  { key: 'micro', where: "Next to Élise's desk. A man with a torch is searching the newsroom.", art: 'le', noun: 'micro caché', g: 'm', en: 'the hidden microphone', emoji: '🎙️', x: -7.2, z: -0.8,
    noteFr: "Un micro caché sous le bureau d'Élise. La rédaction était écoutée par Lumen !",
    note: "A microphone hidden under Élise's desk. The newsroom was being listened to by Lumen!" },
  { key: 'mail', where: 'On a desk on the east side of the newsroom. A man with a torch walks there.', art: 'le', noun: 'courriel imprimé', g: 'm', en: 'the printed e-mail', emoji: '📧', x: 9, z: 2.3,
    noteFr: "Un courriel de Lenoir à Paul Mercier : « Si l'article d'Élise est publié, vous le regretterez. »",
    note: "An e-mail from Lenoir to Paul Mercier: « If Élise's article is published, you will regret it. »" },
  { key: 'dossier', where: 'In the archives, between the shelves.', art: 'le', noun: 'dossier 2019', g: 'm', en: 'the 2019 file', emoji: '🗂️', x: -11.5, z: -13,
    noteFr: "Le dossier 2019 : Victor Delcourt avait écrit que Lumen espionnait ses clients. L'article avait été supprimé.",
    note: 'The 2019 file: Victor Delcourt had written that Lumen was spying on its clients. The article had been deleted.' },
  { key: 'photo', where: 'At the very back of the archives.', art: 'la', noun: 'photo de 2019', g: 'f', en: 'the 2019 photo', emoji: '🖼️', x: -16.5, z: -18.5,
    noteFr: 'Une photo de 2019 : Lenoir et le commissaire Roche, au restaurant. Ils ont l\'air de bons amis.',
    note: 'A photo from 2019: Lenoir and Commissioner Roche, at a restaurant. They look like good friends.' },
  { key: 'tirages', given: true, where: 'Nina prints them for you, in the photo lab.', art: 'les', noun: 'tirages', g: 'm', en: 'the prints', emoji: '🖨️',
    noteFr: 'Les photos des documents de Lumen, imprimées en grand. Les signatures de Lenoir sont parfaitement lisibles.',
    note: "The photos of Lumen's documents, printed big. Lenoir's signatures are perfectly readable." },
  { key: 'accreditation', given: true, where: 'Paul Mercier gives it to you, in his office.', art: "l'", noun: 'accréditation de presse', g: 'f', en: 'the press pass', emoji: '🪪',
    noteFr: "Une accréditation de presse pour Télé Bruxelles, au nom de la Gazette. Elle ouvre toutes les portes du studio.",
    note: 'A press pass for Télé Bruxelles, in the name of the Gazette. It opens every door of the studio.' },
  { key: 'carnet', given: true, where: 'The commissioner drops it, at the reception.', art: 'le', noun: 'carnet du commissaire', g: 'm', en: "the commissioner's notebook", emoji: '📓',
    noteFr: '« Élise M. — Télé Bruxelles, réserve. Six heures : Lenoir en direct. » Élise est enfermée au studio !',
    note: '« Élise M. — Télé Bruxelles, storage room. Six o\'clock: Lenoir live. » Élise is locked up at the studio!' },
];

export const STORY = [
  { emoji: '🌧️', fr: 'Une heure du matin. Lumen a la clé USB… et Élise.', en: 'One in the morning. Lumen has the USB key… and Élise.' },
  { emoji: '📸', fr: 'Mais dans ton téléphone, il y a les photos de tous les documents.', en: 'But in your phone, there are the photos of all the documents.' },
  { emoji: '📰', fr: "Il faut un journal pour les publier. Le journal d'Élise : la Gazette.", en: "You need a newspaper to publish them. Élise's newspaper: the Gazette." },
  { emoji: '🕵️', fr: 'Va à la rédaction, {name}. Mais attention : Lumen a des amis partout… même dans la police.', en: 'Go to the newsroom, {name}. But careful: Lumen has friends everywhere… even in the police.' },
];

export const PEOPLE = {
  bernard: {
    name: 'Bernard, le gardien de nuit', avatar: '💂', voice: { voice: 'gerard', speed: 0.92 },
    pos: [-6, 15.2], face: Math.PI / 2,
    look: { skin: '#b98a6a', hair: '#9a9a9a', coat: '#1f2a44', shirt: '#e8e2d4', pants: '#1a1d26', hat: 'cap', hatColor: '#1f2a44', build: 1.15 },
  },
  paul: {
    name: 'Paul Mercier, rédacteur en chef', avatar: '🧔', voice: { voice: 'henri', speed: 0.92 },
    pos: [11.6, -7], face: 0,
    look: { skin: '#e2b08c', hair: '#5a4632', beard: '#5a4632', coat: '#4a3a2c', shirt: '#e8e2d4', pants: '#22252c', glasses: true },
  },
  jules: {
    name: "Jules, l'archiviste", avatar: '👴', voice: { voice: 'remy', speed: 0.9 },
    pos: [-12, -7], face: 0,
    look: { skin: '#f0d0b8', hair: '#e8e2d4', coat: '#5a5a4a', pants: '#2a2a2a', glasses: true, scarf: '#7a2a2a', height: 0.94 },
  },
  nina: {
    name: 'Nina, la photographe', avatar: '👩‍🎤', voice: { voice: 'eloise', speed: 1 },
    pos: [0, -7.2], face: 0,
    look: { skin: '#6b4430', hair: '#141010', coat: '#3a2a4a', pants: '#1a1a1d', bag: '#2a2a2a', height: 0.96 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const CHIEF = { name: 'Le commissaire Roche', avatar: '👮', voice: { voice: 'remy', speed: 0.88 } };

const BERNARD = [
  { fr: "Halte ! La rédaction est fermée la nuit. Qu'est-ce que vous voulez ?", en: 'Stop! The newsroom is closed at night. What do you want?' },
  {
    fr: "(Explique que tu travailles avec Élise et que c'est urgent.)", en: '(Explain that you work with Élise and that it is urgent.)',
    hint: 'Present tense for now: « je travaille », « c\'est ».',
    choices: [
      { fr: "Je travaille avec Élise Moreau. C'est très urgent.", en: 'I work with Élise Moreau. It is very urgent.', ok: true },
      { fr: "Je travaille avec Élise Moreau. C'était très urgent demain.", en: '(the tenses do not match)' },
      { fr: 'Je travaillais avec Élise Moreau depuis demain.', en: '(this means nothing)' },
    ],
  },
  { fr: "Élise ? Ça fait deux jours qu'elle n'est pas venue. Je m'inquiétais pour elle.", en: 'Élise? She has not come for two days. I was worried about her.' },
  {
    fr: "(Dis-lui qu'elle a été enlevée par les gens de Lumen.)", en: '(Tell him she was kidnapped by the Lumen people.)',
    hint: 'The passive: a été + past participle. « Elle » → enlevée (+e).',
    choices: [
      { fr: 'Elle a été enlevée par les gens de Lumen.', en: 'She was kidnapped by the Lumen people.', ok: true },
      { fr: 'Elle a été enlevé par les gens de Lumen.', en: '(the participle must agree: enlevée)' },
      { fr: 'Elle a enlevée par les gens de Lumen.', en: '(« été » is missing)' },
    ],
  },
  { fr: "Ce n'est pas possible… Montez vite. Le rédacteur en chef, Paul Mercier, est encore dans son bureau.", en: 'It is not possible… Go up quickly. The editor-in-chief, Paul Mercier, is still in his office.' },
  { fr: "Mais faites attention : deux types sont entrés tout à l'heure. Ils avaient un badge « maintenance »… Je ne les crois pas.", en: 'But be careful: two guys came in earlier. They had a « maintenance » badge… I do not believe them.' },
];

const PAUL = [
  { fr: 'Qui êtes-vous ? Qui vous a laissé entrer ?', en: 'Who are you? Who let you in?' },
  {
    fr: '(Explique que tu as des photos des documents secrets de Lumen.)', en: "(Explain that you have photos of Lumen's secret documents.)",
    hint: 'de + les = des.',
    choices: [
      { fr: "J'ai des photos des documents secrets de Lumen.", en: "I have photos of Lumen's secret documents.", ok: true },
      { fr: "J'ai des photos de les documents secrets de Lumen.", en: '(de + les must become des)' },
      { fr: "J'en ai des photos des documents secrets de Lumen.", en: '(« en » is not needed here)' },
    ],
  },
  { fr: "Lumen… Écoutez. Il y a un mois, Élise m'avait déjà apporté une histoire sur Lumen. J'avais refusé de la publier.", en: 'Lumen… Listen. A month ago, Élise had already brought me a story about Lumen. I had refused to publish it.' },
  {
    fr: "(Demande-lui pourquoi il avait refusé.)", en: '(Ask him why he had refused.)',
    hint: 'Plus-que-parfait: avoir in the imparfait (aviez) + refusé.',
    choices: [
      { fr: 'Pourquoi est-ce que vous aviez refusé ?', en: 'Why had you refused?', ok: true },
      { fr: 'Pourquoi est-ce que vous étiez refusé ?', en: '(wrong helper verb)' },
      { fr: 'Pourquoi est-ce que vous aviez refuser ?', en: '(infinitive instead of past participle)' },
    ],
  },
  { fr: "Parce qu'on m'avait menacé. Et je n'avais pas de preuves. Des photos, ça ne suffit pas : on dira qu'elles sont fausses.", en: 'Because I had been threatened. And I had no proof. Photos are not enough: they will say they are fake.' },
  { fr: "Trouvez-moi d'autres preuves. Le bureau d'Élise est dans la salle de rédaction. Et Jules, aux archives, sait beaucoup de choses sur Lenoir.", en: "Find me more proof. Élise's desk is in the newsroom. And Jules, in the archives, knows a lot about Lenoir." },
];

const JULES = [
  { fr: "Ah, du monde à cette heure-ci ! Je classais de vieux journaux. Je ne dors jamais beaucoup.", en: 'Ah, visitors at this time of night! I was sorting old newspapers. I never sleep much.' },
  {
    fr: "(Demande-lui ce qu'il sait sur Lenoir.)", en: '(Ask him what he knows about Lenoir.)',
    hint: '« Qu\'est-ce que » + subject + verb.',
    choices: [
      { fr: "Qu'est-ce que vous savez sur Lenoir ?", en: 'What do you know about Lenoir?', ok: true },
      { fr: "Qu'est-ce qui vous savez sur Lenoir ?", en: '(« qui » is for the subject)' },
      { fr: 'Que est-ce que vous savez sur Lenoir ?', en: '(que + est → qu\'est)' },
    ],
  },
  { fr: "En 2019, un journaliste avait écrit que Lumen espionnait ses clients. Trois semaines plus tard, l'article avait disparu.", en: 'In 2019, a journalist had written that Lumen was spying on its clients. Three weeks later, the article had disappeared.' },
  { fr: 'Et le journaliste avait quitté le métier. Il s\'appelait… Victor. Victor Delcourt.', en: 'And the journalist had left the job. His name was… Victor. Victor Delcourt.' },
  {
    fr: "(Demande-lui s'il a gardé une copie de l'article.)", en: '(Ask him if he kept a copy of the article.)',
    hint: 'garder → avoir + gardé.',
    choices: [
      { fr: "Est-ce que vous avez gardé une copie de l'article ?", en: 'Did you keep a copy of the article?', ok: true },
      { fr: "Est-ce que vous êtes gardé une copie de l'article ?", en: '(wrong helper verb)' },
      { fr: "Est-ce que vous avez garder une copie de l'article ?", en: '(infinitive instead of past participle)' },
    ],
  },
  { fr: 'Bien sûr. Tout est dans le dossier 2019, au milieu des archives. Et cherchez bien au fond : il y a une photo intéressante.', en: 'Of course. Everything is in the 2019 file, in the middle of the archives. And look carefully at the back: there is an interesting photo.' },
];

const NINA = [
  {
    fr: "Salut ! Paul m'a appelée. C'est toi qui as les photos ?", en: 'Hi! Paul called me. Are you the one with the photos?',
    hint: '« les photos » is feminine plural: elles.',
    choices: [
      { fr: "Oui, c'est moi. Elles sont dans mon téléphone.", en: 'Yes, it is me. They are in my phone.', ok: true },
      { fr: "Oui, c'est moi. Ils sont dans mon téléphone.", en: '(photos are feminine: elles)' },
      { fr: "Oui, c'est moi qui ai. Elles sont dans mon téléphone.", en: '(something is missing after « qui ai »)' },
    ],
  },
  { fr: 'Super. Je vais les imprimer en grand. En les agrandissant, on verra tous les détails.', en: 'Great. I will print them big. By enlarging them, we will see every detail.' },
  {
    fr: '(Demande-lui combien de temps il faut.)', en: '(Ask her how much time it takes.)',
    hint: '« combien de » + noun, without an article.',
    choices: [
      { fr: 'Il faut combien de temps ?', en: 'How much time does it take?', ok: true },
      { fr: 'Il faut combien du temps ?', en: '(no article after « combien de »)' },
      { fr: 'Ça faut combien de temps ?', en: '(« falloir » only works with « il »)' },
    ],
  },
  { fr: 'Dix minutes… Voilà ! Regarde : les signatures de Lenoir sont parfaitement lisibles.', en: "Ten minutes… There! Look: Lenoir's signatures are perfectly readable." },
  { fr: 'Va montrer ça à Paul. Cette fois, il ne pourra pas dire non.', en: 'Go and show this to Paul. This time, he will not be able to say no.' },
];

const PAUL_AGAIN = [
  { fr: '(Il regarde les photos longtemps, en silence.)', en: '(He looks at the photos for a long time, in silence.)' },
  { fr: 'Le micro, le dossier de 2019, ces signatures… Vous aviez raison. Élise avait raison.', en: 'The microphone, the 2019 file, these signatures… You were right. Élise was right.' },
  {
    fr: "(Demande-lui s'il va publier l'article.)", en: '(Ask him if he is going to publish the article.)',
    hint: 'aller + infinitive: « vous allez publier ».',
    choices: [
      { fr: "Est-ce que vous allez publier l'article ?", en: 'Are you going to publish the article?', ok: true },
      { fr: "Est-ce que vous allez publié l'article ?", en: '(after « aller », use the infinitive)' },
      { fr: "Est-ce que vous allez publiez l'article ?", en: '(after « aller », use the infinitive)' },
    ],
  },
  { fr: "Oui. Mais le journal sort demain midi. C'est trop tard : à six heures, Lenoir parle à la télévision.", en: 'Yes. But the paper comes out tomorrow at noon. It is too late: at six o\'clock, Lenoir speaks on television.' },
  { fr: 'Prenez ceci : une accréditation de presse pour Télé Bruxelles. On ne sait jamais.', en: 'Take this: a press pass for Télé Bruxelles. You never know.' },
  { fr: "Attendez… Une voiture de police s'arrête devant l'immeuble. Allez voir à l'accueil.", en: 'Wait… A police car is stopping in front of the building. Go and see at the reception.' },
];

const CHIEF_MEET = [
  { fr: 'Commissaire Roche. On m\'a signalé un vol de documents chez Lumen.', en: 'Commissioner Roche. A theft of documents at Lumen has been reported to me.' },
  { fr: 'Donnez-moi votre téléphone. Ou répondez à mes questions… correctement.', en: 'Give me your phone. Or answer my questions… correctly.' },
];

const ENDING = [
  { who: CHIEF, fr: 'Bon… Gardez vos photos. De toute façon, demain, plus personne ne vous croira.', en: 'Fine… Keep your photos. Anyway, tomorrow, nobody will believe you any more.' },
  { who: YOU, fr: '(En partant, il fait tomber un petit carnet.)', en: '(As he leaves, he drops a little notebook.)' },
];
const ENDING_AFTER = [
  { who: PEOPLE.paul, fr: 'Télé Bruxelles… Lenoir passe en direct à six heures. Et Élise est enfermée là-bas !', en: 'Télé Bruxelles… Lenoir is live at six o\'clock. And Élise is locked up there!' },
  {
    who: YOU, fr: '(Propose ton idée : montrer les preuves en direct, à la télévision.)', en: '(Suggest your idea: show the proof live, on television.)',
    hint: 'A suggestion: « on pourrait » (conditional) + infinitive.',
    choices: [
      { fr: 'On pourrait montrer les preuves en direct, à la télévision !', en: 'We could show the proof live, on television!', ok: true },
      { fr: 'On pouvait montrer les preuves en direct demain !', en: '(the imparfait is for the past)' },
      { fr: 'On pourra montrait les preuves en direct.', en: '(two conjugated verbs)' },
    ],
  },
  { who: PEOPLE.paul, fr: "C'est fou… mais c'est notre seule chance. Avec l'accréditation, vous pouvez entrer.", en: 'It is crazy… but it is our only chance. With the press pass, you can get in.' },
  { who: PEOPLE.nina, fr: "J'appelle Sophie, une amie journaliste à Télé Bruxelles. Elle nous aidera.", en: 'I am calling Sophie, a journalist friend at Télé Bruxelles. She will help us.' },
  { who: YOU, fr: '(Cinq heures du matin. Direction : Télé Bruxelles.)', en: '(Five in the morning. Next stop: Télé Bruxelles.)' },
];

const PROOFS = ['article', 'micro', 'mail', 'dossier', 'photo'];
const allProofs = (s) => PROOFS.every((k) => s.found.includes(k));

export function objective(s) {
  if (!s.flags.bernard) return 'Talk to the night guard at the reception.';
  if (!s.flags.paul) return "Go to the editor's office (RÉDACTEUR EN CHEF), at the back. Stay out of the torch light.";
  if (!s.flags.jules) return 'Find proof ({n}/{total}). Jules, in the archives, knows about Lenoir.';
  if (!allProofs(s)) return 'Find proof in the newsroom and the archives ({n}/{total}).';
  if (!s.flags.nina) return 'Go to the photo lab (LABO PHOTO): Nina will print your photos.';
  if (!s.flags.paul2) return 'Show the prints to Paul Mercier, in his office.';
  if (!s.flags.done) return 'A police car has stopped outside. Go to the reception.';
  return 'Stage complete! Next: the live TV studio.';
}

export function hasNews(id, s) {
  if (id === 'bernard') return !s.flags.bernard;
  if (id === 'paul') return (s.flags.bernard && !s.flags.paul) || (s.flags.nina && !s.flags.paul2);
  if (id === 'jules') return s.flags.paul && !s.flags.jules;
  if (id === 'nina') return s.flags.jules && allProofs(s) && !s.flags.nina;
  if (id === 'accueil') return s.flags.paul2 && !s.flags.done;
  return false;
}

export async function afterClue(g) {
  const s = g.state;
  if (s.flags.jules && allProofs(s) && !s.flags.proofTold) {
    s.flags.proofTold = true;
    g.save();
    g.ui.toast('Enough proof! Nina is waiting in the photo lab.', 3200);
  }
  return false;
}

const SHORT = {
  bernardAgain: { fr: 'Le bureau de Paul est au fond. Faites attention aux deux types.', en: "Paul's office is at the back. Watch out for the two guys." },
  paulEarly: { fr: '(Paul Mercier est au téléphone. Il a l\'air nerveux.)', en: '(Paul Mercier is on the phone. He looks nervous.)' },
  paulWait: { fr: "Des preuves. Le bureau d'Élise, et les archives. Allez !", en: "Proof. Élise's desk, and the archives. Go!" },
  paulDone: { fr: 'Allez à Télé Bruxelles. Et ramenez Élise.', en: 'Go to Télé Bruxelles. And bring Élise back.' },
  julesEarly: { fr: '(Un vieil homme classe des journaux. Il chantonne.)', en: '(An old man is sorting newspapers. He is humming.)' },
  julesAgain: { fr: 'Le dossier 2019, au milieu. La photo, au fond.', en: 'The 2019 file, in the middle. The photo, at the back.' },
  ninaEarly: { fr: "Paul m'a dit d'attendre les preuves. Reviens quand tu les as !", en: 'Paul told me to wait for the proof. Come back when you have it!' },
  ninaAgain: { fr: 'Montre les tirages à Paul. Vite !', en: 'Show the prints to Paul. Quick!' },
  accueilEarly: { fr: "(L'accueil. Bernard regarde ses écrans.)", en: '(The reception. Bernard is watching his screens.)' },
  accueilDone: { fr: '(Télé Bruxelles. Six heures. Pas une minute à perdre.)', en: '(Télé Bruxelles. Six o\'clock. Not a minute to lose.)' },
};
const STORY_WORDS = ["J'ai", 'trouvé', 'ces', 'documents', 'en', 'cherchant', 'la', 'vérité.'];

export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'bernard') {
    if (s.flags.bernard) return g.ui.talk(P.bernard, [SHORT.bernardAgain]);
    s.mistakes += await g.ui.talk(P.bernard, BERNARD);
    s.flags.bernard = true;
    g.save();
    g.ui.toast('The newsroom door is open.', 2800);
  } else if (id === 'paul') {
    if (!s.flags.bernard) return g.ui.talk(YOU, [SHORT.paulEarly]);
    if (!s.flags.paul) {
      s.mistakes += await g.ui.talk(P.paul, PAUL);
      s.flags.paul = true;
      g.save();
      g.ui.toast('The archives and the photo lab are open.', 2800);
    } else if (s.flags.nina && !s.flags.paul2) {
      s.mistakes += await g.ui.talk(P.paul, PAUL_AGAIN.slice(0, 5));
      await g.give('accreditation');
      s.mistakes += await g.ui.talk(P.paul, PAUL_AGAIN.slice(5));
      s.flags.paul2 = true;
    } else return g.ui.talk(P.paul, [s.flags.paul2 ? SHORT.paulDone : SHORT.paulWait]);
  } else if (id === 'jules') {
    if (!s.flags.paul) return g.ui.talk(YOU, [SHORT.julesEarly]);
    if (s.flags.jules) return g.ui.talk(P.jules, [SHORT.julesAgain]);
    s.mistakes += await g.ui.talk(P.jules, JULES);
    s.flags.jules = true;
    g.save();
    await afterClue(g);
  } else if (id === 'nina') {
    if (s.flags.nina) return g.ui.talk(P.nina, [SHORT.ninaAgain]);
    if (!hasNews('nina', s)) return g.ui.talk(P.nina, [SHORT.ninaEarly]);
    s.mistakes += await g.ui.talk(P.nina, NINA.slice(0, 4));
    await g.give('tirages');
    s.mistakes += await g.ui.talk(P.nina, NINA.slice(4));
    s.flags.nina = true;
  } else if (id === 'accueil') {
    if (s.flags.done) return g.ui.talk(YOU, [SHORT.accueilDone]);
    if (!hasNews('accueil', s)) return g.ui.talk(YOU, [SHORT.accueilEarly]);
    await g.ui.talk(CHIEF, CHIEF_MEET);
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(STORY_WORDS);
    await g.ui.talk(CHIEF, ENDING);
    await g.give('carnet');
    s.mistakes += await g.ui.talk(CHIEF, ENDING_AFTER);
    s.flags.done = true;
    g.save();
    g.finish();
  }
  g.save();
}

export function allTexts() {
  const out = [];
  for (const n of [BERNARD, PAUL, JULES, NINA, PAUL_AGAIN, CHIEF_MEET, ENDING, ENDING_AFTER, STORY, Object.values(SHORT)].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note, c.where);
  for (const l of CHAPTER.locks) out.push(l.say);
  out.push(
    'Talk to the night guard at the reception.', "Go to the editor's office (RÉDACTEUR EN CHEF), at the back. Stay out of the torch light.",
    'Find proof ({n}/{total}). Jules, in the archives, knows about Lenoir.', 'Find proof in the newsroom and the archives ({n}/{total}).',
    'Go to the photo lab (LABO PHOTO): Nina will print your photos.', 'Show the prints to Paul Mercier, in his office.',
    'A police car has stopped outside. Go to the reception.', 'Stage complete! Next: the live TV studio.',
    'The newsroom door is open.', 'The archives and the photo lab are open.', 'Enough proof! Nina is waiting in the photo lab.',
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
  talk(P.bernard, [...BERNARD, SHORT.bernardAgain]);
  talk(P.paul, [...PAUL, ...PAUL_AGAIN, SHORT.paulWait, SHORT.paulDone]);
  talk(P.jules, [...JULES, SHORT.julesAgain]);
  talk(P.nina, [...NINA, SHORT.ninaEarly, SHORT.ninaAgain]);
  talk(CHIEF, [...CHIEF_MEET, ...ENDING, ...ENDING_AFTER]);
  talk(YOU, [SHORT.paulEarly, SHORT.julesEarly, SHORT.accueilEarly, SHORT.accueilDone]);
  STORY.forEach((st, i) => out.push([st.fr, { voice: i === 0 ? 'charline' : 'denise' }]));
  for (const c of CLUES) {
    out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
    out.push([c.noteFr, { voice: 'denise' }]);
  }
  out.push([STORY_WORDS.join(' '), { voice: 'denise' }]);
  return out;
}
