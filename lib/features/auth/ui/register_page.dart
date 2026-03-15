import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/token_store.dart';
import '../../glasses/ui/home_page.dart';
import '../data/auth_api.dart';
import '../data/social_auth_api.dart';
import 'login_page.dart';

// ═══════════════════════════════════════════════════════════════════
// REGISTER PAGE  —  logique backend 100 % originale
// ═══════════════════════════════════════════════════════════════════
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  // ── Contrôleurs originaux ──────────────────────────────────────
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  final _authApi            = AuthApi();
  final _socialAuthApi      = SocialAuthApi();
  final _googleSignIn       = GoogleSignIn(scopes: ['email', 'profile', 'openid']);

  bool _isLoading       = false;
  bool _obscurePassword = true;
  bool _agreedToTerms   = false;

  // ── Animations ─────────────────────────────────────────────────
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

  // ── dispose original ───────────────────────────────────────────
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _strength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    if (p.length < 6) return 1;
    if (p.length < 10) return 2;
    return 3;
  }
  Color get _strengthColor => const [Colors.transparent,
    Color(0xFFFF4D6A), Color(0xFFF59E0B), Color(0xFF00D4AA)][_strength];
  String get _strengthLabel =>
      ['', 'Faible', 'Moyen', 'Fort'][_strength];

  // ── _submit original ───────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authApi.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
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

  // ── _handleGoogleRegister original ────────────────────────────
  Future<void> _handleGoogleRegister() async {
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
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFFF4D6A), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(color: Color(0xFFEDF2F8)))),
      ]),
      backgroundColor: const Color(0xFF111827),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFF4D6A), width: 1)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C12),
      body: Stack(children: [
        // Grille hexagonale
        Positioned.fill(child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) =>
              CustomPaint(painter: _HexGridPainter(_pulseAnim.value)),
        )),
        // Halos
        Positioned(top: -130, left: -90,
          child: Container(width: 340, height: 340,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00A8FF).withOpacity(0.09), Colors.transparent,
              ])),
          ),
        ),
        Positioned(bottom: -100, right: -60,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFB8C8DC).withOpacity(0.05), Colors.transparent,
              ])),
          ),
        ),

        // Contenu
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
                          // Logo
                          const _GlassesLogo(),
                          const SizedBox(height: 36),

                          // Card
                          _AuthCard(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header shield vert
                              Row(children: [
                                _ShieldIcon(),
                                const SizedBox(width: 14),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Créer un compte',
                                        style: TextStyle(fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFEDF2F8),
                                            letterSpacing: 0.2)),
                                    SizedBox(height: 3),
                                    Text('Rejoignez l\'expérience VTON 3D',
                                        style: TextStyle(fontSize: 12,
                                            color: Color(0xFF7A90A8),
                                            letterSpacing: 0.3)),
                                  ],
                                ),
                              ]),

                              const SizedBox(height: 26),
                              const _HorizDivider(),
                              const SizedBox(height: 24),

                              // Champ username
                              _OpticalField(
                                controller: _usernameController,
                                label: 'IDENTIFIANT',
                                hint: 'Choisissez un pseudo',
                                icon: Icons.person_outline_rounded,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Enter a username' : null,
                              ),
                              const SizedBox(height: 16),

                              // Champ email
                              _OpticalField(
                                controller: _emailController,
                                label: 'ADRESSE E-MAIL',
                                hint: 'vous@exemple.com',
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Champ password
                              _OpticalField(
                                controller: _passwordController,
                                label: 'MOT DE PASSE',
                                hint: '••••••••••',
                                icon: Icons.shield_outlined,
                                obscureText: _obscurePassword,
                                onChanged: (_) => setState(() {}),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF6B8099), size: 18),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Enter a password';
                                  }
                                  if (v.length < 6) {
                                    return 'Use at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              // Barre de force
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _StrengthBar(strength: _strength,
                                    color: _strengthColor,
                                    label: _strengthLabel),
                              ],

                              const SizedBox(height: 18),

                              // Checkbox CGU
                              _TermsRow(
                                value: _agreedToTerms,
                                onChanged: (v) =>
                                    setState(() => _agreedToTerms = v ?? false),
                              ),
                              const SizedBox(height: 20),

                              // ── Bouton Register ───────────────
                              _ChromeButton(
                                label: 'REGISTER',
                                isLoading: _isLoading,
                                onTap: _isLoading ? null : _submit,
                              ),
                              const SizedBox(height: 16),

                              // ── Bouton Google (original) ──────
                              _GoogleButton(
                                isLoading: _isLoading,
                                onTap: _isLoading
                                    ? null
                                    : _handleGoogleRegister,
                              ),
                            ],
                          )),

                          const SizedBox(height: 20),

                          // "Already have an account? Login"
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (_) => const LoginPage())),
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00A8FF)),
                            child: RichText(
                              text: const TextSpan(children: [
                                TextSpan(
                                    text: 'Déjà un compte ? ',
                                    style: TextStyle(
                                        color: Color(0xFF7A90A8),
                                        fontSize: 13)),
                                TextSpan(
                                    text: 'Already have an account? Login',
                                    style: TextStyle(
                                        color: Color(0xFF00A8FF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3)),
                              ]),
                            ),
                          ),

                          const SizedBox(height: 12),
                          const _Footer(
                              label: 'Données sécurisées · VTON 2026'),
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
// WIDGETS LOCAUX REGISTER
// ═══════════════════════════════════════════════════════════════════

