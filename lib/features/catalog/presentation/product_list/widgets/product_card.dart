import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/catalog/domain/money.dart';
import 'package:satur_app/features/catalog/domain/product_summary.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final ProductSummary product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: SaturColors.surfaceVariant.withValues(alpha: 0.35),
                    child: product.imageUrl == null
                        ? const Icon(Icons.image_outlined, color: SaturColors.outline)
                        : Image.network(
                            product.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              color: SaturColors.outline,
                            ),
                          ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SaturColors.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {}, // wishlist no-op
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.favorite_border, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        color: SaturColors.onSurface,
                      ),
                    ),
                    if (product.averageRating != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFF873C00)),
                          const SizedBox(width: 4),
                          Text(
                            product.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: SaturColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.hasDiscount &&
                                  product.originalPriceGross != null)
                                Text(
                                  formatPln(product.originalPriceGross!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SaturColors.outline,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              if (product.priceGross != null)
                                Text(
                                  formatPln(product.priceGross!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: SaturColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Material(
                          color: SaturColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {}, // bag no-op
                            child: const SizedBox(
                              width: 36,
                              height: 36,
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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
