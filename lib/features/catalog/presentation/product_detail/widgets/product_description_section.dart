import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';

class ProductDescriptionSection extends StatelessWidget {
  const ProductDescriptionSection({super.key, this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    if (description == null || description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description!,
          style: const TextStyle(
            color: SaturColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
