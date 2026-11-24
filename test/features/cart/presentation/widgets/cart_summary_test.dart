import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_summary.dart';

Widget _wrap(Cart cart) =>
    MaterialApp(home: Scaffold(body: CartSummary(cart: cart)));

void main() {
  testWidgets('shows items total, shipping and grand total', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Cart(
          tokenValue: 't',
          itemsTotal: 7127,
          shippingTotal: 1000,
          total: 8127,
        ),
      ),
    );

    expect(find.text('Wartość produktów'), findsOneWidget);
    expect(find.text('71,27 zł'), findsOneWidget);
    expect(find.text('Dostawa'), findsOneWidget);
    expect(find.text('10,00 zł'), findsOneWidget);
    expect(find.text('Razem'), findsOneWidget);
    expect(find.text('81,27 zł'), findsOneWidget);
  });

  testWidgets('hides the shipping row when shippingTotal is 0', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Cart(
          tokenValue: 't',
          itemsTotal: 7127,
          shippingTotal: 0,
          total: 7127,
        ),
      ),
    );

    expect(find.text('Dostawa'), findsNothing);
    expect(find.text('Razem'), findsOneWidget);
  });
}
