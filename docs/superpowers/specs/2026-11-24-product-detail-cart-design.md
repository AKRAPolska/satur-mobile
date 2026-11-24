# Product detail polish + working cart — Design

**Date:** 2026-11-24  
**Status:** Approved for implementation (user: PDP polish first, then real cart, same branch `feature/product-detail-and-cart`; no Q&A)

## Goal

1. Make the PDP a full product view (price/discount, spec grid, real „Dodaj do koszyka”).
2. Make the cart work end to end against Sylius: add from PDP, view/edit/remove in the **Koszyk** tab.

## Sources of truth

1. **Stitch** — `karta_produktu/` (price block, 2-col specs), `koszyk/` (line items, qty stepper, „Wartość produktów”)
2. **Existing code** — `catalog` and `auth` features (layout, `Result`, cubits, session store pattern)
3. **Live API** — `../satur` Sylius on `:5051` (`/api/v2/shop/...`)

## Context

- PDP already exists and loads product + default-variant price from the API. Gaps: no strikethrough/discount, specs are a single column, no variant code, ATC shows a „Wkrótce” SnackBar.
- `ApiClient` has only `get` / `post`; Sylius cart mutations need `PATCH` (merge-patch) and `DELETE`.
- `ApiClient` already sends `Accept: application/ld+json` and `Authorization: Bearer` via `tokenProvider` (so logged-in users hit the API as customers; guests work without a token).
- `CatalogTab.koszyk` exists in the bottom nav but is a no-op in `handleCatalogTabNavigation`.
- Money is grosze → `formatPln` in `catalog/domain/money.dart`.

## Decisions

| Topic | Decision |
|-------|----------|
| Order of work | PDP polish → `ApiClient` patch/delete → cart domain/data → `CartCubit` → ATC on PDP → cart screen + nav |
| ATC target | `ProductDetail.defaultVariantCode` (parsed from `defaultVariant` IRI); button disabled when null |
| Add-item verb | **PATCH** `/orders/{token}/items` with `application/merge-patch+json` (BitBag customization) — **not** POST |
| Cart token | `tokenValue` persisted in secure storage via `CartTokenStore` (same shape as `SessionStore`) |
| Cart state scope | **App-level** `CartCubit` (created in `AppDependencies`, provided in `SaturApp`) so PDP, Koszyk tab, and a future badge share one instance |
| Guest vs logged-in | Both supported; JWT attached automatically by `ApiClient` when a session exists |
| Logout | Clear stored cart token + reset `CartCubit` (avoid showing a customer cart to the next user). Login keeps the current token (no merge logic) |
| Expired cart | `404` on cart calls → clear token; fetch shows empty cart; add recreates once and retries |
| Totals | Show `itemsTotal` („Wartość produktów”) and `total` („Razem”); shipping row only when `shippingTotal > 0`. No checkout button |
| Line thumbnails | Best-effort: variant → product → `images[0].path`, cached per variant code in the repository (N+1 accepted, same trade-off as catalog list); failure → placeholder icon |
| Wishlist | Stays no-op |

## Architecture

```
lib/core/network/
  api_client.dart              # + patch(), delete(); header builder takes contentType

lib/features/catalog/          # PDP polish (edits only)
  domain/product_detail.dart   # + defaultVariantCode, discountPercent
  data/http_catalog_repository.dart   # parse variant code from defaultVariant IRI
  presentation/product_detail/widgets/
    product_detail_info.dart   # strikethrough + discount badge
    product_specs_section.dart # 2-col grid
    product_detail_footer.dart # real ATC via CartCubit
  presentation/shared/catalog_nav.dart  # koszyk → /cart

lib/features/cart/             # new, mirrors catalog/auth
  domain/
    cart.dart                  # Cart (tokenValue, items, itemsTotal, shippingTotal, total)
    cart_item.dart             # CartItem (id, variantCode, productName, variantName?, quantity, unitPrice, total, imageUrl?)
    cart_failure.dart          # sealed: network / http / unknown
    cart_repository.dart       # interface
    cart_token_store.dart      # interface
  data/
    http_cart_repository.dart
    secure_cart_token_store.dart   # key: cart.token
    memory_cart_token_store.dart   # tests
  presentation/
    cart_cubit.dart
    cart_state.dart
    cart_screen.dart
    widgets/
      cart_item_tile.dart
      cart_summary.dart
      cart_empty_view.dart

lib/app/
  di.dart                      # cartTokenStore, cartRepository, cartCubit
  app.dart                     # MultiBlocProvider (SessionCubit + CartCubit); logout listener
  router.dart                  # GoRoute /cart
```

