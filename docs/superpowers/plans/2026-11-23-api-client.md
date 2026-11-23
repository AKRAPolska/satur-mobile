# API Client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a thin `package:http` ApiClient that talks to Satur Sylius (`API_BASE_URL`) and returns `Result<T, ApiFailure>`, with unit tests and an updated smoke check — no feature screens wired.

**Architecture:** `lib/core/network/` holds `ApiFailure` + `ApiClient`. Client wraps `http.Client`, normalizes base URL, maps network/timeout/HTTP/parse into sealed failures, returns existing `Result`. Optional `tokenProvider` hook (unused). Registered once in `AppDependencies`.

**Tech Stack:** Flutter/Dart, `package:http`, existing `Result` / `AppConfig`, `http/testing.dart` `MockClient` for tests, Makefile smoke via curl.

## Global Constraints

- Lightweight only: `package:http` — no dio, Retrofit, Chopper, codegen
- Shop-user client only (no admin API usage in Flutter)
- Do not wire join/login/products in this plan
- Do not change `../satur` backend
- Do **not** create git commits (user will CR and commit)
- Keep join on `StubJoinProgramRepository`
- Align with spec: `docs/superpowers/specs/2026-11-23-api-client-design.md`

## File map

- Create: `lib/core/network/api_failure.dart`
- Create: `lib/core/network/api_client.dart`
- Create: `test/core/network/api_client_test.dart`
- Modify: `pubspec.yaml` (add `http`)
- Modify: `lib/app/di.dart` (construct + expose `ApiClient`)
- Modify: `Makefile` (`satur-api-check` → channels endpoint)
- Modify: `README.md` (one line under API about smoke path) — only if needed for accuracy

---

### Task 1: Dependency + ApiFailure

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/network/api_failure.dart`
- Test: covered indirectly in Task 2 (failure variants asserted there)

**Interfaces:**
- Consumes: nothing
- Produces: sealed `ApiFailure` with variants `network`, `timeout`, `http`, `parse`

- [ ] **Step 1: Add dependency**

In `pubspec.yaml` under `dependencies:` (after `google_fonts`):

```yaml
  http: ^1.2.2
```

Run: `flutter pub get`  
Expected: resolves; lockfile updates.

- [ ] **Step 2: Create ApiFailure**

Create `lib/core/network/api_failure.dart`:

```dart
/// Failures from [ApiClient]. Map at feature boundaries if needed.
sealed class ApiFailure {
  const ApiFailure();
}

final class ApiNetworkFailure extends ApiFailure {
  const ApiNetworkFailure([this.message]);
  final String? message;
}

final class ApiTimeoutFailure extends ApiFailure {
  const ApiTimeoutFailure();
}

final class ApiHttpFailure extends ApiFailure {
  const ApiHttpFailure({required this.statusCode, this.body});
  final int statusCode;
  final String? body;
}

final class ApiParseFailure extends ApiFailure {
  const ApiParseFailure([this.message]);
  final String? message;
}
```

- [ ] **Step 3: Analyze**

Run: `dart analyze lib/core/network/api_failure.dart`  
Expected: no issues.

- [ ] **Step 4: Commit**

SKIP — user CR. Leave working tree dirty.

---

### Task 2: ApiClient (TDD)

**Files:**
- Create: `test/core/network/api_client_test.dart`
- Create: `lib/core/network/api_client.dart`

**Interfaces:**
- Consumes: `ApiFailure`, `Result` from `lib/core/result/result.dart`, `http.Client`
- Produces:

```dart
final class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required String baseUrl,
    this.timeout = const Duration(seconds: 15),
    this.tokenProvider,
  });

  final FutureOr<String?> Function()? tokenProvider;

  Future<Result<T, ApiFailure>> get<T>(
    String path, {
    required T Function(Object? json) decode,
  });

  Future<Result<T, ApiFailure>> post<T>(
    String path, {
    Object? body,
    required T Function(Object? json) decode,
  });
}
```

- [ ] **Step 1: Write failing tests**

Create `test/core/network/api_client_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/network/api_failure.dart';
import 'package:satur_app/core/result/result.dart';

