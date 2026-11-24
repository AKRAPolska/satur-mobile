# Product Detail Polish + Working Cart Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the PDP a full product view (discount price, 2-column specs, real „Dodaj do koszyka”) and make the cart work end to end against Sylius (add from PDP, view/edit/remove in the Koszyk tab).

**Architecture:** `ApiClient` gains `patch` (merge-patch) and `delete`. A new `features/cart` slice mirrors `catalog`/`auth` (domain interfaces + `Result`, `HttpCartRepository`, secure token store, Cubit). One app-level `CartCubit` is created in `AppDependencies` and provided in `SaturApp`, so the PDP, the Koszyk tab and a future badge share one instance. The cart token (`tokenValue`) lives in secure storage; guest and logged-in both work because `ApiClient` already attaches the JWT when a session exists.

**Tech Stack:** Flutter / Dart ^3.13, `flutter_bloc` 9 (Cubit), `equatable`, `go_router` 18, `http` (+ `MockClient` in tests), `flutter_secure_storage`, `flutter_test`. (`bloc_test` and `mocktail` are available but this plan uses hand-written fakes like the existing `login_cubit_test.dart`.)

**Spec:** `docs/superpowers/specs/2026-11-24-product-detail-cart-design.md`

## Global Constraints

Every task's requirements implicitly include this section.

- **Branch:** `feature/product-detail-and-cart`. Commit after every task (steps below). **No changes under `../satur`** (the Sylius backend). It already has unrelated uncommitted changes, so record a baseline in Task 11 rather than expecting a clean tree.
- **Commit trailer:** every commit message ends with a blank line then exactly `authored-by: <daniel.slizewski@gmail.com>`. Do **not** add any `Co-authored-by` / Cursor trailer. Use the HEREDOC form shown in each commit step.
- **Commands:** `flutter test <path>` for one file, `make test` / `make analyze` for the whole suite (Makefile puts `~/development/flutter/bin` on `PATH`; `flutter` is already on PATH in this shell). `make analyze` and `make test` must be green at the end of every task.
- **Money is grosze** (ints). Format with `formatPln` from `lib/features/catalog/domain/money.dart` (e.g. `7127` → `71,27 zł`, `8000` → `80,00 zł`).
- **Add-item verb is PATCH**, `Content-Type: application/merge-patch+json` — **not** POST (live API returns 405 for POST).
- **Cart API** (`:5051`, base path `/api/v2/shop`): `POST /orders` body `{}` → `tokenValue`; `GET /orders/{token}`; `PATCH /orders/{token}/items` `{"productVariant": "/api/v2/shop/product-variants/{code}", "quantity": n}`; `PATCH /orders/{token}/items/{id}` `{"quantity": n}`; `DELETE /orders/{token}/items/{id}` → `204`, then re-fetch the order.
- **Cart token** persisted via `CartTokenStore` in secure storage, key `cart.token` (same shape as `SessionStore`).
- **`CartCubit` is app-level** (created in `AppDependencies`, provided in `SaturApp`); not per-route.
- **Guest and logged-in both supported;** JWT attached automatically by `ApiClient`. **Logout** clears the stored cart token and resets `CartCubit` (only on session → null, never on cold-start hydrate). Login keeps the current token (no merge).
- **Expired cart:** `404` on cart calls → clear token; fetch shows an empty cart; add recreates the cart and retries **once**.
- **ATC target:** `ProductDetail.defaultVariantCode` (parsed from the `defaultVariant` IRI); button disabled when null.
- **Totals:** show `itemsTotal` („Wartość produktów”) and `total` („Razem”); „Dostawa” row only when `shippingTotal > 0`. No checkout button.
- **UI copy (Polish, verbatim):** „Dodaj do koszyka”, „Dodano do koszyka” (action „Koszyk” → `/cart`), „Nie udało się dodać do koszyka”, „Twój koszyk”, „Twój koszyk jest pusty”, „Przeglądaj ofertę” (→ `/products`), „Spróbuj ponownie”, „Wartość produktów”, „Dostawa”, „Razem”, „Specyfikacja”.
- **Wishlist stays a no-op.** Out of scope: checkout, coupons, cart badge, variant pickers, JWT refresh, guest→customer merge.
- **Reuse, don't move:** `cart` imports `formatPln`, `CatalogBottomNav`, `catalog_nav` from `catalog` (same as `auth`'s account screen).
- **Line thumbnails** are best-effort: variant → product → `images[0].path`, cached per variant code in the repository; any failure → placeholder icon (N+1 accepted).
- **Tests:** do not put non-ASCII characters in `http.Response` bodies in `MockClient` handlers (default latin1 encoding throws); Polish strings in widget tests are fine.

## Verified API facts (live `curl` against `:5051`, 2026-11-24)

These were checked while writing the plan. They refine the spec; **re-run the curl block in Task 5 Step 0 before implementing the repository** (the API is local and may have changed).

| Question | Result |
|----------|--------|
| PATCH add-item with IRI `"productVariant": "/api/v2/shop/product-variants/58288-variant-0"` | `200`, returns order |
| PATCH add-item with bare code `"productVariant": "58288-variant-0"` | `200`, returns order — **both accepted**. Plan uses the **IRI** (API Platform standard); a repository test pins it. |
| POST `/orders/{token}/items` | `405 Method Not Allowed` |
| Order JSON | `tokenValue`, `itemsTotal`, `shippingTotal` (`1000` as soon as a shipment exists), `total` — ints in grosze |
| `items[]` shape | `id` (**int**), `quantity`, `unitPrice`, `total`, `productName`, and **`variant` is an embedded object** `{"@id": ".../product-variants/58288-variant-0", "code": "58288-variant-0", "price", "originalPrice", "inStock"}` — **not an IRI string**. There is **no `variantName`** field. |
| `GET /product-variants/{code}` | has `name` (e.g. `"Classic Black"`) and `product` (IRI `/api/v2/shop/products/58288`) |
| PATCH `/orders/{token}/items/{id}` `{"quantity":3}` | `200`, returns order |
| `DELETE /orders/{token}/items/{id}` | `204` |
| `GET /orders/does-not-exist` | `404` |

**Deviations from the spec text (intentional):**
1. Cart item `variantCode` is read from `variant.code` (embedded object); a plain IRI string is also accepted defensively.
2. `variantName` is **not** in the order JSON; the repository takes it from the variant fetch it already does for the thumbnail (cached per variant code).
3. `CartCubit.updateQuantity` / `removeItem` return `Future<bool>` (like `addItem`) so the screen can show a failure SnackBar.
4. The logout listener is extracted into a tiny widget `CartSessionListener` so it is unit-testable without secure storage.
5. Spec's “cart screen UI” is split into two tasks (widgets, then screen + route + nav) so each has its own review gate.

## File Structure

```
lib/core/network/api_client.dart                       # modify: patch(), delete(), contentType header

lib/features/catalog/
  domain/product_detail.dart                           # modify: discountPercent, defaultVariantCode
  data/http_catalog_repository.dart                    # modify: parse variant code from IRI
  presentation/product_detail/product_detail_screen.dart            # modify: pass variantCode to footer
  presentation/product_detail/widgets/product_detail_info.dart      # modify: strikethrough + pill
  presentation/product_detail/widgets/product_specs_section.dart    # modify: 2-col grid
  presentation/product_detail/widgets/product_detail_footer.dart    # modify: real ATC
  presentation/shared/catalog_nav.dart                              # modify: koszyk -> /cart

lib/features/cart/                                     # new
  domain/cart.dart, cart_item.dart, cart_failure.dart, cart_repository.dart, cart_token_store.dart
  data/http_cart_repository.dart, secure_cart_token_store.dart, memory_cart_token_store.dart
  presentation/cart_state.dart, cart_cubit.dart, cart_session_listener.dart, cart_screen.dart
  presentation/widgets/cart_item_tile.dart, cart_summary.dart, cart_empty_view.dart

lib/app/di.dart                                        # modify: cartTokenStore, cartRepository, cartCubit
lib/app/app.dart                                       # modify: MultiBlocProvider + CartSessionListener
lib/app/router.dart                                    # modify: GoRoute /cart

test/core/network/api_client_test.dart                 # modify
test/features/catalog/domain/product_detail_test.dart  # new
test/features/catalog/data/http_catalog_repository_test.dart  # modify
test/features/catalog/presentation/product_detail/{product_detail_info,product_specs_section,product_detail_footer}_test.dart  # new
test/features/catalog/presentation/shared/catalog_nav_test.dart  # new
test/features/cart/support/fake_cart_repository.dart   # new (shared test fake + fixtures)
test/features/cart/domain/cart_test.dart               # new
test/features/cart/data/{memory_cart_token_store,http_cart_repository}_test.dart  # new
test/features/cart/presentation/{cart_cubit,cart_session_listener,cart_screen}_test.dart  # new
test/features/cart/presentation/widgets/{cart_item_tile,cart_summary,cart_empty_view}_test.dart  # new
```

---

### Task 1: PDP polish — discount price and 2-column specs

**Files:**
- Modify: `lib/features/catalog/domain/product_detail.dart`
- Modify: `lib/features/catalog/presentation/product_detail/widgets/product_detail_info.dart`
- Modify: `lib/features/catalog/presentation/product_detail/widgets/product_specs_section.dart`
- Test: `test/features/catalog/domain/product_detail_test.dart` (new)
- Test: `test/features/catalog/presentation/product_detail/product_detail_info_test.dart` (new)
- Test: `test/features/catalog/presentation/product_detail/product_specs_section_test.dart` (new)

**Interfaces:**
- Consumes: `formatPln(int)`, `SaturColors`, existing `ProductDetail.hasDiscount`.
- Produces: `int? ProductDetail.discountPercent` (null when no discount; rounded, same formula as `ProductSummary.discountPercent`).

- [ ] **Step 1: Write the failing tests**

`test/features/catalog/domain/product_detail_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';

void main() {
  test('discountPercent is rounded percentage off the original price', () {
    const p = ProductDetail(
      code: '1',
      name: 'x',
      priceGross: 7127,
      originalPriceGross: 8000,
    );
    expect(p.hasDiscount, isTrue);
    expect(p.discountPercent, 11); // (8000-7127)/8000 = 10.9%
  });

  test('discountPercent is null without a discount', () {
    const same = ProductDetail(
      code: '1',
      name: 'x',
      priceGross: 7127,
      originalPriceGross: 7127,
    );
    const noOriginal = ProductDetail(code: '1', name: 'x', priceGross: 7127);
    expect(same.discountPercent, isNull);
    expect(noOriginal.discountPercent, isNull);
  });
}
```

