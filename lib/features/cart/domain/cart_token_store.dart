abstract interface class CartTokenStore {
  Future<String?> read();

  Future<void> save(String token);

  Future<void> clear();
}
