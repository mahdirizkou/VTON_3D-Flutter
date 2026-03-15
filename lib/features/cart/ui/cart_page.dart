import 'package:flutter/material.dart';

import '../../glasses/ui/home_page.dart';
import '../../orders/models/order_item.dart';
import '../../orders/ui/checkout_page.dart';
import '../data/cart_controller.dart';

// ═══════════════════════════════════════════════════════════════════
// PALETTE
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
  static const error      = Color(0xFFFF4D6A);
  static const success    = Color(0xFF00D4AA);
  static const warning    = Color(0xFFF59E0B);
}

// ═══════════════════════════════════════════════════════════════════
// CART PAGE  —  logique backend 100 % originale
// ═══════════════════════════════════════════════════════════════════
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    CartController.instance.ensureLoaded(); // original
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CartController.instance, // original
      builder: (context, _) {
        // ── Logique originale ──────────────────────────────────
        final List<OrderItem> items = CartController.instance.items;
        final double subtotal = CartController.instance.subtotal;
        const double shipping = 0.0;
        const double tax      = 0.0;
        final double total    = subtotal + shipping + tax;

        return Scaffold(
          backgroundColor: _C.obsidian,
          appBar: _buildAppBar(items.length),
          body: Stack(children: [
            Positioned(top: -80, right: -60,
              child: Container(width: 220, height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _C.electric.withOpacity(0.07), Colors.transparent])))),

            FadeTransition(
              opacity: _fadeAnim,
              child: items.isEmpty
                  ? _EmptyCart(
                      onBackHome: () {
                        // original navigation
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        );
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      children: [
                        // Badge items
                        _ItemsBadge(count: items.length),
                        const SizedBox(height: 14),

                        // Items
                        ...items.map((item) => _CartItemTile(item: item)),
                        const SizedBox(height: 16),

                        // Résumé
                        _SummaryCard(
                          subtotal: subtotal,
                          shipping: shipping,
                          tax: tax,
                          total: total,
                        ),
                      ],
                    ),
            ),
          ]),

          // Bouton Checkout (original)
          bottomNavigationBar: items.isEmpty ? null : _buildCheckoutBar(
            items: items, subtotal: subtotal,
            shipping: shipping, tax: tax, total: total,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(int count) {
    return AppBar(
      backgroundColor: _C.deepNavy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: _C.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _C.chrome, size: 16)),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CART', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 2.5)),
        Text('VTON GLASSES', style: TextStyle(fontSize: 9,
            color: _C.electric, letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        if (count > 0)
          GestureDetector(
            onTap: () => CartController.instance.clear(),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _C.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.error.withOpacity(0.35), width: 1)),
              child: const Text('Clear', style: TextStyle(fontSize: 11,
                  color: _C.error, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent, _C.electric, Colors.transparent])))),
    );
  }

  Widget _buildCheckoutBar({
    required List<OrderItem> items,
    required double subtotal, required double shipping,
    required double tax, required double total,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _C.deepNavy,
        border: const Border(top: BorderSide(color: _C.border, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: _GlowButton(
          label: 'CHECKOUT — \$${total.toStringAsFixed(2)}',
          icon: Icons.lock_outline_rounded,
          onTap: () {
            // original navigation
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => CheckoutPage(
                items: List<OrderItem>.from(items),
                subtotal: subtotal, shipping: shipping,
                tax: tax, total: total,
              ),
            ));
          },
        ),
      ),
    );
  }
}

// ── Empty cart ────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final VoidCallback onBackHome;
  const _EmptyCart({required this.onBackHome});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _C.surface, shape: BoxShape.circle,
            border: Border.all(color: _C.cardBorder, width: 1)),
          child: const Icon(Icons.shopping_cart_outlined,
              color: _C.chromeDim, size: 34)),
        const SizedBox(height: 18),
        const Text('Votre panier est vide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: _C.textPrim)),
        const SizedBox(height: 8),
        const Text('Ajoutez des lunettes depuis l\'accueil',
            style: TextStyle(fontSize: 13, color: _C.textSec)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onBackHome,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _C.deepNavy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.electric.withOpacity(0.4), width: 1.5)),
            child: const Text('Back to Home', style: TextStyle(
                color: _C.electric, fontSize: 13, fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
          ),
        ),
      ]),
    ));
  }
}

