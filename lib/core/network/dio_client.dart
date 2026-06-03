import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DioClient {
  static const String baseUrl = 'https://medassist-backend-hryu.onrender.com';

  static Dio createDio() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )..interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
  }
}

// Centralized Injectable Dio Provider
final dioProvider = Provider<Dio>((ref) {
  return DioClient.createDio();
});
