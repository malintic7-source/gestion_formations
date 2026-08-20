import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/Services/local_storage.dart';
import 'package:gestion_formations/Services/tab_session_lifecycle.dart';

class AuthProvider {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal() {
    _loadFromStorage();
  }

  // Load persisted user if any (sessionStorage preserves F5 refresh, clears on tab close)
  Future<User?> _loadFromStorage() async {
    final sessionUserId = _localStorage.getSessionItem('currentUserId');
    final sessionUserJson = _localStorage.getSessionItem('currentUserJson');

    // 1. Instantly restore cached session if present (0ms UI paint)
    if (sessionUserJson != null && sessionUserJson.isNotEmpty) {
      try {
        final map = jsonDecode(sessionUserJson) as Map<String, dynamic>;
        final user = User.fromMap(map, sessionUserId ?? map['id']?.toString() ?? '');
        _currentUser = user;
        TabSessionLifecycle.activate();
        _authController.add(user);
      } catch (_) {}
    }

    // 2. Validate session with the backend asynchronously
    try {
      final response = await http
          .get(Uri.base.resolve('/api/auth/session'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromMap(map, map['id']?.toString() ?? '');
        _currentUser = user;
        TabSessionLifecycle.activate();
        _authController.add(user);
        return user;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Session invalid on server
        _currentUser = null;
        _localStorage.removeSessionItem('currentUserId');
        _localStorage.removeSessionItem('currentUserJson');
        _localStorage.removeItem('currentUserId');
        _localStorage.removeItem('currentUserJson');
        _authController.add(null);
        return null;
      }
    } catch (_) {}

    return _currentUser;
  }

  final LocalDataService _db = LocalDataService();
  final LocalStorage _localStorage = LocalStorage();
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isFormateur => _currentUser?.role == UserRole.formateur;
  bool get isApprenant => _currentUser?.role == UserRole.apprenant;
  bool get isEtudiant => isApprenant;

  Stream<User?> get authStateChanges async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  Stream<User?> watchCurrentUser() => authStateChanges;

  Future<User?> loadCurrentUser() async {
    return _loadFromStorage();
  }

  Future<User?> loginWithEmail(String email, String password) async {
    final rawInput = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final targetEmail = rawInput.contains('@')
        ? rawInput
        : '$rawInput@malintic.ml';
    final targetUsername = targetEmail.split('@').first;

    // La session est stockée dans sessionStorage (survit aux F5, supprimée à la fermeture d'onglet)
    try {
      final response = await http.post(
        Uri.base.resolve('/api/auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': targetEmail, 'password': cleanPassword}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final serverUser = User.fromMap(data, data['id']?.toString() ?? '');
        _currentUser = serverUser;
        TabSessionLifecycle.activate();
        _authController.add(_currentUser);
        _localStorage.setSessionItem('currentUserId', serverUser.id);
        _localStorage.setSessionItem(
          'currentUserJson',
          jsonEncode(serverUser.toMap()),
        );
        await _db.mergeLocalDataWithServer();
        return serverUser;
      }
    } catch (_) {}

    final users = _db.getUsers();

    // 1. Search for matching student/apprenant account
    User? matchedUser = users.where((u) {
      final uEmail = u.email.trim().toLowerCase();
      final uUsername = uEmail.contains('@') ? uEmail.split('@').first : uEmail;
      final fullNomPrenom = '${u.prenom}.${u.nom}'.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9.]'),
        '',
      );
      return uEmail == targetEmail ||
          uEmail == rawInput ||
          uUsername == targetUsername ||
          fullNomPrenom == targetUsername ||
          u.id == rawInput;
    }).firstOrNull;

