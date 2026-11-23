sealed class CatalogFailure {
  const CatalogFailure();
}

final class CatalogNetworkFailure extends CatalogFailure {
  const CatalogNetworkFailure([this.message]);
  final String? message;
}

final class CatalogHttpFailure extends CatalogFailure {
  const CatalogHttpFailure({required this.statusCode, this.message});
  final int statusCode;
  final String? message;
}

final class CatalogNotFoundFailure extends CatalogFailure {
  const CatalogNotFoundFailure();
}

final class CatalogUnknownFailure extends CatalogFailure {
  const CatalogUnknownFailure([this.message]);
  final String? message;
}
