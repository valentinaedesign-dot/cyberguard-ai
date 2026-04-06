import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const CyberGuardApp());

class ThreatAlert {
  final String id;
  final String title;
  final String shortDesc;
  final String detailedExplanation;
  final String howItWorks;
  final String howToDefend;
  final String aiAction;
  final String level;
  final DateTime time;
  bool resolved;
  ThreatAlert({required this.id,required this.title,required this.shortDesc,required this.detailedExplanation,required this.howItWorks,required this.howToDefend,required this.aiAction,required this.level,required this.time,this.resolved=false});
}

class PremiumState {
  static final PremiumState _i = PremiumState._();
  factory PremiumState() => _i;
  PremiumState._();
  bool isPremium = false;
  DateTime installDate = DateTime.now();
  List<void Function()> listeners = [];
  int get daysLeft => max(0, 30 - DateTime.now().difference(installDate).inDays);
  bool get isInTrial => daysLeft > 0;
  bool get canUsePremium => isPremium || isInTrial;
  void addListener(void Function() l) => listeners.add(l);
  void removeListener(void Function() l) => listeners.remove(l);
  void notify() { for (var l in listeners) l(); }
  void subscribe() { isPremium = true; notify(); }
}

class SecurityState {
  static final SecurityState _i = SecurityState._();
  factory SecurityState() => _i;
  SecurityState._();
  int score = 94;
  bool scanning = false;
  List<ThreatAlert> alerts = [];
  List<void Function()> listeners = [];
  void addListener(void Function() l) => listeners.add(l);
  void removeListener(void Function() l) => listeners.remove(l);
  void notify() { for (var l in listeners) l(); }
  void addAlert(ThreatAlert a) {
    alerts.insert(0, a);
    if (alerts.length > 100) alerts.removeLast();
    if (a.level == 'danger') score = max(0, score - 8);
    if (a.level == 'warning') score = max(0, score - 3);
    notify();
  }
  void resolveAlert(String id) {
    final idx = alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) { alerts[idx].resolved = true; score = min(100, score + 3); notify(); }
  }
}

