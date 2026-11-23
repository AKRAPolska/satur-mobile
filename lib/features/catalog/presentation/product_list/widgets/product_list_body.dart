import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/features/catalog/domain/product_summary.dart';
import 'package:satur_app/features/catalog/presentation/product_list/widgets/catalog_filter_bar.dart';
import 'package:satur_app/features/catalog/presentation/product_list/widgets/catalog_section_header.dart';
import 'package:satur_app/features/catalog/presentation/product_list/widgets/product_card.dart';

/// Loaded list: header + filters + grid (+ optional load-more spinner).
class ProductListBody extends StatelessWidget {
  const ProductListBody({
    super.key,
    required this.items,
    required this.loadingMore,
    required this.scrollController,
  });

  final List<ProductSummary> items;
  final bool loadingMore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Brak produktów'));
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        const SliverToBoxAdapter(child: CatalogSectionHeader()),
        const SliverToBoxAdapter(child: CatalogFilterBar()),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = items[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/products/${product.code}'),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
        if (loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}
