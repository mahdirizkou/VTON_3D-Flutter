import 'package:flutter/material.dart';

import '../../orders/ui/checkout_page.dart';
import '../data/cart_controller.dart';
import '../models/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const double _shipping = 4.99;
  static const double _taxRate = 0.08;

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
        final items = CartController.instance.items;
        final subtotal = CartController.instance.subtotal;
        final tax = subtotal * _taxRate;
        final shipping = items.isEmpty ? 0.0 : _shipping;
        final total = subtotal + tax + shipping;

        return Scaffold(
          appBar: AppBar(title: const Text('Cart')),
          body: items.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...items.map((item) => _CartItemTile(item: item)),
                    const SizedBox(height: 14),
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
                              items: items,
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

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.thumbnailUrl ?? 'https://picsum.photos/seed/cart_${item.itemId}/300/300',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('\$${item.price.toStringAsFixed(2)}'),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => CartController.instance.decrement(item.itemId),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${item.quantity}'),
                IconButton(
                  onPressed: () => CartController.instance.increment(item.itemId),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  onPressed: () => CartController.instance.removeItem(item.itemId),
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
    final style = bold
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
