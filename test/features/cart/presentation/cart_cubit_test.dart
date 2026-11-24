import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_state.dart';

import '../support/fake_cart_repository.dart';

void main() {
  late FakeCartRepository repo;
  late CartCubit cubit;

  setUp(() {
    repo = FakeCartRepository();
    cubit = CartCubit(repo);
  });

  tearDown(() => cubit.close());

  Future<List<CartState>> record(Future<void> Function() action) async {
    final emitted = <CartState>[];
    final sub = cubit.stream.listen(emitted.add);
    await action();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return emitted;
  }

  test('refresh with a stored cart emits loading then loaded', () async {
    repo.fetchResult = Success(testCart());

    final states = await record(cubit.refresh);

    expect(states, [const CartLoading(), CartLoaded(testCart())]);
  });

  test('refresh with no cart emits loaded(null)', () async {
    final states = await record(cubit.refresh);

    expect(states, [const CartLoading(), const CartLoaded(null)]);
  });

  test('refresh failure emits CartFailureState', () async {
    repo.fetchResult = const Failure(CartNetworkFailure());

    await cubit.refresh();

    expect(cubit.state, isA<CartFailureState>());
    expect((cubit.state as CartFailureState).failure, isA<CartNetworkFailure>());
  });

  test('refresh while already loaded does not flash the loading state',
      () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();
    // A different cart: Bloc drops emits of a state equal to the current one.
    final emptied = testCart(items: const []);
    repo.fetchResult = Success(emptied);

    final states = await record(cubit.refresh);

    expect(states, [CartLoaded(emptied)]);
  });

  test('addItem success sets adding then emits the new cart and returns true',
      () async {
    repo.addResult = Success(testCart());

    late bool ok;
    final states = await record(() async {
      ok = await cubit.addItem('58288-variant-0');
    });

    expect(ok, isTrue);
    expect(repo.addCalls, ['58288-variant-0']);
    expect(states, [const CartLoaded(null, adding: true), CartLoaded(testCart())]);
  });

  test('addItem failure clears adding and returns false', () async {
    repo.addResult = const Failure(CartHttpFailure(statusCode: 422));

    final ok = await cubit.addItem('x');

    expect(ok, isFalse);
    expect(cubit.state, const CartLoaded(null));
  });

  test('addItem is ignored while another add is in flight', () async {
    repo.addResult = Success(testCart());
    final gate = Completer<void>();
    repo.gate = gate;

    final first = cubit.addItem('a');
    final second = await cubit.addItem('a');
    gate.complete();

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repo.addCalls, ['a']);
  });

  test('updateQuantity marks the item busy, then emits the new cart', () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();
    final updated = testCart(
      items: const [
        CartItem(
          id: '101',
          variantCode: '58288-variant-0',
          productName: 'Maxi Cosi',
          variantName: 'Classic Black',
          quantity: 2,
          unitPrice: 7127,
          total: 14254,
        ),
      ],
    );
    repo.updateResult = Success(updated);
    final gate = Completer<void>();
    repo.gate = gate;

    final future = cubit.updateQuantity('101', 2);
    expect((cubit.state as CartLoaded).busyItemIds, {'101'});
    expect(await cubit.updateQuantity('101', 3), isFalse); // re-entrant ignored
    gate.complete();

    expect(await future, isTrue);
    expect(cubit.state, CartLoaded(updated));
    expect(repo.updateCalls, [('101', 2)]);
  });

  test('updateQuantity failure keeps the old cart and clears busy', () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();
    repo.updateResult = const Failure(CartNetworkFailure());

    final ok = await cubit.updateQuantity('101', 2);

    expect(ok, isFalse);
    expect(cubit.state, CartLoaded(testCart()));
  });

  test('updateQuantity before the cart is loaded returns false', () async {
    expect(await cubit.updateQuantity('101', 2), isFalse);
    expect(repo.updateCalls, isEmpty);
  });

  test('removeItem success emits the new cart', () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();
    final empty = testCart(items: const []);
    repo.removeResult = Success(empty);

    final ok = await cubit.removeItem('101');

    expect(ok, isTrue);
    expect(repo.removeCalls, ['101']);
    expect(cubit.state, CartLoaded(empty));
  });

  test('reset clears the repository and returns to initial', () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();

    await cubit.reset();

    expect(repo.resetCalls, 1);
    expect(cubit.state, const CartInitial());
  });
}
