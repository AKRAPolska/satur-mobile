import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_empty_view.dart';

void main() {
  testWidgets('shows message and browse button that fires the callback',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartEmptyView(onBrowse: () => taps++)),
      ),
    );

    expect(find.text('Twój koszyk jest pusty'), findsOneWidget);
    await tester.tap(find.text('Przeglądaj ofertę'));
    expect(taps, 1);
  });
}