`test/features/catalog/presentation/product_detail/product_detail_info_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_detail_info.dart';

Widget _wrap(ProductDetail p) =>
    MaterialApp(home: Scaffold(body: ProductDetailInfo(product: p)));

void main() {
  testWidgets('discounted product shows struck-through original and -N% pill',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProductDetail(
          code: '1',
          name: 'Maxi Cosi',
          priceGross: 7127,
          originalPriceGross: 8000,
        ),
      ),
    );

    expect(find.text('71,27 zł'), findsOneWidget);
    final original = tester.widget<Text>(find.text('80,00 zł'));
    expect(original.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('-11%'), findsOneWidget);
  });

  testWidgets('non-discounted product shows the price only', (tester) async {
    await tester.pumpWidget(
      _wrap(const ProductDetail(code: '1', name: 'x', priceGross: 7127)),
    );

    expect(find.text('71,27 zł'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('zł'), findsOneWidget);
  });
}
```

`test/features/catalog/presentation/product_detail/product_specs_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_specs_section.dart';

Widget _wrap(Map<String, String> specs) => MaterialApp(
      home: Scaffold(body: ProductSpecsSection(specs: specs)),
    );

void main() {
  testWidgets('lays specs out in two columns; odd count leaves last cell empty',
      (tester) async {
    await tester.pumpWidget(
      _wrap({'Marka': 'Maxi Cosi', 'Kolor': 'Czarny', 'Waga': '5 kg'}),
    );

    expect(find.text('Specyfikacja'), findsOneWidget);
    final marka = tester.getTopLeft(find.text('Marka'));
    final kolor = tester.getTopLeft(find.text('Kolor'));
    final waga = tester.getTopLeft(find.text('Waga'));
    expect(kolor.dy, marka.dy); // same row
    expect(kolor.dx, greaterThan(marka.dx)); // right column
    expect(waga.dy, greaterThan(marka.dy)); // next row
    expect(waga.dx, marka.dx); // left column
    expect(find.text('Maxi Cosi'), findsOneWidget);
    expect(find.text('5 kg'), findsOneWidget);
  });

  testWidgets('renders nothing when specs are empty', (tester) async {
    await tester.pumpWidget(_wrap(const {}));
    expect(find.text('Specyfikacja'), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/catalog/domain/product_detail_test.dart test/features/catalog/presentation/product_detail/`
Expected: FAIL — `The getter 'discountPercent' isn't defined for the class 'ProductDetail'`; the info test fails on the missing `-11%` / line-through; the specs test fails because `Kolor` is on a different row than `Marka`.

- [ ] **Step 3: Implement**

`lib/features/catalog/domain/product_detail.dart` — add below `hasDiscount`:

```dart
  int? get discountPercent {
    if (!hasDiscount) return null;
    final original = originalPriceGross!;
    final price = priceGross!;
    return (((original - price) / original) * 100).round();
  }
```

`lib/features/catalog/presentation/product_detail/widgets/product_detail_info.dart` — replace the `if (product.priceGross != null) ...[ ... ]` block with:

```dart
        if (product.priceGross != null) ...[
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                formatPln(product.priceGross!),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: SaturColors.primary,
                ),
              ),
              if (product.hasDiscount) ...[
                Text(
                  formatPln(product.originalPriceGross!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: SaturColors.outline,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                _DiscountPill(percent: product.discountPercent!),
              ],
            ],
          ),
        ],
```

and append to the same file:

```dart
class _DiscountPill extends StatelessWidget {
  const _DiscountPill({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SaturColors.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

`lib/features/catalog/presentation/product_detail/widgets/product_specs_section.dart` — replace the `...specs.entries.map(...)` spread with grid rows, and add `_SpecCell`:

```dart
          const SizedBox(height: 12),
          ..._rows(),
        ],
      ),
    );
  }

  List<Widget> _rows() {
    final entries = specs.entries.toList();
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      final left = entries[i];
      final right = i + 1 < entries.length ? entries[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SpecCell(entry: left)),
              const SizedBox(width: 16),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _SpecCell(entry: right),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({required this.entry});

  final MapEntry<String, String> entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.key,
          style: const TextStyle(
            fontSize: 12,
            color: SaturColors.onSurfaceVariant,
          ),
        ),
        Text(entry.value),
      ],
    );
  }
}
```

(Keep the existing `if (specs.isEmpty) return const SizedBox.shrink();`, the container, and the „Specyfikacja” title unchanged; only the per-entry column list is replaced by `..._rows()`.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/catalog/ && flutter analyze lib/features/catalog`
Expected: PASS, no analyzer issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/catalog/domain/product_detail.dart \
  lib/features/catalog/presentation/product_detail/widgets/product_detail_info.dart \
  lib/features/catalog/presentation/product_detail/widgets/product_specs_section.dart \
  test/features/catalog
git commit -m "$(cat <<'EOF'
feat: show discount price and two-column specs on product detail.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 2: `ProductDetail.defaultVariantCode` + repository mapping

**Files:**
- Modify: `lib/features/catalog/domain/product_detail.dart`
- Modify: `lib/features/catalog/data/http_catalog_repository.dart` (`fetchProduct`, `_pricesFromDefaultVariant`)
- Test: `test/features/catalog/data/http_catalog_repository_test.dart` (append inside `main()`)

**Interfaces:**
- Consumes: Task 1's `ProductDetail`.
- Produces: `String? ProductDetail.defaultVariantCode` (constructor named param, in `props`) — Task 8 passes it to the footer. Value is the last path segment of the `defaultVariant` IRI (e.g. `58288-variant-0`), `null` when there is no default variant.

- [ ] **Step 1: Write the failing tests**

Append inside `main()` of `test/features/catalog/data/http_catalog_repository_test.dart` (add `import 'package:satur_app/features/catalog/domain/product_detail.dart';` at the top):

```dart
  ApiClient clientWith(Map<String, Object> jsonByPath) {
    return ApiClient(
      httpClient: MockClient((request) async {
        final body = jsonByPath[request.url.path];
        if (body == null) return http.Response('not found', 404);
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'http://example.test',
    );
  }

  test('fetchProduct parses defaultVariantCode from the defaultVariant IRI',
      () async {
    final repo = HttpCatalogRepository(
      clientWith({
        '/api/v2/shop/products/58288': {
          'code': '58288',
          'name': 'Maxi Cosi',
          'defaultVariant': '/api/v2/shop/product-variants/58288-variant-0',
        },
        '/api/v2/shop/product-variants/58288-variant-0': {
          'price': 7127,
          'originalPrice': 8000,
        },
      }),
    );

    final result = await repo.fetchProduct('58288');

    final detail = (result as Success<ProductDetail, CatalogFailure>).value;
    expect(detail.defaultVariantCode, '58288-variant-0');
    expect(detail.priceGross, 7127);
  });

  test('fetchProduct leaves defaultVariantCode null without a default variant',
      () async {
    final repo = HttpCatalogRepository(
      clientWith({
        '/api/v2/shop/products/58288': {'code': '58288', 'name': 'Maxi Cosi'},
      }),
    );

    final result = await repo.fetchProduct('58288');

    final detail = (result as Success<ProductDetail, CatalogFailure>).value;
    expect(detail.defaultVariantCode, isNull);
    expect(detail.priceGross, isNull);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/catalog/data/http_catalog_repository_test.dart`
Expected: FAIL — `The getter 'defaultVariantCode' isn't defined for the class 'ProductDetail'`.

- [ ] **Step 3: Implement**

`product_detail.dart`: add `this.defaultVariantCode,` to the constructor (after `this.specs = const {},`), `final String? defaultVariantCode;` next to the other fields, and `defaultVariantCode,` at the end of `props`.

`http_catalog_repository.dart`: in the `ProductDetail(...)` built by `fetchProduct`, add `defaultVariantCode: _variantCodeFromIri(map['defaultVariant']),`. Then replace `_pricesFromDefaultVariant`'s first lines and add the helper:

```dart
  static String? _variantCodeFromIri(Object? iri) {
    if (iri is! String || iri.isEmpty) return null;
    final code = iri.split('/').last;
    return code.isEmpty ? null : code;
  }

  Future<(int?, int?)> _pricesFromDefaultVariant(Object? defaultVariant) async {
    final code = _variantCodeFromIri(defaultVariant);
    if (code == null) return (null, null);
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v2/shop/product-variants/$code',
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    // ... rest unchanged
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/catalog/ && flutter analyze lib/features/catalog`
Expected: PASS (existing list/404 tests still green).

- [ ] **Step 5: Commit**

```bash
git add lib/features/catalog test/features/catalog/data/http_catalog_repository_test.dart
git commit -m "$(cat <<'EOF'
feat: expose default variant code on product detail.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 3: `ApiClient.patch` (merge-patch) and `delete`

**Files:**
- Modify: `lib/core/network/api_client.dart`
- Test: `test/core/network/api_client_test.dart` (append inside `main()`)

**Interfaces:**
- Consumes: existing `_send`, `_uri`, `tokenProvider`.
- Produces (Task 5 relies on these exact signatures):

```dart
Future<Result<T, ApiFailure>> patch<T>(String path, {Object? body, required T Function(Object? json) decode});
Future<Result<T, ApiFailure>> delete<T>(String path, {required T Function(Object? json) decode});
```

`patch` sends `Content-Type: application/merge-patch+json` (the `http` package appends `; charset=utf-8` for String bodies, so tests use `startsWith`). `delete` sends no `Content-Type` and no body; an empty `204` decodes as `null`. `get`/`post` behaviour is unchanged.

- [ ] **Step 1: Write the failing tests**

Append inside `main()` of `test/core/network/api_client_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/network/api_client_test.dart`
Expected: FAIL (compile) — `The method 'patch' isn't defined for the type 'ApiClient'`.

- [ ] **Step 3: Implement**

In `lib/core/network/api_client.dart`, replace `_headers`'s `jsonBody` flag with a `contentType` string, update `post`, and add the two methods:

```dart
  static const _jsonContentType = 'application/json';
  static const _mergePatchContentType = 'application/merge-patch+json';

  Future<Map<String, String>> _headers({String? contentType}) async {
    final headers = <String, String>{
      // Sylius collections need Hydra (`hydra:member`); application/json returns a bare array.
      'Accept': 'application/ld+json',
    };
    if (contentType != null) {
      headers['Content-Type'] = contentType;
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
```

