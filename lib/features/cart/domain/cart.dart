import 'package:equatable/equatable.dart';

import 'package:satur_app/features/cart/domain/cart_item.dart';

final class Cart extends Equatable {
  const Cart({
    required this.tokenValue,
    this.items = const [],
    required this.itemsTotal,
    required this.shippingTotal,
    required this.total,
  });

  final String tokenValue;
  final List<CartItem> items;

  /// Grosze.
  final int itemsTotal;
  final int shippingTotal;
  final int total;

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [tokenValue, items, itemsTotal, shippingTotal, total];
}
