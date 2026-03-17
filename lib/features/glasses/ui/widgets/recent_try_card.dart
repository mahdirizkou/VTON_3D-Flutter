import 'package:flutter/material.dart';

import '../../models/glasses_item.dart';

class RecentTryCard extends StatelessWidget {
  const RecentTryCard({
    super.key,
    required this.item,
    required this.onTryAgain,
    this.onTap,
  });

  final GlassesItem item;
  final VoidCallback onTryAgain;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 170,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Image.network(
                          item.thumbnailUrl ?? 'https://picsum.photos/seed/recent_${item.id}/900/600',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                        if (item.glbUrl?.trim().isNotEmpty == true)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.view_in_ar_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '3D',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (item.glbUrl?.trim().isNotEmpty == true)
                  Text(
                    'Full 3D preview in details',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onTryAgain,
                    child: const Text('Try again'),
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
