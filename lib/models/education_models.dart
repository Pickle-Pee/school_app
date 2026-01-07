class ClassItem {
  final int id;
  final int grade;
  final String letter;
  final String name;

  ClassItem({
    required this.id,
    required this.grade,
    required this.letter,
    required this.name,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      id: json['id'] as int? ?? 0,
      grade: json['grade'] as int? ?? 0,
      letter: json['letter'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class TopicItem {
  final int id;
  final String title;

  TopicItem({
    required this.id,
    required this.title,
  });

  factory TopicItem.fromJson(Map<String, dynamic> json) {
    return TopicItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
    );
  }
}

class SubjectItem {
  final String name;

  SubjectItem({required this.name});

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(name: json['name'] as String? ?? '');
  }
}
