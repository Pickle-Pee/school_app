class Subject {
  Subject({
    required this.name,
    this.id,
  });

  final int? id;
  final String name;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] ?? json['title'] ?? json['subject'] ?? 'Предмет')
          .toString(),
    );
  }
}
