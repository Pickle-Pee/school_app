import 'package:flutter/material.dart';
import 'package:school_test_app/services/auth_service.dart';
import 'package:school_test_app/theme/app_theme.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.lock_open_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Авторизация',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Вход в цифровой класс',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isTeacher ? 'Режим преподавателя' : 'Режим ученика',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Switch(
                          value: _isTeacher,
                          activeColor: AppTheme.accentColor,
                          onChanged: (val) => setState(() => _isTeacher = val),
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Данные для входа',
                        style: theme.textTheme.headlineSmall,
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
                            labelText: "Код авторизации",
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _login(context),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text("Войти"),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
