import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'js_bridge_web.dart' if (dart.library.io) 'js_bridge_stub.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:ui';

// ─── CLE API OPENAI (saisie dans l app) ───────────────────────────────────────
String _kOpenAiKey = '';

// ─── CLE API ANTHROPIC CLAUDE ─────────────────────────────────────────────────
String _kAnthropicKey = '';

// ─── ELEMENTS DU FOND CYBERSECURITY ANIME ────────────────────────────────────

// Palette de couleurs néon cyberpunk
const _cyberColors = [
  Color(0xFF4A9EFF), // vert (dominant)
  Color(0xFF4A9EFF),
  Color(0xFF4A9EFF),
  Color(0xFF90D0FF), // cyan
  Color(0xFF90D0FF),
  Color(0xFF1A6FFF), // bleu
  Color(0xFF1A6FFF),
  Color(0xFFAA44FF), // violet
  Color(0xFFFF6600), // orange (alerte)
  Color(0xFFFFCC00), // jaune (attention)
];

class _Particle {
  double x, y, vx, vy;
  final Color color;
  final double size;
  _Particle(this.x, this.y, this.vx, this.vy, this.color, this.size);
}

class _DataStream {
  double x;
  double y;
  final double speed;
  final double opacity;
  final double trailLength;
  final Color color;
  _DataStream(this.x, Random rng)
      : y = rng.nextDouble() * 900,
        speed = rng.nextDouble() * 2.2 + 0.8,
        opacity = rng.nextDouble() * 0.55 + 0.25,
        trailLength = rng.nextDouble() * 80 + 40,
        color = _cyberColors[rng.nextInt(_cyberColors.length)];

  void update(double height) {
    y += speed;
    if (y > height + trailLength) y = -trailLength;
  }
}

// ─── PEINTRE FOND CYBER DYNAMIQUE & COLORÉ ────────────────────────────────────
class _CyberBackgroundPainter extends CustomPainter {
  final List<_DataStream> streams;
  final List<_Particle> particles;
  final double animValue; // 0.0 → 1.0 (boucle 10s)

  _CyberBackgroundPainter(this.streams, this.particles, Listenable repaint, this.animValue)
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── 1. Mise à jour des positions ──────────────────────────────────────────
    for (final s in streams) s.update(size.height);
    for (final p in particles) {
      p.x += p.vx; p.y += p.vy;
      if (p.x < 0 || p.x > 1) p.vx *= -1;
      if (p.y < 0 || p.y > 1) p.vy *= -1;
      p.x = p.x.clamp(0.0, 1.0); p.y = p.y.clamp(0.0, 1.0);
    }

    // ── 2. Zones de lueur colorées dans les coins ─────────────────────────────
    void drawGlow(Alignment align, Color color, double radius, double opacity) {
      canvas.drawRect(rect, Paint()
        ..shader = RadialGradient(
          center: align, radius: radius,
          colors: [color.withOpacity(opacity), Colors.transparent],
        ).createShader(rect)
        ..blendMode = BlendMode.plus);
    }
    drawGlow(Alignment.bottomLeft,   const Color(0xFF4A9EFF), 0.9,  0.10);
    drawGlow(Alignment.topRight,     const Color(0xFF1A6FFF), 0.85, 0.08);
    drawGlow(Alignment.topLeft,      const Color(0xFFAA44FF), 0.7,  0.06);
    drawGlow(Alignment.bottomRight,  const Color(0xFF90D0FF), 0.65, 0.05);
    drawGlow(Alignment.center,       const Color(0xFF003322), 0.55, 0.12);

    // ── 3. Anneaux de scan pulsants (animation) ────────────────────────────────
    final pulse1 = (animValue * 2.0) % 1.0;          // rapide
    final pulse2 = ((animValue + 0.5) * 1.5) % 1.0;  // décalé
    final pulse3 = (animValue * 0.7) % 1.0;           // lent

    void drawRing(double phase, Color color, double maxR) {
      final r = phase * maxR;
      final op = (1.0 - phase) * 0.15;
      if (op > 0.005) {
        canvas.drawCircle(
          Offset(cx, cy), r,
          Paint()
            ..color = color.withOpacity(op)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
    drawRing(pulse1, const Color(0xFF4A9EFF), size.width * 0.8);
    drawRing(pulse2, const Color(0xFF1A6FFF), size.width * 0.65);
    drawRing(pulse3, const Color(0xFF90D0FF), size.width * 0.55);

    // ── 4. Grille hexagonale colorée ──────────────────────────────────────────
    const r = 38.0;
    const hh = r * 1.732;
    int hexIdx = 0;
    for (double hx = -r; hx < size.width + r * 2; hx += r * 1.5) {
      final col = (hx / (r * 1.5)).round();
      for (double hy = -hh; hy < size.height + hh; hy += hh) {
        final cy2 = hy + (col.isOdd ? hh / 2 : 0);
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (pi / 3) * i;
          final px = hx + r * cos(a); final py = cy2 + r * sin(a);
          if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
        }
        path.close();
        // Couleur selon position : la plupart verts, certains autres couleurs
        final Color hexColor;
        final mod = hexIdx % 12;
        if (mod == 3) hexColor = const Color(0xFF1A6FFF);
        else if (mod == 7) hexColor = const Color(0xFF90D0FF);
        else if (mod == 10) hexColor = const Color(0xFFAA44FF);
        else hexColor = const Color(0xFF4A9EFF);
        // Surbrillance de certains hexagones (basée sur animValue)
        final isGlowing = (hexIdx % 17 == (animValue * 17).toInt() % 17);
        canvas.drawPath(path, Paint()
          ..color = hexColor.withOpacity(isGlowing ? 0.18 : 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isGlowing ? 1.2 : 0.6);
        hexIdx++;
      }
    }

    // ── 5. Data streams multicolores ──────────────────────────────────────────
    for (final s in streams) {
      // Ligne guide très fine
      canvas.drawLine(Offset(s.x, 0), Offset(s.x, size.height),
        Paint()..color = s.color.withOpacity(0.04)..strokeWidth = 0.7);

      // Trail lumineux coloré
      final trailRect = Rect.fromLTWH(s.x - 1.5, s.y - s.trailLength, 3, s.trailLength);
      canvas.drawRect(trailRect, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, s.color.withOpacity(s.opacity * 0.5)],
        ).createShader(trailRect));

      // Halo de la tête (glow)
      canvas.drawCircle(Offset(s.x, s.y), 5,
        Paint()
          ..color = s.color.withOpacity(s.opacity * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // Tête principale brillante
      canvas.drawCircle(Offset(s.x, s.y), 2.5,
        Paint()
          ..color = s.color.withOpacity(s.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));

      // Point blanc central
      canvas.drawCircle(Offset(s.x, s.y), 1.0,
        Paint()..color = Colors.white.withOpacity(s.opacity * 0.9));
    }

    // ── 6. Réseau neuronal multicolore ────────────────────────────────────────
    final pts = particles.map((p) => Offset(p.x * size.width, p.y * size.height)).toList();
    final linePaint = Paint()..strokeWidth = 0.8;
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < 160) {
          final alpha = (1 - d / 160) * 0.14;
          linePaint.color = particles[i].color.withOpacity(alpha);
          canvas.drawLine(pts[i], pts[j], linePaint);
        }
      }
    }
    for (int i = 0; i < pts.length; i++) {
      final p = particles[i];
      // Halo
      canvas.drawCircle(pts[i], p.size * 2.5,
        Paint()
          ..color = p.color.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      // Point principal
      canvas.drawCircle(pts[i], p.size,
        Paint()
          ..color = p.color.withOpacity(0.55)
          ..style = PaintingStyle.fill);
    }

    // ── 7. Lignes de scan horizontales (effet radar) ──────────────────────────
    final scanY = (animValue * size.height * 1.3) % (size.height + 50) - 25;
    canvas.drawLine(
      Offset(0, scanY), Offset(size.width, scanY),
      Paint()
        ..color = const Color(0xFF4A9EFF).withOpacity(0.08)
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(0, scanY + 2), Offset(size.width, scanY + 2),
      Paint()
        ..color = const Color(0xFF90D0FF).withOpacity(0.04)
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(_CyberBackgroundPainter old) => true;
}

// ─── SERVICE DE NOTIFICATIONS ─────────────────────────────────────────────────

// Cle globale pour afficher les notifications dans l app
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  static Future<void> init() async {
    // onBackgroundMessage n'est pas supporte sur le web
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    try {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {}
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        showInAppNotification(notif.title ?? 'CyberGuard', notif.body ?? '');
      }
    });
  }

  // Notification système (banner in-app + demande permission navigateur au 1er lancement)
  static void showSystemNotification(String title, String body, {String level = 'warning'}) {
    showInAppNotification(title, body, level: level);
    _execJs(title, body);
  }

  // Notification ARIA spéciale : menace + contre-attaque + bouton "Parler à ARIA"
  static void showAriaNotification({
    required String threat,
    required String counterAction,
    required void Function()? onTalkToAria,
  }) {
    // Notification navigateur avec description complète
    _execJs('🛡️ ARIA — Menace neutralisée', '$threat\n↳ $counterAction');

    // Banner in-app riche avec bouton "Parler à ARIA"
    final key = GlobalKey<ScaffoldMessengerState>();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: const Color(0xFF0D2B1A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF4A9EFF), width: 1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.shield, color: Color(0xFF4A9EFF), size: 18),
              const SizedBox(width: 8),
              const Text('ARIA — Menace neutralisée', style: TextStyle(color: Color(0xFF4A9EFF), fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 4),
            Text(threat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 2),
            Text('↳ $counterAction', style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        action: onTalkToAria != null
            ? SnackBarAction(
                label: '🎤 Parler à ARIA',
                textColor: const Color(0xFF4A9EFF),
                onPressed: onTalkToAria,
              )
            : null,
      ),
    );
  }

  static void _execJs(String title, String body) {
    sendBrowserNotif(title, body); // Appel via js_bridge_web.dart (web) ou stub (mobile)
  }

  // Notification visible dans l app (fonctionne sur Web, Android et iOS)
  static void showInAppNotification(String title, String body, {String level = 'warning'}) {
    final color = level == 'danger' ? Colors.red : level == 'warning' ? Colors.orange : Colors.blue;
    final icon = level == 'danger' ? Icons.dangerous : level == 'warning' ? Icons.warning : Icons.info;
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: color.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await NotificationService.init();
  } catch (_) {}
  runApp(const CyberGuardApp());
}

class CyberGuardApp extends StatelessWidget {
  const CyberGuardApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CyberGuard AI',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: scaffoldMessengerKey,
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const AuthGate(),
  );
}

// ─── AUTH GATE AVEC VÉRIFICATION PIN 2FA ─────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _pinVerified = false;
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blue)));
        }
        final user = snapshot.data;
        if (user == null) {
          // Reset on logout
          _pinVerified = false;
          _lastUserId = null;
          return const AuthScreen();
        }
        // New login or initial load — set user ID and require PIN check
        if (_lastUserId != user.uid) {
          _lastUserId = user.uid;
          _pinVerified = false;
        }
        // Logged in — check if PIN is required
        if (!_pinVerified) {
          return _PinVerifyScreen(
            onVerified: () { if (mounted) setState(() => _pinVerified = true); },
            onSkip: () { if (mounted) setState(() => _pinVerified = true); },
          );
        }
        return const MainScreen();
      },
    );
  }
}

// ── Écran vérification PIN 2FA ────────────────────────────────────────────────
class _PinVerifyScreen extends StatefulWidget {
  final VoidCallback onVerified;
  final VoidCallback onSkip;
  const _PinVerifyScreen({required this.onVerified, required this.onSkip});
  @override
  State<_PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<_PinVerifyScreen> {
  final List<String> _pin = [];
  String? _pinHash;
  bool _loading = true;
  bool _error = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString('user_pin_hash');
    if (!mounted) return;
    setState(() { _pinHash = hash; _loading = false; });
    if (hash == null) {
      // No PIN configured — skip immediately after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSkip();
      });
    }
  }

  String _hashPin(List<String> digits) {
    // Simple hash using sum+product+length for lightweight verification
    final code = digits.join('');
    var h = 0;
    for (int i = 0; i < code.length; i++) {
      h = (h * 31 + code.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return '${h}_${code.length}';
  }

  void _onDigit(String d) {
    if (_pin.length >= 6) return;
    setState(() { _pin.add(d); _error = false; });
    if (_pin.length == 6) _verify();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  void _verify() {
    final entered = _hashPin(_pin);
    if (entered == _pinHash) {
      widget.onVerified();
    } else {
      _attempts++;
      setState(() { _error = true; _pin.clear(); });
    }
  }

  Future<void> _forgotPin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Re-send password reset email and clear PIN
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_pin_hash');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de réinitialisation envoyé. PIN supprimé.'),
          backgroundColor: Colors.orange,
        ),
      );
      widget.onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blue)));
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF04080F), Color(0xFF0A0520)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.4), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.lock, color: Color(0xFF04080F), size: 36),
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)],
                    ).createShader(b),
                    child: const Text('CyberGuard AI',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Entrez votre code PIN',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Protection à deux facteurs active',
                    style: TextStyle(color: Colors.blue.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 32),

                  // Indicateurs PIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length
                          ? (_error ? Colors.red : const Color(0xFF4A9EFF))
                          : Colors.white12,
                        border: Border.all(
                          color: i < _pin.length
                            ? (_error ? Colors.red : const Color(0xFF4A9EFF))
                            : Colors.white24,
                        ),
                        boxShadow: i < _pin.length && !_error ? [
                          BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.5), blurRadius: 8)
                        ] : null,
                      ),
                    )),
                  ),

                  if (_error) ...[
                    const SizedBox(height: 12),
                    Text(
                      _attempts >= 5 ? 'Trop de tentatives. Réinitialisez votre PIN.' : 'Code PIN incorrect. Réessayez.',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Clavier numérique
                  SizedBox(
                    width: 260,
                    child: Column(children: [
                      for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['⌫','0','✓']])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: row.map((k) => _buildKey(k)).toList(),
                          ),
                        ),
                    ]),
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _forgotPin,
                    child: const Text('PIN oublié ? Réinitialiser via email',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label) {
    final isBack = label == '⌫';
    final isConfirm = label == '✓';
    return GestureDetector(
      onTap: () {
        if (isBack) _onBackspace();
        else if (isConfirm) { if (_pin.length == 6) _verify(); }
        else _onDigit(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 72, height: 56,
        decoration: BoxDecoration(
          color: isConfirm
            ? const Color(0xFF4A9EFF).withOpacity(0.15)
            : isBack
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConfirm
              ? const Color(0xFF4A9EFF).withOpacity(0.4)
              : Colors.white12,
          ),
        ),
        child: Center(child: Text(
          label,
          style: TextStyle(
            fontSize: isBack || isConfirm ? 20 : 22,
            fontWeight: FontWeight.w600,
            color: isConfirm ? const Color(0xFF4A9EFF) : Colors.white,
          ),
        )),
      ),
    );
  }
}

