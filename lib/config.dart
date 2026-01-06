import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Базовый URL для API
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://89.23.112.33:8000';

  // Тайм-аут для запросов (в миллисекундах)
  static const int requestTimeout = 30000;

  // Дополнительные глобальные настройки
  static const bool enableLogging = true; // Для включения логирования запросов
}
