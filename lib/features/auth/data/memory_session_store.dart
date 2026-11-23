import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/domain/session_store.dart';

/// In-memory [SessionStore] for tests and non-persistent environments.
final class MemorySessionStore implements SessionStore {
  AuthSession? _session;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<String?> readToken() async => _session?.token;

  @override
  Future<void> save(AuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}
