import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/product_detail_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/product_detail_state.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_pinned_app_bar.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_description_section.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_detail_footer.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_detail_info.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_image_gallery.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_specs_section.dart';

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
            ProductDetailFailureState() => const _DetailError(),
            ProductDetailLoaded(:final product) =>
              _ProductDetailLoaded(product: product),
          };
        },
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nie udało się wczytać produktu'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<ProductDetailCubit>().retry(),
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailLoaded extends StatelessWidget {
  const _ProductDetailLoaded({required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              CatalogPinnedAppBar(title: product.name),
              SliverToBoxAdapter(
                child: ProductImageGallery(imageUrls: product.imageUrls),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ProductDetailInfo(product: product),
                    if (product.specs.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ProductSpecsSection(specs: product.specs),
                    ],
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ProductDescriptionSection(
                        description: product.description,
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
        const ProductDetailFooter(),
      ],
    );
  }
}
