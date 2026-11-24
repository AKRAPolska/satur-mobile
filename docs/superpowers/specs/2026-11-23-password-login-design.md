# Password login + Moje konto — Design

**Date:** 2026-11-23  
**Status:** Approved for implementation

## Goal

Email + password login against Satur Shop API, durable JWT session, Stitch-aligned login + Moje konto (logout), 5-tab bottom nav with Konto.

## Wycena deltas (explicit)

| Topic | PODSUMOWANIE_ZAKRESU_V1 | This slice |
|-------|------------------------|------------|
| Auth | Passwordless (email → code) | **Email + password** (Satur / Stitch) |
| Bottom nav | 4 tabs; Konto out of v1 | **5 tabs** including Konto (Stitch) |
| Konto screen | Out of v1 | **Thin** Moje konto: menu no-op + real logout |

## References

- Stitch: `logowanie_mobile_form`, `moje_konto_dashboard`
- API: `POST /api/v2/shop/customers/token` `{ email, password }` → `{ token, customer }`
- Existing: `ApiClient.tokenProvider`, feature layout like `catalog`

## Architecture

```
lib/features/auth/
  domain/       AuthFailure, AuthSession, AuthRepository, SessionStore
  data/         HttpAuthRepository, SecureSessionStore
  presentation/
    login/      screen, cubit, state, widgets
    account/    screen, cubit (logout)
```

- `SessionStore`: read/write/clear token (+ email for display).
- DI: build store → `ApiClient(tokenProvider: store.readToken)` → auth + catalog repos.
- `SessionCubit` (or equivalent) at app root for logged-in UI (Konto routing).

## Flows

1. Welcome → Zaloguj → `/login`
2. Login success → persist session → `/products`
3. Bottom nav Konto → session? `/account` : `/login`
4. Account Wyloguj → clear session → `/welcome`
5. Start tab → `/welcome`

## UI

**Login:** Stitch form (logo, email, password + visibility toggle, forgot no-op, CTA, “lub”, Dołącz → join). Show invalid-credentials / network errors under form.

**Account:** Header „Moje konto”, menu rows as Stitch (no-op), red „Wyloguj się”. Bottom nav active = Konto.

**Bottom nav:** Start, Oferta, Ulubione, Koszyk, Konto.

## Out of scope

Passwordless/code, forgot-password API, full account (profile/password/addresses), refresh token, home, company prices.
