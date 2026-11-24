import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/features/cart/domain/cart.dart';
import 'package:satur_app/features/catalog/domain/money.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({super.key, required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaturColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaturColors.borderLight),
      ),
      child: Column(
        children: [
          _Row(label: 'Wartość produktów', value: formatPln(cart.itemsTotal)),
          if (cart.shippingTotal > 0) ...[
            const SizedBox(height: 8),
            _Row(label: 'Dostawa', value: formatPln(cart.shippingTotal)),
          ],
          const Divider(height: 24, color: SaturColors.surfaceVariant),
          _Row(label: 'Razem', value: formatPln(cart.total), emphasized: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 18 : 14,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
      color: emphasized ? SaturColors.primary : SaturColors.onSurface,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}
