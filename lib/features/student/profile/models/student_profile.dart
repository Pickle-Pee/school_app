class StudentProfile {
  StudentProfile({
    required this.fullName,
    required this.classGroup,
    required this.performance,
    required this.extra,
  });

  final String fullName;
  final String classGroup;
  final String performance;
  final Map<String, dynamic> extra;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      fullName: json['full_name']?.toString() ??
          json['name']?.toString() ??
          'Ученик',
      classGroup: json['class']?.toString() ??
          json['class_group']?.toString() ??
          'Класс',
      performance: json['performance']?.toString() ??
          json['average']?.toString() ??
          'Нет данных',
      extra: json,
    );
  }
}
