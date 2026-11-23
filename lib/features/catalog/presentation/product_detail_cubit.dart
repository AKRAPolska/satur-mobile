import 'package:satur_app/features/catalog/presentation/package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/features/catalog/presentation/package:satur_app/features/catalog/domain/catalog_repository.dart';
import 'package:satur_app/features/catalog/presentation/product_detail_state.dart';

final class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(this._repository, {required this.code})
      : super(const ProductDetailInitial());

  final CatalogRepository _repository;
  final String code;

  Future<void> load() async {
    emit(const ProductDetailLoading());
    final result = await _repository.fetchProduct(code);
    result.when(
      success: (product) => emit(ProductDetailLoaded(product)),
      failure: (err) => emit(ProductDetailFailureState(err)),
    );
  }

  Future<void> retry() => load();
}
