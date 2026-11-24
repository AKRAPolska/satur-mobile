import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/data/http_cart_repository.dart';
import 'package:satur_app/features/cart/data/memory_cart_token_store.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';

typedef _Route = http.Response Function(http.Request request);

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _item({int id = 101, int qty = 1, int unit = 7127}) => {
      'id': id,
      'quantity': qty,
      'unitPrice': unit,
      'total': unit * qty,
      'productName': 'Maxi Cosi',
      'variant': {
        '@id': '/api/v2/shop/product-variants/58288-variant-0',
        'code': '58288-variant-0',
        'price': unit,
      },
    };

Map<String, dynamic> _order({
  String token = 'tok-1',
  List<Map<String, dynamic>> items = const [],
  int itemsTotal = 0,
  int shippingTotal = 0,
  int total = 0,
}) =>
    {
      'tokenValue': token,
      'items': items,
      'itemsTotal': itemsTotal,
      'shippingTotal': shippingTotal,
      'total': total,
    };

final _variantRoute = <String, _Route>{
  'GET /api/v2/shop/product-variants/58288-variant-0': (_) => _json({
        'code': '58288-variant-0',
        'name': 'Classic Black',
        'product': '/api/v2/shop/products/58288',
      }),
  'GET /api/v2/shop/products/58288': (_) => _json({
        'images': [
          {'path': 'http://img/a.jpg'},
        ],
      }),
};

