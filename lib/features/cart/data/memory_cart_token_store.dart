import 'package:satur_app/features/cart/domain/cart_token_store.dart';

/// In-memory [CartTokenStore] for tests and non-persistent environments.
final class MemoryCartTokenStore implements CartTokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}
