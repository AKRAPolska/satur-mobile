import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/network/api_failure.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/catalog/domain/catalog_failure.dart';
import 'package:satur_app/features/catalog/domain/catalog_repository.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';
import 'package:satur_app/features/catalog/domain/product_list_page.dart';
import 'package:satur_app/features/catalog/domain/product_summary.dart';

final class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<ProductListPage, CatalogFailure>> fetchProducts({
    required int page,
    int itemsPerPage = 20,
  }) async {
    final collection = await _api.get<Map<String, dynamic>>(
      '/api/v2/shop/products?itemsPerPage=$itemsPerPage&page=$page',
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );

    return collection.when(
      success: (body) async {
        final members = (body['hydra:member'] as List<dynamic>? ?? const [])
            .cast<dynamic>();
        final total = body['hydra:totalItems'] as int?;
        final view = body['hydra:view'] as Map<String, dynamic>?;
        final hasMore = view != null && view['hydra:next'] != null;

        final summaries = <ProductSummary>[];
        for (final raw in members) {
          final map = Map<String, dynamic>.from(raw as Map);
          final summary = await _summaryFromProductJson(map);
          summaries.add(summary);
        }

        return Success(
          ProductListPage(
            items: summaries,
            page: page,
            hasMore: hasMore,
            totalItems: total,
          ),
        );
      },
      failure: (err) async => Failure(_mapFailure(err)),
    );
  }

  @override
  Future<Result<ProductDetail, CatalogFailure>> fetchProduct(String code) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v2/shop/products/$code',
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );

    return result.when(
      success: (map) async {
        final prices = await _pricesFromDefaultVariant(map['defaultVariant']);
        final images = _imageUrls(map['images']);
        final description = (map['description'] as String?)?.trim();
        final short = (map['shortDescription'] as String?)?.trim();
        final text = (description != null && description.isNotEmpty)
            ? description
            : short;

        return Success(
          ProductDetail(
            code: map['code'] as String? ?? code,
            name: map['name'] as String? ?? '',
            description: text,
            imageUrls: images,
            averageRating: (map['averageRating'] as num?)?.toDouble(),
            priceGross: prices.$1,
            originalPriceGross: prices.$2,
            specs: _specsFromJson(map['attributes']),
            defaultVariantCode: _variantCodeFromIri(map['defaultVariant']),
          ),
        );
      },
      failure: (err) async {
        if (err is ApiHttpFailure && err.statusCode == 404) {
          return const Failure(CatalogNotFoundFailure());
        }
        return Failure(_mapFailure(err));
      },
    );
  }

  Future<ProductSummary> _summaryFromProductJson(Map<String, dynamic> map) async {
    final prices = await _pricesFromDefaultVariant(map['defaultVariant']);
    final images = _imageUrls(map['images']);
    return ProductSummary(
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      imageUrl: images.isEmpty ? null : images.first,
      averageRating: (map['averageRating'] as num?)?.toDouble(),
      priceGross: prices.$1,
      originalPriceGross: prices.$2,
    );
  }

  static String? _variantCodeFromIri(Object? iri) {
    if (iri is! String || iri.isEmpty) return null;
    final code = iri.split('/').last;
    return code.isEmpty ? null : code;
  }

  Future<(int?, int?)> _pricesFromDefaultVariant(Object? defaultVariant) async {
    final code = _variantCodeFromIri(defaultVariant);
    if (code == null) return (null, null);
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v2/shop/product-variants/$code',
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return result.when(
      success: (v) => (
        (v['price'] as num?)?.toInt(),
        (v['originalPrice'] as num?)?.toInt(),
      ),
      failure: (_) => (null, null),
    );
  }

  List<String> _imageUrls(Object? images) {
    if (images is! List) return const [];
    final urls = <String>[];
    for (final item in images) {
      if (item is Map && item['path'] is String) {
        urls.add(item['path'] as String);
      }
    }
    return urls;
  }

  Map<String, String> _specsFromJson(Object? attributes) {
    if (attributes is! List) return const {};
    final specs = <String, String>{};
    for (final item in attributes) {
      if (item is! Map) continue;
      final name = item['name'] ?? item['code'];
      final value = item['value'] ?? item['localeCode'];
      if (name != null && value != null) {
        specs[name.toString()] = value.toString();
      }
    }
    return specs;
  }

  CatalogFailure _mapFailure(ApiFailure err) {
    return switch (err) {
      ApiNetworkFailure(:final message) => CatalogNetworkFailure(message),
      ApiTimeoutFailure() => const CatalogNetworkFailure('timeout'),
      ApiHttpFailure(:final statusCode, :final body) =>
        CatalogHttpFailure(statusCode: statusCode, message: body),
      ApiParseFailure(:final message) => CatalogUnknownFailure(message),
    };
  }
}
