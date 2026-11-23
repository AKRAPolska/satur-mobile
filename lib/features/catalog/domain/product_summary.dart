import 'package:equatable/equatable.dart';

final class ProductSummary extends Equatable {
  const ProductSummary({
    required this.code,
    required this.name,
    this.imageUrl,
    this.averageRating,
    this.priceGross,
    this.originalPriceGross,
  });

  final String code;
  final String name;
  final String? imageUrl;
  final double? averageRating;
  final int? priceGross;
  final int? originalPriceGross;

  bool get hasDiscount =>
      priceGross != null &&
      originalPriceGross != null &&
      originalPriceGross! > priceGross!;

  int? get discountPercent {
    if (!hasDiscount) return null;
    final original = originalPriceGross!;
    final price = priceGross!;
    return (((original - price) / original) * 100).round();
  }

  @override
  List<Object?> get props => [
        code,
        name,
        imageUrl,
        averageRating,
        priceGross,
        originalPriceGross,
      ];
}
