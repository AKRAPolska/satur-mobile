import 'package:equatable/equatable.dart';

import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';

sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => const [];
}

final class CartInitial extends CartState {
  const CartInitial();
}

final class CartLoading extends CartState {
  const CartLoading();
}

/// [cart] == null means "no cart yet" (shown as empty).
final class CartLoaded extends CartState {
  const CartLoaded(
    this.cart, {
    this.busyItemIds = const {},
    this.adding = false,
  });

  final Cart? cart;
  final Set<String> busyItemIds;
  final bool adding;

  CartLoaded copyWith({Set<String>? busyItemIds, bool? adding}) => CartLoaded(
        cart,
        busyItemIds: busyItemIds ?? this.busyItemIds,
        adding: adding ?? this.adding,
      );

  @override
  List<Object?> get props => [cart, busyItemIds, adding];
}

final class CartFailureState extends CartState {
  const CartFailureState(this.failure);

  final CartFailure failure;

  @override
  List<Object?> get props => [failure];
}
