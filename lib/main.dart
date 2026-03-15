import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/token_store.dart';
import 'features/auth/ui/login_page.dart';
import 'features/glasses/ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Barre de statut transparente — style immersif
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1420),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const VtonApp());
}

// ═══════════════════════════════════════════════════════════════════
// APP
// ═══════════════════════════════════════════════════════════════════
class VtonApp extends StatelessWidget {
  const VtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VTON 3D Glasses',

      // Thème sombre cohérent avec la palette Luxury Optical Tech
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080C12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A8FF),
          brightness: Brightness.dark,
          primary: const Color(0xFF00A8FF),
          secondary: const Color(0xFF00D4AA),
          surface: const Color(0xFF111827),
          error: const Color(0xFFFF4D6A),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFFEDF2F8),
        ),

        // AppBar global
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1420),
          foregroundColor: Color(0xFFEDF2F8),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: Color(0xFFEDF2F8), letterSpacing: 1),
        ),

        // Snackbar global
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF111827),
          contentTextStyle: const TextStyle(color: Color(0xFFEDF2F8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),

        // Card global
        cardTheme: CardThemeData(
          color: const Color(0xFF161F2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E2D45), width: 1)),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E2D45), thickness: 1),

        // Input fields global
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1420),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E2D45))),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E2D45))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00A8FF), width: 1.5)),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF4D6A))),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF4D6A), width: 1.5)),
          labelStyle: const TextStyle(color: Color(0xFF7A90A8)),
          hintStyle: const TextStyle(color: Color(0xFF3A4A5A)),
          errorStyle: const TextStyle(color: Color(0xFFFF4D6A), fontSize: 11),
        ),

        // ElevatedButton / FilledButton global
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00A8FF),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF6B8099),
            disabledForegroundColor: Colors.white60,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            minimumSize: const Size(64, 48),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13),
          ),
        ),

        // OutlinedButton global
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00A8FF),
            side: const BorderSide(color: Color(0xFF00A8FF), width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            minimumSize: const Size(64, 48),
          ),
        ),

        // TextButton global
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00A8FF),
          ),
        ),

        // Chip global
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF0D1420),
          selectedColor: Color(0xFF00A8FF),
          labelStyle: TextStyle(color: Color(0xFF7A90A8), fontSize: 12),
          side: BorderSide(color: Color(0xFF1E2D45)),
          shape: StadiumBorder(),
        ),

        // Progress indicator
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF00A8FF),
        ),
      ),

      home: const AuthGate(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AUTH GATE — logique originale + splash screen stylisé
// ═══════════════════════════════════════════════════════════════════
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with SingleTickerProviderStateMixin {
  // ── Logique originale ──────────────────────────────────────────
  late final Future<bool> _hasTokenFuture = _hasAccessToken();

  Future<bool> _hasAccessToken() async {
    final token = await TokenStore.instance.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Animation splash ───────────────────────────────────────────
  late final AnimationController _splashCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _splashCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _fadeAnim  = CurvedAnimation(parent: _splashCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _splashCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _splashCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasTokenFuture,
      builder: (context, snapshot) {
        // ── Loading — splash screen stylisé ───────────────────
        if (snapshot.connectionState != ConnectionState.done) {
          return _SplashScreen(pulseAnim: _pulseAnim);
        }

        // ── Logique originale ──────────────────────────────────
        if (snapshot.data == true) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SPLASH SCREEN
// ═══════════════════════════════════════════════════════════════════
class _SplashScreen extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _SplashScreen({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C12),
      body: Stack(children: [
        // Halos décoratifs
        Positioned(top: -100, right: -80,
          child: Container(width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00A8FF).withOpacity(0.10),
                Colors.transparent])))),
        Positioned(bottom: -100, left: -80,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00D4AA).withOpacity(0.07),
                Colors.transparent])))),

        // Contenu centré
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo lunettes animé
              AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: pulseAnim.value,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0078CC), Color(0xFF00A8FF)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFF00A8FF)
                              .withOpacity(0.35 * pulseAnim.value),
                          blurRadius: 28, offset: const Offset(0, 6))]),
                    child: const Center(
                      child: Text('👗', style: TextStyle(fontSize: 38))),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Titre
              const Text('VTON GLASSES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900,
                  color: Color(0xFFEDF2F8), letterSpacing: 5)),
              const SizedBox(height: 6),

              // Subtitle avec ligne décorative
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 28, height: 1,
                  decoration: const BoxDecoration(gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xFF00A8FF)]))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('3D VIRTUAL TRY-ON', style: TextStyle(
                    fontSize: 10, color: Color(0xFF00A8FF),
                    letterSpacing: 3, fontWeight: FontWeight.w600))),
                Container(width: 28, height: 1,
                  decoration: const BoxDecoration(gradient: LinearGradient(
                    colors: [Color(0xFF00A8FF), Colors.transparent]))),
              ]),
              const SizedBox(height: 40),

              // Loader
              const SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF00A8FF)))),
              const SizedBox(height: 14),
              const Text('Initialisation…', style: TextStyle(
                  color: Color(0xFF7A90A8), fontSize: 12, letterSpacing: 1)),
            ],
          ),
        ),

        // Footer
        Positioned(bottom: 32, left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 5, height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF00D4AA))),
            const SizedBox(width: 6),
            const Text('© 2026 VTON · Mode augmentée',
              style: TextStyle(color: Color(0xFF1E2D45),
                fontSize: 10, letterSpacing: 1)),
          ])),
      ]),
    );
  }
}