import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/core/widgets/satur_logo.dart';

class CatalogTopBar extends StatelessWidget {
  const CatalogTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 0.5,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SaturLogo(width: 120),
                  Positioned(
                    right: 8,
                    child: IconButton(
                      onPressed: () {}, // notifications no-op
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: SaturColors.surfaceGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 20, color: SaturColors.outline),
                    SizedBox(width: 12),
                    Text(
                      'Wyszukaj produkt',
                      style: TextStyle(color: SaturColors.outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
