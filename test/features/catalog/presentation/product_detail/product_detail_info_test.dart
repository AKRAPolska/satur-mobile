import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_detail_info.dart';

Widget _wrap(ProductDetail p) =>
    MaterialApp(home: Scaffold(body: ProductDetailInfo(product: p)));

void main() {
  testWidgets('discounted product shows struck-through original and -N% pill',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProductDetail(
          code: '1',
          name: 'Maxi Cosi',
          priceGross: 7127,
          originalPriceGross: 8000,
        ),
      ),
    );

    expect(find.text('71,27 zł'), findsOneWidget);
    final original = tester.widget<Text>(find.text('80,00 zł'));
    expect(original.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('-11%'), findsOneWidget);
  });

  testWidgets('non-discounted product shows the price only', (tester) async {
    await tester.pumpWidget(
      _wrap(const ProductDetail(code: '1', name: 'x', priceGross: 7127)),
    );

    expect(find.text('71,27 zł'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('zł'), findsOneWidget);
  });
}
