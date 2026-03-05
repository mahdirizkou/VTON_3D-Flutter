class CartItem {
  const CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.thumbnailUrl,
  });

  final int itemId;
  final String name;
  final double price;
  final int quantity;
  final String? thumbnailUrl;

  double get lineTotal => price * quantity;

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      itemId: itemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      thumbnailUrl: json['thumbnailUrl']?.toString(),
    );
  }
}
