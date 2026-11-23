import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/catalog/domain/product_summary.dart';
import 'package:satur_app/features/catalog/presentation/widgets/product_card.dart';

void main() {
  testWidgets('ProductCard shows name and price', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 360,
            child: ProductCard(
              product: const ProductSummary(
                code: '1',
                name: 'Test Phone',
                priceGross: 476900,
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test Phone'), findsOneWidget);
    expect(find.textContaining('zł'), findsOneWidget);
  });
}
