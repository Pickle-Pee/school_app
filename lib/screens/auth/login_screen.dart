import 'package:flutter/material.dart';
import 'package:school_test_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _authCodeController = TextEditingController();

  bool _isTeacher = false;

  Future<void> _login(BuildContext context) async {
    try {
      final success = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        authCode: _isTeacher ? _authCodeController.text.trim() : null,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Авторизация успешна")),
        );
        Navigator.pushNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Неверные учетные данные")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Авторизация"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Переключатель "Я учитель / ученик"
            Row(
              children: [
                const Text("Я учитель"),
                Switch(
                  value: _isTeacher,
                  onChanged: (val) {
                    setState(() {
                      _isTeacher = val;
                    });
                  },
                ),
              ],
            ),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Пароль"),
              obscureText: true,
            ),

            // Только если учитель
            if (_isTeacher)
              TextField(
                controller: _authCodeController,
                decoration: const InputDecoration(
                  labelText: "Код авторизации",
                ),
              ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _login(context),
              child: const Text("Войти"),
            ),
          ],
        ),
      ),
    );
  }
}
