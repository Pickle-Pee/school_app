import 'package:dio/dio.dart';
import 'package:school_test_app/config.dart';
import 'package:school_test_app/core/api/auth_interceptor.dart';
import 'package:school_test_app/core/storage/token_storage.dart';

class ApiClient {

  ApiClient({TokenStorage? tokenStorage})
      : _dio = Dio(
          BaseOptions(
            baseUrl: Config.baseUrl,
            connectTimeout: Duration(milliseconds: Config.requestTimeout),
            receiveTimeout: Duration(milliseconds: Config.requestTimeout),
            headers: const {
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors
        .add(AuthInterceptor(tokenStorage ?? const TokenStorage()));
  }

  final Dio _dio;

  Dio get client => _dio;
}
