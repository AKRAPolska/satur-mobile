import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_colors.dart';

class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              if (images.isEmpty) {
                return const ColoredBox(
                  color: SaturColors.surfaceVariant,
                  child: Center(
                    child: Icon(Icons.image_outlined, size: 48),
                  ),
                );
              }
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: SaturColors.surfaceVariant,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.white.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: () {}, // wishlist no-op
                icon: const Icon(Icons.favorite_border),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? SaturColors.primary
                          : SaturColors.surfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
