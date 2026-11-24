import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';

abstract interface class CartRepository {
  /// `Success(null)` when no token is stored or the server says the cart no longer exists.
  Future<Result<Cart?, CartFailure>> fetchCart();

  Future<Result<Cart, CartFailure>> addItem({
    required String variantCode,
    int quantity = 1,
  });

  Future<Result<Cart, CartFailure>> updateQuantity({
    required String itemId,
    required int quantity,
  });

  Future<Result<Cart, CartFailure>> removeItem(String itemId);

  /// Drops the stored token (logout).
  Future<void> reset();
}
