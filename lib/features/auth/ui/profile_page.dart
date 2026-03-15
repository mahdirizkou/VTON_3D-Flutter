import 'package:flutter/material.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../data/auth_api.dart';
import 'login_page.dart';

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
  static const electricDim= Color(0xFF0070B8);
  static const textPrim   = Color(0xFFEDF2F8);
  static const textSec    = Color(0xFF7A90A8);
  static const border     = Color(0xFF1E2D45);
  static const error      = Color(0xFFFF4D6A);
  static const success    = Color(0xFF00D4AA);
  static const warning    = Color(0xFFF59E0B);
}

// ═══════════════════════════════════════════════════════════════════
// PROFILE PAGE  —  logique backend 100 % originale
// ═══════════════════════════════════════════════════════════════════
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // ── API originale ──────────────────────────────────────────────
  final AuthApi _authApi = AuthApi();

  bool _isLoading    = true;
  bool _isLoggingOut = false;
  String? _error;
  Map<String, dynamic>? _me;

  // ── Animation ──────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _loadProfile();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  // ── _loadProfile original ──────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _authApi.me();
      if (!mounted) return;
      setState(() { _me = data; });
      _entryCtrl.forward(from: 0);
    } on ApiUnauthorizedException catch (e) {
      if (!mounted) return;
      await _logoutAndGoLogin(message: e.toString());
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (!mounted) return;
      setState(() { _isLoading = false; });
    }
  }

  // ── _logoutAndGoLogin original ─────────────────────────────────
  Future<void> _logoutAndGoLogin({String? message}) async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    await TokenStore.instance.clearTokens();
    if (!mounted) return;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: _C.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: const TextStyle(color: _C.textPrim))),
        ]),
        backgroundColor: _C.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _C.error, width: 1)),
        margin: const EdgeInsets.all(16),
      ));
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: _buildAppBar(),
      body: Stack(children: [
        // Halo décoratif
        Positioned(top: -80, right: -60,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.electric.withOpacity(0.07), Colors.transparent,
              ])),
          ),
        ),
        Positioned(bottom: -80, left: -60,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.success.withOpacity(0.05), Colors.transparent,
              ])),
          ),
        ),

        SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadProfile,
            color: _C.electric,
            backgroundColor: _C.surface,
            child: ListView(
              primary: false,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (_isLoading) ...[
                  const SizedBox(height: 120),
                  _buildLoading(),
                ] else if (_error != null) ...[
                  const SizedBox(height: 40),
                  _ErrorCard(message: _error!, onRetry: _loadProfile),
                ] else ...[
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // ── Avatar + nom ─────────────────────
                          _ProfileHeader(
                            username: (_me?['username'] ?? '-').toString(),
                            email: (_me?['email'] ?? '-').toString(),
                          ),
                          const SizedBox(height: 20),

                          // ── Stats rapides ─────────────────────
                          _QuickStats(),
                          const SizedBox(height: 20),

                          // ── Account Info (original) ───────────
                          _InfoCard(
                            title: 'Account Info',
                            icon: Icons.person_outline_rounded,
                            iconColor: _C.electric,
                            items: [
                              _InfoRowData(label: 'ID',
                                  value: (_me?['id'] ?? '-').toString()),
                              _InfoRowData(label: 'Username',
                                  value: (_me?['username'] ?? '-').toString()),
                              _InfoRowData(label: 'Email',
                                  value: (_me?['email'] ?? '-').toString()),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ── Session (original) ────────────────
                          const _InfoCard(
                            title: 'Session',
                            icon: Icons.shield_outlined,
                            iconColor: _C.success,
                            items: [
                              _InfoRowData(label: 'Status',
                                  value: 'Authenticated'),
                              _InfoRowData(label: 'Backend',
                                  value: 'Django JWT'),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // ── Bouton Logout (original) ──────────
                          _LogoutButton(
                            isLoading: _isLoggingOut,
                            onTap: _isLoggingOut ? null : _logoutAndGoLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
        const Text('PROFILE', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 2.5)),
        Text('VTON GLASSES', style: TextStyle(fontSize: 9, color: _C.electric,
            letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _C.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.success.withOpacity(0.4), width: 1)),
          child: Row(children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(
                shape: BoxShape.circle, color: _C.success)),
            const SizedBox(width: 5),
            const Text('ONLINE', style: TextStyle(fontSize: 9,
                color: _C.success, fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
          ]),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent, _C.electric, Colors.transparent])))),
    );
  }

  Widget _buildLoading() {
    return Column(children: const [
      SizedBox(width: 32, height: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(_C.electric))),
      SizedBox(height: 14),
      Text('Chargement du profil…',
          style: TextStyle(color: _C.textSec, fontSize: 13)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════

// ── Header profil ─────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String username, email;
  const _ProfileHeader({required this.username, required this.email});

  @override
  Widget build(BuildContext context) {
    final String initial =
        username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.electric.withOpacity(0.14), _C.electricDim.withOpacity(0.08)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.electric.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(color: _C.electric.withOpacity(0.10),
              blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [Color(0xFF0078CC), _C.electric],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: _C.electric.withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Center(child: Text(initial, style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white))),
        ),
        const SizedBox(width: 16),

        // Nom + email
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(username, style: const TextStyle(fontSize: 20,
              fontWeight: FontWeight.w800, color: _C.textPrim, letterSpacing: 0.2)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(fontSize: 12, color: _C.textSec)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.success.withOpacity(0.3))),
            child: const Text('VTON Member', style: TextStyle(
                fontSize: 10, color: _C.success,
                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ])),

        // Icône edit
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _C.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.cardBorder)),
          child: const Icon(Icons.edit_outlined, color: _C.chromeDim, size: 17),
        ),
      ]),
    );
  }
}

