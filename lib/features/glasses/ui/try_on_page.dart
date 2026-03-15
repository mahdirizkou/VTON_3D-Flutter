import 'package:flutter/material.dart';

import '../../cart/data/cart_controller.dart';
import '../models/glasses_item.dart';

// ═══════════════════════════════════════════════════════════════════
// PALETTE — Luxury Optical Tech
// ═══════════════════════════════════════════════════════════════════
class _C {
  static const obsidian   = Color(0xFF080C12);
  static const deepNavy   = Color(0xFF0D1420);
  static const surface    = Color(0xFF111827);
  static const card       = Color(0xFF161F2E);
  static const cardBorder = Color(0xFF1E2D45);
  static const chrome     = Color(0xFFB8C8DC);
  static const chromeDim  = Color(0xFF6B8099);
  static const electric   = Color(0xFF00A8FF);
  static const textPrim   = Color(0xFFEDF2F8);
  static const textSec    = Color(0xFF7A90A8);
  static const border     = Color(0xFF1E2D45);
  static const success    = Color(0xFF00D4AA);
  static const warning    = Color(0xFFF59E0B);
}

// ═══════════════════════════════════════════════════════════════════
// TRY-ON PAGE  —  logique backend 100 % originale
// ═══════════════════════════════════════════════════════════════════
class TryOnPage extends StatefulWidget {
  const TryOnPage({super.key, required this.item});
  final GlassesItem item;

  @override
  State<TryOnPage> createState() => _TryOnPageState();
}

class _TryOnPageState extends State<TryOnPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final GlassesItem item = widget.item;

    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: AppBar(
        backgroundColor: _C.deepNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border, width: 1)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _C.chrome, size: 16),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TRY-ON', style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 3)),
          Text('3D VIRTUAL', style: TextStyle(
              fontSize: 9, color: _C.electric,
              letterSpacing: 2.5, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.electric.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.electric.withOpacity(0.4), width: 1),
            ),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _C.success)),
              const SizedBox(width: 5),
              const Text('AR LIVE', style: TextStyle(fontSize: 9,
                  color: _C.electric, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
            ]),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent, _C.electric, Colors.transparent])))),
      ),

      body: Stack(children: [
        Positioned(top: -60, right: -60,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.electric.withOpacity(0.08), Colors.transparent,
              ])),
          ),
        ),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image viewer
                    _ImageViewer(item: item),
                    const SizedBox(height: 14),

                    // Infos produit
                    _ProductInfoRow(item: item),
                    const SizedBox(height: 10),

                    // Payload 3D
                    Expanded(child: _PayloadCard(item: item)),
                    const SizedBox(height: 14),

                    // Bouton Open Camera (original)
                    _GlowButton(
                      label: 'Open Camera',
                      icon: Icons.camera_alt_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _styledSnack('Camera placeholder activated.',
                              icon: Icons.camera_alt_outlined,
                              color: _C.electric),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Bouton Add to Cart (original)
                    _OutlineGlowButton(
                      label: 'Add to Cart',
                      icon: Icons.shopping_cart_outlined,
                      onTap: () async {
                        await CartController.instance.addFromGlasses(item);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          _styledSnack('Added to cart',
                              icon: Icons.check_circle_outline,
                              color: _C.success),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Image viewer ──────────────────────────────────────────────────
class _ImageViewer extends StatelessWidget {
  final GlassesItem item;
  const _ImageViewer({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(color: _C.electric.withOpacity(0.10),
              blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.4),
              blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Image.network(
            item.thumbnailUrl ??
                'https://picsum.photos/seed/tryon_${item.id}/900/600',
            height: 240, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 240, color: _C.surface,
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image_outlined,
                      color: _C.chromeDim, size: 36),
                  SizedBox(height: 8),
                  Text('Preview unavailable',
                      style: TextStyle(color: _C.textSec, fontSize: 12)),
                ]),
            ),
          ),
          // Gradient bas
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(height: 60,
              decoration: const BoxDecoration(gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Color(0xCC080C12), Colors.transparent])))),
          // Rating badge
          if (item.rating != null)
            Positioned(top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _C.warning.withOpacity(0.5), width: 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: _C.warning, size: 12),
                  const SizedBox(width: 3),
                  Text(item.rating!.toStringAsFixed(1),
                      style: const TextStyle(color: _C.textPrim,
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              )),
        ]),
      ),
    );
  }
}

