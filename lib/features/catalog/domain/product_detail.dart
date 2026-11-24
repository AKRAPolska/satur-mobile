import 'package:equatable/equatable.dart';

final class ProductDetail extends Equatable {
  const ProductDetail({
    required this.code,
    required this.name,
    this.description,
    this.imageUrls = const [],
    this.averageRating,
    this.priceGross,
    this.originalPriceGross,
    this.specs = const {},
  });

  final String code;
  final String name;
  final String? description;
  final List<String> imageUrls;
  final double? averageRating;
  final int? priceGross;
  final int? originalPriceGross;
  final Map<String, String> specs;

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
        description,
        imageUrls,
        averageRating,
        priceGross,
        originalPriceGross,
        specs,
      ];
}
