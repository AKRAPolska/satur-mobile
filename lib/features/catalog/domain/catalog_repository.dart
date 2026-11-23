import 'package:satur_app/features/catalog/domain/package:satur_app/core/result/result.dart';
import 'package:satur_app/features/catalog/domain/catalog_failure.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';
import 'package:satur_app/features/catalog/domain/product_list_page.dart';

abstract interface class CatalogRepository {
  Future<Result<ProductListPage, CatalogFailure>> fetchProducts({
    required int page,
    int itemsPerPage = 20,
  });

  Future<Result<ProductDetail, CatalogFailure>> fetchProduct(String code);
}
