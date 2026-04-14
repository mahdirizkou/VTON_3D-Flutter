import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_api.dart';
import 'login_page.dart';

// ═══════════════════════════════════════════════════════════════════
// PALETTE — identical to login_page.dart
// ═══════════════════════════════════════════════════════════════════
class _C {
  static const obsidian   = Color(0xFF080C12);
  static const deepNavy   = Color(0xFF0D1420);
  static const card       = Color(0xFF111827);
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
// STEP 1 — ForgotPasswordPage  (enter email)
// ═══════════════════════════════════════════════════════════════════
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  final _authApi   = AuthApi();
  bool _isLoading  = false;

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
    _emailCtrl.dispose();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authApi.forgotPassword(email: _emailCtrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VerifyCodePage(email: _emailCtrl.text.trim()),
      ));
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isSuccess ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          color: isSuccess ? _C.success : _C.error, size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: _C.textPrim))),
      ]),
      backgroundColor: _C.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSuccess ? _C.success : _C.error, width: 1)),
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
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _C.chromeDim, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                              Center(
                                child: Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1A2840), Color(0xFF0D1828)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                        color: _C.electric.withOpacity(0.40),
                                        width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                          color: _C.electric.withOpacity(0.20),
                                          blurRadius: 30,
                                          offset: const Offset(0, 8)),
                                    ],
                                  ),
                                  child: const Icon(
                                      Icons.mark_email_unread_outlined,
                                      color: _C.electric, size: 36),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text('Mot de passe oublié ?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _C.textPrim,
                                      letterSpacing: 0.2)),
                              const SizedBox(height: 10),
                              const Text(
                                'Entrez votre adresse e-mail.\nNous vous enverrons un code à 6 chiffres.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _C.textSec,
                                    height: 1.6),
                              ),
                              const SizedBox(height: 28),

                              _AuthCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _CardHeader(
                                      icon: Icons.alternate_email_rounded,
                                      title: 'Adresse e-mail',
                                      subtitle:
                                          'Associée à votre compte VTON',
                                    ),
                                    const SizedBox(height: 20),
                                    const _HorizDivider(),
                                    const SizedBox(height: 20),
                                    _OpticalField(
                                      controller: _emailCtrl,
                                      label: 'E-MAIL',
                                      hint: 'votre@email.com',
                                      icon: Icons.alternate_email_rounded,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Entrez votre e-mail';
                                        }
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                            .hasMatch(v.trim())) {
                                          return 'E-mail invalide';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 22),
                                    _ChromeButton(
                                      label: 'ENVOYER LE CODE',
                                      icon: Icons.send_rounded,
                                      isLoading: _isLoading,
                                      onTap: _isLoading ? null : _submit,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),
                              Center(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                      foregroundColor: _C.electric),
                                  child: const Text('Retour à la connexion',
                                      style: TextStyle(
                                          color: _C.electric,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const _Footer(
                                  label:
                                      'Code valable 10 minutes · VTON 2026'),
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
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STEP 2 — VerifyCodePage  (6-digit OTP boxes)
// ═══════════════════════════════════════════════════════════════════
class VerifyCodePage extends StatefulWidget {
  final String email;
  const VerifyCodePage({super.key, required this.email});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _digitCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  final _authApi    = AuthApi();
  bool _isLoading   = false;
  bool _isResending = false;

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
    for (final c in _digitCtrl) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _code => _digitCtrl.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) {
      _showSnack('Veuillez entrer le code complet à 6 chiffres.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authApi.verifyResetCode(email: widget.email, code: _code);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ResetPasswordPage(email: widget.email, code: _code),
      ));
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await _authApi.forgotPassword(email: widget.email);
      for (final c in _digitCtrl) c.clear();
      _focusNodes[0].requestFocus();
      if (!mounted) return;
      _showSnack('Nouveau code envoyé !', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isSuccess
              ? Icons.check_circle_outline
              : Icons.warning_amber_rounded,
          color: isSuccess ? _C.success : _C.error,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg, style: const TextStyle(color: _C.textPrim))),
      ]),
      backgroundColor: _C.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: isSuccess ? _C.success : _C.error, width: 1)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final codeComplete = _code.length == 6;

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
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _C.chromeDim, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1A2840),
                                      Color(0xFF0D1828)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                      color: _C.electric.withOpacity(0.40),
                                      width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            _C.electric.withOpacity(0.20),
                                        blurRadius: 30,
                                        offset: const Offset(0, 8)),
                                  ],
                                ),
                                child: const Icon(Icons.key_rounded,
                                    color: _C.electric, size: 36),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text('Vérification',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _C.textPrim,
                                    letterSpacing: 0.2)),
                            const SizedBox(height: 10),
                            Text(
                              'Code envoyé à\n${widget.email}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: _C.textSec,
                                  height: 1.6),
                            ),
                            const SizedBox(height: 28),

                            _AuthCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _CardHeader(
                                    icon: Icons.dialpad_rounded,
                                    title: 'Code OTP',
                                    subtitle: 'Valable 10 minutes',
                                  ),
                                  const SizedBox(height: 20),
                                  const _HorizDivider(),
                                  const SizedBox(height: 24),

                                  // 6 digit boxes
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: List.generate(6, (i) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left:  i == 3 ? 14 : 0,
                                          right: i < 5  ? 8  : 0,
                                        ),
                                        child: _DigitBox(
                                          controller: _digitCtrl[i],
                                          focusNode: _focusNodes[i],
                                          onChanged: (val) {
                                            if (val.length == 1 &&
                                                i < 5) {
                                              _focusNodes[i + 1]
                                                  .requestFocus();
                                            } else if (val.isEmpty &&
                                                i > 0) {
                                              _focusNodes[i - 1]
                                                  .requestFocus();
                                            }
                                            setState(() {});
                                          },
                                        ),
                                      );
                                    }),
                                  ),

                                  const SizedBox(height: 26),
                                  _ChromeButton(
                                    label: 'VÉRIFIER LE CODE',
                                    icon: Icons.verified_outlined,
                                    isLoading: _isLoading,
                                    onTap: (_isLoading || !codeComplete)
                                        ? null
                                        : _verify,
                                  ),
                                  const SizedBox(height: 14),

                                  Center(
                                    child: TextButton(
                                      onPressed:
                                          _isResending ? null : _resend,
                                      style: TextButton.styleFrom(
                                          foregroundColor: _C.electric),
                                      child: _isResending
                                          ? const SizedBox(
                                              width: 18, height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                              _C.electric)))
                                          : const Text('Renvoyer le code',
                                              style: TextStyle(
                                                  color: _C.electric,
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            const _Footer(
                                label: 'Code OTP sécurisé · VTON 2026'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STEP 3 — ResetPasswordPage  (new password + confirm)
// ═══════════════════════════════════════════════════════════════════
class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;
  const ResetPasswordPage(
      {super.key, required this.email, required this.code});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with TickerProviderStateMixin {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  final _authApi      = AuthApi();
  bool _isLoading   = false;
  bool _obscurePass = true;
  bool _obscureConf = true;

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
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authApi.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordCtrl.text,
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          onDone: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: _C.error, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg, style: const TextStyle(color: _C.textPrim))),
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
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _C.chromeDim, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                              Center(
                                child: Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0D2818),
                                        Color(0xFF081410)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                        color:
                                            _C.success.withOpacity(0.40),
                                        width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              _C.success.withOpacity(0.20),
                                          blurRadius: 30,
                                          offset: const Offset(0, 8)),
                                    ],
                                  ),
                                  child: const Icon(
                                      Icons.lock_reset_rounded,
                                      color: _C.success, size: 36),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text('Nouveau mot de passe',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _C.textPrim,
                                      letterSpacing: 0.2)),
                              const SizedBox(height: 10),
                              const Text(
                                'Choisissez un mot de passe fort\nd\'au moins 8 caractères.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _C.textSec,
                                    height: 1.6),
                              ),
                              const SizedBox(height: 28),

                              _AuthCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _CardHeader(
                                      icon: Icons.shield_outlined,
                                      title: 'Sécurité du compte',
                                      subtitle:
                                          'Définissez votre nouveau mot de passe',
                                      successTint: true,
                                    ),
                                    const SizedBox(height: 20),
                                    const _HorizDivider(),
                                    const SizedBox(height: 20),

                                    _OpticalField(
                                      controller: _passwordCtrl,
                                      label: 'NOUVEAU MOT DE PASSE',
                                      hint: '••••••••••',
                                      icon: Icons.shield_outlined,
                                      obscureText: _obscurePass,
                                      suffixIcon: GestureDetector(
                                        onTap: () => setState(() =>
                                            _obscurePass = !_obscurePass),
                                        child: Icon(
                                          _obscurePass
                                              ? Icons.visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined,
                                          color: _C.chromeDim, size: 18),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Entrez un mot de passe';
                                        }
                                        if (v.length < 8) {
                                          return 'Au moins 8 caractères';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    _OpticalField(
                                      controller: _confirmCtrl,
                                      label: 'CONFIRMER LE MOT DE PASSE',
                                      hint: '••••••••••',
                                      icon: Icons.verified_user_outlined,
                                      obscureText: _obscureConf,
                                      suffixIcon: GestureDetector(
                                        onTap: () => setState(() =>
                                            _obscureConf = !_obscureConf),
                                        child: Icon(
                                          _obscureConf
                                              ? Icons.visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined,
                                          color: _C.chromeDim, size: 18),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Confirmez votre mot de passe';
                                        }
                                        if (v != _passwordCtrl.text) {
                                          return 'Les mots de passe ne correspondent pas';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 22),

                                    _ChromeButton(
                                      label: 'RÉINITIALISER',
                                      icon: Icons.lock_reset_rounded,
                                      isLoading: _isLoading,
                                      onTap: _isLoading ? null : _submit,
                                      successColor: true,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),
                              const _Footer(
                                  label:
                                      'Connexion chiffrée SSL · VTON 2026'),
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
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SUCCESS DIALOG
// ═══════════════════════════════════════════════════════════════════
class _SuccessDialog extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessDialog({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.success.withOpacity(0.40), width: 1),
          boxShadow: [
            BoxShadow(
                color: _C.success.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D2818), Color(0xFF081410)]),
              border:
                  Border.all(color: _C.success.withOpacity(0.5), width: 1.5),
            ),
            child: const Icon(Icons.check_rounded,
                color: _C.success, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('Mot de passe modifié !',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrim)),
          const SizedBox(height: 10),
          const Text(
            'Votre mot de passe a été réinitialisé avec succès.\nVous pouvez maintenant vous connecter.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: _C.textSec, height: 1.6),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: _ChromeButton(
              label: 'SE CONNECTER',
              icon: Icons.login_rounded,
              isLoading: false,
              onTap: onDone,
              successColor: true,
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════

Widget _halo({
  double? top, double? bottom, double? left, double? right,
  required double size, required Color color,
}) {
  return Positioned(
    top: top, bottom: bottom, left: left, right: right,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    ),
  );
}

// ── Card header row ───────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool successTint;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.successTint = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = successTint ? _C.success : _C.electric;
    return Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: successTint
                ? [const Color(0xFF0D2818), const Color(0xFF081410)]
                : [const Color(0xFF1A2840), const Color(0xFF0D1828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border:
              Border.all(color: accentColor.withOpacity(0.40), width: 1),
          boxShadow: [
            BoxShadow(
                color: accentColor.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: accentColor, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrim)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: _C.textSec, letterSpacing: 0.3)),
        ]),
      ),
    ]);
  }
}

