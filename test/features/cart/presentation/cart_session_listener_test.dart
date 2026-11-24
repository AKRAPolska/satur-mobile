import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/auth/data/memory_session_store.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_session_listener.dart';

import '../support/fake_cart_repository.dart';

void main() {
  const session = AuthSession(token: 't', email: 'a@b.pl');

  Future<(SessionCubit, MemorySessionStore, FakeCartRepository)> pump(
    WidgetTester tester,
  ) async {
    final store = MemorySessionStore();
    final sessionCubit = SessionCubit(store);
    final repo = FakeCartRepository();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: sessionCubit),
          BlocProvider<CartCubit>.value(value: CartCubit(repo)),
        ],
        child: const MaterialApp(
          home: CartSessionListener(child: SizedBox()),
        ),
      ),
    );
    return (sessionCubit, store, repo);
  }

  testWidgets('resets the cart when the session goes from set to null',
      (tester) async {
    final (sessionCubit, _, repo) = await pump(tester);

    await sessionCubit.setSession(session);
    await tester.pump();
    expect(repo.resetCalls, 0); // login keeps the cart token

    await sessionCubit.clear();
    await tester.pump();
    expect(repo.resetCalls, 1);
  });

  testWidgets('does not reset on cold-start hydrate', (tester) async {
    final (sessionCubit, store, repo) = await pump(tester);
    await store.save(session);

    await sessionCubit.hydrate(); // null -> session
    await tester.pump();

    expect(repo.resetCalls, 0);
  });
}
