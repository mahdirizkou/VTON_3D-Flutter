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
// NOTIFICATIONS PAGE  —  contenu original, design premium
// ═══════════════════════════════════════════════════════════════════
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double>   _fadeAnim;

  // Données des notifs (originales)
  final List<_NotifData> _notifications = const [
    _NotifData(
      icon: Icons.local_offer_outlined,
      title: 'New arrivals this week',
      subtitle: 'Check out 8 new 3D-ready frames.',
      color: Color(0xFF00A8FF),
      time: '2h ago',
      isNew: true,
    ),
    _NotifData(
      icon: Icons.favorite_outline,
      title: 'Price drop on your favorites',
      subtitle: 'Some saved frames are now on sale.',
      color: Color(0xFFFF4D6A),
      time: '5h ago',
      isNew: true,
    ),
    _NotifData(
      icon: Icons.tips_and_updates_outlined,
      title: 'Try-On tip',
      subtitle: 'Use good lighting for better face tracking.',
      color: Color(0xFFF59E0B),
      time: 'Yesterday',
      isNew: false,
    ),
  ];

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
    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: _buildAppBar(),
      body: Stack(children: [
        Positioned(top: -80, right: -60,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.electric.withOpacity(0.07), Colors.transparent,
              ])),
          ),
        ),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              // Header résumé
              _NotifHeader(count: _notifications.where((n) => n.isNew).length),

              // Liste
              Expanded(
                child: ListView.separated(
            primary: false,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _NotifTile(
                      data: _notifications[index],
                      delay: Duration(milliseconds: 100 * index),
                    );
                  },
                ),
              ),
            ]),
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
        const Text('NOTIFICATIONS', style: TextStyle(fontSize: 14,
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
          child: const Text('Mark all read', style: TextStyle(fontSize: 10,
              color: _C.electric, fontWeight: FontWeight.w600)),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent, _C.electric, Colors.transparent])))),
    );
  }
}

// ── Header résumé ─────────────────────────────────────────────────
class _NotifHeader extends StatelessWidget {
  final int count;
  const _NotifHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.cardBorder, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _C.electric.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.electric.withOpacity(0.3))),
          child: const Icon(Icons.notifications_rounded,
              color: _C.electric, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count nouvelles notifications',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: _C.textPrim)),
          const Text('Restez informé de vos lunettes préférées',
              style: TextStyle(fontSize: 11, color: _C.textSec)),
        ]),
        const Spacer(),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0078CC), _C.electric]),
            borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('$count',
              style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w800))),
        ),
      ]),
    );
  }
}

// ── Tile notification ─────────────────────────────────────────────
class _NotifTile extends StatefulWidget {
  final _NotifData data;
  final Duration delay;
  const _NotifTile({required this.data, required this.delay});

  @override
  State<_NotifTile> createState() => _NotifTileState();
}

class _NotifTileState extends State<_NotifTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final _NotifData d = widget.data;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: d.isNew
                  ? d.color.withOpacity(0.25)
                  : _C.cardBorder,
              width: 1),
            boxShadow: d.isNew ? [
              BoxShadow(color: d.color.withOpacity(0.08),
                  blurRadius: 12, offset: const Offset(0, 3))
            ] : [],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: d.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: d.color.withOpacity(0.25))),
                child: Icon(d.icon, color: d.color, size: 20),
              ),
              const SizedBox(width: 12),

              // Texte
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(d.title,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: _C.textPrim))),
                  if (d.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.electric.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                      child: const Text('NEW', style: TextStyle(
                          fontSize: 8, color: _C.electric,
                          fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(d.subtitle, style: const TextStyle(
                    fontSize: 12, color: _C.textSec, height: 1.4)),
                const SizedBox(height: 6),
                Text(d.time, style: const TextStyle(
                    fontSize: 10, color: _C.chromeDim, letterSpacing: 0.3)),
              ])),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifData {
  final IconData icon;
  final String title, subtitle, time;
  final Color color;
  final bool isNew;
  const _NotifData({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.time, required this.isNew,
  });
}