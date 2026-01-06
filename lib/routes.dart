import 'package:flutter/material.dart';
import 'package:school_test_app/features/student/student_shell.dart';
import 'package:school_test_app/features/teacher/teacher_shell.dart';
import 'package:school_test_app/screens/auth/login_screen.dart';
import 'package:school_test_app/screens/strart_screen.dart';
import 'package:school_test_app/services/auth_service.dart';

Map<String, WidgetBuilder> get appRoutes => {
      '/': (_) => StartScreen(),
      '/login': (_) => const LoginScreen(),
      '/shell': (_) => const RoleGate(),
      '/teacher': (_) => const TeacherShell(),
      '/student': (_) => const StudentShell(),
    };

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return _RoleGateBody();
  }
}

class _RoleGateBody extends StatefulWidget {
  @override
  State<_RoleGateBody> createState() => _RoleGateBodyState();
}

class _RoleGateBodyState extends State<_RoleGateBody> {
  late Future<_RoleCheck> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _resolveRole();
  }

  Future<_RoleCheck> _resolveRole() async {
    final token = await AuthService.getAccessToken();
    if (token == null || token.isEmpty) {
      return const _RoleCheck(hasToken: false);
    }
    final role = await AuthService.getUserType();
    return _RoleCheck(hasToken: true, role: role);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RoleCheck>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data?.role;
        if (role == 'teacher') {
          return const TeacherShell();
        }
        if (role == 'student') {
          return const StudentShell();
        }
        if (snapshot.data?.hasToken == true) {
          return _RoleGateError(
            onRetry: () {
              setState(() {
                _roleFuture = _resolveRole();
              });
            },
            onLogout: () async {
              await AuthService.clearSession();
              setState(() {
                _roleFuture = _resolveRole();
              });
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}

class _RoleGateError extends StatelessWidget {
  const _RoleGateError({
    required this.onRetry,
    required this.onLogout,
  });

  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Не удалось определить роль пользователя.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCheck {
  const _RoleCheck({required this.hasToken, this.role});

  final bool hasToken;
  final String? role;
}
