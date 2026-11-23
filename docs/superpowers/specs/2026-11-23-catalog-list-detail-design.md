# Catalog list + product detail — Design Spec

**Date:** 2026-11-23  
**Status:** Approved for implementation (user: approach A — pixel UI + API data; filters/ATC/wishlist UI no-op; no agent commit until asked)

## Goal

Ship product **list** and **PDP** screens that match Stitch design visually (v1 rules), fed by Satur Sylius Shop API via existing `ApiClient`. No real filters, cart, or wishlist behavior yet.

## Sources of truth

1. **Wycena / `PODSUMOWANIE_ZAKRESU_V1.md`** — scope, 4-tab bottom nav, out-of-scope rules  
2. **Stitch** — layout/look:  
   - `docs/stitch_myriad_pro_design_system/smartfony_i_telefony_lista_produkt_w/`  
   - `docs/stitch_myriad_pro_design_system/karta_produktu/`  
   - tokens: `satur_e_commerce_mobile/DESIGN.md`  
3. **Live API** — `../satur` Sylius on `:5051` (`/api/v2/shop/...`)

If Stitch shows 5 tabs (+ Konto) → **use 4 tabs** per wycena.

## Context (Satur web vs API)

- Web listing uses BitBag Elasticsearch + facets; this slice uses **`GET /api/v2/shop/products`** (paginated), not ES.  
- Price lives on **variant** (`GET /api/v2/shop/product-variants/{code}`), not on product.  
- Company discounts require auth — **out of scope**; show channel/public variant price.  
- Product `attributes` may be null → hide Specyfikacja block when empty.

## Architecture

Feature module mirroring `join_program`:

```
lib/features/catalog/
  domain/
    product_summary.dart      # list card model
    product_detail.dart       # PDP model
    money.dart                # grosze → display (optional helper)
    catalog_failure.dart
    catalog_repository.dart   # interface
  data/
    http_catalog_repository.dart
    catalog_dto_mapping.dart  # JSON → domain (keep thin)
  presentation/
    product_list_screen.dart
    product_list_cubit.dart
    product_list_state.dart
    product_detail_screen.dart
    product_detail_cubit.dart
    product_detail_state.dart
    widgets/
      product_card.dart
      catalog_bottom_nav.dart  # 4 tabs; shared or local
```

- Use existing `ApiClient` + `Result` / map `ApiFailure` → `CatalogFailure`.  
- Register repository in `AppDependencies`.  
- Routes (go_router): `/products`, `/products/:code`. Temporary entry: navigate from Welcome secondary path **or** start app at `/products` for CR — prefer link from Welcome only if it doesn’t break join flow; otherwise add a debug-friendly route and document `make run-chrome` with initial route. **Decision:** add route; from Welcome keep CTAs; open lista via new tertiary text button only if design allows — **simpler:** `initialLocation` stays `/welcome`; add navigation from a temporary “Oferta” entry on Welcome **or** bottom-nav placeholder later. For this PR: **router routes exist**; entry = `context.go('/products')` from a small “Przeglądaj ofertę” text button under join CTAs on Welcome (acceptable until home exists).

### Repository contract

```dart
abstract interface class CatalogRepository {
  Future<Result<ProductListPage, CatalogFailure>> fetchProducts({
    required int page,
    int itemsPerPage = 20,
  });

  Future<Result<ProductDetail, CatalogFailure>> fetchProduct(String code);
}
```

`ProductListPage`: items + page + optional `hasMore` / total from Hydra (`hydra:totalItems`, `hydra:view`).

`ProductSummary`: `code`, `name`, `imageUrl?`, `averageRating?`, `priceGross?`, `originalPriceGross?` (grosze int).

`ProductDetail`: `code`, `name`, `description?`, `imageUrls`, `averageRating?`, `priceGross?`, `originalPriceGross?`, `specs` map (empty ok).

List pricing strategy (YAGNI-simple): for each product in page, resolve `defaultVariant` IRI → fetch variant for `price` / `originalPrice`. Accept N+1 for v1 slice; document follow-up to optimize (embed/batch).

## UI — Product list

Match Stitch structure:

| Block | Behavior |
|-------|----------|
| Top bar | Logo center, notifications icon **no-op** |
| Search row | Visible, **no-op** |
| Inner header | Back → `/welcome`; title e.g. „Oferta” |
| Filtry / Sortuj | Visible buttons, **no-op** |
| Active filter pills | Optional static empty or hidden if none — **no fake pills** |
| Grid | 2 columns, margin 16, gutter 12 |
| Card | Image, discount badge if original > price, wishlist **no-op**, name (2 lines), rating if present, price + strikethrough, bag button **no-op** |
| Bottom nav | Start / Oferta / Ulubione / Koszyk — Oferta selected; others **no-op** |
| Pagination | Load more on scroll **or** page footer — implement `hasMore` + load next page |
| States | loading (first page), error + retry, empty |

## UI — Product detail (PDP)

| Block | Behavior |
|-------|----------|
| App bar | Back, title truncated name or „Produkt” |
| Gallery | Horizontal page/snap, dots; images from API |
| Wishlist | **no-op** |
| Name, rating, price | From domain |
| Specyfikacja | Only if `specs` non-empty |
| Opis | description / shortDescription |
| Sticky CTA | „Dodaj do koszyka” → **no-op** (optional SnackBar „Wkrótce”) |
| Bottom nav | 4 tabs per wycena |

## Out of scope

- Real filters, sort, search, Elasticsearch taxon listing  
- Categories / home carousels  
- Wishlist / cart / ATC API  
- Auth / company pricing  
- iOS polish beyond shared Flutter UI  
- Changes in `../satur` backend

## Testing

| Layer | Coverage |
|-------|----------|
| Domain/mapping | JSON fixtures → models; money format |
| Repository | Mock `ApiClient` success/failure |
| Cubits | loading → data / error; load more |
| Widgets | ProductCard shows name+price; list shows grid; detail shows gallery/name |

## Success criteria

- [ ] List and PDP visually aligned with Stitch + DESIGN tokens (Arimo, navy, spacing)  
- [ ] Real data from local Satur API  
- [ ] No-op controls clearly non-functional (no crashes)  
- [ ] Tests green; analyze clean  
- [ ] No git commit from agent until user asks  

## Follow-ups

1. Taxon/ES listing + real filters  
2. Wishlist + ATC  
3. Home (`ekran_g_wny_...`)  
4. Optimize list pricing (avoid N+1)
