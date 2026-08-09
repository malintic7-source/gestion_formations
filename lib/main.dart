import 'package:flutter/material.dart';
import 'package:gestion_formations/config/theme.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Pages/Login/welcom_page.dart';
import 'package:gestion_formations/Pages/INSCRIPTIONS/formulaire.dart';
import 'package:gestion_formations/Pages/home_screen.dart';
import 'package:gestion_formations/Services/auth_provider.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/Services/local_storage.dart';
import 'package:gestion_formations/Models/payment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Import any pending local inscriptions created by the static public page.
  try {
    await _importLocalInscriptionQueue();
    await _importFromApi();
  } catch (e) {
    // ignore import errors
  }

  // Firebase initialization removed (migrating away from Firebase).
  runApp(const MyApp());
}

Future<void> _importLocalInscriptionQueue() async {
  try {
    final storage = LocalStorage();
    final key = 'local_inscriptions';
    final raw = storage.getItem(key);
    if (raw == null || raw.isEmpty) return;

    final List<dynamic> list = jsonDecode(raw);
    final db = LocalDataService();

    for (final item in list) {
      try {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        final etudiantId = map['etudiantId']?.toString() ?? 'web_${DateTime.now().millisecondsSinceEpoch}';
        final prenom = map['prenom']?.toString();
        final nom = map['nom']?.toString();
        final email = map['email']?.toString();
        final telephone = map['telephone']?.toString();
        final formationId = map['formationId']?.toString() ?? '';
        final modules = (map['modules'] as List<dynamic>?)?.map((e) => e.toString()).toList();
        final description = map['description']?.toString();
        final typeFormation = map['typeFormation']?.toString();

        // Create inscription in local in-memory DB. Use default payment values.
        await db.createInscription(
          etudiantId: etudiantId,
          formationId: formationId,
          montant: 0.0,
          methode: PaymentMethod.especes,
          prenom: prenom,
          nom: nom,
          email: email,
          telephone: telephone,
          description: description,
          modules: modules,
          typeFormation: typeFormation,
        );
      } catch (e) {
        // ignore individual item errors
      }
    }

    // Clear queue after import
    storage.removeItem(key);
  } catch (e) {
    // ignore
  }
}

Future<void> _importFromApi() async {
  try {
    final db = LocalDataService();
    // Use current page origin to call the API through nginx proxy
    final origin = Uri.base.origin;
    final response = await http.get(
      Uri.parse('$origin/api/inscriptions'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) return;
    final text = response.body;
    if (text.isEmpty) return;
    final List<dynamic> list = jsonDecode(text);
    for (final item in list) {
      try {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        final etudiantId = map['etudiantId']?.toString() ?? 'web_${DateTime.now().millisecondsSinceEpoch}';
        final prenom = map['prenom']?.toString();
        final nom = map['nom']?.toString();
        final email = map['email']?.toString();
        final telephone = map['telephone']?.toString();
        final formationId = map['formationId']?.toString() ?? '';
        final modules = (map['modules'] as List<dynamic>?)?.map((e) => e.toString()).toList();
        final description = map['description']?.toString();
        final typeFormation = map['typeFormation']?.toString();

        await db.createInscription(
          etudiantId: etudiantId,
          formationId: formationId,
          montant: 0.0,
          methode: PaymentMethod.especes,
          prenom: prenom,
          nom: nom,
          email: email,
          telephone: telephone,
          description: description,
          modules: modules,
          typeFormation: typeFormation,
        );
      } catch (e) {
        // ignore
      }
    }
  } catch (e) {
    // ignore if API not reachable
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion-Formations',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _inscriptionScheduled = false;
  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    // Primary: check standard query parameters
    String? preselectedFormationId = uri.queryParameters['formationId'];
    bool showInscriptionPage = uri.queryParameters['inscription'] == 'true';

    // Fallback: some share links may use hash routing (/#/inscription?formationId=...)
    // In that case the fragment contains the route and its query params.
    if (!showInscriptionPage) {
      final frag = uri.fragment; // e.g. "/inscription?formationId=..." or "inscription?formationId=..."
      if (frag.isNotEmpty && frag.contains('inscription')) {
        // Try to extract query params from fragment
        try {
          final fragPart = frag.contains('?') ? frag.split('?').last : '';
          final fragParams = Uri.splitQueryString(fragPart.isNotEmpty ? fragPart : '');
          if (fragParams['inscription'] == 'true' || frag.contains('inscription')) {
            showInscriptionPage = true;
          }
          if (preselectedFormationId == null || preselectedFormationId.isEmpty) {
            preselectedFormationId = fragParams['formationId'];
          }
        } catch (e) {
          // ignore parsing errors and continue
        }
      }
    }

    return StreamBuilder<User?>(
      stream: AuthProvider().watchCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If share link requests inscription, schedule navigation after first frame
        if (showInscriptionPage && !_inscriptionScheduled) {
          _inscriptionScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => InscriptionPage(formationId: preselectedFormationId),
              ));
            } catch (e) {
              // ignore navigator errors during early builds
            }
          });
        }

        if (snapshot.connectionState == ConnectionState.active) {
          final currentUser = snapshot.data;
          if (currentUser != null) {
            return HomeScreen(user: currentUser);
          }

          return const WelcomPage();
        }

        return const WelcomPage();
      },
    );
  }
}
