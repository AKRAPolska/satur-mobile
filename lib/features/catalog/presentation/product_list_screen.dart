import 'package:satur_app/features/catalog/presentation/package:flutter/material.dart';
import 'package:satur_app/features/catalog/presentation/package:flutter_bloc/flutter_bloc.dart';
import 'package:satur_app/features/catalog/presentation/package:go_router/go_router.dart';

import 'package:satur_app/features/catalog/presentation/package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/catalog/presentation/package:satur_app/core/widgets/satur_logo.dart';
import 'package:satur_app/features/catalog/presentation/product_list_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_list_state.dart';
import 'package:satur_app/features/catalog/presentation/widgets/catalog_bottom_nav.dart';
import 'package:satur_app/features/catalog/presentation/widgets/product_card.dart';

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
          _TopBar(),
          Expanded(
            child: BlocBuilder<ProductListCubit, ProductListState>(
              builder: (context, state) {
                return switch (state) {
                  ProductListInitial() || ProductListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ProductListFailureState() => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Nie udało się wczytać oferty'),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                context.read<ProductListCubit>().retry(),
                            child: const Text('Spróbuj ponownie'),
                          ),
                        ],
                      ),
                    ),
                  ProductListLoaded(:final items, :final loadingMore) =>
                    items.isEmpty
                        ? const Center(child: Text('Brak produktów'))
                        : CustomScrollView(
                            controller: _scroll,
                            slivers: [
                              const SliverToBoxAdapter(child: _InnerHeader()),
                              const SliverToBoxAdapter(child: _FilterBar()),
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                                        onTap: () => context.push(
                                          '/products/${product.code}',
                                        ),
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
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 16),
                              ),
                            ],
                          ),
                };
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
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 0.5,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SaturLogo(width: 120),
                  Positioned(
                    right: 8,
                    child: IconButton(
                      onPressed: () {}, // notifications no-op
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: SaturColors.surfaceGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 20, color: SaturColors.outline),
                    SizedBox(width: 12),
                    Text(
                      'Wyszukaj produkt',
                      style: TextStyle(color: SaturColors.outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InnerHeader extends StatelessWidget {
  const _InnerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.go('/welcome'),
            icon: const Icon(Icons.arrow_back, size: 20),
            label: const Text('Wróć'),
            style: TextButton.styleFrom(foregroundColor: SaturColors.onSurface),
          ),
          const Expanded(
            child: Text(
              'Oferta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: SaturColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(child: _chip(Icons.tune, 'Filtry')),
          const SizedBox(width: 12),
          Expanded(child: _chip(Icons.swap_vert, 'Sortuj')),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Material(
      color: SaturColors.surfaceVariant.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {}, // no-op
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: SaturColors.onSurface),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
