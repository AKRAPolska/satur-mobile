import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';

class CatalogFilterBar extends StatelessWidget {
  const CatalogFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: SaturColors.borderLight)),
      ),
      child: const Row(
        children: [
          Expanded(child: _FilterChip(icon: Icons.tune, label: 'Filtry')),
          SizedBox(width: 12),
          Expanded(child: _FilterChip(icon: Icons.swap_vert, label: 'Sortuj')),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SaturColors.surfaceVariant.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {}, // no-op
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: SaturColors.onSurface),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
