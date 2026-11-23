import 'package:satur_app/features/catalog/presentation/package:flutter/material.dart';
import 'package:satur_app/features/catalog/presentation/package:flutter_bloc/flutter_bloc.dart';
import 'package:satur_app/features/catalog/presentation/package:go_router/go_router.dart';

import 'package:satur_app/features/catalog/presentation/package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/catalog/presentation/package:satur_app/core/widgets/satur_button.dart';
import 'package:satur_app/features/catalog/presentation/package:satur_app/features/catalog/domain/money.dart';
import 'package:satur_app/features/catalog/presentation/package:satur_app/features/catalog/domain/product_detail.dart';
import 'package:satur_app/features/catalog/presentation/product_detail_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_detail_state.dart';
import 'package:satur_app/features/catalog/presentation/widgets/catalog_bottom_nav.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaturColors.surface,
      body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          return switch (state) {
            ProductDetailInitial() || ProductDetailLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ProductDetailFailureState() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nie udało się wczytać produktu'),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          context.read<ProductDetailCubit>().retry(),
                      child: const Text('Spróbuj ponownie'),
                    ),
                  ],
                ),
              ),
            ProductDetailLoaded(:final product) => _LoadedBody(product: product),
          };
        },
      ),
    );
  }
}

class _LoadedBody extends StatefulWidget {
  const _LoadedBody({required this.product});
  final ProductDetail product;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.imageUrls;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.isEmpty ? 1 : images.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, index) {
                          if (images.isEmpty) {
                            return const ColoredBox(
                              color: SaturColors.surfaceVariant,
                              child: Center(
                                child: Icon(Icons.image_outlined, size: 48),
                              ),
                            );
                          }
                          return Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: SaturColors.surfaceVariant,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () {}, // wishlist no-op
                            icon: const Icon(Icons.favorite_border),
                          ),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (i) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _page
                                      ? SaturColors.primary
                                      : SaturColors.surfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: SaturColors.onSurface,
                      ),
                    ),
                    if (product.averageRating != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Color(0xFFFFB400)),
                          const SizedBox(width: 4),
                          Text(
                            product.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (product.priceGross != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        formatPln(product.priceGross!),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SaturColors.primary,
                        ),
                      ),
                    ],
                    if (product.specs.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SaturColors.surfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Specyfikacja',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...product.specs.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: SaturColors.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(e.value),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Opis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: const TextStyle(
                          color: SaturColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white.withValues(alpha: 0.95),
          elevation: 4,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SaturButton(
                    label: 'Dodaj do koszyka',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Wkrótce')),
                      );
                    },
                  ),
                ),
                CatalogBottomNav(
                  active: CatalogTab.oferta,
                  onTap: (tab) {
                    if (tab == CatalogTab.start) {
                      context.go('/welcome');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