// ── Single OTP digit box ──────────────────────────────────────────
class _DigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44, height: 54,
      decoration: BoxDecoration(
        color: _C.deepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused
              ? _C.electric
              : filled
                  ? _C.electric.withOpacity(0.45)
                  : _C.border,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: _C.electric.withOpacity(0.22),
                    blurRadius: 12,
                    spreadRadius: 1)
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        cursorColor: _C.electric,
        style: const TextStyle(
            color: _C.electric,
            fontSize: 22,
            fontWeight: FontWeight.w800),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ── OpticalField ──────────────────────────────────────────────────
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
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  @override
  State<_OpticalField> createState() => _OpticalFieldState();
}

class _OpticalFieldState extends State<_OpticalField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 7),
        child: Text(widget.label,
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
                color: _focused ? _C.electric : _C.textSec)),
      ),
      Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _focused
                ? [
                    BoxShadow(
                        color: _C.electric.withOpacity(0.18),
                        blurRadius: 16,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            validator: widget.validator,
            cursorColor: _C.electric,
            style: const TextStyle(
                color: _C.textPrim, fontSize: 14, letterSpacing: 0.3),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                  color: Color(0xFF3A4A5A), fontSize: 14),
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(widget.icon,
                    color: _focused ? _C.electric : _C.chromeDim,
                    size: 19),
              ),
              suffixIcon: widget.suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: widget.suffixIcon)
                  : null,
              filled: true,
              fillColor: _C.deepNavy,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: _C.border, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: _C.electric, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.error)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: _C.error, width: 1.5)),
              errorStyle: const TextStyle(
                  color: _C.error, fontSize: 11, letterSpacing: 0.3),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Chrome button ─────────────────────────────────────────────────
