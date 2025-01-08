import 'package:flutter/material.dart';
import 'package:school_test_app/widgets/app_navigator.dart';

class RegistrationSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appHeader('Регистрация'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/book.png', height: 100),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register/teacher');
                },
                child: const Text('Преподаватель'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register/student');
                },
                child: const Text('Ученик'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
