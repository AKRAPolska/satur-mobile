import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable pinned [SliverAppBar] with back + centered title (PDP, etc.).
class CatalogPinnedAppBar extends StatelessWidget {
  const CatalogPinnedAppBar({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? () => context.pop(),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
    );
  }
}
