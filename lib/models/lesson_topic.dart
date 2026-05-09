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
    description: 'Learn how to talk about jobs, professions and work in French',
  ),
];
