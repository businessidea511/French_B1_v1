// Le Dossier Bruxelles — Chapitre 5 : « La Vérité » (B1, the finale).
// The subjonctif (il faut que, je veux que, bien que, pour que), the
// conditionnel and hypotheses (si + imparfait → conditionnel), and reported
// speech (il a dit que… / il a demandé si…).

export const CHAPTER = {
  id: 5,
  title: 'Chapitre 5 : La Vérité',
  level: 'B1',
  world: 'office',
  layout: 'studio',
  detect: 'cone',
  saveKey: 'dossier_save_ch5',
  spawn: [0, 21.5, Math.PI],
  respawn: [0, 21, Math.PI],
  lights: [[0, 2.6, 16, '#d6e4ff'], [-12, 2.6, 3, '#ffe2b8'], [12, 2.6, 3, '#9fd8ff'], [4, 2.8, -16, '#fff3d6'], [-15, 2.6, -20, '#d6e4ff'], [-5, 2.6, -10, '#ffd59a']],
  places: [{ id: 'plateau', x: 4, z: -12.6, y: 2.4, symbol: '!' }],
  locks: [
    { rect: [-3, 3, -7, -5], flag: 'ready', say: 'The studio is closed. You need Sophie, Karim, Élise… and all the proof.' },
  ],
  agents: [
    { id: 'reserve', path: [[-11, -13.2]] },
    { id: 'redaction', path: [[-17.5, -3.2], [-5, -3.2]], guards: 'conducteur' },
    { id: 'lenoir', path: [[4, -16.4]], chief: true,
      look: { skin: '#e0b896', hair: '#d0d0d0', coat: '#15171c', shirt: '#ffffff', pants: '#15171c', height: 1.05 } },
  ],
  next: '🎓 Niveau B1 terminé ! — Saison 2 (B2)',
  doneIcon: '🌅',
};

export const LINES = {
  agentName: 'Un garde de Lumen', chiefName: 'Monsieur Lenoir (en direct)',
  agentVoice: { voice: 'remy', speed: 0.95 }, chiefVoice: { voice: 'henri', speed: 0.85 },
  agentIntro: 'Halte ! Personne n\'entre ici.', chiefIntro: 'Je vous écoute. La Belgique entière vous écoute.',
  release: 'Bon… Passez.', storyAsk: 'Alors, dites-le. Devant les caméras.',
  caught: 'The guards push you back to the lobby.',
};

