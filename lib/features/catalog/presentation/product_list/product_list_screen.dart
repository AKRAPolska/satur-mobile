import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/catalog/presentation/product_list/product_list_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_list/product_list_state.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_nav.dart';
import 'package:satur_app/features/catalog/presentation/product_list/widgets/catalog_top_bar.dart';
import 'package:satur_app/features/catalog/presentation/product_list/widgets/product_list_body.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ProductListCubit>().load();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels > pos.maxScrollExtent - 400) {
      context.read<ProductListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaturColors.surfaceGray,
      body: Column(
        children: [
          const CatalogTopBar(),
          Expanded(
            child: BlocBuilder<ProductListCubit, ProductListState>(
              builder: (context, state) {
                return switch (state) {
                  ProductListInitial() || ProductListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ProductListFailureState() => const _ListError(),
                  ProductListLoaded(:final items, :final loadingMore) =>
                    ProductListBody(
                      items: items,
                      loadingMore: loadingMore,
                      scrollController: _scroll,
                    ),
                };
              },
            ),
          ),
          CatalogBottomNav(
            active: CatalogTab.oferta,
            onTap: (tab) => handleCatalogTabNavigation(context, tab),
          ),
        ],
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nie udało się wczytać oferty'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<ProductListCubit>().retry(),
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }
}
