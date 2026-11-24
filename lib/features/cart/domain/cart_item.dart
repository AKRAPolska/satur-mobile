import 'package:equatable/equatable.dart';

final class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.variantCode,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.imageUrl,
  });

  /// Sylius order-item id (int in JSON, kept as String for path building).
  final String id;
  final String variantCode;
  final String productName;
  final String? variantName;
  final int quantity;

  /// Grosze.
  final int unitPrice;
  final int total;
  final String? imageUrl;

  @override
  List<Object?> get props => [
        id,
        variantCode,
        productName,
        variantName,
        quantity,
        unitPrice,
        total,
        imageUrl,
      ];
}
