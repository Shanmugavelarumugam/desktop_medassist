import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../domain/models/auth_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/auth_local_datasource.dart';
import '../datasource/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final String? token = data['token'];
        final String? refreshToken = data['refreshToken'];
        final dynamic rawUser = data['user'];
        if (rawUser == null || rawUser is! Map<String, dynamic>) {
          throw Exception('User data missing from server response');
        }
        final userData = AuthUser.fromJson(rawUser);

        // Persist session tokens and user data (only if present)
        if (token != null && token.isNotEmpty) {
          await _localDataSource.saveToken(token);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _localDataSource.saveRefreshToken(refreshToken);
        }
        await _localDataSource.saveUser(userData);

        return userData;
      } else {
        throw Exception(
          response.data?['error']?['message'] ?? 'Authentication failed',
        );
      }
    } on DioException catch (e) {
      developer.log("DioException in Repository: ${e.response?.data}");
      throw Exception(
        e.response?.data?['error']?['message'] ?? 'Network error',
      );
    } catch (e) {
      developer.log("Exception in Repository login: $e");
      throw Exception(e.toString());
    }
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String role,
    required String shopName,
    required String branchName,
  }) async {
    try {
      final response = await _remoteDataSource.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
        role: role,
        shopName: shopName,
        branchName: branchName,
      );

      if (response.data != null && response.data['success'] == true) {
        // Automatically perform login on successful registration
        return await login(email: email, password: password);
      } else {
        throw Exception(
          response.data?['error']?['message'] ?? 'Registration failed',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ?? 'Network or validation error',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      final token = await _localDataSource.getToken();
      if (token != null) {
        await _remoteDataSource.logout(token: token);
      }
    } catch (_) {
      // Ignore network failures on logout to allow local cleanup
    } finally {
      await _localDataSource.clearAll();
    }
  }

  @override
  Future<AuthUser?> getSessionUser() async {
    return await _localDataSource.getUser();
  }

  @override
  Future<void> saveSessionUser(AuthUser user) async {
    await _localDataSource.saveUser(user);
  }

  @override
  Future<String?> getSessionToken() async {
    return await _localDataSource.getToken();
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await _remoteDataSource.forgotPassword(email: email);
      if (response.data == null || response.data['success'] != true) {
        throw Exception(
          response.data?['error']?['message'] ??
              'Forgot password request failed',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ?? 'Network error',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _remoteDataSource.verifyResetOtp(
        email: email,
        otp: otp,
      );
      if (response.data != null && response.data['success'] == true) {
        final token = response.data['data']?['resetToken'];
        if (token == null || (token is String && token.isEmpty)) {
          throw Exception(
            'Reset token missing from backend response. Please contact support.',
          );
        }
        return token.toString();
      } else {
        throw Exception(
          response.data?['error']?['message'] ?? 'OTP verification failed',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ?? 'Network error',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _remoteDataSource.resetPassword(
        resetToken: resetToken,
        newPassword: newPassword,
      );
      if (response.data == null || response.data['success'] != true) {
        throw Exception(
          response.data?['error']?['message'] ?? 'Password reset failed',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ?? 'Network error',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

// Injectable Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final local = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(remote, local);
});
