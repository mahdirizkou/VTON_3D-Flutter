import 'package:flutter/material.dart';

import '../models/glasses_item.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    required this.allItems,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onTryTap,
  });

  final List<GlassesItem> allItems;
  final Set<int> favoriteIds;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<GlassesItem> onTryTap;

  @override
  Widget build(BuildContext context) {
    final List<GlassesItem> favorites = allItems.where((item) => favoriteIds.contains(item.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(
              child: Text('No favorites yet. Save frames you like.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final GlassesItem item = favorites[index];
                return Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.thumbnailUrl ?? 'https://picsum.photos/seed/fav_${item.id}/300/300',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined, size: 18),
                        ),
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text('${item.brand ?? 'Unknown brand'} • \$${item.price.toStringAsFixed(2)}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline),
                          onPressed: () => onTryTap(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite),
                          onPressed: () => onToggleFavorite(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