class _ShieldIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2840), Color(0xFF0D1828)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(
            color: const Color(0xFF00D4AA).withOpacity(0.4), width: 1),
        boxShadow: [BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.15),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: const Icon(Icons.verified_user_outlined,
          color: Color(0xFF00D4AA), size: 24),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final int strength; final Color color; final String label;
  const _StrengthBar({required this.strength, required this.color,
      required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(3, (i) => Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 3,
          margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
          decoration: BoxDecoration(
            color: strength > i ? color : const Color(0xFF1E2D45),
            borderRadius: BorderRadius.circular(2)),
        ),
      ))),
      const SizedBox(height: 5),
      Row(children: [
        Text(label, style: TextStyle(color: color, fontSize: 10,
            letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const Spacer(),
        const Text('Sécurité du mot de passe',
            style: TextStyle(color: Color(0xFF7A90A8), fontSize: 10)),
      ]),
    ]);
  }
}

class _TermsRow extends StatelessWidget {
  final bool value; final ValueChanged<bool?> onChanged;
  const _TermsRow({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            gradient: value ? const LinearGradient(
              colors: [Color(0xFF00A8FF), Color(0xFF0070B8)],
              begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            color: value ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: value ? const Color(0xFF00A8FF) : const Color(0xFF1E2D45),
              width: 1.5),
          ),
          child: value ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text.rich(TextSpan(
        style: const TextStyle(color: Color(0xFF7A90A8), fontSize: 12, height: 1.6),
        children: [
          const TextSpan(text: 'J\'accepte les '),
          TextSpan(text: 'conditions d\'utilisation',
            style: const TextStyle(color: Color(0xFF00A8FF),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF00A8FF))),
          const TextSpan(text: ' et la '),
          TextSpan(text: 'politique de confidentialité',
            style: const TextStyle(color: Color(0xFF00A8FF),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF00A8FF))),
        ],
      ))),
    ]);
  }
}

// ── Copies des widgets partagés ───────────────────────────────────
// (À centraliser dans lib/auth/ui/shared/vton_widgets.dart)

