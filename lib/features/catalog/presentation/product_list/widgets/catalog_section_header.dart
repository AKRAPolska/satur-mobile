import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/core/theme/satur_colors.dart';

class CatalogSectionHeader extends StatelessWidget {
  const CatalogSectionHeader({
    super.key,
    this.title = 'Oferta',
    this.backLabel = 'Wróć',
    this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack ?? () => context.go('/welcome'),
            icon: const Icon(Icons.arrow_back, size: 20),
            label: Text(backLabel),
            style: TextButton.styleFrom(foregroundColor: SaturColors.onSurface),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}
