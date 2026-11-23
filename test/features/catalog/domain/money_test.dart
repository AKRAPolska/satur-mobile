import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/catalog/domain/money.dart';
import 'package:satur_app/features/catalog/domain/product_summary.dart';

void main() {
  group('formatPln', () {
    test('formats grosze with thousands separator', () {
      expect(formatPln(476900), '4 769,00 zł');
      expect(formatPln(7127), '71,27 zł');
      expect(formatPln(0), '0,00 zł');
    });
  });

  group('ProductSummary', () {
    test('hasDiscount when original greater than price', () {
      const p = ProductSummary(
        code: '1',
        name: 'x',
        priceGross: 1000,
        originalPriceGross: 2000,
      );
      expect(p.hasDiscount, isTrue);
      expect(p.discountPercent, 50);
    });

    test('no discount when prices equal', () {
      const p = ProductSummary(
        code: '1',
        name: 'x',
        priceGross: 1000,
        originalPriceGross: 1000,
      );
      expect(p.hasDiscount, isFalse);
      expect(p.discountPercent, isNull);
    });
  });
}
