import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/auth/data/memory_session_store.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';

void main() {
  test('save, read, clear session', () async {
    final store = MemorySessionStore();

    expect(await store.read(), isNull);
    expect(await store.readToken(), isNull);

    const session = AuthSession(token: 'tok-1', email: 'a@b.pl');
    await store.save(session);

    expect(await store.read(), session);
    expect(await store.readToken(), 'tok-1');

    await store.clear();
    expect(await store.read(), isNull);
    expect(await store.readToken(), isNull);
  });
}
