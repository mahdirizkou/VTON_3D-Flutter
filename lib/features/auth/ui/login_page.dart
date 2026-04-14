import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/token_store.dart';
import '../../glasses/ui/home_page.dart';
import '../data/auth_api.dart';
import '../data/social_auth_api.dart';
import 'register_page.dart';
import 'forgot_password_page.dart'; // ✅ ADDED

// ═══════════════════════════════════════════════════════════════════
// PALETTE — Luxury Optical Tech
// ═══════════════════════════════════════════════════════════════════
class _C {
  static const obsidian    = Color(0xFF080C12);
  static const deepNavy    = Color(0xFF0D1420);
  static const card        = Color(0xFF111827);
  static const cardBorder  = Color(0xFF1E2D45);
  static const chrome      = Color(0xFFB8C8DC);
  static const chromeDim   = Color(0xFF6B8099);
  static const electric    = Color(0xFF00A8FF);
  static const textPrim    = Color(0xFFEDF2F8);
  static const textSec     = Color(0xFF7A90A8);
  static const border      = Color(0xFF1E2D45);
  static const error       = Color(0xFFFF4D6A);
  static const success     = Color(0xFF00D4AA);
}

// ═══════════════════════════════════════════════════════════════════
// LOGIN PAGE
// ═══════════════════════════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  final _authApi            = AuthApi();
  final _socialAuthApi      = SocialAuthApi();
  final _googleSignIn       = GoogleSignIn(scopes: ['email', 'profile', 'openid']);

  bool _isLoading       = false;
  bool _obscurePassword = true;

  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authApi.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final authentication = await googleUser.authentication;
      final idToken        = authentication.idToken;
      final accessToken    = authentication.accessToken;

      final data    = await _socialAuthApi.googleLogin(
          idToken: idToken, accessToken: accessToken);
      final access  = data['access']  as String?;
      final refresh = data['refresh'] as String?;

      if (access == null  || access.isEmpty ||
          refresh == null || refresh.isEmpty) {
        throw Exception('Missing tokens in response.');
      }

      await TokenStore.instance.saveTokens(access: access, refresh: refresh);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      final lower   = message.toLowerCase();
      if (lower.contains('401') ||
          lower.contains('unauthorized') ||
          lower.contains('expired')) {
        await TokenStore.instance.clearTokens();
      }
      if (!mounted) return;
      _showSnack(message.isEmpty ? 'Google login failed.' : message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: _C.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(color: _C.textPrim))),
      ]),
      backgroundColor: _C.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _C.error, width: 1)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      body: Stack(children: [
        Positioned.fill(child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) =>
              CustomPaint(painter: _HexGridPainter(_pulseAnim.value)),
        )),
        _halo(top: -130, right: -90, size: 340,
            color: _C.electric.withOpacity(0.10)),
        _halo(bottom: -100, left: -70, size: 280,
            color: _C.chrome.withOpacity(0.06)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _GlassesLogo(),
                          const SizedBox(height: 36),

                          _AuthCard(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(children: [
                                _LockIcon(),
                                SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Connexion sécurisée',
                                        style: TextStyle(fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: _C.textPrim,
                                            letterSpacing: 0.2)),
                                    SizedBox(height: 3),
                                    Text('Accédez à votre espace VTON',
                                        style: TextStyle(fontSize: 12,
                                            color: _C.textSec,
                                            letterSpacing: 0.3)),
                                  ],
                                ),
                              ]),

                              const SizedBox(height: 26),
                              const _HorizDivider(),
                              const SizedBox(height: 24),

                              _OpticalField(
                                controller: _usernameController,
                                label: 'IDENTIFIANT',
                                hint: 'Nom d\'utilisateur',
                                icon: Icons.fingerprint,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Enter your username' : null,
                              ),
                              const SizedBox(height: 16),

                              _OpticalField(
                                controller: _passwordController,
                                label: 'MOT DE PASSE',
                                hint: '••••••••••',
                                icon: Icons.shield_outlined,
                                obscureText: _obscurePassword,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _C.chromeDim, size: 18),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter your password' : null,
                              ),

                              const SizedBox(height: 8),

                              // ✅ FIXED: was onPressed: () {} — now navigates to ForgotPasswordPage
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ForgotPasswordPage(),
                                            ),
                                          ),
                                  style: TextButton.styleFrom(
                                      foregroundColor: _C.electric,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      textStyle: const TextStyle(
                                          fontSize: 12, letterSpacing: 0.4)),
                                  child: const Text('Mot de passe oublié ?'),
                                ),
                              ),

                              const SizedBox(height: 16),

                              _ChromeButton(
                                label: 'LOGIN',
                                isLoading: _isLoading,
                                onTap: _isLoading ? null : _submit,
                              ),

                              const SizedBox(height: 16),

                              _GoogleButton(
                                isLoading: _isLoading,
                                onTap: _isLoading ? null : _handleGoogleLogin,
                              ),
                            ],
                          )),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => const RegisterPage()),
                                    ),
                            style: TextButton.styleFrom(
                                foregroundColor: _C.electric),
                            child: RichText(
                              text: const TextSpan(children: [
                                TextSpan(
                                    text: 'Pas encore de compte ? ',
                                    style: TextStyle(
                                        color: _C.textSec, fontSize: 13)),
                                TextSpan(
                                    text: 'Create an account',
                                    style: TextStyle(
                                        color: _C.electric,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3)),
                              ]),
                            ),
                          ),

                          const SizedBox(height: 12),
                          const _Footer(
                              label: 'Connexion chiffrée SSL · VTON 2026'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ═══════════════════════════════════════════════════════════════════

Widget _halo({double? top, double? bottom, double? left, double? right,
    required double size, required Color color}) {
  return Positioned(
    top: top, bottom: bottom, left: left, right: right,
    child: Container(width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    ),
  );
}

class _GlassesLogo extends StatelessWidget {
  const _GlassesLogo();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(width: 130, height: 58,
          child: CustomPaint(painter: _GlassesPainter())),
      const SizedBox(height: 14),
      const Text('VTON GLASSES',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
              color: _C.textPrim, letterSpacing: 6)),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 28, height: 1,
          decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Colors.transparent, _C.electric]))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('3D VIRTUAL TRY-ON',
              style: TextStyle(fontSize: 10, color: _C.electric,
                  letterSpacing: 3, fontWeight: FontWeight.w600)),
        ),
        Container(width: 28, height: 1,
          decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [_C.electric, Colors.transparent]))),
      ]),
    ]);
  }
}

