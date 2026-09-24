import 'package:flutter/material.dart';

class SaturLogo extends StatelessWidget {
  const SaturLogo({super.key, this.width = 220});

  final double width;

  static const assetPath = 'assets/brand/satur_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'Satur',
    );
  }
}
