import 'package:flutter/material.dart';

import '../../cart/data/cart_controller.dart';
import '../models/glasses_item.dart';

class TryOnPage extends StatelessWidget {
  const TryOnPage({super.key, required this.item});

  final GlassesItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try-On')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                item.thumbnailUrl ?? 'https://picsum.photos/seed/tryon_${item.id}/900/600',
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 260,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(item.brand ?? 'Unknown brand', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Price: \$${item.price.toStringAsFixed(2)}'),
            Text('Rating: ${(item.rating ?? 0).toStringAsFixed(1)}'),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Try-On Payload', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('glb_url: ${item.glbUrl ?? '-'}'),
                        Text('scale: ${item.scale?.toStringAsFixed(3) ?? '-'}'),
                        Text(
                          'position_offset: ${item.positionOffset != null ? item.positionOffset!.toInlineString() : '-'}',
                        ),
                        Text(
                          'rotation_offset: ${item.rotationOffset != null ? item.rotationOffset!.toInlineString() : '-'}',
                        ),
                        Text('anchor: ${item.anchor ?? '-'}'),
                        Text('version: ${item.version ?? '-'}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera placeholder activated.')),
                );
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Open Camera'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await CartController.instance.addFromGlasses(item);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart')),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