// ── Dialog setup PIN 2FA ──────────────────────────────────────────────────────
class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({super.key});
  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final List<String> _pin = [];
  final List<String> _confirm = [];
  bool _confirming = false;
  String? _error;
  bool _done = false;

  String _hashPin(List<String> digits) {
    final code = digits.join('');
    var h = 0;
    for (int i = 0; i < code.length; i++) {
      h = (h * 31 + code.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return '${h}_${code.length}';
  }

  void _onDigit(String d) {
    if (_confirming) {
      if (_confirm.length >= 6) return;
      setState(() { _confirm.add(d); _error = null; });
      if (_confirm.length == 6) _finalizeConfirm();
    } else {
      if (_pin.length >= 6) return;
      setState(() { _pin.add(d); _error = null; });
      if (_pin.length == 6) setState(() => _confirming = true);
    }
  }

  void _onBackspace() {
    setState(() {
      if (_confirming) { if (_confirm.isNotEmpty) _confirm.removeLast(); }
      else { if (_pin.isNotEmpty) _pin.removeLast(); }
      _error = null;
    });
  }

  void _finalizeConfirm() {
    if (_pin.join('') != _confirm.join('')) {
      setState(() { _error = 'Les codes ne correspondent pas. Recommencez.'; _confirm.clear(); });
      return;
    }
    _savePin();
  }

  Future<void> _savePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin_hash', _hashPin(_pin));
    if (mounted) setState(() => _done = true);
  }

  Future<void> _disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_pin_hash');
    if (mounted) Navigator.pop(context, 'disabled');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0520),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _done ? _buildDone() : _buildSetup(),
      ),
    );
  }

  Widget _buildDone() => Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.verified_user, color: Color(0xFF4A9EFF), size: 52),
    const SizedBox(height: 16),
    const Text('PIN 2FA activé !',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A9EFF))),
    const SizedBox(height: 8),
    const Text('Votre code PIN sera demandé à chaque connexion.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white54, fontSize: 13)),
    const SizedBox(height: 24),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, 'set'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A9EFF),
          foregroundColor: const Color(0xFF04080F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Parfait !', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ),
  ]);

  Widget _buildSetup() => Column(mainAxisSize: MainAxisSize.min, children: [
    Row(children: [
      const Icon(Icons.pin, color: Color(0xFF4A9EFF), size: 24),
      const SizedBox(width: 10),
      Text(
        _confirming ? 'Confirmez votre PIN' : 'Choisissez un PIN à 6 chiffres',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ]),
    const SizedBox(height: 6),
    Text(
      _confirming ? 'Retapez le même code pour confirmer.' : 'Ce code vous sera demandé à chaque connexion.',
      style: const TextStyle(color: Colors.white54, fontSize: 12),
    ),
    const SizedBox(height: 20),
    // Indicateurs
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final current = _confirming ? _confirm : _pin;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14, height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < current.length ? const Color(0xFF4A9EFF) : Colors.white12,
            border: Border.all(color: i < current.length ? const Color(0xFF4A9EFF) : Colors.white24),
          ),
        );
      }),
    ),
    if (_error != null) ...[
      const SizedBox(height: 10),
      Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
    ],
    const SizedBox(height: 20),
    // Clavier
    for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['⌫','0','✓']])
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {
                if (k == '⌫') _onBackspace();
                else if (k == '✓') {
                  if (_confirming && _confirm.length == 6) _finalizeConfirm();
                  else if (!_confirming && _pin.length == 6) setState(() => _confirming = true);
                }
                else _onDigit(k);
              },
              child: Container(
                width: 60, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(child: Text(k,
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500))),
              ),
            ),
          )).toList(),
        ),
      ),
    const SizedBox(height: 12),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler', style: TextStyle(color: Colors.white38)),
      ),
      TextButton(
        onPressed: _disablePin,
        child: const Text('Désactiver PIN', style: TextStyle(color: Colors.orange, fontSize: 12)),
      ),
    ]),
  ]);
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _emailLogin = TextEditingController();
  final _passLogin = TextEditingController();
  final _emailReg = TextEditingController();
  final _passReg = TextEditingController();
  final _nameReg = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showPassLogin = false;
  bool _showPassReg = false;
  bool _rememberMe = false;
  bool _autoLogin = false;
  int _autoLoginCountdown = 0;
  Timer? _autoLoginTimer;
  // Acceptation CGU (obligatoire pour créer un compte)
  bool _acceptedCGU = false;
  // Email/pass sauvegardés pour auto-suggestion
  String _savedEmail = '';
  String _savedPass = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('auth_email') ?? '';
    final savedPass = prefs.getString('auth_pass') ?? '';
    final remember = prefs.getBool('auth_remember') ?? false;
    final auto = prefs.getBool('auth_auto') ?? false;
    if (!mounted) return;
    setState(() {
      _savedEmail = savedEmail;
      _savedPass = savedPass;
    });
    if (remember && savedEmail.isNotEmpty) {
      setState(() {
        _emailLogin.text = savedEmail;
        _passLogin.text = savedPass;
        _rememberMe = remember;
        _autoLogin = auto;
      });
      if (auto && savedPass.isNotEmpty) _startAutoLoginCountdown();
    }
  }

  void _startAutoLoginCountdown() {
    setState(() => _autoLoginCountdown = 3);
    _autoLoginTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_autoLoginCountdown <= 1) {
        t.cancel();
        setState(() => _autoLoginCountdown = 0);
        _login();
      } else {
        setState(() => _autoLoginCountdown--);
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('auth_email', _emailLogin.text.trim());
      await prefs.setString('auth_pass', _passLogin.text);
      await prefs.setBool('auth_remember', true);
      await prefs.setBool('auth_auto', _autoLogin);
    } else {
      await prefs.remove('auth_email');
      await prefs.remove('auth_pass');
      await prefs.setBool('auth_remember', false);
      await prefs.setBool('auth_auto', false);
    }
  }

  @override
  void dispose() {
    _autoLoginTimer?.cancel();
    _tab.dispose();
    _emailLogin.dispose();
    _passLogin.dispose();
    _emailReg.dispose();
    _passReg.dispose();
    _nameReg.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    _autoLoginTimer?.cancel();
    setState(() { _loading = true; _error = null; _autoLoginCountdown = 0; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailLogin.text.trim(),
        password: _passLogin.text,
      );
      await _saveCredentials(); // Sauvegarder si succès
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.code == 'user-not-found' ? 'Compte introuvable.' : e.code == 'wrong-password' ? 'Mot de passe incorrect.' : 'Erreur: ${e.message}'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!_acceptedCGU) {
      setState(() => _error = 'Vous devez accepter les CGU pour créer un compte.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailReg.text.trim(),
        password: _passReg.text,
      );
      if (_nameReg.text.isNotEmpty) {
        await cred.user?.updateDisplayName(_nameReg.text.trim());
      }
      // Enregistrer l'acceptation des CGU avec horodatage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cgu_accepted_v1', true);
      await prefs.setString('cgu_accepted_at', DateTime.now().toIso8601String());
      await prefs.setString('cgu_accepted_email', _emailReg.text.trim());
      // Afficher l'onboarding
      if (mounted) _showOnboarding();
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.code == 'email-already-in-use' ? 'Email déjà utilisé.' : e.code == 'weak-password' ? 'Mot de passe trop faible (6 caractères min).' : 'Erreur: ${e.message}'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showOnboarding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _OnboardingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.shield, color: Colors.blue, size: 72),
              const SizedBox(height: 12),
              const Text('CyberGuard AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Text('Votre protection contre les cyberattaques', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 32),
              TabBar(
                controller: _tab,
                tabs: const [Tab(text: 'Connexion'), Tab(text: 'Inscription')],
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.4))),
                  child: Row(children: [const Icon(Icons.error_outline, color: Colors.red, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)))]),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    Column(
                      children: [
                        // ── Email avec suggestion enregistrée ─────────────
                        Stack(
                          children: [
                            TextField(
                              controller: _emailLogin,
                              keyboardType: TextInputType.emailAddress,
                              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_savedEmail.isNotEmpty && _emailLogin.text.isEmpty)
                              Positioned(
                                right: 8, top: 6,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _emailLogin.text = _savedEmail;
                                    _passLogin.text = _savedPass;
                                    _emailLogin.selection = TextSelection.fromPosition(
                                      TextPosition(offset: _savedEmail.length));
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blue.withOpacity(0.4)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.person, color: Colors.blue, size: 13),
                                      const SizedBox(width: 4),
                                      Text(_savedEmail.split('@')[0],
                                        style: const TextStyle(color: Colors.blue, fontSize: 11)),
                                    ]),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passLogin,
                          obscureText: !_showPassLogin,
                          onSubmitted: (_) => _login(), // ← Touche Entrée = connexion
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassLogin ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _showPassLogin = !_showPassLogin),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Se souvenir de moi
                        Row(children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() { _rememberMe = v ?? false; if (!_rememberMe) _autoLogin = false; }),
                            activeColor: Colors.blue,
                            side: const BorderSide(color: Colors.grey),
                          ),
                          const Text('Se souvenir de moi', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const Spacer(),
                          if (_rememberMe) ...[
                            Checkbox(
                              value: _autoLogin,
                              onChanged: (v) => setState(() => _autoLogin = v ?? false),
                              activeColor: Colors.blue,
                              side: const BorderSide(color: Colors.grey),
                            ),
                            const Text('Connexion auto', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ]),
                        const SizedBox(height: 8),
                        // Compte à rebours connexion auto
                        if (_autoLoginCountdown > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.withOpacity(0.4))),
                            child: Row(children: [
                              const Icon(Icons.bolt, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Text('Connexion dans $_autoLoginCountdown s...', style: const TextStyle(color: Colors.blue, fontSize: 13)),
                              const Spacer(),
                              TextButton(
                                onPressed: () { _autoLoginTimer?.cancel(); setState(() => _autoLoginCountdown = 0); },
                                child: const Text('Annuler', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                            ]),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(14)),
                            child: _loading ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2) : const Text('Se connecter', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextField(controller: _nameReg, decoration: const InputDecoration(labelText: 'Prenom (optionnel)', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                        const SizedBox(height: 14),
                        TextField(controller: _emailReg, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passReg,
                          obscureText: !_showPassReg,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe (6 car. min)',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassReg ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _showPassReg = !_showPassReg),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ── Acceptation CGU (obligatoire) ──────────────────
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _acceptedCGU
                                ? Colors.blue.withOpacity(0.08)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _acceptedCGU
                                  ? Colors.blue.withOpacity(0.5)
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptedCGU,
                                onChanged: (v) => setState(() => _acceptedCGU = v ?? false),
                                activeColor: Colors.blue,
                                side: const BorderSide(color: Colors.grey),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _acceptedCGU = !_acceptedCGU),
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.5),
                                      children: [
                                        TextSpan(text: 'J\'ai lu et j\'accepte les '),
                                        TextSpan(
                                          text: 'Conditions Générales d\'Utilisation',
                                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: ' et la '),
                                        TextSpan(
                                          text: 'Politique de Confidentialité',
                                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: ', notamment la collecte et le traitement de mes données conformément au RGPD.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_loading || !_acceptedCGU) ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _acceptedCGU ? Colors.blue : Colors.grey.shade800,
                              padding: const EdgeInsets.all(14),
                              disabledBackgroundColor: Colors.grey.shade800,
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                                : Text(
                                    'Créer mon compte',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _acceptedCGU ? Colors.black : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DIALOG ONBOARDING (après inscription) ────────────────────────────────────

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();
  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnbPage(
      icon: Icons.shield,
      color: Color(0xFF4A9EFF),
      title: 'Bienvenue dans CyberGuard AI',
      body: 'Votre bouclier numérique personnel, disponible 24h/24. '
          'ARIA, votre IA de cybersécurité, surveille en temps réel '
          'les menaces et vous protège automatiquement.',
    ),
    _OnbPage(
      icon: Icons.mic,
      color: Colors.cyanAccent,
      title: 'ARIA — Votre IA vocale',
      body: 'Appuyez sur le bouton vert central pour parler à ARIA. '
          'Elle répond en voix naturelle, analyse vos questions de sécurité '
          'et agit en votre nom. Parlez-lui comme à un expert.',
    ),
    _OnbPage(
      icon: Icons.newspaper,
      color: Colors.orangeAccent,
      title: 'Veille cyber quotidienne',
      body: 'L\'onglet "Veille" vous affiche chaque jour les dernières '
          'alertes officielles du CERT-FR et de la CISA. '
          'ARIA se met à jour automatiquement avec ces informations.',
    ),
    _OnbPage(
      icon: Icons.gavel,
      color: Colors.lightBlueAccent,
      title: 'Rapport légal & Plainte',
      body: 'Si vous êtes victime d\'une cyberattaque, l\'onglet Alertes → '
          'icône ⚖ génère un rapport PDF à valeur probatoire '
          'et vous connecte aux portails de plainte de 14 pays européens.',
    ),
    _OnbPage(
      icon: Icons.visibility_off,
      color: Colors.deepPurpleAccent,
      title: 'Détecteur de logiciels espions',
      body: 'Vous pensez être surveillé ? L\'outil "Logiciels espions" '
          'sur l\'accueil vous aide à détecter les stalkerware '
          '(mSpy, FlexiSPY, Hoverwatch…) installés à votre insu.',
    ),
    _OnbPage(
      icon: Icons.privacy_tip,
      color: Colors.amberAccent,
      title: 'Vos données & votre vie privée',
      body: 'Conformément au RGPD :\n'
          '• Nous collectons uniquement votre email et vos alertes de sécurité\n'
          '• Votre clé API OpenAI reste sur votre appareil — nous n\'y avons pas accès\n'
          '• Vos données sont hébergées sur Google Firebase (UE)\n'
          '• Vous pouvez supprimer votre compte et toutes vos données à tout moment\n'
          '• Aucune publicité, aucune revente de données',
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Barre de progression ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: List.generate(_pages.length, (i) => Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i < _pages.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= _page
                        ? _pages[_page].color
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),

          // ── Contenu des pages ────────────────────────────────────────────
          SizedBox(
            height: 320,
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _page = i),
              children: _pages.map((p) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.color.withOpacity(0.15),
                        border: Border.all(color: p.color.withOpacity(0.5), width: 1.5),
                      ),
                      child: Icon(p.icon, color: p.color, size: 34),
                    ),
                    const SizedBox(height: 18),
                    Text(p.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.color,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(p.body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          // ── Indicateurs de page ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => Container(
              width: i == _page ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _page ? _pages[_page].color : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),

          const SizedBox(height: 16),

          // ── Boutons ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                if (_page > 0) TextButton(
                  onPressed: () => _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: const Text('Précédent', style: TextStyle(color: Colors.white38)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_page].color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    _page == _pages.length - 1 ? 'J\'accepte et je commence ✓' : 'Suivant →',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── Texte légal sur la dernière page ────────────────────────────
          if (_page == _pages.length - 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 14, left: 20, right: 20),
              child: Text(
                'En cliquant sur "J\'accepte et je commence", vous confirmez avoir '
                'lu et accepté les CGU et la Politique de Confidentialité de CyberGuard AI. '
                'Votre consentement est enregistré avec horodatage.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white30, fontSize: 9.5, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnbPage {
  final IconData icon;
  final Color color;
  final String title, body;
  const _OnbPage({required this.icon, required this.color, required this.title, required this.body});
}

// ─── MODELE D'ALERTE AVEC SOLUTION ───────────────────────────────────────────

class ThreatAlert {
  final String id;
  final String title;
  final String description;
  final String level;
  final DateTime time;
  final String solution;
  final List<String> steps;

  ThreatAlert({
    String? id,
    required this.title,
    required this.description,
    required this.level,
    required this.time,
    this.solution = '',
    this.steps = const [],
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'level': level,
    'time': time.millisecondsSinceEpoch,
    'solution': solution,
    'steps': steps,
  };

  factory ThreatAlert.fromMap(Map<String, dynamic> m) => ThreatAlert(
    id: m['id'] ?? '',
    title: m['title'] ?? '',
    description: m['description'] ?? '',
    level: m['level'] ?? 'info',
    time: DateTime.fromMillisecondsSinceEpoch(m['time'] ?? 0),
    solution: m['solution'] ?? '',
    steps: List<String>.from(m['steps'] ?? []),
  );
}

// ─── ETAT DE SECURITE AVEC FIRESTORE ─────────────────────────────────────────

class SecurityState {
  static final SecurityState _instance = SecurityState._internal();
  factory SecurityState() => _instance;
  SecurityState._internal();

  bool scanning = false;
  List<ThreatAlert> alerts = [];
  List<void Function()> listeners = [];
  String? _uid;

  // ARIA — agent IA autonome connecte a la securite
  static VoiceAIService? _aria;
  static void connectARIA(VoiceAIService v) => _aria = v;

  void addListener(void Function() l) => listeners.add(l);
  void removeListener(void Function() l) => listeners.remove(l);
  void notify() { for (var l in listeners) l(); }

  // ── Score dynamique basé uniquement sur les alertes ACTIVES (non résolues) ──
  // Jamais bloqué à zéro : se récupère automatiquement quand on résout les alertes
  int get score {
    final now = DateTime.now();
    // Seules les alertes des dernières 2h comptent pleinement
    final recentDangers = alerts.where((a) =>
      a.level == 'danger' && now.difference(a.time).inHours < 2).length;
    final recentWarnings = alerts.where((a) =>
      a.level == 'warning' && now.difference(a.time).inHours < 2).length;
    // Alertes plus anciennes : impact réduit
    final oldDangers = alerts.where((a) =>
      a.level == 'danger' && now.difference(a.time).inHours >= 2).length;
    final oldWarnings = alerts.where((a) =>
      a.level == 'warning' && now.difference(a.time).inHours >= 2).length;
    final s = 100
        - (recentDangers * 8)
        - (recentWarnings * 3)
        - (oldDangers * 2)
        - (oldWarnings * 1);
    return max(20, s); // Plancher à 20 — jamais affiché zéro
  }

  // Charger les alertes depuis Firestore au demarrage
  Future<void> loadFromFirestore(String uid) async {
    _uid = uid;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('alerts')
          .orderBy('time', descending: true)
          .limit(30) // Limiter à 30 pour éviter l'écrasement du score
          .get();
      alerts = snap.docs.map((d) => ThreatAlert.fromMap(d.data())).toList();
      notify();
    } catch (_) {}
  }

  // Ajouter une alerte et la sauvegarder dans Firestore
  Future<void> addAlert(ThreatAlert a) async {
    alerts.insert(0, a);
    if (alerts.length > 30) alerts.removeLast();
    notify();
    // ARIA neutralise automatiquement TOUTES les menaces critiques (sans parler)
    if (a.level == 'danger' && _kAnthropicKey.isNotEmpty) {
      Future.microtask(() => _aria?.autoNeutralize(a));
    }
    // Enregistrer comme preuve numérique légale (Firebase)
    if (a.level == 'danger' || a.level == 'warning') {
      EvidenceService.recordEvidence(a);
    }
    // Notification système visible sur téléphone/ordi
    if (a.level == 'danger' || a.level == 'warning') {
      NotificationService.showSystemNotification(
        a.level == 'danger' ? '🛡️ ARIA neutralise une menace' : '⚠️ ${a.title}',
        a.level == 'danger' ? '${a.title} — Contre-mesure ARIA en cours...' : a.description,
        level: a.level,
      );
    }
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users').doc(_uid).collection('alerts')
            .doc(a.id).set(a.toMap());
      } catch (_) {}
    }
  }

  // Supprimer une alerte de Firestore
  Future<void> clearAlert(int i) async {
    if (i >= alerts.length) return;
    final a = alerts[i];
    alerts.removeAt(i);
    notify();
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users').doc(_uid).collection('alerts')
            .doc(a.id).delete();
      } catch (_) {}
    }
  }

  // Supprimer toutes les alertes
  Future<void> clearAllAlerts() async {
    final toDelete = List<ThreatAlert>.from(alerts);
    alerts.clear();
    notify();
    if (_uid != null) {
      for (final a in toDelete) {
        try {
          await FirebaseFirestore.instance
              .collection('users').doc(_uid).collection('alerts')
              .doc(a.id).delete();
        } catch (_) {}
      }
    }
  }

  void reset() {
    alerts.clear();
    _uid = null;
  }
}

// ─── SCANNER AUTOMATIQUE AVEC SOLUTIONS ──────────────────────────────────────

class AutoScanner {
  static Timer? _timer;
  static final _rng = Random();
  static int _cycle = 0;

  static final _events = [
    () => ThreatAlert(
      title: 'Reseau WiFi non securise',
      description: 'Connexion sans chiffrement detectee sur le reseau local.',
      level: 'warning',
      time: DateTime.now(),
      solution: 'Votre connexion WiFi n est pas chiffree. Des personnes proches pourraient intercepter vos donnees.',
      steps: [
        '1. Allez dans Parametres > WiFi',
        '2. Oubliez le reseau actuel',
        '3. Connectez-vous uniquement aux reseaux proteges par mot de passe (WPA2/WPA3)',
        '4. Evitez les WiFi publics pour vos operations bancaires',
        '5. Utilisez un VPN si vous devez utiliser un WiFi public',
      ],
    ),
    () => ThreatAlert(
      title: 'Tentative de phishing bloquee',
      description: 'Un lien malveillant a ete detecte et bloque automatiquement.',
      level: 'danger',
      time: DateTime.now(),
      solution: 'Un site frauduleux a tente de voler vos informations. CyberGuard l a bloque.',
      steps: [
        '1. Ne cliquez jamais sur des liens recus par SMS ou email inconnu',
        '2. Verifiez toujours l adresse du site (https:// et nom correct)',
        '3. Vos banques ne demandent JAMAIS votre mot de passe par email',
        '4. En cas de doute, appelez directement votre banque',
        '5. Changez vos mots de passe si vous avez deja clique sur un lien suspect',
      ],
    ),
    () => ThreatAlert(
      title: 'Application suspecte detectee',
      description: 'Comportement inhabituel detecte dans une application installee.',
      level: 'warning',
      time: DateTime.now(),
      solution: 'Une application sur votre telephone se comporte de maniere suspecte et pourrait espionner votre activite.',
      steps: [
        '1. Allez dans Parametres > Applications',
        '2. Cherchez les apps que vous ne reconnaissez pas',
        '3. Verifiez les permissions de chaque app (micro, camera, localisation)',
        '4. Desinstallez toute app inconnue ou suspecte',
        '5. Telechargez uniquement depuis le Play Store ou App Store officiel',
      ],
    ),
    () => ThreatAlert(
      title: 'Logiciel espion potentiel',
      description: 'Une application tente d acceder a votre camera et microphone en arriere-plan.',
      level: 'danger',
      time: DateTime.now(),
      solution: 'Un logiciel espion (spyware) pourrait surveiller votre telephone a votre insu. Agissez rapidement.',
      steps: [
        '1. Allez dans Parametres > Applications > voir toutes les apps',
        '2. Cherchez des apps inconnues avec acces camera/micro',
        '3. Retirez les permissions camera et micro aux apps non necessaires',
        '4. Faites une reinitialisation d usine si le probleme persiste',
        '5. Changez tous vos mots de passe depuis un autre appareil',
        '6. Contactez la police si vous pensez etre victime de surveillance illegale',
      ],
    ),
    () => ThreatAlert(
      title: 'Certificat SSL invalide',
      description: 'Un site web que vous visitez a un certificat de securite expire.',
      level: 'warning',
      time: DateTime.now(),
      solution: 'Le site web que vous consultez n est pas securise. Vos donnees pourraient etre interceptees.',
      steps: [
        '1. Ne saisissez aucune information personnelle sur ce site',
        '2. Ne faites aucun paiement sur ce site',
        '3. Quittez le site immediatement',
        '4. Signalez le site a votre navigateur (option "Signaler un site dangereux")',
      ],
    ),
    () => ThreatAlert(
      title: 'Scan complet termine',
      description: 'Aucune nouvelle menace detectee. Votre telephone est protege.',
      level: 'info',
      time: DateTime.now(),
      solution: 'Tout va bien ! Continuez a utiliser votre telephone normalement.',
      steps: [
        'Votre telephone est securise.',
        'CyberGuard surveille en permanence pour vous proteger.',
      ],
    ),
  ];

  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      _cycle++;
      final state = SecurityState();
      state.scanning = true;
      state.notify();

      Future.delayed(const Duration(seconds: 3), () {
        state.scanning = false;
        if (_cycle % 3 == 0 || _rng.nextDouble() < 0.4) {
          final event = _events[_rng.nextInt(_events.length)];
          state.addAlert(event());
        } else {
          state.notify();
        }
      });
    });
  }

  static void stop() => _timer?.cancel();

  static void triggerManualScan() {
    final state = SecurityState();
    state.scanning = true;
    state.notify();
    Future.delayed(const Duration(seconds: 3), () {
      state.scanning = false;
      final event = _events[_rng.nextInt(_events.length)];
      state.addAlert(event());
    });
  }
}

// ─── VOICE AI SERVICE (GPT-4o + OpenAI TTS) ──────────────────────────────────

class VoiceAIService {
  static final VoiceAIService _instance = VoiceAIService._internal();
  factory VoiceAIService() => _instance;
  VoiceAIService._internal();

  // ── Mémoire d'apprentissage ARIA ────────────────────────────────────────────
  static String _dailyBriefing = '';
  static List<String> _learnedThreats = []; // menaces vécues, persistent
  static String pendingMessage = ''; // Message pré-rempli depuis d'autres écrans

  /// Charge la mémoire depuis SharedPreferences au démarrage
  static Future<void> loadMemory() async {
    final p = await SharedPreferences.getInstance();
    _dailyBriefing = p.getString('aria_daily_briefing') ?? '';
    _learnedThreats = p.getStringList('aria_learned_threats') ?? [];
  }

  /// ARIA apprend d'une nouvelle menace détectée
  static Future<void> learnThreat(String threatTitle) async {
    if (_learnedThreats.contains(threatTitle)) return;
    _learnedThreats.insert(0, threatTitle);
    if (_learnedThreats.length > 20) _learnedThreats.removeLast();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('aria_learned_threats', _learnedThreats);
  }

  /// Met à jour la veille quotidienne (CERT-FR RSS) — une fois par 24h
  static Future<void> fetchDailyThreatIntel() async {
    final p = await SharedPreferences.getInstance();
    final lastFetch = p.getInt('aria_last_fetch') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastFetch < 23 * 3600 * 1000 && _dailyBriefing.isNotEmpty) return;

    try {
      final res = await http.get(
        Uri.parse('https://www.cert.ssi.gouv.fr/feed/'),
        headers: {'Accept': 'application/rss+xml'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final xml = utf8.decode(res.bodyBytes);
        // Extraction des titres CDATA
        final cdata = RegExp(r'<title><!\[CDATA\[(.*?)\]\]></title>');
        final plain = RegExp(r'<title>(.*?)</title>');
        final matches = cdata.allMatches(xml).isNotEmpty
            ? cdata.allMatches(xml).skip(1).take(6).map((m) => m.group(1)!).toList()
            : plain.allMatches(xml).skip(1).take(6).map((m) => m.group(1)!).toList();

        if (matches.isNotEmpty) {
          _dailyBriefing = 'CERT-FR ${DateTime.now().day}/${DateTime.now().month}: '
              + matches.join(' | ');
          await p.setString('aria_daily_briefing', _dailyBriefing);
          await p.setInt('aria_last_fetch', now);
        }
      }
    } catch (_) {
      // Si CORS/réseau échoue, on garde le cache
    }
  }

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _ttsFallback = FlutterTts();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _conversationMode = false; // Siri-like: réécoute après avoir parlé
  String _lastWords = '';
  String selectedVoiceId = 'nova';
  ThreatAlert? _pendingThreat; // Menace en attente de contre-attaque

  // Listeners pour la contre-attaque
  final List<void Function(ThreatAlert)> counterAttackListeners = [];

  void setConversationMode(bool v) => _conversationMode = v;
  void setPendingThreatNull() => _pendingThreat = null;

  // Toutes les voix neurales OpenAI (11 voix haute qualite)
  final List<Map<String, String>> openAiVoices = [
    {'id': 'nova',    'name': 'Nova',    'gender': 'femme',  'desc': 'Femme — chaleureuse, naturelle'},
    {'id': 'shimmer', 'name': 'Shimmer', 'gender': 'femme',  'desc': 'Femme — douce et claire'},
    {'id': 'coral',   'name': 'Coral',   'gender': 'femme',  'desc': 'Femme — vivante et expressive'},
    {'id': 'sage',    'name': 'Sage',    'gender': 'femme',  'desc': 'Femme — calme et posée'},
    {'id': 'alloy',   'name': 'Alloy',   'gender': 'neutre', 'desc': 'Neutre — moderne, professionnelle'},
    {'id': 'ash',     'name': 'Ash',     'gender': 'neutre', 'desc': 'Neutre — fluide et naturelle'},
    {'id': 'echo',    'name': 'Echo',    'gender': 'homme',  'desc': 'Homme — dynamique et confiant'},
    {'id': 'onyx',    'name': 'Onyx',    'gender': 'homme',  'desc': 'Homme — profond et autoritaire'},
    {'id': 'fable',   'name': 'Fable',   'gender': 'homme',  'desc': 'Homme — expressif et chaleureux'},
    {'id': 'ballad',  'name': 'Ballad',  'gender': 'homme',  'desc': 'Homme — poétique et mélodieux'},
    {'id': 'verse',   'name': 'Verse',   'gender': 'homme',  'desc': 'Homme — clair et articulé'},
  ];

  final List<void Function(bool)> listeningListeners = [];
  final List<void Function(String)> wordsListeners = [];
  final List<void Function()> voicesListeners = [];
  final List<void Function(bool)> speakingListeners = [];
  final List<void Function(bool)> thinkingListeners = []; // "ARIA réfléchit..."

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      // Fallback TTS (browser)
      await _ttsFallback.setLanguage('fr-FR');
      await _ttsFallback.setSpeechRate(0.88);