    // 2. If apprenant login with default password '00000000' (or matched password)
    if (matchedUser != null && matchedUser.role == UserRole.apprenant) {
      final validPassword =
          matchedUser.password.isEmpty ||
          matchedUser.password == '00000000' ||
          matchedUser.password == cleanPassword ||
          cleanPassword == '00000000';
      if (!validPassword) {
        throw Exception(
          'Mot de passe incorrect pour le compte apprenant. Le mot de passe par défaut est : 00000000',
        );
      }

      if (!matchedUser.estActif) {
        throw Exception('Compte apprenant désactivé.');
      }

      _currentUser = matchedUser;
      _authController.add(_currentUser);
      try {
        _localStorage.setSessionItem('currentUserId', _currentUser!.id);
        _localStorage.setSessionItem(
          'currentUserJson',
          jsonEncode(_currentUser!.toMap()),
        );
      } catch (_) {}
      _db.logAction(
        userNom: '${matchedUser.prenom} ${matchedUser.nom}'.trim().isNotEmpty ? '${matchedUser.prenom} ${matchedUser.nom}'.trim() : 'Apprenant',
        userRole: matchedUser.role.name,
        action: 'Connexion',
        description: 'Connexion réussie au portail apprenant (${matchedUser.email})',
      );
      return _currentUser;
    }

    // Les comptes du personnel sont maintenant validés contre la base locale
    // partagée Docker. Firebase Auth n'est plus utilisé.
    matchedUser ??= users.where((u) {
      final uEmail = u.email.trim().toLowerCase();
      return uEmail == targetEmail;
    }).firstOrNull;

    if (matchedUser == null) {
      throw Exception(
        'Compte introuvable. Il doit être créé par un administrateur.',
      );
    }

    if (matchedUser.password.isNotEmpty &&
        matchedUser.password != cleanPassword) {
      throw Exception('Mot de passe incorrect.');
    }

    if (!matchedUser.estActif) {
      throw Exception('Compte désactivé dans l\'application.');
    }

