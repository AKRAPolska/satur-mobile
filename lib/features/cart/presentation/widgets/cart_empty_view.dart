import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';
import 'package:satur_app/core/widgets/satur_button.dart';

class CartEmptyView extends StatelessWidget {
  const CartEmptyView({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: SaturColors.outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'Twój koszyk jest pusty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              child: SaturButton(label: 'Przeglądaj ofertę', onPressed: onBrowse),
            ),
          ],
        ),
      ),
    );
  }
}
