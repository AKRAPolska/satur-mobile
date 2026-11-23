# API Client (backend connection) — Design Spec

**Date:** 2026-11-23  
**Status:** Approved for implementation (user: lightweight `package:http`; no commit from agent — user CR)

## Goal

Add a thin HTTP layer so Flutter can talk to Satur (Sylius) and return clear success/failure. Smoke against live Shop API. No feature screens wired yet.

## Context

- **satur-app** = mobile/web client (Flutter)
- **satur** = backend (Sylius) on `:5051` — API + business logic + DB
- Existing: `AppConfig.apiBaseUrl` via `--dart-define`; join program still on stub
- Live today: `GET /api/v2/shop/channels` → 200 JSON (Hydra)
- App is shop-user only (no admin panel in Flutter)

## Out of scope (this PR)

- Login / passwordless auth / JWT flow
- Join program HTTP + Sylius custom endpoint
- Product list / product detail
- DTO/mappers for catalog
- `dio`, Retrofit/Chopper, code generation
- Changes in `../satur` repo

## Architecture

```
lib/core/
  config.dart                 # existing API_BASE_URL
  result/result.dart          # existing Result<T,E>
  network/
    api_client.dart           # thin HTTP wrapper
    api_failure.dart          # sealed failure types
```

Laravel analogy: a small HTTP client service (like a Guzzle wrapper in `app/Services`), registered in the composition root — not feature controllers yet.

### ApiClient

- Depends on `package:http` (`Client`)
- `baseUrl` from `AppConfig.apiBaseUrl` (no trailing-slash assumptions; normalize in client)
- Methods: at least `get` and `post` returning `Future<Result<T, ApiFailure>>`
- Caller passes `path` (e.g. `/api/v2/shop/channels`) and a `decode` function `T Function(Object? json)`
- Default headers: `Accept: application/json`; `Content-Type: application/json` on POST body
- Optional `tokenProvider` (`FutureOr<String?> Function()?`) — unused for now; when non-null and non-empty, set `Authorization: Bearer <token>` (hook for later login)
- Timeouts: reasonable default (e.g. 15s) via `http` client / `Client` wrapper

### ApiFailure (sealed)

| Variant | When |
|---------|------|
| `network` | socket / connection failed |
| `timeout` | request exceeded timeout |
| `http` | non-2xx; carry `statusCode` + optional body snippet |
| `parse` | JSON decode / mapper threw |

Do **not** throw across the feature boundary — always `Result`.

### DI

- `AppDependencies.create()` constructs one shared `http.Client` + `ApiClient`
- Expose `apiClient` on `AppDependencies`
- Do not swap join stub in this PR

### Smoke / verification

1. **Unit tests** with a fake/mock `http.Client` (or injected handler): 200 + JSON, 500, malformed JSON, connection error
2. **Optional live check**: keep/extend `make satur-api-check` to hit `/api/v2/shop/channels` (or document curl). Skip-on-down for any automated live test so CI/local without Docker still passes unit suite

No UI change required to prove connection.

## Testing

| Layer | What |
|-------|------|
| Unit | `ApiClient` mapping: success decode, http failure, parse failure, network |
| Live (manual/make) | `GET {API_BASE_URL}/api/v2/shop/channels` returns channel collection |

## Success criteria

- [ ] `package:http` in dependencies
- [ ] `ApiClient` + `ApiFailure` in `lib/core/network/`
- [ ] Wired in `AppDependencies`
- [ ] Unit tests green
- [ ] Documented/make smoke against Satur channels
- [ ] No feature wiring; no git commit from agent

## Follow-ups (later PRs)

1. Sylius endpoint mirroring web onboarding → `HttpJoinProgramRepository`
2. Passwordless login + tokenProvider usage
3. Product list + product detail repositories on top of `ApiClient`