class _GlassesLogo extends StatelessWidget {
  const _GlassesLogo();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(width: 130, height: 58,
          child: CustomPaint(painter: _GlassesPainter())),
      const SizedBox(height: 14),
      const Text('VTON GLASSES', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
              color: Color(0xFFEDF2F8), letterSpacing: 6)),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 28, height: 1, decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFF00A8FF)]))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('3D VIRTUAL TRY-ON', style: TextStyle(fontSize: 10,
              color: Color(0xFF00A8FF), letterSpacing: 3,
              fontWeight: FontWeight.w600))),
        Container(width: 28, height: 1, decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF00A8FF), Colors.transparent]))),
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
        colors: [Color(0xFFB8C8DC), Color(0xFF00A8FF), Color(0xFFB8C8DC)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(2,h*.12,w*.40,h*.70),const Radius.circular(11)),fp);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w*.58,h*.12,w*.40,h*.70),const Radius.circular(11)),fp);
    final rp = Paint()..color=const Color(0xFF00A8FF).withOpacity(0.22)
      ..style=PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(7,h*.17,w*.11,h*.14),const Radius.circular(4)),rp);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w*.62,h*.17,w*.11,h*.14),const Radius.circular(4)),rp);
    canvas.drawPath(
      Path()..moveTo(w*.42,h*.34)..cubicTo(w*.46,h*.20,w*.54,h*.20,w*.58,h*.34),
      Paint()..color=const Color(0xFFB8C8DC)..style=PaintingStyle.stroke
        ..strokeWidth=2.2..strokeCap=StrokeCap.round);
    final bp = Paint()..color=const Color(0xFF6B8099)..style=PaintingStyle.stroke
      ..strokeWidth=2.0..strokeCap=StrokeCap.round;
    canvas.drawLine(const Offset(2,0),Offset(2,h*.12),bp);
    canvas.drawLine(Offset(w-2,0),Offset(w-2,h*.12),bp);
    canvas.drawCircle(Offset(w/2,h*.47),5,Paint()
      ..shader=RadialGradient(colors:[const Color(0xFF00A8FF).withOpacity(0.6),
        Colors.transparent]).createShader(Rect.fromCenter(
          center:Offset(w/2,h*.47),width:18,height:18))
      ..style=PaintingStyle.fill);
    canvas.drawCircle(Offset(w/2,h*.47),2,
        Paint()..color=const Color(0xFF00A8FF));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _OpticalField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint; final IconData icon;
  final bool obscureText; final Widget? suffixIcon;
  final TextInputType? keyboardType; final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  const _OpticalField({required this.controller, required this.label,
    required this.hint, required this.icon, this.obscureText = false,
    this.suffixIcon, this.keyboardType, this.onChanged, this.validator});
  @override State<_OpticalField> createState() => _OpticalFieldState();
}
class _OpticalFieldState extends State<_OpticalField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 7),
        child: Text(widget.label, style: TextStyle(fontSize: 10,
            letterSpacing: 2.5, fontWeight: FontWeight.w700,
            color: _focused ? const Color(0xFF00A8FF) : const Color(0xFF7A90A8)))),
      Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
            boxShadow: _focused ? [BoxShadow(
                color: const Color(0xFF00A8FF).withOpacity(0.18),
                blurRadius: 16, spreadRadius: 2)] : []),
          child: TextFormField(
            controller: widget.controller, obscureText: widget.obscureText,
            keyboardType: widget.keyboardType, onChanged: widget.onChanged,
            validator: widget.validator, cursorColor: const Color(0xFF00A8FF),
            style: const TextStyle(color: Color(0xFFEDF2F8), fontSize: 14,
                letterSpacing: 0.3),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color(0xFF3A4A5A), fontSize: 14),
              prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(widget.icon,
                    color: _focused ? const Color(0xFF00A8FF) : const Color(0xFF6B8099),
                    size: 19)),
              suffixIcon: widget.suffixIcon != null
                  ? Padding(padding: const EdgeInsets.only(right: 14),
                      child: widget.suffixIcon) : null,
              filled: true, fillColor: const Color(0xFF0D1420),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00A8FF), width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFF4D6A))),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFF4D6A), width: 1.5)),
              errorStyle: const TextStyle(color: Color(0xFFFF4D6A), fontSize: 11,
                  letterSpacing: 0.3),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ChromeButton extends StatefulWidget {
  final String label; final bool isLoading; final VoidCallback? onTap;
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
          duration: const Duration(milliseconds: 200), height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.onTap == null
                  ? [const Color(0xFF6B8099), const Color(0xFF6B8099)]
                  : const [Color(0xFF0078CC), Color(0xFF00A8FF), Color(0xFF00C8FF)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onTap == null ? [] : [BoxShadow(
                color: const Color(0xFF00A8FF).withOpacity(_pressed ? 0.2 : 0.40),
                blurRadius: _pressed ? 10 : 24, offset: const Offset(0, 6))]),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 0, left: 16, right: 16,
              child: Container(height: 1, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent,
                  Colors.white24, Colors.transparent])))),
            if (widget.isLoading)
              const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white)))
            else
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_open_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 10),
                Text(widget.label, style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ]),
          ]),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatefulWidget {
  final bool isLoading; final VoidCallback? onTap;
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
          duration: const Duration(milliseconds: 200), height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1420),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed
                  ? const Color(0xFF00A8FF).withOpacity(0.7)
                  : const Color(0xFF1E2D45),
              width: 1.5),
            boxShadow: _pressed ? [BoxShadow(
                color: const Color(0xFF00A8FF).withOpacity(0.10),
                blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: widget.isLoading
              ? const Center(child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00A8FF)))))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CustomPaint(painter: _GoogleLogoPainter(),
                      size: const Size(20, 20)),
                  const SizedBox(width: 12),
                  const Text('Continue with Google',
                      style: TextStyle(color: Color(0xFFEDF2F8), fontSize: 13,
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
    final cx = size.width/2; final cy = size.height/2; final r = size.width/2;
    canvas.drawCircle(Offset(cx,cy),r,Paint()..color=Colors.white);
    canvas.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r),
        -pi*0.15,pi*0.65,false,
        Paint()..color=const Color(0xFFEA4335)..style=PaintingStyle.stroke..strokeWidth=r*0.38);
    canvas.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r),
        pi*0.50,pi*0.52,false,
        Paint()..color=const Color(0xFF34A853)..style=PaintingStyle.stroke..strokeWidth=r*0.38);
    canvas.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r),
        pi*1.02,pi*0.42,false,
        Paint()..color=const Color(0xFFFBBC05)..style=PaintingStyle.stroke..strokeWidth=r*0.38);
    canvas.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r),
        pi*1.44,pi*0.41,false,
        Paint()..color=const Color(0xFF4285F4)..style=PaintingStyle.stroke..strokeWidth=r*0.38);
    canvas.drawRect(Rect.fromLTWH(cx,cy-r*0.18,r*0.92,r*0.36),
        Paint()..color=const Color(0xFF4285F4)..style=PaintingStyle.fill);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AuthCard extends StatelessWidget {
  final Widget child; const _AuthCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFF111827), borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF1E2D45), width: 1),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.55),
            blurRadius: 60, offset: const Offset(0, 24)),
        BoxShadow(color: const Color(0xFF00A8FF).withOpacity(0.04),
            blurRadius: 1, spreadRadius: 1),
      ]),
    child: child);
}

