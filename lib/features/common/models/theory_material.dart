class TheoryMaterial {
  TheoryMaterial({
    required this.id,
    required this.title,
    this.content,
    this.fileUrl,
    this.topicId,
    this.classId,
  });

  final int id;
  final String title;
  final String? content;
  final String? fileUrl;
  final int? topicId;
  final int? classId;

  factory TheoryMaterial.fromJson(Map<String, dynamic> json) {
    return TheoryMaterial(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? json['name'] ?? 'Без названия').toString(),
      content: json['content']?.toString(),
      fileUrl: json['file_url']?.toString() ?? json['file']?.toString(),
      topicId: (json['topic_id'] as num?)?.toInt(),
      classId: (json['class_id'] as num?)?.toInt(),
    );
  }
}