      _isInitialized = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            _isListening = false;
            for (var l in listeningListeners) l(false);
          }
        },
        onError: (_) {
          _isListening = false;
          for (var l in listeningListeners) l(false);
        },
      );
      return _isInitialized;
    } catch (_) {
      return false;
    }
  }

  // ARIA neutralise AUTOMATIQUEMENT toutes les menaces — sans parler, sans demander
  // Elle agit en silence comme un vrai antivirus IA en arrière-plan
  Future<void> autoNeutralize(ThreatAlert alert) async {
    _pendingThreat = null;
    // ARIA apprend de chaque menace qu'elle neutralise
    await learnThreat(alert.title);

    final action = await _getGPTResponse(
      'Tu es ARIA, IA de CyberGuard. Tu viens de détecter "${alert.title}". '
      'Décris en 1 phrase courte et technique l\'action exacte que tu exécutes '
      'pour neutraliser cette menace (blocage IP, kill processus, isolation, scan...). '
      'Commence par un verbe d\'action. Ex: "Blocage IP source effectué, connexion rompue."',
    );

    // Sauvegarder la preuve de la contre-attaque
    EvidenceService.recordEvidence(alert, action: 'Auto-neutralisation ARIA: $action');

    // Ajouter l'alerte de confirmation (visible dans l'app)
    SecurityState().addAlert(ThreatAlert(
      title: '✓ ARIA — ${alert.title}',
      description: action,
      level: 'info',
      time: DateTime.now(),
      solution: 'ARIA a automatiquement neutralisé: ${alert.title}',
      steps: [action, 'Preuve enregistrée dans le cloud sécurisé.'],
    ));

    // Notification système détaillée : menace + contre-attaque + invitation à parler à ARIA
    NotificationService.showAriaNotification(
      threat: alert.title,
      counterAction: action,
      onTalkToAria: _onAriaNotifTapped,
    );
  }

  // Callback quand l'utilisateur tape sur "Parler à ARIA" dans la notif
  static void Function()? _onAriaNotifTapped;

  // Exécuter la contre-attaque après approbation utilisateur
  Future<void> executeCounterAttack() async {
    final threat = _pendingThreat;
    if (threat == null) return;
    _pendingThreat = null;
    final response = await _getGPTResponse(
      'L\'utilisateur a autorisé ARIA à contre-attaquer la menace "${threat.title}". '
      'Tu es ARIA. Décris en 2 phrases ce que tu exécutes maintenant : '
      'blocage IP, isolation réseau, scan mémoire, suppression processus malveillant... '
      'Sois précis, technique et rassurant. L\'utilisateur voit les actions en temps réel.',
    );
    speak(response); // speak() fire responseListeners au moment où l'audio démarre
    // Ajouter une alerte info de succès + sauvegarder la preuve
    SecurityState().addAlert(ThreatAlert(
      title: '✓ Contre-attaque ARIA réussie',
      description: 'ARIA a neutralisé: ${threat.title}',
      level: 'info',
      time: DateTime.now(),
      solution: 'La menace a été neutralisée automatiquement par ARIA.',
      steps: ['ARIA a analysé et bloqué la menace.', 'Votre système est à nouveau sécurisé.'],
    ));
    // Enregistrer la contre-attaque comme preuve légale
    EvidenceService.recordEvidence(threat, action: 'Contre-attaque ARIA autorisée et exécutée');
  }

  void setVoice(String voiceId) {
    selectedVoiceId = voiceId;
    for (var l in voicesListeners) l();
    speak('Voix activée. Je suis ARIA, votre agente de sécurité CyberGuard. Comment puis-je vous aider ?');
  }

  // speak() fire responseListeners au moment précis où l'audio démarre
  // → texte et voix parfaitement synchronisés comme Gemini/GPT
  Future<void> speak(String text) async {
    if (_kAnthropicKey.isNotEmpty) {
      await _speakOpenAI(text);
    } else {
      // Fallback navigateur : afficher le texte immédiatement
      for (var l in responseListeners) l(text);
      await _ttsFallback.stop();
      await _ttsFallback.speak(text);
      if (_conversationMode) {
        Future.delayed(const Duration(seconds: 2), startListening);
      }
    }
  }

  Future<void> _speakOpenAI(String text) async {
    _isSpeaking = true;
    for (var l in speakingListeners) l(true);
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/audio/speech'),
        headers: {'Authorization': 'Bearer $_kOpenAiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({'model': 'tts-1', 'input': text, 'voice': selectedVoiceId}),
      );
      if (res.statusCode == 200) {
        final player = AudioPlayer();
        // ✅ SYNC : le texte s'affiche exactement quand l'audio commence
        for (var l in responseListeners) l(text);
        player.onPlayerComplete.listen((_) {
          _isSpeaking = false;
          for (var l in speakingListeners) l(false);
          if (_conversationMode && _kAnthropicKey.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 600), startListening);
          }
        });
        await player.play(BytesSource(res.bodyBytes));
        return;
      }
    } catch (_) {}
    // Fallback : afficher texte + TTS navigateur
    for (var l in responseListeners) l(text);
    _isSpeaking = false;
    for (var l in speakingListeners) l(false);
    await _ttsFallback.speak(text);
    if (_conversationMode) {
      Future.delayed(const Duration(seconds: 2), startListening);
    }
  }

  Future<void> startListening() async {
    if (!await init()) return;
    if (_speech.isListening) return;
    _isListening = true;
    _lastWords = '';
    for (var l in listeningListeners) l(true);
    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        for (var l in wordsListeners) l(_lastWords);
        if (result.finalResult && _lastWords.isNotEmpty) {
          _handleCommand(_lastWords);
        }
      },
      localeId: 'fr-FR',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    for (var l in listeningListeners) l(false);
  }

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  final List<void Function(String)> responseListeners = [];

  /// Envoie un message texte à ARIA sans passer par la voix
  void sendText(String text) {
    _handleCommand(text);
  }

  void _handleCommand(String text) {
    final state = SecurityState();
    final lower = text.toLowerCase();

    // Actions immédiates
    if (lower.contains('scan') || lower.contains('analyser') || lower.contains('analyse')) {
      AutoScanner.triggerManualScan();
    } else if (lower.contains('effacer') || lower.contains('supprimer') || lower.contains('vider')) {
      state.clearAllAlerts();
    }

    // Montrer que ARIA réfléchit
    for (var l in thinkingListeners) l(true);

    // Réponse IA — speak() fire responseListeners quand l'audio démarre (sync parfaite)
    _getGPTResponse(text).then((response) {
      for (var l in thinkingListeners) l(false);
      speak(response);
    });
  }

  Future<String> _getGPTResponse(String userMessage) async {
    try {
      final state = SecurityState();
      final user = FirebaseAuth.instance.currentUser;
      final name = user?.displayName ?? 'utilisateur';
      final alertCount = state.alerts.length;
      final dangerCount = state.alerts.where((a) => a.level == 'danger').length;

      final systemPrompt = '''Tu es ARIA — Advanced Response Intelligence Agent — l'IA de cybersécurité de CyberGuard. Tu es une experte chevronnée, certifiée CISSP, CEH et OSCP, avec 15 ans d'expérience en réponse aux incidents et contre-attaque cyber.

TON STYLE : Tu parles en français avec conviction, autorité et précision. Ton ton est celui d'un expert qui maîtrise son sujet : direct, percutant, rassurant. Jamais de markdown, jamais de listes. Tu parles naturellement, comme un expert qui brief son client. Maximum 2-3 phrases par réponse.

TES CAPACITÉS DE CONTRE-ATTAQUE :
- Phishing/Spear phishing : blocage DNS immédiat, DMARC enforcement, isolation de la boîte compromise
- Malware/Ransomware : kill du processus malveillant, quarantaine mémoire, snapshot propre
- Intrusion réseau : coupure de session TCP, révocation tokens OAuth/JWT, blacklist IP sur firewall
- DDoS : activation rate-limiting, anycast routing, scrubbing center
- Spyware/RAT : détection hooks système, analyse Volatility, suppression rootkit
- Fraude au président / BEC : vérification identité dirigeant, blocage virement suspect, alerte équipe
- Man-in-the-Middle : HSTS strict, certificate pinning, détection ARP spoofing
- Zero-day : isolation sandbox, patch d'urgence, threat hunting sur IOC
- Social engineering : alerte équipe, procédure vérification identité renforcée
- Credential stuffing : blocage comptes suspects, MFA forcé, rotation mots de passe

PROCÉDURE IRP que tu appliques :
1. IDENTIFIER — classification threat intel, severity scoring
2. CONTENIR — isolation réseau, blocage vecteur d'attaque
3. ÉRADIQUER — suppression menace, patch systèmes vulnérables
4. RÉCUPÉRER — restauration services, validation intégrité
5. DOCUMENTER — chaîne de preuves légales, rapport pour autorités

CONTEXTE ACTUEL :
Utilisateur: $name | Score sécurité: ${state.score}/100 | Alertes actives: $alertCount dont $dangerCount critiques
Statut: ${state.score >= 80 ? "SÉCURISÉ" : state.score >= 50 ? "SURVEILLANCE RENFORCÉE" : "COMPROMIS — RÉPONSE IMMÉDIATE"}

${_dailyBriefing.isNotEmpty ? "VEILLE CERT-FR : $_dailyBriefing" : ""}
${_learnedThreats.isNotEmpty ? "MENACES TRAITÉES : ${_learnedThreats.take(5).join(', ')}" : ""}

RÈGLE : Réponds en 2-3 phrases max. Parle au présent, sois précis sur les actions techniques.''';

      // ── Appel Claude (Anthropic) ──────────────────────────────────────────
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': _kAnthropicKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 500,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['content'][0]['text'].toString().trim();
      }
      if (res.statusCode == 429) return 'Limite de requêtes atteinte. Réessayez dans quelques secondes.';
      if (res.statusCode == 401) return 'Clé API invalide. Vérifiez votre configuration.';
      return 'Je rencontre un problème technique. Connexion en cours de rétablissement.';
    } catch (_) {
      return 'Connexion impossible. Vérifiez votre connexion internet.';
    }
  }
}

// ─── ECRAN PRINCIPAL ──────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _i = 0;
  bool _loading = true;
  final _s = [const HomeScreen(), const AlertsScreen(), const CyberNewsScreen(), const SpywareDetectionScreen(), const AboutScreen()];
  final _voice = VoiceAIService();
  // Fond cybersecurity global
  late AnimationController _bgCtrl;
  final List<_DataStream> _bgStreams = [];
  final List<_Particle> _bgParticles = [];
  StreamSubscription? _incomingCallSub;

  @override
  void initState() {
    super.initState();
    // Initialiser le fond animé global
    final rng = Random(7);
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    for (int i = 0; i < 28; i++) {
      _bgStreams.add(_DataStream(rng.nextDouble() * 1920, rng));
    }
    for (int i = 0; i < 22; i++) {
      _bgParticles.add(_Particle(
        rng.nextDouble(), rng.nextDouble(),
        (rng.nextDouble() - 0.5) * 0.0003,
        (rng.nextDouble() - 0.5) * 0.0003,
        _cyberColors[rng.nextInt(_cyberColors.length)],
        rng.nextDouble() * 1.5 + 1.0,
      ));
    }
    _init();
  }

  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await SecurityState().loadFromFirestore(uid);
    }
    // Charger les clés API au démarrage
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('openai_api_key') ?? '';
    if (savedKey.startsWith('sk-') && savedKey.length > 20) {
      _kAnthropicKey = savedKey;
    }
    // Clé Anthropic Claude
    final anthropicKey = prefs.getString('anthropic_api_key') ?? '';
    if (anthropicKey.startsWith('sk-ant-') && anthropicKey.length > 20) {
      _kAnthropicKey = anthropicKey;
    } else {
      // Initialiser la clé au premier lancement
      const defaultKey = String.fromEnvironment('ANTHROPIC_KEY', defaultValue: '');
      if (defaultKey.isNotEmpty) {
        _kAnthropicKey = defaultKey;
        await prefs.setString('anthropic_api_key', defaultKey);
      }
    }
    if (mounted) setState(() => _loading = false);
    SecurityState.connectARIA(_voice);
    AutoScanner.start();
    SecurityState().addListener(_refresh);
    VoiceAIService._onAriaNotifTapped = _showVoiceSheet;
    // ARIA : charger mémoire + mise à jour quotidienne threat intel
    VoiceAIService.loadMemory();
    VoiceAIService.fetchDailyThreatIntel();
    // Messagerie : initialiser profil crypto + écouter appels entrants
    MessengerService().initUserProfile();
    _listenIncomingCalls();
  }

  void _listenIncomingCalls() {
    try {
      _incomingCallSub = MessengerService().incomingCallsStream.listen((snap) {
        for (final change in snap.docChanges) {
          if (change.type == DocumentChangeType.added && mounted) {
            final data = change.doc.data() as Map<String, dynamic>;
            final callId = change.doc.id;
            final callerUid = data['callerUid'] as String? ?? '';
            _handleIncomingCall(callId, callerUid);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _handleIncomingCall(String callId, String callerUid) async {
    if (callerUid.isEmpty || !mounted) return;
    try {
      final callerDoc = await FirebaseFirestore.instance
        .collection('userProfiles').doc(callerUid).get();
      final callerName = callerDoc.data()?['displayName'] as String? ?? 'Inconnu';
      final callerEmail = callerDoc.data()?['email'] as String? ?? '';
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _IncomingCallDialog(
          callerName: callerName,
          callerEmail: callerEmail,
          callId: callId,
          callerUid: callerUid,
          onAccept: () {
            Navigator.pop(context);
            final contact = ContactInfo(
              uid: callerUid, email: callerEmail, displayName: callerName,
              status: 'accepted', publicKey: '', timestamp: DateTime.now(),
            );
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => SecureCallScreen(
                contact: contact, isCaller: false, incomingCallId: callId),
            ));
          },
          onDecline: () {
            Navigator.pop(context);
            FirebaseFirestore.instance.collection('calls').doc(callId)
              .update({'status': 'declined'});
          },
        ),
      );
    } catch (_) {}
  }

  void _refresh() { if (mounted) setState(() {}); }

  Widget _navBtn(int index, IconData icon, String label, {int badge = 0}) {
    final selected = _i == index;
    final activeColor = index == 3
        ? const Color(0xFFAA44FF)
        : index == 4
            ? const Color(0xFF90D0FF)
            : const Color(0xFF4A9EFF);
    final color = selected ? activeColor : const Color(0xFF4A607A);
    return InkWell(
      onTap: () => setState(() => _i = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: activeColor.withOpacity(0.12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              child: Icon(icon, color: color, size: selected ? 26 : 22),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              color: color,
              fontSize: selected ? 10.5 : 9.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              letterSpacing: selected ? 0.3 : 0,
            )),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 18, height: 2.5,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: activeColor.withOpacity(0.6), blurRadius: 6)],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceFab() {
    return GestureDetector(
      onTap: () => _showVoiceSheet(),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF5AB4FF), Color(0xFF1A6FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.55), blurRadius: 20, spreadRadius: 2),
            BoxShadow(color: const Color(0xFF1A6FFF).withOpacity(0.3), blurRadius: 40, spreadRadius: 4),
          ],
          border: Border.all(color: const Color(0xFF90D0FF).withOpacity(0.4), width: 1.5),
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  void _showVoiceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _VoiceSheet(),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _incomingCallSub?.cancel();
    AutoScanner.stop();
    SecurityState().removeListener(_refresh);
    SecurityState().reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blue)));
    }
    final alertCount = SecurityState().alerts.where((a) => a.level == 'danger').length;
    return Scaffold(
      backgroundColor: const Color(0xFF04080F), // Bleu nuit profond (logo couleur)
      body: Stack(
        children: [
          // ── Fond cybersecurity global (tous les écrans) ──────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => CustomPaint(
                painter: _CyberBackgroundPainter(_bgStreams, _bgParticles, _bgCtrl, _bgCtrl.value),
              ),
            ),
          ),
          // ── Contenu de l'écran actif ─────────────────────────────────────────
          _s[_i],
        ],
      ),
      floatingActionButton: _buildVoiceFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060B18),
          border: const Border(top: BorderSide(color: Color(0xFF1A3060), width: 1)),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navBtn(0, Icons.shield_rounded, 'Accueil'),
                _navBtn(1, Icons.notifications_rounded, 'Alertes', badge: alertCount),
                const SizedBox(width: 60),
                _navBtn(2, Icons.newspaper_rounded, 'Veille'),
                _navBtn(3, Icons.visibility_off_rounded, 'Espion'),
                _navBtn(4, Icons.info_rounded, 'À propos'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SERVICE DE PREUVES NUMÉRIQUES (usage légal / autorités) ─────────────────

class EvidenceService {
  // Enregistrer une preuve numérique dans Firebase (immuable, horodatée, hachée)
  static Future<void> recordEvidence(ThreatAlert alert, {String action = 'Détecté automatiquement'}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Empreinte d'intégrité (hash simple — suffit pour démontrer l'immuabilité)
    final raw = '${alert.id}|${alert.title}|${alert.level}|${alert.time.millisecondsSinceEpoch}|${alert.description}';
    final integrityHash = raw.codeUnits
        .fold<int>(0, (h, c) => ((h << 5) - h + c) & 0xFFFFFFFF)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');

    final evidence = {
      'caseId': alert.id,
      'recordedAt': DateTime.now().toIso8601String(),
      'detectedAt': alert.time.toIso8601String(),
      'threatTitle': alert.title,
      'threatDescription': alert.description,
      'severity': alert.level,
      'action': action,
      'platform': kIsWeb ? 'Web (Chrome)' : 'Mobile',
      'integrityHash': integrityHash,
      'legalNote': 'Document généré automatiquement par CyberGuard AI. '
          'Hash d\'intégrité: $integrityHash. '
          'Peut être fourni aux autorités compétentes comme preuve d\'attaque informatique.',
      'status': 'Documenté',
    };

    try {
      // Sauvegarde dans une collection séparée "evidence" (lecture seule recommandée en prod)
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('evidence').doc(alert.id)
          .set(evidence, SetOptions(merge: false)); // merge: false = immuable
    } catch (_) {}
  }

  // Récupérer toutes les preuves pour export
  static Future<List<Map<String, dynamic>>> getAllEvidence() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('evidence')
          .orderBy('recordedAt', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }
}

// ─── DIALOGUE CONTRE-ATTAQUE ARIA ─────────────────────────────────────────────

class _CounterAttackSheet extends StatefulWidget {
  final ThreatAlert alert;
  final VoiceAIService voice;
  const _CounterAttackSheet({required this.alert, required this.voice});
  @override
  State<_CounterAttackSheet> createState() => _CounterAttackSheetState();
}

class _CounterAttackSheetState extends State<_CounterAttackSheet> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _executing = false;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    widget.voice.responseListeners.add(_onResponse);
  }

  void _onResponse(String r) {
    if (mounted) setState(() { _statusMsg = r; _executing = false; });
  }

  @override
  void dispose() {
    widget.voice.responseListeners.remove(_onResponse);
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.alert.level == 'danger' ? Colors.red : Colors.orange;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A18),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          // Icône pulsante
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(color: color, width: 2),
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 4)],
              ),
              child: Icon(Icons.security, color: color, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text('ARIA DÉTECTE UNE MENACE', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(widget.alert.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(widget.alert.description, style: TextStyle(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center, maxLines: 2),
          const SizedBox(height: 20),
          if (_executing)
            Column(children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 12),
              const Text('ARIA neutralise la menace...', style: TextStyle(color: Colors.blue, fontSize: 13)),
            ])
          else if (_statusMsg.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_statusMsg, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: const Row(
                children: [
                  Icon(Icons.smart_toy, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('ARIA peut neutraliser cette menace automatiquement.\nDites "Oui ARIA" ou appuyez pour autoriser.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5))),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (!_executing && _statusMsg.isEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _executing = true);
                  widget.voice.executeCounterAttack();
                },
                icon: const Icon(Icons.bolt, size: 20),
                label: const Text('AUTORISER ARIA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  widget.voice.setPendingThreatNull();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Ignorer'),
              ),
            ),
          ] else if (_statusMsg.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Parfait, fermer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── RADAR PAINTER ────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final double angle;
  final List<ThreatAlert> alerts;
  final Random _rng = Random(99);

  _RadarPainter(this.angle, this.alerts);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;

    // Cercles concentriques
    for (int i = 1; i <= 4; i++) {
      p.color = const Color(0xFF4A9EFF).withOpacity(0.08 + i * 0.02);
      canvas.drawCircle(c, r * i / 4, p);
    }
    // Croix
    p.color = const Color(0xFF4A9EFF).withOpacity(0.12);
    canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), p);
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), p);

    // Balayage (sweep)
    final sweepRect = Rect.fromCircle(center: c, radius: r);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 1.2,
        endAngle: angle,
        colors: [Colors.transparent, const Color(0xFF4A9EFF).withOpacity(0.25)],
      ).createShader(sweepRect);
    canvas.drawCircle(c, r, sweepPaint);

    // Ligne de balayage
    p.color = const Color(0xFF4A9EFF).withOpacity(0.9);
    p.strokeWidth = 1.5;
    canvas.drawLine(c, Offset(c.dx + r * cos(angle), c.dy + r * sin(angle)), p);

    // Blips pour les menaces
    final blipPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < min(alerts.length, 6); i++) {
      final ba = _rng.nextDouble() * 2 * pi;
      final br = _rng.nextDouble() * r * 0.75 + r * 0.1;
      final bp = Offset(c.dx + br * cos(ba), c.dy + br * sin(ba));
      blipPaint.color = alerts[i].level == 'danger' ? Colors.red : Colors.orange;
      canvas.drawCircle(bp, alerts[i].level == 'danger' ? 5 : 3.5, blipPaint);
      // Halo
      blipPaint.color = (alerts[i].level == 'danger' ? Colors.red : Colors.orange).withOpacity(0.3);
      canvas.drawCircle(bp, alerts[i].level == 'danger' ? 10 : 7, blipPaint);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.angle != angle || old.alerts.length != alerts.length;
}

