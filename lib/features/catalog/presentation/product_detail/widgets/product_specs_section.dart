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
          ..._rows(),
        ],
      ),
    );
  }

  List<Widget> _rows() {
    final entries = specs.entries.toList();
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      final left = entries[i];
      final right = i + 1 < entries.length ? entries[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SpecCell(entry: left)),
              const SizedBox(width: 16),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _SpecCell(entry: right),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({required this.entry});

  final MapEntry<String, String> entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.key,
          style: const TextStyle(
            fontSize: 12,
            color: SaturColors.onSurfaceVariant,
          ),
        ),
        Text(entry.value),
      ],
    );
  }
}