In `post`, change `headers: await _headers(jsonBody: true),` to `headers: await _headers(contentType: _jsonContentType),`. Then add after `post`:

```dart
  /// Sylius/API Platform item updates require `application/merge-patch+json`.
  Future<Result<T, ApiFailure>> patch<T>(
    String path, {
    Object? body,
    required T Function(Object? json) decode,
  }) {
    return _send<T>(
      () async => _http
          .patch(
            _uri(path),
            headers: await _headers(contentType: _mergePatchContentType),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout),
      decode: decode,
    );
  }

  Future<Result<T, ApiFailure>> delete<T>(
    String path, {
    required T Function(Object? json) decode,
  }) {
    return _send<T>(
      () async => _http
          .delete(_uri(path), headers: await _headers())
          .timeout(timeout),
      decode: decode,
    );
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/network/api_client_test.dart && flutter analyze lib/core`
Expected: PASS (all old `get`/`post` tests still green).

- [ ] **Step 5: Commit**

```bash
git add lib/core/network/api_client.dart test/core/network/api_client_test.dart
git commit -m "$(cat <<'EOF'
feat: add merge-patch and delete to ApiClient.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 4: Cart domain models, failures, repository + token-store interfaces

**Files:**
- Create: `lib/features/cart/domain/cart_item.dart`, `cart.dart`, `cart_failure.dart`, `cart_repository.dart`, `cart_token_store.dart`
- Create: `lib/features/cart/data/memory_cart_token_store.dart`
- Test: `test/features/cart/domain/cart_test.dart`, `test/features/cart/data/memory_cart_token_store_test.dart`

**Interfaces:**
- Consumes: `Result<T, E>` from `lib/core/result/result.dart`.
- Produces (used by every later cart task):

```dart
final class CartItem extends Equatable {
  const CartItem({required String id, required String variantCode, required String productName,
      String? variantName, required int quantity, required int unitPrice, required int total, String? imageUrl});
}
final class Cart extends Equatable {
  const Cart({required String tokenValue, List<CartItem> items = const [],
      required int itemsTotal, required int shippingTotal, required int total});
  bool get isEmpty; int get itemCount; // sum of quantities
}
sealed class CartFailure; CartNetworkFailure([String? message]);
  CartHttpFailure({required int statusCode, String? message}); CartUnknownFailure([String? message]);
abstract interface class CartRepository { fetchCart / addItem / updateQuantity / removeItem / reset }
abstract interface class CartTokenStore { Future<String?> read(); Future<void> save(String); Future<void> clear(); }
final class MemoryCartTokenStore implements CartTokenStore
```

- [ ] **Step 1: Write the failing tests**

`test/features/cart/domain/cart_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';

CartItem _item(String id, int qty) => CartItem(
      id: id,
      variantCode: 'v-$id',
      productName: 'P$id',
      quantity: qty,
      unitPrice: 100,
      total: 100 * qty,
    );

void main() {
  test('isEmpty and itemCount reflect items', () {
    const empty = Cart(
      tokenValue: 't',
      itemsTotal: 0,
      shippingTotal: 0,
      total: 0,
    );
    final full = Cart(
      tokenValue: 't',
      items: [_item('1', 2), _item('2', 3)],
      itemsTotal: 500,
      shippingTotal: 0,
      total: 500,
    );

    expect(empty.isEmpty, isTrue);
    expect(empty.itemCount, 0);
    expect(full.isEmpty, isFalse);
    expect(full.itemCount, 5);
  });

  test('carts with equal fields are equal', () {
    Cart build() => Cart(
          tokenValue: 't',
          items: [_item('1', 1)],
          itemsTotal: 100,
          shippingTotal: 0,
          total: 100,
        );
    expect(build(), build());
  });
}
```

`test/features/cart/data/memory_cart_token_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/data/memory_cart_token_store.dart';

