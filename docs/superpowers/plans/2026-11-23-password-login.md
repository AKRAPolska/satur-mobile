# Password login + Moje konto — Implementation Plan

> Execute task-by-task. Use TDD. **Do not commit** unless user asks.

**Goal:** Email/password login, JWT session, Moje konto logout, 5-tab nav — Stitch UI.

**Spec:** `docs/superpowers/specs/2026-11-23-password-login-design.md`

---

### Task 1: Domain + SessionStore

- [ ] `AuthFailure` sealed (invalidCredentials, network, http, unknown)
- [ ] `AuthSession` (token, email)
- [ ] `SessionStore` interface + in-memory for tests
- [ ] `AuthRepository` interface (`login`)
- [ ] Unit tests: memory store save/read/clear

### Task 2: Secure store + DI tokenProvider

- [ ] `SecureSessionStore` (`flutter_secure_storage`)
- [ ] Wire in `AppDependencies`; `ApiClient.tokenProvider`

### Task 3: HttpAuthRepository (TDD)

- [ ] POST `/api/v2/shop/authentication-token`
- [ ] Map 200 → session; 401 → invalidCredentials
- [ ] Persist via SessionStore on success
- [ ] MockClient tests

### Task 4: Login Cubit + UI

- [ ] LoginCubit / state; tests
- [ ] LoginScreen Stitch widgets
- [ ] Welcome → `/login`
- [ ] Success → `/products`

### Task 5: Account + logout

- [ ] AccountScreen Stitch list + Wyloguj
- [ ] Clear session → `/welcome`
- [ ] Guard: no session → `/login`

### Task 6: Nav + routes

- [ ] 5-tab bottom nav + Konto routing
- [ ] Routes `/login`, `/account`
- [ ] Remove „Przeglądaj ofertę” if present

### Task 7: Verify

- [ ] `flutter analyze` + `flutter test`
