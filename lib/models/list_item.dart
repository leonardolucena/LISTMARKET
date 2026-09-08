class ListItem {
  ListItem({
    required this.id,
    required this.name,
    this.price,
    this.quantity = 1,
    this.isPurchased = false,
    this.barcode,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double? price;
  final int quantity;
  final bool isPurchased;
  final String? barcode;
  final String? imageUrl;

  ListItem copyWith({
    String? id,
    String? name,
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
      price: (json['price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      isPurchased: json['isPurchased'] as bool? ?? false,
      barcode: json['barcode'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
