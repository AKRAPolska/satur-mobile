import 'package:equatable/equatable.dart';

import 'package:satur_app/features/catalog/domain/catalog_failure.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';

sealed class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

final class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

final class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

final class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded(this.product);
  final ProductDetail product;

  @override
  List<Object?> get props => [product];
}

final class ProductDetailFailureState extends ProductDetailState {
  const ProductDetailFailureState(this.failure);
  final CatalogFailure failure;

  @override
  List<Object?> get props => [failure];
}
