import '../../domain/models/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({required String email, required String password});
  Future<AuthUser> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String role,
    required String shopName,
    required String branchName,
  });
  Future<void> logout();
  Future<AuthUser?> getSessionUser();
  Future<String?> getSessionToken();
  Future<void> saveSessionUser(AuthUser user);
  Future<void> forgotPassword({required String email});
  Future<String> verifyResetOtp({required String email, required String otp});
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });
}
