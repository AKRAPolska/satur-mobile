import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/features/catalog/domain/catalog_repository.dart';
import 'package:satur_app/features/catalog/presentation/product_list/product_list_state.dart';

final class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit(this._repository) : super(const ProductListInitial());

  final CatalogRepository _repository;
  static const _pageSize = 20;

  Future<void> load() async {
    emit(const ProductListLoading());
    final result = await _repository.fetchProducts(page: 1, itemsPerPage: _pageSize);
    result.when(
      success: (page) => emit(
        ProductListLoaded(
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
      failure: (err) => emit(ProductListFailureState(err)),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ProductListLoaded || !current.hasMore || current.loadingMore) {
      return;
    }
    emit(
      ProductListLoaded(
        items: current.items,
        page: current.page,
        hasMore: current.hasMore,
        loadingMore: true,
      ),
    );
    final nextPage = current.page + 1;
    final result = await _repository.fetchProducts(
      page: nextPage,
      itemsPerPage: _pageSize,
    );
    result.when(
      success: (page) => emit(
        ProductListLoaded(
          items: [...current.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
      failure: (_) => emit(
        ProductListLoaded(
          items: current.items,
          page: current.page,
          hasMore: current.hasMore,
        ),
      ),
    );
  }

  Future<void> retry() => load();
}
