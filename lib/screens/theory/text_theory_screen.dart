import 'package:flutter/material.dart';
import 'package:school_test_app/theme/app_theme.dart';

class TextTheoryScreen extends StatelessWidget {
  final String title;
  final String text;

  const TextTheoryScreen({
    Key? key,
    required this.title,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: text.trim().isEmpty
                ? const Text('Текст материала отсутствует.')
                : Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
          ),
        ),
      ),
    );
  }
}
