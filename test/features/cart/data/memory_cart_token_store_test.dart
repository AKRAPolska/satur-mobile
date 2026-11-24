import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/data/memory_cart_token_store.dart';

void main() {
  test('read returns null until saved, then the token, then null after clear',
      () async {
    final store = MemoryCartTokenStore();
    expect(await store.read(), isNull);

    await store.save('tok-1');
    expect(await store.read(), 'tok-1');

    await store.clear();
    expect(await store.read(), isNull);
  });
}
