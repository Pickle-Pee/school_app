class TeacherProfile {
  final int id;
  final String fullName;
  final String phone;
  final String subject;
  final String? email;
  final String? room;
  final String? note;

  TeacherProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.subject,
    this.email,
    this.room,
    this.note,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      email: json['email'] as String?,
      room: json['room'] as String?,
      note: json['note'] as String?,
    );
  }
}

class StudentProfile {
  final int id;
  final String fullName;
  final String phone;
  final String? className;

  StudentProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    this.className,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final classJson = json['class'] as Map<String, dynamic>?;
    return StudentProfile(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      className: classJson?['name'] as String?,
    );
  }
}

class ProfileView {
  final String role;
  final String fullName;
  final String phone;
  final String? subject;
  final String? className;
  final String? email;
  final String? room;
  final String? note;

  ProfileView({
    required this.role,
    required this.fullName,
    required this.phone,
    this.subject,
    this.className,
    this.email,
    this.room,
    this.note,
  });

  bool get isTeacher => role == 'teacher';

  factory ProfileView.fromTeacher(TeacherProfile profile) {
    return ProfileView(
      role: 'teacher',
      fullName: profile.fullName,
      phone: profile.phone,
      subject: profile.subject,
      email: profile.email,
      room: profile.room,
      note: profile.note,
    );
  }

  factory ProfileView.fromStudent(StudentProfile profile) {
    return ProfileView(
      role: 'student',
      fullName: profile.fullName,
      phone: profile.phone,
      className: profile.className,
    );
  }
}