// ── Stats rapides ─────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const List<_StatData> stats = [
      _StatData('0',  'Try-Ons',   Icons.videocam_outlined,   _C.electric),
      _StatData('0',  'Favorites', Icons.favorite_outline,    Color(0xFFFF4D6A)),
      _StatData('0',  'Orders',    Icons.shopping_bag_outlined, _C.success),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.cardBorder, width: 1)),
      child: Row(children: [
        _StatTile(stats[0]),
        Container(width: 1, height: 60, color: _C.cardBorder),
        _StatTile(stats[1]),
        Container(width: 1, height: 60, color: _C.cardBorder),
        _StatTile(stats[2]),
      ]),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_InfoRowData> items;

  const _InfoCard({
    required this.title, required this.icon,
    required this.iconColor, required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // Header section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            border: const Border(bottom: BorderSide(color: _C.cardBorder))),
          child: Row(children: [
            Container(width: 3, height: 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [iconColor, iconColor.withOpacity(0.4)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w800, color: _C.textPrim, letterSpacing: 0.3)),
          ]),
        ),

        // Rows
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: List.generate(items.length, (i) {
            final _InfoRowData item = items[i];
            return Column(children: [
              Row(children: [
                Text(item.label, style: const TextStyle(
                    fontSize: 12, color: _C.textSec, letterSpacing: 0.3)),
                const Spacer(),
                Flexible(child: Text(item.value, textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: _C.textPrim))),
              ]),
              if (i < items.length - 1) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: _C.cardBorder.withOpacity(0.6)),
                const SizedBox(height: 8),
              ],
            ]);
          })),
        ),
      ]),
    );
  }
}

// ── InfoRowData ───────────────────────────────────────────────────
class _InfoRowData {
  final String label, value;
  const _InfoRowData({required this.label, required this.value});
}

// ── Bouton Logout ─────────────────────────────────────────────────
class _LogoutButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _LogoutButton({required this.isLoading, this.onTap});

  @override State<_LogoutButton> createState() => _LogoutButtonState();
}
class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: _pressed
                ? _C.error.withOpacity(0.15)
                : _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed
                  ? _C.error.withOpacity(0.7)
                  : _C.error.withOpacity(0.4),
              width: 1.5),
            boxShadow: _pressed ? [BoxShadow(
                color: _C.error.withOpacity(0.15),
                blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.isLoading)
              const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(_C.error)))
            else ...[
              Icon(Icons.logout_rounded,
                  color: _pressed ? _C.error : _C.error.withOpacity(0.8),
                  size: 18),
              const SizedBox(width: 10),
              Text(widget.isLoading ? 'Logging out…' : 'Logout',
                  style: TextStyle(
                    color: _pressed ? _C.error : _C.error.withOpacity(0.8),
                    fontSize: 13, fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.error.withOpacity(0.3), width: 1)),
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: _C.error.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: _C.error.withOpacity(0.3))),
          child: const Icon(Icons.error_outline_rounded,
              color: _C.error, size: 26)),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: _C.textSec, fontSize: 13, height: 1.5)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0078CC), _C.electric]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _C.electric.withOpacity(0.25),
                  blurRadius: 12, offset: const Offset(0, 4))]),
            child: const Text('Retry', style: TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
        ),
      ]),
    );
  }
}

// ── StatTile widget ──────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final _StatData data;
  const _StatTile(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(data.icon, color: data.color, size: 18),
        const SizedBox(height: 5),
        Text(data.value, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: data.color)),
        const SizedBox(height: 2),
        Text(data.label, style: const TextStyle(
            fontSize: 9, color: _C.textSec, letterSpacing: 0.5)),
      ]),
    ));
  }
}

// ── StatData ──────────────────────────────────────────────────────
class _StatData {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatData(this.value, this.label, this.icon, this.color);
}