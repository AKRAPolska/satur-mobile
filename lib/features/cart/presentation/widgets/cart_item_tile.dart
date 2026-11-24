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