export const BANKS = [
  { kind: 'phrase', icon: '🙏', help: 'The subjonctif: after il faut que, je veux que, bien que, pour que…', items: [
    ["Qu'est-ce qu'il faut faire ?", 'Il faut que nous disions la vérité.', ['Il faut que nous disons la vérité.', 'Il faut que nous dirons la vérité.'], 'What must be done?'],
    ['Vous voulez que je vous aide ?', 'Oui, je veux que vous m\'aidiez.', ["Oui, je veux que vous m'aidez.", "Oui, je veux vous m'aider."], 'Do you want me to help you?'],
    ['Pourquoi restez-vous ici ?', 'Je reste pour que vous soyez en sécurité.', ['Je reste pour que vous êtes en sécurité.', 'Je reste pour que vous serez en sécurité.'], 'Why are you staying here?'],
    ['Vous continuez, même maintenant ?', 'Bien que ce soit dangereux, je continue.', ["Bien que c'est dangereux, je continue.", 'Bien que ce sera dangereux, je continue.'], 'Are you going on, even now?'],
    ['Il faut partir quand ?', 'Il faut que nous partions avant six heures.', ['Il faut que nous partons avant six heures.', 'Il faut que nous partirons avant six heures.'], 'When must we leave?'],
    ['De quoi avez-vous peur ?', "J'ai peur qu'il soit trop tard.", ["J'ai peur qu'il est trop tard.", "J'ai peur qu'il sera trop tard."], 'What are you afraid of?'],
  ] },
  { kind: 'phrase', icon: '🌗', help: 'The conditionnel, and si + imparfait → conditionnel.', items: [
    ['Que feriez-vous à ma place ?', 'À votre place, je dirais la vérité.', ['À votre place, je dirai la vérité.', 'À votre place, je disais la vérité.'], 'What would you do in my place?'],
    ['Et si vous aviez le choix ?', "Si j'avais le choix, je partirais.", ["Si j'aurais le choix, je partirais.", "Si j'avais le choix, je partirai."], 'And if you had the choice?'],
    ['Vous pourriez m\'aider ?', 'Oui, je pourrais vous aider.', ['Oui, je pourrait vous aider.', 'Oui, je pourrais vous aidé.'], 'Could you help me?'],
    ['Et si la police venait ?', 'Si la police venait, je lui parlerais.', ['Si la police viendrait, je lui parlerais.', 'Si la police venait, je lui parlerai.'], 'And if the police came?'],
    ['Vous voudriez un café ?', 'Oui, je voudrais bien, merci.', ['Oui, je voudrai bien, merci.', 'Oui, je voulais bien, merci.'], 'Would you like a coffee?'],
  ] },
  { kind: 'phrase', icon: '🗣️', help: 'Reported speech: il a dit que… (the tenses move back), il a demandé si…', items: [
    ["Qu'est-ce qu'Élise a dit ?", "Elle a dit qu'elle avait les preuves.", ["Elle a dit qu'elle a eu les preuves demain.", 'Elle a dit que elle avait les preuves.'], 'What did Élise say?'],
    ["Qu'est-ce que le garde a dit ?", "Il a dit qu'il ne savait rien.", ["Il a dit qu'il ne sait rien hier.", 'Il a dit que il ne savait rien.'], 'What did the guard say?'],
    ["Qu'est-ce que Victor a promis ?", "Il a promis qu'il nous aiderait.", ["Il a promis qu'il nous aidera hier.", "Il a promis qu'il nous aide hier."], 'What did Victor promise?'],
    ["Qu'est-ce que Sophie a demandé ?", 'Elle a demandé si nous avions des preuves.', ['Elle a demandé que nous avions des preuves.', 'Elle a demandé si nous avons eu des preuves demain.'], 'What did Sophie ask?'],
    ["Qu'est-ce que Karim a répondu ?", "Il a répondu qu'il diffuserait les images.", ["Il a répondu qu'il diffusera les images hier.", "Il a répondu que il diffuserait les images."], 'What did Karim answer?'],
  ] },
];

export const CLUES = [
  { key: 'badge', where: 'In the lobby, on the left.', art: 'le', noun: 'badge de presse', g: 'm', en: 'the press badge', emoji: '🪪', x: -12, z: 20.6,
    noteFr: '« PRESSE — Télé Bruxelles ». Avec ce badge, personne ne te posera de questions… peut-être.',
    note: '« PRESS — Télé Bruxelles ». With this badge, nobody will ask you questions… maybe.' },
  { key: 'lettre', where: 'In the lobby, near the sofa on the right.', art: 'la', noun: 'lettre de Victor', g: 'f', en: "Victor's letter", emoji: '✉️', x: 15.2, z: 20.2,
    noteFr: '« Pardon. Ma fille est libre maintenant. Je témoignerai contre Lenoir. — Victor »',
    note: '« Forgive me. My daughter is free now. I will testify against Lenoir. — Victor »' },
  { key: 'enregistrement', where: 'In the newsroom, near the desks at the back.', art: "l'", noun: 'enregistrement', g: 'm', en: 'the recording', emoji: '📼', x: -15, z: 2.6,
    noteFr: 'La voix de Lenoir : « Personne ne doit savoir ce que fait la puce. Personne. »',
    note: "Lenoir's voice: « Nobody must know what the chip does. Nobody. »" },
  { key: 'conducteur', where: 'In the newsroom, near the front desks. A guard walks there.', art: 'le', noun: 'conducteur du journal', g: 'm', en: "the news programme's running order", emoji: '📄', x: -9, z: -2.6,
    noteFr: '« Six heures : interview de Victor Lenoir, en direct, pendant dix minutes. »',
    note: '« 6 a.m.: interview with Victor Lenoir, live, for ten minutes. »' },
  { key: 'micro', where: 'In the control room (RÉGIE), near the screens.', art: 'le', noun: 'micro-cravate', g: 'm', en: 'the lapel microphone', emoji: '🎙️', x: 17.4, z: 7.6,
    noteFr: 'Le micro-cravate du présentateur. Avec lui, ta voix passera en direct.',
    note: "The presenter's lapel microphone. With it, your voice will go out live." },
  { key: 'telephone', where: 'Élise will give it to you.', art: 'le', noun: "téléphone d'Élise", g: 'm', en: "Élise's phone", emoji: '📱', given: true,
    noteFr: "Élise a tout enregistré quand les gardes l'ont enfermée : leurs voix, leurs menaces.",
    note: 'Élise recorded everything when the guards locked her up: their voices, their threats.' },
];

