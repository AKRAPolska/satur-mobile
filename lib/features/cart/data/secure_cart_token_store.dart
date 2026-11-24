import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:satur_app/features/cart/domain/cart_token_store.dart';

final class SecureCartTokenStore implements CartTokenStore {
  SecureCartTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'cart.token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  @override
  Future<void> save(String token) => _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
