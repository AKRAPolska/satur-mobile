import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/core/widgets/satur_button.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_state.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_nav.dart';

class ProductDetailFooter extends StatelessWidget {
  const ProductDetailFooter({super.key, required this.variantCode});

  /// `ProductDetail.defaultVariantCode`; null disables the button.
  final String? variantCode;

  static bool _isAdding(CartState s) => s is CartLoaded && s.adding;

  Future<void> _addToCart(BuildContext context, String code) async {
    // Capture before the await: the widget may be gone when the request ends.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final added = await context.read<CartCubit>().addItem(code);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      added
          ? SnackBar(
              content: const Text('Dodano do koszyka'),
              action: SnackBarAction(
                label: 'Koszyk',
                onPressed: () => router.go('/cart'),
              ),
            )
          : const SnackBar(content: Text('Nie udało się dodać do koszyka')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = variantCode;
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: BlocBuilder<CartCubit, CartState>(
                buildWhen: (previous, current) =>
                    _isAdding(previous) != _isAdding(current),
                builder: (context, state) => SaturButton(
                  label: 'Dodaj do koszyka',
                  isLoading: _isAdding(state),
                  onPressed: code == null ? null : () => _addToCart(context, code),
                ),
              ),
            ),
            CatalogBottomNav(
              active: CatalogTab.oferta,
              onTap: (tab) => handleCatalogTabNavigation(context, tab),
            ),
          ],
        ),
      ),
    );
  }
}