// ── Infos produit ─────────────────────────────────────────────────
class _ProductInfoRow extends StatelessWidget {
  final GlassesItem item;
  const _ProductInfoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.cardBorder, width: 1),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w800, color: _C.textPrim)),
          const SizedBox(height: 2),
          Text(item.brand ?? 'Unknown brand',
              style: const TextStyle(fontSize: 12, color: _C.textSec)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0078CC), _C.electric]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: _C.electric.withOpacity(0.25),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Text('\$${item.price.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

// ── Payload 3D ────────────────────────────────────────────────────
class _PayloadCard extends StatelessWidget {
  final GlassesItem item;
  const _PayloadCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: const BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: _C.cardBorder))),
          child: Row(children: [
            Container(width: 3, height: 14,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_C.electric, Color(0xFF0070B8)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Try-On Payload', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w800, color: _C.textPrim)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.success.withOpacity(0.3))),
              child: const Text('3D DATA', style: TextStyle(fontSize: 9,
                  color: _C.success, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
            ),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(children: [
            _DataRow('glb_url',           item.glbUrl ?? '-'),
            _DataRow('scale',             item.scale?.toStringAsFixed(3) ?? '-'),
            _DataRow('position_offset',   item.positionOffset != null
                ? item.positionOffset!.toInlineString() : '-'),
            _DataRow('rotation_offset',   item.rotationOffset != null
                ? item.rotationOffset!.toInlineString() : '-'),
            _DataRow('anchor',            item.anchor ?? '-'),
            _DataRow('version',           item.version ?? '-'),
          ]),
        )),
      ]),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String key0, value;
  const _DataRow(this.key0, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120,
          child: Text(key0, style: const TextStyle(fontSize: 11,
              color: _C.electric, fontWeight: FontWeight.w600,
              letterSpacing: 0.5))),
        Expanded(child: Text(value, style: const TextStyle(
            fontSize: 11, color: _C.textSec))),
      ]),
    );
  }
}

// ── Boutons ───────────────────────────────────────────────────────
class _GlowButton extends StatefulWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _GlowButton({required this.label, required this.icon,
      required this.onTap});
  @override State<_GlowButton> createState() => _GlowButtonState();
}
class _GlowButtonState extends State<_GlowButton> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _p ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0078CC), _C.electric, Color(0xFF00C8FF)],
                begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: _C.electric.withOpacity(_p ? 0.2 : 0.38),
                blurRadius: _p ? 10 : 22, offset: const Offset(0, 5))]),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 0, left: 16, right: 16,
              child: Container(height: 1, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent, Colors.white24, Colors.transparent])))),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(widget.label, style: const TextStyle(color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _OutlineGlowButton extends StatefulWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _OutlineGlowButton({required this.label, required this.icon,
      required this.onTap});
  @override State<_OutlineGlowButton> createState() => _OutlineGlowButtonState();
}
class _OutlineGlowButtonState extends State<_OutlineGlowButton> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _p ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: _p ? _C.electric.withOpacity(0.08) : _C.deepNavy,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _p ? _C.electric.withOpacity(0.7) : _C.cardBorder,
                width: 1.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, color: _p ? _C.electric : _C.chrome, size: 18),
            const SizedBox(width: 10),
            Text(widget.label, style: TextStyle(
                color: _p ? _C.electric : _C.chrome, fontSize: 13,
                fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ]),
        ),
      ),
    );
  }
}

// ── SnackBar stylisé ──────────────────────────────────────────────
SnackBar _styledSnack(String msg,
    {required IconData icon, Color color = _C.electric}) {
  return SnackBar(
    content: Row(children: [
      Icon(icon, color: color, size: 18), const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(
          color: _C.textPrim, fontSize: 13))),
    ]),
    backgroundColor: _C.surface,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 1)),
    margin: const EdgeInsets.all(16),
  );
}