// ── Badge items count ─────────────────────────────────────────────
class _ItemsBadge extends StatelessWidget {
  final int count;
  const _ItemsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.cardBorder, width: 1)),
      child: Row(children: [
        Container(width: 3, height: 14,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.electric, Color(0xFF0070B8)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        const Icon(Icons.shopping_cart_outlined, color: _C.electric, size: 16),
        const SizedBox(width: 8),
        Text('$count article${count > 1 ? 's' : ''} dans votre panier',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: _C.textPrim)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _C.electric.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.electric.withOpacity(0.3))),
          child: Text('$count', style: const TextStyle(
              fontSize: 11, color: _C.electric, fontWeight: FontWeight.w800))),
      ]),
    );
  }
}

// ── Cart item tile ────────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final OrderItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
            blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(children: [
        // Icône produit
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _C.deepNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.cardBorder)),
          child: const Icon(Icons.remove_red_eye_outlined,
              color: _C.electric, size: 22)),
        const SizedBox(width: 12),

        // Infos
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: _C.textPrim),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('\$${item.unitPrice.toStringAsFixed(2)} each',
              style: const TextStyle(fontSize: 11, color: _C.textSec)),
          const SizedBox(height: 2),
          Text('Total: \$${item.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: _C.electric)),
        ])),

        // Contrôles quantité (original)
        Row(mainAxisSize: MainAxisSize.min, children: [
          _QtyBtn(
            icon: Icons.remove_rounded,
            color: _C.warning,
            onTap: () => CartController.instance.decrement(item.glassesId)),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _C.deepNavy, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.cardBorder)),
            child: Center(child: Text('${item.quantity}',
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w800, color: _C.textPrim)))),
          _QtyBtn(
            icon: Icons.add_rounded,
            color: _C.success,
            onTap: () => CartController.instance.increment(item.glassesId)),
          const SizedBox(width: 4),
          _QtyBtn(
            icon: Icons.delete_outline_rounded,
            color: _C.error,
            onTap: () => CartController.instance.remove(item.glassesId)),
        ]),
      ]),
    );
  }
}

class _QtyBtn extends StatefulWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.color, required this.onTap});
  @override State<_QtyBtn> createState() => _QtyBtnState();
}
class _QtyBtnState extends State<_QtyBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _p ? widget.color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8)),
        child: Icon(widget.icon, color: widget.color, size: 18)),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double subtotal, shipping, tax, total;
  const _SummaryCard({required this.subtotal, required this.shipping,
      required this.tax, required this.total});

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
              gradient: const LinearGradient(colors: [_C.electric, Color(0xFF0070B8)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Text('Résumé de la commande', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: _C.textPrim)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _SummaryRow(label: 'Subtotal', value: subtotal),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Shipping', value: shipping),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Tax', value: tax),
            const SizedBox(height: 10),
            Container(height: 1, color: _C.cardBorder),
            const SizedBox(height: 10),
            _SummaryRow(label: 'TOTAL', value: total, bold: true),
          ]),
        ),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label; final double value; final bool bold;
  const _SummaryRow({required this.label, required this.value,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: TextStyle(
          fontSize: bold ? 14 : 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: bold ? _C.textPrim : _C.textSec,
          letterSpacing: bold ? 0.5 : 0.2)),
      const Spacer(),
      Text('\$${value.toStringAsFixed(2)}', style: TextStyle(
          fontSize: bold ? 16 : 13,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          color: bold ? _C.electric : _C.textPrim)),
    ]);
  }
}

// ── Glow button ───────────────────────────────────────────────────
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
        child: Container(height: 54,
          margin: const EdgeInsets.only(bottom: 8),
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