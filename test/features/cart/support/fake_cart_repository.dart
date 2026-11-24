import 'dart:async';

import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/domain/cart_repository.dart';

const kTestItem = CartItem(
  id: '101',
  variantCode: '58288-variant-0',
  productName: 'Maxi Cosi',
  variantName: 'Classic Black',
  quantity: 1,
  unitPrice: 7127,
  total: 7127,
);

/// Shipping fixed at 1000 grosze (live API adds a shipment as soon as a cart has items).
Cart testCart({List<CartItem> items = const [kTestItem]}) {
  final itemsTotal = items.fold<int>(0, (sum, i) => sum + i.total);
  return Cart(
    tokenValue: 'tok-1',
    items: items,
    itemsTotal: itemsTotal,
    shippingTotal: 1000,
    total: itemsTotal + 1000,
  );
}

final class FakeCartRepository implements CartRepository {
  Result<Cart?, CartFailure> fetchResult = const Success(null);
  Result<Cart, CartFailure> addResult = const Failure(CartUnknownFailure());
  Result<Cart, CartFailure> updateResult = const Failure(CartUnknownFailure());
  Result<Cart, CartFailure> removeResult = const Failure(CartUnknownFailure());

  /// When set, mutating calls wait on it (to observe in-flight state).
  Completer<void>? gate;

  int fetchCalls = 0;
  int resetCalls = 0;
  final addCalls = <String>[];
  final updateCalls = <(String, int)>[];
  final removeCalls = <String>[];

  @override
  Future<Result<Cart?, CartFailure>> fetchCart() async {
    fetchCalls++;
    return fetchResult;
  }

  @override
  Future<Result<Cart, CartFailure>> addItem({
    required String variantCode,
    int quantity = 1,
  }) async {
    addCalls.add(variantCode);
    await gate?.future;
    return addResult;
  }

  @override
  Future<Result<Cart, CartFailure>> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    updateCalls.add((itemId, quantity));
    await gate?.future;
    return updateResult;
  }

  @override
  Future<Result<Cart, CartFailure>> removeItem(String itemId) async {
    removeCalls.add(itemId);
    await gate?.future;
    return removeResult;
  }

  @override
  Future<void> reset() async {
    resetCalls++;
  }
}
