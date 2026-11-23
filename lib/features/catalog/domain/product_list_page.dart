import 'package:equatable/equatable.dart';

import 'package:satur_app/features/catalog/domain/product_summary.dart';

final class ProductListPage extends Equatable {
  const ProductListPage({
    required this.items,
    required this.page,
    required this.hasMore,
    this.totalItems,
  });

  final List<ProductSummary> items;
  final int page;
  final bool hasMore;
  final int? totalItems;

  @override
  List<Object?> get props => [items, page, hasMore, totalItems];
}
