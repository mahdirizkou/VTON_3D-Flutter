import 'dart:math';
import 'package:flutter/material.dart';

// ─── Palette ──────────────────────────────────────────────────────
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
  static const purple     = Color(0xFF8B5CF6);
}

// ═══════════════════════════════════════════════════════════════════
// EXPLORE PAGE  —  contenu original, design premium
// ═══════════════════════════════════════════════════════════════════
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() { _entryCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  // ── Données des styles ────────────────────────────────────────
  final List<_StyleCard> _styles = const [
    _StyleCard('Aviator', Icons.flight_outlined,
        Color(0xFF00A8FF), 'Classic & timeless'),
    _StyleCard('Round', Icons.circle_outlined,
        Color(0xFF8B5CF6), 'Retro inspired'),
    _StyleCard('Square', Icons.crop_square_outlined,
        Color(0xFF00D4AA), 'Bold & modern'),
    _StyleCard('Cat Eye', Icons.visibility_outlined,
        Color(0xFFF59E0B), 'Elegant curves'),
    _StyleCard('Sport', Icons.sports_outlined,
        Color(0xFFFF4D6A), 'Performance'),
    _StyleCard('Rimless', Icons.remove_outlined,
        Color(0xFFB8C8DC), 'Minimalist'),
  ];

  final List<_TrendBadge> _trends = const [
    _TrendBadge('Blue Light Block', Color(0xFF00A8FF)),
    _TrendBadge('Titanium Frame', Color(0xFFB8C8DC)),
    _TrendBadge('Gradient Lens', Color(0xFF8B5CF6)),
    _TrendBadge('Anti-UV 400', Color(0xFF00D4AA)),
    _TrendBadge('Flex Hinge', Color(0xFFF59E0B)),
    _TrendBadge('Photochromic', Color(0xFFFF4D6A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: _buildAppBar(),
      body: Stack(children: [
        // Grille hex
        Positioned.fill(child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) =>
              CustomPaint(painter: _HexGridPainter(_pulseAnim.value)),
        )),
        // Halos
        Positioned(top: -80, right: -50,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.electric.withOpacity(0.08), Colors.transparent,
              ])),
          ),
        ),
        Positioned(bottom: -80, left: -50,
          child: Container(width: 180, height: 180,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.purple.withOpacity(0.07), Colors.transparent,
              ])),
          ),
        ),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ListView(
              primary: false,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                // ── Hero discover ────────────────────────────
                _DiscoverHero(),
                const SizedBox(height: 24),

                // ── Section Styles ───────────────────────────
                _SectionLabel(title: 'Discover trending frames and styles.'),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _styles.length,
                  itemBuilder: (context, i) => _StyleTile(
                    data: _styles[i],
                    delay: Duration(milliseconds: 80 * i),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section Trends ───────────────────────────
                _SectionLabel(title: 'Trending Technologies'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _trends.map((t) => _TrendPill(data: t)).toList(),
                ),
                const SizedBox(height: 24),

                // ── Stats bar ────────────────────────────────
                _StatsBar(),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.deepNavy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('EXPLORE', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 2.5)),
        Text('VTON GLASSES', style: TextStyle(fontSize: 9, color: _C.electric,
            letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _C.electric.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.electric.withOpacity(0.4), width: 1)),
          child: const Text('NEW', style: TextStyle(fontSize: 10,
              color: _C.electric, fontWeight: FontWeight.w800,
              letterSpacing: 1.5)),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent, _C.electric, Colors.transparent])))),
    );
  }
}

