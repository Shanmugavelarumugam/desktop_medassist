import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repository/auth_repository.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../state/auth_state.dart';

class AuthController extends Notifier<AuthState> {
  late final LoginUseCase _loginUseCase;
  late final RegisterUseCase _registerUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _loginUseCase = ref.watch(loginUseCaseProvider);
    _registerUseCase = ref.watch(registerUseCaseProvider);
    _logoutUseCase = ref.watch(logoutUseCaseProvider);
    _repository = ref.watch(authRepositoryProvider);

    return const AuthState();
  }

  Future<void> initialize() async {
    await _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.getSessionUser();
      final token = await _repository.getSessionToken();
      if (user != null && token != null) {
        state = AuthState(
          isAuthenticated: true,
          user: user,
          token: token,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _loginUseCase.execute(email: email, password: password);
      final token = await _repository.getSessionToken();

      state = AuthState(
        isAuthenticated: true,
        user: user,
        token: token,
        isLoading: false,
      );

      // Print statements for debugging state updates
      print("LOGIN SUCCESS");
      print("isAuthenticated: ${state.isAuthenticated}");
      print("User FullName: ${state.user?.fullName}");

      return true;
    } catch (e) {
      print("LOGIN ERROR IN CONTROLLER: $e");
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

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
      final user = await _registerUseCase.execute(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
        role: role,
        shopName: shopName,
        branchName: branchName,
      );
      final token = await _repository.getSessionToken();

      state = AuthState(
        isAuthenticated: true,
        user: user,
        token: token,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _logoutUseCase.execute();
    } catch (_) {
      // Local session is cleared even if network fails
    } finally {
      state = const AuthState(isAuthenticated: false);
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.forgotPassword(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<String?> verifyResetOtp({required String email, required String otp}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resetToken = await _repository.verifyResetOtp(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
      return resetToken;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> resetPassword({required String resetToken, required String newPassword}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.resetPassword(resetToken: resetToken, newPassword: newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

// Global Injectable AuthController Provider
final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
