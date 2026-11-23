import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/catalog/domain/money.dart';
import 'package:satur_app/features/catalog/domain/product_detail.dart';

/// Name, rating, price block on PDP.
class ProductDetailInfo extends StatelessWidget {
  const ProductDetailInfo({super.key, required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: SaturColors.onSurface,
          ),
        ),
        if (product.averageRating != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Color(0xFFFFB400)),
              const SizedBox(width: 4),
              Text(
                product.averageRating!.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
        if (product.priceGross != null) ...[
          const SizedBox(height: 8),
          Text(
            formatPln(product.priceGross!),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: SaturColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}
