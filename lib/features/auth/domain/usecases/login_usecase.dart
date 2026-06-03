import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../../data/repository/auth_repository_impl.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<AuthUser> execute({required String email, required String password}) async {
    return await _repository.login(email: email, password: password);
  }
}

// Injectable LoginUseCase Provider
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return LoginUseCase(repo);
});
