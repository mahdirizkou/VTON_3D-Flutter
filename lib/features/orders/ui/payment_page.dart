import 'package:flutter/material.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../../auth/ui/login_page.dart';
import '../../cart/data/cart_controller.dart';
import '../data/orders_api.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/shipping_info.dart';
import 'order_success_page.dart';

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
  static const error      = Color(0xFFFF4D6A);
  static const success    = Color(0xFF00D4AA);
  static const warning    = Color(0xFFF59E0B);
}

// ═══════════════════════════════════════════════════════════════════
// PAYMENT PAGE  —  logique backend 100 % originale
// ═══════════════════════════════════════════════════════════════════
class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.items,
    required this.shipping,
    required this.total,
  });

  final List<OrderItem> items;
  final ShippingInfo    shipping;
  final double          total;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  // ── Contrôleurs originaux ──────────────────────────────────────
  final _formKey              = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController     = TextEditingController();
  final _cvcController        = TextEditingController();
  final OrdersApi _ordersApi  = OrdersApi();

  bool _isPaying = false;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  // ── dispose original ───────────────────────────────────────────
  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── _pay original ──────────────────────────────────────────────
  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPaying = true);
    try {
      final Order order = await _ordersApi.createOrder(
        items: widget.items,
        shipping: widget.shipping,
        paymentMethod: 'mock_card',
      );
      await CartController.instance.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderSuccessPage(
            order: order, items: widget.items)),
        (route) => false,
      );
    } on ApiUnauthorizedException catch (e) {
      if (!mounted) return;
      await TokenStore.instance.clearTokens();
      if (!mounted) return;
      _showSnack(e.toString(), color: _C.error);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), color: _C.error);
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  void _showSnack(String msg, {Color color = _C.electric}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(color: _C.textPrim))),
      ]),
      backgroundColor: _C.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5))),
      margin: const EdgeInsets.all(16),
    ));
  }

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
                _C.electric.withOpacity(0.07), Colors.transparent])))),

        SafeArea(child: FadeTransition(
          opacity: _fadeAnim,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // ── Card mockup visuelle ──────────────────────
                _CreditCardMockup(total: widget.total),
                const SizedBox(height: 20),

                // ── Champs carte ──────────────────────────────
                _FormCard(
                  icon: Icons.credit_card_outlined,
                  iconColor: _C.electric,
                  title: 'Mock Card Payment',
                  children: [
                    _OpticalField(
                      ctrl: _cardNumberController,
                      label: 'CARD NUMBER',
                      hint: '4242 4242 4242 4242',
                      icon: Icons.credit_card_outlined,
                      keyboard: TextInputType.number,
                      validator: (value) {
                        final cleaned = (value ?? '').replaceAll(' ', '');
                        if (cleaned.length < 12 || cleaned.length > 19) {
                          return 'Enter a valid card number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _OpticalField(
                        ctrl: _expiryController,
                        label: 'EXPIRY',
                        hint: 'MM/YY',
                        icon: Icons.calendar_today_outlined,
                        validator: (v) {
                          final val = (v ?? '').trim();
                          if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(val)) {
                            return 'MM/YY';
                          }
                          return null;
                        },
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _OpticalField(
                        ctrl: _cvcController,
                        label: 'CVC',
                        hint: '•••',
                        icon: Icons.lock_outline_rounded,
                        keyboard: TextInputType.number,
                        validator: (v) {
                          final val = (v ?? '').trim();
                          if (!RegExp(r'^\d{3,4}$').hasMatch(val)) {
                            return 'Invalid CVC';
                          }
                          return null;
                        },
                      )),
                    ]),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Total badge ───────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _C.electric.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _C.electric.withOpacity(0.25))),
                  child: Row(children: [
                    const Icon(Icons.receipt_outlined,
                        color: _C.electric, size: 18),
                    const SizedBox(width: 10),
                    const Text('Total à payer',
                        style: TextStyle(fontSize: 13,
                            color: _C.textSec)),
                    const Spacer(),
                    Text('\$${widget.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _C.electric)),
                  ]),
                ),

                // ── Sécurité badge ────────────────────────────
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Container(width: 5, height: 5,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _C.success)),
                  const SizedBox(width: 6),
                  const Text('Paiement 100% sécurisé · SSL Encrypted',
                      style: TextStyle(fontSize: 10,
                          color: _C.textSec, letterSpacing: 0.5)),
                ]),
              ],
            ),
          ),
        )),
      ]),

      bottomNavigationBar: _buildConfirmBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        const Text('PAYMENT', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 2.5)),
        Text('VTON GLASSES', style: TextStyle(fontSize: 9,
            color: _C.electric, letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _C.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.warning.withOpacity(0.35))),
          child: Row(children: [
            const Icon(Icons.lock_outline_rounded,
                color: _C.warning, size: 11),
            const SizedBox(width: 4),
            const Text('MOCK', style: TextStyle(fontSize: 9,
                color: _C.warning, fontWeight: FontWeight.w700,
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

  Widget _buildConfirmBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _C.deepNavy,
        border: const Border(top: BorderSide(color: _C.border, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: _isPaying
            ? Container(
                height: 54, margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _C.surface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.cardBorder)),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(_C.electric))),
                  SizedBox(width: 12),
                  Text('Processing payment…', style: TextStyle(
                      color: _C.textSec, fontSize: 13,
                      fontWeight: FontWeight.w600)),
                ]))
            : _GlowButton(
                label: 'CONFIRM PAYMENT',
                icon: Icons.verified_rounded,
                onTap: _pay),
      ),
    );
  }
}

