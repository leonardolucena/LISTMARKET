class ProductInfo {
  const ProductInfo({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
  });

  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;

  String get displayName {
    final brandText = brand?.trim();
    if (brandText != null && brandText.isNotEmpty) {
      return '$name ($brandText)';
    }
    return name;
  }
}

sealed class ProductLookupResult {
  const ProductLookupResult();
}

class ProductLookupSuccess extends ProductLookupResult {
  const ProductLookupSuccess(this.product);

  final ProductInfo product;
}

class ProductLookupNotFound extends ProductLookupResult {
  const ProductLookupNotFound(this.barcode);

  final String barcode;
}

class ProductLookupConnectionError extends ProductLookupResult {
  const ProductLookupConnectionError(this.barcode);

  final String barcode;
}