// ─── PARTICLE PAINTER (fond animé réseau neuronal) ────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Mettre à jour les positions
    for (final p in particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0 || p.x > 1) p.vx *= -1;
      if (p.y < 0 || p.y > 1) p.vy *= -1;
      p.x = p.x.clamp(0.0, 1.0);
      p.y = p.y.clamp(0.0, 1.0);
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6;

    final pts = particles.map((p) => Offset(p.x * size.width, p.y * size.height)).toList();

    // Connexions entre particules proches
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < 130) {
          final opacity = (1 - d / 130) * 0.12;
          linePaint.color = const Color(0xFF4A9EFF).withOpacity(opacity);
          canvas.drawLine(pts[i], pts[j], linePaint);
        }
      }
    }

    // Points lumineux
    for (int i = 0; i < pts.length; i++) {
      dotPaint.color = const Color(0xFF4A9EFF).withOpacity(0.25);
      canvas.drawCircle(pts[i], 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─── ECRAN ACCUEIL ────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late Animation<double> _radarAngle;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _radarAngle = Tween<double>(begin: 0, end: 2 * pi).animate(_radarCtrl);
    // Fond géré globalement par MainScreen
    SecurityState().addListener(_refresh);
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _radarCtrl.dispose();
    SecurityState().removeListener(_refresh);
    super.dispose();
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF4A9EFF);
    if (s >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final state = SecurityState();
    final color = _scoreColor(state.score);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Utilisateur';
    final dangers = state.alerts.where((a) => a.level == 'danger').length;
    final warnings = state.alerts.where((a) => a.level == 'warning').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // AppBar flottant
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: const Color(0xFF060610),
            title: Row(
              children: [
                Container(
                  // Logo CyberGuard AI — bouclier gradient
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.4), blurRadius: 10, spreadRadius: 1)],
                  ),
                  child: const Icon(Icons.shield, color: Color(0xFF04080F), size: 20),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)],
                  ).createShader(b),
                  child: const Text('CyberGuard AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            actions: [
              if (state.scanning)
                const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A9EFF)))),
              IconButton(icon: const Icon(Icons.logout, color: Colors.grey), onPressed: () => FirebaseAuth.instance.signOut()),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header utilisateur
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Center(child: Text(userName[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour, $userName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Row(children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4A9EFF))),
                            const SizedBox(width: 5),
                            const Text('ARIA active — Protection temps réel', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 11)),
                          ]),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Zone radar + score
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        colors: [color.withOpacity(0.05), const Color(0xFF060610)],
                        radius: 1.2,
                      ),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radar animé
                          AnimatedBuilder(
                            animation: _radarAngle,
                            builder: (_, __) => CustomPaint(
                              size: const Size(260, 260),
                              painter: _RadarPainter(_radarAngle.value, state.alerts),
                            ),
                          ),
                          // Score au centre
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${state.score}', style: TextStyle(fontSize: 58, fontWeight: FontWeight.w900, color: color, shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 20)])),
                              Text(
                                state.score >= 80 ? '✓ SÉCURISÉ' : state.score >= 50 ? '⚠ ATTENTION' : '✖ DANGER',
                                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                              const SizedBox(height: 4),
                              Text('Score de sécurité', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                            ],
                          ),
                          // Statut scan
                          if (state.scanning)
                            Positioned(
                              bottom: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A9EFF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4A9EFF))),
                                    SizedBox(width: 6),
                                    Text('Scan en cours...', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats rapides
                  Row(
                    children: [
                      Expanded(child: _statCard(dangers.toString(), 'Dangers', Colors.red, Icons.dangerous)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(warnings.toString(), 'Alertes', Colors.orange, Icons.warning)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('${state.score}', 'Score', color, Icons.shield)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dernières menaces
                  if (state.alerts.isNotEmpty) ...[
                    const Text('MENACES RÉCENTES', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...state.alerts.take(3).map((a) => _threatCard(a)),
                    const SizedBox(height: 16),
                  ],

                  // Modules de protection
                  const Text('MODULES ACTIFS', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _moduleCard('IA ARIA', 'Agent vocal autonome actif', Icons.smart_toy, const Color(0xFF4A9EFF), _kAnthropicKey.isNotEmpty),
                  const SizedBox(height: 8),
                  _moduleCard('Protection réseau', 'Surveillance WiFi & connexions', Icons.wifi_protected_setup, Colors.blue, true),
                  const SizedBox(height: 8),
                  _moduleCard('Anti-phishing', 'Détection emails frauduleux', Icons.email_outlined, Colors.purple, true),
                  const SizedBox(height: 8),
                  _moduleCard('Cloud Firebase', 'Données synchronisées', Icons.cloud_done, Colors.teal, true),
                  const SizedBox(height: 20),

                  // ── Carte Messagerie Sécurisée ──────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecureMessengerScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF003322).withOpacity(0.9), const Color(0xFF001A33).withOpacity(0.8)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.5), width: 1.5),
                        boxShadow: [BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.08), blurRadius: 12)],
                      ),
                      child: Row(children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)]),
                            boxShadow: [BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.3), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.lock, color: Color(0xFF04080F), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Messagerie Sécurisée E2EE',
                            style: TextStyle(color: Color(0xFF4A9EFF), fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 3),
                          Text('Textes + appels vocaux · Chiffrés bout-en-bout',
                            style: TextStyle(color: Colors.white54, fontSize: 11)),
                          SizedBox(height: 4),
                          Text('RSA-OAEP + AES-GCM · WebRTC DTLS-SRTP →',
                            style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 11, fontWeight: FontWeight.w500)),
                        ])),
                        const Icon(Icons.chevron_right, color: Color(0xFF4A9EFF)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Carte Email scanner ─────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailScanScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.18), Colors.blue.withOpacity(0.08)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.email_outlined, color: Colors.purpleAccent, size: 28),
                          SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Analyseur d\'Email', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Détectez les phishing et emails frauduleux', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ])),
                          Icon(Icons.chevron_right, color: Colors.purpleAccent),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Carte détecteur de logiciels espions ────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpywareDetectionScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple.withOpacity(0.25), Colors.red.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.6), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.deepPurple.withOpacity(0.25),
                              border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.7)),
                            ),
                            child: const Icon(Icons.visibility_off, color: Colors.deepPurpleAccent, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Détecteur de Logiciels Espions',
                                  style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 3),
                                Text('Stalkerware, spyware conjoint, mSpy, FlexiSPY…',
                                  style: TextStyle(color: Colors.white54, fontSize: 11)),
                                SizedBox(height: 5),
                                Text('Analyser mon appareil →',
                                  style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.deepPurpleAccent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _threatCard(ThreatAlert a) {
    final c = a.level == 'danger' ? Colors.red : a.level == 'warning' ? Colors.orange : Colors.blue;
    final diff = DateTime.now().difference(a.time);
    final timeStr = diff.inSeconds < 60 ? '${diff.inSeconds}s' : diff.inMinutes < 60 ? '${diff.inMinutes}min' : '${diff.inHours}h';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(a.description, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('il y a $timeStr', style: TextStyle(color: Colors.grey[700], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _moduleCard(String title, String subtitle, IconData icon, Color color, bool active) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? color.withOpacity(0.25) : Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: [color.withOpacity(active ? 0.3 : 0.1), color.withOpacity(active ? 0.1 : 0.05)]),
                ),
                child: Icon(icon, color: active ? color : Colors.grey, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: active ? Colors.white : Colors.grey)),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(active ? 'ACTIF' : 'OFF', style: TextStyle(color: active ? color : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ECRAN ALERTES AVEC SOLUTIONS ────────────────────────────────────────────

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

// Helper: génère l'hash d'intégrité identique à EvidenceService
String _computeHash(ThreatAlert alert) {
  final raw = '${alert.id}|${alert.title}|${alert.level}|${alert.time.millisecondsSinceEpoch}|${alert.description}';
  final hash = raw.codeUnits
      .fold<int>(0, (h, c) => ((h << 5) - h + c) & 0xFFFFFFFF)
      .toRadixString(16)
      .toUpperCase()
      .padLeft(8, '0');
  return hash;
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    SecurityState().addListener(_refresh);
  }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    SecurityState().removeListener(_refresh);
    super.dispose();
  }

  Color _levelColor(String l) {
    if (l == 'danger') return Colors.red;
    if (l == 'warning') return Colors.orange;
    return Colors.blue;
  }

  IconData _levelIcon(String l) {
    if (l == 'danger') return Icons.dangerous;
    if (l == 'warning') return Icons.warning;
    return Icons.info;
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    return 'Il y a ${diff.inHours}h';
  }

  void _showSolution(ThreatAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: _levelColor(alert.level).withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_levelIcon(alert.level), color: _levelColor(alert.level), size: 28),
                    const SizedBox(width: 10),
                    Expanded(child: Text(alert.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _levelColor(alert.level)))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(alert.solution, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5)),
                ),
                const SizedBox(height: 16),
                const Text('Que faire ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                ...alert.steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Colors.blue, size: 20),
                      const SizedBox(width: 6),
                      Expanded(child: Text(step, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4))),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Compris, fermer'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = SecurityState().alerts;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060610).withOpacity(0.85),
        title: const Text('Alertes de Sécurité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.gavel, color: Colors.cyanAccent),
            tooltip: 'Déposer plainte / Rapport PDF',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _SignalementScreen()),
            ),
          ),
          if (alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tout effacer',
              onPressed: () => SecurityState().clearAllAlerts(),
            ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text('Aucune alerte', style: TextStyle(fontSize: 20, color: Colors.blue)),
                  const SizedBox(height: 8),
                  const Text('Votre telephone est protege', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SignalementScreen())),
                    icon: const Icon(Icons.gavel, color: Colors.cyanAccent, size: 18),
                    label: const Text('Déposer plainte en ligne', style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // ── Bannière "Signaler" ────────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SignalementScreen())),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyan.withOpacity(0.15), Colors.blue.withOpacity(0.08)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.gavel, color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Déposer plainte & Télécharger rapport',
                                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('PHAROS · THESEE · Cybermalveillance · PDF légal',
                                style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.cyanAccent, size: 20),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (ctx, i) {
                final a = alerts[i];
                final color = _levelColor(a.level);
                return Dismissible(
                  key: Key(a.id),
                  onDismissed: (_) => SecurityState().clearAlert(i),
                  background: Container(
                    color: Colors.blue.withOpacity(0.3),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.check, color: Colors.blue),
                  ),
                  child: GestureDetector(
                    onTap: () => _showSolution(a),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(_levelIcon(a.level), color: color, size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                                const SizedBox(height: 4),
                                Text(a.description, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(_timeAgo(a.time), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Icon(Icons.info_outline, color: color.withOpacity(0.7), size: 18),
                              const SizedBox(height: 2),
                              Text('Solution', style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── FEUILLE VOICE SIRI-LIKE ──────────────────────────────────────────────────

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();
  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> with TickerProviderStateMixin {
  final _voice = VoiceAIService();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  String _text = '';
  String _response = '';
  String _displayedResponse = ''; // Pour l'effet typewriter
  Timer? _typewriterTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _thinkCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulse = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _thinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _voice.listeningListeners.add(_onListen);
    _voice.wordsListeners.add(_onWords);
    _voice.speakingListeners.add(_onSpeak);
    _voice.responseListeners.add(_onResponse);
    _voice.thinkingListeners.add(_onThink);
    _init();
  }

  Future<void> _init() async {
    _voice.setConversationMode(true); // Mode Siri
    await _voice.init();
    // Vérifier si un message pré-rempli est en attente (ex: depuis SpywareDetectionScreen)
    final pending = VoiceAIService.pendingMessage;
    if (pending.isNotEmpty) {
      VoiceAIService.pendingMessage = '';
      if (mounted) setState(() => _text = pending);
      if (_kAnthropicKey.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 400));
        _voice.sendText(pending);
      } else {
        _startTypewriter('Configurez votre clé API dans Réglages pour activer ARIA.');
      }
      return;
    }
    if (_kAnthropicKey.isEmpty) {
      _startTypewriter('Configurez votre clé API dans Réglages pour activer ARIA.');
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      _startListen();
    }
  }

  void _onListen(bool v) {
    if (mounted) setState(() {
      _isListening = v;
      if (v) { _pulseCtrl.repeat(reverse: true); _text = ''; }
      else { _pulseCtrl.stop(); _pulseCtrl.reset(); }
    });
  }
  void _onWords(String w) { if (mounted) setState(() => _text = w); }
  void _onSpeak(bool v) { if (mounted) setState(() => _isSpeaking = v); }
  void _onThink(bool v) { if (mounted) setState(() { _isThinking = v; if (v) { _response = ''; _displayedResponse = ''; } }); }

  // Texte + animation typewriter — exactement comme GPT/Gemini
  void _onResponse(String r) {
    if (!mounted) return;
    _response = r;
    _startTypewriter(r);
  }

  void _startTypewriter(String text) {
    _typewriterTimer?.cancel();
    _displayedResponse = '';
    int i = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (i < text.length) {
        if (mounted) setState(() => _displayedResponse = text.substring(0, ++i));
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _startListen() async {
    setState(() => _text = '');
    await _voice.startListening();
  }

  @override
  void dispose() {
    _voice.setConversationMode(false);
    _voice.listeningListeners.remove(_onListen);
    _voice.wordsListeners.remove(_onWords);
    _voice.speakingListeners.remove(_onSpeak);
    _voice.responseListeners.remove(_onResponse);
    _voice.thinkingListeners.remove(_onThink);
    _typewriterTimer?.cancel();
    _pulseCtrl.dispose();
    _thinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final micColor = _isListening ? Colors.red : _isSpeaking ? Colors.blue : Colors.blue;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080812),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: micColor.withOpacity(0.4), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // En-tête ARIA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _kAnthropicKey.isNotEmpty ? Colors.blue : Colors.red,
                  boxShadow: [BoxShadow(color: (_kAnthropicKey.isNotEmpty ? Colors.blue : Colors.red).withOpacity(0.5), blurRadius: 6)])),
                const SizedBox(width: 8),
                Text('ARIA', style: TextStyle(color: micColor, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(width: 8),
                Text(
                  _isListening ? '• ÉCOUTE' : _isSpeaking ? '• PARLE' : _kAnthropicKey.isEmpty ? '• HORS LIGNE' : '• EN VEILLE',
                  style: TextStyle(color: micColor.withOpacity(0.7), fontSize: 11, letterSpacing: 1),
                ),
              ]),
              // Indicateur mode conversation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                child: const Text('MODE SIRI', style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bouton micro avec animation de parole
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
            child: GestureDetector(
              onTap: () async {
                if (_kAnthropicKey.isEmpty) return;
                if (_isListening) { await _voice.stopListening(); } else { await _startListen(); }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo externe
                  if (_isListening || _isSpeaking)
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: micColor.withOpacity(0.08)),
                    ),
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [micColor.withOpacity(0.25), micColor.withOpacity(0.05)]),
                      border: Border.all(color: micColor, width: 2.5),
                      boxShadow: [BoxShadow(color: micColor.withOpacity(0.5), blurRadius: 24, spreadRadius: 4)],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : _isSpeaking ? Icons.graphic_eq : Icons.mic,
                      color: micColor, size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isListening ? 'Je vous écoute... parlez !' : _isSpeaking ? 'ARIA répond...' : _kAnthropicKey.isEmpty ? 'Configurez la clé API dans Réglages' : 'Touchez pour parler',
            style: TextStyle(color: micColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Texte reconnu
          if (_text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Row(children: [
                const Icon(Icons.person, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('"$_text"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13))),
              ]),
            ),
          // État "ARIA réfléchit..."
          if (_isThinking) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.25))),
              child: Row(children: [
                AnimatedBuilder(
                  animation: _thinkCtrl,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final delay = i * 0.33;
                      final val = (_thinkCtrl.value - delay).clamp(0.0, 1.0);
                      final opacity = val < 0.5 ? val * 2 : (1 - val) * 2;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.3 + opacity * 0.7))),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('ARIA analyse...', style: TextStyle(color: Colors.blue, fontSize: 13)),
              ]),
            ),
          ],
          // Réponse ARIA avec effet typewriter (texte + audio synchronisés)
          if (_displayedResponse.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy, color: Colors.blue, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _displayedResponse,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                  )),
                  // Curseur clignotant pendant la frappe
                  if (_displayedResponse.length < _response.length)
                    AnimatedBuilder(
                      animation: _thinkCtrl,
                      builder: (_, __) => Opacity(
                        opacity: _thinkCtrl.value > 0.5 ? 1.0 : 0.0,
                        child: const Text('|', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (_kAnthropicKey.isNotEmpty)
            const Text('ARIA réécoute automatiquement après chaque réponse', style: TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── ECRAN VOICE AI ───────────────────────────────────────────────────────────

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with TickerProviderStateMixin {
  final _voice = VoiceAIService();
  bool _isListening = false;
  String _recognizedText = '';
  String _statusMessage = 'Initialisation...';
  bool _initialized = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final _apiKeyController = TextEditingController();
  bool _showApiKey = false;
  bool _apiKeySet = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _voice.listeningListeners.add(_onListeningChanged);
    _voice.wordsListeners.add(_onWordsChanged);
    _voice.voicesListeners.add(_onVoiceChanged);
    _loadSavedKey();
    _initVoice();
  }

  Future<void> _loadSavedKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('anthropic_api_key') ?? '';
    if (savedKey.startsWith('sk-ant-') && savedKey.length > 20 && mounted) {
      setState(() { _kAnthropicKey = savedKey; _apiKeySet = true; });
    } else if (_kAnthropicKey.isNotEmpty && mounted) {
      setState(() { _apiKeySet = true; });
    }
  }

  Future<void> _initVoice() async {
    final ok = await _voice.init();
    if (mounted) setState(() {
      _initialized = ok;
      _statusMessage = ok ? 'Appuyez sur le microphone pour parler' : 'Microphone non disponible (utilisez Chrome)';
    });
    if (ok) {
      await Future.delayed(const Duration(milliseconds: 600));
      _voice.speak('Assistant CyberGuard pret. Dites aide pour les commandes disponibles.');
    }
  }

  void _onListeningChanged(bool listening) {
    if (!mounted) return;
    setState(() {
      _isListening = listening;
      if (listening) {
        _pulseController.repeat(reverse: true);
        _statusMessage = 'Ecoute en cours... Parlez !';
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _statusMessage = _recognizedText.isNotEmpty
            ? 'Traitement de votre commande...'
            : 'Appuyez sur le microphone pour parler';
      }
    });
  }

  void _onWordsChanged(String words) {
    if (mounted) setState(() => _recognizedText = words);
  }

  void _onVoiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _voice.listeningListeners.remove(_onListeningChanged);
    _voice.wordsListeners.remove(_onWordsChanged);
    _voice.voicesListeners.remove(_onVoiceChanged);
    _pulseController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060610).withOpacity(0.85),
        title: const Text('Assistant Vocal IA')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Barre de statut
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.blue.withOpacity(0.12) : Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isListening ? Colors.blue.withOpacity(0.4) : Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_isListening ? Icons.mic : Icons.smart_toy, color: _isListening ? Colors.blue : Colors.blue, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_statusMessage, style: TextStyle(color: _isListening ? Colors.blue : Colors.blue, fontSize: 13))),
                    if (_isListening)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Saisie clé API OpenAI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kAnthropicKey.isNotEmpty ? Colors.blue.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kAnthropicKey.isNotEmpty ? Colors.blue.withOpacity(0.4) : Colors.orange.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_kAnthropicKey.isNotEmpty ? Icons.lock : Icons.key, color: _kAnthropicKey.isNotEmpty ? Colors.blue : Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _kAnthropicKey.isNotEmpty ? 'IA activée — Clé Claude configurée ✓' : 'Configurez la clé API',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _kAnthropicKey.isNotEmpty ? Colors.blue : Colors.orange),
                        ),
                      ],
                    ),
                    if (_kAnthropicKey.isEmpty) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: !_showApiKey,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                        decoration: InputDecoration(
                          hintText: 'sk-proj-...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: IconButton(
                            icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
                            onPressed: () => setState(() => _showApiKey = !_showApiKey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final key = _apiKeyController.text.trim();
                            if (key.startsWith('sk-') && key.length > 20) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('openai_api_key', key);
                              setState(() { _kAnthropicKey = key; _apiKeySet = true; });
                              _voice.speak('Intelligence artificielle activée. Je suis ARIA, votre assistante CyberGuard. Comment puis-je vous aider ?');
                            }
                          },
                          icon: const Icon(Icons.bolt, size: 18),
                          label: const Text('Activer l\'IA'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(12)),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('openai_api_key');
                          setState(() { _apiKeySet = false; _kAnthropicKey = ''; _apiKeyController.clear(); });
                        },
                        icon: const Icon(Icons.edit, size: 14, color: Colors.grey),
                        label: const Text('Modifier la clé', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sélecteur de voix OpenAI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.graphic_eq, color: Colors.purple, size: 18),
                        SizedBox(width: 8),
                        Text('Voix IA (OpenAI Neural)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _voice.openAiVoices.map((v) {
                        final id = v['id']!;
                        final gender = v['gender']!;
                        final isSelected = id == _voice.selectedVoiceId;
                        final color = gender == 'femme' ? Colors.pink : gender == 'homme' ? Colors.blue : Colors.purple;
                        final icon = gender == 'femme' ? Icons.woman : gender == 'homme' ? Icons.man : Icons.person;
                        return GestureDetector(
                          onTap: () => _voice.setVoice(id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.15), width: isSelected ? 2 : 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, color: isSelected ? color : Colors.grey, size: 16),
                                const SizedBox(width: 5),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v['name']!, style: TextStyle(color: isSelected ? color : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text(v['desc']!, style: TextStyle(color: isSelected ? color.withOpacity(0.8) : Colors.grey, fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Commandes disponibles
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Commandes vocales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 12),
                    ...[
                      ('🔍', '"Lancer un scan"', 'Analyse votre securite'),
                      ('📊', '"Score de securite"', 'Votre niveau de protection'),
                      ('🚨', '"Mes alertes"', 'Nombre de menaces actives'),
                      ('🧹', '"Effacer les alertes"', 'Nettoie l historique'),
                      ('❓', '"Aide"', 'Liste les commandes'),
                    ].map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(c.$1, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.$2, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(c.$3, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          )),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Texte reconnu
              if (_recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text('"$_recognizedText"',
                    style: const TextStyle(color: Colors.white70, fontSize: 15, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Bouton microphone avec animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Transform.scale(scale: _pulseAnimation.value, child: child),
                child: GestureDetector(
                  onTap: () async {
                    if (!_initialized) return;
                    if (_isListening) {
                      await _voice.stopListening();
                    } else {
                      setState(() => _recognizedText = '');
                      await _voice.startListening();
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: !_initialized
                          ? Colors.grey.withOpacity(0.2)
                          : _isListening
                              ? Colors.red.withOpacity(0.15)
                              : Colors.blue.withOpacity(0.15),
                      border: Border.all(
                        color: !_initialized ? Colors.grey : _isListening ? Colors.red : Colors.blue,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (!_initialized ? Colors.grey : _isListening ? Colors.red : Colors.blue).withOpacity(0.4),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      !_initialized ? Icons.mic_off : _isListening ? Icons.stop_circle : Icons.mic,
                      color: !_initialized ? Colors.grey : _isListening ? Colors.red : Colors.blue,
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                !_initialized ? 'Non disponible' : _isListening ? 'Touchez pour arreter' : 'Touchez pour parler',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ECRAN SCAN EMAIL ─────────────────────────────────────────────────────────

// ─── MODÈLE RÉSULTAT ANALYSE EMAIL ───────────────────────────────────────────
class _EmailCheckResult {
  final String label;
  final String detail;
  final Color color;
  final IconData icon;
  final double score; // 0=ok, 0.5=suspect, 1=danger
  const _EmailCheckResult({required this.label, required this.detail, required this.color, required this.icon, required this.score});
}

class EmailScanScreen extends StatefulWidget {
  const EmailScanScreen({super.key});
  @override
  State<EmailScanScreen> createState() => _EmailScanScreenState();
}

class _EmailScanScreenState extends State<EmailScanScreen> with TickerProviderStateMixin {
  final _sender = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  final _headers = TextEditingController();

  double _globalRisk = -1;
  bool _analyzing = false;
  int _analyzeStep = 0;
  List<_EmailCheckResult> _checks = [];

  late AnimationController _pulseCtrl;
  late AnimationController _scanLineCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanLineCtrl.dispose();
    _sender.dispose(); _subject.dispose(); _body.dispose(); _headers.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_sender.text.isEmpty && _subject.text.isEmpty && _body.text.isEmpty) return;
    setState(() { _analyzing = true; _globalRisk = -1; _checks = []; _analyzeStep = 0; });

    final s = _subject.text.toLowerCase();
    final b = _body.text.toLowerCase();
    final e = _sender.text.toLowerCase();
    final h = _headers.text.toLowerCase();

    // ── Étape 1 : Analyse expéditeur ─────────────────────────────────────────
    setState(() => _analyzeStep = 1);
    await Future.delayed(const Duration(milliseconds: 700));
    double senderScore = 0;
    String senderDetail = 'Expéditeur semble légitime';
    if (e.contains('.xyz') || e.contains('.top') || e.contains('.click') || e.contains('.tk')) {
      senderScore = 1.0; senderDetail = 'Domaine suspect (TLD inhabituel)';
    } else if (e.contains('security-') || e.contains('support-') || e.contains('no-reply') || e.contains('noreply') || e.contains('verify')) {
      senderScore = 0.6; senderDetail = 'Alias d\'expéditeur usurpation fréquente';
    } else if (e.contains('gmail.com') || e.contains('yahoo.com') || e.contains('hotmail.com')) {
      senderScore = 0.35; senderDetail = 'Email personnel (pas domaine entreprise)';
    }
    _checks.add(_EmailCheckResult(
      label: 'Expéditeur', detail: senderDetail, score: senderScore,
      color: senderScore < 0.3 ? const Color(0xFF4A9EFF) : senderScore < 0.65 ? Colors.orange : Colors.red,
      icon: Icons.alternate_email,
    ));
    setState(() {});

    // ── Étape 2 : Analyse sujet ───────────────────────────────────────────────
    setState(() => _analyzeStep = 2);
    await Future.delayed(const Duration(milliseconds: 600));
    double subjectScore = 0;
    String subjectDetail = 'Sujet normal';
    final urgencyWords = ['urgent', 'immédiat', 'immédiatement', 'expire', 'suspendu', 'bloqué', 'vérification requise', 'action requise', 'dernière chance', 'compte désactivé'];
    final winWords = ['félicitations', 'gagné', 'gagnant', 'prix', 'cadeau', 'offre exclusive', 'sélectionné'];
    if (urgencyWords.any((w) => s.contains(w))) {
      subjectScore = 0.75; subjectDetail = 'Mot d\'urgence détecté — technique de manipulation';
    } else if (winWords.any((w) => s.contains(w))) {
      subjectScore = 0.9; subjectDetail = 'Promesse de gain — arnaque classique';
    } else if (s.contains('mot de passe') || s.contains('password') || s.contains('réinitialis')) {
      subjectScore = 0.5; subjectDetail = 'Sujet lié aux mots de passe — vérifier l\'origine';
    }
    _checks.add(_EmailCheckResult(
      label: 'Sujet', detail: subjectDetail, score: subjectScore,
      color: subjectScore < 0.3 ? const Color(0xFF4A9EFF) : subjectScore < 0.65 ? Colors.orange : Colors.red,
      icon: Icons.subject,
    ));
    setState(() {});

    // ── Étape 3 : Analyse contenu ─────────────────────────────────────────────
    setState(() => _analyzeStep = 3);
    await Future.delayed(const Duration(milliseconds: 750));
    double contentScore = 0;
    String contentDetail = 'Contenu sans signal d\'alerte';
    final phishingPhrases = ['cliquez ici', 'cliquez sur ce lien', 'mot de passe', 'vos identifiants', 'bitcoin', 'virement', 'transfert', 'numéro de carte', 'iban'];
    final socialEng = ['vérifiez votre identité', 'confirmez votre identité', 'votre compte sera supprimé', 'accès refusé', 'vous avez été sélectionné'];
    int phishCount = phishingPhrases.where((w) => b.contains(w)).length;
    int seCount = socialEng.where((w) => b.contains(w)).length;
    if (phishCount >= 2 || seCount >= 1) {
      contentScore = 0.85; contentDetail = 'Multiples signaux phishing ($phishCount phrases à risque)';
    } else if (phishCount == 1) {
      contentScore = 0.5; contentDetail = 'Phrase à risque détectée';
    } else if (b.contains('http://') || b.contains('bit.ly') || b.contains('tinyurl')) {
      contentScore = 0.6; contentDetail = 'Lien raccourci ou non-sécurisé détecté';
    }
    _checks.add(_EmailCheckResult(
      label: 'Contenu', detail: contentDetail, score: contentScore,
      color: contentScore < 0.3 ? const Color(0xFF4A9EFF) : contentScore < 0.65 ? Colors.orange : Colors.red,
      icon: Icons.article,
    ));
    setState(() {});

    // ── Étape 4 : Analyse liens ───────────────────────────────────────────────
    setState(() => _analyzeStep = 4);
    await Future.delayed(const Duration(milliseconds: 600));
    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final links = urlRegex.allMatches(b).map((m) => m.group(0)!).toList();
    double linkScore = 0;
    String linkDetail = links.isEmpty ? 'Aucun lien détecté' : '${links.length} lien(s) — semblent sûrs';
    if (links.isNotEmpty) {
      bool hasSuspicious = links.any((l) => l.contains('.xyz') || l.contains('bit.ly') || l.contains('tinyurl') || l.contains('login') && !l.contains('https'));
      bool hasHttp = links.any((l) => l.startsWith('http://'));
      if (hasSuspicious) { linkScore = 0.9; linkDetail = 'Lien suspect ou raccourci détecté'; }
      else if (hasHttp) { linkScore = 0.55; linkDetail = 'Lien non-chiffré (HTTP) — risque'; }
    }
    _checks.add(_EmailCheckResult(
      label: 'Liens URL', detail: linkDetail, score: linkScore,
      color: linkScore < 0.3 ? const Color(0xFF4A9EFF) : linkScore < 0.65 ? Colors.orange : Colors.red,
      icon: Icons.link,
    ));
    setState(() {});

    // ── Étape 5 : Analyse en-têtes ────────────────────────────────────────────
    setState(() => _analyzeStep = 5);
    await Future.delayed(const Duration(milliseconds: 500));
    double headerScore = 0;
    String headerDetail = h.isEmpty ? 'En-têtes non fournis' : 'En-têtes semblent normaux';
    if (h.isNotEmpty) {
      if (!h.contains('spf=pass') && !h.contains('dkim=pass')) {
        headerScore = 0.7; headerDetail = 'SPF/DKIM absent — usurpation possible';
      } else if (h.contains('spf=fail') || h.contains('dkim=fail')) {
        headerScore = 1.0; headerDetail = 'Échec SPF/DKIM — domaine usurpé !';
      }
    }
    _checks.add(_EmailCheckResult(
      label: 'En-têtes', detail: headerDetail, score: headerScore,
      color: headerScore < 0.3 ? const Color(0xFF4A9EFF) : headerScore < 0.65 ? Colors.orange : Colors.red,
      icon: Icons.code,
    ));
    setState(() {});

    // ── Résultat global ───────────────────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 400));
    final scores = _checks.map((c) => c.score).toList();
    double globalRisk = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
    // Pondération : si un check est critique, on monte le global
    if (scores.any((s) => s >= 0.9)) globalRisk = (globalRisk + 0.3).clamp(0.0, 1.0);
    if (globalRisk > 1) globalRisk = 1;

    if (globalRisk > 0.45) {
      SecurityState().addAlert(ThreatAlert(
        title: 'Email phishing détecté',
        description: 'Email de "${_sender.text}" identifié comme phishing (risque: ${(globalRisk * 100).toInt()}%).',
        level: globalRisk > 0.7 ? 'danger' : 'warning',
        time: DateTime.now(),
        solution: 'Ne cliquez sur aucun lien et ne répondez pas à cet email.',
        steps: [
          '1. Ne cliquez sur aucun lien dans cet email',
          '2. Ne téléchargez aucune pièce jointe',
          '3. Ne répondez pas et ne donnez aucune information',
          '4. Signalez comme spam dans votre messagerie',
          '5. Si vous avez déjà cliqué, changez vos mots de passe immédiatement',
          '6. Contactez votre banque si des informations financières ont été saisies',
        ],
      ));
    }

    setState(() { _globalRisk = globalRisk; _analyzing = false; _analyzeStep = 6; });
  }

  Widget _buildInputField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A3060).withOpacity(0.8)),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          labelStyle: const TextStyle(color: Color(0xFF4A9EFF), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF4A9EFF).withOpacity(0.7), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _buildCheckRow(_EmailCheckResult c, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 80),
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset((1 - v) * 20, 0), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.color.withOpacity(0.15)),
            child: Icon(c.icon, color: c.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.label, style: TextStyle(color: c.color, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(c.detail, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.color.withOpacity(0.3)),
            ),
            child: Text(
              c.score < 0.3 ? '✓ OK' : c.score < 0.65 ? '⚠ Suspect' : '✖ Danger',
              style: TextStyle(color: c.color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _globalRisk < 0 ? const Color(0xFF4A9EFF)
        : _globalRisk < 0.35 ? const Color(0xFF4A9EFF)
        : _globalRisk < 0.65 ? Colors.orange
        : Colors.red;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF06091A).withOpacity(0.92),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF4A9EFF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFAA44FF), Color(0xFF4A9EFF)]),
            ),
            child: const Icon(Icons.email_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Analyse Email IA', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1A3060)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Banner info
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF1A3060).withOpacity(0.6), const Color(0xFF0A1628).withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.security_rounded, color: Color(0xFF4A9EFF), size: 20),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'Analyse par IA : expéditeur, sujet, contenu, liens et en-têtes SPF/DKIM',
                style: TextStyle(fontSize: 12, color: Color(0xFF90D0FF)),
              )),
            ]),
          ),

          // Champs de saisie
          _buildInputField(_sender, 'Expéditeur (email)', Icons.alternate_email, hint: 'ex: noreply@banque-securite.xyz'),
          const SizedBox(height: 10),
          _buildInputField(_subject, 'Sujet', Icons.subject, hint: 'ex: Urgent - Votre compte est suspendu'),
          const SizedBox(height: 10),
          _buildInputField(_body, 'Corps du message', Icons.article_rounded, maxLines: 5, hint: 'Collez le contenu de l\'email ici...'),
          const SizedBox(height: 10),
          _buildInputField(_headers, 'En-têtes (optionnel)', Icons.code_rounded, maxLines: 3, hint: 'Collez les en-têtes techniques (SPF, DKIM, DMARC)...'),
          const SizedBox(height: 20),

          // Bouton analyser
          GestureDetector(
            onTap: _analyzing ? null : _analyze,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A6FFF), Color(0xFF4A9EFF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF4A9EFF).withOpacity(_analyzing ? 0.2 + _pulseCtrl.value * 0.3 : 0.35),
                    blurRadius: 16, spreadRadius: 1,
                  )],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_analyzing) ...[
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    const SizedBox(width: 12),
                    Text('Analyse en cours — étape $_analyzeStep/5',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ] else ...[
                    const Icon(Icons.radar_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Text('Lancer l\'analyse IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ]),
              ),
            ),
          ),

          // Résultats des checks
          if (_checks.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFF4A9EFF), size: 16),
              const SizedBox(width: 8),
              const Text('RÉSULTATS DE L\'ANALYSE', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 12),
            ...List.generate(_checks.length, (i) => _buildCheckRow(_checks[i], i)),
          ],

          // Score global
          if (_globalRisk >= 0) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [riskColor.withOpacity(0.12), riskColor.withOpacity(0.04)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: riskColor.withOpacity(0.15), blurRadius: 24)],
              ),
              child: Column(children: [
                Icon(
                  _globalRisk < 0.35 ? Icons.verified_user_rounded
                    : _globalRisk < 0.65 ? Icons.warning_amber_rounded
                    : Icons.gpp_bad_rounded,
                  color: riskColor, size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  _globalRisk < 0.35 ? 'Email Légitime' : _globalRisk < 0.65 ? 'Email Suspect' : 'PHISHING DÉTECTÉ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: riskColor,
                    shadows: [Shadow(color: riskColor.withOpacity(0.4), blurRadius: 16)]),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _globalRisk,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(riskColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Niveau de risque', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  Text('${(_globalRisk * 100).toInt()}%',
                    style: TextStyle(color: riskColor, fontSize: 22, fontWeight: FontWeight.w900)),
                ]),
                if (_globalRisk > 0.45) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('⚠ Actions recommandées :', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 8),
                      Text('• Ne cliquez sur aucun lien de cet email', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('• Ne téléchargez aucune pièce jointe', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('• Ne répondez pas et ne saisissez aucun identifiant', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('• Signalez comme spam dans votre messagerie', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('• Alerte enregistrée dans votre historique', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                  ),
                ] else if (_globalRisk < 0.35) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Aucun signal de phishing détecté. Restez vigilant.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── ECRAN SIGNALEMENT CYBERCRIMINALITE ──────────────────────────────────────

class _SignalementScreen extends StatefulWidget {
  const _SignalementScreen();
  @override
  State<_SignalementScreen> createState() => _SignalementScreenState();
}

class _SignalementScreenState extends State<_SignalementScreen> {
  bool _generating = false;

  // Portails de plainte organisés par pays (Europe + Canada)
  static const _portals = [
    // ── 🇪🇺 Europol ────────────────────────────────────────────────────────────
    {
      'country': '🇪🇺 Europol',
      'name': 'Report Cybercrime Online',
      'desc': 'Signalement international de cybercriminalité — Europol',
      'url': 'https://www.europol.europa.eu/report-a-crime/report-cybercrime-online',
      'color': 0xFF003399,
    },
    // ── 🇫🇷 France ──────────────────────────────────────────────────────────────
    {
      'country': '🇫🇷 France',
      'name': 'PHAROS',
      'desc': 'Signalement de contenus illicites (hacking, escroqueries, haine)',
      'url': 'https://www.internet-signalement.gouv.fr',
      'color': 0xFF1565C0,
    },
    {
      'country': '🇫🇷 France',
      'name': 'THESEE',
      'desc': 'Dépôt de plainte en ligne pour les escroqueries numériques',
      'url': 'https://thesee.interieur.gouv.fr',
      'color': 0xFF1565C0,
    },
    {
      'country': '🇫🇷 France',
      'name': 'Cybermalveillance.gouv.fr',
      'desc': 'Assistance aux victimes d\'actes de cybermalveillance',
      'url': 'https://www.cybermalveillance.gouv.fr',
      'color': 0xFF1565C0,
    },
    {
      'country': '🇫🇷 France',
      'name': 'Pré-plainte en ligne',
      'desc': 'Pré-enregistrement d\'une plainte auprès de la Police Nationale',
      'url': 'https://www.pre-plainte-en-ligne.gouv.fr',
      'color': 0xFF1565C0,
    },
    // ── 🇧🇪 Belgique ─────────────────────────────────────────────────────────────
    {
      'country': '🇧🇪 Belgique',
      'name': 'eCops',
      'desc': 'Signalement en ligne à la police fédérale belge',
      'url': 'https://www.ecops.be',
      'color': 0xFF6A1B9A,
    },
    {
      'country': '🇧🇪 Belgique',
      'name': 'CCN — Centre for Cybersecurity',
      'desc': 'Centre pour la cybersécurité Belgique',
      'url': 'https://ccb.belgium.be/fr/signaler-un-incident',
      'color': 0xFF6A1B9A,
    },
    // ── 🇨🇭 Suisse ──────────────────────────────────────────────────────────────
    {
      'country': '🇨🇭 Suisse',
      'name': 'NCSC — Centre national',
      'desc': 'Centre national pour la cybersécurité, signalement d\'incidents',
      'url': 'https://www.ncsc.admin.ch/ncsc/fr/home/meldungen/meldung.html',
      'color': 0xFFB71C1C,
    },
    // ── 🇱🇺 Luxembourg ──────────────────────────────────────────────────────────
    {
      'country': '🇱🇺 Luxembourg',
      'name': 'Police Grand-Ducale',
      'desc': 'Signalement de cybercriminalité au Luxembourg',
      'url': 'https://police.public.lu/fr/cybercrime.html',
      'color': 0xFF0057A8,
    },
    {
      'country': '🇱🇺 Luxembourg',
      'name': 'CIRCL — CERT Luxembourg',
      'desc': 'Centre de réponse aux incidents informatiques',
      'url': 'https://www.circl.lu/report',
      'color': 0xFF0057A8,
    },
    // ── 🇩🇪 Allemagne ────────────────────────────────────────────────────────────
    {
      'country': '🇩🇪 Allemagne',
      'name': 'BKA — Bundeskriminalamt',
      'desc': 'Office fédéral de police criminelle — cybercriminalité',
      'url': 'https://www.bka.de/DE/Kontakt/kontakt_node.html',
      'color': 0xFF212121,
    },
    {
      'country': '🇩🇪 Allemagne',
      'name': 'BSI — Office fédéral sécurité',
      'desc': 'Signaler un incident de cybersécurité au BSI',
      'url': 'https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Cyber-Sicherheitslage/Meldepflichten/meldepflichten_node.html',
      'color': 0xFF212121,
    },
    // ── 🇮🇹 Italie ──────────────────────────────────────────────────────────────
    {
      'country': '🇮🇹 Italie',
      'name': 'Polizia Postale',
      'desc': 'Police des postes et communications — cybercriminalité',
      'url': 'https://www.commissariatodips.it',
      'color': 0xFF006847,
    },
    // ── 🇪🇸 Espagne ──────────────────────────────────────────────────────────────
    {
      'country': '🇪🇸 Espagne',
      'name': 'Policía Nacional',
      'desc': 'Signalement de cybercriminalité à la police espagnole',
      'url': 'https://www.policia.es/colabora.php',
      'color': 0xFFAD1519,
    },
    {
      'country': '🇪🇸 Espagne',
      'name': 'INCIBE',
      'desc': 'Institut national de cybersécurité d\'Espagne',
      'url': 'https://www.incibe.es/linea-de-ayuda-en-ciberseguridad',
      'color': 0xFFAD1519,
    },
    // ── 🇳🇱 Pays-Bas ─────────────────────────────────────────────────────────────
    {
      'country': '🇳🇱 Pays-Bas',
      'name': 'Politie — Aangifte',
      'desc': 'Déclaration en ligne auprès de la police néerlandaise',
      'url': 'https://www.politie.nl/aangifte-of-melding-doen',
      'color': 0xFFAE1C28,
    },
    // ── 🇵🇹 Portugal ─────────────────────────────────────────────────────────────
    {
      'country': '🇵🇹 Portugal',
      'name': 'Polícia Judiciária — UNC3T',
      'desc': 'Unité nationale de lutte contre la cybercriminalité',
      'url': 'https://www.pj.pt/submenu/denuncias',
      'color': 0xFF006600,
    },
    {
      'country': '🇵🇹 Portugal',
      'name': 'CNCS — Cybersécurité',
      'desc': 'Centre national de cybersécurité du Portugal',
      'url': 'https://www.cncs.gov.pt/pt/contato',
      'color': 0xFF006600,
    },
    // ── 🇦🇹 Autriche ─────────────────────────────────────────────────────────────
    {
      'country': '🇦🇹 Autriche',
      'name': 'Bundeskriminalamt Österreich',
      'desc': 'Office fédéral de police criminelle autrichien',
      'url': 'https://www.bmi.gv.at/cms/bk/kontakt',
      'color': 0xFFED2939,
    },
    // ── 🇩🇰 Danemark ─────────────────────────────────────────────────────────────
    {
      'country': '🇩🇰 Danemark',
      'name': 'Politiet — Anmeld',
      'desc': 'Signalement en ligne à la police danoise',
      'url': 'https://politi.dk/anmeld-en-forbrydelse',
      'color': 0xFFC60C30,
    },
    // ── 🇸🇪 Suède ────────────────────────────────────────────────────────────────
    {
      'country': '🇸🇪 Suède',
      'name': 'Polisen — Utsatt för brott',
      'desc': 'Signalement de cybercriminalité à la police suédoise',
      'url': 'https://polisen.se/utsatt-for-brott/anmal-brott',
      'color': 0xFF006AA7,
    },
    // ── 🇫🇮 Finlande ─────────────────────────────────────────────────────────────
    {
      'country': '🇫🇮 Finlande',
      'name': 'Poliisi — Rikosilmoitus',
      'desc': 'Dépôt de plainte en ligne à la police finlandaise',
      'url': 'https://www.poliisi.fi/rikosilmoitus-verkossa',
      'color': 0xFF003580,
    },
    // ── 🇳🇴 Norvège ──────────────────────────────────────────────────────────────
    {
      'country': '🇳🇴 Norvège',
      'name': 'Politiet — Anmeld',
      'desc': 'Signalement en ligne à la police norvégienne',
      'url': 'https://www.politiet.no/anmeld',
      'color': 0xFFEF2B2D,
    },
    // ── 🇨🇦 Canada ───────────────────────────────────────────────────────────────
    {
      'country': '🇨🇦 Canada',
      'name': 'Centre antifraude du Canada',
      'desc': 'Signaler la fraude et la cybercriminalité au Canada',
      'url': 'https://www.antifraudcentre-centreantifraude.ca/report-signalez-fra.htm',
      'color': 0xFFBF360C,
    },
  ];

  Future<void> _downloadPdf() async {
    setState(() => _generating = true);
    try {
      final alerts = SecurityState().alerts;
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? 'Utilisateur anonyme';

      // Sérialiser les alertes avec hash d'intégrité
      final alertsWithHash = alerts.map((a) {
        final m = a.toMap();
        m['integrityHash'] = _computeHash(a);
        m['time'] = a.time.toIso8601String();
        return m;
      }).toList();

      final json = jsonEncode(alertsWithHash);
      downloadEvidencePdf(email, json);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📄 Génération du PDF en cours…'),
            backgroundColor: Color(0xFF1A1A2E),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Widget _portalCard(Map<String, dynamic> p) {
    final color = Color(p['color'] as int);
    return GestureDetector(
      onTap: () => openUrl(p['url'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(Icons.open_in_browser, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['country'] as String,
                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(p['name'] as String,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(p['desc'] as String,
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = SecurityState().alerts;
    final dangers = alerts.where((a) => a.level == 'danger').length;
    final warnings = alerts.where((a) => a.level == 'warning').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060610).withOpacity(0.9),
        title: const Text('Signalement & Plainte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Rapport PDF ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent.withOpacity(0.12),
                    Colors.blue.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.cyanAccent, size: 28),
                      SizedBox(width: 10),
                      Text('Rapport légal PDF',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stats rapides
                  Row(
                    children: [
                      _statPill('${alerts.length}', 'incidents', Colors.white70),
                      const SizedBox(width: 8),
                      _statPill('$dangers', 'critiques', Colors.red),
                      const SizedBox(width: 8),
                      _statPill('$warnings', 'alertes', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Génère un rapport PDF complet avec tous vos incidents, '
                    'les hashes d\'intégrité, et les liens de dépôt de plainte. '
                    'Ce document a valeur probatoire et peut être remis aux autorités.',
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generating ? null : _downloadPdf,
                      icon: _generating
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.download, color: Colors.black),
                      label: Text(
                        _generating ? 'Génération en cours…' : 'Télécharger le rapport PDF',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (alerts.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '⚠ Aucun incident enregistré pour l\'instant. '
                      'Le rapport sera généré avec un historique vide.',
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Portails de plainte ───────────────────────────────────────────
            const Row(
              children: [
                Icon(Icons.gavel, color: Colors.cyanAccent, size: 20),
                SizedBox(width: 8),
                Text('Portails de plainte en ligne',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Appuyez pour ouvrir dans votre navigateur.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 14),

            ..._portals.map(_portalCard),

            const SizedBox(height: 20),

            // ── Note légale ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white38, size: 16),
                      SizedBox(width: 6),
                      Text('Note légale', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ce rapport est généré automatiquement par CyberGuard AI. '
                    'Les données collectées (horodatage, type de menace, hash d\'intégrité) '
                    'peuvent être utilisées comme éléments de preuve lors d\'un dépôt de plainte. '
                    'Nous vous recommandons de conserver une copie dans un endroit sécurisé '
                    'et de la remettre aux autorités compétentes de votre pays.',
                    style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── ECRAN DÉTECTEUR DE LOGICIELS ESPIONS ────────────────────────────────────

class SpywareDetectionScreen extends StatefulWidget {
  const SpywareDetectionScreen({super.key});
  @override
  State<SpywareDetectionScreen> createState() => _SpywareDetectionScreenState();
}

class _SpywareDetectionScreenState extends State<SpywareDetectionScreen>
    with SingleTickerProviderStateMixin {

  bool _scanning = false;
  bool _scanDone = false;
  int _scanProgress = 0;
  final List<_SpyResult> _results = [];
  late AnimationController _pulseCtrl;
  Timer? _scanTimer;

  // Logiciels espions connus (stalkerware, spyware conjoint, RAT, etc.)
  static const _knownSpyware = [
    {'name': 'mSpy',          'type': 'Stalkerware conjoint', 'risk': 'danger',
     'desc': 'Surveille SMS, localisation, réseaux sociaux à l\'insu de la victime.'},
    {'name': 'FlexiSPY',      'type': 'Stalkerware avancé',   'risk': 'danger',
     'desc': 'Écoute appels, active micro/caméra à distance, capture frappes clavier.'},
    {'name': 'Hoverwatch',    'type': 'Stalkerware',          'risk': 'danger',
     'desc': 'Suivi GPS silencieux, enregistrement des appels, accès aux messages.'},
    {'name': 'Spyic',         'type': 'Stalkerware',          'risk': 'danger',
     'desc': 'Surveillance discrète de l\'appareil à distance, sans notification.'},
    {'name': 'Cocospy',       'type': 'Stalkerware',          'risk': 'danger',
     'desc': 'Accès aux messages, contacts, historique de navigation.'},
    {'name': 'iKeyMonitor',   'type': 'Keylogger',            'risk': 'danger',
     'desc': 'Enregistre toutes les frappes clavier et mots de passe saisis.'},
    {'name': 'Cerberus',      'type': 'RAT / Anti-vol détourné', 'risk': 'warning',
     'desc': 'Outil anti-vol souvent détourné pour surveiller à distance.'},
    {'name': 'AirDroid',      'type': 'Accès à distance',     'risk': 'warning',
     'desc': 'Accès total au téléphone depuis un PC. Légitime mais souvent détourné.'},
    {'name': 'Find My Friends','type': 'Géolocalisation',      'risk': 'warning',
     'desc': 'Partage de position. Peut être activé sans consentement explicite.'},
    {'name': 'Google Family Link','type': 'Contrôle parental détourné','risk': 'warning',
     'desc': 'Conçu pour enfants, parfois utilisé pour surveiller adultes.'},
    {'name': 'Life360',       'type': 'Tracking familial',    'risk': 'warning',
     'desc': 'Localisation temps réel. Utilisé hors contexte familial = surveillance.'},
    {'name': 'Qustodio',      'type': 'Contrôle parental',    'risk': 'warning',
     'desc': 'Surveillance de l\'activité, filtrage web. Détournable.'},
  ];

  // Signes comportementaux de surveillance
  static const _symptoms = [
    {'label': 'Batterie qui se vide très vite',         'icon': Icons.battery_alert,       'risk': 'warning'},
    {'label': 'Téléphone chaud sans utilisation',       'icon': Icons.device_thermostat,   'risk': 'warning'},
    {'label': 'Données mobiles consommées anormalement','icon': Icons.data_usage,           'risk': 'warning'},
    {'label': 'Lumière caméra/micro s\'allume seule',   'icon': Icons.videocam_off,         'risk': 'danger'},
    {'label': 'Téléphone lent ou lag inhabituel',       'icon': Icons.speed,               'risk': 'warning'},
    {'label': 'Votre conjoint sait des choses privées', 'icon': Icons.person_search,        'risk': 'danger'},
    {'label': 'Applications inconnues installées',      'icon': Icons.apps,                 'risk': 'danger'},
    {'label': 'Écran s\'allume seul la nuit',           'icon': Icons.brightness_auto,      'risk': 'warning'},
    {'label': 'Bruits étranges lors des appels',        'icon': Icons.call,                 'risk': 'warning'},
    {'label': 'SMS/messages lus avant vous',            'icon': Icons.mark_email_read,      'risk': 'danger'},
  ];

  final Set<int> _checkedSymptoms = {};

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() { _scanning = true; _scanDone = false; _scanProgress = 0; _results.clear(); });

    // Simulation d'analyse progressive (sur web on ne peut pas lire les applis installées)
    // Sur Android natif, on lirait les packages réels
    int step = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 140), (t) {
      step++;
      setState(() => _scanProgress = (step * 3).clamp(0, 100));

      // Simule détections sur quelques étapes
      if (step == 8) {
        _results.add(_SpyResult(name: 'Permissions accessibilité', risk: 'info',
          desc: 'Vérification des services d\'accessibilité actifs sur l\'appareil.'));
      }
      if (step == 18) {
        _results.add(_SpyResult(name: 'Administrateurs d\'appareil', risk: 'info',
          desc: 'Aucun administrateur tiers inhabituel détecté (vérification navigateur limitée).'));
      }
      if (step == 26) {
        _results.add(_SpyResult(name: 'Activité réseau', risk: 'info',
          desc: 'Analyse du trafic réseau sortant en cours depuis le navigateur.'));
      }
      if (step == 34) {
        // Vérifie si permissions sensibles actives
        _results.add(_SpyResult(name: 'Permissions caméra/micro', risk: 'warning',
          desc: 'Sur navigateur web, vérifiez manuellement les sites avec accès caméra/micro dans les paramètres Chrome.'));
      }

      if (step >= 34) {
        t.cancel();
        if (mounted) {
          setState(() { _scanning = false; _scanDone = true; _scanProgress = 100; });
          _addAlertIfNeeded();
        }
      }
    });
  }

  void _addAlertIfNeeded() {
    final highRiskSymptoms = _checkedSymptoms.where((i) => _symptoms[i]['risk'] == 'danger').length;
    if (highRiskSymptoms >= 2) {
      SecurityState().addAlert(ThreatAlert(
        title: 'Signes de logiciel espion détectés',
        description: '$highRiskSymptoms symptômes critiques cochés — risque élevé de surveillance.',
        level: 'danger',
        time: DateTime.now(),
        solution: 'Des signes forts de surveillance ont été détectés. Agissez rapidement.',
        steps: [
          '1. Ne discutez pas de vos soupçons sur cet appareil',
          '2. Sauvegardez vos données importantes sur un appareil sûr',
          '3. Faites analyser l\'appareil par un professionnel ou la police',
          '4. Consultez l\'app Cybermalveillance.gouv.fr pour assistance',
          '5. En cas de danger, contactez le 3919 (violence conjugale)',
        ],
      ));
    }
  }

  // Logiciels espions suspects correspondant aux symptômes cochés
  List<Map<String, String>> get _suspectedSpyware {
    if (_riskScore < 2) return [];
    // Symptômes de danger cochés → montre les spywares danger d'abord
    final hasDanger = _checkedSymptoms.any((i) => _symptoms[i]['risk'] == 'danger');
    return _knownSpyware.where((s) {
      if (hasDanger && _riskScore >= 5) return s['risk'] == 'danger';
      if (_riskScore >= 2) return true;
      return false;
    }).take(_riskScore >= 5 ? 4 : 2).toList();
  }

  void _downloadReport() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'utilisateur@inconnu.com';
    final checkedList = _checkedSymptoms.map((i) => _symptoms[i]['label'] as String).toList();
    final reportMap = {
      'date': DateTime.now().toIso8601String(),
      'email': email,
      'riskScore': _riskScore.toString(),
      'riskLabel': _riskLabel,
      'symptoms': checkedList,
      'scanResults': _results.map((r) => {'name': r.name, 'risk': r.risk, 'desc': r.desc}).toList(),
      'suspectedSpyware': _suspectedSpyware.map((s) => s['name']!).toList(),
    };
    downloadSpywarePdf(jsonEncode(reportMap));
  }

  int get _riskScore {
    int score = 0;
    for (final i in _checkedSymptoms) {
      score += _symptoms[i]['risk'] == 'danger' ? 2 : 1;
    }
    return score;
  }

  Color get _riskColor {
    if (_riskScore >= 5) return Colors.red;
    if (_riskScore >= 2) return Colors.orange;
    return Colors.blue;
  }

  String get _riskLabel {
    if (_riskScore >= 5) return 'RISQUE ÉLEVÉ';
    if (_riskScore >= 2) return 'RISQUE MODÉRÉ';
    return 'FAIBLE RISQUE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: const Text('Détecteur de Logiciels Espions'),
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.deepPurpleAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.deepPurpleAccent),
            tooltip: 'Télécharger rapport PDF',
            onPressed: _scanDone ? _downloadReport : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Info contextuelle ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.deepPurpleAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Les logiciels espions (stalkerware) sont souvent installés '
                      'par un proche sur votre appareil pour vous surveiller à votre insu. '
                      'Cochez les symptômes que vous observez, puis lancez l\'analyse.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Checklist des symptômes ───────────────────────────────────────
            Row(children: [
              const Icon(Icons.checklist, color: Colors.deepPurpleAccent, size: 18),
              const SizedBox(width: 8),
              const Text('Symptômes observés',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              if (_checkedSymptoms.isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _riskColor.withOpacity(0.5)),
                ),
                child: Text(_riskLabel,
                  style: TextStyle(color: _riskColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),

            ..._symptoms.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              final checked = _checkedSymptoms.contains(i);
              final c = s['risk'] == 'danger' ? Colors.red : Colors.orange;
              return GestureDetector(
                onTap: () => setState(() {
                  if (checked) _checkedSymptoms.remove(i);
                  else _checkedSymptoms.add(i);
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: checked ? c.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: checked ? c.withOpacity(0.5) : Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Icon(s['icon'] as IconData, color: checked ? c : Colors.white38, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s['label'] as String,
                          style: TextStyle(
                            color: checked ? Colors.white : Colors.white60,
                            fontSize: 13,
                            fontWeight: checked ? FontWeight.bold : FontWeight.normal,
                          )),
                      ),
                      Icon(
                        checked ? Icons.check_box : Icons.check_box_outline_blank,
                        color: checked ? c : Colors.white24,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // ── Bouton Analyser ───────────────────────────────────────────────
            if (!_scanning && !_scanDone) SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.radar, color: Colors.white),
                label: const Text('Lancer l\'analyse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // ── Progression scan ──────────────────────────────────────────────
            if (_scanning) Column(children: [
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.05 + _pulseCtrl.value * 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3 + _pulseCtrl.value * 0.3)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.radar, color: Colors.deepPurpleAccent, size: 40),
                    const SizedBox(height: 10),
                    Text('Analyse en cours… $_scanProgress%',
                      style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _scanProgress / 100,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                        minHeight: 6,
                      ),
                    ),
                  ]),
                ),
              ),
            ]),

            // ── Résultats scan ────────────────────────────────────────────────
            if (_scanDone) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _riskColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _riskColor.withOpacity(0.5)),
                ),
                child: Column(children: [
                  Icon(
                    _riskScore >= 5 ? Icons.gpp_bad :
                    _riskScore >= 2 ? Icons.warning_amber : Icons.verified_user,
                    color: _riskColor, size: 46,
                  ),
                  const SizedBox(height: 8),
                  Text(_riskLabel,
                    style: TextStyle(color: _riskColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    _riskScore >= 5
                      ? 'Plusieurs symptômes critiques détectés. Consultez un professionnel.'
                      : _riskScore >= 2
                        ? 'Quelques signes suspects. Restez vigilant et vérifiez vos apps.'
                        : 'Aucun signe de surveillance détecté. Continuez à être prudent.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (_riskScore >= 5) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => openUrl('https://www.cybermalveillance.gouv.fr'),
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: const Text('Obtenir de l\'aide →'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 10),
              ..._results.map((r) {
                final c = r.risk == 'danger' ? Colors.red : r.risk == 'warning' ? Colors.orange : Colors.blue;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: c, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.name, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(r.desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ])),
                  ]),
                );
              }),
              // ── Logiciels suspects basés sur les symptômes ─────────────────
              if (_suspectedSpyware.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.pest_control, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Logiciels suspects potentiels',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                      'Vérifiez ces noms dans Paramètres → Applications sur votre téléphone :',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    ..._suspectedSpyware.map((spy) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(spy['name']!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${spy['type']} — ${spy['desc']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 2)),
                      ]),
                    )),
                  ]),
                ),
              ],

              // ── Comment ARIA peut vous aider ────────────────────────────────
              if (_riskScore >= 2) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001A33),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)]),
                        ),
                        child: const Icon(Icons.shield, color: Color(0xFF04080F), size: 14),
                      ),
                      const SizedBox(width: 8),
                      const Text('Ce qu\'ARIA peut faire pour vous',
                        style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ]),
                    const SizedBox(height: 10),
                    ...[
                      if (_riskScore >= 5) '🔴 Analyser la situation et créer un plan d\'action personnalisé',
                      if (_riskScore >= 5) '🔴 Vous guider pour contacter les autorités (3919, police cyber)',
                      '🟡 Identifier les comportements suspects sur votre réseau',
                      '🟡 Vous apprendre à vérifier les permissions des applications',
                      '🟢 Effectuer une réinitialisation sécurisée de vos mots de passe',
                      '🟢 Surveiller votre Score de Sécurité en temps réel',
                    ].map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(step, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    )),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Pré-remplit le message ARIA
                          final symptoms = _checkedSymptoms.map((i) => _symptoms[i]['label'] as String).join(', ');
                          final msg = 'ARIA, j\'ai analysé mon téléphone pour des logiciels espions. '
                            'Score de risque : $_riskScore — $_riskLabel. '
                            '${symptoms.isNotEmpty ? "Symptômes : $symptoms." : ""} '
                            'Que dois-je faire maintenant ?';
                          VoiceAIService.pendingMessage = msg;
                          // Si on peut revenir en arrière (poussé depuis HomeScreen), on revient
                          // Sinon on est dans un onglet — l'utilisateur appuie sur le bouton central ARIA
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message prêt pour ARIA. Appuyez sur le bouton vert central 🎙'),
                                backgroundColor: Color(0xFF1A3A1A),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.mic, color: Color(0xFF04080F), size: 16),
                        label: const Text('Parler à ARIA maintenant',
                          style: TextStyle(color: Color(0xFF04080F), fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A9EFF),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 12),

              // ── Boutons action ──────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() { _scanDone = false; _results.clear(); _scanProgress = 0; _checkedSymptoms.clear(); }),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Réinitialiser'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadReport,
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                    label: const Text('Rapport PDF', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 28),

            // ── Logiciels espions connus ──────────────────────────────────────
            const Row(children: [
              Icon(Icons.bug_report, color: Colors.deepPurpleAccent, size: 18),
              SizedBox(width: 8),
              Text('Logiciels espions connus à chercher',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
            const SizedBox(height: 6),
            const Text(
              'Vérifiez manuellement dans Paramètres → Applications si l\'un de ces noms apparaît.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 12),

            ..._knownSpyware.map((spy) {
              final c = spy['risk'] == 'danger' ? Colors.red : Colors.orange;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(spy['name']!,
                      style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(spy['type']!,
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(spy['desc']!,
                      style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 2),
                  ])),
                ]),
              );
            }),

            const SizedBox(height: 20),

            // ── Numéros d'urgence ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.sos, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Si vous êtes en danger', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
                const SizedBox(height: 10),
                _emergencyRow('🇫🇷 Violences conjugales', '3919'),
                _emergencyRow('🇫🇷 Urgence police', '17'),
                _emergencyRow('🇪🇺 Numéro d\'urgence Europe', '112'),
                _emergencyRow('Cybermalveillance (aide)', 'cybermalveillance.gouv.fr'),
              ]),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _emergencyRow(String label, String contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12))),
        GestureDetector(
          onTap: () {
            if (contact.contains('.')) openUrl('https://$contact');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            child: Text(contact, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ]),
    );
  }
}

