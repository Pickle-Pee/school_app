class StudentModel {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;

  StudentModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }
}
