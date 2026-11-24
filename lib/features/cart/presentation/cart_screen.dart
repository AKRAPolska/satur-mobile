import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_state.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_empty_view.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_summary.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_nav.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().refresh();
  }

  /// `false` also covers "ignored while busy"; the tile ignores taps when busy,
  /// so in practice this only fires on real failures.
  Future<void> _mutate(Future<bool> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    if (ok) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Nie udało się zaktualizować koszyka')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return Scaffold(
      backgroundColor: SaturColors.surface,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  title: Text(
                    'Twój koszyk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SaturColors.onSurface,
                    ),
                  ),
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                ),
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) => switch (state) {
                    CartInitial() || CartLoading() => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    CartFailureState() => SliverFillRemaining(
                        hasScrollBody: false,
                        child: _CartError(onRetry: cubit.refresh),
                      ),
                    CartLoaded(cart: final c?, :final busyItemIds)
                        when !c.isEmpty =>
                      _CartList(
                        cart: c,
                        busyItemIds: busyItemIds,
                        onIncrement: (i) => _mutate(
                          () => cubit.updateQuantity(i.id, i.quantity + 1),
                        ),
                        onDecrement: (i) => _mutate(
                          () => cubit.updateQuantity(i.id, i.quantity - 1),
                        ),
                        onRemove: (i) => _mutate(() => cubit.removeItem(i.id)),
                      ),
                    CartLoaded() => SliverFillRemaining(
                        hasScrollBody: false,
                        child: CartEmptyView(
                          onBrowse: () => context.go('/products'),
                        ),
                      ),
                  },
                ),
              ],
            ),
          ),
          CatalogBottomNav(
            active: CatalogTab.koszyk,
            onTap: (tab) => handleCatalogTabNavigation(context, tab),
          ),
        ],
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({
    required this.cart,
    required this.busyItemIds,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final Cart cart;
  final Set<String> busyItemIds;
  final void Function(CartItem item) onIncrement;
  final void Function(CartItem item) onDecrement;
  final void Function(CartItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          for (final item in cart.items) ...[
            CartItemTile(
              item: item,
              busy: busyItemIds.contains(item.id),
              onIncrement: () => onIncrement(item),
              onDecrement: () => onDecrement(item),
              onRemove: () => onRemove(item),
            ),
            const SizedBox(height: 12),
          ],
          CartSummary(cart: cart),
        ]),
      ),
    );
  }
}

class _CartError extends StatelessWidget {
  const _CartError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nie udało się wczytać koszyka'),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Spróbuj ponownie')),
        ],
      ),
    );
  }
}