// ── Discover Hero ─────────────────────────────────────────────────
class _DiscoverHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.electric.withOpacity(0.15), _C.purple.withOpacity(0.10)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.electric.withOpacity(0.25), width: 1),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.electric.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6)),
            child: const Text('EXPLORE', style: TextStyle(fontSize: 9,
                color: _C.electric, fontWeight: FontWeight.w800,
                letterSpacing: 2)),
          ),
          const SizedBox(height: 10),
          const Text('Discover\nTrending Styles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                  color: _C.textPrim, height: 1.2, letterSpacing: 0.2)),
          const SizedBox(height: 6),
          const Text('Browse 500+ 3D-ready frames',
              style: TextStyle(fontSize: 12, color: _C.textSec)),
        ])),
        const SizedBox(width: 16),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0078CC), _C.electric]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: _C.electric.withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 5))]),
          child: const Icon(Icons.explore_rounded,
              color: Colors.white, size: 30),
        ),
      ]),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 16,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_C.electric,
              Color(0xFF0070B8)], begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 14,
          fontWeight: FontWeight.w800, color: _C.textPrim, letterSpacing: 0.2))),
    ]);
  }
}

// ── Style tile ────────────────────────────────────────────────────
class _StyleTile extends StatefulWidget {
  final _StyleCard data;
  final Duration delay;
  const _StyleTile({required this.data, required this.delay});

  @override State<_StyleTile> createState() => _StyleTileState();
}
class _StyleTileState extends State<_StyleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final _StyleCard d = widget.data;
    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {},
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _pressed
                      ? d.color.withOpacity(0.4)
                      : _C.cardBorder,
                  width: 1),
              boxShadow: _pressed ? [BoxShadow(
                  color: d.color.withOpacity(0.15),
                  blurRadius: 12, offset: const Offset(0, 3))] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: d.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: d.color.withOpacity(0.25))),
                child: Icon(d.icon, color: d.color, size: 22)),
              const SizedBox(height: 8),
              Text(d.name, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: _C.textPrim)),
              const SizedBox(height: 3),
              Text(d.subtitle, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: _C.textSec)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Trend pill ────────────────────────────────────────────────────
class _TrendPill extends StatelessWidget {
  final _TrendBadge data;
  const _TrendPill({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withOpacity(0.3), width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: data.color)),
        const SizedBox(width: 6),
        Text(data.label, style: TextStyle(
            fontSize: 11, color: data.color,
            fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      ]),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────
class _StatItem {
  final String value, label;
  const _StatItem(this.value, this.label);
}

class _StatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const List<_StatItem> stats = [
      _StatItem('500+', 'Frames'),
      _StatItem('50+',  'Brands'),
      _StatItem('3D',   'Try-On'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.cardBorder, width: 1)),
      child: Row(
        children: List.generate(stats.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Container(width: 1, height: 32, color: _C.cardBorder);
          }
          final _StatItem s = stats[i ~/ 2];
          return Expanded(child: Column(children: [
            Text(s.value, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: _C.electric)),
            const SizedBox(height: 2),
            Text(s.label, style: const TextStyle(
                fontSize: 10, color: _C.textSec, letterSpacing: 0.5)),
          ]));
        }),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────
class _StyleCard {
  final String name, subtitle;
  final IconData icon;
  final Color color;
  const _StyleCard(this.name, this.icon, this.color, this.subtitle);
}

class _TrendBadge {
  final String label; final Color color;
  const _TrendBadge(this.label, this.color);
}

// ── Grille hexagonale ─────────────────────────────────────────────
class _HexGridPainter extends CustomPainter {
  final double opacity;
  const _HexGridPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.electric.withOpacity(0.018 * opacity)
      ..style = PaintingStyle.stroke ..strokeWidth = 0.5;
    const r = 40.0; const dx = r * 1.732; const dy = r * 1.5;
    int row = 0;
    for (double y = -r; y < size.height + r; y += dy) {
      final off = (row % 2 == 0) ? 0.0 : dx / 2;
      for (double x = -r + off; x < size.width + r; x += dx) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (pi / 180) * (60 * i - 30);
          final pt = Offset(x + r * cos(a), y + r * sin(a));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close(); canvas.drawPath(path, paint);
      }
      row++;
    }
  }
  @override bool shouldRepaint(_HexGridPainter old) => old.opacity != opacity;
}