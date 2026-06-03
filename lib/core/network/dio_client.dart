import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/datasource/auth_local_datasource.dart';

class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trigger() => state = true;
  void reset() => state = false;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, bool>(SessionExpiredNotifier.new);

class DioClient {
  static const String baseUrl = 'https://medassist-backend-hryu.onrender.com';

  static Dio createDio({List<Interceptor>? interceptors}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (interceptors != null) {
      dio.interceptors.addAll(interceptors);
    }

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    return dio;
  }
}

class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _localDataSource;
  final Ref _ref;
  final Dio _refreshDio;

  AuthInterceptor(this._localDataSource, this._ref)
      : _refreshDio = Dio(
          BaseOptions(
            baseUrl: DioClient.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    if (kDebugMode) {
      _refreshDio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }
  }

  Future<String?>? _refreshFuture;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _localDataSource.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    // Do not attempt to refresh for authentication endpoints
    if (requestOptions.path.contains('/api/auth/login') ||
        requestOptions.path.contains('/api/auth/refresh') ||
        requestOptions.path.contains('/api/auth/register')) {
      return handler.next(err);
    }

    if (response?.statusCode == 401) {
      try {
        final newAccessToken = await _getValidAccessToken();
        if (newAccessToken != null) {
          // Update the authorization header for retried request
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          
          final retryDio = Dio(
            BaseOptions(
              baseUrl: DioClient.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
          
          final retryResponse = await retryDio.request(
            requestOptions.path,
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
              contentType: requestOptions.contentType,
              extra: requestOptions.extra,
            ),
          );
          
          return handler.resolve(retryResponse);
        }
      } catch (refreshErr) {
        if (refreshErr is DioException && refreshErr.response?.statusCode == 401) {
          await _localDataSource.clearAll();
          _ref.read(sessionExpiredProvider.notifier).trigger();
        }
        return handler.next(err);
      }
    }

    super.onError(err, handler);
  }

  Future<String?> _getValidAccessToken() {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _executeTokenRefresh();
    return _refreshFuture!.whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _executeTokenRefresh() async {
    final refreshToken = await _localDataSource.getRefreshToken();
    if (refreshToken == null) {
      await _localDataSource.clearAll();
      _ref.read(sessionExpiredProvider.notifier).trigger();
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        message: 'No refresh token available',
      );
    }

    final response = await _refreshDio.post(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
      final data = response.data['data'];
      final newAccessToken = data['token'];
      final newRefreshToken = data['refreshToken'];

      if (newAccessToken != null) {
        await _localDataSource.saveToken(newAccessToken);
      }
      if (newRefreshToken != null) {
        await _localDataSource.saveRefreshToken(newRefreshToken);
      }

      return newAccessToken;
    } else {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        response: response,
        message: 'Token refresh failed',
      );
    }
  }
}

// Centralized Injectable Dio Provider
final dioProvider = Provider<Dio>((ref) {
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  final authInterceptor = AuthInterceptor(localDataSource, ref);
  return DioClient.createDio(interceptors: [authInterceptor]);
});
