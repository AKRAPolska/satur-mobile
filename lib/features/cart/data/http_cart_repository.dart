import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/network/api_failure.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/domain/cart_repository.dart';
import 'package:satur_app/features/cart/domain/cart_token_store.dart';

final class HttpCartRepository implements CartRepository {
  HttpCartRepository(this._api, this._tokens);

  static const _orders = '/api/v2/shop/orders';
  static const _variants = '/api/v2/shop/product-variants';

  final ApiClient _api;
  final CartTokenStore _tokens;

  /// variantCode -> name + thumbnail, filled lazily (N+1 accepted).
  final Map<String, _VariantInfo> _variantCache = {};

  @override
  Future<Result<Cart?, CartFailure>> fetchCart() async {
    final token = await _tokens.read();
    if (token == null) return const Success(null);

    final result = await _getOrder(token);
    switch (result) {
      case Success(:final value):
        return Success(value);
      case Failure(:final error):
        if (_isNotFound(error)) {
          await _tokens.clear();
          return const Success(null);
        }
        return Failure(_mapFailure(error));
    }
  }

  @override
  Future<Result<Cart, CartFailure>> addItem({
    required String variantCode,
    int quantity = 1,
  }) async {
    final stored = await _tokens.read();
    final String token;
    final bool freshlyCreated;
    if (stored != null) {
      token = stored;
      freshlyCreated = false;
    } else {
      final created = await _createCart();
      if (created case Failure(:final error)) {
        return Failure(_mapFailure(error));
      }
      token = (created as Success<String, ApiFailure>).value;
      freshlyCreated = true;
    }

    var result = await _patchAdd(token, variantCode, quantity);

    // Stored cart expired server-side: recreate once and retry once.
    if (!freshlyCreated &&
        result is Failure<Cart, ApiFailure> &&
        _isNotFound(result.error)) {
      await _tokens.clear();
      final created = await _createCart();
      if (created case Failure(:final error)) {
        return Failure(_mapFailure(error));
      }
      final newToken = (created as Success<String, ApiFailure>).value;
      result = await _patchAdd(newToken, variantCode, quantity);
    }
    return _toCartResult(result);
  }

  @override
  Future<Result<Cart, CartFailure>> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final token = await _tokens.read();
    if (token == null) return const Failure(CartHttpFailure(statusCode: 404));

