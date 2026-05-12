class LessonTopic {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String description;
  final List<dynamic>? content; // For AI-generated dynamic content

  const LessonTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
    this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'description': description,
      'content': content,
    };
  }

  factory LessonTopic.fromJson(Map<String, dynamic> json) {
    return LessonTopic(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      icon: json['icon'],
      description: json['description'],
      content: json['content'],
    );
  }
}

final List<LessonTopic> lessonTopics = [
  const LessonTopic(
    id: 'metiers',
    title: 'Les Métiers',
    subtitle: 'Jobs & Professions',
    icon: '💼',
    description: 'Learn how to talk about jobs, professions and work in French with proper gender forms and professional vocabulary.',
    content: [
      {"type": "section_title", "emoji": "🚀", "title": "Introduction aux Métiers"},
      {"type": "text", "content": "Les métiers (jobs) are essential for daily life in France. When introducing yourself, you will often say what you do. Remember: in French, we do NOT use an article (un/une) when stating our profession after the verb \"être\"!"},
      {"type": "example", "french": "Je suis médecin.", "translation": "I am a doctor."},
      {"type": "example", "french": "Il est ingénieur.", "translation": "He is an engineer."},
      
      {"type": "section_title", "emoji": "⚖️", "title": "Le Genre des Métiers (Masculin vs Féminin)"},
      {"type": "tipbox", "title": "La Règle d'Or", "content": "Most professions change their ending when a woman is doing the job. The general rule is adding an \"-e\", but there are specific patterns to memorize.", "color": "purple"},
      {"type": "table", "headers": ["Terminaison Masculine", "Terminaison Féminine", "Exemple"], "rows": [
        ["-er", "-ère", "Boulanger → Boulangère"],
        ["-eur", "-euse", "Serveur → Serveuse"],
        ["-teur", "-trice", "Directeur → Directrice"],
        ["-ien", "-ienne", "Musicien → Musicienne"]
      ]},
      
      {"type": "section_title", "emoji": "🏥", "title": "Santé et Éducation"},
      {"type": "french_tipbox", "title": "Vocabulaire Essentiel", "frenchText": "médecin → doctor\ninfirmier / infirmière → nurse\ndentiste → dentist\npharmacien / pharmacienne → pharmacist\nprofesseur / professeure → teacher\nétudiant / étudiante → student", "color": "green"},
      
      {"type": "section_title", "emoji": "🏢", "title": "Bureau et Commerce"},
      {"type": "french_tipbox", "title": "Monde du Travail", "frenchText": "avocat / avocate → lawyer\ncomptable → accountant\nsecrétaire → secretary\ninformaticien / informaticienne → IT specialist\nvendeur / vendeuse → salesperson\nchef d'entreprise → business owner", "color": "blue"},
      
      {"type": "section_title", "emoji": "🏗️", "title": "Métiers Techniques"},
      {"type": "french_tipbox", "title": "Artisans et Techniciens", "frenchText": "architecte → architect\ningénieur / ingénieure → engineer\nélectricien / électricienne → electrician\nplombier → plumber\nmécanicien / mécanicienne → mechanic", "color": "yellow"},
      
      {"type": "section_title", "emoji": "💡", "title": "Conseils du Professeur"},
      {"type": "tipbox", "title": "Genre Invariable", "content": "Some professions remain the same regardless of gender, especially those ending in \"-e\", such as: journaliste, dentiste, architecte, artiste.", "color": "red"},
      
      {"type": "section_title", "emoji": "💬", "title": "Phrases Utiles"},
      {"type": "example", "french": "Quel est votre métier ?", "translation": "What is your profession?"},
      {"type": "example", "french": "Je travaille comme infirmière.", "translation": "I work as a nurse."},
      {"type": "example", "french": "Elle est à la recherche d'un emploi.", "translation": "She is looking for a job."},
      {"type": "example", "french": "Mon père est à la retraite.", "translation": "My father is retired."}
    ],
  ),
];
