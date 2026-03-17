import 'package:flutter/material.dart';

import '../../models/glasses_item.dart';
import 'glasses_model_viewer.dart';

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    super.key,
    required this.item,
    required this.width,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTryTap,
    required this.onBuyTap,
    required this.onTap,
  });

  final GlassesItem item;
  final double width;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTryTap;
  final VoidCallback onBuyTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GlassesModelViewer(
                          glbUrl: item.glbUrl,
                          thumbnailUrl: item.thumbnailUrl ?? 'https://picsum.photos/seed/fallback_${item.id}/900/600',
                          alt: '${item.name} 3D preview',
                          compact: true,
                          allowZoom: false,
                          autoRotate: false,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                item.glbUrl?.trim().isNotEmpty == true
                                    ? Icons.view_in_ar_outlined
                                    : Icons.image_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.glbUrl?.trim().isNotEmpty == true ? '3D Preview' : 'Image',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filledTonal(
                          onPressed: onFavoriteTap,
                          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(item.brand ?? 'Unknown brand', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${item.price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text((item.rating ?? 0).toStringAsFixed(1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: onTryTap,
                              child: const Text('Try'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onBuyTap,
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text('Buy'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