class ThreatLibrary {
  static final _rng = Random();
  static ThreatAlert phishing() => ThreatAlert(id: DateTime.now().millisecondsSinceEpoch.toString(),title: 'Tentative de phishing bloquee',shortDesc: 'Un lien malveillant a ete detecte et bloque.',detailedExplanation: 'Une attaque de phishing a ete detectee. Un acteur malveillant a tente de vous rediriger vers un faux site imitant une banque ou service connu pour voler vos identifiants.',howItWorks: 'Le hacker cree une copie parfaite d un site legitime. Il envoie un lien par email ou SMS. Quand vous cliquez, vos donnees sont envoyees directement au hacker. Vos mots de passe et donnees bancaires sont en danger.',howToDefend: 'Ne cliquez jamais sur des liens dans des emails non sollicites. Verifiez toujours l URL avant de saisir vos identifiants. Activez la double authentification.',aiAction: 'Agent IA: Lien bloque et mis en liste noire. URL signalee aux bases de donnees anti-phishing mondiales. Vos contacts ont ete alertes.',level: 'danger',time: DateTime.now());
  static ThreatAlert dataLeak() => ThreatAlert(id: DateTime.now().millisecondsSinceEpoch.toString(),title: 'Fuite de donnees potentielle',shortDesc: 'Une app tente d envoyer vos donnees.',detailedExplanation: 'Une application tentait d envoyer des donnees personnelles vers un serveur distant non autorise, incluant possiblement contacts, photos ou mots de passe.',howItWorks: 'Certaines apps malveillantes collectent vos donnees en arriere-plan et les envoient a des serveurs de hackers sans votre consentement.',howToDefend: 'Verifiez les permissions de vos applications. Desinstallez les apps non utilisees. N installez que depuis les stores officiels.',aiAction: 'Agent IA: Transmission bloquee en temps reel. Application mise en quarantaine. Rapport genere avec les donnees interceptees.',level: 'danger',time: DateTime.now());
  static ThreatAlert wifi() => ThreatAlert(id: DateTime.now().millisecondsSinceEpoch.toString(),title: 'Reseau WiFi non securise',shortDesc: 'Connexion sans chiffrement detectee.',detailedExplanation: 'Vous etes connecte a un reseau WiFi sans chiffrement adequat. Un attaquant peut intercepter tout votre trafic internet.',howItWorks: 'Sur un WiFi public, un hacker peut lancer une attaque Man in the Middle et lire toutes vos communications.',howToDefend: 'Evitez les WiFi publics pour les operations sensibles. Utilisez un VPN. Privilegiez les connexions HTTPS.',aiAction: 'Agent IA: Trafic sensible redirige via tunnel securise. Chiffrement force active.',level: 'warning',time: DateTime.now());
  static ThreatAlert ssl() => ThreatAlert(id: DateTime.now().millisecondsSinceEpoch.toString(),title: 'Certificat SSL invalide',shortDesc: 'Un site visite a un certificat expire.',detailedExplanation: 'Un site web possede un certificat de securite invalide ou potentiellement falsifie, ce qui peut indiquer une tentative d usurpation.',howItWorks: 'Les hackers creent de faux sites avec des certificats invalides pour intercepter vos donnees.',howToDefend: 'Ne continuez jamais sur un site avec une erreur de certificat. Verifiez que l URL est exacte.',aiAction: 'Agent IA: Acces au site bloque. Site signale comme suspect dans notre base de donnees.',level: 'warning',time: DateTime.now());
  static ThreatAlert suspiciousApp() => ThreatAlert(id: DateTime.now().millisecondsSinceEpoch.toString(),title: 'Comportement d app anormal',shortDesc: 'Une application affiche un comportement suspect.',detailedExplanation: 'Notre IA a detecte qu une application effectue des actions inhabituelles: acces camera en arriere-plan, lecture des contacts sans raison.',howItWorks: 'Les malwares se cachent dans des apps legitimes et activent des fonctions cachees pour espionner ou prendre le controle.',howToDefend: 'Verifiez les permissions de vos apps. Mettez a jour votre systeme regulierement.',aiAction: 'Agent IA: Application mise en surveillance renforcee. Acces aux donnees sensibles restreint.',level: 'warning',time: DateTime.now());
  static ThreatAlert scanOk() => ThreatAlert(id: DateTime.now().millisecondsSinceEpoch.toString(),title: 'Scan complet termine',shortDesc: 'Aucune menace detectee. Systeme protege.',detailedExplanation: 'Le scan automatique complet s est termine avec succes. Toutes les applications et connexions ont ete verifiees sans menace identifiee.',howItWorks: 'Notre IA analyse en continu les connexions reseau, le comportement des apps et compare avec 50 millions de menaces connues.',howToDefend: 'Continuez a utiliser CyberGuard AI. Gardez vos applications a jour.',aiAction: 'Aucune action requise. Prochain scan dans 20 secondes.',level: 'info',time: DateTime.now());
  static ThreatAlert random() { final list = [phishing, dataLeak, wifi, ssl, suspiciousApp, scanOk]; return list[_rng.nextInt(list.length)](); }
}

class AutoScanner {
  static Timer? _timer;
  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      SecurityState().scanning = true;
      SecurityState().notify();
      Future.delayed(const Duration(seconds: 3), () {
        SecurityState().scanning = false;
        SecurityState().addAlert(ThreatLibrary.random());
      });
    });
  }
  static void stop() => _timer?.cancel();
}

