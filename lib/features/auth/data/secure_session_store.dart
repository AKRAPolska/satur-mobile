import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/domain/session_store.dart';

final class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth.token';
  static const _emailKey = 'auth.email';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final email = await _storage.read(key: _emailKey);
    if (token == null || token.isEmpty || email == null || email.isEmpty) {
      return null;
    }
    return AuthSession(token: token, email: email);
  }

  @override
  Future<String?> readToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  @override
  Future<void> save(AuthSession session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _emailKey, value: session.email);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }
}
