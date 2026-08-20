class Student {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String phone;
  final String? matricule;
  final String? photoUrl;
  final List<Map<String, dynamic>> assignedFormations;
  final bool estActif;
  final DateTime dateCreation;
  final DateTime? dateModification;

  Student({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.phone,
    this.matricule,
    this.photoUrl,
    this.assignedFormations = const [],
    required this.estActif,
    required this.dateCreation,
    this.dateModification,
  });

  factory Student.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Student(
      id: id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      phone: data['phone'] ?? '',
      matricule: data['matricule']?.toString(),
      photoUrl: data['photoUrl'],
      assignedFormations: (data['assignedFormations'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      estActif: data['estActif'] ?? true,
      dateCreation: parseDate(data['dateCreation']),
      dateModification: data['dateModification'] != null ? parseDate(data['dateModification']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'phone': phone,
      'matricule': matricule,
      'photoUrl': photoUrl,
      'assignedFormations': assignedFormations,
      'estActif': estActif,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification?.toIso8601String(),
    };
  }

  String get nomComplet => '$prenom $nom';
}
