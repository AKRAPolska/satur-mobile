import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/core/widgets/satur_button.dart';
import 'package:satur_app/features/catalog/presentation/shared/catalog_bottom_nav.dart';

class ProductDetailFooter extends StatelessWidget {
  const ProductDetailFooter({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: SaturButton(
                label: 'Dodaj do koszyka',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wkrótce')),
                  );
                },
              ),
            ),
            CatalogBottomNav(
              active: CatalogTab.oferta,
              onTap: (tab) {
                if (tab == CatalogTab.start) {
                  context.go('/welcome');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
