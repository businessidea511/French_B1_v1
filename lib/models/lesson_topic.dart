class LessonTopic {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String description;

  const LessonTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
  });
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
