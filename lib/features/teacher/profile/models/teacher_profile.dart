class TeacherProfile {
  TeacherProfile({
    required this.fullName,
    required this.subject,
    required this.extra,
  });

  final String fullName;
  final String subject;
  final Map<String, dynamic> extra;

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      fullName: json['full_name']?.toString() ??
          json['name']?.toString() ??
          'Преподаватель',
      subject: json['subject']?.toString() ?? 'Предмет',
      extra: json,
    );
  }
}
