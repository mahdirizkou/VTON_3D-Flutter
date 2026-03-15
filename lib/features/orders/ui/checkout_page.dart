import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../models/shipping_info.dart';
import 'payment_page.dart';

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
}

// ═══════════════════════════════════════════════════════════════════
// CHECKOUT PAGE  —  logique backend 100 % originale
// ═══════════════════════════════════════════════════════════════════
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
  });

  // ── Props originales ───────────────────────────────────────────
  final List<OrderItem> items;
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {
  // ── Contrôleurs originaux ──────────────────────────────────────
  final _formKey          = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController    = TextEditingController();
  final _countryController = TextEditingController();

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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── _goToPayment original ──────────────────────────────────────
  void _goToPayment() {
    if (!_formKey.currentState!.validate()) return;
    final shipping = ShippingInfo(
      name:    _nameController.text.trim(),
      phone:   _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city:    _cityController.text.trim(),
      country: _countryController.text.trim(),
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentPage(
        items: widget.items, shipping: shipping, total: widget.total),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: _buildAppBar(),
      body: Stack(children: [
        Positioned(top: -80, left: -60,
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
                // ── Adresse de livraison ──────────────────────
                _FormCard(
                  icon: Icons.local_shipping_outlined,
                  iconColor: _C.electric,
                  title: 'Shipping Address',
                  children: [
                    _OpticalField(ctrl: _nameController,
                        label: 'FULL NAME', hint: 'Jean Dupont',
                        icon: Icons.person_outline_rounded,
                        validator: _required),
                    const SizedBox(height: 14),
                    _OpticalField(ctrl: _phoneController,
                        label: 'PHONE', hint: '+212 6XX XXX XXX',
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        validator: _required),
                    const SizedBox(height: 14),
                    _OpticalField(ctrl: _addressController,
                        label: 'ADDRESS', hint: '123 Rue principale',
                        icon: Icons.home_outlined,
                        validator: _required),
                    const SizedBox(height: 14),
                    _OpticalField(ctrl: _cityController,
                        label: 'CITY', hint: 'Casablanca',
                        icon: Icons.location_city_outlined,
                        validator: _required),
                    const SizedBox(height: 14),
                    _OpticalField(ctrl: _countryController,
                        label: 'COUNTRY', hint: 'Morocco',
                        icon: Icons.flag_outlined,
                        validator: _required),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Résumé commande ───────────────────────────
                _FormCard(
                  icon: Icons.receipt_long_outlined,
                  iconColor: _C.success,
                  title: 'Order Summary',
                  children: [
                    ...widget.items.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Expanded(child: Text('${e.name} ×${e.quantity}',
                            style: const TextStyle(
                                fontSize: 12, color: _C.textSec))),
                        Text('\$${e.lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: _C.textPrim)),
                      ]),
                    )),
                    const SizedBox(height: 8),
                    Container(height: 1, color: _C.cardBorder),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Subtotal', value: widget.subtotal),
                    const SizedBox(height: 5),
                    _SummaryRow(label: 'Shipping', value: widget.shipping),
                    const SizedBox(height: 5),
                    _SummaryRow(label: 'Tax',      value: widget.tax),
                    const SizedBox(height: 8),
                    Container(height: 1, color: _C.cardBorder),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'TOTAL',    value: widget.total, bold: true),
                  ],
                ),
              ],
            ),
          ),
        )),
      ]),

      bottomNavigationBar: _buildPayBar(),
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
        const Text('CHECKOUT', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 2.5)),
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
            Container(width: 5, height: 5, decoration: const BoxDecoration(
                shape: BoxShape.circle, color: _C.success)),
            const SizedBox(width: 5),
            const Text('SSL', style: TextStyle(fontSize: 9,
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

  Widget _buildPayBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _C.deepNavy,
        border: const Border(top: BorderSide(color: _C.border, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: _GlowButton(label: 'PAY — \$${widget.total.toStringAsFixed(2)}',
            icon: Icons.credit_card_outlined, onTap: _goToPayment),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

// ── Form card ─────────────────────────────────────────────────────
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
        Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
      ]),
    );
  }
}

// ── Optical field ─────────────────────────────────────────────────
class _OpticalField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label, hint; final IconData icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  const _OpticalField({required this.ctrl, required this.label,
      required this.hint, required this.icon, this.keyboard, this.validator});
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

// ── Summary row ───────────────────────────────────────────────────
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
          color: bold ? _C.textPrim : _C.textSec)),
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