import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/network/api_failure.dart';
import 'package:satur_app/core/result/result.dart';

void main() {
  ApiClient buildClient(
    MockClientHandler handler, {
    FutureOr<String?> Function()? tokenProvider,
  }) {
    return ApiClient(
      httpClient: MockClient(handler),
      baseUrl: 'http://example.test',
      tokenProvider: tokenProvider,
    );
  }

  test('get success decodes JSON', () async {
    final client = buildClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'http://example.test/api/v2/shop/channels');
      expect(request.headers['Accept'], 'application/ld+json');
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    final result = await client.get(
      '/api/v2/shop/channels',
      decode: (json) => (json as Map)['ok'] as bool,
    );

    expect(result, isA<Success<bool, ApiFailure>>());
    expect((result as Success).value, isTrue);
  });

  test('get strips trailing slash on baseUrl', () async {
    final client = ApiClient(
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'http://example.test/api/v2/shop/channels');
        return http.Response('{}', 200);
      }),
      baseUrl: 'http://example.test/',
    );

    final result = await client.get('/api/v2/shop/channels', decode: (_) => null);
    expect(result, isA<Success<void, ApiFailure>>());
  });

  test('get maps non-2xx to ApiHttpFailure', () async {
    final client = buildClient(
      (_) async => http.Response('nope', 500),
    );

    final result = await client.get('/x', decode: (_) => null);

    expect(result, isA<Failure<void, ApiFailure>>());
    final err = (result as Failure).error;
    expect(err, isA<ApiHttpFailure>());
    expect((err as ApiHttpFailure).statusCode, 500);
  });

  test('get maps invalid JSON to ApiParseFailure', () async {
    final client = buildClient(
      (_) async => http.Response('not-json', 200),
    );

    final result = await client.get('/x', decode: (_) => null);

    expect(result, isA<Failure<void, ApiFailure>>());
    expect((result as Failure).error, isA<ApiParseFailure>());
  });

  test('get maps decode throw to ApiParseFailure', () async {
    final client = buildClient(
      (_) async => http.Response(jsonEncode({'a': 1}), 200),
    );

    final result = await client.get(
      '/x',
      decode: (_) => throw StateError('bad shape'),
    );

    expect((result as Failure).error, isA<ApiParseFailure>());
  });

  test('get maps ClientException to ApiNetworkFailure', () async {
    final client = buildClient(
      (_) async => throw http.ClientException('offline'),
    );

    final result = await client.get('/x', decode: (_) => null);

    expect((result as Failure).error, isA<ApiNetworkFailure>());
  });

  test('get maps TimeoutException to ApiTimeoutFailure', () async {
    final client = buildClient(
      (_) async => throw TimeoutException('slow'),
    );

    final result = await client.get('/x', decode: (_) => null);

    expect((result as Failure).error, isA<ApiTimeoutFailure>());
  });

  test('post sends JSON body and Content-Type', () async {
    final client = buildClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {'email': 'a@b.c'});
      return http.Response(jsonEncode({'id': 1}), 201);
    });

    final result = await client.post(
      '/api/v2/shop/customers',
      body: {'email': 'a@b.c'},
      decode: (json) => (json as Map)['id'] as int,
    );

    expect((result as Success).value, 1);
  });

  test('adds Bearer token when tokenProvider returns value', () async {
    final client = buildClient(
      (request) async {
        expect(request.headers['Authorization'], 'Bearer tok-1');
        return http.Response('{}', 200);
      },
      tokenProvider: () async => 'tok-1',
    );

    final result = await client.get('/x', decode: (_) => null);
    expect(result, isA<Success<void, ApiFailure>>());
  });

  test('omits Authorization when tokenProvider is null or empty', () async {
    final client = buildClient(
      (request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response('{}', 200);
      },
      tokenProvider: () async => '',
    );

    final result = await client.get('/x', decode: (_) => null);
    expect(result, isA<Success<void, ApiFailure>>());
  });

  test('patch sends merge-patch+json body, Accept and Bearer token', () async {
    final client = buildClient(
      (request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v2/shop/orders/t/items');
        expect(
          request.headers['Content-Type'],
          startsWith('application/merge-patch+json'),
        );
        expect(request.headers['Accept'], 'application/ld+json');
        expect(request.headers['Authorization'], 'Bearer tok-1');
        expect(jsonDecode(request.body), {'quantity': 2});
        return http.Response(jsonEncode({'ok': true}), 200);
      },
      tokenProvider: () async => 'tok-1',
    );

    final result = await client.patch(
      '/api/v2/shop/orders/t/items',
      body: {'quantity': 2},
      decode: (json) => (json as Map)['ok'] as bool,
    );

    expect((result as Success).value, isTrue);
  });

  test('post keeps application/json Content-Type', () async {
    final client = buildClient((request) async {
      expect(request.headers['Content-Type'], startsWith('application/json'));
      return http.Response('{}', 200);
    });

    final result = await client.post('/x', body: {}, decode: (_) => null);
    expect(result, isA<Success<void, ApiFailure>>());
  });

  test('patch maps non-2xx to ApiHttpFailure', () async {
    final client = buildClient((_) async => http.Response('bad', 422));

    final result = await client.patch('/x', body: {}, decode: (_) => null);

    final err = (result as Failure).error as ApiHttpFailure;
    expect(err.statusCode, 422);
    expect(err.body, 'bad');
  });

  test('delete sends no body or Content-Type and decodes empty 204 as null',
      () async {
    final client = buildClient(
      (request) async {
        expect(request.method, 'DELETE');
        expect(request.headers.containsKey('Content-Type'), isFalse);
        expect(request.headers['Authorization'], 'Bearer tok-1');
        expect(request.body, isEmpty);
        return http.Response('', 204);
      },
      tokenProvider: () async => 'tok-1',
    );

    final result = await client.delete<Object?>('/x', decode: (json) => json);

    expect(result, isA<Success<Object?, ApiFailure>>());
    expect((result as Success).value, isNull);
  });

  test('delete maps 404 to ApiHttpFailure', () async {
    final client = buildClient((_) async => http.Response('gone', 404));

    final result = await client.delete('/x', decode: (_) => null);

    expect(((result as Failure).error as ApiHttpFailure).statusCode, 404);
  });
}