void main() {
  test('read returns null until saved, then the token, then null after clear',
      () async {
    final store = MemoryCartTokenStore();
    expect(await store.read(), isNull);

    await store.save('tok-1');
    expect(await store.read(), 'tok-1');

    await store.clear();
    expect(await store.read(), isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/cart/`
Expected: FAIL — `Target of URI doesn't exist: 'package:satur_app/features/cart/domain/cart.dart'`.

- [ ] **Step 3: Implement**

`lib/features/cart/domain/cart_item.dart`:

```dart
import 'package:equatable/equatable.dart';

final class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.variantCode,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.imageUrl,
  });

  /// Sylius order-item id (int in JSON, kept as String for path building).
  final String id;
  final String variantCode;
  final String productName;
  final String? variantName;
  final int quantity;

  /// Grosze.
  final int unitPrice;
  final int total;
  final String? imageUrl;

  @override
  List<Object?> get props => [
        id,
        variantCode,
        productName,
        variantName,
        quantity,
        unitPrice,
        total,
        imageUrl,
      ];
}
```

`lib/features/cart/domain/cart.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:satur_app/features/cart/domain/cart_item.dart';

final class Cart extends Equatable {
  const Cart({
    required this.tokenValue,
    this.items = const [],
    required this.itemsTotal,
    required this.shippingTotal,
    required this.total,
  });

  final String tokenValue;
  final List<CartItem> items;

  /// Grosze.
  final int itemsTotal;
  final int shippingTotal;
  final int total;

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [tokenValue, items, itemsTotal, shippingTotal, total];
}
```

`lib/features/cart/domain/cart_failure.dart`:

```dart
sealed class CartFailure {
  const CartFailure();
}

final class CartNetworkFailure extends CartFailure {
  const CartNetworkFailure([this.message]);
  final String? message;
}

final class CartHttpFailure extends CartFailure {
  const CartHttpFailure({required this.statusCode, this.message});
  final int statusCode;
  final String? message;
}

final class CartUnknownFailure extends CartFailure {
  const CartUnknownFailure([this.message]);
  final String? message;
}
```

`lib/features/cart/domain/cart_token_store.dart`:

```dart
abstract interface class CartTokenStore {
  Future<String?> read();

  Future<void> save(String token);

  Future<void> clear();
}
```

`lib/features/cart/domain/cart_repository.dart`:

```dart
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';

abstract interface class CartRepository {
  /// `Success(null)` when no token is stored or the server says the cart no longer exists.
  Future<Result<Cart?, CartFailure>> fetchCart();

  Future<Result<Cart, CartFailure>> addItem({
    required String variantCode,
    int quantity = 1,
  });

  Future<Result<Cart, CartFailure>> updateQuantity({
    required String itemId,
    required int quantity,
  });

  Future<Result<Cart, CartFailure>> removeItem(String itemId);

  /// Drops the stored token (logout).
  Future<void> reset();
}
```

`lib/features/cart/data/memory_cart_token_store.dart`:

```dart
import 'package:satur_app/features/cart/domain/cart_token_store.dart';

/// In-memory [CartTokenStore] for tests and non-persistent environments.
final class MemoryCartTokenStore implements CartTokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/cart/ && flutter analyze lib/features/cart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cart test/features/cart
git commit -m "$(cat <<'EOF'
feat: add cart domain models and token store interface.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 5: `HttpCartRepository` (mock-http TDD)

**Files:**
- Create: `lib/features/cart/data/http_cart_repository.dart`
- Test: `test/features/cart/data/http_cart_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient.get/post/patch/delete` (Task 3), `CartRepository`/`CartTokenStore`/`Cart`/`CartItem`/`CartFailure` (Task 4), `MemoryCartTokenStore` (tests).
- Produces: `HttpCartRepository(ApiClient api, CartTokenStore tokens) implements CartRepository` (DI in Task 7).

- [ ] **Step 0: Re-verify the add-item contract with live `curl`** (IRI vs bare code)

The plan author ran this on 2026-11-24 (both forms → `200`, POST → `405`). Re-run it; if the result differs, use whichever `productVariant` form the API accepts **and update the `productVariant` expectation in test 4 below to match**.

```bash
B=http://localhost:5051/api/v2/shop
TOK=$(curl -s -X POST -H 'Content-Type: application/json' -H 'Accept: application/ld+json' -d '{}' $B/orders | python3 -c "import sys,json; print(json.load(sys.stdin)['tokenValue'])")
# product variant code from the catalog (e.g. 58288-variant-0):
curl -s -H 'Accept: application/ld+json' "$B/products?itemsPerPage=1" | python3 -c "import sys,json; m=json.load(sys.stdin)['hydra:member'][0]; print(m['code'], m['defaultVariant'])"

# 1) IRI form  -> expect 200
curl -s -o /dev/null -w "%{http_code}\n" -X PATCH -H 'Content-Type: application/merge-patch+json' -H 'Accept: application/ld+json' \
  -d '{"productVariant":"/api/v2/shop/product-variants/58288-variant-0","quantity":1}' "$B/orders/$TOK/items"
# 2) bare code -> 200 on 2026-11-24
curl -s -o /dev/null -w "%{http_code}\n" -X PATCH -H 'Content-Type: application/merge-patch+json' -H 'Accept: application/ld+json' \
  -d '{"productVariant":"58288-variant-0","quantity":1}' "$B/orders/$TOK/items"
# 3) POST is not allowed -> expect 405
curl -s -o /dev/null -w "%{http_code}\n" -X POST -H 'Content-Type: application/json' -H 'Accept: application/ld+json' \
  -d '{"productVariant":"/api/v2/shop/product-variants/58288-variant-0","quantity":1}' "$B/orders/$TOK/items"
# 4) item shape: `variant` is an embedded object with `code`; no `variantName`
curl -s -H 'Accept: application/ld+json' "$B/orders/$TOK" | python3 -c "import sys,json; o=json.load(sys.stdin); print(o['itemsTotal'],o['shippingTotal'],o['total']); print(o['items'][0])"
```

Expected: `200`, `200`, `405`, then totals and an item whose `variant` is a dict containing `code`.

- [ ] **Step 1: Write the failing tests**

`test/features/cart/data/http_cart_repository_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/cart/data/http_cart_repository_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:satur_app/features/cart/data/http_cart_repository.dart'`.

- [ ] **Step 3: Implement**

`lib/features/cart/data/http_cart_repository.dart`:

```dart
import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/network/api_failure.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/domain/cart_repository.dart';
import 'package:satur_app/features/cart/domain/cart_token_store.dart';

final class HttpCartRepository implements CartRepository {
  HttpCartRepository(this._api, this._tokens);

  static const _orders = '/api/v2/shop/orders';
  static const _variants = '/api/v2/shop/product-variants';

  final ApiClient _api;
  final CartTokenStore _tokens;

  /// variantCode -> name + thumbnail, filled lazily (N+1 accepted).
  final Map<String, _VariantInfo> _variantCache = {};

  @override
  Future<Result<Cart?, CartFailure>> fetchCart() async {
    final token = await _tokens.read();
    if (token == null) return const Success(null);

    final result = await _getOrder(token);
    switch (result) {
      case Success(:final value):
        return Success(value);
      case Failure(:final error):
        if (_isNotFound(error)) {
          await _tokens.clear();
          return const Success(null);
        }
        return Failure(_mapFailure(error));
    }
  }

  @override
  Future<Result<Cart, CartFailure>> addItem({
    required String variantCode,
    int quantity = 1,
  }) async {
    final stored = await _tokens.read();
    final String token;
    final bool freshlyCreated;
    if (stored != null) {
      token = stored;
      freshlyCreated = false;
    } else {
      final created = await _createCart();
      if (created case Failure(:final error)) {
        return Failure(_mapFailure(error));
      }
      token = (created as Success<String, ApiFailure>).value;
      freshlyCreated = true;
    }

    var result = await _patchAdd(token, variantCode, quantity);

    // Stored cart expired server-side: recreate once and retry once.
    if (!freshlyCreated &&
        result is Failure<Cart, ApiFailure> &&
        _isNotFound(result.error)) {
      await _tokens.clear();
      final created = await _createCart();
      if (created case Failure(:final error)) {
        return Failure(_mapFailure(error));
      }
      final newToken = (created as Success<String, ApiFailure>).value;
      result = await _patchAdd(newToken, variantCode, quantity);
    }
    return _toCartResult(result);
  }

  @override
  Future<Result<Cart, CartFailure>> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final token = await _tokens.read();
    if (token == null) return const Failure(CartHttpFailure(statusCode: 404));

    final response = await _api.patch<Map<String, dynamic>>(
      '$_orders/$token/items/$itemId',
      body: {'quantity': quantity},
      decode: _asMap,
    );
    return _finishMutation(await _toCart(response));
  }

  @override
  Future<Result<Cart, CartFailure>> removeItem(String itemId) async {
    final token = await _tokens.read();
    if (token == null) return const Failure(CartHttpFailure(statusCode: 404));

    final deleted = await _api.delete<Object?>(
      '$_orders/$token/items/$itemId',
      decode: (_) => null,
    );
    if (deleted case Failure(:final error)) {
      return _finishMutation(Failure(error));
    }
    return _finishMutation(await _getOrder(token));
  }

  @override
  Future<void> reset() => _tokens.clear();

  // ---- helpers ----

  static Map<String, dynamic> _asMap(Object? json) =>
      Map<String, dynamic>.from(json as Map);

  static bool _isNotFound(ApiFailure e) =>
      e is ApiHttpFailure && e.statusCode == 404;

  Future<Result<String, ApiFailure>> _createCart() async {
    final response = await _api.post<String>(
      _orders,
      body: const <String, Object?>{},
      decode: (json) => (json as Map)['tokenValue'] as String,
    );
    if (response case Success(:final value)) {
      await _tokens.save(value);
    }
    return response;
  }

  Future<Result<Cart, ApiFailure>> _patchAdd(
    String token,
    String variantCode,
    int quantity,
  ) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '$_orders/$token/items',
      body: {
        'productVariant': '$_variants/$variantCode',
        'quantity': quantity,
      },
      decode: _asMap,
    );
    return _toCart(response);
  }

  Future<Result<Cart, ApiFailure>> _getOrder(String token) async {
    final response = await _api.get<Map<String, dynamic>>(
      '$_orders/$token',
      decode: _asMap,
    );
    return _toCart(response);
  }

  Future<Result<Cart, ApiFailure>> _toCart(
    Result<Map<String, dynamic>, ApiFailure> response,
  ) async {
    switch (response) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        try {
          return Success(await _cartFromJson(value));
        } catch (e) {
          return Failure(ApiParseFailure(e.toString()));
        }
    }
  }

  /// A 404 on a mutation means the cart is gone: drop the token, surface the failure.
  Future<Result<Cart, CartFailure>> _finishMutation(
    Result<Cart, ApiFailure> result,
  ) async {
    if (result case Failure(:final error) when _isNotFound(error)) {
      await _tokens.clear();
    }
    return _toCartResult(result);
  }

  Result<Cart, CartFailure> _toCartResult(Result<Cart, ApiFailure> result) {
    return switch (result) {
      Success(:final value) => Success(value),
      Failure(:final error) => Failure(_mapFailure(error)),
    };
  }

  Future<Cart> _cartFromJson(Map<String, dynamic> order) async {
    final rawItems = order['items'] as List<dynamic>? ?? const [];
    final items = await Future.wait(
      rawItems.map((raw) => _itemFromJson(Map<String, dynamic>.from(raw as Map))),
    );
    return Cart(
      tokenValue: order['tokenValue'] as String? ?? '',
      items: items,
      itemsTotal: (order['itemsTotal'] as num?)?.toInt() ?? 0,
      shippingTotal: (order['shippingTotal'] as num?)?.toInt() ?? 0,
      total: (order['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<CartItem> _itemFromJson(Map<String, dynamic> json) async {
    final code = _variantCode(json['variant']);
    final info = code == null ? const _VariantInfo() : await _variantInfo(code);
    return CartItem(
      id: '${json['id']}',
      variantCode: code ?? '',
      productName: json['productName'] as String? ?? '',
      variantName: info.name,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      imageUrl: info.imageUrl,
    );
  }

  /// Live API embeds the variant as an object with `code`; a bare IRI string is accepted too.
  static String? _variantCode(Object? variant) {
    if (variant is Map) {
      final code = variant['code'];
      if (code is String && code.isNotEmpty) return code;
      final iri = variant['@id'];
      if (iri is String && iri.isNotEmpty) return iri.split('/').last;
      return null;
    }
    if (variant is String && variant.isNotEmpty) return variant.split('/').last;
    return null;
  }

  Future<_VariantInfo> _variantInfo(String code) async {
    final cached = _variantCache[code];
    if (cached != null) return cached;

    final variant = await _api.get<Map<String, dynamic>>(
      '$_variants/$code',
      decode: _asMap,
    );
    switch (variant) {
      case Failure():
        return const _VariantInfo(); // not cached: retry on next fetch
      case Success(:final value):
        final name = (value['name'] as String?)?.trim();
        final info = _VariantInfo(
          name: (name == null || name.isEmpty) ? null : name,
          imageUrl: await _productImage(value['product']),
        );
        _variantCache[code] = info;
        return info;
    }
  }

  Future<String?> _productImage(Object? productIri) async {
    if (productIri is! String || productIri.isEmpty) return null;
    final product = await _api.get<Map<String, dynamic>>(productIri, decode: _asMap);
    switch (product) {
      case Failure():
        return null;
      case Success(:final value):
        final images = value['images'];
        if (images is List && images.isNotEmpty) {
          final first = images.first;
          if (first is Map && first['path'] is String) {
            return first['path'] as String;
          }
        }
        return null;
    }
  }

  CartFailure _mapFailure(ApiFailure err) {
    return switch (err) {
      ApiNetworkFailure(:final message) => CartNetworkFailure(message),
      ApiTimeoutFailure() => const CartNetworkFailure('timeout'),
      ApiHttpFailure(:final statusCode, :final body) =>
        CartHttpFailure(statusCode: statusCode, message: body),
      ApiParseFailure(:final message) => CartUnknownFailure(message),
    };
  }
}

final class _VariantInfo {
  const _VariantInfo({this.name, this.imageUrl});
  final String? name;
  final String? imageUrl;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/cart/data/ && flutter analyze lib/features/cart`
Expected: PASS (12 tests), no analyzer issues. If a `switch` pattern complains about generics inference, annotate the local with its explicit `Result<..., ApiFailure>` type — do not change behaviour.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cart/data/http_cart_repository.dart test/features/cart/data/http_cart_repository_test.dart
git commit -m "$(cat <<'EOF'
feat: add HttpCartRepository for Sylius shop orders.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 6: `SecureCartTokenStore` + `CartState` + `CartCubit`

**Files:**
- Create: `lib/features/cart/data/secure_cart_token_store.dart`
- Create: `lib/features/cart/presentation/cart_state.dart`
- Create: `lib/features/cart/presentation/cart_cubit.dart`
- Create: `test/features/cart/support/fake_cart_repository.dart` (shared by Tasks 7–10)
- Test: `test/features/cart/presentation/cart_cubit_test.dart`

**Interfaces:**
- Consumes: `CartRepository`, `Cart`, `CartItem`, `CartFailure`, `CartTokenStore`.
- Produces:

```dart
sealed class CartState extends Equatable;
CartInitial(); CartLoading();
CartLoaded(Cart? cart, {Set<String> busyItemIds = const {}, bool adding = false}) { CartLoaded copyWith({Set<String>? busyItemIds, bool? adding}); }
CartFailureState(CartFailure failure);

class CartCubit extends Cubit<CartState> {
  CartCubit(CartRepository repository);   // starts as CartInitial
  Future<void> refresh();
  Future<bool> addItem(String variantCode, {int quantity = 1});
  Future<bool> updateQuantity(String itemId, int quantity);
  Future<bool> removeItem(String itemId);
  Future<void> reset();
}
class SecureCartTokenStore implements CartTokenStore { SecureCartTokenStore([FlutterSecureStorage? storage]); }  // key 'cart.token'
// test support:
class FakeCartRepository implements CartRepository; const kTestItem; Cart testCart({List<CartItem> items})
```

`SecureCartTokenStore` mirrors `SecureSessionStore`, which has no unit test (it would need a platform plugin); it is covered by `flutter analyze` here and by the restart check in Task 11.

- [ ] **Step 1: Write the test fake and the failing cubit tests**

`test/features/cart/support/fake_cart_repository.dart`:

```dart
import 'dart:async';

import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/domain/cart_repository.dart';

const kTestItem = CartItem(
  id: '101',
  variantCode: '58288-variant-0',
  productName: 'Maxi Cosi',
  variantName: 'Classic Black',
  quantity: 1,
  unitPrice: 7127,
  total: 7127,
);

/// Shipping fixed at 1000 grosze (live API adds a shipment as soon as a cart has items).
Cart testCart({List<CartItem> items = const [kTestItem]}) {
  final itemsTotal = items.fold<int>(0, (sum, i) => sum + i.total);
  return Cart(
    tokenValue: 'tok-1',
    items: items,
    itemsTotal: itemsTotal,
    shippingTotal: 1000,
    total: itemsTotal + 1000,
  );
}

final class FakeCartRepository implements CartRepository {
  Result<Cart?, CartFailure> fetchResult = const Success(null);
  Result<Cart, CartFailure> addResult = const Failure(CartUnknownFailure());
  Result<Cart, CartFailure> updateResult = const Failure(CartUnknownFailure());
  Result<Cart, CartFailure> removeResult = const Failure(CartUnknownFailure());

  /// When set, mutating calls wait on it (to observe in-flight state).
  Completer<void>? gate;

  int fetchCalls = 0;
  int resetCalls = 0;
  final addCalls = <String>[];
  final updateCalls = <(String, int)>[];
  final removeCalls = <String>[];

  @override
  Future<Result<Cart?, CartFailure>> fetchCart() async {
    fetchCalls++;
    return fetchResult;
  }

  @override
  Future<Result<Cart, CartFailure>> addItem({
    required String variantCode,
    int quantity = 1,
  }) async {
    addCalls.add(variantCode);
    await gate?.future;
    return addResult;
  }

  @override
  Future<Result<Cart, CartFailure>> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    updateCalls.add((itemId, quantity));
    await gate?.future;
    return updateResult;
  }

  @override
  Future<Result<Cart, CartFailure>> removeItem(String itemId) async {
    removeCalls.add(itemId);
    await gate?.future;
    return removeResult;
  }

  @override
  Future<void> reset() async {
    resetCalls++;
  }
}
```

`test/features/cart/presentation/cart_cubit_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_state.dart';

import '../support/fake_cart_repository.dart';

void main() {
  late FakeCartRepository repo;
  late CartCubit cubit;

  setUp(() {
    repo = FakeCartRepository();
    cubit = CartCubit(repo);
  });

  tearDown(() => cubit.close());

  Future<List<CartState>> record(Future<void> Function() action) async {
    final emitted = <CartState>[];
    final sub = cubit.stream.listen(emitted.add);
    await action();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return emitted;
  }

  test('refresh with a stored cart emits loading then loaded', () async {
    repo.fetchResult = Success(testCart());

    final states = await record(cubit.refresh);

    expect(states, [const CartLoading(), CartLoaded(testCart())]);
  });

  test('refresh with no cart emits loaded(null)', () async {
    final states = await record(cubit.refresh);

    expect(states, [const CartLoading(), const CartLoaded(null)]);
  });

  test('refresh failure emits CartFailureState', () async {
    repo.fetchResult = const Failure(CartNetworkFailure());

    await cubit.refresh();

    expect(cubit.state, isA<CartFailureState>());
    expect((cubit.state as CartFailureState).failure, isA<CartNetworkFailure>());
  });

  test('refresh while already loaded does not flash the loading state',
      () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();
    // A different cart: Bloc drops emits of a state equal to the current one.
    final emptied = testCart(items: const []);
    repo.fetchResult = Success(emptied);

    final states = await record(cubit.refresh);

    expect(states, [CartLoaded(emptied)]);
  });

  test('addItem success sets adding then emits the new cart and returns true',
      () async {
    repo.addResult = Success(testCart());

    late bool ok;
    final states = await record(() async {
      ok = await cubit.addItem('58288-variant-0');
    });

    expect(ok, isTrue);
    expect(repo.addCalls, ['58288-variant-0']);
    expect(states, [const CartLoaded(null, adding: true), CartLoaded(testCart())]);
  });

  test('addItem failure clears adding and returns false', () async {
    repo.addResult = const Failure(CartHttpFailure(statusCode: 422));

    final ok = await cubit.addItem('x');

    expect(ok, isFalse);
    expect(cubit.state, const CartLoaded(null));
  });

  test('addItem is ignored while another add is in flight', () async {
    repo.addResult = Success(testCart());
    final gate = Completer<void>();
    repo.gate = gate;

    final first = cubit.addItem('a');
    final second = await cubit.addItem('a');
    gate.complete();

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repo.addCalls, ['a']);
  });

  test('updateQuantity marks the item busy, then emits the new cart', () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();
    final updated = testCart(
      items: const [
        CartItem(
          id: '101',
          variantCode: '58288-variant-0',
          productName: 'Maxi Cosi',
          variantName: 'Classic Black',
          quantity: 2,
          unitPrice: 7127,
          total: 14254,
        ),
      ],
    );
    repo.updateResult = Success(updated);
    final gate = Completer<void>();
    repo.gate = gate;

    final future = cubit.updateQuantity('101', 2);
    expect((cubit.state as CartLoaded).busyItemIds, {'101'});
    expect(await cubit.updateQuantity('101', 3), isFalse); // re-entrant ignored
    gate.complete();

    expect(await future, isTrue);
    expect(cubit.state, CartLoaded(updated));
    expect(repo.updateCalls, [('101', 2)]);
  });

  test('updateQuantity failure keeps the old cart and clears busy', () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();
    repo.updateResult = const Failure(CartNetworkFailure());

    final ok = await cubit.updateQuantity('101', 2);

    expect(ok, isFalse);
    expect(cubit.state, CartLoaded(testCart()));
  });

  test('updateQuantity before the cart is loaded returns false', () async {
    expect(await cubit.updateQuantity('101', 2), isFalse);
    expect(repo.updateCalls, isEmpty);
  });

  test('removeItem success emits the new cart', () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();
    final empty = testCart(items: const []);
    repo.removeResult = Success(empty);

    final ok = await cubit.removeItem('101');

    expect(ok, isTrue);
    expect(repo.removeCalls, ['101']);
    expect(cubit.state, CartLoaded(empty));
  });

  test('reset clears the repository and returns to initial', () async {
    repo.fetchResult = Success(testCart());
    await cubit.refresh();

    await cubit.reset();

    expect(repo.resetCalls, 1);
    expect(cubit.state, const CartInitial());
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/cart/presentation/cart_cubit_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../cart_cubit.dart'`.

- [ ] **Step 3: Implement**

`lib/features/cart/presentation/cart_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';

sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => const [];
}

final class CartInitial extends CartState {
  const CartInitial();
}

final class CartLoading extends CartState {
  const CartLoading();
}

/// [cart] == null means "no cart yet" (shown as empty).
final class CartLoaded extends CartState {
  const CartLoaded(
    this.cart, {
    this.busyItemIds = const {},
    this.adding = false,
  });

  final Cart? cart;
  final Set<String> busyItemIds;
  final bool adding;

  CartLoaded copyWith({Set<String>? busyItemIds, bool? adding}) => CartLoaded(
        cart,
        busyItemIds: busyItemIds ?? this.busyItemIds,
        adding: adding ?? this.adding,
      );

  @override
  List<Object?> get props => [cart, busyItemIds, adding];
}

final class CartFailureState extends CartState {
  const CartFailureState(this.failure);

  final CartFailure failure;

  @override
  List<Object?> get props => [failure];
}
```

`lib/features/cart/presentation/cart_cubit.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/domain/cart_repository.dart';
import 'package:satur_app/features/cart/presentation/cart_state.dart';

/// App-level cart state shared by PDP, Koszyk tab and (later) a badge.
final class CartCubit extends Cubit<CartState> {
  CartCubit(this._repository) : super(const CartInitial());

  final CartRepository _repository;

  Future<void> refresh() async {
    if (state is! CartLoaded) emit(const CartLoading());
    final result = await _repository.fetchCart();
    switch (result) {
      case Success(:final value):
        final current = state;
        emit(
          CartLoaded(
            value,
            busyItemIds: current is CartLoaded ? current.busyItemIds : const {},
            adding: current is CartLoaded && current.adding,
          ),
        );
      case Failure(:final error):
        emit(CartFailureState(error));
    }
  }

  /// Returns true on success. Re-entrant calls while an add is in flight are ignored (false).
  Future<bool> addItem(String variantCode, {int quantity = 1}) async {
    final current = state;
    if (current is CartLoaded && current.adding) return false;

    final base = current is CartLoaded ? current : const CartLoaded(null);
    emit(base.copyWith(adding: true));

    final result = await _repository.addItem(
      variantCode: variantCode,
      quantity: quantity,
    );

    final latest = state;
    final busy = latest is CartLoaded ? latest.busyItemIds : const <String>{};
    switch (result) {
      case Success(:final value):
        emit(CartLoaded(value, busyItemIds: busy));
        return true;
      case Failure():
        emit(latest is CartLoaded ? latest.copyWith(adding: false) : latest);
        return false;
    }
  }

  Future<bool> updateQuantity(String itemId, int quantity) {
    return _mutate(
      itemId,
      () => _repository.updateQuantity(itemId: itemId, quantity: quantity),
    );
  }

  Future<bool> removeItem(String itemId) {
    return _mutate(itemId, () => _repository.removeItem(itemId));
  }

  Future<void> reset() async {
    await _repository.reset();
    emit(const CartInitial());
  }

  Future<bool> _mutate(
    String itemId,
    Future<Result<Cart, CartFailure>> Function() call,
  ) async {
    final current = state;
    if (current is! CartLoaded || current.busyItemIds.contains(itemId)) {
      return false;
    }
    emit(current.copyWith(busyItemIds: {...current.busyItemIds, itemId}));

    final result = await call();

    final latest = state;
    if (latest is! CartLoaded) return result is Success; // reset() ran meanwhile
    final busy = {...latest.busyItemIds}..remove(itemId);
    switch (result) {
      case Success(:final value):
        emit(CartLoaded(value, busyItemIds: busy, adding: latest.adding));
        return true;
      case Failure():
        emit(latest.copyWith(busyItemIds: busy));
        return false;
    }
  }
}
```

`lib/features/cart/data/secure_cart_token_store.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:satur_app/features/cart/domain/cart_token_store.dart';

final class SecureCartTokenStore implements CartTokenStore {
  SecureCartTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'cart.token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  @override
  Future<void> save(String token) => _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/cart/ && flutter analyze lib/features/cart test/features/cart`
Expected: PASS, no analyzer issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cart test/features/cart
git commit -m "$(cat <<'EOF'
feat: add CartCubit and secure cart token store.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 7: Wire DI + `CartCubit` at app root + logout reset

**Files:**
- Create: `lib/features/cart/presentation/cart_session_listener.dart`
- Modify: `lib/app/di.dart`
- Modify: `lib/app/app.dart`
- Test: `test/features/cart/presentation/cart_session_listener_test.dart`

**Interfaces:**
- Consumes: `SessionCubit` (state `AuthSession?`), `CartCubit.reset()`, `HttpCartRepository`, `SecureCartTokenStore`, `FakeCartRepository` (tests).
- Produces: `AppDependencies.cartTokenStore`, `.cartRepository`, `.cartCubit`; `CartSessionListener({required Widget child})`; `CartCubit` available via `context.read<CartCubit>()` anywhere under `MaterialApp.router` (used by Tasks 8–10).

- [ ] **Step 1: Write the failing test**

`test/features/cart/presentation/cart_session_listener_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/auth/data/memory_session_store.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_session_listener.dart';

import '../support/fake_cart_repository.dart';

void main() {
  const session = AuthSession(token: 't', email: 'a@b.pl');

  Future<(SessionCubit, MemorySessionStore, FakeCartRepository)> pump(
    WidgetTester tester,
  ) async {
    final store = MemorySessionStore();
    final sessionCubit = SessionCubit(store);
    final repo = FakeCartRepository();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: sessionCubit),
          BlocProvider<CartCubit>.value(value: CartCubit(repo)),
        ],
        child: const MaterialApp(
          home: CartSessionListener(child: SizedBox()),
        ),
      ),
    );
    return (sessionCubit, store, repo);
  }

  testWidgets('resets the cart when the session goes from set to null',
      (tester) async {
    final (sessionCubit, _, repo) = await pump(tester);

    await sessionCubit.setSession(session);
    await tester.pump();
    expect(repo.resetCalls, 0); // login keeps the cart token

    await sessionCubit.clear();
    await tester.pump();
    expect(repo.resetCalls, 1);
  });

  testWidgets('does not reset on cold-start hydrate', (tester) async {
    final (sessionCubit, store, repo) = await pump(tester);
    await store.save(session);

    await sessionCubit.hydrate(); // null -> session
    await tester.pump();

    expect(repo.resetCalls, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/cart/presentation/cart_session_listener_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../cart_session_listener.dart'`.

- [ ] **Step 3: Implement**

`lib/features/cart/presentation/cart_session_listener.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';

/// Resets the cart (drops token + state) when the user logs out (session -> null).
/// Cold-start hydrate (null -> session) and login do nothing.
class CartSessionListener extends StatelessWidget {
  const CartSessionListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, AuthSession?>(
      listenWhen: (previous, current) => previous != null && current == null,
      listener: (context, _) => context.read<CartCubit>().reset(),
      child: child,
    );
  }
}
```

`lib/app/di.dart` — add imports and wiring:

```dart
import 'package:satur_app/features/cart/data/http_cart_repository.dart';
import 'package:satur_app/features/cart/data/secure_cart_token_store.dart';
import 'package:satur_app/features/cart/domain/cart_repository.dart';
import 'package:satur_app/features/cart/domain/cart_token_store.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
```

Add to the private constructor `required this.cartTokenStore, required this.cartRepository, required this.cartCubit,`, matching fields:

```dart
  final CartTokenStore cartTokenStore;
  final CartRepository cartRepository;
  final CartCubit cartCubit;
```

and in `create()` (after `apiClient`):

```dart
    final cartTokenStore = SecureCartTokenStore();
    final cartRepository = HttpCartRepository(apiClient, cartTokenStore);
```

passing `cartTokenStore: cartTokenStore, cartRepository: cartRepository, cartCubit: CartCubit(cartRepository),` into `AppDependencies._(...)`.

`lib/app/app.dart` — replace the `BlocProvider<SessionCubit>.value(...)` root with:

```dart
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: dependencies.sessionCubit),
        BlocProvider<CartCubit>.value(value: dependencies.cartCubit),
      ],
      child: CartSessionListener(
        child: MaterialApp.router(
          title: 'Satur',
          debugShowCheckedModeBanner: false,
          theme: SaturTheme.light(),
          routerConfig: router,
        ),
      ),
    );
```

with imports for `CartCubit` and `CartSessionListener`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `make analyze && make test`
Expected: PASS, no analyzer issues.

- [ ] **Step 5: Commit**

```bash
git add lib/app lib/features/cart/presentation/cart_session_listener.dart test/features/cart/presentation/cart_session_listener_test.dart
git commit -m "$(cat <<'EOF'
feat: provide CartCubit at app root and reset it on logout.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 8: „Dodaj do koszyka” on the PDP footer → `CartCubit.addItem` + SnackBar

**Files:**
- Modify: `lib/features/catalog/presentation/product_detail/widgets/product_detail_footer.dart`
- Modify: `lib/features/catalog/presentation/product_detail/product_detail_screen.dart` (the `const ProductDetailFooter()` line)
- Test: `test/features/catalog/presentation/product_detail/product_detail_footer_test.dart`

**Interfaces:**
- Consumes: `CartCubit.addItem(String) → Future<bool>`, `CartState`/`CartLoaded.adding` (Task 6), `ProductDetail.defaultVariantCode` (Task 2), `FakeCartRepository` (Task 6), `SaturButton(isLoading:)`.
- Produces: `ProductDetailFooter({super.key, required String? variantCode})`.

- [ ] **Step 1: Write the failing tests**

`test/features/catalog/presentation/product_detail/product_detail_footer_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/widgets/product_detail_footer.dart';

import '../../../cart/support/fake_cart_repository.dart';

Future<void> _pumpFooter(
  WidgetTester tester,
  FakeCartRepository repo, {
  String? variantCode = '58288-variant-0',
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ProductDetailFooter(variantCode: variantCode),
          ),
        ),
      ),
      GoRoute(path: '/cart', builder: (_, _) => const Text('cart-page')),
    ],
  );
  await tester.pumpWidget(
    BlocProvider<CartCubit>.value(
      value: CartCubit(repo),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tap adds the default variant and shows success SnackBar with Koszyk action',
      (tester) async {
    final repo = FakeCartRepository()..addResult = Success(testCart());
    await _pumpFooter(tester, repo);

    await tester.tap(find.text('Dodaj do koszyka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.addCalls, ['58288-variant-0']);
    expect(find.text('Dodano do koszyka'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Koszyk'));
    await tester.pumpAndSettle();
    expect(find.text('cart-page'), findsOneWidget);
  });

  testWidgets('failure shows the error SnackBar', (tester) async {
    final repo = FakeCartRepository()
      ..addResult = const Failure(CartHttpFailure(statusCode: 422));
    await _pumpFooter(tester, repo);

    await tester.tap(find.text('Dodaj do koszyka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nie udało się dodać do koszyka'), findsOneWidget);
    expect(find.text('Dodano do koszyka'), findsNothing);
  });

  testWidgets('button is disabled when the product has no default variant',
      (tester) async {
    final repo = FakeCartRepository();
    await _pumpFooter(tester, repo, variantCode: null);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.text('Dodaj do koszyka'), warnIfMissed: false);
    expect(repo.addCalls, isEmpty);
  });

  testWidgets('shows a spinner and blocks a second tap while adding',
      (tester) async {
    final gate = Completer<void>();
    final repo = FakeCartRepository()
      ..addResult = Success(testCart())
      ..gate = gate;
    await _pumpFooter(tester, repo);

    await tester.tap(find.text('Dodaj do koszyka'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Dodaj do koszyka'), findsNothing);
    expect(repo.addCalls, hasLength(1));

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/catalog/presentation/product_detail/product_detail_footer_test.dart`
Expected: FAIL (compile) — `No named parameter with the name 'variantCode'`.

- [ ] **Step 3: Implement**

`lib/features/catalog/presentation/product_detail/widgets/product_detail_footer.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/core/widgets/satur_button.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_state.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_nav.dart';

class ProductDetailFooter extends StatelessWidget {
  const ProductDetailFooter({super.key, required this.variantCode});

  /// `ProductDetail.defaultVariantCode`; null disables the button.
  final String? variantCode;

  static bool _isAdding(CartState s) => s is CartLoaded && s.adding;

  Future<void> _addToCart(BuildContext context, String code) async {
    // Capture before the await: the widget may be gone when the request ends.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final added = await context.read<CartCubit>().addItem(code);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      added
          ? SnackBar(
              content: const Text('Dodano do koszyka'),
              action: SnackBarAction(
                label: 'Koszyk',
                onPressed: () => router.go('/cart'),
              ),
            )
          : const SnackBar(content: Text('Nie udało się dodać do koszyka')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = variantCode;
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: BlocBuilder<CartCubit, CartState>(
                buildWhen: (previous, current) =>
                    _isAdding(previous) != _isAdding(current),
                builder: (context, state) => SaturButton(
                  label: 'Dodaj do koszyka',
                  isLoading: _isAdding(state),
                  onPressed: code == null ? null : () => _addToCart(context, code),
                ),
              ),
            ),
            CatalogBottomNav(
              active: CatalogTab.oferta,
              onTap: (tab) => handleCatalogTabNavigation(context, tab),
            ),
          ],
        ),
      ),
    );
  }
}
```

`product_detail_screen.dart`: replace `const ProductDetailFooter(),` with `ProductDetailFooter(variantCode: product.defaultVariantCode),`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `make analyze && make test`
Expected: PASS. (Do not use `pumpAndSettle` right after the tap in the SnackBar tests: it would run past the 4 s auto-dismiss and the SnackBar would be gone.)

- [ ] **Step 5: Commit**

```bash
git add lib/features/catalog/presentation/product_detail test/features/catalog/presentation/product_detail/product_detail_footer_test.dart
git commit -m "$(cat <<'EOF'
feat: add to cart from product detail footer.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 9: Cart widgets — `CartItemTile`, `CartSummary`, `CartEmptyView`

**Files:**
- Create: `lib/features/cart/presentation/widgets/cart_item_tile.dart`, `cart_summary.dart`, `cart_empty_view.dart`
- Test: `test/features/cart/presentation/widgets/cart_item_tile_test.dart`, `cart_summary_test.dart`, `cart_empty_view_test.dart`

**Interfaces:**
- Consumes: `CartItem`, `Cart`, `formatPln`, `SaturColors`, `SaturButton`.
- Produces (used by Task 10):

```dart
CartItemTile({super.key, required CartItem item, required bool busy,
  required VoidCallback onIncrement, required VoidCallback onDecrement, required VoidCallback onRemove});
CartSummary({super.key, required Cart cart});
CartEmptyView({super.key, required VoidCallback onBrowse});
```

Tooltips (used by tests and Task 10 tests): `Zmniejsz ilość`, `Zwiększ ilość`, `Usuń`. Decrement is disabled at quantity 1 (use remove). While `busy`, the tile is dimmed (`Opacity` with key `cart-item-dim`, 0.5) and ignores taps.

- [ ] **Step 1: Write the failing tests**

`test/features/cart/presentation/widgets/cart_item_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_item_tile.dart';

CartItem _item({int qty = 2}) => CartItem(
      id: '101',
      variantCode: 'v',
      productName: 'Maxi Cosi',
      variantName: 'Classic Black',
      quantity: qty,
      unitPrice: 7127,
      total: 7127 * qty,
    );

Future<void> _pump(
  WidgetTester tester, {
  required CartItem item,
  bool busy = false,
  VoidCallback? onIncrement,
  VoidCallback? onDecrement,
  VoidCallback? onRemove,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CartItemTile(
          item: item,
          busy: busy,
          onIncrement: onIncrement ?? () {},
          onDecrement: onDecrement ?? () {},
          onRemove: onRemove ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows name, variant name, unit price and quantity', (tester) async {
    await _pump(tester, item: _item());

    expect(find.text('Maxi Cosi'), findsOneWidget);
    expect(find.text('Classic Black'), findsOneWidget);
    expect(find.text('71,27 zł'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget); // no imageUrl
  });

  testWidgets('stepper and remove invoke callbacks', (tester) async {
    var inc = 0, dec = 0, rem = 0;
    await _pump(
      tester,
      item: _item(),
      onIncrement: () => inc++,
      onDecrement: () => dec++,
      onRemove: () => rem++,
    );

    await tester.tap(find.byTooltip('Zwiększ ilość'));
    await tester.tap(find.byTooltip('Zmniejsz ilość'));
    await tester.tap(find.byTooltip('Usuń'));

    expect((inc, dec, rem), (1, 1, 1));
  });

  testWidgets('decrement is disabled at quantity 1', (tester) async {
    await _pump(tester, item: _item(qty: 1));

    final minus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(minus.onPressed, isNull);
  });

  testWidgets('busy row is dimmed and ignores taps', (tester) async {
    var inc = 0;
    await _pump(tester, item: _item(), busy: true, onIncrement: () => inc++);

    final dim = tester.widget<Opacity>(find.byKey(const Key('cart-item-dim')));
    expect(dim.opacity, 0.5);
    await tester.tap(find.byTooltip('Zwiększ ilość'), warnIfMissed: false);
    expect(inc, 0);
  });
}
```

`test/features/cart/presentation/widgets/cart_summary_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_summary.dart';

Widget _wrap(Cart cart) =>
    MaterialApp(home: Scaffold(body: CartSummary(cart: cart)));

void main() {
  testWidgets('shows items total, shipping and grand total', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Cart(
          tokenValue: 't',
          itemsTotal: 7127,
          shippingTotal: 1000,
          total: 8127,
        ),
      ),
    );

    expect(find.text('Wartość produktów'), findsOneWidget);
    expect(find.text('71,27 zł'), findsOneWidget);
    expect(find.text('Dostawa'), findsOneWidget);
    expect(find.text('10,00 zł'), findsOneWidget);
    expect(find.text('Razem'), findsOneWidget);
    expect(find.text('81,27 zł'), findsOneWidget);
  });

  testWidgets('hides the shipping row when shippingTotal is 0', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Cart(
          tokenValue: 't',
          itemsTotal: 7127,
          shippingTotal: 0,
          total: 7127,
        ),
      ),
    );

    expect(find.text('Dostawa'), findsNothing);
    expect(find.text('Razem'), findsOneWidget);
  });
}
```

`test/features/cart/presentation/widgets/cart_empty_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_empty_view.dart';

void main() {
  testWidgets('shows message and browse button that fires the callback',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartEmptyView(onBrowse: () => taps++)),
      ),
    );

    expect(find.text('Twój koszyk jest pusty'), findsOneWidget);
    await tester.tap(find.text('Przeglądaj ofertę'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/cart/presentation/widgets/`
Expected: FAIL — `Target of URI doesn't exist` for the three widget files.

- [ ] **Step 3: Implement**

`lib/features/cart/presentation/widgets/cart_item_tile.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/catalog/domain/money.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.busy,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final bool busy;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      key: const Key('cart-item-dim'),
      opacity: busy ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: busy,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SaturColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SaturColors.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(url: item.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SaturColors.onSurface,
                      ),
                    ),
                    if (item.variantName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.variantName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SaturColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      formatPln(item.unitPrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SaturColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Zmniejsz ilość',
                          icon: const Icon(Icons.remove),
                          onPressed: item.quantity > 1 ? onDecrement : null,
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Zwiększ ilość',
                          icon: const Icon(Icons.add),
                          onPressed: onIncrement,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Usuń',
                icon: const Icon(Icons.delete_outline),
                color: SaturColors.outline,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 72,
        color: SaturColors.surfaceVariant.withValues(alpha: 0.35),
        child: url == null
            ? const Icon(Icons.image_outlined, color: SaturColors.outline)
            : Image.network(
                url!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: SaturColors.outline,
                ),
              ),
      ),
    );
  }
}
```

`lib/features/cart/presentation/widgets/cart_summary.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/catalog/domain/money.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({super.key, required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaturColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaturColors.borderLight),
      ),
      child: Column(
        children: [
          _Row(label: 'Wartość produktów', value: formatPln(cart.itemsTotal)),
          if (cart.shippingTotal > 0) ...[
            const SizedBox(height: 8),
            _Row(label: 'Dostawa', value: formatPln(cart.shippingTotal)),
          ],
          const Divider(height: 24, color: SaturColors.surfaceVariant),
          _Row(label: 'Razem', value: formatPln(cart.total), emphasized: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 18 : 14,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
      color: emphasized ? SaturColors.primary : SaturColors.onSurface,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}
```

`lib/features/cart/presentation/widgets/cart_empty_view.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/core/widgets/satur_button.dart';

class CartEmptyView extends StatelessWidget {
  const CartEmptyView({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: SaturColors.outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'Twój koszyk jest pusty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              child: SaturButton(label: 'Przeglądaj ofertę', onPressed: onBrowse),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/cart/presentation/widgets/ && flutter analyze lib/features/cart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cart/presentation/widgets test/features/cart/presentation/widgets
git commit -m "$(cat <<'EOF'
feat: add cart item tile, summary and empty view widgets.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 10: `CartScreen`, route `/cart`, Koszyk tab navigation

**Files:**
- Create: `lib/features/cart/presentation/cart_screen.dart`
- Modify: `lib/app/router.dart` (add `GoRoute` `/cart`)
- Modify: `lib/features/catalog/presentation/shared/catalog_nav.dart` (koszyk → `/cart`)
- Test: `test/features/cart/presentation/cart_screen_test.dart`
- Test: `test/features/catalog/presentation/shared/catalog_nav_test.dart`

**Interfaces:**
- Consumes: `CartCubit.refresh/updateQuantity/removeItem` (Task 6), root-provided `CartCubit` (Task 7), widgets from Task 9, `CatalogBottomNav`/`handleCatalogTabNavigation`, `FakeCartRepository`.
- Produces: `CartScreen()` at route `/cart` (name `cart`); `CatalogTab.koszyk` → `context.go('/cart')`.

- [ ] **Step 1: Write the failing tests**

`test/features/cart/presentation/cart_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/cart/domain/cart_failure.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_screen.dart';

import '../support/fake_cart_repository.dart';

Future<void> _pumpCart(WidgetTester tester, FakeCartRepository repo) async {
  final router = GoRouter(
    initialLocation: '/cart',
    routes: [
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      GoRoute(path: '/products', builder: (_, _) => const Text('products-page')),
    ],
  );
  await tester.pumpWidget(
    BlocProvider<CartCubit>.value(
      value: CartCubit(repo),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('refreshes on open and lists items with totals', (tester) async {
    final repo = FakeCartRepository()..fetchResult = Success(testCart());
    await _pumpCart(tester, repo);

    expect(repo.fetchCalls, 1);
    expect(find.text('Twój koszyk'), findsOneWidget);
    expect(find.text('Maxi Cosi'), findsOneWidget);
    expect(find.text('Classic Black'), findsOneWidget);
    expect(find.text('Wartość produktów'), findsOneWidget);
    expect(find.text('Dostawa'), findsOneWidget);
    expect(find.text('Razem'), findsOneWidget);
    expect(find.text('81,27 zł'), findsOneWidget); // 7127 + 1000
  });

  testWidgets('empty cart shows the empty view and browse goes to /products',
      (tester) async {
    final repo = FakeCartRepository(); // fetchResult = Success(null)
    await _pumpCart(tester, repo);

    expect(find.text('Twój koszyk jest pusty'), findsOneWidget);
    await tester.tap(find.text('Przeglądaj ofertę'));
    await tester.pumpAndSettle();
    expect(find.text('products-page'), findsOneWidget);
  });

  testWidgets('error shows retry which refetches', (tester) async {
    final repo = FakeCartRepository()
      ..fetchResult = const Failure(CartNetworkFailure());
    await _pumpCart(tester, repo);

    expect(find.text('Nie udało się wczytać koszyka'), findsOneWidget);
    repo.fetchResult = Success(testCart());
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();

    expect(repo.fetchCalls, 2);
    expect(find.text('Maxi Cosi'), findsOneWidget);
  });

  testWidgets('increment calls updateQuantity with quantity + 1', (tester) async {
    final repo = FakeCartRepository()
      ..fetchResult = Success(testCart())
      ..updateResult = Success(testCart());
    await _pumpCart(tester, repo);

    await tester.tap(find.byTooltip('Zwiększ ilość'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, [('101', 2)]);
  });

  testWidgets('remove calls removeItem', (tester) async {
    final repo = FakeCartRepository()
      ..fetchResult = Success(testCart())
      ..removeResult = Success(testCart(items: const []));
    await _pumpCart(tester, repo);

    await tester.tap(find.byTooltip('Usuń'));
    await tester.pumpAndSettle();

    expect(repo.removeCalls, ['101']);
    expect(find.text('Twój koszyk jest pusty'), findsOneWidget);
  });

  testWidgets('failed update shows a SnackBar and keeps the list', (tester) async {
    final repo = FakeCartRepository()
      ..fetchResult = Success(testCart())
      ..updateResult = const Failure(CartNetworkFailure());
    await _pumpCart(tester, repo);

    await tester.tap(find.byTooltip('Zwiększ ilość'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nie udało się zaktualizować koszyka'), findsOneWidget);
    expect(find.text('Maxi Cosi'), findsOneWidget);
  });
}
```

`test/features/catalog/presentation/shared/catalog_nav_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_nav.dart';

void main() {
  testWidgets('Koszyk tab navigates to /cart', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: CatalogBottomNav(
                active: CatalogTab.oferta,
                onTap: (tab) => handleCatalogTabNavigation(context, tab),
              ),
            ),
          ),
        ),
        GoRoute(path: '/cart', builder: (_, _) => const Text('cart-page')),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Koszyk'));
    await tester.pumpAndSettle();

    expect(find.text('cart-page'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/cart/presentation/cart_screen_test.dart test/features/catalog/presentation/shared/catalog_nav_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../cart_screen.dart'`; nav test fails (`cart-page` not found, tab is a no-op).

- [ ] **Step 3: Implement**

`lib/features/cart/presentation/cart_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/cart/domain/cart_item.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/cart/presentation/cart_state.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_empty_view.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:satur_app/features/cart/presentation/widgets/cart_summary.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_nav.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().refresh();
  }

  /// `false` also covers “ignored while busy”; the tile ignores taps when busy,
  /// so in practice this only fires on real failures.
  Future<void> _mutate(Future<bool> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    if (ok) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Nie udało się zaktualizować koszyka')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return Scaffold(
      backgroundColor: SaturColors.surface,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  title: Text(
                    'Twój koszyk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SaturColors.onSurface,
                    ),
                  ),
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                ),
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) => switch (state) {
                    CartInitial() || CartLoading() => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    CartFailureState() => SliverFillRemaining(
                        hasScrollBody: false,
                        child: _CartError(onRetry: cubit.refresh),
                      ),
                    CartLoaded(cart: final c?, :final busyItemIds)
                        when !c.isEmpty =>
                      _CartList(
                        cart: c,
                        busyItemIds: busyItemIds,
                        onIncrement: (i) => _mutate(
                          () => cubit.updateQuantity(i.id, i.quantity + 1),
                        ),
                        onDecrement: (i) => _mutate(
                          () => cubit.updateQuantity(i.id, i.quantity - 1),
                        ),
                        onRemove: (i) => _mutate(() => cubit.removeItem(i.id)),
                      ),
                    CartLoaded() => SliverFillRemaining(
                        hasScrollBody: false,
                        child: CartEmptyView(
                          onBrowse: () => context.go('/products'),
                        ),
                      ),
                  },
                ),
              ],
            ),
          ),
          CatalogBottomNav(
            active: CatalogTab.koszyk,
            onTap: (tab) => handleCatalogTabNavigation(context, tab),
          ),
        ],
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({
    required this.cart,
    required this.busyItemIds,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final Cart cart;
  final Set<String> busyItemIds;
  final void Function(CartItem item) onIncrement;
  final void Function(CartItem item) onDecrement;
  final void Function(CartItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          for (final item in cart.items) ...[
            CartItemTile(
              item: item,
              busy: busyItemIds.contains(item.id),
              onIncrement: () => onIncrement(item),
              onDecrement: () => onDecrement(item),
              onRemove: () => onRemove(item),
            ),
            const SizedBox(height: 12),
          ],
          CartSummary(cart: cart),
        ]),
      ),
    );
  }
}

class _CartError extends StatelessWidget {
  const _CartError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nie udało się wczytać koszyka'),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Spróbuj ponownie')),
        ],
      ),
    );
  }
}
```

`lib/features/catalog/presentation/shared/catalog_nav.dart` — replace the last cases with:

```dart
    case CatalogTab.ulubione:
      break; // wishlist: no-op for now
    case CatalogTab.koszyk:
      context.go('/cart');
```

`lib/app/router.dart` — add `import 'package:satur_app/features/cart/presentation/cart_screen.dart';` and, next to `/account`:

```dart
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
```

(`CartCubit` is provided at app root, so no `BlocProvider` here.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `make analyze && make test`
Expected: PASS. If `pumpAndSettle` times out in a cart-screen test, a `CircularProgressIndicator` is still on screen: check that the fake's `fetchResult` is set before `_pumpCart`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cart/presentation/cart_screen.dart lib/app/router.dart \
  lib/features/catalog/presentation/shared/catalog_nav.dart \
  test/features/cart/presentation/cart_screen_test.dart \
  test/features/catalog/presentation/shared/catalog_nav_test.dart
git commit -m "$(cat <<'EOF'
feat: add cart screen, /cart route and Koszyk tab navigation.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

---

### Task 11: Verification and manual / API smoke notes

**Files:** none expected. Only touch code if a check below fails (fix with a test first, then commit as `fix: ...` with the trailer).

- [ ] **Step 1: Full automated gate**

Run: `make analyze && make test`
Expected: `No issues found!` and `All tests passed!`.

- [ ] **Step 2: Confirm nothing under `../satur` changed because of this work**

`../satur` already has unrelated uncommitted edits (`application/config/packages/security.yaml`, `config/nginx.conf`, `application/src/Product/`). Compare against that baseline, don't expect a clean tree:

```bash
git -C ../satur status --short
```

Expected: exactly those three entries, and no others. Also `git diff --stat main...HEAD -- ':!lib' ':!test' ':!docs'` in this repo shows no unexpected files.

- [ ] **Step 3: Live API smoke (curl, local Sylius on `:5051`)**

```bash
B=http://localhost:5051/api/v2/shop; H='Accept: application/ld+json'
TOK=$(curl -s -X POST -H 'Content-Type: application/json' -H "$H" -d '{}' $B/orders | python3 -c "import sys,json; print(json.load(sys.stdin)['tokenValue'])")
curl -s -o /dev/null -w "add(IRI)   %{http_code}\n" -X PATCH -H 'Content-Type: application/merge-patch+json' -H "$H" -d '{"productVariant":"/api/v2/shop/product-variants/58288-variant-0","quantity":1}' $B/orders/$TOK/items
ID=$(curl -s -H "$H" $B/orders/$TOK | python3 -c "import sys,json; print(json.load(sys.stdin)['items'][0]['id'])")
curl -s -o /dev/null -w "qty=3      %{http_code}\n" -X PATCH -H 'Content-Type: application/merge-patch+json' -H "$H" -d '{"quantity":3}' $B/orders/$TOK/items/$ID
curl -s -o /dev/null -w "delete     %{http_code}\n" -X DELETE -H "$H" $B/orders/$TOK/items/$ID
curl -s -o /dev/null -w "bad token  %{http_code}\n" -H "$H" $B/orders/does-not-exist
```

Expected: `200`, `200`, `204`, `404`.

- [ ] **Step 4: Manual app run (`make run-chrome`, API on `:5051`)** — walk the spec's acceptance list

1. Open a discounted product → original price struck through and red `-N%` pill; a non-discounted product shows the price only.
2. Specyfikacja renders as a 2-column grid; a product without attributes hides the section.
3. Tap „Dodaj do koszyka” (guest) → spinner, then SnackBar „Dodano do koszyka”; tap action „Koszyk” → `/cart` shows the line with name, variant name, thumbnail (or placeholder), unit price.
4. Change qty with `+` / `−` (`−` disabled at 1); row dims while the request runs; „Razem” = „Wartość produktów” + „Dostawa” and matches the API.
5. Remove the line → empty view „Twój koszyk jest pusty”; „Przeglądaj ofertę” → `/products`.
6. Koszyk bottom-nav tab opens `/cart` from the product list, PDP and account screen.
7. Add an item, **fully restart the app** → open Koszyk: the item is still there (token persisted in secure storage).
8. Log in (token kept), add an item, then „Wyloguj się” → open Koszyk: empty (token cleared, cubit reset).
9. Stop the API (or break the base URL) → Koszyk shows „Nie udało się wczytać koszyka” + „Spróbuj ponownie”; PDP ATC shows „Nie udało się dodać do koszyka”.

- [ ] **Step 5: Commit only if fixes were needed**

If steps 1–4 required code changes, commit them with a `fix:` message ending in the trailer:

```bash
git add <changed files>
git commit -m "$(cat <<'EOF'
fix: <what was wrong>.

authored-by: <daniel.slizewski@gmail.com>
EOF
)"
```

Otherwise no commit: the branch is ready for review.

---

## Self-Review (spec coverage)

| Spec requirement | Task |
|------------------|------|
| PDP strikethrough + `-N%` pill; price only when no discount | 1 |
| Specs 2-col grid, hidden when empty | 1 |
| `defaultVariantCode` from IRI; null when none | 2 |
| `ApiClient.patch` (merge-patch + auth) / `delete` (204) + failure mapping | 3 |
| Cart models, `CartFailure`, `CartRepository`, `CartTokenStore`, memory store | 4 |
| Create-then-add; reuse token; 404 → recreate + retry once; qty update; delete → re-fetch; JSON → `Cart`; thumbnail best-effort + cache; live PATCH IRI-vs-code curl | 5 |
| `SecureCartTokenStore` (`cart.token`); `CartCubit` refresh/add/update/remove/busy/reset | 6 |
| App-level `CartCubit` in DI + root provider; logout-only reset (not hydrate/login) | 7 |
| ATC → `CartCubit.addItem`, spinner, disabled w/o variant, success/failure SnackBar, „Koszyk” action → `/cart` | 8 |
| Line tile, stepper (− disabled at 1), remove, dimmed busy row; summary w/ conditional „Dostawa”; empty view | 9 |
| Cart screen (refresh on open, loading/error/empty/loaded), route `/cart`, Koszyk nav | 10 |
| `make analyze` / `make test` green; no `../satur` changes; acceptance walkthrough | 11 |
| Out of scope (checkout, coupons, badge, wishlist, merge, JWT refresh) | not implemented, by design |
