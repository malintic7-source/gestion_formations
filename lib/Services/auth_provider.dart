import 'dart:async';
import 'package:gestion_formations/Models/user.dart';
import 'package:gestion_formations/Services/db_services.dart';

class AuthProvider {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal();

  final LocalDataService _db = LocalDataService();
  final StreamController<User?> _authController = StreamController<User?>.broadcast();

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isFormateur => _currentUser?.role == UserRole.formateur;
  bool get isEtudiant => _currentUser?.role == UserRole.etudiant;

  Stream<User?> get authStateChanges async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  Stream<User?> watchCurrentUser() => authStateChanges;

  Future<User?> loadCurrentUser() async {
    return _currentUser;
  }

  Future<User?> loginWithEmail(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = _db.getUsers();

    final matchedUser = users.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
      orElse: () => throw Exception('Identifiants invalides.'),
    );

    if (!matchedUser.estActif) {
      throw Exception('Compte désactivé. Veuillez contacter l\'administrateur.');
    }

    if (matchedUser.password != password) {
      throw Exception('Identifiants invalides.');
    }

    _currentUser = matchedUser;
    _authController.add(_currentUser);
    return _currentUser;
  }

  Future<void> logout() async {
    _currentUser = null;
    _authController.add(null);
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

  Future<User> updateUser(User user) async {
    final updated = await _db.addUser(user);
    if (_currentUser?.id == user.id) {
      _currentUser = updated;
      _authController.add(_currentUser);
    }
    return updated;
  }

  Future<void> setUserActive(String userId, bool isActive) async {
    await _db.setUserActive(userId, isActive);
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
  }) async {
    if (email.trim().isEmpty) {
      throw Exception('MISSING_EMAIL');
    }

    final newUser = User(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      nom: nom.trim(),
      prenom: prenom.trim(),
      phone: phone.trim(),
      role: role,
      password: '00000000',
      estActif: true,
      dateCreation: DateTime.now(),
    );

    await _db.addUser(newUser);
    return newUser;
  }
}