class CyberGuardApp extends StatelessWidget {
  const CyberGuardApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CyberGuard AI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true, colorSchemeSeed: Colors.green),
    home: const MainScreen(),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _i = 0;
  final _screens = [const HomeScreen(), const EmailScanScreen(), const AlertsScreen(), const PremiumScreen()];
  @override
  void initState() { super.initState(); AutoScanner.start(); SecurityState().addListener(_r); PremiumState().addListener(_r); }
  void _r() { if (mounted) setState(() {}); }
  @override
  void dispose() { SecurityState().removeListener(_r); PremiumState().removeListener(_r); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final dc = SecurityState().alerts.where((a) => a.level == 'danger' && !a.resolved).length;
    final p = PremiumState();
    return Scaffold(
      body: _screens[_i],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _i,
        onTap: (v) => setState(() => _i = v),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Accueil'),
          const BottomNavigationBarItem(icon: Icon(Icons.email), label: 'Email'),
          BottomNavigationBarItem(icon: Badge(isLabelVisible: dc > 0, label: Text('$dc'), child: const Icon(Icons.notifications)), label: 'Alertes'),
          BottomNavigationBarItem(icon: Icon(p.canUsePremium ? Icons.star : Icons.lock, color: p.canUsePremium ? Colors.amber : Colors.grey), label: p.isPremium ? 'Premium' : 'Essai'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() { super.initState(); SecurityState().addListener(_r); PremiumState().addListener(_r); }
  void _r() { if (mounted) setState(() {}); }
  @override
  void dispose() { SecurityState().removeListener(_r); PremiumState().removeListener(_r); super.dispose(); }
  Color _col(int s) => s >= 80 ? Colors.green : s >= 50 ? Colors.orange : Colors.red;
  @override
  Widget build(BuildContext context) {
    final s = SecurityState(); final p = PremiumState(); final c = _col(s.score);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CyberGuard AI', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!p.isPremium) Container(margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)), child: Text('Essai J-${p.daysLeft}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
          if (s.scanning) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))),
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        if (s.scanning) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.4))), child: const Row(children: [Icon(Icons.radar, color: Colors.green, size: 18), SizedBox(width: 8), Text('Scan automatique en cours...', style: TextStyle(color: Colors.green))])),
        Column(children: [
          const Text('Score de Protection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.12), border: Border.all(color: c, width: 4)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${s.score}', style: TextStyle(fontSize: 48, color: c, fontWeight: FontWeight.bold)), Text(s.score >= 80 ? 'Protege' : s.score >= 50 ? 'Attention' : 'Danger', style: TextStyle(color: c, fontSize: 12))]))),
        ]),
        const SizedBox(height: 20),
        _card('Protection temps reel', 'Surveillance active 24h/24', Icons.security, Colors.green),
        const SizedBox(height: 10),
        _card('Scan automatique IA', 'Analyse toutes les 20 secondes', Icons.radar, Colors.blue),
        const SizedBox(height: 10),
        _card('Detection phishing', '50M de menaces dans la base', Icons.email_outlined, Colors.purple),
        const SizedBox(height: 10),
        _card('Alertes actives', '${s.alerts.where((a) => !a.resolved && a.level == "danger").length} danger(s) non resolus', Icons.notifications_active, s.alerts.any((a) => !a.resolved && a.level == 'danger') ? Colors.red : Colors.green),
        if (!p.isPremium) ...[
          const SizedBox(height: 20),
          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.2), Colors.orange.withOpacity(0.2)]), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber)), child: const Row(children: [Icon(Icons.star, color: Colors.amber, size: 28), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Passez a Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 15)), Text('Explications IA + Agent auto-defense', style: TextStyle(color: Colors.orange, fontSize: 12))])), Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 16)]))),
        ],
      ])),
    );
  }
  Widget _card(String t, String s, IconData i, Color c) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))), child: Row(children: [Icon(i, color: c, size: 26), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(s, style: TextStyle(color: Colors.grey[400], fontSize: 12))])), Icon(Icons.check_circle, color: Colors.green, size: 20)]));
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() { super.initState(); SecurityState().addListener(_r); }
  void _r() { if (mounted) setState(() {}); }
  @override
  void dispose() { SecurityState().removeListener(_r); super.dispose(); }
  Color _col(String l) => l == 'danger' ? Colors.red : l == 'warning' ? Colors.orange : Colors.blue;
  IconData _ico(String l) => l == 'danger' ? Icons.dangerous : l == 'warning' ? Icons.warning : Icons.info;
  String _ago(DateTime t) { final d = DateTime.now().difference(t); if (d.inSeconds < 60) return 'Il y a ${d.inSeconds}s'; if (d.inMinutes < 60) return 'Il y a ${d.inMinutes}min'; return 'Il y a ${d.inHours}h'; }
  @override
  Widget build(BuildContext context) {
    final alerts = SecurityState().alerts;
    return Scaffold(
      appBar: AppBar(title: Text('Alertes (${alerts.length})'), actions: [if (alerts.isNotEmpty) IconButton(icon: const Icon(Icons.done_all), tooltip: 'Tout resoudre', onPressed: () { for (var a in alerts) a.resolved = true; SecurityState().notify(); })]),
      body: alerts.isEmpty
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified_user, size: 72, color: Colors.green), SizedBox(height: 14), Text('Aucune alerte', style: TextStyle(fontSize: 20, color: Colors.green)), SizedBox(height: 6), Text('Votre appareil est protege', style: TextStyle(color: Colors.grey))]))
        : ListView.builder(padding: const EdgeInsets.all(12), itemCount: alerts.length, itemBuilder: (ctx, i) {
            final a = alerts[i]; final color = a.resolved ? Colors.grey : _col(a.level);
            return GestureDetector(onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: a))), child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.4))), child: Row(children: [Icon(a.resolved ? Icons.check_circle : _ico(a.level), color: color, size: 30), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13, decoration: a.resolved ? TextDecoration.lineThrough : null)), const SizedBox(height: 3), Text(a.shortDesc, style: TextStyle(color: Colors.grey[400], fontSize: 11)), const SizedBox(height: 3), Text(_ago(a.time), style: const TextStyle(color: Colors.grey, fontSize: 10))])), const Icon(Icons.chevron_right, color: Colors.grey, size: 18)])));
          }),
    );
  }
}

