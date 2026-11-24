import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_specs_section.dart';

Widget _wrap(Map<String, String> specs) => MaterialApp(
      home: Scaffold(body: ProductSpecsSection(specs: specs)),
    );

void main() {
  testWidgets('lays specs out in two columns; odd count leaves last cell empty',
      (tester) async {
    await tester.pumpWidget(
      _wrap({'Marka': 'Maxi Cosi', 'Kolor': 'Czarny', 'Waga': '5 kg'}),
    );

    expect(find.text('Specyfikacja'), findsOneWidget);
    final marka = tester.getTopLeft(find.text('Marka'));
    final kolor = tester.getTopLeft(find.text('Kolor'));
    final waga = tester.getTopLeft(find.text('Waga'));
    expect(kolor.dy, marka.dy); // same row
    expect(kolor.dx, greaterThan(marka.dx)); // right column
    expect(waga.dy, greaterThan(marka.dy)); // next row
    expect(waga.dx, marka.dx); // left column
    expect(find.text('Maxi Cosi'), findsOneWidget);
    expect(find.text('5 kg'), findsOneWidget);
  });

  testWidgets('renders nothing when specs are empty', (tester) async {
    await tester.pumpWidget(_wrap(const {}));
    expect(find.text('Specyfikacja'), findsNothing);
  });
}
