sealed class CartFailure {
  const CartFailure();
}

final class CartNetworkFailure extends CartFailure {
  const CartNetworkFailure([this.message]);
  final String? message;
}

final class CartHttpFailure extends CartFailure {
  const CartHttpFailure({required this.statusCode, this.message});
  final int statusCode;
  final String? message;
}

final class CartUnknownFailure extends CartFailure {
  const CartUnknownFailure([this.message]);
  final String? message;
}
