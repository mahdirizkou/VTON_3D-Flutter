import 'package:flutter/material.dart';

import '../models/glasses_item.dart';

// ─── Palette ──────────────────────────────────────────────────────
class _C {
  static const obsidian   = Color(0xFF080C12);
  static const deepNavy   = Color(0xFF0D1420);
  static const surface    = Color(0xFF111827);
  static const cardBorder = Color(0xFF1E2D45);
  static const chrome     = Color(0xFFB8C8DC);
  static const chromeDim  = Color(0xFF6B8099);
  static const electric   = Color(0xFF00A8FF);
  static const textPrim   = Color(0xFFEDF2F8);
  static const textSec    = Color(0xFF7A90A8);
  static const border     = Color(0xFF1E2D45);
  static const error      = Color(0xFFFF4D6A);
  static const success    = Color(0xFF00D4AA);
  static const warning    = Color(0xFFF59E0B);
}

// ═══════════════════════════════════════════════════════════════════
// FAVORITES PAGE  —  logique backend 100 % originale
// ═══════════════════════════════════════════════════════════════════
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.allItems,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onTryTap,
  });

  // ── Props originales ───────────────────────────────────────────
  final List<GlassesItem>   allItems;
  final Set<int>            favoriteIds;
  final ValueChanged<int>   onToggleFavorite;
  final ValueChanged<GlassesItem> onTryTap;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // Logique originale
    final List<GlassesItem> favorites = widget.allItems
        .where((item) => widget.favoriteIds.contains(item.id))
        .toList();

    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: _buildAppBar(favorites.length),
      body: Stack(children: [
        Positioned(top: -80, left: -60,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.error.withOpacity(0.07), Colors.transparent,
              ])),
          ),
        ),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: favorites.isEmpty
                ? _buildEmpty()
                : _buildList(favorites),
          ),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar(int count) {
    return AppBar(
      backgroundColor: _C.deepNavy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FAVORITES', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 2.5)),
        Text('VTON GLASSES', style: TextStyle(fontSize: 9, color: _C.electric,
            letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        if (count > 0)
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _C.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.error.withOpacity(0.3), width: 1)),
            child: Row(children: [
              const Icon(Icons.favorite_rounded, color: _C.error, size: 13),
              const SizedBox(width: 5),
              Text('$count', style: const TextStyle(fontSize: 12,
                  color: _C.error, fontWeight: FontWeight.w800)),
            ]),
          ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent, _C.electric, Colors.transparent])))),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _C.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _C.cardBorder, width: 1)),
          child: const Icon(Icons.favorite_outline,
              color: _C.chromeDim, size: 32),
        ),
        const SizedBox(height: 16),
        const Text('No favorites yet.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: _C.textPrim)),
        const SizedBox(height: 6),
        const Text('Save frames you like.',
            style: TextStyle(fontSize: 13, color: _C.textSec)),
      ]),
    );
  }

  Widget _buildList(List<GlassesItem> favorites) {
    return ListView.separated(
            primary: false,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _FavTile(
          item: favorites[index],
          onTryTap: () => widget.onTryTap(favorites[index]),       // original
          onRemove: () => widget.onToggleFavorite(favorites[index].id), // original
          delay: Duration(milliseconds: 60 * index),
        );
      },
    );
  }
}

// ── Tile favori ───────────────────────────────────────────────────
class _FavTile extends StatefulWidget {
  final GlassesItem item;
  final VoidCallback onTryTap;
  final VoidCallback onRemove;
  final Duration delay;
  const _FavTile({required this.item, required this.onTryTap,
      required this.onRemove, required this.delay});

  @override
  State<_FavTile> createState() => _FavTileState();
}

class _FavTileState extends State<_FavTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 450));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final GlassesItem item = widget.item;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.cardBorder, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: _C.deepNavy,
                  border: Border.all(color: _C.cardBorder)),
                child: Image.network(
                  item.thumbnailUrl ??
                      'https://picsum.photos/seed/fav_${item.id}/300/300',
                  width: 58, height: 58, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 58, height: 58, color: _C.deepNavy,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined,
                        color: _C.chromeDim, size: 20)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: _C.textPrim),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${item.brand ?? 'Unknown brand'} · \$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: _C.textSec)),
              if (item.rating != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: _C.warning, size: 11),
                  const SizedBox(width: 3),
                  Text(item.rating!.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10,
                          color: _C.warning, fontWeight: FontWeight.w600)),
                ]),
              ],
            ])),

            const SizedBox(width: 8),

            // Actions (originales)
            Column(children: [
              _ActionBtn(
                icon: Icons.play_circle_outline_rounded,
                color: _C.electric,
                onTap: widget.onTryTap, // original
              ),
              const SizedBox(height: 6),
              _ActionBtn(
                icon: Icons.favorite_rounded,
                color: _C.error,
                onTap: widget.onRemove, // original
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});
  @override State<_ActionBtn> createState() => _ActionBtnState();
}
class _ActionBtnState extends State<_ActionBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _p
              ? widget.color.withOpacity(0.2)
              : widget.color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: widget.color.withOpacity(_p ? 0.5 : 0.25), width: 1)),
        child: Icon(widget.icon, color: widget.color, size: 18),
      ),
    );
  }
}