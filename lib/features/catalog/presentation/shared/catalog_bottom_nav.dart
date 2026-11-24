import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';

enum CatalogTab { start, oferta, ulubione, koszyk, konto }

/// 5-tab bottom nav per Stitch (incl. Konto). Unwired tabs are no-op.
class CatalogBottomNav extends StatelessWidget {
  const CatalogBottomNav({
    super.key,
    required this.active,
    this.onTap,
  });

  final CatalogTab active;
  final ValueChanged<CatalogTab>? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SaturColors.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: SaturColors.borderLight)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Start hidden for now — wired to /welcome and felt like logout.
              _item(CatalogTab.oferta, Icons.storefront_outlined, 'Oferta'),
              _item(CatalogTab.ulubione, Icons.favorite_border, 'Ulubione'),
              _item(CatalogTab.koszyk, Icons.shopping_bag_outlined, 'Koszyk'),
              _item(CatalogTab.konto, Icons.person_outline, 'Konto'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(CatalogTab tab, IconData icon, String label) {
    final selected = tab == active;
    final color = selected ? SaturColors.primary : SaturColors.onSurfaceVariant;
    return InkWell(
      onTap: () => onTap?.call(tab),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