void main() {
  late List<http.Request> log;
  late MemoryCartTokenStore tokens;

  HttpCartRepository build(Map<String, _Route> routes) {
    final client = ApiClient(
      httpClient: MockClient((request) async {
        log.add(request);
        final route = routes['${request.method} ${request.url.path}'];
        if (route == null) {
          return http.Response('unrouted ${request.method} ${request.url.path}', 500);
        }
        return route(request);
      }),
      baseUrl: 'http://example.test',
    );
    return HttpCartRepository(client, tokens);
  }

  List<String> mutations() => log
      .where((r) => r.method != 'GET')
      .map((r) => '${r.method} ${r.url.path}')
      .toList();

  setUp(() {
    log = [];
    tokens = MemoryCartTokenStore();
  });

  test('fetchCart without a stored token returns null and makes no request',
      () async {
    final repo = build({});

    final result = await repo.fetchCart();

    expect((result as Success<Cart?, CartFailure>).value, isNull);
    expect(log, isEmpty);
  });

  test('fetchCart maps order JSON and enriches items with name and image',
      () async {
    await tokens.save('tok-1');
    final repo = build({
      'GET /api/v2/shop/orders/tok-1': (_) => _json(
            _order(
              items: [_item(qty: 2)],
              itemsTotal: 14254,
              shippingTotal: 1000,
              total: 15254,
            ),
          ),
      ..._variantRoute,
    });

    final result = await repo.fetchCart();

    final cart = (result as Success<Cart?, CartFailure>).value!;
    expect(cart.tokenValue, 'tok-1');
    expect(cart.itemsTotal, 14254);
    expect(cart.shippingTotal, 1000);
    expect(cart.total, 15254);
    expect(cart.items, hasLength(1));
    final item = cart.items.single;
    expect(item.id, '101');
    expect(item.variantCode, '58288-variant-0');
    expect(item.productName, 'Maxi Cosi');
    expect(item.variantName, 'Classic Black');
    expect(item.quantity, 2);
    expect(item.unitPrice, 7127);
    expect(item.total, 14254);
    expect(item.imageUrl, 'http://img/a.jpg');
  });

  test('fetchCart keeps the item (no image) when variant lookup fails',
      () async {
    await tokens.save('tok-1');
    final repo = build({
      'GET /api/v2/shop/orders/tok-1': (_) =>
          _json(_order(items: [_item()], itemsTotal: 7127, total: 7127)),
      // variant route intentionally missing -> 500
    });

    final result = await repo.fetchCart();

    final item =
        (result as Success<Cart?, CartFailure>).value!.items.single;
    expect(item.productName, 'Maxi Cosi');
    expect(item.imageUrl, isNull);
    expect(item.variantName, isNull);
  });

  test('fetchCart on 404 clears the token and returns null', () async {
    await tokens.save('old');
    final repo = build({
      'GET /api/v2/shop/orders/old': (_) => http.Response('gone', 404),
    });

    final result = await repo.fetchCart();

    expect((result as Success<Cart?, CartFailure>).value, isNull);
    expect(await tokens.read(), isNull);
  });

  test('fetchCart maps client exceptions to CartNetworkFailure', () async {
    await tokens.save('tok-1');
    final client = ApiClient(
      httpClient: MockClient((_) async => throw http.ClientException('offline')),
      baseUrl: 'http://example.test',
    );
    final repo = HttpCartRepository(client, tokens);

    final result = await repo.fetchCart();

    expect((result as Failure).error, isA<CartNetworkFailure>());
  });

  test('addItem without a token creates the cart, saves it, then PATCHes',
      () async {
    final repo = build({
      'POST /api/v2/shop/orders': (_) => _json(_order(token: 'new-1'), 201),
      'PATCH /api/v2/shop/orders/new-1/items': (_) => _json(
            _order(token: 'new-1', items: [_item()], itemsTotal: 7127, total: 7127),
          ),
      ..._variantRoute,
    });

    final result = await repo.addItem(variantCode: '58288-variant-0');

    final cart = (result as Success<Cart, CartFailure>).value;
    expect(cart.items.single.variantCode, '58288-variant-0');
    expect(await tokens.read(), 'new-1');
    expect(mutations(), [
      'POST /api/v2/shop/orders',
      'PATCH /api/v2/shop/orders/new-1/items',
    ]);
    final patch = log.firstWhere((r) => r.method == 'PATCH');
    expect(
      patch.headers['Content-Type'],
      startsWith('application/merge-patch+json'),
    );
    // IRI form (bare code is also accepted by the API; see "Verified API facts").
    expect(jsonDecode(patch.body), {
      'productVariant': '/api/v2/shop/product-variants/58288-variant-0',
      'quantity': 1,
    });
  });

  test('addItem reuses the stored token without creating a cart', () async {
    await tokens.save('tok-1');
    final repo = build({
      'PATCH /api/v2/shop/orders/tok-1/items': (_) =>
          _json(_order(items: [_item(qty: 3)], itemsTotal: 21381, total: 21381)),
      ..._variantRoute,
    });

    final result =
        await repo.addItem(variantCode: '58288-variant-0', quantity: 3);

    expect(result, isA<Success<Cart, CartFailure>>());
    expect(mutations(), ['PATCH /api/v2/shop/orders/tok-1/items']);
    expect(
      (jsonDecode(log.firstWhere((r) => r.method == 'PATCH').body)
          as Map)['quantity'],
      3,
    );
  });

  test('addItem on 404 recreates the cart and retries exactly once', () async {
    await tokens.save('old');
    final repo = build({
      'PATCH /api/v2/shop/orders/old/items': (_) => http.Response('gone', 404),
      'POST /api/v2/shop/orders': (_) => _json(_order(token: 'new-2'), 201),
      'PATCH /api/v2/shop/orders/new-2/items': (_) => _json(
            _order(token: 'new-2', items: [_item()], itemsTotal: 7127, total: 7127),
          ),
      ..._variantRoute,
    });

    final result = await repo.addItem(variantCode: '58288-variant-0');

    expect(result, isA<Success<Cart, CartFailure>>());
    expect(await tokens.read(), 'new-2');
    expect(mutations(), [
      'PATCH /api/v2/shop/orders/old/items',
      'POST /api/v2/shop/orders',
      'PATCH /api/v2/shop/orders/new-2/items',
    ]);
  });

  test('addItem does not retry more than once when the new cart also 404s',
      () async {
    await tokens.save('old');
    final repo = build({
      'PATCH /api/v2/shop/orders/old/items': (_) => http.Response('gone', 404),
      'POST /api/v2/shop/orders': (_) => _json(_order(token: 'new-3'), 201),
      'PATCH /api/v2/shop/orders/new-3/items': (_) =>
          http.Response('gone', 404),
    });

    final result = await repo.addItem(variantCode: '58288-variant-0');

    final failure = (result as Failure).error as CartHttpFailure;
    expect(failure.statusCode, 404);
    expect(mutations(), hasLength(3));
  });

  test('addItem maps 422 to CartHttpFailure', () async {
    await tokens.save('tok-1');
    final repo = build({
      'PATCH /api/v2/shop/orders/tok-1/items': (_) =>
          http.Response('unavailable', 422),
    });

    final result = await repo.addItem(variantCode: 'x');

    final failure = (result as Failure).error as CartHttpFailure;
    expect(failure.statusCode, 422);
  });

  test('updateQuantity PATCHes the item with merge-patch', () async {
    await tokens.save('tok-1');
    final repo = build({
      'PATCH /api/v2/shop/orders/tok-1/items/101': (_) => _json(
            _order(items: [_item(qty: 3)], itemsTotal: 21381, total: 21381),
          ),
      ..._variantRoute,
    });

    final result = await repo.updateQuantity(itemId: '101', quantity: 3);

    expect((result as Success<Cart, CartFailure>).value.items.single.quantity, 3);
    final patch = log.firstWhere((r) => r.method == 'PATCH');
    expect(
      patch.headers['Content-Type'],
      startsWith('application/merge-patch+json'),
    );
    expect(jsonDecode(patch.body), {'quantity': 3});
  });

  test('removeItem DELETEs the item then re-fetches the order', () async {
    await tokens.save('tok-1');
    final repo = build({
      'DELETE /api/v2/shop/orders/tok-1/items/101': (_) =>
          http.Response('', 204),
      'GET /api/v2/shop/orders/tok-1': (_) => _json(_order()),
    });

    final result = await repo.removeItem('101');

    expect((result as Success<Cart, CartFailure>).value.isEmpty, isTrue);
    expect(
      log.map((r) => '${r.method} ${r.url.path}').toList(),
      [
        'DELETE /api/v2/shop/orders/tok-1/items/101',
        'GET /api/v2/shop/orders/tok-1',
      ],
    );
  });

  test('reset clears the stored token', () async {
    await tokens.save('tok-1');
    final repo = build({});

    await repo.reset();

    expect(await tokens.read(), isNull);
  });
}
