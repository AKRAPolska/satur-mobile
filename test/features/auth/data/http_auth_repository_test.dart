import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/auth/data/http_auth_repository.dart';
import 'package:satur_app/features/auth/data/memory_session_store.dart';
import 'package:satur_app/features/auth/domain/auth_failure.dart';

void main() {
  test('login maps token and persists session', () async {
    final store = MemorySessionStore();
    final client = ApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v2/shop/authentication-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'user@satur.pl');
        expect(body['password'], 'secret');
        return http.Response(
          jsonEncode({
            'token': 'jwt-abc',
            'customer': '/api/v2/shop/customers/1',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'http://example.test',
    );

    final repo = HttpAuthRepository(client, store);
    final result = await repo.login(
      email: 'user@satur.pl',
      password: 'secret',
    );

    expect(result, isA<Success>());
    final session = (result as Success).value;
    expect(session.token, 'jwt-abc');
    expect(session.email, 'user@satur.pl');
    expect(await store.readToken(), 'jwt-abc');
  });

  test('login 401 maps to AuthInvalidCredentialsFailure', () async {
    final store = MemorySessionStore();
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 401, 'message': 'Invalid credentials.'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      ),
      baseUrl: 'http://example.test',
    );

    final repo = HttpAuthRepository(client, store);
    final result = await repo.login(email: 'a@b.pl', password: 'wrong');

    expect((result as Failure).error, isA<AuthInvalidCredentialsFailure>());
    expect(await store.read(), isNull);
  });
}