class _GlassesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final fp = Paint()
      ..shader = const LinearGradient(
        colors: [_C.chrome, _C.electric, _C.chrome],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 ..strokeCap = StrokeCap.round;

    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(2, h * .12, w * .40, h * .70),
        const Radius.circular(11)), fp);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .58, h * .12, w * .40, h * .70),
        const Radius.circular(11)), fp);

    final rp = Paint()
      ..color = _C.electric.withOpacity(0.22) ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(7, h * .17, w * .11, h * .14),
        const Radius.circular(4)), rp);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .62, h * .17, w * .11, h * .14),
        const Radius.circular(4)), rp);

    canvas.drawPath(
      Path()..moveTo(w*.42,h*.34)..cubicTo(w*.46,h*.20,w*.54,h*.20,w*.58,h*.34),
      Paint()..color=_C.chrome..style=PaintingStyle.stroke
        ..strokeWidth=2.2..strokeCap=StrokeCap.round);

    final bp = Paint()..color=_C.chromeDim..style=PaintingStyle.stroke
      ..strokeWidth=2.0..strokeCap=StrokeCap.round;
    canvas.drawLine(const Offset(2,0), Offset(2,h*.12), bp);
    canvas.drawLine(Offset(w-2,0), Offset(w-2,h*.12), bp);

    canvas.drawCircle(Offset(w/2,h*.47), 5, Paint()
      ..shader=RadialGradient(colors:[_C.electric.withOpacity(0.6),Colors.transparent])
        .createShader(Rect.fromCenter(center:Offset(w/2,h*.47),width:18,height:18))
      ..style=PaintingStyle.fill);
    canvas.drawCircle(Offset(w/2,h*.47),2,Paint()..color=_C.electric);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LockIcon extends StatelessWidget {
  const _LockIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2840), Color(0xFF0D1828)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: _C.electric.withOpacity(0.40), width: 1),
        boxShadow: [
          BoxShadow(color: _C.electric.withOpacity(0.18),
              blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: _C.electric.withOpacity(0.08),
              blurRadius: 1, spreadRadius: 1),
        ],
      ),
      child: CustomPaint(painter: _LockPainter(), size: const Size(50, 50)),
    );
  }
}

