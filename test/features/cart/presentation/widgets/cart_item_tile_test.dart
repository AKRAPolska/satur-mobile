import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_item_tile.dart';

CartItem _item({int qty = 2}) => CartItem(
      id: '101',
      variantCode: 'v',
      productName: 'Maxi Cosi',
      variantName: 'Classic Black',
      quantity: qty,
      unitPrice: 7127,
      total: 7127 * qty,
    );

Future<void> _pump(
  WidgetTester tester, {
  required CartItem item,
  bool busy = false,
  VoidCallback? onIncrement,
  VoidCallback? onDecrement,
  VoidCallback? onRemove,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CartItemTile(
          item: item,
          busy: busy,
          onIncrement: onIncrement ?? () {},
          onDecrement: onDecrement ?? () {},
          onRemove: onRemove ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows name, variant name, unit price and quantity', (tester) async {
    await _pump(tester, item: _item());

    expect(find.text('Maxi Cosi'), findsOneWidget);
    expect(find.text('Classic Black'), findsOneWidget);
    expect(find.text('71,27 zł'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget); // no imageUrl
  });

  testWidgets('stepper and remove invoke callbacks', (tester) async {
    var inc = 0, dec = 0, rem = 0;
    await _pump(
      tester,
      item: _item(),
      onIncrement: () => inc++,
      onDecrement: () => dec++,
      onRemove: () => rem++,
    );

    await tester.tap(find.byTooltip('Zwiększ ilość'));
    await tester.tap(find.byTooltip('Zmniejsz ilość'));
    await tester.tap(find.byTooltip('Usuń'));

    expect((inc, dec, rem), (1, 1, 1));
  });

  testWidgets('decrement is disabled at quantity 1', (tester) async {
    await _pump(tester, item: _item(qty: 1));

    final minus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(minus.onPressed, isNull);
  });

  testWidgets('busy row is dimmed and ignores taps', (tester) async {
    var inc = 0;
    await _pump(tester, item: _item(), busy: true, onIncrement: () => inc++);

    final dim = tester.widget<Opacity>(find.byKey(const Key('cart-item-dim')));
    expect(dim.opacity, 0.5);
    await tester.tap(find.byTooltip('Zwiększ ilość'), warnIfMissed: false);
    expect(inc, 0);
  });
}