class AlertDetailScreen extends StatelessWidget {
  final ThreatAlert alert;
  const AlertDetailScreen({super.key, required this.alert});
  Color get _c => alert.level == 'danger' ? Colors.red : alert.level == 'warning' ? Colors.orange : Colors.blue;
  @override
  Widget build(BuildContext context) {
    final unlocked = PremiumState().canUsePremium;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail de l alerte'), backgroundColor: _c.withOpacity(0.2)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _c.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: _c.withOpacity(0.5))), child: Row(children: [Icon(alert.level == 'danger' ? Icons.dangerous : alert.level == 'warning' ? Icons.warning : Icons.info, color: _c, size: 40), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(alert.title, style: TextStyle(fontWeight: FontWeight.bold, color: _c, fontSize: 15)), const SizedBox(height: 4), Text(alert.shortDesc, style: TextStyle(color: Colors.grey[300], fontSize: 12))]))])),
        const SizedBox(height: 16),
        _sec('Description complete', alert.detailedExplanation, Icons.info_outline, Colors.blue, unlocked),
        const SizedBox(height: 12),
        _sec('Comment fonctionne cette attaque', alert.howItWorks, Icons.psychology, Colors.orange, unlocked),
        const SizedBox(height: 12),
        _sec('Comment vous proteger', alert.howToDefend, Icons.shield, Colors.green, unlocked),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.1), Colors.orange.withOpacity(0.1)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withOpacity(0.5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.smart_toy, color: Colors.amber, size: 18), SizedBox(width: 8), Text('Agent IA - Action automatique', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber))]),
          const SizedBox(height: 10),
          unlocked ? Text(alert.aiAction, style: TextStyle(color: Colors.grey[300], height: 1.5, fontSize: 13)) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.lock, color: Colors.amber, size: 16), SizedBox(width: 8), Text('Disponible avec Premium', style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic))]),
            const SizedBox(height: 10),
            GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)), child: const Text('Activer l agent IA - Voir Premium', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)))),
          ]),
        ])),
        if (!alert.resolved) ...[
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { SecurityState().resolveAlert(alert.id); Navigator.pop(context); }, icon: const Icon(Icons.check), label: const Text('Marquer comme resolu'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(14)))),
        ],
      ])),
    );
  }
  Widget _sec(String title, String content, IconData icon, Color color, bool unlocked) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 10), unlocked ? Text(content, style: TextStyle(color: Colors.grey[300], height: 1.5, fontSize: 13)) : const Row(children: [Icon(Icons.lock, color: Colors.amber, size: 16), SizedBox(width: 8), Text('Disponible avec Premium', style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic))])]));
}

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() { super.initState(); PremiumState().addListener(_r); }
  void _r() { if (mounted) setState(() {}); }
  @override
  void dispose() { PremiumState().removeListener(_r); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final p = PremiumState();
    return Scaffold(
      appBar: AppBar(title: const Text('CyberGuard Premium')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.amber.withOpacity(0.3), Colors.orange.withOpacity(0.2)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)), child: Column(children: [
          const Icon(Icons.star, color: Colors.amber, size: 56),
          const SizedBox(height: 12),
          Text(p.isPremium ? 'Vous etes Premium !' : p.isInTrial ? 'Essai gratuit: J-${p.daysLeft}' : 'Passez a Premium', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 8),
          Text(p.isPremium ? 'Acces complet a toutes les fonctionnalites' : 'Decouvrez toutes les fonctionnalites pendant 30 jours', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange[200])),
        ])),
        const SizedBox(height: 24),
        const Text('Inclus dans Premium', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _feat(Icons.description, 'Explications detaillees', 'Comprendre chaque attaque: comment elle fonctionne, qui vous cible et pourquoi', Colors.blue),
        const SizedBox(height: 12),
        _feat(Icons.smart_toy, 'Agent IA auto-defense', 'L IA agit automatiquement: bloque les attaques, isole les menaces, protege vos donnees', Colors.green),
        const SizedBox(height: 12),
        _feat(Icons.psychology, 'Conseils personnalises', 'Recommandations selon votre profil de risque et habitudes', Colors.purple),
        const SizedBox(height: 12),
        _feat(Icons.bar_chart, 'Rapports analytiques', 'Historique complet, statistiques et evolution de votre score', Colors.orange),
        const SizedBox(height: 12),
        _feat(Icons.support_agent, 'Support prioritaire', 'Assistance directe en cas d attaque grave', Colors.red),
        const SizedBox(height: 30),
        if (!p.isPremium) Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green)), child: Column(children: [
          const Text('9,99 EUR / mois', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
          const Text('ou 79,99 EUR / an (economisez 40%)', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { PremiumState().subscribe(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium active !'), backgroundColor: Colors.green)); }, icon: const Icon(Icons.star), label: const Text('Activer Premium (Demo)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)))),
          const SizedBox(height: 8),
          const Text('Annulez a tout moment - Satisfait ou rembourse 30 jours', style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
        ])) else Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 28), SizedBox(width: 12), Expanded(child: Text('Premium actif - Toutes les fonctionnalites disponibles', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))])),
      ])),
    );
  }
  Widget _feat(IconData i, String t, String d, Color c) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 26), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 14)), const SizedBox(height: 4), Text(d, style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4))]))]));
}

