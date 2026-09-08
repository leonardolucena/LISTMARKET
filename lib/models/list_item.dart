class ListItem {
  ListItem({
    required this.id,
    required this.name,
    this.price,
    this.quantity = 1,
    this.isPurchased = false,
  });

  final String id;
  final String name;
  final double? price;
  final int quantity;
  final bool isPurchased;

  ListItem copyWith({
    String? id,
    String? name,
    double? price,
    bool clearPrice = false,
    int? quantity,
    bool? isPurchased,
  }) {
    return ListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: clearPrice ? null : (price ?? this.price),
      quantity: quantity ?? this.quantity,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'isPurchased': isPurchased,
    };
  }

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      isPurchased: json['isPurchased'] as bool? ?? false,
    );
  }
}
