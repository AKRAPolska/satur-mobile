# Catalog list + PDP Implementation Plan

> **For agentic workers:** Execute task-by-task. Use TDD. **Do not commit** unless user asks.

**Goal:** Product list + PDP matching Stitch UI, data from Sylius Shop API via `ApiClient`; filters/wishlist/ATC no-op.

**Architecture:** Feature `catalog` with domain/data/presentation; Cubits; `HttpCatalogRepository`; routes `/products`, `/products/:code`.

**Tech Stack:** Flutter, flutter_bloc, go_router, existing ApiClient/Result, equatable.

## Global Constraints

- Pixel UI from Stitch list + `karta_produktu`; 4-tab nav per wycena
- Filtry/Sort/search/wishlist/ATC/bag = no-op
- Hide Specyfikacja when no attributes
- No `../satur` changes; no agent commit
- Spec: `docs/superpowers/specs/2026-11-23-catalog-list-detail-design.md`

## File map

- Create: `lib/features/catalog/**`
- Modify: `lib/app/di.dart`, `lib/app/router.dart`, `lib/features/welcome/presentation/welcome_screen.dart`
- Test: `test/features/catalog/**`

---

### Task 1: Domain + money helper + tests

**Files:** `lib/features/catalog/domain/*`, `test/features/catalog/domain/*`

- [ ] `CatalogFailure` sealed (network, http, notFound, unknown)
- [ ] `ProductSummary`, `ProductDetail`, `ProductListPage`
- [ ] `formatPln(int grosze)` → `"4 769,00 zł"` style
- [ ] `CatalogRepository` interface
- [ ] Unit tests for money + model equality

### Task 2: HttpCatalogRepository (TDD)

**Files:** `lib/features/catalog/data/*`, `test/features/catalog/data/*`

- [ ] Parse Hydra collection + variant prices (N+1 via ApiClient)
- [ ] `fetchProduct(code)` + variant
- [ ] Map ApiFailure → CatalogFailure
- [ ] Tests with MockClient / fake ApiClient

### Task 3: Cubits (TDD)

**Files:** presentation cubit/state + tests

- [ ] List: load, loadMore, retry
- [ ] Detail: load by code, retry

### Task 4: UI screens + widgets

**Files:** screens, product_card, bottom_nav

- [ ] List + PDP per Stitch/DESIGN tokens
- [ ] Wire router + DI
- [ ] Welcome: „Przeglądaj ofertę” → `/products`
- [ ] Widget tests smoke

### Task 5: Verify

- [ ] `flutter analyze` + `flutter test`
- [ ] Manual: Chrome against `:5051`
