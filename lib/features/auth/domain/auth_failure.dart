sealed class AuthFailure {
  const AuthFailure();
}

final class AuthInvalidCredentialsFailure extends AuthFailure {
  const AuthInvalidCredentialsFailure();
}

final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure([this.message]);
  final String? message;
}

final class AuthHttpFailure extends AuthFailure {
  const AuthHttpFailure({required this.statusCode, this.message});
  final int statusCode;
  final String? message;
}

final class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure([this.message]);
  final String? message;
}