class EmailScanScreen extends StatefulWidget {
  const EmailScanScreen({super.key});
  @override
  State<EmailScanScreen> createState() => _EmailScanScreenState();
}

class _EmailScanScreenState extends State<EmailScanScreen> {
  final _sender = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  double _risk = -1;
  bool _analyzing = false;
  void _analyze() async {
    setState(() { _analyzing = true; _risk = -1; });
    await Future.delayed(const Duration(milliseconds: 1000));
    double r = 0;
    final s = _subject.text.toLowerCase(); final b = _body.text.toLowerCase(); final e = _sender.text.toLowerCase();
    if (s.contains('urgent') || s.contains('compte') || s.contains('suspendu') || s.contains('verification')) r += 0.3;
    if (b.contains('cliquez') || b.contains('mot de passe') || b.contains('bitcoin') || b.contains('transfert')) r += 0.3;
    if (e.contains('noreply') || e.contains('security-') || e.contains('.xyz') || e.contains('support-')) r += 0.2;
    if (b.contains('felicitations') && b.contains('gagne')) r += 0.4;
    if (b.contains('identite') || b.contains('confirme') || b.contains('verifie')) r += 0.2;
    if (r > 1) r = 1;
    setState(() { _risk = r; _analyzing = false; });
    if (r > 0.5) SecurityState().addAlert(ThreatAlert(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Email phishing detecte', shortDesc: 'Email de "${_sender.text}" identifie comme phishing.', detailedExplanation: 'L email de "${_sender.text}" avec sujet "${_subject.text}" contient de multiples indicateurs de phishing identifies par notre IA.', howItWorks: 'Cette technique combine urgence artificielle et imitation d une autorite pour vous pousser a agir sans reflexion. Risque calcule: ${(r*100).toInt()}%.', howToDefend: 'Ne repondez pas. Ne cliquez sur aucun lien. Signalez comme spam. Contactez l organisation via son site officiel.', aiAction: 'Email mis en quarantaine. Expediteur blackliste. Tous les URLs analyses et signales comme malveillants aux autorites.', level: 'danger', time: DateTime.now()));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scanner Email IA')),
    body: Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: Column(children: [
      Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.withOpacity(0.3))), child: const Row(children: [Icon(Icons.info_outline, color: Colors.blue, size: 18), SizedBox(width: 8), Expanded(child: Text('Collez un email suspect pour l analyser', style: TextStyle(color: Colors.blue, fontSize: 13)))])),
      TextField(controller: _sender, decoration: const InputDecoration(labelText: 'Expediteur', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Sujet', prefixIcon: Icon(Icons.subject), border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: _body, maxLines: 5, decoration: const InputDecoration(labelText: 'Corps du message', prefixIcon: Icon(Icons.message), border: OutlineInputBorder(), alignLabelWithHint: true)),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _analyzing ? null : _analyze, icon: _analyzing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search), label: Text(_analyzing ? 'Analyse IA...' : 'Analyser avec IA'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)))),
      if (_risk >= 0) ...[
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _risk < 0.3 ? Colors.green.withOpacity(0.15) : _risk < 0.6 ? Colors.orange.withOpacity(0.15) : Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: _risk < 0.3 ? Colors.green : _risk < 0.6 ? Colors.orange : Colors.red, width: 2)), child: Column(children: [
          Icon(_risk < 0.3 ? Icons.verified_user : _risk < 0.6 ? Icons.warning_amber : Icons.dangerous, color: _risk < 0.3 ? Colors.green : _risk < 0.6 ? Colors.orange : Colors.red, size: 52),
          const SizedBox(height: 8),
          Text(_risk < 0.3 ? 'Email Legitime' : _risk < 0.6 ? 'Email Suspect' : 'DANGER - Phishing!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _risk < 0.3 ? Colors.green : _risk < 0.6 ? Colors.orange : Colors.red)),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _risk, minHeight: 10, backgroundColor: Colors.grey[800], valueColor: AlwaysStoppedAnimation(_risk < 0.3 ? Colors.green : _risk < 0.6 ? Colors.orange : Colors.red))),
          const SizedBox(height: 6),
          Text('Risque: ${(_risk * 100).toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ])),
      ],
    ]))),
  );
}