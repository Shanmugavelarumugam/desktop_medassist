import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repository/auth_repository.dart';
import '../../data/repository/auth_repository_impl.dart';

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<void> execute() async {
    await _repository.logout();
  }
}

// Injectable LogoutUseCase Provider
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repo);
});