class _HorizDivider extends StatelessWidget {
  const _HorizDivider();
  @override
  Widget build(BuildContext context) => Container(height: 1,
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [
      Colors.transparent, Color(0xFF1E2D45), Colors.transparent])));
}

class _Footer extends StatelessWidget {
  final String label; const _Footer({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 6, height: 6, decoration: const BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFF00D4AA))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(
          color: Color(0xFF1E2D45), fontSize: 10, letterSpacing: 1)),
    ]);
  }
}

class _HexGridPainter extends CustomPainter {
  final double opacity; const _HexGridPainter(this.opacity);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF00A8FF).withOpacity(0.022 * opacity)
      ..style = PaintingStyle.stroke ..strokeWidth = 0.6;
    const r = 36.0; const dx = r * 1.732; const dy = r * 1.5;
    int row = 0;
    for (double y = -r; y < size.height + r; y += dy) {
      final off = (row % 2 == 0) ? 0.0 : dx / 2;
      for (double x = -r + off; x < size.width + r; x += dx) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (pi/180)*(60*i-30);
          final pt = Offset(x+r*cos(a), y+r*sin(a));
          i==0 ? path.moveTo(pt.dx,pt.dy) : path.lineTo(pt.dx,pt.dy);
        }
        path.close(); canvas.drawPath(path, p);
      }
      row++;
    }
  }
  @override bool shouldRepaint(_HexGridPainter old) => old.opacity != opacity;
}