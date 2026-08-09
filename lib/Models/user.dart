enum UserRole { admin, formateur, etudiant }

class User {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String phone;
  final UserRole role;
  final String password;
  final String? photoUrl;
  final bool estActif;
  final DateTime dateCreation;
  final DateTime? dateModification;

  User({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.phone,
    required this.role,
    this.password = '',
    this.photoUrl,
    required this.estActif,
    required this.dateCreation,
    this.dateModification,
  });

  factory User.fromMap(Map<String, dynamic> data, String id) {
    UserRole parseRole(String roleStr) {
      if (roleStr.contains('admin')) {
        return UserRole.admin;
      }
      if (roleStr.contains('formateur')) {
        return UserRole.formateur;
      }
      return UserRole.etudiant;
    }

    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return User(
      id: id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      phone: data['phone'] ?? '',
      role: parseRole(data['role']?.toString() ?? 'UserRole.etudiant'),
      password: data['password'] ?? '',
      photoUrl: data['photoUrl'],
      estActif: data['estActif'] ?? true,
      dateCreation: parseDate(data['dateCreation']),
      dateModification: data['dateModification'] != null ? parseDate(data['dateModification']) : null,
    );
  }

  // Alias for backward compatibility if code calls User.fromFirestore
  factory User.fromFirestore(dynamic doc) {
    if (doc is Map<String, dynamic>) {
      return User.fromMap(doc, doc['id'] ?? '');
    }
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return User.fromMap(data, doc.id ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'phone': phone,
      'role': role.toString(),
      'password': password,
      'photoUrl': photoUrl,
      'estActif': estActif,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  String get nomComplet => '$prenom $nom';
}

