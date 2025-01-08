// lib/screens/register/student_register.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:school_test_app/config.dart';

class StudentRegistrationScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  StudentRegistrationScreen({super.key});

  void registerStudent(BuildContext context) async {
    const url = "${Config.baseUrl}/register/student";

    final body = {
      "email": _emailController.text,
      "password": _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ученик зарегистрирован")),
        );
        Navigator.pushNamed(context, '/login');
      } else {
        final error = json.decode(response.body)["detail"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка: $error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Произошла ошибка: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Регистрация ученика')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Пароль"),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => registerStudent(context),
              child: Text("Зарегистрироваться"),
            ),
          ],
        ),
      ),
    );
  }
}
