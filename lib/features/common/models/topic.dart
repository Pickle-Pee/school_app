class Topic {
  Topic({
    required this.id,
    required this.title,
    this.subject,
  });

  final int id;
  final String title;
  final String? subject;

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? json['name'] ?? 'Без названия').toString(),
      subject: json['subject']?.toString(),
    );
  }
}
