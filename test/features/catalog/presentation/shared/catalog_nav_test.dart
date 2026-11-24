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
