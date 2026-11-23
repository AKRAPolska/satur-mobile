import 'package:equatable/equatable.dart';

final class AuthSession extends Equatable {
  const AuthSession({
    required this.token,
    required this.email,
  });

  final String token;
  final String email;

  @override
  List<Object?> get props => [token, email];
}
