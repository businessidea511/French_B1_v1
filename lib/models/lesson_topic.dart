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
    description: 'Learn how to talk about jobs, professions and work in Belgium with proper gender forms and professional vocabulary.',
    content: [
      {"type": "section_title", "emoji": "🚀", "title": "Introduction aux Métiers en Belgique"},
      {"type": "text", "content": "Les métiers (jobs) are essential for daily life in Belgium. When introducing yourself in Bruxelles or Liège, you will often say what you do. Remember: in French, we do NOT use an article (un/une) when stating our profession after the verb \"être\"!"},
      {"type": "example", "french": "Je suis médecin.", "translation": "I am a doctor."},
      {"type": "example", "french": "Il est ingénieur.", "translation": "He is an engineer."},
      
      {"type": "section_title", "emoji": "⚖️", "title": "Le Genre des Métiers (Masculin vs Féminin)"},
      {"type": "tipbox", "title": "La Règle d'Or", "content": "Most professions change their ending when a woman is doing the job. In Belgium, many formerly masculine-only titles now have established feminine forms.", "color": "purple"},
      {"type": "table", "headers": ["Terminaison Masculine", "Terminaison Féminine", "Exemple"], "rows": [
        ["-er", "-ère", "Boulanger → Boulangère"],
        ["-eur", "-euse", "Serveur → Serveuse"],
        ["-teur", "-trice", "Directeur → Directrice"],
        ["-ien", "-ienne", "Musicien → Musicienne"]
      ]},
      
      {"type": "section_title", "emoji": "🏥", "title": "Santé et Éducation (Belgique)"},
      {"type": "french_tipbox", "title": "Vocabulaire Essentiel", "frenchText": "médecin → doctor\ninfirmier / infirmière → nurse\ndentiste → dentist\npharmacien / pharmacienne → pharmacist\nprofesseur / professeure → teacher\nétudiant / étudiante → student", "color": "green"},
      
      {"type": "section_title", "emoji": "🏢", "title": "Bureau et Commerce"},
      {"type": "french_tipbox", "title": "Monde du Travail", "frenchText": "avocat / avocate → lawyer\ncomptable → accountant\nsecrétaire → secretary\ninformaticien / informaticienne → IT specialist\nvendeur / vendeuse → salesperson\nchef d'entreprise → business owner", "color": "blue"},
      
      {"type": "section_title", "emoji": "🇧🇪", "title": "Travailler en Belgique"},
      {"type": "tipbox", "title": "Le mot 'Job'", "content": "In Belgium, the word for job is often simply 'un job' (pronounced like in English) in informal contexts.", "color": "yellow"},
      {"type": "french_tipbox", "title": "Contrats Courants", "frenchText": "CDI (Contrat à Durée Indéterminée) → Permanent\nCDD (Contrat à Durée Déterminée) → Fixed-term\nActiris / Forem → Employment agencies", "color": "blue"},

      {"type": "section_title", "emoji": "💬", "title": "Phrases Utiles à Bruxelles"},
      {"type": "example", "french": "Quel est votre métier ?", "translation": "What is your profession?"},
      {"type": "example", "french": "Je travaille comme infirmière à l'hôpital Saint-Luc.", "translation": "I work as a nurse at Saint-Luc hospital."},
      {"type": "example", "french": "Elle cherche un emploi via Actiris.", "translation": "She is looking for a job via Actiris."}
    ],
  ),
];