// ── Carte de crédit visuelle ──────────────────────────────────────
class _CreditCardMockup extends StatelessWidget {
  final double total;
  const _CreditCardMockup({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F3C), Color(0xFF0078CC), Color(0xFF00A8FF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00A8FF).withOpacity(0.30),
              blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.4),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(children: [
        // Cercle déco haut droit
        Positioned(top: -30, right: -30,
          child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06)))),
        Positioned(top: 20, right: -10,
          child: Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04)))),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('VTON', style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w900, color: Colors.white,
                    letterSpacing: 3)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                  child: const Text('MOCK CARD', style: TextStyle(
                      fontSize: 8, color: Colors.white,
                      fontWeight: FontWeight.w700, letterSpacing: 1.5))),
              ]),
              const Text('•••• •••• •••• ••••',
                  style: TextStyle(fontSize: 18, color: Colors.white70,
                      letterSpacing: 4, fontWeight: FontWeight.w300)),
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('AMOUNT', style: TextStyle(fontSize: 8,
                      color: Colors.white54, letterSpacing: 1.5)),
                  Text('\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w900, color: Colors.white)),
                ]),
                const Spacer(),
                const Icon(Icons.credit_card_rounded,
                    color: Colors.white54, size: 32),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Widgets partagés ──────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final IconData icon; final Color iconColor;
  final String title; final List<Widget> children;
  const _FormCard({required this.icon, required this.iconColor,
      required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface, borderRadius: BorderRadius.circular(18),
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
              gradient: LinearGradient(colors: [iconColor,
                  iconColor.withOpacity(0.4)], begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w800, color: _C.textPrim)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(16),
            child: Column(children: children)),
      ]),
    );
  }
}

class _OpticalField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label, hint; final IconData icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  const _OpticalField({required this.ctrl, required this.label,
      required this.hint, required this.icon,
      this.keyboard, this.validator});
  @override State<_OpticalField> createState() => _OpticalFieldState();
}
class _OpticalFieldState extends State<_OpticalField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(widget.label, style: TextStyle(fontSize: 10,
            letterSpacing: 2.2, fontWeight: FontWeight.w700,
            color: _focused ? _C.electric : _C.textSec))),
      Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
            boxShadow: _focused ? [BoxShadow(
                color: _C.electric.withOpacity(0.15), blurRadius: 14,
                spreadRadius: 2)] : []),
          child: TextFormField(
            controller: widget.ctrl, keyboardType: widget.keyboard,
            validator: widget.validator, cursorColor: _C.electric,
            style: const TextStyle(color: _C.textPrim, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color(0xFF3A4A5A), fontSize: 13),
              prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(widget.icon,
                    color: _focused ? _C.electric : _C.chromeDim, size: 18)),
              filled: true, fillColor: _C.deepNavy,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.electric, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.error)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.error, width: 1.5)),
              errorStyle: const TextStyle(color: _C.error, fontSize: 11)),
          ),
        ),
      ),
    ]);
  }
}

class _GlowButton extends StatefulWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _GlowButton({required this.label, required this.icon, required this.onTap});
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