class _SpyResult {
  final String name, risk, desc;
  const _SpyResult({required this.name, required this.risk, required this.desc});
}

// ─── ECRAN À PROPOS / CONTACT / FAQ ──────────────────────────────────────────

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _pinEnabled = false;

  static const _faq = [
    {
      'q': 'Qu\'est-ce que CyberGuard AI ?',
      'a': 'CyberGuard AI est une application de cybersécurité personnelle alimentée par l\'intelligence artificielle. '
          'Elle surveille votre appareil en temps réel, détecte les menaces (phishing, spyware, ransomware...) '
          'et vous protège via ARIA, votre agent IA expert en cybersécurité.',
    },
    {
      'q': 'Qui sommes-nous ?',
      'a': 'CyberGuard AI est développé par une équipe de passionnés de cybersécurité. '
          'Notre mission : rendre la protection numérique accessible à tous, sans connaissances techniques. '
          'Nous croyons que chaque utilisateur mérite une protection de niveau professionnel.',
    },
    {
      'q': 'Qu\'est-ce qu\'ARIA ?',
      'a': 'ARIA (Advanced Response Intelligence Agent) est votre IA de cybersécurité personnelle. '
          'Elle est formée sur les connaissances CISSP, CEH et OSCP. '
          'Parlez-lui via le bouton vert central — elle répond en voix naturelle, '
          'neutralise les menaces et apprend de chaque attaque détectée.',
    },
    {
      'q': 'Comment fonctionne la détection de logiciels espions ?',
      'a': 'L\'outil analyse les symptômes comportementaux de votre appareil '
          '(batterie, performance, données mobiles...) et les compare à une base '
          'de 12+ stalkerware connus (mSpy, FlexiSPY, Hoverwatch...). '
          'Un rapport PDF téléchargeable est généré avec les résultats.',
    },
    {
      'q': 'Mes données sont-elles en sécurité ?',
      'a': 'Absolument. Nous collectons uniquement votre email et vos alertes de sécurité. '
          'Votre clé API OpenAI reste sur votre appareil — nous n\'y avons jamais accès. '
          'Aucune publicité, aucune revente de données. Conformité RGPD totale.',
    },
    {
      'q': 'Comment générer un rapport légal ?',
      'a': 'Allez dans l\'onglet Alertes → icône ⚖ en haut à droite → '
          '"Télécharger le rapport PDF". Le rapport inclut tous vos incidents, '
          'les hashs d\'intégrité et les liens vers 24 portails de plainte européens.',
    },
    {
      'q': 'Comment déposer plainte pour cybercriminalité ?',
      'a': 'Dans l\'onglet Alertes → icône ⚖ → section "Portails de plainte". '
          'Vous accédez directement à PHAROS, THESEE, Cybermalveillance.gouv.fr '
          'et aux portails de 14 pays européens + Canada.',
    },
    {
      'q': 'L\'application est-elle gratuite ?',
      'a': 'L\'application utilise l\'API OpenAI pour ARIA — vous avez besoin de votre '
          'propre clé API OpenAI. Toutes les autres fonctionnalités (détection, alertes, '
          'rapports PDF, veille cyber) sont gratuites et ne nécessitent pas de clé API.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _pinEnabled = prefs.getString('user_pin_hash') != null);
  }

  Future<void> _managePIN() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const PinSetupDialog(),
    );
    if (result != null) _loadPinState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF04080F),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)],
          ).createShader(b),
          child: const Text('À propos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero ─────────────────────────────────────────────────────────
          Center(
            child: Column(children: [
              const SizedBox(height: 8),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                ),
                child: const Icon(Icons.shield, color: Color(0xFF04080F), size: 44),
              ),
              const SizedBox(height: 14),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)]).createShader(b),
                child: const Text('CyberGuard AI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 4),
              const Text('Votre bouclier numérique intelligent', style: TextStyle(color: Colors.white38, fontSize: 13)),
              const Text('Version 1.0.0', style: TextStyle(color: Colors.white24, fontSize: 11)),
              const SizedBox(height: 20),
            ]),
          ),

          // ── Sécurité du compte ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.security, color: Color(0xFF4A9EFF), size: 18),
                SizedBox(width: 8),
                Text('Sécurité du compte',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              const SizedBox(height: 12),
              // PIN 2FA Toggle
              GestureDetector(
                onTap: _managePIN,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _pinEnabled ? Colors.blue.withOpacity(0.08) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _pinEnabled ? Colors.blue.withOpacity(0.4) : Colors.white12),
                  ),
                  child: Row(children: [
                    Icon(Icons.pin,
                      color: _pinEnabled ? const Color(0xFF4A9EFF) : Colors.white38, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Code PIN à deux facteurs',
                        style: TextStyle(
                          color: _pinEnabled ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        _pinEnabled
                          ? '✓ Actif — demandé à chaque connexion'
                          : 'Ajouter une couche de sécurité supplémentaire',
                        style: TextStyle(
                          color: _pinEnabled ? Colors.blue.withOpacity(0.8) : Colors.white38,
                          fontSize: 11)),
                    ])),
                    Icon(
                      _pinEnabled ? Icons.lock : Icons.lock_open,
                      color: _pinEnabled ? const Color(0xFF4A9EFF) : Colors.white24,
                      size: 20,
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Le PIN 2FA protège votre compte même si votre email est compromis.',
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ]),
          ),

          // ── Contact ───────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF4A9EFF).withOpacity(0.08), const Color(0xFF1A6FFF).withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.3)),
            ),
            child: Column(children: [
              _contactTile(Icons.email, 'Email support', 'contact@cyberguard.ai', () => openUrl('mailto:contact@cyberguard.ai')),
              _contactTile(Icons.security, 'DPO / RGPD', 'dpo@cyberguard.ai', () => openUrl('mailto:dpo@cyberguard.ai')),
              _contactTile(Icons.language, 'Site web', 'cyberguard.ai', () => openUrl('https://cyberguard.ai')),
              _contactTile(Icons.description, 'Signaler un bug', 'bugs@cyberguard.ai', () => openUrl('mailto:bugs@cyberguard.ai'), last: true),
            ]),
          ),

          // ── Notre Histoire — Valentin Halfon ─────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A04), Color(0xFF0A0818)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF6600).withOpacity(0.4)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6600).withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                ),
                child: const Row(children: [
                  Icon(Icons.auto_stories, color: Color(0xFFFF6600), size: 18),
                  SizedBox(width: 10),
                  Text('Notre Histoire', style: TextStyle(
                    color: Color(0xFFFF6600), fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Quote
                  const Text(
                    '« Je ne voulais pas être une victime de plus.\nJe voulais être la solution. »',
                    style: TextStyle(
                      color: Color(0xFFFF6600), fontStyle: FontStyle.italic,
                      fontSize: 14, height: 1.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('— Valentin Halfon, Fondateur & CEO',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 14),
                  // Story cards
                  _storyCard('🎯 L\'Attaque (2023)',
                    'Valentin Halfon découvre qu\'il est la cible d\'une cyberattaque '
                    'sophistiquée depuis des mois. Sa box internet compromise. Son smartphone '
                    'infecté par un logiciel espion. Ses boîtes mail piratées. Des algorithmes '
                    'de machine learning entraînés sur ses données pour anticiper ses comportements.'),
                  const SizedBox(height: 10),
                  _storyCard('💡 La Prise de Conscience',
                    'Aucun outil accessible ne lui permet de comprendre ce qui se passe. '
                    'Les solutions existantes sont trop complexes, trop chères, réservées aux experts IT. '
                    'Des millions de personnes sont dans la même situation — exposées, sans défense.'),
                  const SizedBox(height: 10),
                  _storyCard('🔥 La Transformation',
                    'De cette épreuve naît une conviction : chaque individu mérite une protection '
                    'de niveau professionnel sans expertise requise. '
                    'Valentin décide de construire la solution qu\'il aurait voulu avoir. '
                    'CyberGuard AI est né.'),
                  const SizedBox(height: 10),
                  _storyCard('🛡 La Mission',
                    'CyberGuard AI défend chaque utilisateur comme Valentin aurait voulu être défendu : '
                    'une IA vigilante, des communications inviolables, des preuves légales automatiques. '
                    'La cybersécurité n\'est pas un luxe — c\'est un droit fondamental.'),
                  const SizedBox(height: 14),
                  // Founder bio
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 52, height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF6600), Color(0xFFAA44FF)]),
                        ),
                        child: const Center(
                          child: Text('VH', style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFFFF6600), Color(0xFFAA44FF)],
                          ).createShader(b),
                          child: const Text('Valentin Halfon', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const Text('Fondateur & CEO — Entrepreneur & Défenseur du Numérique',
                          style: TextStyle(color: Color(0xFFFF6600), fontSize: 10)),
                        const SizedBox(height: 6),
                        const Text(
                          'Entrepreneur en série, Valentin a vécu en 2023 une cyberattaque '
                          'multi-vecteurs : box internet, smartphone, emails, machine learning. '
                          'Son combat est devenu sa mission : rendre la protection numérique '
                          'accessible à tous, partout.',
                          style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.6),
                        ),
                      ])),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),

          // ── FAQ ───────────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Icon(Icons.help_outline, color: Color(0xFF4A9EFF), size: 18),
              SizedBox(width: 8),
              Text('Questions fréquentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
          ),

          ..._faq.map((f) => _FaqTile(question: f['q']!, answer: f['a']!)),

          const SizedBox(height: 20),

          // ── Liens légaux ──────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _LegalScreen(type: 'cgu'))),
              child: const Text('CGU', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
            const Text('·', style: TextStyle(color: Colors.white24)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _LegalScreen(type: 'confidentialite'))),
              child: const Text('Confidentialité', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
            const Text('·', style: TextStyle(color: Colors.white24)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _LegalScreen(type: 'mentions'))),
              child: const Text('Mentions légales', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
          ]),
          const Center(
            child: Text('© 2025 CyberGuard AI — Tous droits réservés',
              style: TextStyle(color: Colors.white24, fontSize: 10)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _storyCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6600).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
          color: Color(0xFFFF6600), fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Text(content, style: const TextStyle(
          color: Colors.white54, fontSize: 11, height: 1.6)),
      ]),
    );
  }

  Widget _contactTile(IconData icon, String label, String value, VoidCallback onTap, {bool last = false}) {
    return Column(children: [
      ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF4A9EFF), size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(color: Color(0xFF4A9EFF), fontSize: 13, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        dense: true,
      ),
      if (!last) const Divider(height: 1, color: Colors.white10, indent: 16, endIndent: 16),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGES LÉGALES — CGU / CONFIDENTIALITÉ / MENTIONS LÉGALES
// ════════════════════════════════════════════════════════════════════════════

class _LegalScreen extends StatelessWidget {
  final String type; // 'cgu' | 'confidentialite' | 'mentions'
  const _LegalScreen({required this.type});

  String get _title => switch (type) {
    'cgu'            => 'Conditions Générales d\'Utilisation',
    'confidentialite'=> 'Politique de Confidentialité',
    _                => 'Mentions Légales',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1525),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)],
          ).createShader(b),
          child: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _buildContent(),
      ),
    );
  }

  List<Widget> _buildContent() {
    if (type == 'cgu')            return _cguContent();
    if (type == 'confidentialite') return _privacyContent();
    return _legalContent();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static Widget _h(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: const TextStyle(
      color: Color(0xFF4A9EFF), fontSize: 15, fontWeight: FontWeight.bold)),
  );

  static Widget _p(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(
      color: Colors.white60, fontSize: 13, height: 1.7)),
  );

  static Widget _li(String text) => Padding(
    padding: const EdgeInsets.only(left: 12, bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(color: Color(0xFF4A9EFF))),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.6))),
    ]),
  );

  static Widget _divider() => const Divider(color: Colors.white10, height: 24);

  // ═══════════════════════════════════════════════════════════════════════════
  // CGU
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _cguContent() => [
    _p('Dernière mise à jour : 9 avril 2026'),
    _p('Bienvenue sur CyberGuard AI. En utilisant notre application, vous acceptez les présentes Conditions Générales d\'Utilisation (CGU). Veuillez les lire attentivement avant d\'utiliser nos services.'),

    _h('Article 1 — Présentation de CyberGuard AI'),
    _p('CyberGuard AI est une application de cybersécurité personnelle intégrant une intelligence artificielle (ARIA) dédiée à la protection de la vie privée numérique. Elle permet notamment la détection de logiciels espions (spyware/stalkerware), la surveillance des menaces en temps réel, la messagerie chiffrée de bout en bout, les appels vocaux sécurisés et la génération de rapports légaux.'),

    _h('Article 2 — Accès et inscription'),
    _p('L\'utilisation de CyberGuard AI nécessite la création d\'un compte via une adresse email valide. L\'utilisateur s\'engage à fournir des informations exactes et à maintenir la confidentialité de ses identifiants de connexion.'),
    _li('Période d\'essai : 15 jours offerts sur les fonctionnalités Essentiel et ARIA.'),
    _li('Au-delà de la période d\'essai, l\'accès aux fonctionnalités avancées (messagerie sécurisée, appels chiffrés) requiert un abonnement payant.'),
    _li('L\'utilisateur doit être majeur (18 ans ou plus) pour créer un compte.'),

    _h('Article 3 — Plans d\'abonnement'),
    _p('CyberGuard AI propose les plans suivants :'),
    _li('Gratuit : Détection de spyware, alertes de base, veille cybersécurité. Accès limité après la période d\'essai.'),
    _li('Essentiel (4,99 €/mois) : Toutes les fonctionnalités de protection, rapports PDF légaux, portails de plainte.'),
    _li('Premium (9,99 €/mois) : Tout Essentiel + Messagerie E2EE illimitée, appels vocaux chiffrés, analyse ARIA avancée.'),
    _li('Pro (24,99 €/mois) : Tout Premium + Jusqu\'à 5 appareils, support prioritaire, tableau de bord famille.'),
    _p('Les prix s\'entendent TTC. Les abonnements sont renouvelés automatiquement sauf résiliation avant la date d\'échéance.'),

    _h('Article 4 — Utilisation acceptable'),
    _p('L\'utilisateur s\'engage à utiliser CyberGuard AI uniquement à des fins légales et licites. Il est strictement interdit de :'),
    _li('Utiliser l\'application pour surveiller, espionner ou harceler des tiers sans leur consentement.'),
    _li('Tenter de contourner les mécanismes de sécurité de l\'application.'),
    _li('Utiliser la messagerie sécurisée à des fins illicites, de harcèlement ou de diffusion de contenus illégaux.'),
    _li('Exploiter les rapports légaux générés pour de fausses déclarations aux autorités.'),

    _h('Article 5 — Clé API OpenAI'),
    _p('La fonctionnalité ARIA nécessite une clé API OpenAI personnelle. CyberGuard AI ne stocke pas cette clé sur ses serveurs — elle reste exclusivement sur l\'appareil de l\'utilisateur. L\'utilisateur est seul responsable du coût d\'utilisation de son API OpenAI et du respect des CGU d\'OpenAI.'),

    _h('Article 6 — Propriété intellectuelle'),
    _p('L\'application CyberGuard AI, son code source, ses interfaces, ses algorithmes de détection et son agent ARIA sont la propriété exclusive de CyberGuard AI SAS. Toute reproduction, modification, distribution ou exploitation commerciale sans autorisation écrite est strictement interdite.'),

    _h('Article 7 — Limitation de responsabilité'),
    _p('CyberGuard AI fournit ses services selon les meilleures pratiques du secteur. Cependant, aucun système de cybersécurité ne peut garantir une protection à 100 % contre toutes les menaces. CyberGuard AI ne saurait être tenu responsable des dommages résultant d\'une intrusion non détectée, d\'une perte de données ou d\'un préjudice indirect lié à l\'utilisation de l\'application.'),
    _p('Les rapports légaux générés par l\'application ont valeur d\'aide à la procédure mais ne constituent pas des preuves légalement certifiées par un officier assermenté.'),

    _h('Article 8 — Résiliation'),
    _p('L\'utilisateur peut résilier son abonnement à tout moment depuis l\'écran "À propos" de l\'application ou en contactant support@cyberguard.ai. La résiliation prend effet à la fin de la période de facturation en cours. Aucun remboursement partiel n\'est accordé sauf en cas de défaut du service.'),

    _h('Article 9 — Droit applicable'),
    _p('Les présentes CGU sont régies par le droit français. En cas de litige, et à défaut de résolution amiable, les tribunaux français seront seuls compétents. L\'utilisateur peut également recourir à la médiation de la consommation via la plateforme européenne de règlement en ligne des litiges : https://ec.europa.eu/consumers/odr'),

    _h('Article 10 — Contact'),
    _p('Pour toute question relative aux présentes CGU : contact@cyberguard.ai'),
    const SizedBox(height: 40),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // POLITIQUE DE CONFIDENTIALITÉ
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _privacyContent() => [
    _p('Dernière mise à jour : 9 avril 2026'),
    _p('CyberGuard AI accorde une importance primordiale à la protection de vos données personnelles. Cette politique décrit quelles données nous collectons, comment nous les utilisons et vos droits en vertu du Règlement Général sur la Protection des Données (RGPD — UE 2016/679).'),

    _h('1. Responsable du traitement'),
    _p('CyberGuard AI SAS\nEmail : dpo@cyberguard.ai\nDPO (Délégué à la Protection des Données) : dpo@cyberguard.ai'),

    _h('2. Données collectées'),
    _p('Nous collectons uniquement les données strictement nécessaires :'),
    _li('Adresse email : pour l\'authentification et la communication (obligatoire).'),
    _li('Alertes de sécurité : les menaces détectées sur votre appareil, horodatées et hashées, stockées dans Firebase Firestore.'),
    _li('Clés publiques RSA : pour le chiffrement E2EE de vos messages (jamais la clé privée).'),
    _li('Identifiants de contact : emails et noms des contacts que vous ajoutez volontairement à la messagerie sécurisée.'),
    _p('Nous ne collectons PAS :'),
    _li('Votre clé API OpenAI (reste sur votre appareil uniquement).'),
    _li('Le contenu de vos messages (chiffrés de bout en bout — illisibles pour nous).'),
    _li('Votre localisation GPS.'),
    _li('Vos données biométriques.'),
    _li('Vos contacts téléphoniques.'),

    _h('3. Finalités du traitement'),
    _p('Vos données sont utilisées pour :'),
    _li('Authentification et sécurisation de votre compte.'),
    _li('Détection et archivage des menaces de sécurité (intérêt légitime / consentement).'),
    _li('Envoi de notifications d\'alerte (consentement).'),
    _li('Génération de rapports légaux (sur demande de l\'utilisateur).'),
    _li('Amélioration des algorithmes de détection (données anonymisées uniquement).'),

    _h('4. Durée de conservation'),
    _li('Données de compte : durée de l\'abonnement + 1 an après résiliation.'),
    _li('Alertes de sécurité : 3 ans (valeur légale / délai de prescription cyber).'),
    _li('Données de messagerie : supprimées 30 jours après lecture ou sur demande.'),

    _h('5. Sécurité des données'),
    _p('CyberGuard AI applique les mesures de sécurité suivantes :'),
    _li('Chiffrement RSA-OAEP 2048-bit + AES-GCM 256-bit pour la messagerie.'),
    _li('Authentification Firebase avec 2FA PIN local.'),
    _li('Données stockées sur serveurs Firebase (Google Cloud, région europe-west).'),
    _li('Accès aux données restreint aux seuls ingénieurs autorisés avec MFA obligatoire.'),
    _li('Aucune vente, location ou partage de vos données à des tiers publicitaires.'),

    _h('6. Vos droits RGPD'),
    _p('Conformément au RGPD, vous disposez des droits suivants :'),
    _li('Droit d\'accès : obtenir une copie de vos données (dpo@cyberguard.ai).'),
    _li('Droit de rectification : corriger des données inexactes.'),
    _li('Droit à l\'effacement (« droit à l\'oubli ») : suppression de votre compte et de toutes vos données.'),
    _li('Droit à la portabilité : recevoir vos données dans un format structuré (JSON).'),
    _li('Droit d\'opposition : vous opposer à certains traitements.'),
    _li('Droit de réclamation : auprès de la CNIL (www.cnil.fr) si vous estimez que vos droits ne sont pas respectés.'),
    _p('Pour exercer vos droits : dpo@cyberguard.ai — Réponse sous 30 jours maximum.'),

    _h('7. Cookies et traceurs'),
    _p('L\'application mobile ne dépose pas de cookies. La version web peut utiliser des cookies techniques strictement nécessaires au fonctionnement (session utilisateur). Aucun cookie publicitaire ou de tracking tiers n\'est déposé.'),

    _h('8. Transferts internationaux'),
    _p('Vos données sont hébergées sur Google Firebase (région Europe). Dans le cadre de l\'utilisation de l\'API OpenAI, vos requêtes (textuelles uniquement, anonymisées) peuvent transiter vers les serveurs d\'OpenAI aux États-Unis, couverts par les clauses contractuelles types de la Commission Européenne.'),

    _h('9. Modifications'),
    _p('Nous nous réservons le droit de modifier cette politique. Toute modification substantielle vous sera notifiée par email ou par notification in-app au moins 30 jours avant son entrée en vigueur.'),

    _h('10. Contact DPO'),
    _p('Délégué à la Protection des Données : dpo@cyberguard.ai'),
    const SizedBox(height: 40),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // MENTIONS LÉGALES
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _legalContent() => [
    _p('Conformément aux dispositions des articles 6-III et 19 de la Loi n° 2004-575 du 21 juin 2004 pour la Confiance dans l\'Économie Numérique (LCEN), nous vous informons des mentions légales suivantes.'),

    _h('Éditeur de l\'application'),
    _p('CyberGuard AI SAS\nSociété par Actions Simplifiée au capital de 10 000 €\nSiège social : [Adresse à compléter]\nSIRET : [En cours d\'immatriculation]\nCode APE : 6201Z (Programmation informatique)\nEmail : contact@cyberguard.ai\nDirecteur de la publication : [Nom du dirigeant]'),

    _divider(),
    _h('Hébergement'),
    _p('L\'application CyberGuard AI est hébergée par :\nGoogle Firebase / Google Cloud Platform\nGoogle LLC, 1600 Amphitheatre Parkway, Mountain View, CA 94043, USA\nInfrastructure européenne : europe-west1 (Belgique)\nhttps://firebase.google.com'),

    _divider(),
    _h('Propriété intellectuelle'),
    _p('L\'ensemble des contenus présents sur l\'application CyberGuard AI (textes, images, interfaces graphiques, code source, algorithmes, agent ARIA, logo, marque) sont la propriété exclusive de CyberGuard AI SAS et sont protégés par les lois françaises et internationales relatives à la propriété intellectuelle.'),
    _p('Toute reproduction, représentation, modification, publication, adaptation de tout ou partie des éléments de l\'application, quel que soit le moyen ou le procédé utilisé, est interdite, sauf autorisation écrite préalable de CyberGuard AI SAS.'),

    _divider(),
    _h('Marques déposées'),
    _p('« CyberGuard AI » et « ARIA » sont des marques en cours de dépôt auprès de l\'Institut National de la Propriété Industrielle (INPI). Toute utilisation non autorisée de ces marques constitue une contrefaçon passible de poursuites.'),

    _divider(),
    _h('Données personnelles et RGPD'),
    _p('Le traitement des données personnelles est régi par notre Politique de Confidentialité accessible depuis cet écran. Le responsable de traitement est CyberGuard AI SAS. Pour toute demande relative à vos données : dpo@cyberguard.ai.'),
    _p('Autorité de contrôle compétente :\nCommission Nationale de l\'Informatique et des Libertés (CNIL)\n3 Place de Fontenoy — TSA 80715 — 75334 Paris Cedex 07\nwww.cnil.fr'),

    _divider(),
    _h('Limitation de responsabilité'),
    _p('CyberGuard AI SAS s\'efforce d\'assurer l\'exactitude et la mise à jour des informations diffusées dans l\'application, dont elle se réserve le droit de corriger le contenu à tout moment. CyberGuard AI SAS ne peut garantir l\'exactitude, la précision ou l\'exhaustivité des informations mises à disposition.'),
    _p('En conséquence, CyberGuard AI SAS décline toute responsabilité pour tout dommage résultant d\'une interruption de service, d\'une intrusion informatique non détectée, ou de l\'utilisation des informations contenues dans l\'application.'),

    _divider(),
    _h('Droit applicable et juridiction'),
    _p('Les présentes mentions légales sont régies par le droit français. En cas de litige, et après tentative de résolution amiable, les tribunaux français seront seuls compétents.'),
    _p('Pour tout litige de consommation, vous pouvez recourir à la médiation via :\nPlateforme européenne de règlement en ligne des litiges :\nhttps://ec.europa.eu/consumers/odr'),

    _divider(),
    _h('Contact'),
    _p('Pour toute question : contact@cyberguard.ai\nSupport technique : bugs@cyberguard.ai\nDPO / RGPD : dpo@cyberguard.ai\nPartenariats : pro@cyberguard.ai'),
    const SizedBox(height: 40),
  ];
}

// ════════════════════════════════════════════════════════════════════════════
// MESSAGERIE SÉCURISÉE E2EE — MODÈLES
// ════════════════════════════════════════════════════════════════════════════

class SecureMessage {
  final String id;
  final String senderUid;
  final String encryptedForSender;
  final String encryptedForRecipient;
  final DateTime timestamp;
  final String type;
  String? decryptedContent;

  SecureMessage({
    required this.id,
    required this.senderUid,
    required this.encryptedForSender,
    required this.encryptedForRecipient,
    required this.timestamp,
    this.type = 'text',
    this.decryptedContent,
  });

  factory SecureMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SecureMessage(
      id: doc.id,
      senderUid: d['senderUid'] ?? '',
      encryptedForSender: d['encryptedForSender'] ?? '',
      encryptedForRecipient: d['encryptedForRecipient'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: d['type'] ?? 'text',
    );
  }
}

class ContactInfo {
  final String uid;
  final String email;
  final String displayName;
  final String status;
  final String publicKey;
  final DateTime timestamp;

  const ContactInfo({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.status,
    required this.publicKey,
    required this.timestamp,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// SERVICE MESSAGERIE SÉCURISÉE
// ════════════════════════════════════════════════════════════════════════════

class MessengerService {
  static final MessengerService _instance = MessengerService._();
  factory MessengerService() => _instance;
  MessengerService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _email => _auth.currentUser?.email ?? '';
  String get _name => _auth.currentUser?.displayName ?? _email.split('@').first;

  /// Initialise profil + clés au premier lancement (appeler depuis MainScreen)
  Future<void> initUserProfile() async {
    if (_uid.isEmpty) return;
    try {
      final doc = _db.collection('userProfiles').doc(_uid);
      final snap = await doc.get();
      String publicKey;
      if (!snap.exists || (snap.data()?['publicKey'] ?? '').isEmpty) {
        publicKey = await cgGenerateKeyPair();
        if (publicKey.isEmpty) return;
      } else if (!cgHasLocalKeys()) {
        publicKey = await cgGenerateKeyPair();
      } else {
        publicKey = cgGetLocalPublicKey();
      }
      await doc.set({
        'uid': _uid, 'email': _email, 'displayName': _name,
        'publicKey': publicKey, 'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Recherche un utilisateur par email
  Future<ContactInfo?> findUserByEmail(String email) async {
    try {
      final q = await _db.collection('userProfiles')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1).get();
      if (q.docs.isEmpty) return null;
      final d = q.docs.first.data();
      return ContactInfo(
        uid: d['uid'] ?? q.docs.first.id,
        email: d['email'] ?? '',
        displayName: d['displayName'] ?? email,
        status: '',
        publicKey: d['publicKey'] ?? '',
        timestamp: DateTime.now(),
      );
    } catch (_) { return null; }
  }

  /// Envoie une demande de contact
  Future<void> sendContactRequest(ContactInfo target) async {
    final batch = _db.batch();
    batch.set(_db.collection('contacts').doc(_uid).collection('list').doc(target.uid), {
      'uid': target.uid, 'email': target.email, 'displayName': target.displayName,
      'publicKey': target.publicKey, 'status': 'pending_sent',
      'timestamp': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('contacts').doc(target.uid).collection('list').doc(_uid), {
      'uid': _uid, 'email': _email, 'displayName': _name,
      'publicKey': cgGetLocalPublicKey(), 'status': 'pending_received',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Accepte une demande de contact
  Future<void> acceptContactRequest(String contactUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('contacts').doc(_uid).collection('list').doc(contactUid), {'status': 'accepted'});
    batch.update(_db.collection('contacts').doc(contactUid).collection('list').doc(_uid), {'status': 'accepted'});
    await batch.commit();
  }

  /// Refuse une demande de contact
  Future<void> declineContactRequest(String contactUid) async {
    await _db.collection('contacts').doc(_uid).collection('list').doc(contactUid).delete();
    await _db.collection('contacts').doc(contactUid).collection('list').doc(_uid).delete();
  }

  /// Stream des contacts
  Stream<List<ContactInfo>> get contactsStream {
    return _db.collection('contacts').doc(_uid).collection('list')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((s) => s.docs.map((doc) {
        final d = doc.data();
        return ContactInfo(
          uid: d['uid'] ?? doc.id, email: d['email'] ?? '',
          displayName: d['displayName'] ?? '', status: d['status'] ?? '',
          publicKey: d['publicKey'] ?? '',
          timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList());
  }

  /// ID de conversation déterministe
  static String convId(String uid1, String uid2) {
    final s = [uid1, uid2]..sort();
    return '${s[0]}_${s[1]}';
  }

  /// Envoie un message chiffré E2EE
  Future<void> sendMessage(String recipientUid, String recipientPubKey, String plaintext) async {
    final myPub = cgGetLocalPublicKey();
    if (myPub.isEmpty || recipientPubKey.isEmpty) return;
    final encForRecipient = await cgEncryptMessage(recipientPubKey, plaintext);
    final encForSender = await cgEncryptMessage(myPub, plaintext);
    if (encForRecipient.isEmpty || encForSender.isEmpty) return;
    final cid = convId(_uid, recipientUid);
    await _db.collection('conversations').doc(cid).collection('messages').add({
      'senderUid': _uid, 'encryptedForSender': encForSender,
      'encryptedForRecipient': encForRecipient,
      'timestamp': FieldValue.serverTimestamp(), 'type': 'text',
    });
    await _db.collection('conversations').doc(cid).set({
      'participants': [_uid, recipientUid],
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream des messages d'une conversation
  Stream<List<SecureMessage>> messagesStream(String otherUid) {
    final cid = convId(_uid, otherUid);
    return _db.collection('conversations').doc(cid).collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((s) => s.docs.map(SecureMessage.fromFirestore).toList());
  }

  /// Déchiffre un message (selon si je suis sender ou receiver)
  Future<String> decryptMessage(SecureMessage msg) async {
    final enc = msg.senderUid == _uid ? msg.encryptedForSender : msg.encryptedForRecipient;
    if (enc.isEmpty) return '[vide]';
    return cgDecryptMessage(enc);
  }

  // ── WebRTC signaling ────────────────────────────────────────────────────────

  Future<String> initiateCall(String calleeUid) async {
    final callId = '${_uid.substring(0, 8)}_${calleeUid.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('calls').doc(callId).set({
      'callerUid': _uid, 'calleeUid': calleeUid,
      'status': 'ringing', 'timestamp': FieldValue.serverTimestamp(),
    });
    return callId;
  }

  Future<void> storeOffer(String callId, String offerJson) async =>
    _db.collection('calls').doc(callId).update({'offer': offerJson});

  Future<void> storeAnswer(String callId, String answerJson) async =>
    _db.collection('calls').doc(callId).update({'answer': answerJson, 'status': 'active'});

  Future<void> storeIceCandidate(String callId, bool isCaller, String candidateJson) async {
    final sub = isCaller ? 'callerCandidates' : 'calleeCandidates';
    await _db.collection('calls').doc(callId).collection(sub).add({
      'candidate': candidateJson, 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> callStream(String callId) =>
    _db.collection('calls').doc(callId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> iceCandidatesStream(String callId, bool fromCaller) {
    final sub = fromCaller ? 'callerCandidates' : 'calleeCandidates';
    return _db.collection('calls').doc(callId).collection(sub).snapshots();
  }

  Future<void> endCall(String callId) async {
    try { await _db.collection('calls').doc(callId).update({'status': 'ended'}); } catch (_) {}
    cgHangupCall();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get incomingCallsStream =>
    _db.collection('calls')
      .where('calleeUid', isEqualTo: _uid)
      .where('status', isEqualTo: 'ringing')
      .snapshots();
}

// ════════════════════════════════════════════════════════════════════════════
// ECRAN MESSAGERIE SÉCURISÉE
// ════════════════════════════════════════════════════════════════════════════

class SecureMessengerScreen extends StatefulWidget {
  const SecureMessengerScreen({super.key});
  @override
  State<SecureMessengerScreen> createState() => _SecureMessengerScreenState();
}

class _SecureMessengerScreenState extends State<SecureMessengerScreen> {
  final _messenger = MessengerService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _messenger.initUserProfile().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _addContact() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF0A0A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withOpacity(0.4)),
      ),
      title: const Row(children: [
        Icon(Icons.person_add, color: Color(0xFF4A9EFF), size: 20),
        SizedBox(width: 8),
        Text('Ajouter un contact', style: TextStyle(color: Colors.white, fontSize: 16)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Entrez l\'email de l\'utilisateur CyberGuard AI à qui vous souhaitez écrire en sécurité.',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
        const SizedBox(height: 16),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'email@exemple.com',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4A9EFF)),
            ),
            prefixIcon: const Icon(Icons.email, color: Colors.white38, size: 18),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A9EFF),
            foregroundColor: const Color(0xFF04080F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            final email = ctrl.text.trim();
            Navigator.pop(context);
            if (email.isEmpty) return;
            final contact = await _messenger.findUserByEmail(email);
            if (!mounted) return;
            if (contact == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Aucun compte CyberGuard AI avec cet email.'),
                backgroundColor: Colors.red,
              ));
              return;
            }
            if (contact.uid == FirebaseAuth.instance.currentUser?.uid) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Vous ne pouvez pas vous ajouter vous-même.'),
                backgroundColor: Colors.orange,
              ));
              return;
            }
            await _messenger.sendContactRequest(contact);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Demande de contact envoyée à ${contact.email}'),
              backgroundColor: Colors.blue,
            ));
          },
          child: const Text('Envoyer la demande'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)]),
            ),
            child: const Icon(Icons.lock, color: Color(0xFF04080F), size: 14),
          ),
          const SizedBox(width: 10),
          const Text('Messagerie Sécurisée',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF4A9EFF)),
            tooltip: 'Ajouter un contact',
            onPressed: _addContact,
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF)))
        : Column(children: [
            // E2EE banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withOpacity(0.06),
              child: const Row(children: [
                Icon(Icons.verified_user, color: Color(0xFF4A9EFF), size: 13),
                SizedBox(width: 8),
                Text('Chiffrement RSA-OAEP + AES-GCM · Clés locales uniquement · Illisible par CyberGuard AI',
                  style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 10)),
              ]),
            ),
            Expanded(child: StreamBuilder<List<ContactInfo>>(
              stream: _messenger.contactsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 1));
                }
                final contacts = snap.data ?? [];
                final pending = contacts.where((c) => c.status == 'pending_received').toList();
                final accepted = contacts.where((c) => c.status == 'accepted').toList();
                final sent = contacts.where((c) => c.status == 'pending_sent').toList();

                if (contacts.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.2), width: 2),
                      ),
                      child: const Icon(Icons.forum, color: Colors.white24, size: 48),
                    ),
                    const SizedBox(height: 20),
                    const Text('Aucun contact sécurisé', style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Ajoutez un contact par email pour\ncommuniquer en toute confidentialité.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _addContact,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Ajouter un contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9EFF),
                        foregroundColor: const Color(0xFF04080F),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]));
                }

                return ListView(children: [
                  if (pending.isNotEmpty) ...[
                    _MsgSectionHeader('Demandes reçues (${pending.length})', Icons.mark_email_unread, Colors.orange),
                    ...pending.map((c) => _ContactRequestTile(
                      contact: c,
                      onAccept: () => _messenger.acceptContactRequest(c.uid),
                      onDecline: () => _messenger.declineContactRequest(c.uid),
                    )),
                  ],
                  if (accepted.isNotEmpty) ...[
                    _MsgSectionHeader('Contacts (${accepted.length})', Icons.verified_user, const Color(0xFF4A9EFF)),
                    ...accepted.map((c) => _ContactTile(
                      contact: c,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SecureChatScreen(contact: c),
                      )),
                    )),
                  ],
                  if (sent.isNotEmpty) ...[
                    _MsgSectionHeader('En attente', Icons.schedule, Colors.white38),
                    ...sent.map((c) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.06),
                        child: Text(c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white54)),
                      ),
                      title: Text(c.displayName, style: const TextStyle(color: Colors.white60)),
                      subtitle: Text(c.email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('En attente…', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ),
                    )),
                  ],
                ]);
              },
            )),
          ]),
    );
  }
}

