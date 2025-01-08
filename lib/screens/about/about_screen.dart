import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('О приложении'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Школьник',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Общее описание
            const Text(
              'Это приложение создано для облегчения процесса обучения. '
              'Учителя могут создавать тесты, экзамены, материалы, а ученики — '
              'проходить их и получать результаты.',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16),

            // Вывод версии и сборки:
            Text(
              'Версия: $_version (build $_buildNumber)',
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16),

            // Прочая информация
            const Text(
              'Разработчик:',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Александр Парамонов\n',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16),

            const Text(
              'Все права защищены © 2024 - 2025',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
