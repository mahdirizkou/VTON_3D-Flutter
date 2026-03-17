import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:model_viewer_plus/model_viewer_plus.dart';

class GlassesModelViewer extends StatefulWidget {
  const GlassesModelViewer({
    super.key,
    required this.glbUrl,
    this.thumbnailUrl,
    this.alt = '3D glasses model',
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.backgroundColor,
    this.compact = false,
    this.allowZoom = true,
    this.autoRotate = false,
  });

  final String? glbUrl;
  final String? thumbnailUrl;
  final String alt;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final bool compact;
  final bool allowZoom;
  final bool autoRotate;

  @override
  State<GlassesModelViewer> createState() => _GlassesModelViewerState();
}

class _GlassesModelViewerState extends State<GlassesModelViewer> {
  bool _isCheckingModel = true;
  bool _canRenderModel = false;
  String? _lastResolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolveModelAvailability();
  }

  @override
  void didUpdateWidget(covariant GlassesModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.glbUrl != widget.glbUrl || oldWidget.thumbnailUrl != widget.thumbnailUrl) {
      _resolveModelAvailability();
    }
  }

  Future<void> _resolveModelAvailability() async {
    final String? glbUrl = widget.glbUrl?.trim();
    if (glbUrl == null || glbUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isCheckingModel = false;
        _canRenderModel = false;
        _lastResolvedUrl = null;
      });
      return;
    }

    setState(() {
      _isCheckingModel = true;
      _canRenderModel = false;
      _lastResolvedUrl = glbUrl;
    });

    final bool available = await _probeGlbUrl(glbUrl);
    if (!mounted || _lastResolvedUrl != glbUrl) return;

    setState(() {
      _isCheckingModel = false;
      _canRenderModel = available;
    });
  }

  Future<bool> _probeGlbUrl(String glbUrl) async {
    final Uri uri;
    try {
      uri = Uri.parse(glbUrl);
    } catch (_) {
      return false;
    }

    final http.Client client = http.Client();
    try {
      final http.Response response = await client.head(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return true;
      }
      if (response.statusCode != 403 && response.statusCode != 405) {
        return false;
      }

      final http.Request request = http.Request('GET', uri);
      request.headers['Range'] = 'bytes=0-0';
      final http.StreamedResponse streamed = await client.send(request).timeout(
        const Duration(seconds: 8),
      );
      return streamed.statusCode >= 200 && streamed.statusCode < 400;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor = widget.backgroundColor ?? colorScheme.surfaceContainerHighest;

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: ColoredBox(
        color: backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (_canRenderModel && !_isCheckingModel)
              ModelViewer(
                key: ValueKey<String?>(widget.glbUrl),
                src: widget.glbUrl!,
                alt: widget.alt,
                ar: false,
                autoRotate: widget.autoRotate,
                cameraControls: true,
                disableZoom: !widget.allowZoom,
                backgroundColor: backgroundColor,
                loading: Loading.eager,
                interactionPrompt: widget.compact
                    ? InteractionPrompt.none
                    : InteractionPrompt.auto,
              )
            else
              _FallbackPreview(
                thumbnailUrl: widget.thumbnailUrl,
                fit: widget.fit,
                iconSize: widget.compact ? 28 : 40,
              ),
            if (_isCheckingModel)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.14),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Preparing 3D preview',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_canRenderModel && !_isCheckingModel)
              Positioned(
                right: 10,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.58),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.threed_rotation,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.allowZoom ? 'Drag / pinch' : 'Drag to rotate',
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
              ),
          ],
        ),
      ),
    );
  }
}

class _FallbackPreview extends StatelessWidget {
  const _FallbackPreview({
    required this.thumbnailUrl,
    required this.fit,
    required this.iconSize,
  });

  final String? thumbnailUrl;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (thumbnailUrl == null || thumbnailUrl!.trim().isEmpty) {
      return Center(
        child: Icon(
          Icons.view_in_ar_outlined,
          size: iconSize,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      thumbnailUrl!,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: iconSize,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
