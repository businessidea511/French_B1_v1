class LessonTopic {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String description;
  final List<dynamic>? content; 
  final Map<String, dynamic>? metadata;

  const LessonTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
    this.content,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'description': description,
      'content': content,
      'metadata': metadata,
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
      metadata: json['metadata'],
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