class _LockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2 + 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx-9,cy,18,13),const Radius.circular(4)),
      Paint()..shader=const LinearGradient(colors:[_C.chrome,_C.electric],
          begin:Alignment.topCenter,end:Alignment.bottomCenter)
        .createShader(Rect.fromLTWH(cx-9,cy,18,13))..style=PaintingStyle.fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx-9,cy,18,2),const Radius.circular(4)),
      Paint()..color=Colors.white.withOpacity(0.2));

    final arch = Path()
      ..moveTo(cx-5.5,cy+.5)..lineTo(cx-5.5,cy-6.5)
      ..arcToPoint(Offset(cx+5.5,cy-6.5),
          radius:const Radius.circular(5.5),clockwise:false)
      ..lineTo(cx+5.5,cy+.5);
    canvas.drawPath(arch, Paint()..color=_C.electric.withOpacity(0.3)
      ..style=PaintingStyle.stroke..strokeWidth=4..strokeCap=StrokeCap.round
      ..maskFilter=const MaskFilter.blur(BlurStyle.normal,3));
    canvas.drawPath(arch, Paint()..color=_C.chrome..style=PaintingStyle.stroke
      ..strokeWidth=2.5..strokeCap=StrokeCap.round);
    canvas.drawCircle(Offset(cx,cy+5.5),2.6,Paint()..color=_C.obsidian);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx-1.3,cy+7,2.6,3.5),const Radius.circular(1)),
        Paint()..color=_C.obsidian);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _OpticalField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _OpticalField({
    required this.controller, required this.label, required this.hint,
    required this.icon, this.obscureText = false, this.suffixIcon,
    this.keyboardType, this.onChanged, this.validator,
  });
  @override State<_OpticalField> createState() => _OpticalFieldState();
}

