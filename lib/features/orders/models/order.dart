class Order {
  const Order({
    required this.orderId,
    required this.status,
    required this.total,
  });

  final int orderId;
  final String status;
  final double total;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}
