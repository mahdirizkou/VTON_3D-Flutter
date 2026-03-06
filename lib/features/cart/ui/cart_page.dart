import 'package:flutter/material.dart';

import '../../glasses/ui/home_page.dart';
import '../../orders/models/order_item.dart';
import '../../orders/ui/checkout_page.dart';
import '../data/cart_controller.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    CartController.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CartController.instance,
      builder: (context, _) {
        final List<OrderItem> items = CartController.instance.items;
        final double subtotal = CartController.instance.subtotal;
        const double shipping = 0.0;
        const double tax = 0.0;
        final double total = subtotal + shipping + tax;

        return Scaffold(
          appBar: AppBar(title: const Text('Cart')),
          body: items.isEmpty
              ? _EmptyCart(
                  onBackHome: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...items.map((item) => _CartItemTile(item: item)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _SummaryRow(label: 'Subtotal', value: subtotal),
                            _SummaryRow(label: 'Shipping', value: shipping),
                            _SummaryRow(label: 'Tax', value: tax),
                            const Divider(),
                            _SummaryRow(label: 'Total', value: total, bold: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: items.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(
                              items: List<OrderItem>.from(items),
                              subtotal: subtotal,
                              shipping: shipping,
                              tax: tax,
                              total: total,
                            ),
                          ),
                        );
                      },
                      child: const Text('Checkout'),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBackHome});

  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 54),
            const SizedBox(height: 12),
            Text('Your cart is empty', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBackHome,
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('\$${item.unitPrice.toStringAsFixed(2)} each'),
                  const SizedBox(height: 4),
                  Text('Line total: \$${item.lineTotal.toStringAsFixed(2)}'),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => CartController.instance.decrement(item.glassesId),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${item.quantity}'),
                IconButton(
                  onPressed: () => CartController.instance.increment(item.glassesId),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  onPressed: () => CartController.instance.remove(item.glassesId),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
