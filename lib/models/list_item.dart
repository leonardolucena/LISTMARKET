class ListItem {
  ListItem({
    required this.id,
    required this.name,
    this.brand,
    this.price,
    this.quantity = 1,
    this.isPurchased = false,
    this.barcode,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? brand;
  final double? price;
  final int quantity;
  final bool isPurchased;
  final String? barcode;
  final String? imageUrl;

  static final RegExp _legacyBrandPattern = RegExp(r'^(.+?)\s+\(([^)]+)\)$');

  String get displayName {
    final brandText = brand?.trim();
    if (brandText != null && brandText.isNotEmpty) {
      return '$name ($brandText)';
    }
    return name;
  }

  String get titleText {
    final rawTitle = _rawTitleText;
    return _truncateToWords(rawTitle);
  }

  String get _rawTitleText {
    if (brand != null && brand!.trim().isNotEmpty) return name;
    final match = _legacyBrandPattern.firstMatch(name);
    return match?.group(1)?.trim() ?? name;
  }

  static String _truncateToWords(String text, {int maxWords = 3}) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final wordList = words.toList();
    if (wordList.length <= maxWords) {
      return wordList.join(' ');
    }
    return '${wordList.take(maxWords).join(' ')}...';
  }

  String? get brandText {
    if (brand != null && brand!.trim().isNotEmpty) return brand!.trim();
    final match = _legacyBrandPattern.firstMatch(name);
    return match?.group(2)?.trim();
  }

  ListItem copyWith({
    String? id,
    String? name,
    String? brand,
    bool clearBrand = false,
    double? price,
    bool clearPrice = false,
    int? quantity,
    bool? isPurchased,
    String? barcode,
    bool clearBarcode = false,
    String? imageUrl,
    bool clearImageUrl = false,
  }) {
    return ListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: clearBrand ? null : (brand ?? this.brand),
      price: clearPrice ? null : (price ?? this.price),
      quantity: quantity ?? this.quantity,
      isPurchased: isPurchased ?? this.isPurchased,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'quantity': quantity,
      'isPurchased': isPurchased,
      'barcode': barcode,
      'imageUrl': imageUrl,
    };
  }

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      isPurchased: json['isPurchased'] as bool? ?? false,
      barcode: json['barcode'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
