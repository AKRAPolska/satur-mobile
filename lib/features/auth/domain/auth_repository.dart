import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/auth/domain/auth_failure.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';

abstract interface class AuthRepository {
  Future<Result<AuthSession, AuthFailure>> login({
    required String email,
    required String password,
  });
}
