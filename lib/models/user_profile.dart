// models/user_profile.dart
class UserProfile {
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  UserProfile({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json["email"] as String,
      firstName: json["first_name"] as String,
      lastName: json["last_name"] as String,
      role: json["role"] as String,
    );
  }
}
