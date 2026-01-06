class ClassGroup {
  ClassGroup({
    required this.id,
    required this.grade,
    required this.letter,
  });

  final int id;
  final int grade;
  final String letter;

  String get title => '$grade$letter';

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    return ClassGroup(
      id: json['id'] as int,
      grade: json['grade'] as int,
      letter: (json['letter'] as String).toUpperCase(),
    );
  }
}
