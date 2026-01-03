import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:school_test_app/config.dart';
import 'package:school_test_app/theme/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Поля
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _authCodeController = TextEditingController();

  bool _isTeacher = false; // По умолчанию считаем, что ученик

  Future<void> _register() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final authCode = _authCodeController.text.trim();

    // Простейшая валидация
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Заполните имя, фамилию, email и пароль.")),
      );
      return;
    }
    if (_isTeacher && authCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите код авторизации для учителя.")),
      );
      return;
    }

    // Формируем тело запроса
    final Map<String, dynamic> body = {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "password": password,
    };
    String endpoint;

    if (_isTeacher) {
      endpoint = "/register/teacher";
      body["auth_code"] = authCode;
    } else {
      endpoint = "/register/student";
    }

    try {
      final url = Uri.parse("${Config.baseUrl}$endpoint");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Регистрация успешна
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Регистрация прошла успешно.")),
        );

        // Перенаправляем на экран логина (или сразу логиним)
        Navigator.pushNamed(context, '/login');
      } else {
        // Показываем ошибку
        try {
          final error = json.decode(response.body)["detail"];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка: $error")),
          );
        } catch (_) {
          // Если нет "detail"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Произошла ошибка: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Регистрация'),
      ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTeacher
                              ? 'Аккаунт преподавателя'
                              : 'Аккаунт ученика',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Доступ к материалам, практике и цифровым экзаменам.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isTeacher,
                    activeColor: AppTheme.accentColor,
                    onChanged: (val) => setState(() => _isTeacher = val),
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
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: "Имя",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: "Фамилия",
                        prefixIcon: Icon(Icons.person_pin_circle_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    if (_isTeacher) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _authCodeController,
                        decoration: const InputDecoration(
                          labelText: "Код авторизации (для учителя)",
                          prefixIcon: Icon(Icons.verified_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _register,
                      icon: const Icon(Icons.person_add_alt_1),
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
