// services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/models/user_profile.dart';

class ProfileService {
  final String baseUrl;

  ProfileService(this.baseUrl);

  Future<UserProfile> getMe() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception("No access token. User not authorized?");
    }

    final url = Uri.parse('$baseUrl/me');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserProfile.fromJson(data);
    } else {
      throw Exception("Failed to load user profile. Status code: ${response.statusCode}");
    }
  }
}