export const STORY = [
  { emoji: '🌌', fr: "Cinq heures du matin. Élise est prisonnière. Lenoir a la clé USB.", en: 'Five in the morning. Élise is a prisoner. Lenoir has the USB key.' },
  { emoji: '📸', fr: 'Mais tu as les photos des documents… et une idée : la télévision.', en: 'But you have the photos of the documents… and an idea: television.' },
  { emoji: '📺', fr: 'À six heures, Lenoir passe en direct au journal de Télé Bruxelles.', en: "At six o'clock, Lenoir is live on the Télé Bruxelles news." },
  { emoji: '⚖️', fr: "C'est ta dernière chance, {name}. Il faut que la vérité éclate.", en: 'It is your last chance, {name}. The truth must come out.' },
];

export const PEOPLE = {
  sophie: {
    name: 'Sophie, la journaliste', avatar: '🎤', voice: { voice: 'vivienne', speed: 0.98 },
    pos: [4.6, 18.6], face: -Math.PI / 2,
    look: { skin: '#e9c2a0', hair: '#1f1612', longHair: true, coat: '#6a2f4a', pants: '#1a1a1d', scarf: '#e8c33a', height: 0.97 },
  },
  karim: {
    name: 'Karim, le technicien', avatar: '🎛️', voice: { voice: 'gerard', speed: 0.98 },
    pos: [11.6, 7.4], face: 0,
    look: { skin: '#b7865f', hair: '#14100c', beard: '#14100c', coat: '#2a3340', pants: '#1a1d24', glasses: true },
  },
  elise: {
    name: 'Élise', avatar: '👩', voice: { voice: 'charline', speed: 0.98 },
    pos: [-15, -20], face: 0,
    look: { skin: '#f0caa8', hair: '#3a2416', longHair: true, coat: '#a8231f', coatLong: true, pants: '#1a1a1d', height: 0.97 },
  },
};

export const YOU = { name: 'Toi', avatar: '🕵️', voice: { voice: 'denise' } };
export const LENOIR = { name: 'Monsieur Lenoir', avatar: '🎩', voice: { voice: 'henri', speed: 0.85 } };
export const VICTOR = { name: 'Victor', avatar: '📚', voice: { voice: 'remy', speed: 0.92 } };
export const POLICE = { name: 'La commissaire', avatar: '👮', voice: { voice: 'denise', speed: 0.95 } };

const SOPHIE = [
  { fr: "Bonsoir… ou bonjour ? Il est cinq heures du matin ! Qu'est-ce que vous faites ici ?", en: 'Good evening… or good morning? It is five in the morning! What are you doing here?' },
  {
    fr: '(Demande-lui de l\'aide.)', en: '(Ask her for help.)',
    hint: 'After « il faut que » → the subjonctif: « que vous m\'aidiez ».',
    choices: [
      { fr: "Il faut que vous m'aidiez. C'est très important.", en: 'You must help me. It is very important.', ok: true },
      { fr: "Il faut que vous m'aidez. C'est très important.", en: '(indicative: wrong after il faut que)' },
      { fr: "Il faut que vous m'aiderez. C'est très important.", en: '(future: wrong after il faut que)' },
    ],
  },
  { fr: 'Vous aider ? Mais… qui êtes-vous ?', en: 'Help you? But… who are you?' },
  {
    fr: '(Montre-lui les photos des documents.)', en: '(Show her the photos of the documents.)',
    hint: 'Use « vous » with her, and the present tense.',
    choices: [
      { fr: 'Regardez ces photos. Lumen surveille toute la ville.', en: 'Look at these photos. Lumen watches the whole city.', ok: true },
      { fr: 'Regarde ces photos, toi. Lumen surveille la ville.', en: '(too familiar with a stranger)' },
      { fr: 'Regardez ces photos. Lumen surveillera la ville hier.', en: '(future + hier: impossible)' },
    ],
  },
  { fr: "Mon Dieu… Si c'est vrai, ce serait le plus grand scandale de Belgique !", en: 'My God… If it is true, it would be the biggest scandal in Belgium!' },
  {
    fr: '(Qu\'est-ce que Sophie pense ?)', en: '(What does Sophie think?)',
    hint: '« ce serait » = conditionnel: it would be.',
    choices: [
      { fr: "Si c'est vrai, ce serait un énorme scandale.", en: 'If it is true, it would be a huge scandal.', ok: true },
      { fr: "C'est faux, ce n'est pas un scandale.", en: 'It is false, it is not a scandal.' },
      { fr: 'Ce sera un petit problème.', en: 'It will be a small problem.' },
    ],
  },
  { fr: 'Lenoir passe en direct à six heures. Allez voir Karim, à la régie. Lui seul peut changer les images.', en: 'Lenoir is live at six. Go and see Karim, in the control room. Only he can change the pictures.' },
];

