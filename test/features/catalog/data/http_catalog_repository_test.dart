import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/catalog/data/http_catalog_repository.dart';
import 'package:satur_app/features/catalog/domain/catalog_failure.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';

void main() {
  test('fetchProducts maps hydra members and variant prices', () async {
    final client = ApiClient(
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v2/shop/products') {
          return http.Response(
            jsonEncode({
              'hydra:member': [
                {
                  'code': '58288',
                  'name': 'Maxi Cosi',
                  'averageRating': 4.5,
                  'defaultVariant':
                      '/api/v2/shop/product-variants/58288-variant-0',
                  'images': [
                    {'path': 'http://img/a.jpg', 'type': 'main'},
                  ],
                },
              ],
              'hydra:totalItems': 1,
              'hydra:view': {
                'hydra:next': '/api/v2/shop/products?page=2',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.endsWith('/product-variants/58288-variant-0')) {
          return http.Response(
            jsonEncode({'price': 7127, 'originalPrice': 8000}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      }),
      baseUrl: 'http://example.test',
    );

    final repo = HttpCatalogRepository(client);
    final result = await repo.fetchProducts(page: 1, itemsPerPage: 20);

    expect(result, isA<Success>());
    final page = (result as Success).value;
    expect(page.items, hasLength(1));
    expect(page.items.first.code, '58288');
    expect(page.items.first.priceGross, 7127);
    expect(page.items.first.originalPriceGross, 8000);
    expect(page.hasMore, isTrue);
  });

  test('fetchProduct 404 maps to CatalogNotFoundFailure', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response('missing', 404),
      ),
      baseUrl: 'http://example.test',
    );
    final repo = HttpCatalogRepository(client);
    final result = await repo.fetchProduct('nope');
    expect((result as Failure).error, isA<CatalogNotFoundFailure>());
  });

  ApiClient clientWith(Map<String, Object> jsonByPath) {
    return ApiClient(
      httpClient: MockClient((request) async {
        final body = jsonByPath[request.url.path];
        if (body == null) return http.Response('not found', 404);
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'http://example.test',
    );
  }

  test('fetchProduct parses defaultVariantCode from the defaultVariant IRI',
      () async {
    final repo = HttpCatalogRepository(
      clientWith({
        '/api/v2/shop/products/58288': {
          'code': '58288',
          'name': 'Maxi Cosi',
          'defaultVariant': '/api/v2/shop/product-variants/58288-variant-0',
        },
        '/api/v2/shop/product-variants/58288-variant-0': {
          'price': 7127,
          'originalPrice': 8000,
        },
      }),
    );

    final result = await repo.fetchProduct('58288');

    final detail = (result as Success<ProductDetail, CatalogFailure>).value;
    expect(detail.defaultVariantCode, '58288-variant-0');
    expect(detail.priceGross, 7127);
  });

  test('fetchProduct leaves defaultVariantCode null without a default variant',
      () async {
    final repo = HttpCatalogRepository(
      clientWith({
        '/api/v2/shop/products/58288': {'code': '58288', 'name': 'Maxi Cosi'},
      }),
    );

    final result = await repo.fetchProduct('58288');

    final detail = (result as Success<ProductDetail, CatalogFailure>).value;
    expect(detail.defaultVariantCode, isNull);
    expect(detail.priceGross, isNull);
  });
}