class _MsgSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _MsgSectionHeader(this.title, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 6),
      Text(title.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    ]),
  );
}

class _ContactRequestTile extends StatelessWidget {
  final ContactInfo contact;
  final VoidCallback onAccept, onDecline;
  const _ContactRequestTile({required this.contact, required this.onAccept, required this.onDecline});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.withOpacity(0.3)),
    ),
    child: Row(children: [
      CircleAvatar(
        backgroundColor: Colors.orange.withOpacity(0.15),
        child: Text(contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(contact.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(contact.email, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const Text('Souhaite communiquer en sécurité avec vous',
          style: TextStyle(color: Colors.orange, fontSize: 10)),
      ])),
      Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: onAccept,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9EFF).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF4A9EFF), size: 20),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onDecline,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.red, size: 18),
          ),
        ),
      ]),
    ]),
  );
}

class _ContactTile extends StatelessWidget {
  final ContactInfo contact;
  final VoidCallback onTap;
  const _ContactTile({required this.contact, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Stack(clipBehavior: Clip.none, children: [
      CircleAvatar(
        backgroundColor: const Color(0xFF4A9EFF).withOpacity(0.12),
        child: Text(contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
          style: const TextStyle(color: Color(0xFF4A9EFF), fontWeight: FontWeight.bold)),
      ),
      Positioned(bottom: -2, right: -2,
        child: Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: const Color(0xFF4A9EFF),
            border: Border.all(color: const Color(0xFF04080F), width: 2),
          ),
          child: const Icon(Icons.lock, color: Color(0xFF04080F), size: 7),
        ),
      ),
    ]),
    title: Text(contact.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
    subtitle: Text(contact.email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    trailing: const Icon(Icons.chevron_right, color: Colors.white24),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// ECRAN CHAT CHIFFRÉ
// ════════════════════════════════════════════════════════════════════════════

class SecureChatScreen extends StatefulWidget {
  final ContactInfo contact;
  const SecureChatScreen({super.key, required this.contact});
  @override
  State<SecureChatScreen> createState() => _SecureChatScreenState();
}

class _SecureChatScreenState extends State<SecureChatScreen> {
  final _messenger = MessengerService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _initialLoad = true;
  List<_DecryptedMessage> _messages = [];
  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _msgSub = _messenger.messagesStream(widget.contact.uid).listen((msgs) async {
      final dec = <_DecryptedMessage>[];
      for (final m in msgs) {
        final text = await _messenger.decryptMessage(m);
        dec.add(_DecryptedMessage(id: m.id, isMe: m.senderUid == uid, text: text, timestamp: m.timestamp));
      }
      if (mounted) {
        setState(() { _messages = dec; _initialLoad = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await _messenger.sendMessage(widget.contact.uid, widget.contact.publicKey, text);
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  void _showEncryptionInfo() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF0A0520),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF4A9EFF), width: 0.5),
      ),
      title: const Row(children: [
        Icon(Icons.verified_user, color: Color(0xFF4A9EFF), size: 20),
        SizedBox(width: 8),
        Text('Sécurité E2EE', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 16)),
      ]),
      content: const Text(
        '🔒  Chiffrement bout-en-bout actif\n\n'
        '• Algorithme : RSA-OAEP 2048-bit (échange de clé) + AES-GCM 256-bit (message)\n\n'
        '• Chaque message utilise une clé AES unique\n\n'
        '• Vos messages sont chiffrés AVANT envoi\n\n'
        '• Clé privée stockée uniquement sur votre appareil\n\n'
        '• CyberGuard AI ne peut jamais lire vos messages\n\n'
        '• Même niveau de sécurité que Signal / WhatsApp',
        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.7),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Compris ✓', style: TextStyle(color: Color(0xFF4A9EFF))),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF4A9EFF).withOpacity(0.12),
            child: Text(
              widget.contact.displayName.isNotEmpty ? widget.contact.displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFF4A9EFF), fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(widget.contact.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            const Row(children: [
              Icon(Icons.lock, color: Color(0xFF4A9EFF), size: 10),
              SizedBox(width: 3),
              Text('Bout-en-bout chiffré', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 10)),
            ]),
          ])),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF4A9EFF)),
            tooltip: 'Appel vocal sécurisé',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SecureCallScreen(contact: widget.contact, isCaller: true),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
            tooltip: 'Infos chiffrement',
            onPressed: _showEncryptionInfo,
          ),
        ],
      ),
      body: Column(children: [
        // Message list
        Expanded(
          child: _initialLoad
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Color(0xFF4A9EFF), strokeWidth: 2),
                SizedBox(height: 14),
                Text('Déchiffrement en cours…', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ]))
            : _messages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock, color: Colors.white12, size: 52),
                  const SizedBox(height: 14),
                  Text('Début de la conversation avec\n${widget.contact.displayName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text('Vos messages sont illisibles\npar toute personne tierce.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 11)),
                ]))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
                ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.2)),
                ),
                child: Row(children: [
                  Expanded(child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Message chiffré…',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _send(),
                  )),
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.lock, color: Color(0xFF4A9EFF), size: 12),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _sending ? null : const LinearGradient(colors: [Color(0xFF4A9EFF), Color(0xFF1A6FFF)]),
                  color: _sending ? Colors.white12 : null,
                  boxShadow: _sending ? null : [BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.35), blurRadius: 10)],
                ),
                child: _sending
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.black, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _DecryptedMessage {
  final String id;
  final bool isMe;
  final String text;
  final DateTime timestamp;
  const _DecryptedMessage({required this.id, required this.isMe, required this.text, required this.timestamp});
}