    _currentUser = matchedUser;
    _authController.add(_currentUser);
    try {
      _localStorage.setSessionItem('currentUserId', _currentUser!.id);
      _localStorage.setSessionItem(
        'currentUserJson',
        jsonEncode(_currentUser!.toMap()),
      );
    } catch (_) {}
    _db.logAction(
      userNom: '${matchedUser.prenom} ${matchedUser.nom}'.trim().isNotEmpty ? '${matchedUser.prenom} ${matchedUser.nom}'.trim() : 'Personnel',
      userRole: matchedUser.role.name,
      action: 'Connexion',
      description: 'Connexion réussie au compte ${matchedUser.role.name} (${matchedUser.email})',
    );
    return _currentUser;
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      _db.logAction(
        userNom: '${_currentUser!.prenom} ${_currentUser!.nom}'.trim().isNotEmpty ? '${_currentUser!.prenom} ${_currentUser!.nom}'.trim() : 'Utilisateur',
        userRole: _currentUser!.role.name,
        action: 'Déconnexion',
        description: 'Déconnexion de la session (${_currentUser!.email})',
      );
    }
    try {
      await http.post(Uri.base.resolve('/api/auth/logout'));
    } catch (_) {
      // The local state must still be cleared if the network is unavailable.
    }
    TabSessionLifecycle.deactivate();
    _currentUser = null;
    _authController.add(null);
    try {
      _localStorage.removeSessionItem('currentUserId');
      _localStorage.removeSessionItem('currentUserJson');
      _localStorage.removeItem('currentUserId');
      _localStorage.removeItem('currentUserJson');
    } catch (_) {}
  }

  Future<User?> updateCurrentUser({
    required String nom,
    required String prenom,
    required String phone,
  }) async {
    if (_currentUser == null) {
      throw Exception('Aucun utilisateur connecté.');
    }

    final updated = User(
      id: _currentUser!.id,
      email: _currentUser!.email,
      nom: nom,
      prenom: prenom,
      phone: phone,
      role: _currentUser!.role,
      password: _currentUser!.password,
      photoUrl: _currentUser!.photoUrl,
      assignedFormations: _currentUser!.assignedFormations,
      estActif: _currentUser!.estActif,
      dateCreation: _currentUser!.dateCreation,
      dateModification: DateTime.now(),
    );

    await _db.addUser(updated);
    _currentUser = updated;
    _authController.add(_currentUser);
    return _currentUser;
  }

  Stream<List<User>> watchUsers() {
    return _db.watchUsers();
  }

  String _normalizeEmail(String input) {
    var email = input.trim().toLowerCase();
    if (email.isNotEmpty && !email.contains('@')) {
      email = '$email@gmail.com';
    }
    return email;
  }

  Future<User> updateUser(User user) async {
    final cleanEmail = _normalizeEmail(user.email);
    if (cleanEmail.isEmpty) {
      throw Exception('MISSING_EMAIL');
    }
    final duplicate = _db.getUsers().any(
      (existing) =>
          existing.id != user.id &&
          existing.email.trim().toLowerCase() == cleanEmail,
    );
    if (duplicate) {
      throw Exception('EMAIL_ALREADY_EXISTS');
    }
    final normalizedUser = User(
      id: user.id,
      email: cleanEmail,
      nom: user.nom.trim(),
      prenom: user.prenom.trim(),
      phone: user.phone.trim(),
      role: user.role,
      password: user.password,
      photoUrl: user.photoUrl,
      assignedFormations: user.assignedFormations,
      estActif: user.estActif,
      dateCreation: user.dateCreation,
      dateModification: user.dateModification,
    );
    final updated = await _db.addUser(normalizedUser);
    if (_currentUser?.id == normalizedUser.id) {
      _currentUser = updated;
      _authController.add(_currentUser);
    }
    return updated;
  }

  Future<void> setUserActive(String userId, bool isActive) async {
    await _db.setUserActive(userId, isActive);
  }

  Future<void> deleteUser(String userId) async {
    await _db.deleteUser(userId);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('Aucun utilisateur connecté.');
    }

    if (_currentUser!.password != currentPassword) {
      throw Exception('Ancien mot de passe incorrect.');
    }

    final updatedUser = User(
      id: _currentUser!.id,
      email: _currentUser!.email,
      nom: _currentUser!.nom,
      prenom: _currentUser!.prenom,
      phone: _currentUser!.phone,
      role: _currentUser!.role,
      password: newPassword,
      photoUrl: _currentUser!.photoUrl,
      assignedFormations: _currentUser!.assignedFormations,
      estActif: _currentUser!.estActif,
      dateCreation: _currentUser!.dateCreation,
      dateModification: DateTime.now(),
    );

    await _db.addUser(updatedUser);
    _currentUser = updatedUser;
    _authController.add(_currentUser);
  }

  Future<User?> createUserByAdmin({
    required String email,
    required String nom,
    required String prenom,
    required String phone,
    required UserRole role,
    String password = '00000000',
    String sexe = 'Homme',
    String? photoUrl,
    String? specialite,
  }) async {
    final cleanEmail = _normalizeEmail(email);
    if (cleanEmail.isEmpty) {
      throw Exception('Veuillez fournir une adresse e-mail valide.');
    }
    if (_db.getUsers().any(
      (user) => user.email.trim().toLowerCase() == cleanEmail,
    )) {
      throw Exception('Un utilisateur avec cette adresse e-mail existe déjà.');
    }

    final userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';

    final newUser = User(
      id: userId,
      email: cleanEmail,
      nom: nom.trim(),
      prenom: prenom.trim(),
      phone: phone.trim(),
      role: role,
      password: password,
      sexe: sexe,
      photoUrl: photoUrl,
      specialite: specialite,
      estActif: true,
      dateCreation: DateTime.now(),
    );

    await _db.addUser(newUser);
    return newUser;
  }

  Future<void> resetUserPassword(
    String userId, {
    String password = '00000000',
  }) async {
    final user = _db.getUserById(userId);
    if (user == null) throw Exception('Utilisateur introuvable.');

    await _db.addUser(
      User(
        id: user.id,
        email: user.email,
        nom: user.nom,
        prenom: user.prenom,
        phone: user.phone,
        role: user.role,
        password: password,
        photoUrl: user.photoUrl,
        assignedFormations: user.assignedFormations,
        estActif: user.estActif,
        dateCreation: user.dateCreation,
        dateModification: DateTime.now(),
      ),
    );
  }
}