`cart` reuses `formatPln` and `CatalogBottomNav` / `catalog_nav` from `catalog` (same pattern as `auth` account screen). Moving them to `core` is a later refactor, not part of this slice.

## API contract (Sylius, `:5051`)

| Action | Request | Notes |
|--------|---------|-------|
| Create / pick up cart | `POST /api/v2/shop/orders` body `{}` (`application/json`) | Response `tokenValue` → `CartTokenStore.save` |
| Read cart | `GET /api/v2/shop/orders/{token}` | |
| Add item | `PATCH /api/v2/shop/orders/{token}/items` `Content-Type: application/merge-patch+json` body `{"productVariant": "/api/v2/shop/product-variants/{code}", "quantity": n}` | Returns order. Implementation step 1 of cart verifies IRI vs bare code with a live `curl`; use whichever the API accepts and cover it in the repository test |
| Change qty | `PATCH /api/v2/shop/orders/{token}/items/{id}` `merge-patch+json` `{"quantity": n}` | Returns order |
| Remove item | `DELETE /api/v2/shop/orders/{token}/items/{id}` | `204` → repository re-fetches order |

Mapping from order JSON: `tokenValue`, `itemsTotal`, `shippingTotal`, `total` (grosze ints); each `items[]`: `id`, `quantity`, `unitPrice`, `total`, `productName`, `variantName`, `variant` (IRI → `variantCode`).

### ApiClient additions

```dart
Future<Result<T, ApiFailure>> patch<T>(String path, {Object? body, required T Function(Object? json) decode});
Future<Result<T, ApiFailure>> delete<T>(String path, {required T Function(Object? json) decode});
```

- `patch` sends `Content-Type: application/merge-patch+json` (not `application/json`); `post` unchanged.
- `delete` sends no body; empty `204` body decodes as `null` (existing `_send` already allows this).
- Same timeout, auth header, and `ApiFailure` mapping as `get` / `post`.

### Repository contract

```dart
abstract interface class CartRepository {
  /// null when no token stored or server says the cart no longer exists.
  Future<Result<Cart?, CartFailure>> fetchCart();

  Future<Result<Cart, CartFailure>> addItem({required String variantCode, int quantity = 1});
  Future<Result<Cart, CartFailure>> updateQuantity({required String itemId, required int quantity});
  Future<Result<Cart, CartFailure>> removeItem(String itemId);

  /// Drops the stored token (logout).
  Future<void> reset();
}

abstract interface class CartTokenStore {
  Future<String?> read();
  Future<void> save(String token);
  Future<void> clear();
}
```

`addItem` flow: read token → if missing, `POST /orders` and save → `PATCH .../items`. On `404` clear token, create a new cart, retry once.

## UI

### PDP polish (first)

| Block | Behavior |
|-------|----------|
| Price | Current price (primary, bold); when `hasDiscount`: original price strikethrough + red `-N%` pill (same visuals as `ProductCard`) |
| Rating | Unchanged (`averageRating` only; no review count — no API field in use) |
| Specyfikacja | Stitch card: title + `grid-cols-2` (label small/muted, value below); odd count leaves last cell empty; hidden when `specs` empty |
| Footer CTA | „Dodaj do koszyka” → `CartCubit.addItem(defaultVariantCode)`; spinner while busy; disabled if no variant code or busy. Success: SnackBar „Dodano do koszyka” with action „Koszyk” → `/cart`. Failure: SnackBar „Nie udało się dodać do koszyka” |
| Wishlist | no-op (unchanged) |

### Cart screen (`/cart`)

