import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_detail_footer.dart';

import '../../../cart/support/fake_cart_repository.dart';

Future<void> _pumpFooter(
  WidgetTester tester,
  FakeCartRepository repo, {
  String? variantCode = '58288-variant-0',
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ProductDetailFooter(variantCode: variantCode),
          ),
        ),
      ),
      GoRoute(path: '/cart', builder: (_, _) => const Text('cart-page')),
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
  testWidgets('tap adds the default variant and shows success SnackBar with Koszyk action',
      (tester) async {
    final repo = FakeCartRepository()..addResult = Success(testCart());
    await _pumpFooter(tester, repo);

    await tester.tap(find.text('Dodaj do koszyka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.addCalls, ['58288-variant-0']);
    expect(find.text('Dodano do koszyka'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Koszyk'));
    await tester.pumpAndSettle();
    expect(find.text('cart-page'), findsOneWidget);
  });

  testWidgets('failure shows the error SnackBar', (tester) async {
    final repo = FakeCartRepository()
      ..addResult = const Failure(CartHttpFailure(statusCode: 422));
    await _pumpFooter(tester, repo);

    await tester.tap(find.text('Dodaj do koszyka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nie udało się dodać do koszyka'), findsOneWidget);
    expect(find.text('Dodano do koszyka'), findsNothing);
  });

  testWidgets('button is disabled when the product has no default variant',
      (tester) async {
    final repo = FakeCartRepository();
    await _pumpFooter(tester, repo, variantCode: null);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.text('Dodaj do koszyka'), warnIfMissed: false);
    expect(repo.addCalls, isEmpty);
  });

  testWidgets('shows a spinner and blocks a second tap while adding',
      (tester) async {
    final gate = Completer<void>();
    final repo = FakeCartRepository()
      ..addResult = Success(testCart())
      ..gate = gate;
    await _pumpFooter(tester, repo);

    await tester.tap(find.text('Dodaj do koszyka'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Dodaj do koszyka'), findsNothing);
    expect(repo.addCalls, hasLength(1));

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
