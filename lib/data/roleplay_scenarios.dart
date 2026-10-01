/// Real situations of life in Belgium for the AI role-play.
class Scenario {
  final String id;
  final String emoji;
  final String title; // French
  final String goal; // English: what the learner must achieve (translated on screen)
  final String aiRole; // English, for the AI: who it plays
  final String opening; // the AI's first line, in French

  const Scenario(this.id, this.emoji, this.title, this.goal, this.aiRole, this.opening);
}

const List<Scenario> scenarios = [
  Scenario('commune', '🏛️', 'À la commune',
      'Change your address after moving, and find out which documents you need.',
      'an employee at the counter of a Brussels commune (population service), polite but busy, who asks for documents',
      'Bonjour ! Vous avez votre ticket ? Qu\'est-ce que je peux faire pour vous ?'),
  Scenario('medecin', '🩺', 'Chez le médecin',
      'Explain your symptoms, answer the doctor\'s questions and understand the treatment.',
      'a friendly general practitioner (médecin généraliste) in Liège who asks precise questions about symptoms',
      'Bonjour, asseyez-vous. Alors, qu\'est-ce qui vous amène aujourd\'hui ?'),
  Scenario('proprietaire', '🔑', 'Le propriétaire',
      'The heating is broken. Call your landlord and get a date for the repair.',
      'a landlord who is not very happy to spend money and first suggests the tenant fixes it alone',
      'Allô, oui ? C\'est à quel sujet ?'),
  Scenario('entretien', '💼', 'Entretien d\'embauche',
      'Present yourself, talk about your experience and ask a question about the job.',
      'an HR manager of a supermarket chain in Namur interviewing for a sales assistant job',
      'Bonjour et bienvenue. Pour commencer, pouvez-vous vous présenter en quelques mots ?'),
  Scenario('boulangerie', '🥐', 'À la boulangerie',
      'Buy bread and pastries for a birthday, and ask what they recommend.',
      'a cheerful Brussels baker who uses Belgian words (pistolets, couques) and makes small talk',
      'Bonjour ! Qu\'est-ce que je vous sers ?'),
  Scenario('pharmacie', '💊', 'À la pharmacie',
      'You have a cold. Ask for advice and something without a prescription.',
      'a careful pharmacist who asks about allergies and other medicines',
      'Bonjour, je vous écoute.'),
  Scenario('ecole', '🎒', 'À l\'école des enfants',
      'Meet your child\'s teacher to talk about their progress and a school trip.',
      'a primary school teacher (institutrice) who talks about the child\'s homework and a trip to Bruges',
      'Bonjour, merci d\'être venu. Asseyez-vous, je voulais vous parler de votre enfant.'),
  Scenario('voisin', '🔊', 'Le voisin bruyant',
      'Your neighbour plays loud music late at night. Complain politely and find a solution.',
      'a neighbour who does not think he is noisy and gets a bit defensive',
      'Oui ? Bonsoir… Il y a un problème ?'),
  Scenario('banque', '🏦', 'À la banque',
      'Open a bank account and ask about the bank card and fees.',
      'a bank advisor who explains documents needed and account options',
      'Bonjour, vous avez rendez-vous ? Que puis-je faire pour vous ?'),
  Scenario('stib', '🚋', 'Contrôle dans le tram',
      'A ticket inspector checks you, but your card does not work. Explain the situation.',
      'a strict STIB ticket inspector in Brussels',
      'Bonjour, contrôle des titres de transport. Votre ticket ou votre carte, s\'il vous plaît.'),
  Scenario('restaurant', '🍽️', 'Au restaurant',
      'Book a table, order a meal with a special request, and complain kindly about a mistake.',
      'a waiter in a brasserie in Liège, friendly and talkative',
      'Bonsoir ! Vous avez réservé ?'),
  Scenario('ami', '🍻', 'Sortir avec un ami belge',
      'Plan a night out with a Belgian friend: when, where and what to do.',
      'a young Belgian friend who speaks casually with Belgian expressions (une fois, à tantôt, septante, il drache)',
      'Salut ! Ça fait longtemps ! On se fait quelque chose ce week-end ?'),
];
