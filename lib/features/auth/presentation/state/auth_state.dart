import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/auth_user.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    AuthUser? user,
    String? token,
    String? errorMessage,
    @Default(false) bool isLoading,
  }) = _AuthState;
}
