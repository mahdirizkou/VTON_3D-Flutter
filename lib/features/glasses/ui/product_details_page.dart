import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../../auth/ui/login_page.dart';
import '../../cart/data/cart_controller.dart';
import '../data/glasses_api.dart';
import '../models/glasses_item.dart';
import 'try_on_page.dart';
import 'widgets/glasses_model_viewer.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    super.key,
    this.item,
    this.glassesId,
    this.isFavorite = false,
    this.onFavoriteToggle,
  }) : assert(item != null || glassesId != null, 'Either item or glassesId must be provided.');

  final GlassesItem? item;
  final int? glassesId;
  final bool isFavorite;
  final ValueChanged<int>? onFavoriteToggle;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final GlassesApi _glassesApi = const GlassesApi();

  GlassesItem? _item;
  late bool _isFavorite;
  bool _isLoading = true;
  bool _isTryOnLoading = false;
  String? _error;

  int get _resolvedId => widget.glassesId ?? widget.item?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _isFavorite = widget.isFavorite;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    if (_resolvedId <= 0) {
      setState(() {
        _isLoading = false;
        _error = 'This product is missing a valid identifier.';
      });
      return;
    }

    if (_item == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final GlassesItem detail = await _glassesApi.fetchGlassesDetail(_resolvedId);
      if (!mounted) return;
      setState(() {
        _item = _item?.mergeWith(detail) ?? detail;
      });
    } on ApiUnauthorizedException catch (e) {
      if (!mounted) return;
      await _redirectToLogin(message: e.toString());
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load full product details right now.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    final GlassesItem? item = _item;
    if (item == null) return;

    await CartController.instance.addFromGlasses(item, quantity: 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart')),
    );
  }

  Future<void> _openTryOn() async {
    final GlassesItem? item = _item;
    if (item == null) return;

    setState(() {
      _isTryOnLoading = true;
    });

    try {
      final GlassesItem enriched = await _glassesApi.fetchTryOnPayload(item);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TryOnPage(item: enriched)),
      );
    } on ApiUnauthorizedException catch (e) {
      if (!mounted) return;
      await _redirectToLogin(message: e.toString());
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load try-on payload. Opening available product data.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TryOnPage(item: item)),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isTryOnLoading = false;
      });
    }
  }

  Future<void> _copyGlbUrl(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GLB URL copied')),
    );
  }

  Future<void> _redirectToLogin({String? message}) async {
    await TokenStore.instance.clearTokens();
    if (!mounted) return;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final GlassesItem? item = _item;

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.name ?? 'Product Details'),
        actions: [
          if (widget.onFavoriteToggle != null && item != null)
            IconButton(
              tooltip: _isFavorite ? 'Remove favorite' : 'Add favorite',
              onPressed: () {
                widget.onFavoriteToggle!(item.id);
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            ),
        ],
      ),
      body: item == null
          ? _buildEmptyState(context)
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadDetails,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: colorScheme.onErrorContainer),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      _buildHeaderImage(context, item),
                      const SizedBox(height: 16),
                      _buildSummarySection(context, item),
                      const SizedBox(height: 16),
                      _buildActionRow(context, item),
                      const SizedBox(height: 16),
                      _buildModelSection(context, item),
                      const SizedBox(height: 16),
                      _buildAttributesSection(context, item),
                      const SizedBox(height: 16),
                      _buildOffsetsSection(context, item),
                      const SizedBox(height: 16),
                      _buildDatesSection(context, item),
                    ],
                  ),
                ),
                if (_isLoading && item != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Chip(
                      avatar: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: const Text('Refreshing'),
                      backgroundColor: colorScheme.surface,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Product details are unavailable.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context, GlassesItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GlassesModelViewer(
              glbUrl: item.glbUrl,
              thumbnailUrl: item.thumbnailUrl ?? 'https://picsum.photos/seed/details_${item.id}/1200/900',
              alt: '${item.name} 3D model preview',
              compact: false,
              allowZoom: true,
              autoRotate: false,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withOpacity(0.06),
                    Colors.black.withOpacity(0.38),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  if (item.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.tags.take(3).map((String tag) {
                          return Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.white.withOpacity(0.88),
                          );
                        }).toList(),
                      ),
                    ),
                  if (item.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(item.rating!.toStringAsFixed(1)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, GlassesItem item) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            item.brand ?? 'Unknown brand',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (item.version != null && item.version!.trim().isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.layers_outlined, size: 18),
                  label: Text('Version ${item.version}'),
                ),
              if (item.anchor != null && item.anchor!.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.my_location_outlined, size: 18),
                  label: Text(item.anchor!),
                ),
              ],
            ],
          ),
          if (item.tags.length > 3) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.tags.skip(3).map((String tag) => Chip(label: Text(tag))).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, GlassesItem item) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _isTryOnLoading ? null : _openTryOn,
            icon: _isTryOnLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_outlined),
            label: const Text('Try On'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _addToCart,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Add to Cart'),
          ),
        ),
      ],
    );
  }

  Widget _buildModelSection(BuildContext context, GlassesItem item) {
    final ThemeData theme = Theme.of(context);
    final String? resolvedGlbUrl = item.glbUrl?.trim().isNotEmpty == true ? item.glbUrl!.trim() : null;
    final String glbUrl = resolvedGlbUrl ?? 'No GLB URL provided';

    return _DetailSection(
      title: '3D Model',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inspect the glasses model directly from the backend GLB source. Drag to rotate and pinch to zoom when the viewer is available.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SelectableText(
              glbUrl,
              style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: resolvedGlbUrl == null ? null : () => _copyGlbUrl(resolvedGlbUrl),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy GLB URL'),
              ),
              TextButton.icon(
                onPressed: resolvedGlbUrl == null
                    ? null
                    : () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text('GLB Info'),
                              content: SelectableText(resolvedGlbUrl),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                icon: const Icon(Icons.info_outline),
                label: const Text('View GLB Info'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection(BuildContext context, GlassesItem item) {
    return _DetailSection(
      title: 'Product Details',
      child: Column(
        children: [
          _InfoRow(label: 'Brand', value: item.brand ?? '-'),
          _InfoRow(label: 'Price', value: '\$${item.price.toStringAsFixed(2)}'),
          _InfoRow(label: 'Rating', value: item.rating?.toStringAsFixed(1) ?? '-'),
          _InfoRow(label: 'Anchor', value: item.anchor ?? '-'),
          _InfoRow(label: 'Version', value: item.version ?? '-'),
          _InfoRow(label: 'Scale', value: item.scale?.toStringAsFixed(3) ?? '-'),
        ],
      ),
    );
  }

  Widget _buildOffsetsSection(BuildContext context, GlassesItem item) {
    return _DetailSection(
      title: 'Offsets',
      child: Column(
        children: [
          _InfoRow(label: 'position_offset_x', value: _formatDouble(item.positionOffsetX)),
          _InfoRow(label: 'position_offset_y', value: _formatDouble(item.positionOffsetY)),
          _InfoRow(label: 'position_offset_z', value: _formatDouble(item.positionOffsetZ)),
          _InfoRow(label: 'rotation_offset_x', value: _formatDouble(item.rotationOffsetX)),
          _InfoRow(label: 'rotation_offset_y', value: _formatDouble(item.rotationOffsetY)),
          _InfoRow(label: 'rotation_offset_z', value: _formatDouble(item.rotationOffsetZ)),
        ],
      ),
    );
  }

  Widget _buildDatesSection(BuildContext context, GlassesItem item) {
    return _DetailSection(
      title: 'Timeline',
      child: Column(
        children: [
          _InfoRow(label: 'Created', value: _formatDate(item.createdAt)),
          _InfoRow(label: 'Updated', value: _formatDate(item.updatedAt)),
        ],
      ),
    );
  }

  String _formatDouble(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(3);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final DateTime local = value.toLocal();
    final String month = _monthLabel(local.month);
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$month $day, ${local.year} at $hour:$minute';
  }

  String _monthLabel(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '-';
    return months[month - 1];
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
