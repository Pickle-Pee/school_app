class Assignment {
  Assignment({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.maxAttempts,
    this.topicId,
    this.classId,
  });

  final int id;
  final String title;
  final String type;
  final String? description;
  final int? maxAttempts;
  final int? topicId;
  final int? classId;

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? json['name'] ?? 'Без названия').toString(),
      type: (json['type'] ?? json['assignment_type'] ?? 'practice').toString(),
      description: json['description']?.toString(),
      maxAttempts: (json['max_attempts'] as num?)?.toInt(),
      topicId: (json['topic_id'] as num?)?.toInt(),
      classId: (json['class_id'] as num?)?.toInt(),
    );
  }
}
