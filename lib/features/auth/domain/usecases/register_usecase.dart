import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../../data/repository/auth_repository_impl.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<AuthUser> execute({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    String role = 'owner',
    String shopName = 'Viyan MediCare Shop',
    String branchName = 'Main Branch',
  }) async {
    return await _repository.register(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      fullName: fullName,
      role: role,
      shopName: shopName,
      branchName: branchName,
    );
  }
}

// Injectable RegisterUseCase Provider
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repo);
});
