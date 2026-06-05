import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// User info class
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String tenantId;
  final String branchId;
  final String? avatar;
  final String subscriptionStatus;
  final String currentPeriodEnd;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.tenantId,
    required this.branchId,
    this.avatar,
    required this.subscriptionStatus,
    required this.currentPeriodEnd,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? '',
      tenantId: json['tenantId'] ?? '',
      branchId: json['branchId'] ?? '',
      avatar: json['avatar'],
      subscriptionStatus: json['subscriptionStatus'] ?? '',
      currentPeriodEnd: json['currentPeriodEnd'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'tenantId': tenantId,
      'branchId': branchId,
      'avatar': avatar,
      'subscriptionStatus': subscriptionStatus,
      'currentPeriodEnd': currentPeriodEnd,
    };
  }
}

// Authentication state
class AuthState {
  final bool isAuthenticated;
  final AuthUser? user;
  final String? token;
  final String? errorMessage;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    AuthUser? user,
    String? token,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Auth Notifier using modern standard Riverpod Notifier class
class AuthNotifier extends Notifier<AuthState> {
  late final Dio _dio;
  final _secureStorage = const FlutterSecureStorage();
  static const String _baseUrl =
      'https://medassist-backend-hryu.onrender.com/api/auth';

  @override
  AuthState build() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _tryAutoLogin();
    return AuthState();
  }

  // Auto Login
  Future<void> _tryAutoLogin() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _secureStorage.read(key: 'access_token');
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('auth_user');

      if (token != null && userString != null) {
        final userJson = jsonDecode(userString);
        state = AuthState(
          isAuthenticated: true,
          token: token,
          user: AuthUser.fromJson(userJson),
          isLoading: false,
        );
      } else {
        state = AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  // Helper helper to format Dio errors nicely
  String _formatDioError(DioException e) {
    if (e.type == DioExceptionType.receiveTimeout || 
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Server is starting or taking too long to respond. Please try again in a few seconds.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    } else {
      return e.response?.data?['error']?['message'] ?? 'Network or Server Error';
    }
  }

  // Register Method
  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    String role = 'owner',
    String shopName = 'Viyan MediCare Shop',
    String branchName = 'Main Branch',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
          'confirmPassword': confirmPassword.trim(),
          'fullName': fullName.trim(),
          'role': role,
          'shopName': shopName.trim(),
          'branchName': branchName.trim(),
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return await login(email: email, password: password);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              response.data['error']?['message'] ?? 'Registration failed',
        );
        return false;
      }
    } on DioException catch (e) {
      final errorMsg = _formatDioError(e);
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<Response> _attemptLogin(String email, String password) async {
    return await _dio.post(
      '/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
        'deviceName': 'Desktop App',
      },
    );
  }

  // Login Method
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      late Response response;
      try {
        response = await _attemptLogin(email, password);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          // Retry once on timeout
          response = await _attemptLogin(email, password);
        } else {
          rethrow;
        }
      }

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];
        final refreshToken = data['refreshToken'];
        final userData = data['user'];

        await _secureStorage.write(key: 'access_token', value: token);
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user', jsonEncode(userData));

        state = AuthState(
          isAuthenticated: true,
          token: token,
          user: AuthUser.fromJson(userData),
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              response.data['error']?['message'] ?? 'Authentication failed',
        );
        return false;
      }
    } on DioException catch (e) {
      final errorMsg = _formatDioError(e);
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Logout Method
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        await _dio.post(
          '/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user');

      state = AuthState(isAuthenticated: false);
    }
  }
}

// Global Provider for Auth
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
