import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';

class ProductSpecsSection extends StatelessWidget {
  const ProductSpecsSection({super.key, required this.specs});

  final Map<String, String> specs;

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaturColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specyfikacja',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...specs.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SaturColors.onSurfaceVariant,
                    ),
                  ),
                  Text(e.value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