const KARIM = [
  { fr: 'Sophie m\'a parlé de vous. Mais si je diffusais vos photos, je perdrais mon travail.', en: 'Sophie told me about you. But if I broadcast your photos, I would lose my job.' },
  {
    fr: '(Convaincs-le.)', en: '(Convince him.)',
    hint: 'si + imparfait → conditionnel. Never the conditionnel right after « si ».',
    choices: [
      { fr: "Si vous m'aidiez, toute la ville saurait la vérité.", en: 'If you helped me, the whole city would know the truth.', ok: true },
      { fr: "Si vous m'aideriez, toute la ville saurait la vérité.", en: '(conditionnel after si: wrong)' },
      { fr: "Si vous m'aiderez, toute la ville saura la vérité.", en: '(future after si: wrong here)' },
    ],
  },
  { fr: 'Hmm… Vous avez raison. Mais il me faudrait deux choses.', en: 'Hmm… You are right. But I would need two things.' },
  { fr: "Il faudrait que vous trouviez le micro-cravate du présentateur. Et il faudrait qu'un témoin parle à l'antenne.", en: "You would need to find the presenter's lapel microphone. And a witness would need to speak on air." },
  {
    fr: '(De quoi Karim a-t-il besoin ?)', en: '(What does Karim need?)',
    hint: 'Listen again: « le micro-cravate… un témoin ».',
    choices: [
      { fr: "Du micro-cravate et d'un témoin.", en: 'The lapel microphone and a witness.', ok: true },
      { fr: "D'un café et d'un taxi.", en: 'A coffee and a taxi.' },
      { fr: 'De la clé USB et de Victor.', en: 'The USB key and Victor.' },
    ],
  },
  { fr: 'Un témoin… Élise Moreau ! Mes collègues disent que des gardes ont enfermé une femme dans la réserve.', en: 'A witness… Élise Moreau! My colleagues say that guards locked a woman in the storage room.' },
  {
    fr: '(Qu\'est-ce que les collègues disent ?)', en: '(What do the colleagues say?)',
    hint: 'Reported speech: « ils disent que… ».',
    choices: [
      { fr: 'Ils disent que des gardes ont enfermé une femme.', en: 'They say that guards locked up a woman.', ok: true },
      { fr: 'Ils disent que des gardes enfermeront une femme hier.', en: '(future + hier: impossible)' },
      { fr: 'Ils disent si des gardes ont enfermé une femme.', en: '(si is for questions)' },
    ],
  },
];

const ELISE = [
  { fr: '{name} ! Tu es venu ! Je savais que tu viendrais.', en: 'You came! I knew you would come.' },
  { fr: "Lenoir a dit qu'il me libérerait après l'émission. Il ment.", en: 'Lenoir said that he would free me after the show. He is lying.' },
  {
    fr: '(Qu\'est-ce que Lenoir a dit ?)', en: '(What did Lenoir say?)',
    hint: 'Reported speech: « il me libérera » becomes « qu\'il la libérerait ».',
    choices: [
      { fr: "Il a dit qu'il la libérerait après l'émission.", en: 'He said that he would free her after the show.', ok: true },
      { fr: "Il a dit qu'il la libérera hier.", en: '(future + hier: impossible)' },
      { fr: "Il a dit si il la libérerait.", en: '(si is for questions)' },
    ],
  },
  { fr: "Il faut qu'on aille au studio. Je veux que tout le monde sache la vérité.", en: 'We must go to the studio. I want everyone to know the truth.' },
  {
    fr: '« Je veux que tout le monde ___ la vérité. »', en: '« I want everyone ___ the truth. »',
    hint: 'savoir in the subjonctif: que je sache, qu\'il sache.',
    choices: [{ fr: 'sache', ok: true }, { fr: 'sait' }, { fr: 'saura' }], keepOrder: true,
  },
  { fr: "Tiens, mon téléphone. J'ai tout enregistré quand ils m'ont enfermée.", en: 'Here, my phone. I recorded everything when they locked me up.' },
];

