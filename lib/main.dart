import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gestion_formations/config/theme.dart';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Pages/Login/welcom_page.dart';
import 'package:gestion_formations/Pages/INSCRIPTIONS/formulaire.dart';
import 'package:gestion_formations/Pages/home_screen.dart';
import 'package:gestion_formations/Services/auth_provider.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/Services/local_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  // Import queues asynchronously in background after first paint
  Future.microtask(() async {
    try {
      await _importLocalInscriptionQueue();
      await _importFromApi();
    } catch (e) {
      debugPrint('Import queue error: $e');
    }
  });
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
        // Import administrative enrolments only. Payments are recorded from
        // the dedicated Payments module when money is actually received.
        await db.createInscription(
          etudiantId: etudiantId,
          formationId: formationId,
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
    if (!kIsWeb) return;
    final db = LocalDataService();
    // Use current page origin to call the API through nginx proxy
    if (!Uri.base.hasAuthority) return;
    final origin = Uri.base.origin;
    if (origin.isEmpty || !origin.startsWith('http')) return;
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
      title: 'Malintic',
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
  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    String? preselectedFormationId =
        uri.queryParameters['formationId'] ?? uri.queryParameters['id'];
    bool showInscriptionPage = uri.queryParameters['inscription'] == 'true';

    if (!showInscriptionPage) {
      final frag = uri.fragment;
      if (frag.isNotEmpty && frag.contains('inscription')) {
        try {
          final fragPart = frag.contains('?') ? frag.split('?').last : '';
          final fragParams = Uri.splitQueryString(fragPart.isNotEmpty ? fragPart : '');
          if (fragParams['inscription'] == 'true' || frag.contains('inscription')) {
            showInscriptionPage = true;
          }
          if (preselectedFormationId == null || preselectedFormationId.isEmpty) {
            preselectedFormationId =
                fragParams['formationId'] ?? fragParams['id'];
          }
        } catch (e) {
          // ignore parsing errors and continue
        }
      }
    }

    return StreamBuilder<User?>(
      stream: AuthProvider().watchCurrentUser(),
      initialData: AuthProvider().currentUser,
      builder: (context, snapshot) {
        final activeUser = snapshot.data ?? AuthProvider().currentUser;
        if (activeUser != null) {
          return HomeScreen(user: activeUser);
        }

        if (showInscriptionPage) {
          return InscriptionPage(formationId: preselectedFormationId);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        return const WelcomPage();
      },
    );
  }
}
