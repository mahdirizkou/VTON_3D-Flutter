import 'dart:math' as math;

import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _pulseAnim;

  final List<_StyleCard> _styles = const <_StyleCard>[
    _StyleCard('Aviator', Icons.flight_outlined, Color(0xFF00A8FF), 'Classic & timeless'),
    _StyleCard('Round', Icons.circle_outlined, Color(0xFF8B5CF6), 'Retro inspired'),
    _StyleCard('Square', Icons.crop_square_outlined, Color(0xFF00D4AA), 'Bold & modern'),
    _StyleCard('Cat Eye', Icons.visibility_outlined, Color(0xFFF59E0B), 'Elegant curves'),
    _StyleCard('Sport', Icons.sports_outlined, Color(0xFFFF4D6A), 'Performance'),
    _StyleCard('Rimless', Icons.remove_outlined, Color(0xFFB8C8DC), 'Minimalist'),
  ];

  final List<_TrendBadge> _trends = const <_TrendBadge>[
    _TrendBadge('Blue Light Block', Color(0xFF00A8FF)),
    _TrendBadge('Titanium Frame', Color(0xFFB8C8DC)),
    _TrendBadge('Gradient Lens', Color(0xFF8B5CF6)),
    _TrendBadge('Anti-UV 400', Color(0xFF00D4AA)),
    _TrendBadge('Flex Hinge', Color(0xFFF59E0B)),
    _TrendBadge('Photochromic', Color(0xFFFF4D6A)),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: AppBar(
        backgroundColor: _C.deepNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'EXPLORE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _C.textPrim,
                letterSpacing: 2.6,
              ),
            ),
            Text(
              'TRENDING FRAMES',
              style: TextStyle(
                fontSize: 9,
                color: _C.electric,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Colors.transparent, _C.electric, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                return Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        _C.electric.withOpacity(0.11 * _pulseAnim.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    _C.purple.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HexGridPainter(_pulseAnim),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: <Widget>[
                  const _HeroPanel(),
                  const SizedBox(height: 16),
                  const _StatsBar(),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Trend Signals',
                    subtitle: 'Materials and lens features trending now',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _trends
                        .map(( _TrendBadge trend) => _TrendPill(data: trend))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Frame Styles',
                    subtitle: 'A curated grid of silhouettes to explore',
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _styles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.12,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return _StyleTile(data: _styles[index]);
                    },
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Editorial Picks',
                    subtitle: 'Visual directions for your next pair',
                  ),
                  const SizedBox(height: 12),
                  const _EditorialCard(
                    title: 'Studio Chrome',
                    subtitle: 'Sharp titanium lines with cool metallic finishes.',
                    accent: _C.electric,
                    icon: Icons.auto_awesome_outlined,
                  ),
                  const SizedBox(height: 12),
                  const _EditorialCard(
                    title: 'Soft Retro',
                    subtitle: 'Rounded rims, warm tints, and light acetate volumes.',
                    accent: _C.purple,
                    icon: Icons.blur_circular_outlined,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0D1420), Color(0xFF131E30), Color(0xFF0B111A)],
        ),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _C.electric.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _C.electric.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.electric.withOpacity(0.30)),
            ),
            child: const Text(
              'Curated weekly',
              style: TextStyle(
                fontSize: 10,
                color: _C.electric,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Discover premium frames built for style and 3D try-on.',
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: _C.textPrim,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Browse silhouettes, materials, and trend signals before jumping into the fitting flow.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _C.textSec,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _C.textPrim,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: _C.textSec,
          ),
        ),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.data,
  });

  final _StyleCard data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: data.color.withOpacity(0.28)),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const Spacer(),
          Text(
            data.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _C.textPrim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: _C.textSec,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialCard extends StatelessWidget {
  const _EditorialCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 1),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.25)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrim,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _C.textSec,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.data});

  final _TrendBadge data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 11,
              color: data.color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.value, this.label);

  final String value;
  final String label;
}

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    const List<_StatItem> stats = <_StatItem>[
      _StatItem('500+', 'Frames'),
      _StatItem('50+', 'Brands'),
      _StatItem('3D', 'Try-On'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.cardBorder, width: 1),
      ),
      child: Row(
        children: List<Widget>.generate(stats.length * 2 - 1, (int index) {
          if (index.isOdd) {
            return Container(width: 1, height: 32, color: _C.cardBorder);
          }

          final _StatItem stat = stats[index ~/ 2];
          return Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  stat.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _C.electric,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _C.textSec,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StyleCard {
  const _StyleCard(this.name, this.icon, this.color, this.subtitle);

  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _TrendBadge {
  const _TrendBadge(this.label, this.color);

  final String label;
  final Color color;
}

class _HexGridPainter extends CustomPainter {
  const _HexGridPainter(this.opacity);

  final Animation<double> opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = _C.electric.withOpacity(0.018 * opacity.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const double radius = 40.0;
    const double dx = radius * 1.732;
    const double dy = radius * 1.5;
    int row = 0;

    for (double y = -radius; y < size.height + radius; y += dy) {
      final double offset = row.isEven ? 0.0 : dx / 2;
      for (double x = -radius + offset; x < size.width + radius; x += dx) {
        final Path path = Path();
        for (int i = 0; i < 6; i++) {
          final double angle = (math.pi / 180) * (60 * i - 30);
          final Offset point = Offset(
            x + radius * math.cos(angle),
            y + radius * math.sin(angle),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) {
    return oldDelegate.opacity.value != opacity.value;
  }
}

class _C {
  static const Color obsidian = Color(0xFF080C12);
  static const Color deepNavy = Color(0xFF0D1420);
  static const Color surface = Color(0xFF111827);
  static const Color cardBorder = Color(0xFF1E2D45);
  static const Color electric = Color(0xFF00A8FF);
  static const Color textPrim = Color(0xFFEDF2F8);
  static const Color textSec = Color(0xFF7A90A8);
  static const Color purple = Color(0xFF8B5CF6);
}