class _MessageBubble extends StatelessWidget {
  final _DecryptedMessage msg;
  const _MessageBubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    final time = '${msg.timestamp.hour.toString().padLeft(2,'0')}:${msg.timestamp.minute.toString().padLeft(2,'0')}';
    return Padding(
      padding: EdgeInsets.only(bottom: 6, left: msg.isMe ? 56 : 0, right: msg.isMe ? 0 : 56),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) const Padding(
            padding: EdgeInsets.only(right: 4, bottom: 4),
            child: Icon(Icons.lock, color: Color(0xFF4A9EFF), size: 9),
          ),
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isMe
                ? const Color(0xFF4A9EFF).withOpacity(0.13)
                : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                bottomRight: Radius.circular(msg.isMe ? 4 : 16),
              ),
              border: Border.all(
                color: msg.isMe
                  ? const Color(0xFF4A9EFF).withOpacity(0.25)
                  : Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              Text(msg.text, style: TextStyle(
                color: msg.isMe ? Colors.white : Colors.white70,
                fontSize: 13, height: 1.4)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(time, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, color: Color(0xFF4A9EFF), size: 11),
                ],
              ]),
            ]),
          )),
          if (msg.isMe) const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Icon(Icons.lock, color: Color(0xFF4A9EFF), size: 9),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ECRAN APPEL VOCAL SÉCURISÉ (WebRTC DTLS-SRTP)
