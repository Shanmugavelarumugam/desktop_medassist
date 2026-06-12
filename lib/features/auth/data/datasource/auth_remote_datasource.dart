import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

abstract class AuthRemoteDataSource {
  Future<Response> login({required String email, required String password});
  Future<Response> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String role,
    required String shopName,
    required String branchName,
  });
  Future<void> logout({required String token});
  Future<Response> forgotPassword({required String email});
  Future<Response> verifyResetOtp({required String email, required String otp});
  Future<Response> resetPassword({
    required String resetToken,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      '/api/auth/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
        'deviceName': 'Desktop App',
      },
    );
  }

  @override
  Future<Response> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String role,
    required String shopName,
    required String branchName,
  }) async {
    return await _dio.post(
      '/api/auth/register',
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
  }

  @override
  Future<void> logout({required String token}) async {
    await _dio.post(
      '/api/auth/logout',
      data: {},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  @override
  Future<Response> forgotPassword({required String email}) async {
    return await _dio.post(
      '/api/auth/forgot-password',
      data: {'email': email.trim().toLowerCase()},
    );
  }

  @override
  Future<Response> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    return await _dio.post(
      '/api/auth/verify-reset-otp',
      data: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
    );
  }

  @override
  Future<Response> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    return await _dio.post(
      '/api/auth/reset-password',
      data: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }
}

// Injectable Remote Data Source Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSourceImpl(dio);
});