const PLATEAU = [
  { who: LENOIR, fr: 'Vous ? Ici ? Sécurité !… Non. Attendez. Nous sommes en direct.', en: 'You? Here? Security!… No. Wait. We are live.' },
  { who: LENOIR, fr: 'Très bien. Parlons. Devant toute la Belgique.', en: 'Very well. Let us talk. In front of the whole of Belgium.' },
];

const ENDING = [
  { who: PEOPLE.sophie, fr: 'Nous sommes en direct. Mesdames et messieurs, voici les documents secrets de Lumen.', en: "We are live. Ladies and gentlemen, here are Lumen's secret documents." },
  { who: PEOPLE.elise, fr: "Je m'appelle Élise Moreau. Cette nuit, on m'a enfermée parce que je disais la vérité.", en: 'My name is Élise Moreau. Tonight, I was locked up because I was telling the truth.' },
  { who: VICTOR, fr: 'Et moi, je témoignerai. Lenoir a menacé ma fille pour que je l\'aide.', en: 'And I will testify. Lenoir threatened my daughter so that I would help him.' },
  { who: LENOIR, fr: "C'est… c'est faux ! Je…", en: 'It is… it is false! I…' },
  { who: YOU, fr: '(Des sirènes. La police entre dans le studio. Cette fois, c\'est la vraie police.)', en: '(Sirens. The police come into the studio. This time, it is the real police.)' },
  { who: POLICE, fr: 'Monsieur Lenoir, vous êtes en état d\'arrestation.', en: 'Mr Lenoir, you are under arrest.' },
  { who: PEOPLE.elise, fr: "Sans toi, je n'aurais jamais réussi. Merci.", en: 'Without you, I would never have succeeded. Thank you.' },
  { who: YOU, fr: "(Dehors, le soleil se lève sur Bruxelles. La pluie s'est arrêtée.)", en: '(Outside, the sun is rising over Brussels. The rain has stopped.)' },
  {
    who: PEOPLE.elise, fr: 'Alors… On va prendre un café ? Au Corbeau, comme avant ?', en: 'So… Shall we have a coffee? At the Corbeau, like before?',
    hint: '« c\'est moi qui » + the verb with « je »: « c\'est moi qui l\'offre ».',
    choices: [
      { fr: "Avec plaisir ! C'est moi qui l'offre.", en: 'With pleasure! It is on me.', ok: true },
      { fr: "Avec plaisir ! C'est moi que l'offre.", en: '(que does not fit here)' },
      { fr: "Avec plaisir ! C'est moi qui l'offrirais hier.", en: '(conditionnel + hier: impossible)' },
    ],
  },
];

const SHORT = {
  sophieAgain: { fr: 'Karim est à la régie. Vite, il est presque six heures !', en: 'Karim is in the control room. Quick, it is almost six!' },
  karimAgain: { fr: 'Le micro-cravate et un témoin. Sans eux, je ne peux rien faire.', en: 'The lapel microphone and a witness. Without them, I can do nothing.' },
  karimEarly: { fr: 'La régie est fermée au public. Qui vous a laissé entrer ?', en: 'The control room is closed to the public. Who let you in?' },
  eliseAgain: { fr: 'Allons au studio. Il faut que tout le monde sache.', en: 'Let us go to the studio. Everyone must know.' },
  eliseLocked: { fr: '(La porte de la réserve… Un garde la surveille.)', en: '(The storage room door… A guard is watching it.)' },
  plateauEarly: { fr: '(Le studio. Lenoir se prépare. Il me faut d\'abord Sophie, Karim, Élise et toutes les preuves.)', en: '(The studio. Lenoir is getting ready. First I need Sophie, Karim, Élise and all the proof.)' },
  plateauDone: { fr: '(Le studio est vide. Tout est fini.)', en: '(The studio is empty. It is all over.)' },
};
const STORY_WORDS = ['Il', 'faut', 'que', 'tout', 'le', 'monde', 'sache', 'la', 'vérité.'];

export function objective(s) {
  if (!s.flags.sophie) return 'Talk to the journalist in the lobby.';
  if (!s.flags.karim) return 'Find Karim in the control room (RÉGIE). Proof: {n}/{total}.';
  if (!s.flags.elise) return 'Free Élise from the storage room (RÉSERVE). Proof: {n}/{total}.';
  if (s.found.length < CLUES.length) return 'Find the last proof ({n}/{total}).';
  if (!s.flags.done) return 'Go into the studio and face Lenoir, live.';
  return 'The end! You have finished the B1 level.';
}