void main() {
  ApiClient buildClient(MockClientHandler handler, {FutureOr<String?> Function()? tokenProvider}) {
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
      expect(request.headers['Accept'], 'application/json');
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
}
```

- [ ] **Step 2: Run tests — expect FAIL**

Run: `flutter test test/core/network/api_client_test.dart`  
Expected: FAIL (missing `api_client.dart` / undefined `ApiClient`).

- [ ] **Step 3: Implement ApiClient**

Create `lib/core/network/api_client.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../result/result.dart';
import 'api_failure.dart';

final class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required String baseUrl,
    this.timeout = const Duration(seconds: 15),
    this.tokenProvider,
  })  : _http = httpClient,
        _baseUrl = _stripTrailingSlash(baseUrl);

  final http.Client _http;
  final String _baseUrl;
  final Duration timeout;
  final FutureOr<String?> Function()? tokenProvider;

  static String _stripTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalized');
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    final provider = tokenProvider;
    if (provider != null) {
      final token = await provider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Result<T, ApiFailure>> get<T>(
    String path, {
    required T Function(Object? json) decode,
  }) {
    return _send<T>(
      () async => _http
          .get(_uri(path), headers: await _headers())
          .timeout(timeout),
      decode: decode,
    );
  }

  Future<Result<T, ApiFailure>> post<T>(
    String path, {
    Object? body,
    required T Function(Object? json) decode,
  }) {
    return _send<T>(
      () async => _http
          .post(
            _uri(path),
            headers: await _headers(jsonBody: true),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout),
      decode: decode,
    );
  }

  Future<Result<T, ApiFailure>> _send<T>(
    Future<http.Response> Function() send, {
    required T Function(Object? json) decode,
  }) async {
    try {
      final response = await send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(
          ApiHttpFailure(
            statusCode: response.statusCode,
            body: response.body.isEmpty ? null : response.body,
          ),
        );
      }
      try {
        final Object? json =
            response.body.isEmpty ? null : jsonDecode(response.body);
        return Success(decode(json));
      } catch (e) {
        return Failure(ApiParseFailure(e.toString()));
      }
    } on TimeoutException {
      return const Failure(ApiTimeoutFailure());
    } on http.ClientException catch (e) {
      return Failure(ApiNetworkFailure(e.message));
    } on Exception catch (e) {
      return Failure(ApiNetworkFailure(e.toString()));
    }
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

Run: `flutter test test/core/network/api_client_test.dart`  
Expected: all tests PASS.

- [ ] **Step 5: Commit**

SKIP — user CR.

---

### Task 3: Wire DI + Makefile smoke

**Files:**
- Modify: `lib/app/di.dart`
- Modify: `Makefile` target `satur-api-check`
- Modify: `README.md` (API section — one sentence)

**Interfaces:**
- Consumes: `ApiClient`, `AppConfig.apiBaseUrl`
- Produces: `AppDependencies.apiClient`

- [ ] **Step 1: Update DI**

Modify `lib/app/di.dart` to:

```dart
import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../core/network/api_client.dart';
import '../features/join_program/data/stub_join_program_repository.dart';
import '../features/join_program/domain/join_program.dart';
import '../features/join_program/domain/join_program_repository.dart';

/// Manual composition root. Swap [JoinProgramRepository] when HTTP is ready.
final class AppDependencies {
  AppDependencies._({
    required this.httpClient,
    required this.apiClient,
    required this.joinProgramRepository,
    required this.joinProgram,
  });

  final http.Client httpClient;
  final ApiClient apiClient;
  final JoinProgramRepository joinProgramRepository;
  final JoinProgram joinProgram;

  factory AppDependencies.create() {
    final httpClient = http.Client();
    final apiClient = ApiClient(
      httpClient: httpClient,
      baseUrl: AppConfig.apiBaseUrl,
    );
    final repository = StubJoinProgramRepository();
    return AppDependencies._(
      httpClient: httpClient,
      apiClient: apiClient,
      joinProgramRepository: repository,
      joinProgram: JoinProgram(repository),
    );
  }
}
```

Note: no feature uses `apiClient` yet; that is intentional.

- [ ] **Step 2: Update Makefile smoke**

Replace `satur-api-check` target body with:

```makefile
satur-api-check:
	@echo "Checking $(API_BASE_URL)/api/v2/shop/channels ..."
	@curl -sS -o /tmp/satur-channels.json -w "HTTP %{http_code}\n" --connect-timeout 3 \
		"$(API_BASE_URL)/api/v2/shop/channels" \
		|| (echo "API niedostępne. W ../satur: make up  (web na :5051)"; exit 1)
	@grep -q 'SATUR' /tmp/satur-channels.json \
		|| (echo "Oczekiwano kanału SATUR w odpowiedzi channels"; exit 1)
	@echo "OK — Shop API channels zawiera SATUR"
```

- [ ] **Step 3: README API blurb**

In `README.md` under `## API`, ensure it mentions:

```markdown
- Smoke: `make satur-api-check` → `GET /api/v2/shop/channels` (oczekuje kanału `SATUR`).
```

- [ ] **Step 4: Verify**

Run:

```bash
flutter analyze
flutter test
make satur-api-check
```

Expected: analyze clean; all tests PASS; smoke OK if `../satur` is up (if down, smoke fails with clear message — unit suite still green).

- [ ] **Step 5: Commit**

SKIP — user CR. Show `git status` / `git diff` summary for review.

---

## Spec coverage checklist

| Spec item | Task |
|-----------|------|
| `package:http` dependency | Task 1 |
| `ApiFailure` sealed | Task 1 |
| `ApiClient` get/post + Result | Task 2 |
| baseUrl normalize + JSON headers | Task 2 |
| tokenProvider hook | Task 2 |
| DI registration | Task 3 |
| Unit tests mock HTTP | Task 2 |
| Make smoke channels | Task 3 |
| No feature wiring / no satur changes / no agent commit | all tasks |

## Plan self-review

- No TBD/placeholders in steps
- Signatures consistent across tasks (`get`/`post`/`tokenProvider`/`ApiFailure` variants)
- Commit steps explicitly SKIP per user CR request
