import 'package:flutter/material.dart';
import 'package:school_test_app/theme/app_theme.dart';
import 'package:school_test_app/services/student_api_service.dart';
import 'package:school_test_app/utils/session_manager.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({Key? key}) : super(key: key);

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  bool _loading = true; // загрузка классов
  bool _submitting = false; // отправка формы
  String? _error;

  // справочник классов
  List<dynamic> _classes = [];
  int? _selectedClassId;

  // поля формы
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final classes = await StudentApiService.getClassGroups();
      setState(() {
        _classes = classes;
        _selectedClassId = classes.isNotEmpty
            ? ((classes.first as Map)["id"] as num).toInt()
            : null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _classLabel(Map<String, dynamic> c) {
    final name = c["name"]?.toString();
    if (name != null && name.isNotEmpty) return name;
    final grade = c["grade"]?.toString() ?? "";
    final letter = c["letter"]?.toString() ?? "";
    return "$grade$letter";
  }

  String? _validate() {
    final fullName = _fullNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    if (fullName.isEmpty) return "Введите ФИО";
    if (phone.isEmpty) return "Введите телефон";
    if (_selectedClassId == null) return "Выберите класс";
    if (pass.length < 4) return "Пароль должен быть не короче 4 символов";
    return null;
  }

  Future<void> _submit() async {
    final v = _validate();
    if (v != null) {
      setState(() => _error = v);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await StudentApiService.registerStudent(
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        classGroupId: _selectedClassId!,
      );

      final token = res["access_token"]?.toString();
      if (token == null || token.isEmpty) {
        throw Exception("Сервер не вернул access_token");
      }

      await SessionManager.saveAccessToken(token);

      // 🔎 Быстрый дебаг: убедиться, что реально сохранилось
      final saved = await SessionManager.getAccessToken();
      debugPrint("SAVED TOKEN: $saved");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Регистрация успешна")),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Регистрация ученика")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Создайте аккаунт",
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Заполните данные и выберите класс",
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (_error != null) _ErrorCard(error: _error!, onRetry: _init),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Данные", style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fullNameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "ФИО",
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Телефон",
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const _InlineLoading(text: "Загрузка классов…")
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedClassId,
                          items: _classes.map((c) {
                            final m = Map<String, dynamic>.from(c as Map);
                            final id = (m["id"] as num).toInt();
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(_classLabel(m)),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedClassId = v),
                          decoration: const InputDecoration(
                            labelText: "Класс",
                            prefixIcon: Icon(Icons.school_rounded),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Email (опционально)",
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: "Пароль",
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: (_loading || _submitting) ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(_submitting
                            ? "Регистрируем…"
                            : "Зарегистрироваться"),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        child: const Text("Уже есть аккаунт? Назад"),
                      ),
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

class _InlineLoading extends StatelessWidget {
  final String text;
  const _InlineLoading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                SizedBox(width: 10),
                Text("Ошибка", style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Text(error),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Повторить"),
            ),
          ],
        ),
      ),
    );
  }
}
