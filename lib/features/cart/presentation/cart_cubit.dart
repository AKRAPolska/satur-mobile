import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/domain/cart_repository.dart';
import 'package:satur_app/features/cart/presentation/cart_state.dart';

/// App-level cart state shared by PDP, Koszyk tab and (later) a badge.
final class CartCubit extends Cubit<CartState> {
  CartCubit(this._repository) : super(const CartInitial());

  final CartRepository _repository;

  Future<void> refresh() async {
    if (state is! CartLoaded) emit(const CartLoading());
    final result = await _repository.fetchCart();
    switch (result) {
      case Success(:final value):
        final current = state;
        emit(
          CartLoaded(
            value,
            busyItemIds: current is CartLoaded ? current.busyItemIds : const {},
            adding: current is CartLoaded && current.adding,
          ),
        );
      case Failure(:final error):
        emit(CartFailureState(error));
    }
  }

  /// Returns true on success. Re-entrant calls while an add is in flight are ignored (false).
  Future<bool> addItem(String variantCode, {int quantity = 1}) async {
    final current = state;
    if (current is CartLoaded && current.adding) return false;

    final base = current is CartLoaded ? current : const CartLoaded(null);
    emit(base.copyWith(adding: true));

    final result = await _repository.addItem(
      variantCode: variantCode,
      quantity: quantity,
    );

    final latest = state;
    final busy = latest is CartLoaded ? latest.busyItemIds : const <String>{};
    switch (result) {
      case Success(:final value):
        emit(CartLoaded(value, busyItemIds: busy));
        return true;
      case Failure():
        emit(latest is CartLoaded ? latest.copyWith(adding: false) : latest);
        return false;
    }
  }

  Future<bool> updateQuantity(String itemId, int quantity) {
    return _mutate(
      itemId,
      () => _repository.updateQuantity(itemId: itemId, quantity: quantity),
    );
  }

  Future<bool> removeItem(String itemId) {
    return _mutate(itemId, () => _repository.removeItem(itemId));
  }

  Future<void> reset() async {
    await _repository.reset();
    emit(const CartInitial());
  }

  Future<bool> _mutate(
    String itemId,
    Future<Result<Cart, CartFailure>> Function() call,
  ) async {
    final current = state;
    if (current is! CartLoaded || current.busyItemIds.contains(itemId)) {
      return false;
    }
    emit(current.copyWith(busyItemIds: {...current.busyItemIds, itemId}));

    final result = await call();

    final latest = state;
    if (latest is! CartLoaded) return result is Success; // reset() ran meanwhile
    final busy = {...latest.busyItemIds}..remove(itemId);
    switch (result) {
      case Success(:final value):
        emit(CartLoaded(value, busyItemIds: busy, adding: latest.adding));
        return true;
      case Failure():
        emit(latest.copyWith(busyItemIds: busy));
        return false;
    }
  }
}