export function hasNews(id, s) {
  if (id === 'sophie') return !s.flags.sophie;
  if (id === 'karim') return s.flags.sophie && !s.flags.karim;
  if (id === 'elise') return s.flags.karim && !s.flags.elise;
  if (id === 'plateau') return !!s.flags.ready && !s.flags.done;
  return false;
}

/** The studio opens once everyone and every proof is here. */
export async function afterClue(g) {
  const s = g.state;
  if (s.flags.ready || !s.flags.sophie || !s.flags.karim || !s.flags.elise || s.found.length < CLUES.length) return false;
  s.flags.ready = true;
  g.save();
  g.ui.toast('🎬 The studio is open. Go and face Lenoir, live!', 3500);
  return true;
}

export async function interact(id, g) {
  const s = g.state;
  const P = PEOPLE;
  if (id === 'sophie') {
    if (s.flags.sophie) return g.ui.talk(P.sophie, [SHORT.sophieAgain]);
    s.mistakes += await g.ui.talk(P.sophie, SOPHIE);
    s.flags.sophie = true;
  } else if (id === 'karim') {
    if (!s.flags.sophie) return g.ui.talk(P.karim, [SHORT.karimEarly]);
    if (s.flags.karim) return g.ui.talk(P.karim, [SHORT.karimAgain]);
    s.mistakes += await g.ui.talk(P.karim, KARIM);
    s.flags.karim = true;
  } else if (id === 'elise') {
    if (s.flags.elise) return g.ui.talk(P.elise, [SHORT.eliseAgain]);
    if (!s.flags.karim) return g.ui.talk(YOU, [SHORT.eliseLocked]);
    s.mistakes += await g.ui.talk(P.elise, ELISE);
    s.flags.elise = true;
    g.save();
    await g.give('telephone');
  } else if (id === 'plateau') {
    if (s.flags.done) return g.ui.talk(YOU, [SHORT.plateauDone]);
    if (!s.flags.ready) return g.ui.talk(YOU, [SHORT.plateauEarly]);
    await g.ui.talk(LENOIR, PLATEAU);
    if (!(await g.confrontChief())) return;
    s.mistakes += await g.story(STORY_WORDS);
    s.mistakes += await g.ui.talk(P.sophie, ENDING);
    s.flags.done = true;
    g.save();
    g.finish();
    return;
  }
  g.save();
  await afterClue(g);
}

export function allTexts() {
  const out = [];
  for (const n of [SOPHIE, KARIM, ELISE, PLATEAU, ENDING, STORY, Object.values(SHORT)].flat()) {
    out.push(n.en, n.hint);
    for (const c of n.choices || []) out.push(c.en);
  }
  for (const c of CLUES) out.push(c.en, c.note, c.where);
  for (const l of CHAPTER.locks) out.push(l.say);
  out.push(
    'Talk to the journalist in the lobby.', 'Find Karim in the control room (RÉGIE). Proof: {n}/{total}.',
    'Free Élise from the storage room (RÉSERVE). Proof: {n}/{total}.', 'Find the last proof ({n}/{total}).',
    'Go into the studio and face Lenoir, live.', 'The end! You have finished the B1 level.',
    '🎬 The studio is open. Go and face Lenoir, live!', 'Chapter 5 complete!', 'A man in grey guards this clue. Get past him first.', 'Hint',
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
  talk(P.sophie, [...SOPHIE, SHORT.sophieAgain]);
  talk(P.karim, [...KARIM, SHORT.karimAgain, SHORT.karimEarly]);
  talk(P.elise, [...ELISE, SHORT.eliseAgain]);
  talk(YOU, [SHORT.eliseLocked, SHORT.plateauEarly, SHORT.plateauDone]);
  talk(LENOIR, PLATEAU);
  talk(P.sophie, ENDING);
  STORY.forEach((st) => out.push([st.fr, { voice: 'denise' }]));
  for (const c of CLUES) {
    out.push([c.art.endsWith("'") ? c.art + c.noun : `${c.art} ${c.noun}`, { voice: 'denise' }]);
    out.push([c.noteFr, { voice: 'denise' }]);
  }
  out.push([STORY_WORDS.join(' '), { voice: 'denise' }]);
  return out;
}