    final response = await _api.patch<Map<String, dynamic>>(
      '$_orders/$token/items/$itemId',
      body: {'quantity': quantity},
      decode: _asMap,
    );
    return _finishMutation(await _toCart(response));
  }

  @override
  Future<Result<Cart, CartFailure>> removeItem(String itemId) async {
    final token = await _tokens.read();
    if (token == null) return const Failure(CartHttpFailure(statusCode: 404));

    final deleted = await _api.delete<Object?>(
      '$_orders/$token/items/$itemId',
      decode: (_) => null,
    );
    if (deleted case Failure(:final error)) {
      return _finishMutation(Failure(error));
    }
    return _finishMutation(await _getOrder(token));
  }

  @override
  Future<void> reset() => _tokens.clear();

  // ---- helpers ----

  static Map<String, dynamic> _asMap(Object? json) =>
      Map<String, dynamic>.from(json as Map);

  static bool _isNotFound(ApiFailure e) =>
      e is ApiHttpFailure && e.statusCode == 404;

  Future<Result<String, ApiFailure>> _createCart() async {
    final response = await _api.post<String>(
      _orders,
      body: const <String, Object?>{},
      decode: (json) => (json as Map)['tokenValue'] as String,
    );
    if (response case Success(:final value)) {
      await _tokens.save(value);
    }
    return response;
  }

  Future<Result<Cart, ApiFailure>> _patchAdd(
    String token,
    String variantCode,
    int quantity,
  ) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '$_orders/$token/items',
      body: {
        'productVariant': '$_variants/$variantCode',
        'quantity': quantity,
      },
      decode: _asMap,
    );
    return _toCart(response);
  }

  Future<Result<Cart, ApiFailure>> _getOrder(String token) async {
    final response = await _api.get<Map<String, dynamic>>(
      '$_orders/$token',
      decode: _asMap,
    );
    return _toCart(response);
  }

  Future<Result<Cart, ApiFailure>> _toCart(
    Result<Map<String, dynamic>, ApiFailure> response,
  ) async {
    switch (response) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        try {
          return Success(await _cartFromJson(value));
        } catch (e) {
          return Failure(ApiParseFailure(e.toString()));
        }
    }
  }

  /// A 404 on a mutation means the cart is gone: drop the token, surface the failure.
  Future<Result<Cart, CartFailure>> _finishMutation(
    Result<Cart, ApiFailure> result,
  ) async {
    if (result case Failure(:final error) when _isNotFound(error)) {
      await _tokens.clear();
    }
    return _toCartResult(result);
  }

  Result<Cart, CartFailure> _toCartResult(Result<Cart, ApiFailure> result) {
    return switch (result) {
      Success(:final value) => Success(value),
      Failure(:final error) => Failure(_mapFailure(error)),
    };
  }

  Future<Cart> _cartFromJson(Map<String, dynamic> order) async {
    final rawItems = order['items'] as List<dynamic>? ?? const [];
    final items = await Future.wait(
      rawItems.map((raw) => _itemFromJson(Map<String, dynamic>.from(raw as Map))),
    );
    return Cart(
      tokenValue: order['tokenValue'] as String? ?? '',
      items: items,
      itemsTotal: (order['itemsTotal'] as num?)?.toInt() ?? 0,
      shippingTotal: (order['shippingTotal'] as num?)?.toInt() ?? 0,
      total: (order['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<CartItem> _itemFromJson(Map<String, dynamic> json) async {
    final code = _variantCode(json['variant']);
    final info = code == null ? const _VariantInfo() : await _variantInfo(code);
    return CartItem(
      id: '${json['id']}',
      variantCode: code ?? '',
      productName: json['productName'] as String? ?? '',
      variantName: info.name,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      imageUrl: info.imageUrl,
    );
  }

  /// Live API embeds the variant as an object with `code`; a bare IRI string is accepted too.
  static String? _variantCode(Object? variant) {
    if (variant is Map) {
      final code = variant['code'];
      if (code is String && code.isNotEmpty) return code;
      final iri = variant['@id'];
      if (iri is String && iri.isNotEmpty) return iri.split('/').last;
      return null;
    }
    if (variant is String && variant.isNotEmpty) return variant.split('/').last;
    return null;
  }

  Future<_VariantInfo> _variantInfo(String code) async {
    final cached = _variantCache[code];
    if (cached != null) return cached;

    final variant = await _api.get<Map<String, dynamic>>(
      '$_variants/$code',
      decode: _asMap,
    );
    switch (variant) {
      case Failure():
        return const _VariantInfo(); // not cached: retry on next fetch
      case Success(:final value):
        final name = (value['name'] as String?)?.trim();
        final info = _VariantInfo(
          name: (name == null || name.isEmpty) ? null : name,
          imageUrl: await _productImage(value['product']),
        );
        _variantCache[code] = info;
        return info;
    }
  }

  Future<String?> _productImage(Object? productIri) async {
    if (productIri is! String || productIri.isEmpty) return null;
    final product = await _api.get<Map<String, dynamic>>(productIri, decode: _asMap);
    switch (product) {
      case Failure():
        return null;
      case Success(:final value):
        final images = value['images'];
        if (images is List && images.isNotEmpty) {
          final first = images.first;
          if (first is Map && first['path'] is String) {
            return first['path'] as String;
          }
        }
        return null;
    }
  }

  CartFailure _mapFailure(ApiFailure err) {
    return switch (err) {
      ApiNetworkFailure(:final message) => CartNetworkFailure(message),
      ApiTimeoutFailure() => const CartNetworkFailure('timeout'),
      ApiHttpFailure(:final statusCode, :final body) =>
        CartHttpFailure(statusCode: statusCode, message: body),
      ApiParseFailure(:final message) => CartUnknownFailure(message),
    };
  }
}

final class _VariantInfo {
  const _VariantInfo({this.name, this.imageUrl});
  final String? name;
  final String? imageUrl;
}
