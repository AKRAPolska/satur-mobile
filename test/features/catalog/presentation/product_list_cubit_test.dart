import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/catalog/domain/catalog_failure.dart';
import 'package:satur_app/features/catalog/domain/catalog_repository.dart';
import 'package:satur_app/features/catalog/domain/product_list_page.dart';
import 'package:satur_app/features/catalog/domain/product_summary.dart';
import 'package:satur_app/features/catalog/presentation/product_list_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_list_state.dart';

class _MockRepo extends Mock implements CatalogRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  blocTest<ProductListCubit, ProductListState>(
    'load emits loading then loaded',
    build: () {
      when(
        () => repo.fetchProducts(page: 1, itemsPerPage: 20),
      ).thenAnswer(
        (_) async => const Success(
          ProductListPage(
            items: [
              ProductSummary(code: '1', name: 'Phone'),
            ],
            page: 1,
            hasMore: false,
          ),
        ),
      );
      return ProductListCubit(repo);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductListLoading(),
      isA<ProductListLoaded>().having((s) => s.items.first.code, 'code', '1'),
    ],
  );

  blocTest<ProductListCubit, ProductListState>(
    'load emits failure',
    build: () {
      when(
        () => repo.fetchProducts(page: 1, itemsPerPage: 20),
      ).thenAnswer(
        (_) async => const Failure(CatalogNetworkFailure()),
      );
      return ProductListCubit(repo);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductListLoading(),
      isA<ProductListFailureState>(),
    ],
  );
}
