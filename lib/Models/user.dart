enum UserRole { admin, dg, daf, comptable, assistant, it, formateur, apprenant }

class User {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String phone;
  final String? matricule;
  final UserRole role;
  final String password;
  final String? photoUrl;
  final List<Map<String, dynamic>> assignedFormations;
  final String sexe;
  final bool estActif;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final String? specialite;

  User({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.phone,
    this.matricule,
    required this.role,
    this.password = '',
    this.photoUrl,
    this.assignedFormations = const [],
    this.sexe = 'Homme',
    this.estActif = true,
    DateTime? dateCreation,
    this.dateModification,
    this.specialite,
  }) : dateCreation = dateCreation ?? DateTime.now();

  factory User.fromMap(Map<String, dynamic> data, String id) {
    UserRole parseRole(String roleStr) {
      final normalized = roleStr.toLowerCase();
      if (normalized.contains('admin')) {
        return UserRole.admin;
      }
      if (normalized.contains('dg')) {
        return UserRole.dg;
      }
      if (normalized.contains('daf')) {
        return UserRole.daf;
      }
      if (normalized.contains('comptable')) {
        return UserRole.comptable;
      }
      if (normalized.contains('assistant')) {
        return UserRole.assistant;
      }
      if (normalized.contains('it')) {
        return UserRole.it;
      }
      if (normalized.contains('formateur')) {
        return UserRole.formateur;
      }
      return UserRole.apprenant;
    }

    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val != null && val.runtimeType.toString().contains('Timestamp')) {
        try {
          return (val as dynamic).toDate();
        } catch (_) {}
      }
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return User(
      id: id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      phone: data['phone'] ?? '',
      role: parseRole(data['role']?.toString() ?? 'UserRole.apprenant'),
      password: data['password'] ?? '',
      photoUrl: data['photoUrl'],
      matricule: data['matricule']?.toString(),
        assignedFormations: (data['assignedFormations'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      sexe: data['sexe']?.toString() ?? 'Homme',
      estActif: data['estActif'] ?? true,
      dateCreation: parseDate(data['dateCreation']),
      dateModification: data['dateModification'] != null ? parseDate(data['dateModification']) : null,
      specialite: data['specialite']?.toString(),
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
      'matricule': matricule,
      'assignedFormations': assignedFormations,
      'sexe': sexe,
      'estActif': estActif,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification?.toIso8601String(),
      'specialite': specialite,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  String get nomComplet => '$prenom $nom';

  bool get isApprenant => role == UserRole.apprenant;
  bool get isEtudiant => role == UserRole.apprenant;
  bool get isEmployee => role != UserRole.apprenant;
}