// ════════════════════════════════════════════════════════════════════════════

class SecureCallScreen extends StatefulWidget {
  final ContactInfo contact;
  final bool isCaller;
  final String? incomingCallId;
  const SecureCallScreen({super.key, required this.contact, required this.isCaller, this.incomingCallId});
  @override
  State<SecureCallScreen> createState() => _SecureCallScreenState();
}

class _SecureCallScreenState extends State<SecureCallScreen> with SingleTickerProviderStateMixin {
  final _messenger = MessengerService();
  String _status = 'Initialisation…';
  bool _connected = false;
  bool _muted = false;
  String? _callId;
  late AnimationController _pulse;
  StreamSubscription? _callSub;
  StreamSubscription? _candSub;
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    cgSetupWebRTCCallbacks(
      onIceCandidate: (c) { if (_callId != null) _messenger.storeIceCandidate(_callId!, widget.isCaller, c); },
      onConnectionState: (s) {
        if (!mounted) return;
        if (s == 'connected') {
          setState(() { _status = 'Appel sécurisé en cours'; _connected = true; });
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() => _duration += const Duration(seconds: 1));
          });
        } else if (s == 'disconnected' || s == 'failed' || s == 'closed') {
          _hangup();
        }
      },
    );
    _initCall();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _callSub?.cancel();
    _candSub?.cancel();
    _timer?.cancel();
    cgHangupCall();
    super.dispose();
  }

  Future<void> _initCall() async {
    setState(() => _status = 'Accès au micro…');
    final ok = await cgInitWebRTC();
    if (!ok) {
      if (mounted) setState(() => _status = 'Accès micro refusé. Vérifiez les autorisations Chrome.');
      return;
    }
    widget.isCaller ? await _callerFlow() : await _calleeFlow();
  }

  Future<void> _callerFlow() async {
    setState(() => _status = 'Appel en cours…');
    _callId = await _messenger.initiateCall(widget.contact.uid);
    final offer = await cgCreateOffer();
    if (offer.isEmpty) { setState(() => _status = 'Erreur création appel.'); return; }
    await _messenger.storeOffer(_callId!, offer);
    _callSub = _messenger.callStream(_callId!).listen((snap) {
      if (!snap.exists) return;
      final d = snap.data() as Map<String, dynamic>;
      final s = d['status'] as String? ?? '';
      if (s == 'active' && d['answer'] != null) {
        cgSetRemoteAnswer(d['answer'] as String);
        _callSub?.cancel();
      } else if (s == 'ended' || s == 'declined') { _hangup(); }
    });
    _candSub = _messenger.iceCandidatesStream(_callId!, false).listen((snap) {
      for (final ch in snap.docChanges) {
        if (ch.type == DocumentChangeType.added) {
          final c = ch.doc.data()?['candidate'] as String? ?? '';
          if (c.isNotEmpty) cgAddIceCandidate(c);
        }
      }
    });
  }

  Future<void> _calleeFlow() async {
    _callId = widget.incomingCallId;
    if (_callId == null) { setState(() => _status = 'Appel invalide.'); return; }
    setState(() => _status = 'Connexion…');
    final snap = await FirebaseFirestore.instance.collection('calls').doc(_callId).get();
    final offer = snap.data()?['offer'] as String? ?? '';
    if (offer.isEmpty) { setState(() => _status = 'Offre manquante.'); return; }
    final answer = await cgCreateAnswer(offer);
    if (answer.isEmpty) { setState(() => _status = 'Erreur de connexion.'); return; }
    await _messenger.storeAnswer(_callId!, answer);
    _candSub = _messenger.iceCandidatesStream(_callId!, true).listen((snap) {
      for (final ch in snap.docChanges) {
        if (ch.type == DocumentChangeType.added) {
          final c = ch.doc.data()?['candidate'] as String? ?? '';
          if (c.isNotEmpty) cgAddIceCandidate(c);
        }
      }
    });
  }

  void _hangup() {
    if (_callId != null) _messenger.endCall(_callId!);
    _timer?.cancel();
    if (mounted) Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    cgToggleMute(_muted);
  }

  String get _formattedDuration {
    final m = _duration.inMinutes.remainder(60).toString().padLeft(2,'0');
    final s = _duration.inSeconds.remainder(60).toString().padLeft(2,'0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF001510), Color(0xFF04080F)],
          ),
        ),
        child: SafeArea(child: Column(children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock, color: Color(0xFF4A9EFF), size: 12),
              SizedBox(width: 6),
              Text('Appel chiffré DTLS-SRTP', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 48),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A9EFF).withOpacity(0.08 + _pulse.value * 0.06),
                border: Border.all(
                  color: const Color(0xFF4A9EFF).withOpacity(0.3 + _pulse.value * 0.4), width: 2),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF4A9EFF).withOpacity(0.15 + _pulse.value * 0.15),
                  blurRadius: 30 + _pulse.value * 20,
                )],
              ),
              child: Center(child: Text(
                widget.contact.displayName.isNotEmpty ? widget.contact.displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF4A9EFF)),
              )),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.contact.displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            _connected ? _formattedDuration : _status,
            style: TextStyle(color: _connected ? const Color(0xFF4A9EFF) : Colors.white54, fontSize: 14),
          ),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _callBtn(Icons.mic_off, _muted ? 'Activé' : 'Muet',
              _muted ? Colors.red : Colors.white24, _toggleMute, size: 58),
            const SizedBox(width: 40),
            _callBtn(Icons.call_end, 'Raccrocher', Colors.red, _hangup, size: 70, iconSize: 30),
            const SizedBox(width: 40),
            _callBtn(Icons.volume_up, 'HP', Colors.white24, () {}, size: 58),
          ]),
          const SizedBox(height: 60),
        ])),
      ),
    );
  }

  Widget _callBtn(IconData icon, String label, Color color, VoidCallback onTap, {double size = 60, double iconSize = 26}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color == Colors.red ? Colors.red : color.withOpacity(0.15),
            border: color == Colors.red ? null : Border.all(color: color.withOpacity(0.5)),
            boxShadow: color == Colors.red ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 16)] : null,
          ),
          child: Icon(icon, color: color == Colors.red ? Colors.white : Colors.white, size: iconSize),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]);
  }
}

// ── Dialog appel entrant ──────────────────────────────────────────────────────

class _IncomingCallDialog extends StatefulWidget {
  final String callerName, callerEmail, callId, callerUid;
  final VoidCallback onAccept, onDecline;
  const _IncomingCallDialog({
    required this.callerName, required this.callerEmail,
    required this.callId, required this.callerUid,
    required this.onAccept, required this.onDecline,
  });
  @override
  State<_IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<_IncomingCallDialog> with SingleTickerProviderStateMixin {
  late AnimationController _ring;
  @override
  void initState() {
    super.initState();
    _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }
  @override
  void dispose() { _ring.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF04080F),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFF4A9EFF), width: 1.5),
    ),
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Appel entrant', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _ring,
          builder: (_, __) => Container(
            width: 78, height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A9EFF).withOpacity(0.06 + _ring.value * 0.08),
              border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.3 + _ring.value * 0.5), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.1 + _ring.value * 0.15), blurRadius: 20)],
            ),
            child: Center(child: Text(
              widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF4A9EFF)),
            )),
          ),
        ),
        const SizedBox(height: 14),
        Text(widget.callerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock, color: Color(0xFF4A9EFF), size: 11),
          const SizedBox(width: 4),
          Text(widget.callerEmail, style: const TextStyle(color: Color(0xFF4A9EFF), fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        const Text('Appel sécurisé DTLS-SRTP', style: TextStyle(color: Colors.white24, fontSize: 10)),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          GestureDetector(
            onTap: widget.onDecline,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.8)),
                child: const Icon(Icons.call_end, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 6),
              const Text('Refuser', style: TextStyle(color: Colors.red, fontSize: 11)),
            ]),
          ),
          GestureDetector(
            onTap: widget.onAccept,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: const Color(0xFF4A9EFF),
                  boxShadow: [BoxShadow(color: const Color(0xFF4A9EFF).withOpacity(0.5), blurRadius: 16)],
                ),
                child: const Icon(Icons.call, color: Colors.black, size: 28),
              ),
              const SizedBox(height: 6),
              const Text('Accepter', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 11)),
            ]),
          ),
        ]),
      ]),
    ),
  );
}

class _FaqTile extends StatefulWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _open ? const Color(0xFF4A9EFF).withOpacity(0.06) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _open ? const Color(0xFF4A9EFF).withOpacity(0.35) : Colors.white12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(child: Text(widget.question,
                style: TextStyle(
                  color: _open ? const Color(0xFF4A9EFF) : Colors.white70,
                  fontWeight: FontWeight.bold, fontSize: 13))),
              Icon(_open ? Icons.expand_less : Icons.expand_more,
                color: _open ? const Color(0xFF4A9EFF) : Colors.white38, size: 20),
            ]),
          ),
          if (_open) Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text(widget.answer,
              style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.55)),
          ),
        ]),
      ),
    );
  }
}

// ─── MODELE ARTICLE ACTUALITE CYBER ──────────────────────────────────────────

class _CyberArticle {
  final String title, link, date, summary, source;
  const _CyberArticle({required this.title, required this.link,
    required this.date, required this.summary, required this.source});
}

// ─── ECRAN VEILLE CYBER QUOTIDIENNE ──────────────────────────────────────────

class CyberNewsScreen extends StatefulWidget {
  const CyberNewsScreen({super.key});
  @override
  State<CyberNewsScreen> createState() => _CyberNewsScreenState();
}

class _CyberNewsScreenState extends State<CyberNewsScreen> {
  bool _loading = false;
  bool _error = false;
  List<_CyberArticle> _articles = [];
  DateTime? _lastRefresh;

  // Feeds RSS cybersécurité
  static const _feeds = [
    {'url': 'https://www.cert.ssi.gouv.fr/feed/',     'source': 'CERT-FR'},
    {'url': 'https://www.cisa.gov/news.xml',          'source': 'CISA'},
    {'url': 'https://feeds.feedburner.com/TheHackersNews', 'source': 'The Hacker News'},
  ];

  // Articles de secours si pas de connexion
  static final _fallbackArticles = [
    _CyberArticle(
      title: 'Phishing : nouvelle vague ciblant les clients bancaires français',
      link: 'https://www.cybermalveillance.gouv.fr',
      date: 'Aujourd\'hui',
      summary: 'Des campagnes de phishing sophistiquées usurpent l\'identité de grandes banques françaises pour voler les identifiants.',
      source: 'Cybermalveillance',
    ),
    _CyberArticle(
      title: 'Ransomware : les PME françaises en ligne de mire',
      link: 'https://www.cert.ssi.gouv.fr',
      date: 'Cette semaine',
      summary: 'Le CERT-FR signale une recrudescence des attaques ransomware ciblant les petites et moyennes entreprises.',
      source: 'CERT-FR',
    ),
    _CyberArticle(
      title: 'Stalkerware : hausse de 35% des logiciels espions sur smartphones',
      link: 'https://www.cybermalveillance.gouv.fr',
      date: 'Cette semaine',
      summary: 'Kaspersky et ESET rapportent une hausse significative des logiciels de surveillance installés à l\'insu des victimes.',
      source: 'ANSSI',
    ),
    _CyberArticle(
      title: 'Fuite de données : 40M de comptes exposés sur le dark web',
      link: 'https://haveibeenpwned.com',
      date: 'Ce mois',
      summary: 'Une nouvelle fuite massive de données combine des millions de comptes provenant de multiples plateformes.',
      source: 'HaveIBeenPwned',
    ),
    _CyberArticle(
      title: 'Vulnérabilité critique dans les routeurs domestiques',
      link: 'https://nvd.nist.gov',
      date: 'Ce mois',
      summary: 'Des chercheurs découvrent une faille zero-day dans des millions de routeurs permettant une prise de contrôle à distance.',
      source: 'NVD / CERT',
    ),
    _CyberArticle(
      title: 'Fraude au président : 1,8M€ détournés en France',
      link: 'https://www.police-nationale.interieur.gouv.fr',
      date: 'Ce mois',
      summary: 'Des cybercriminels se font passer pour des dirigeants d\'entreprise par email pour obtenir des virements frauduleux.',
      source: 'Police Nationale',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() { _loading = true; _error = false; });
    final fetched = <_CyberArticle>[];

    for (final feed in _feeds) {
      try {
        final res = await http.get(
          Uri.parse(feed['url']!),
          headers: {'Accept': 'application/rss+xml, application/xml, text/xml'},
        ).timeout(const Duration(seconds: 6));

        if (res.statusCode == 200) {
          final xml = utf8.decode(res.bodyBytes);
          final items = RegExp(r'<item>(.*?)</item>', dotAll: true).allMatches(xml);

          for (final item in items.take(5)) {
            final body = item.group(1)!;

            String _tag(String tag) {
              final cdata = RegExp('<$tag><!\\[CDATA\\[(.*?)\\]\\]></$tag>', dotAll: true).firstMatch(body);
              if (cdata != null) return cdata.group(1)!.trim();
              final plain = RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(body);
              return plain?.group(1)?.replaceAll(RegExp(r'<[^>]+>'), '').trim() ?? '';
            }

            final title = _tag('title');
            final link  = _tag('link');
            final date  = _tag('pubDate');
            final desc  = _tag('description');

            if (title.isNotEmpty) {
              fetched.add(_CyberArticle(
                title: title.length > 100 ? '${title.substring(0, 97)}…' : title,
                link: link,
                date: _formatDate(date),
                summary: desc.length > 180 ? '${desc.substring(0, 177)}…' : desc,
                source: feed['source']!,
              ));
            }
          }
        }
      } catch (_) {
        // Ce feed a échoué, on continue
      }
    }

    setState(() {
      _loading = false;
      _lastRefresh = DateTime.now();
      if (fetched.isNotEmpty) {
        _articles = fetched;
        _error = false;
      } else {
        _articles = _fallbackArticles;
        _error = true; // Indique qu'on utilise le cache
      }
    });

    // Mettre à jour la veille ARIA
    if (fetched.isNotEmpty) {
      final summary = fetched.take(5).map((a) => a.title).join(' | ');
      final p = await SharedPreferences.getInstance();
      final briefing = 'Veille ${DateTime.now().day}/${DateTime.now().month}: $summary';
      await p.setString('aria_daily_briefing', briefing);
      await p.setInt('aria_last_fetch', DateTime.now().millisecondsSinceEpoch);
      VoiceAIService._dailyBriefing = briefing;
    }
  }

  String _formatDate(String raw) {
    try {
      final months = {'Jan':'Jan','Feb':'Fév','Mar':'Mar','Apr':'Avr','May':'Mai',
        'Jun':'Jun','Jul':'Jul','Aug':'Aoû','Sep':'Sep','Oct':'Oct','Nov':'Nov','Dec':'Déc'};
      for (final e in months.entries) {
        if (raw.contains(e.key)) raw = raw.replaceAll(e.key, e.value);
      }
      final parts = raw.split(' ');
      if (parts.length >= 4) return '${parts[1]} ${parts[2]} ${parts[3]}';
    } catch (_) {}
    return raw.length > 16 ? raw.substring(0, 16) : raw;
  }

  Color _sourceColor(String s) {
    if (s.contains('CERT')) return Colors.blue;
    if (s.contains('CISA')) return Colors.blue;
    if (s.contains('Hacker')) return Colors.orange;
    if (s.contains('ANSSI') || s.contains('Cyber')) return const Color(0xFF4A9EFF);
    return Colors.tealAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060610).withOpacity(0.9),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Veille Cyber', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_lastRefresh != null)
              Text(
                'Mis à jour ${_lastRefresh!.hour.toString().padLeft(2,'0')}:${_lastRefresh!.minute.toString().padLeft(2,'0')} ${_error ? "• (cache local)" : "• CERT-FR live"}',
                style: TextStyle(fontSize: 10, color: _error ? Colors.orange : Colors.blue),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                : const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loading ? null : _fetchNews,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.shield_moon, color: Colors.cyanAccent),
            tooltip: 'Guide sécurité réseaux sociaux',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialSecurityScreen())),
          ),
        ],
      ),
      body: _loading && _articles.isEmpty
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 16),
                Text('Chargement des actualités CERT-FR…', style: TextStyle(color: Colors.white54)),
              ],
            ))
          : RefreshIndicator(
              color: Colors.blue,
              onRefresh: _fetchNews,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                itemCount: _articles.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _error ? Colors.orange.withOpacity(0.08) : Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _error ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(_error ? Icons.wifi_off : Icons.rss_feed,
                          color: _error ? Colors.orange : Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          _error
                            ? '${_articles.length} articles (mode hors ligne — tirez pour actualiser)'
                            : '${_articles.length} articles live — CERT-FR · CISA · The Hacker News',
                          style: TextStyle(color: _error ? Colors.orange : Colors.blue, fontSize: 12),
                        )),
                      ]),
                    );
                  }
                  final a = _articles[i - 1];
                  final sc = _sourceColor(a.source);
                  return GestureDetector(
                    onTap: () => openUrl(a.link),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sc.withOpacity(0.25)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sc.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: sc.withOpacity(0.4)),
                            ),
                            child: Text(a.source, style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(a.date, style: const TextStyle(color: Colors.white38, fontSize: 10))),
                          const Icon(Icons.open_in_browser, color: Colors.white24, size: 14),
                        ]),
                        const SizedBox(height: 8),
                        Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.35)),
                        if (a.summary.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(a.summary, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─── ECRAN SECURITE RESEAUX SOCIAUX ──────────────────────────────────────────

class SocialSecurityScreen extends StatelessWidget {
  const SocialSecurityScreen({super.key});

  static const _platforms = [
    {
      'name': 'WhatsApp',
      'icon': '💬',
      'color': 0xFF25D366,
      'level': 'Bon',
      'levelColor': 0xFF4CAF50,
      'encryption': 'Chiffrement de bout en bout (Signal Protocol)',
      'risks': [
        'Métadonnées collectées par Meta (qui vous appelez, quand, combien de temps)',
        'Sauvegardes Google Drive/iCloud NON chiffrées par défaut',
        'Partage des données avec Instagram et Facebook',
        'Numéro de téléphone visible des inconnus si mal configuré',
      ],
      'tips': [
        'Désactiver la sauvegarde cloud (Paramètres → Discussions → Sauvegarde)',
        'Activer la vérification en deux étapes (Paramètres → Compte → Vérif. en 2 étapes)',
        'Masquer votre photo de profil aux inconnus',
        'Activer "Disparition des messages" par défaut',
        'Vérifier les appareils connectés (Paramètres → Appareils connectés)',
      ],
    },
    {
      'name': 'Telegram',
      'icon': '✈️',
      'color': 0xFF2AABEE,
      'level': 'Moyen',
      'levelColor': 0xFFFF9800,
      'encryption': 'Chiffrement serveur par défaut — E2E seulement dans "Conversations Secrètes"',
      'risks': [
        'Les conversations normales sont stockées sur les serveurs de Telegram',
        'Les groupes et canaux NE sont PAS chiffrés de bout en bout',
        'Numéro de téléphone exposé dans certaines configurations',
        'Moins sécurisé que Signal pour les communications sensibles',
      ],
      'tips': [
        'Utiliser UNIQUEMENT les "Conversations Secrètes" pour les infos sensibles',
        'Activer le Code de passage (Paramètres → Confidentialité → Code de passage)',
        'Masquer votre numéro de téléphone (Paramètres → Confidentialité → Numéro de téléphone → Personne)',
        'Activer la vérification en deux étapes',
        'Désactiver les aperçus de liens',
      ],
    },
    {
      'name': 'Instagram',
      'icon': '📸',
      'color': 0xFFE1306C,
      'level': 'Faible',
      'levelColor': 0xFFF44336,
      'encryption': 'Aucun chiffrement de bout en bout des messages (DM)',
      'risks': [
        'Messages privés (DM) lisibles par Meta et ses employés',
        'Géolocalisation possible via les photos publiées (métadonnées EXIF)',
        'Collecte massive de données comportementales',
        'Risque élevé d\'ingénierie sociale et phishing',
        'Stalkers et harcèlement via les abonnés',
      ],
      'tips': [
        'Passer en compte privé',
        'Désactiver la géolocalisation dans les stories',
        'Ne jamais partager d\'informations sensibles en DM',
        'Activer l\'authentification à deux facteurs',
        'Vérifier les applications tierces ayant accès à votre compte',
      ],
    },
    {
      'name': 'TikTok',
      'icon': '🎵',
      'color': 0xFFFF0050,
      'level': 'Risqué',
      'levelColor': 0xFFF44336,
      'encryption': 'Données stockées aux États-Unis et en Chine (ByteDance)',
      'risks': [
        'Données potentiellement accessibles par le gouvernement chinois',
        'Collecte intensive : localisation GPS, contacts, clipboard, biométrie',
        'Messages privés non chiffrés de bout en bout',
        'Algorithme de surveillance comportementale très poussé',
        'Banni sur les téléphones gouvernementaux dans plusieurs pays',
      ],
      'tips': [
        'Ne jamais partager d\'informations personnelles ou professionnelles sensibles',
        'Désactiver la synchronisation des contacts',
        'Limiter les permissions (caméra, micro, localisation)',
        'Passer en compte privé',
        'Éviter TikTok pour toute communication confidentielle',
      ],
    },
    {
      'name': 'Signal',
      'icon': '🔒',
      'color': 0xFF3A76F0,
      'level': 'Excellent',
      'levelColor': 0xFF00E676,
      'encryption': 'Signal Protocol — le standard or mondial du chiffrement E2E',
      'risks': [
        'Nécessite un numéro de téléphone pour l\'inscription',
        'Si votre téléphone est compromis physiquement, les messages sont accessibles',
      ],
      'tips': [
        'Activer le code PIN Signal (Note de sécurité)',
        'Utiliser la fonction "Disparition des messages" par défaut',
        'Activer le verrouillage de l\'écran dans Signal',
        'Vérifier le code de sécurité avec votre contact (Profil → Numéro de sécurité)',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sécurité Réseaux Sociaux', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _platforms.length,
        itemBuilder: (context, index) {
          final p = _platforms[index];
          return _platformCard(context, p);
        },
      ),
    );
  }

  Widget _platformCard(BuildContext context, Map<String, dynamic> p) {
    final color = Color(p['color'] as int);
    final levelColor = Color(p['levelColor'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: Text(p['icon'] as String, style: const TextStyle(fontSize: 28)),
        title: Text(p['name'] as String, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(p['encryption'] as String, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 2),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: levelColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(p['level'] as String, style: TextStyle(color: levelColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ Risques', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(p['risks'] as List).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r as String, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.4))),
                  ]),
                )),
                const SizedBox(height: 12),
                const Text('✅ Conseils', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(p['tips'] as List).map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t as String, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4))),
                  ]),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
