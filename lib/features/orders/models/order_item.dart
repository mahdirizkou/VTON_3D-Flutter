import '../../glasses/models/glasses_item.dart';

class OrderItem {
  const OrderItem({
    required this.glassesId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItem.fromGlassesItem(GlassesItem item, {int quantity = 1}) {
    return OrderItem(
      glassesId: item.id,
      name: item.name,
      unitPrice: _toDouble(item.price),
      quantity: quantity,
    );
  }

  factory OrderItem.fromGlasses(GlassesItem item, {int quantity = 1}) {
    return OrderItem.fromGlassesItem(item, quantity: quantity);
  }

  factory OrderItem.fromCartJson(Map<String, dynamic> json) {
    return OrderItem(
      glassesId: _toInt(json['glasses_id']) ?? _toInt(json['glassesId']) ?? 0,
      name: json['name']?.toString() ?? 'Unnamed',
      unitPrice: _toDouble(json['unit_price'] ?? json['unitPrice']),
      quantity: _toInt(json['quantity']) ?? 1,
    );
  }

  final int glassesId;
  final String name;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  OrderItem copyWith({
    int? glassesId,
    String? name,
    double? unitPrice,
    int? quantity,
  }) {
    return OrderItem(
      glassesId: glassesId ?? this.glassesId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toOrderJson() => {
        'glasses_id': glassesId,
        'quantity': quantity,
      };

  Map<String, dynamic> toCartJson() => {
        'glasses_id': glassesId,
        'name': name,
        'unit_price': unitPrice,
        'quantity': quantity,
      };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0.0;
    }
    return 0.0;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
