import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';

CartItem _item(String id, int qty) => CartItem(
      id: id,
      variantCode: 'v-$id',
      productName: 'P$id',
      quantity: qty,
      unitPrice: 100,
      total: 100 * qty,
    );

void main() {
  test('isEmpty and itemCount reflect items', () {
    const empty = Cart(
      tokenValue: 't',
      itemsTotal: 0,
      shippingTotal: 0,
      total: 0,
    );
    final full = Cart(
      tokenValue: 't',
      items: [_item('1', 2), _item('2', 3)],
      itemsTotal: 500,
      shippingTotal: 0,
      total: 500,
    );

    expect(empty.isEmpty, isTrue);
    expect(empty.itemCount, 0);
    expect(full.isEmpty, isFalse);
    expect(full.itemCount, 5);
  });

  test('carts with equal fields are equal', () {
    Cart build() => Cart(
          tokenValue: 't',
          items: [_item('1', 1)],
          itemsTotal: 100,
          shippingTotal: 0,
          total: 100,
        );
    expect(build(), build());
  });
}