class _OpticalFieldState extends State<_OpticalField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 7),
        child: Text(widget.label,
          style: TextStyle(fontSize: 10, letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              color: _focused ? _C.electric : _C.textSec)),
      ),
      Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
            boxShadow: _focused ? [BoxShadow(
                color: _C.electric.withOpacity(0.18), blurRadius: 16,
                spreadRadius: 2)] : []),
          child: TextFormField(
            controller: widget.controller, obscureText: widget.obscureText,
            keyboardType: widget.keyboardType, onChanged: widget.onChanged,
            validator: widget.validator, cursorColor: _C.electric,
            style: const TextStyle(color: _C.textPrim, fontSize: 14,
                letterSpacing: 0.3),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color(0xFF3A4A5A), fontSize: 14),
              prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(widget.icon,
                    color: _focused ? _C.electric : _C.chromeDim, size: 19)),
              suffixIcon: widget.suffixIcon != null
                  ? Padding(padding: const EdgeInsets.only(right: 14),
                      child: widget.suffixIcon)
                  : null,
              filled: true, fillColor: _C.deepNavy,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.border, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.electric, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.error)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.error, width: 1.5)),
              errorStyle: const TextStyle(
                  color: _C.error, fontSize: 11, letterSpacing: 0.3),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ChromeButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  const _ChromeButton({required this.label, required this.isLoading, this.onTap});
  @override State<_ChromeButton> createState() => _ChromeButtonState();
}
class _ChromeButtonState extends State<_ChromeButton> {
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
            gradient: LinearGradient(
              colors: widget.onTap == null
                  ? [_C.chromeDim, _C.chromeDim]
                  : const [Color(0xFF0078CC), _C.electric, Color(0xFF00C8FF)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onTap == null ? [] : [
              BoxShadow(
                  color: _C.electric.withOpacity(_pressed ? 0.2 : 0.40),
                  blurRadius: _pressed ? 10 : 24, offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 0, left: 16, right: 16,
              child: Container(height: 1,
                decoration: const BoxDecoration(gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.white24,
                      Colors.transparent])))),
            if (widget.isLoading)
              const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white)))
            else
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_open_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 10),
                Text(widget.label,
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w800, letterSpacing: 2)),
              ]),
          ]),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _GoogleButton({required this.isLoading, this.onTap});
  @override State<_GoogleButton> createState() => _GoogleButtonState();
}
class _GoogleButtonState extends State<_GoogleButton> {
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
            color: const Color(0xFF0D1420),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed ? _C.electric.withOpacity(0.7) : _C.border,
              width: 1.5,
            ),
            boxShadow: _pressed ? [
              BoxShadow(color: _C.electric.withOpacity(0.10),
                  blurRadius: 12, offset: const Offset(0, 4)),
            ] : [],
          ),
          child: widget.isLoading
              ? const Center(child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(_C.electric))))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CustomPaint(
                      painter: _GoogleLogoPainter(),
                      size: const Size(20, 20)),
                  const SizedBox(width: 12),
                  const Text('Continue with Google',
                      style: TextStyle(color: _C.textPrim, fontSize: 13,
                          fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                ]),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2; final r = size.width / 2;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi * 0.15, pi * 0.65, false,
        Paint()..color = const Color(0xFFEA4335)
          ..style = PaintingStyle.stroke ..strokeWidth = r * 0.38);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        pi * 0.50, pi * 0.52, false,
        Paint()..color = const Color(0xFF34A853)
          ..style = PaintingStyle.stroke ..strokeWidth = r * 0.38);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        pi * 1.02, pi * 0.42, false,
        Paint()..color = const Color(0xFFFBBC05)
          ..style = PaintingStyle.stroke ..strokeWidth = r * 0.38);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        pi * 1.44, pi * 0.41, false,
        Paint()..color = const Color(0xFF4285F4)
          ..style = PaintingStyle.stroke ..strokeWidth = r * 0.38);
    canvas.drawRect(
        Rect.fromLTWH(cx, cy - r * 0.18, r * 0.92, r * 0.36),
        Paint()..color = const Color(0xFF4285F4) ..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AuthCard extends StatelessWidget {
  final Widget child;
  const _AuthCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.card, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.55),
              blurRadius: 60, offset: const Offset(0, 24)),
          BoxShadow(color: _C.electric.withOpacity(0.04),
              blurRadius: 1, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

class _HorizDivider extends StatelessWidget {
  const _HorizDivider();
  @override
  Widget build(BuildContext context) => Container(height: 1,
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [
      Colors.transparent, _C.cardBorder, Colors.transparent])));
}

class _Footer extends StatelessWidget {
  final String label;
  const _Footer({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 6, height: 6,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: _C.success)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(
          color: _C.border, fontSize: 10, letterSpacing: 1)),
    ]);
  }
}

class _HexGridPainter extends CustomPainter {
  final double opacity;
  const _HexGridPainter(this.opacity);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _C.electric.withOpacity(0.022 * opacity)
      ..style = PaintingStyle.stroke ..strokeWidth = 0.6;
    const r = 36.0; const dx = r * 1.732; const dy = r * 1.5;
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
        path.close(); canvas.drawPath(path, p);
      }
      row++;
    }
  }
  @override bool shouldRepaint(_HexGridPainter old) => old.opacity != opacity;
}