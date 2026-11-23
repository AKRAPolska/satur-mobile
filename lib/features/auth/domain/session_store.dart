import 'package:satur_app/features/auth/domain/auth_session.dart';

abstract interface class SessionStore {
  Future<AuthSession?> read();

  Future<String?> readToken();

  Future<void> save(AuthSession session);

  Future<void> clear();
}
