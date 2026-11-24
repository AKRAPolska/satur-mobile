import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';

void main() {
  test('discountPercent is rounded percentage off the original price', () {
    const p = ProductDetail(
      code: '1',
      name: 'x',
      priceGross: 7127,
      originalPriceGross: 8000,
    );
    expect(p.hasDiscount, isTrue);
    expect(p.discountPercent, 11); // (8000-7127)/8000 = 10.9%
  });

  test('discountPercent is null without a discount', () {
    const same = ProductDetail(
      code: '1',
      name: 'x',
      priceGross: 7127,
      originalPriceGross: 7127,
    );
    const noOriginal = ProductDetail(code: '1', name: 'x', priceGross: 7127);
    expect(same.discountPercent, isNull);
    expect(noOriginal.discountPercent, isNull);
  });
}