| Block | Behavior |
|-------|----------|
| App bar | Title „Twój koszyk” (pinned, same as catalog screens) |
| Line item | Thumbnail, name, `variantName` (muted), unit price, qty stepper (− / n / +), remove |
| Stepper | `−` disabled at 1 (use remove); changes call `updateQuantity`; row dimmed while its request is in flight |
| Summary | „Wartość produktów” = `itemsTotal`; optional „Dostawa” if `shippingTotal > 0`; „Razem” = `total` |
| Checkout | None (out of scope) |
| Empty | „Twój koszyk jest pusty” + button „Przeglądaj ofertę” → `/products` |
| Error | Message + „Spróbuj ponownie” |
| Bottom nav | Existing 5-tab nav, `koszyk` active; `CatalogTab.koszyk` → `context.go('/cart')` |

`CartScreen` calls `CartCubit.refresh()` on open.

### Cubit

```
CartState (sealed, Equatable)
  CartInitial
  CartLoading
  CartLoaded(cart, {busyItemIds, adding})   // cart == null → empty
  CartFailureState(failure)
```

- `refresh()` → `fetchCart`
- `addItem(variantCode)` → `Future<bool>` (PDP shows the SnackBar; cubit emits updated `CartLoaded`)
- `updateQuantity` / `removeItem` → mark id busy, call repo, emit new cart or keep old cart on failure
- Ignore re-entrant mutations for the same item/variant while busy
- `reset()` → repo `reset`, emit `CartInitial`; called from a `BlocListener<SessionCubit>` on **session → null** only (not on cold-start hydrate)

## Error handling

| Case | Behavior |
|------|----------|
| Network / timeout | Cart screen: error + retry; PDP: failure SnackBar |
| `404` cart token | Clear token; treat as empty cart; ATC recreates |
| `401` with stale JWT | Surfaces as `CartHttpFailure`; user can retry / re-login (no auto-refresh in this slice) |
| `422` on add (unavailable variant) | `CartHttpFailure` → failure SnackBar |

## Testing

| Layer | Coverage |
|-------|----------|
| `ApiClient` | `patch` sends `merge-patch+json` + auth header; `delete` handles `204`; failure mapping |
| Catalog repository | `defaultVariantCode` parsed from IRI; null when no default variant |
| `ProductDetail` | `hasDiscount`, `discountPercent` |
| Cart repository | Create-then-add; reuse stored token; `404` → recreate + retry once; qty update; delete → re-fetch; JSON → `Cart` mapping |
| Token stores | `MemoryCartTokenStore` read/save/clear |
| `CartCubit` | refresh → loaded/empty/failure; add success/failure; busy flags; reset on logout |
| Widgets | PDP shows strikethrough + badge, 2-col specs, ATC calls cubit; cart tile qty/remove callbacks; empty and summary states |

## Out of scope

- Checkout, shipping method, payment, addresses, order submission
- Coupons / promotion codes
- Wishlist API, Ulubione tab, Start tab
- Variant pickers, stock/availability UI, review count API
- Cart badge on the bottom nav (state is ready; UI later)
- Guest→customer cart merge, JWT refresh
- Changes in `../satur` backend

## Acceptance

- [ ] PDP: discounted products show original price struck through and `-N%` pill; non-discounted show price only
- [ ] PDP: specs render as a 2-column grid; hidden when empty
- [ ] `ProductDetail.defaultVariantCode` populated from the API
- [ ] `ApiClient.patch` / `delete` implemented and unit-tested
- [ ] ATC from PDP adds the item (no „Wkrótce”); guest and logged-in both work against local Sylius
- [ ] Cart token persists across app restart (secure storage)
- [ ] Koszyk tab opens `/cart`; list, qty change, remove, and totals (`itemsTotal` + `total`) match the API
- [ ] Empty, loading, and error states on cart screen
- [ ] Logout clears the cart token and state
- [ ] `make analyze` and `make test` green
- [ ] No changes under `../satur`

## Follow-ups

1. Cart badge on bottom nav
2. Checkout flow (address → shipping → payment)
3. Move `formatPln` and shared nav widgets to `core`
4. Batch/embed variant + image data to remove N+1 on cart thumbnails
5. Wishlist API
