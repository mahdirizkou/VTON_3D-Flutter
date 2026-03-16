import 'dart:typed_data';

import 'package:flutter/material.dart';

class TripoUploadSlotCard extends StatelessWidget {
  const TripoUploadSlotCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isRequired,
    required this.imageBytes,
    required this.fileName,
    required this.onPick,
    required this.onRemove,
  });

  final String title;
  final IconData icon;
  final bool isRequired;
  final Uint8List? imageBytes;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool hasImage = imageBytes != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRequired ? '$title *' : title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasImage && onRemove != null)
                  IconButton(
                    tooltip: 'Remove $title image',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                height: 150,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(icon, size: 36, color: colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasImage ? (fileName ?? 'Selected image') : 'No image selected',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: Icon(hasImage ? Icons.refresh : Icons.add_photo_alternate_outlined),
                label: Text(hasImage ? 'Replace' : 'Choose Image'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
