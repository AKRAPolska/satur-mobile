import 'package:equatable/equatable.dart';

import 'package:satur_app/features/catalog/domain/catalog_failure.dart';
import 'package:satur_app/features/catalog/domain/product_summary.dart';

sealed class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object?> get props => [];
}

final class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

final class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

final class ProductListLoaded extends ProductListState {
  const ProductListLoaded({
    required this.items,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<ProductSummary> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  @override
  List<Object?> get props => [items, page, hasMore, loadingMore];
}

final class ProductListFailureState extends ProductListState {
  const ProductListFailureState(this.failure);
  final CatalogFailure failure;

  @override
  List<Object?> get props => [failure];
}
