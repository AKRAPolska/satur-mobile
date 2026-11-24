import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_screen.dart';

import '../support/fake_cart_repository.dart';

Future<void> _pumpCart(WidgetTester tester, FakeCartRepository repo) async {
  final router = GoRouter(
    initialLocation: '/cart',
    routes: [
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      GoRoute(path: '/products', builder: (_, _) => const Text('products-page')),
    ],
  );
  await tester.pumpWidget(
    BlocProvider<CartCubit>.value(
      value: CartCubit(repo),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('refreshes on open and lists items with totals', (tester) async {
    final repo = FakeCartRepository()..fetchResult = Success(testCart());
    await _pumpCart(tester, repo);

    expect(repo.fetchCalls, 1);
    expect(find.text('Twój koszyk'), findsOneWidget);
    expect(find.text('Maxi Cosi'), findsOneWidget);
    expect(find.text('Classic Black'), findsOneWidget);
    expect(find.text('Wartość produktów'), findsOneWidget);
    expect(find.text('Dostawa'), findsOneWidget);
    expect(find.text('Razem'), findsOneWidget);
    expect(find.text('81,27 zł'), findsOneWidget); // 7127 + 1000
  });

  testWidgets('empty cart shows the empty view and browse goes to /products',
      (tester) async {
    final repo = FakeCartRepository(); // fetchResult = Success(null)
    await _pumpCart(tester, repo);

    expect(find.text('Twój koszyk jest pusty'), findsOneWidget);
    await tester.tap(find.text('Przeglądaj ofertę'));
    await tester.pumpAndSettle();
    expect(find.text('products-page'), findsOneWidget);
  });

  testWidgets('error shows retry which refetches', (tester) async {
    final repo = FakeCartRepository()
      ..fetchResult = const Failure(CartNetworkFailure());
    await _pumpCart(tester, repo);

    expect(find.text('Nie udało się wczytać koszyka'), findsOneWidget);
    repo.fetchResult = Success(testCart());
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();

    expect(repo.fetchCalls, 2);
    expect(find.text('Maxi Cosi'), findsOneWidget);
  });

  testWidgets('increment calls updateQuantity with quantity + 1', (tester) async {
    final repo = FakeCartRepository()
      ..fetchResult = Success(testCart())
      ..updateResult = Success(testCart());
    await _pumpCart(tester, repo);

    await tester.tap(find.byTooltip('Zwiększ ilość'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, [('101', 2)]);
  });

  testWidgets('remove calls removeItem', (tester) async {
    final repo = FakeCartRepository()
      ..fetchResult = Success(testCart())
      ..removeResult = Success(testCart(items: const []));
    await _pumpCart(tester, repo);

    await tester.tap(find.byTooltip('Usuń'));
    await tester.pumpAndSettle();

    expect(repo.removeCalls, ['101']);
    expect(find.text('Twój koszyk jest pusty'), findsOneWidget);
  });

  testWidgets('failed update shows a SnackBar and keeps the list', (tester) async {
    final repo = FakeCartRepository()
      ..fetchResult = Success(testCart())
      ..updateResult = const Failure(CartNetworkFailure());
    await _pumpCart(tester, repo);

    await tester.tap(find.byTooltip('Zwiększ ilość'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nie udało się zaktualizować koszyka'), findsOneWidget);
    expect(find.text('Maxi Cosi'), findsOneWidget);
  });
}
