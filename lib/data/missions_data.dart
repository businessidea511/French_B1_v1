/// Real-life missions: small things to do in French in Belgium. Three are
/// offered each week. Titles are French; descriptions are English (translated
/// on screen).
class Mission {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final String phrase; // a sentence to help

  const Mission(this.id, this.emoji, this.title, this.description, this.phrase);
}

const List<Mission> allMissions = [
  Mission('pain', '🥖', 'Acheter du pain en français', 'Buy bread at a bakery speaking only French.', 'Un pain gris, s\'il vous plaît. Il est tranché ?'),
  Mission('chemin', '🧭', 'Demander son chemin', 'Ask someone in the street for directions.', 'Excusez-moi, la gare, c\'est loin d\'ici ?'),
  Mission('cafe', '☕', 'Commander au café', 'Order a drink and ask for the bill in French.', 'Je voudrais un café, s\'il vous plaît. L\'addition, s\'il vous plaît.'),
  Mission('voisin', '🏠', 'Parler à un voisin', 'Have a short chat with a neighbour (weather, weekend…).', 'Il drache encore aujourd\'hui ! Vous avez passé un bon week-end ?'),
  Mission('telephone', '📞', 'Téléphoner pour un rendez-vous', 'Call to book an appointment (doctor, hairdresser…).', 'Bonjour, je voudrais prendre rendez-vous pour la semaine prochaine.'),
  Mission('radio', '📻', 'Écouter la radio 15 minutes', 'Listen to a French-speaking radio (RTBF La Première, Classic 21…) for 15 minutes.', 'J\'ai écouté les infos de ce matin.'),
  Mission('serie', '🎬', 'Regarder un épisode en français', 'Watch one episode of a series in French with French subtitles.', 'J\'ai regardé un épisode sans sous-titres anglais.'),
  Mission('journal', '✍️', 'Écrire 5 phrases sur ta journée', 'Write five sentences about your day in the passé composé.', 'Ce matin, je me suis levé(e) tôt et j\'ai pris le tram.'),
  Mission('pharmacie', '💊', 'Demander conseil au pharmacien', 'Ask a pharmacist for advice about a small problem.', 'J\'ai mal à la gorge, qu\'est-ce que vous me conseillez ?'),
  Mission('marche', '🍎', 'Faire le marché', 'Buy fruit or vegetables at a market and ask the price.', 'C\'est combien, le kilo de pommes ?'),
  Mission('message', '💬', 'Envoyer un message vocal', 'Send a voice message in French to a classmate.', 'Salut ! Tu as compris les devoirs pour demain ?'),
  Mission('affiche', '🪧', 'Lire une affiche', 'Read a poster or sign in the street and understand it all.', 'Il est interdit de stationner ici.'),
  Mission('recette', '🍲', 'Cuisiner une recette en français', 'Follow a French recipe (video or website).', 'Il faut mélanger la farine et les œufs.'),
  Mission('bibliotheque', '📚', 'Emprunter un livre', 'Borrow a book or a comic (BD) at a library.', 'Je voudrais m\'inscrire à la bibliothèque.'),
  Mission('compliment', '🌟', 'Faire un compliment', 'Give someone a compliment in French.', 'Ta veste est super jolie !'),
  Mission('expression', '🗣️', 'Utiliser une expression', 'Use one new expression of the week in a real conversation.', 'Ça tombe bien !'),
  Mission('magasin', '🛍️', 'Demander une taille', 'Ask for another size or colour in a shop.', 'Vous l\'avez en taille M ? Et en bleu ?'),
  Mission('transport', '🚋', 'Acheter un ticket', 'Buy a bus/tram ticket or ask about a timetable.', 'Le prochain tram pour la gare passe à quelle heure ?'),
  Mission('meteo', '⛅', 'Parler de la météo', 'Talk about the weather with someone — very Belgian!', 'Il fait cru ce matin, hein ?'),
  Mission('podcast', '🎧', 'Écouter un podcast', 'Listen to a French podcast for learners (e.g. « Français facile » RFI).', 'J\'ai compris l\'idée principale.'),
  Mission('presenter', '🙋', 'Te présenter', 'Introduce yourself to someone new in French.', 'Je m\'appelle…, je viens de…, j\'habite à… depuis…'),
  Mission('formulaire', '📝', 'Remplir un formulaire', 'Fill in a form in French (online or on paper) on your own.', 'Nom, prénom, date de naissance, adresse…'),
  Mission('opinion', '🤔', 'Donner ton opinion', 'Give your opinion on a topic in a conversation.', 'À mon avis, … parce que …'),
  Mission('chanson', '🎵', 'Apprendre une chanson', 'Listen to a French song and read its words (Stromae, Angèle…).', 'J\'ai trouvé les paroles et j\'ai compris le refrain.'),
];

/// The three missions of the week containing [weekStart] (a Monday).
List<Mission> missionsOfWeek(DateTime weekStart) {
  final week = weekStart.difference(DateTime(2024, 1, 1)).inDays ~/ 7;
  final start = (week * 3) % allMissions.length;
  return [for (var i = 0; i < 3; i++) allMissions[(start + i) % allMissions.length]];
}
