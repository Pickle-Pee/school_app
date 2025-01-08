import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:school_test_app/config.dart';

class TeacherRegistrationScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authCodeController = TextEditingController();

  TeacherRegistrationScreen({super.key});

  void registerTeacher(BuildContext context) async {
    const url = "${Config.baseUrl}/register/teacher";

    final body = {
      "email": _emailController.text,
      "password": _passwordController.text,
      "auth_code": _authCodeController.text,
    };

    final response = await http.post(Uri.parse(url),
        headers: {"Content-Type": "application/json"}, body: json.encode(body));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Учитель зарегистрирован")),
      );
      Navigator.pushNamed(context, '/login');
    } else {
      final error = json.decode(response.body)["detail"];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Регистрация учителя')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Пароль"),
              obscureText: true,
            ),
            TextField(
              controller: _authCodeController,
              decoration: InputDecoration(labelText: "Код авторизации"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => registerTeacher(context),
              child: Text("Зарегистрироваться"),
            ),
          ],
        ),
      ),
    );
  }
}
