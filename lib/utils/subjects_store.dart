import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/src/response.dart';
import 'package:mobx/mobx.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/utils/interceptor.dart';

part 'subjects_store.g.dart';

class SubjectsStore = _SubjectsStore with _$SubjectsStore;

abstract class _SubjectsStore with Store {
  @observable
  ObservableList<String> subjects = ObservableList<String>();

  @action
  Future<void> fetchSubjects() async {
    try {
      final response =
          await ApiInterceptor.get('${Config.baseUrl}/api/subjects');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = decodeJson(response);
        if (data is List) {
          subjects = ObservableList.of(data.cast<String>());
        } else {
          // Обработать случай, когда формат данных не соответствует ожидаемому
        }
      } else {
        // Обработать ошибочный код ответа или пустое тело ответа
      }
    } catch (e) {
      // Обработать исключения запроса или парсинга JSON
    }
  }

  static dynamic decodeJson(Response response) {
    final body = kIsWeb ? response.body : utf8.decode(response.bodyBytes);
    return json.decode(body);
  }
}

final subjectsStore = SubjectsStore();
