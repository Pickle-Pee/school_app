// lib/screens/register/student_register.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:school_test_app/config.dart';
import 'package:school_test_app/theme/app_theme.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Регистрация ученика')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: const [
                  Icon(Icons.school_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Создайте доступ к практикам, теориям и экзаменам',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: "Пароль",
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => registerStudent(context),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text("Зарегистрироваться"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
