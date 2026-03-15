import 'package:flutter/material.dart';

import '../../glasses/ui/home_page.dart';
import '../models/order.dart';
import '../models/order_item.dart';

// ─── Palette ──────────────────────────────────────────────────────
class _C {
  static const obsidian   = Color(0xFF080C12);
  static const deepNavy   = Color(0xFF0D1420);
  static const surface    = Color(0xFF111827);
  static const card       = Color(0xFF161F2E);
  static const cardBorder = Color(0xFF1E2D45);
  static const chrome     = Color(0xFFB8C8DC);
  static const electric   = Color(0xFF00A8FF);
  static const textPrim   = Color(0xFFEDF2F8);
  static const textSec    = Color(0xFF7A90A8);
  static const border     = Color(0xFF1E2D45);
  static const success    = Color(0xFF00D4AA);
}

// ═══════════════════════════════════════════════════════════════════
// ORDER SUCCESS PAGE  —  logique backend 100 % originale
// ═══════════════════════════════════════════════════════════════════
class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({
    super.key,
    required this.order,
    required this.items,
  });

  final Order          order;
  final List<OrderItem> items;

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scaleAnim;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: _buildAppBar(),
      body: Stack(children: [
        // Halo success
        Positioned(top: -60, left: -60,
          child: Container(width: 240, height: 240,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.success.withOpacity(0.10), Colors.transparent])))),
        Positioned(bottom: -80, right: -60,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.electric.withOpacity(0.06), Colors.transparent])))),

        SafeArea(child: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              // ── Check animé ───────────────────────────────
              _SuccessHero(
                scaleAnim: _scaleAnim,
                orderId: widget.order.orderId.toString(),
                status: widget.order.status,
                total: widget.order.total,
              ),
              const SizedBox(height: 20),

              // ── Résumé commande ───────────────────────────
              _OrderSummaryCard(items: widget.items, order: widget.order),
            ],
          ),
        )),
      ]),

      // Bouton Back to Home (original)
      bottomNavigationBar: _buildHomeBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.deepNavy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ORDER CONFIRMED', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 2)),
        Text('VTON GLASSES', style: TextStyle(fontSize: 9,
            color: _C.electric, letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _C.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.success.withOpacity(0.35))),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: _C.success, size: 11),
            const SizedBox(width: 4),
            const Text('PAID', style: TextStyle(fontSize: 9,
                color: _C.success, fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
          ]),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent, _C.success, Colors.transparent])))),
    );
  }

  Widget _buildHomeBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _C.deepNavy,
        border: const Border(top: BorderSide(color: _C.border, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: _GlowButton(
          label: 'BACK TO HOME',
          icon: Icons.home_rounded,
          color: _C.success,
          onTap: () {
            // original navigation
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }
}

// ── Hero succès ───────────────────────────────────────────────────
class _SuccessHero extends StatelessWidget {
  final Animation<double> scaleAnim;
  final String orderId, status;
  final double total;
  const _SuccessHero({required this.scaleAnim, required this.orderId,
      required this.status, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.success.withOpacity(0.12), _C.success.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.success.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: _C.success.withOpacity(0.12),
            blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(children: [
        // Check animé
        ScaleTransition(
          scale: scaleAnim,
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF00B896), _C.success],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: _C.success.withOpacity(0.40),
                  blurRadius: 20, offset: const Offset(0, 6))]),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 38)),
        ),
        const SizedBox(height: 18),

        const Text('Payment successful', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900, color: _C.textPrim)),
        const SizedBox(height: 8),
        const Text('Votre commande a bien été confirmée',
            style: TextStyle(fontSize: 13, color: _C.textSec)),
        const SizedBox(height: 20),

        // Infos commande
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.cardBorder)),
          child: Column(children: [
            _InfoLine(label: 'Order', value: '#$orderId'),
            const SizedBox(height: 8),
            _InfoLine(label: 'Status', value: status),
            const SizedBox(height: 8),
            _InfoLine(
                label: 'Total paid',
                value: '\$${total.toStringAsFixed(2)}',
                valueColor: _C.success),
          ]),
        ),
      ]),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label, value; final Color? valueColor;
  const _InfoLine({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: const TextStyle(
          fontSize: 12, color: _C.textSec)),
      const Spacer(),
      Text(value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: valueColor ?? _C.textPrim)),
    ]);
  }
}

// ── Order summary card ────────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  final List<OrderItem> items;
  final Order order;
  const _OrderSummaryCard({required this.items, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 1)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            border: Border(bottom: BorderSide(color: _C.cardBorder))),
          child: Row(children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_C.electric, Color(0xFF0070B8)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Icon(Icons.receipt_long_outlined, color: _C.electric, size: 16),
            const SizedBox(width: 8),
            const Text('Summary', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w800, color: _C.textPrim)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ...items.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.electric.withOpacity(0.7))),
                const SizedBox(width: 10),
                Expanded(child: Text('${e.name} ×${e.quantity}',
                    style: const TextStyle(fontSize: 12, color: _C.textSec))),
                Text('\$${e.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: _C.textPrim)),
              ]),
            )),
            const SizedBox(height: 10),
            Container(height: 1, color: _C.cardBorder),
            const SizedBox(height: 10),
            Row(children: [
              const Text('TOTAL', style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w800, color: _C.textPrim,
                  letterSpacing: 0.5)),
              const Spacer(),
              Text('\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w900, color: _C.success)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── Glow button ───────────────────────────────────────────────────
class _GlowButton extends StatefulWidget {
  final String label; final IconData icon;
  final Color color; final VoidCallback onTap;
  const _GlowButton({required this.label, required this.icon,
      required this.color, required this.onTap});
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
        child: Container(height: 54, margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [widget.color.withOpacity(0.8), widget.color,
                         widget.color.withOpacity(0.8)],
                begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: widget.color.withOpacity(_p ? 0.2 : 0.35),
                blurRadius: _p ? 10 : 22, offset: const Offset(0, 5))]),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 0, left: 16, right: 16,
              child: Container(height: 1, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent, Colors.white24, Colors.transparent])))),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, color: Colors.white, size: 16),
              const SizedBox(width: 10),
              Text(widget.label, style: const TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ]),
          ]),
        ),
      ),
    );
  }
}