class _ChromeButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool successColor;
  final VoidCallback? onTap;

  const _ChromeButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.successColor = false,
    this.onTap,
  });

  @override
  State<_ChromeButton> createState() => _ChromeButtonState();
}

class _ChromeButtonState extends State<_ChromeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.successColor
        ? [
            const Color(0xFF008060),
            _C.success,
            const Color(0xFF00F0C0)
          ]
        : [
            const Color(0xFF0078CC),
            _C.electric,
            const Color(0xFF00C8FF)
          ];
    final glowColor = widget.successColor ? _C.success : _C.electric;

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
                  : colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onTap == null
                ? []
                : [
                    BoxShadow(
                        color: glowColor
                            .withOpacity(_pressed ? 0.20 : 0.40),
                        blurRadius: _pressed ? 10 : 24,
                        offset: const Offset(0, 6)),
                  ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(
              top: 0, left: 16, right: 16,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    Colors.white24,
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            if (widget.isLoading)
              const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation(Colors.white)),
              )
            else
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 16),
                    const SizedBox(width: 10),
                    Text(widget.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                  ]),
          ]),
        ),
      ),
    );
  }
}

// ── Auth Card ─────────────────────────────────────────────────────
class _AuthCard extends StatelessWidget {
  final Widget child;
  const _AuthCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 60,
              offset: const Offset(0, 24)),
          BoxShadow(
              color: _C.electric.withOpacity(0.04),
              blurRadius: 1,
              spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

// ── Horizontal divider ────────────────────────────────────────────
class _HorizDivider extends StatelessWidget {
  const _HorizDivider();

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            _C.cardBorder,
            Colors.transparent,
          ]),
        ),
      );
}

// ── Footer ────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final String label;
  const _Footer({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: _C.success)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              color: _C.border, fontSize: 10, letterSpacing: 1)),
    ]);
  }
}

// ── Animated hex-grid background ──────────────────────────────────
class _HexGridPainter extends CustomPainter {
  final double opacity;
  const _HexGridPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _C.electric.withOpacity(0.022 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    const r = 36.0;
    const dx = r * 1.732;
    const dy = r * 1.5;
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
        path.close();
        canvas.drawPath(path, p);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(_HexGridPainter old) => old.opacity != opacity;
}