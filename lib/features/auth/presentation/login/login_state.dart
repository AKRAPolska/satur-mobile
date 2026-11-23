import 'package:equatable/equatable.dart';

import 'package:satur_app/features/auth/domain/auth_failure.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

final class LoginIdle extends LoginState {
  const LoginIdle();
}

final class LoginSubmitting extends LoginState {
  const LoginSubmitting();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess();
}

final class LoginFailureState extends LoginState {
  const LoginFailureState(this.failure);
  final AuthFailure failure;

  @override
  List<Object?> get props => [failure];
}
